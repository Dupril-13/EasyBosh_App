-- ===========================================
-- EASYBOSH V2 - STRUCTURE BASE DE DONNÉES
-- ===========================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===========================================
-- 1. TABLES DE CONFIGURATION
-- ===========================================

-- Table des niveaux scolaires
CREATE TABLE niveaux (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL, -- '3eme', '1ere', 'tle'
    nom VARCHAR(50) NOT NULL,
    description TEXT,
    ordre INTEGER NOT NULL
);

-- Table des séries
CREATE TABLE series (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL, -- 'A', 'C', 'D', 'TI', 'A4Esp', etc.
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL -- 'litteraire', 'scientifique', 'technique', 'linguistique'
);

-- Table des combinaisons niveau/série valides
CREATE TABLE niveau_serie_config (
    id SERIAL PRIMARY KEY,
    niveau_code VARCHAR(10) REFERENCES niveaux(code),
    serie_code VARCHAR(10) REFERENCES series(code),
    valide BOOLEAN DEFAULT true,
    UNIQUE(niveau_code, serie_code)
);

-- Table des matières
CREATE TABLE matieres (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL, -- 'MATH', 'PHYS', 'FRAN', etc.
    description TEXT,
    couleur VARCHAR(7) DEFAULT '#2196F3', -- Code couleur hex
    icone VARCHAR(50) DEFAULT 'book',
    type VARCHAR(20) NOT NULL CHECK (type IN ('obligatoire', 'optionnelle', 'facultative')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de liaison matières-niveaux-séries avec coefficients
CREATE TABLE matiere_niveau_serie (
    id SERIAL PRIMARY KEY,
    matiere_id INTEGER REFERENCES matieres(id) ON DELETE CASCADE,
    niveau_code VARCHAR(10) REFERENCES niveaux(code),
    serie_code VARCHAR(10) REFERENCES series(code),
    coefficient INTEGER NOT NULL DEFAULT 1,
    obligatoire BOOLEAN NOT NULL DEFAULT true,
    UNIQUE(matiere_id, niveau_code, serie_code)
);

-- ===========================================
-- 2. TABLES UTILISATEURS
-- ===========================================

-- Table des utilisateurs (anciennement 'users', renommée pour éviter conflit avec auth.users)
-- Cette table 'profiles' stocke les informations de profil supplémentaires liées à auth.users
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, -- Clé étrangère vers auth.users.id
    email VARCHAR(255) UNIQUE, -- Peut être redondant si vous ne faites que le lire depuis auth.users
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'teacher', 'admin', 'superadmin')) DEFAULT 'student',
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200), -- Peut être généré
    student_level_code VARCHAR(10) REFERENCES niveaux(code),
    student_serie_code VARCHAR(10) REFERENCES series(code),
    phone_number VARCHAR(20),
    birth_date DATE,
    -- email_verified_at est géré dans auth.users, mais peut être copié ici si utile pour RLS/triggers
    email_verified_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Contrainte pour vérifier les combinaisons niveau/série pour les étudiants
    -- Elle est maintenant plus permissive pour la création initiale
    CONSTRAINT valid_niveau_serie_student
        CHECK (
            role != 'student' OR
            (student_level_code IS NULL AND student_serie_code IS NULL) OR
            (
                student_level_code IS NOT NULL AND
                student_serie_code IS NOT NULL AND
                public.is_valid_niveau_serie_combination(student_level_code, student_serie_code)
            )
        )
);
-- Index pour optimiser les recherches par rôle
CREATE INDEX idx_profiles_role ON profiles(role);


-- ===========================================
-- 3. TABLES CONTENU ÉDUCATIF
-- ===========================================

-- Table des chapitres
CREATE TABLE chapitres (
    id SERIAL PRIMARY KEY,
    matiere_id INTEGER REFERENCES matieres(id) ON DELETE CASCADE,
    niveau_code VARCHAR(10) REFERENCES niveaux(code),
    serie_code VARCHAR(10) REFERENCES series(code),
    nom VARCHAR(200) NOT NULL,
    description TEXT,
    ordre INTEGER NOT NULL,
    duree_estimee INTEGER, -- en minutes
    objectifs TEXT[],
    prerequis TEXT[],
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) -- Changé pour référencer auth.users
);

-- Table des cours
CREATE TABLE cours (
    id SERIAL PRIMARY KEY,
    chapitre_id INTEGER REFERENCES chapitres(id) ON DELETE CASCADE,
    nom VARCHAR(200) NOT NULL,
    description TEXT,
    contenu TEXT NOT NULL, -- Contenu markdown/html
    ordre INTEGER NOT NULL,
    duree_estimee INTEGER, -- en minutes
    type VARCHAR(20) DEFAULT 'texte', -- 'texte', 'video', 'audio', 'interactif'
    url_media VARCHAR(500), -- URL pour vidéos/audios
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) -- Changé pour référencer auth.users
);

-- Table des quiz
CREATE TABLE quiz (
    id SERIAL PRIMARY KEY,
    chapitre_id INTEGER REFERENCES chapitres(id) ON DELETE CASCADE,
    nom VARCHAR(200) NOT NULL,
    description TEXT,
    instructions TEXT,
    temps_limite INTEGER, -- en minutes
    nombre_questions INTEGER DEFAULT 0,
    note_passage DECIMAL(5,2) DEFAULT 10.0, -- Note minimale pour réussir
    tentatives_max INTEGER DEFAULT 3,
    melanger_questions BOOLEAN DEFAULT true,
    melanger_reponses BOOLEAN DEFAULT true,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) -- Changé pour référencer auth.users
);

-- Table des questions
CREATE TABLE questions (
    id SERIAL PRIMARY KEY,
    quiz_id INTEGER REFERENCES quiz(id) ON DELETE CASCADE,
    texte TEXT NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('qcm', 'vrai_faux', 'texte_libre', 'numerique')),
    ordre INTEGER NOT NULL,
    points DECIMAL(5,2) DEFAULT 1.0,
    explication TEXT, -- Explication de la réponse
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des options de réponse
CREATE TABLE options_reponse (
    id SERIAL PRIMARY KEY,
    question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
    texte TEXT NOT NULL,
    est_correcte BOOLEAN DEFAULT false,
    ordre INTEGER NOT NULL
);

-- Table des épreuves d'examen
CREATE TABLE epreuves (
    id SERIAL PRIMARY KEY,
    matiere_id INTEGER REFERENCES matieres(id) ON DELETE CASCADE,
    niveau_code VARCHAR(10) REFERENCES niveaux(code),
    serie_code VARCHAR(10) REFERENCES series(code),
    nom VARCHAR(200) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'bepc', 'probatoire', 'baccalaureat', 'examen_blanc'
    annee INTEGER NOT NULL,
    session VARCHAR(20), -- 'normale', 'rattrapage'
    duree INTEGER NOT NULL, -- en minutes
    bareme DECIMAL(5,2) DEFAULT 20.0,
    fichier_url VARCHAR(500), -- URL du fichier PDF
    corrige_url VARCHAR(500), -- URL du corrigé
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) -- Changé pour référencer auth.users
);

-- ===========================================
-- 4. TABLES DE PROGRESSION ET RÉSULTATS
-- ===========================================

-- Progression des cours
CREATE TABLE cours_progression (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Changé pour référencer auth.users
    cours_id INTEGER REFERENCES cours(id) ON DELETE CASCADE,
    commence BOOLEAN DEFAULT false,
    termine BOOLEAN DEFAULT false,
    temps_passe INTEGER DEFAULT 0, -- en secondes
    pourcentage_progression INTEGER DEFAULT 0,
    derniere_position INTEGER DEFAULT 0, -- Pour reprendre là où on s'est arrêté
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, cours_id)
);

-- Résultats des quiz
CREATE TABLE quiz_resultats (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Changé pour référencer auth.users
    quiz_id INTEGER REFERENCES quiz(id) ON DELETE CASCADE,
    tentative INTEGER NOT NULL DEFAULT 1,
    score DECIMAL(5,2) NOT NULL,
    note_sur_20 DECIMAL(5,2) NOT NULL,
    temps_passe INTEGER NOT NULL, -- en secondes
    termine BOOLEAN DEFAULT false,
    reussi BOOLEAN DEFAULT false,
    reponses JSONB, -- Stockage des réponses données
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, quiz_id, tentative)
);

-- Résultats des épreuves
CREATE TABLE epreuve_resultats (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Changé pour référencer auth.users
    epreuve_id INTEGER REFERENCES epreuves(id) ON DELETE CASCADE,
    score DECIMAL(5,2),
    note_sur_20 DECIMAL(5,2),
    temps_passe INTEGER, -- en secondes
    termine BOOLEAN DEFAULT false,
    commentaires TEXT,
    corrige_par UUID REFERENCES auth.users(id), -- Enseignant qui a corrigé (référence auth.users)
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    corrected_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, epreuve_id)
);

-- ===========================================
-- 5. FONCTIONS ET TRIGGERS
-- ===========================================

-- Fonction pour vérifier la validité d'une combinaison niveau/série
CREATE OR REPLACE FUNCTION public.is_valid_niveau_serie_combination(
    p_niveau_code TEXT,
    p_serie_code TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.niveau_serie_config nsc
    WHERE nsc.niveau_code = p_niveau_code
      AND nsc.serie_code = p_serie_code
      AND nsc.valide = true
  );
$$;

-- Fonction pour créer un profil utilisateur après insertion dans auth.users
CREATE OR REPLACE FUNCTION public.create_user_profile_after_auth_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Important pour pouvoir insérer dans public.profiles avec les droits du créateur de la fonction
AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        role, -- Rôle par défaut à la création, ex: 'student'
        first_name,
        last_name,
        full_name,
        email_verified_at, -- Peut être récupéré de NEW.confirmed_at ou NEW.email_confirmed_at
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE((NEW.raw_app_meta_data->>'app_role'), 'student')::VARCHAR, -- Prend le rôle des métadonnées s'il existe, sinon 'student'
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name',
        NEW.raw_user_meta_data->>'full_name',
        NEW.email_confirmed_at, -- ou NEW.confirmed_at selon votre version de Supabase/GoTrue
        true, -- Par défaut actif
        NOW(),
        NOW()
    );

    -- Assurer que raw_app_meta_data.app_role est défini même si le profil est créé avec un rôle par défaut
    -- Cela est important si le rôle initial vient du trigger et non des métadonnées à la création de l'user
    UPDATE auth.users
    SET raw_app_meta_data = jsonb_set(
        COALESCE(raw_app_meta_data, '{}'::jsonb),
        '{app_role}',
        to_jsonb(COALESCE((NEW.raw_app_meta_data->>'app_role'), 'student'))
    )
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$;

-- Trigger sur auth.users pour créer un profil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users; -- Supprimer l'ancien trigger s'il existe
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.create_user_profile_after_auth_insert();


-- Fonction pour mettre à jour auth.users.raw_app_meta_data.app_role depuis profiles.role
CREATE OR REPLACE FUNCTION public.update_user_app_role_from_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Important pour pouvoir modifier auth.users
AS $$
BEGIN
    RAISE NOTICE '[TRIGGER DEBUG] update_user_app_role_from_profile: Fired for profiles.id = %, profiles.role = %', NEW.id, NEW.role;

    UPDATE auth.users
    SET raw_app_meta_data = jsonb_set(
        COALESCE(raw_app_meta_data, '{}'::jsonb),
        '{app_role}',
        to_jsonb(NEW.role)
    )
    WHERE id = NEW.id; -- Utilise l'ID du profil qui est aussi l'UID de l'utilisateur

    IF FOUND THEN
        RAISE NOTICE '[TRIGGER DEBUG] update_user_app_role_from_profile: Successfully attempted to update auth.users for id = %. app_role should be: %', NEW.id, NEW.role;
    ELSE
        RAISE NOTICE '[TRIGGER DEBUG] update_user_app_role_from_profile: FAILED to find user in auth.users with id = % OR data was unchanged for role: %', NEW.id, NEW.role;
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger sur la table profiles pour mettre à jour le rôle dans auth.users
DROP TRIGGER IF EXISTS on_profile_role_updated ON public.profiles;
CREATE TRIGGER on_profile_role_updated
AFTER INSERT OR UPDATE OF role ON public.profiles -- Se déclenche à l'insertion ou à la MAJ du rôle
FOR EACH ROW
EXECUTE FUNCTION public.update_user_app_role_from_profile();

-- Fonction pour générer full_name à partir de first_name et last_name
CREATE OR REPLACE FUNCTION public.generate_full_name_from_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.full_name = TRIM(BOTH FROM COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, ''));
    IF NEW.full_name = '' THEN
        NEW.full_name = NULL;
    END IF;

    -- Mettre à jour aussi full_name dans auth.users.raw_app_meta_data pour cohérence (optionnel mais bien)
    IF NEW.id IS NOT NULL THEN -- S'assurer que l'ID existe (pour éviter erreur à la suppression potentielle)
        UPDATE auth.users
        SET raw_app_meta_data = jsonb_set(
            COALESCE(raw_app_meta_data, '{}'::jsonb),
            '{full_name}',
            to_jsonb(NEW.full_name)
        )
        WHERE id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger sur profiles pour générer full_name
DROP TRIGGER IF EXISTS on_profile_name_changed ON public.profiles;
CREATE TRIGGER on_profile_name_changed
BEFORE INSERT OR UPDATE OF first_name, last_name ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.generate_full_name_from_profile();


-- ===========================================
-- 6. DONNÉES INITIALES (Exemples)
-- ===========================================

-- Insertion des niveaux
INSERT INTO niveaux (code, nom, description, ordre) VALUES
('3eme', 'Troisième', 'Classe de Troisième', 1),
('1ere', 'Première', 'Classe de Première', 2),
('tle', 'Terminale', 'Classe de Terminale', 3)
ON CONFLICT (code) DO NOTHING;

-- Insertion des séries
INSERT INTO series (code, nom, description, type) VALUES
('A', 'Série A', 'Série Littéraire', 'litteraire'),
('A4Esp', 'Série A4 Espagnol', 'Série Littéraire spécialisée Espagnol', 'linguistique'),
('A4All', 'Série A4 Allemand', 'Série Littéraire spécialisée Allemand', 'linguistique'),
('C', 'Série C', 'Série Scientifique Mathématiques-Physique', 'scientifique'),
('D', 'Série D', 'Série Scientifique Mathématiques-SVT', 'scientifique'),
('TI', 'Série TI', 'Série Technologie Industrielle', 'technique')
ON CONFLICT (code) DO NOTHING;

-- Configuration des combinaisons niveau/série valides
INSERT INTO niveau_serie_config (niveau_code, serie_code, valide) VALUES
-- 3ème : que série A
('3eme', 'A', true),
-- 1ère : toutes les séries
('1ere', 'A', true), ('1ere', 'A4Esp', true), ('1ere', 'A4All', true), ('1ere', 'C', true), ('1ere', 'D', true), ('1ere', 'TI', true),
-- Terminale : toutes les séries
('tle', 'A', true), ('tle', 'A4Esp', true), ('tle', 'A4All', true), ('tle', 'C', true), ('tle', 'D', true), ('tle', 'TI', true)
ON CONFLICT (niveau_code, serie_code) DO NOTHING;

-- Insertion des matières (exemples)
INSERT INTO matieres (nom, code, description, couleur, type) VALUES
('Français', 'FRAN', 'Langue française', '#9C27B0', 'obligatoire'),
('Anglais', 'ANGL', 'Langue anglaise', '#F44336', 'obligatoire'),
('Mathématiques', 'MATH', 'Mathématiques', '#2196F3', 'obligatoire'),
('Histoire-Géographie', 'HIST_GEO', 'Histoire et Géographie', '#795548', 'obligatoire'),
('SVT', 'SVT', 'Sciences de la Vie et de la Terre', '#8BC34A', 'obligatoire'),
('Physique-Chimie', 'PHYS_CHIM', 'Physique et Chimie', '#FF9800', 'obligatoire')
ON CONFLICT (code) DO NOTHING;


-- ===========================================
-- 7. POLITIQUES DE SÉCURITÉ (RLS) - IMPORTANT !
-- ===========================================
-- Activer RLS pour toutes les tables sensibles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.options_reponse ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.epreuves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cours_progression ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_resultats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.epreuve_resultats ENABLE ROW LEVEL SECURITY;
-- Les tables de configuration comme niveaux, series, matieres peuvent être publiques ou restreintes selon besoin

-- Exemples de politiques RLS (À ADAPTER PRÉCISÉMENT À VOS BESOINS)

-- PROFILES
-- Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Allow individual read access to own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- Les utilisateurs peuvent mettre à jour leur propre profil (sauf le rôle, géré par admin/triggers)
CREATE POLICY "Allow individual update access to own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id AND role = (SELECT role FROM public.profiles WHERE id = auth.uid())); -- Empêche de changer son propre rôle

-- Les administrateurs peuvent tout voir et tout faire sur les profils
CREATE POLICY "Allow admin full access to profiles"
ON public.profiles FOR ALL
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'superadmin')))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'superadmin')));


-- CHAPITRES, COURS, QUIZ, EPREUVES (Exemple : lecture publique, écriture par admin/enseignant)
-- Lecture publique pour tous les utilisateurs authentifiés
CREATE POLICY "Allow authenticated read access to educational content"
ON public.chapitres FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated read access to educational content"
ON public.cours FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated read access to educational content"
ON public.quiz FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated read access to educational content"
ON public.epreuves FOR SELECT USING (auth.role() = 'authenticated');
-- (Adapter pour questions et options_reponse si nécessaire)

-- Écriture (INSERT, UPDATE, DELETE) par les admins ou les enseignants
CREATE POLICY "Allow admin/teacher write access to educational content"
ON public.chapitres FOR ALL -- INSERT, UPDATE, DELETE
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')));

CREATE POLICY "Allow admin/teacher write access to educational content"
ON public.cours FOR ALL
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')));

CREATE POLICY "Allow admin/teacher write access to educational content"
ON public.quiz FOR ALL
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')));

CREATE POLICY "Allow admin/teacher write access to educational content"
ON public.epreuves FOR ALL
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')));


-- COURS_PROGRESSION, QUIZ_RESULTATS, EPREUVE_RESULTATS
-- L'utilisateur peut voir et gérer ses propres résultats/progressions
CREATE POLICY "Allow individual access to own progression and results"
ON public.cours_progression FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual access to own progression and results"
ON public.quiz_resultats FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow individual access to own progression and results"
ON public.epreuve_resultats FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Les admins/enseignants peuvent voir les résultats/progressions (utile pour le suivi)
CREATE POLICY "Allow admin/teacher read access to all progression and results"
ON public.cours_progression FOR SELECT
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')));

CREATE POLICY "Allow admin/teacher read access to all progression and results"
ON public.quiz_resultats FOR SELECT
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')));

CREATE POLICY "Allow admin/teacher read access to all progression and results"
ON public.epreuve_resultats FOR SELECT
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'superadmin')));


-- Note: Les politiques pour `questions` et `options_reponse` dépendent de si vous voulez que les étudiants puissent voir les réponses après un quiz, etc.
-- Souvent, la lecture des questions est liée à l'accès au quiz, mais les options correctes peuvent être plus restreintes.

-- Assurez-vous que le rôle `postgres` (utilisé par Supabase en interne pour les opérations SECURITY DEFINER)
-- a les droits nécessaires sur les schémas et tables, ce qui est généralement le cas par défaut.

-- FIN DE LA STRUCTURE --
