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

-- Table des utilisateurs
CREATE TABLE users (
    uid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('etudiant', 'enseignant', 'admin')),
    nom VARCHAR(100),
    prenom VARCHAR(100),
    niveau_code VARCHAR(10) REFERENCES niveaux(code),
    serie_code VARCHAR(10) REFERENCES series(code),
    telephone VARCHAR(20),
    date_naissance DATE,
    email_verified BOOLEAN DEFAULT false,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Contrainte pour vérifier les combinaisons niveau/série pour les étudiants
    CONSTRAINT valid_niveau_serie_etudiant
        CHECK (
            role != 'etudiant' OR
            (niveau_code IS NOT NULL AND serie_code IS NOT NULL)
        )
);

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
    created_by UUID REFERENCES users(uid)
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
    created_by UUID REFERENCES users(uid)
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
    created_by UUID REFERENCES users(uid)
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
    created_by UUID REFERENCES users(uid)
);

-- ===========================================
-- 4. TABLES DE PROGRESSION ET RÉSULTATS
-- ===========================================

-- Progression des cours
CREATE TABLE cours_progression (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(uid) ON DELETE CASCADE,
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
    user_id UUID REFERENCES users(uid) ON DELETE CASCADE,
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
    user_id UUID REFERENCES users(uid) ON DELETE CASCADE,
    epreuve_id INTEGER REFERENCES epreuves(id) ON DELETE CASCADE,
    score DECIMAL(5,2),
    note_sur_20 DECIMAL(5,2),
    temps_passe INTEGER, -- en secondes
    termine BOOLEAN DEFAULT false,
    commentaires TEXT,
    corrige_par UUID REFERENCES users(uid), -- Enseignant qui a corrigé
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    corrected_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, epreuve_id)
);

-- ===========================================
-- 5. DONNÉES INITIALES
-- ===========================================

-- Insertion des niveaux
INSERT INTO niveaux (code, nom, description, ordre) VALUES
('3eme', 'Troisième', 'Classe de Troisième', 1),
('1ere', 'Première', 'Classe de Première', 2),
('tle', 'Terminale', 'Classe de Terminale', 3);

-- Insertion des séries
INSERT INTO series (code, nom, description, type) VALUES
('A', 'Série A', 'Série Littéraire', 'litteraire'),
('A4Esp', 'Série A4 Espagnol', 'Série Littéraire spécialisée Espagnol', 'linguistique'),
('A4All', 'Série A4 Allemand', 'Série Littéraire spécialisée Allemand', 'linguistique'),
('A4ITA', 'Série A4 Italien', 'Série Littéraire spécialisée Italien', 'linguistique'),
('A4CHI', 'Série A4 Chinois', 'Série Littéraire spécialisée Chinois', 'linguistique'),
('C', 'Série C', 'Série Scientifique Mathématiques-Physique', 'scientifique'),
('D', 'Série D', 'Série Scientifique Mathématiques-SVT', 'scientifique'),
('TI', 'Série TI', 'Série Technologie Industrielle', 'technique');

-- Configuration des combinaisons niveau/série valides
INSERT INTO niveau_serie_config (niveau_code, serie_code, valide) VALUES
-- 3ème : que série A
('3eme', 'A', true),
-- 1ère : toutes les séries
('1ere', 'A', true),
('1ere', 'A4Esp', true),
('1ere', 'A4All', true),
('1ere', 'A4ITA', true),
('1ere', 'A4CHI', true),
('1ere', 'C', true),
('1ere', 'D', true),
('1ere', 'TI', true),
-- Terminale : toutes les séries
('tle', 'A', true),
('tle', 'A4Esp', true),
('tle', 'A4All', true),
('tle', 'A4ITA', true),
('tle', 'A4CHI', true),
('tle', 'C', true),
('tle', 'D', true),
('tle', 'TI', true);

-- Insertion des matières
INSERT INTO matieres (nom, code, description, couleur, type) VALUES
-- Matières obligatoires communes
('Français', 'FRAN', 'Langue française', '#9C27B0', 'obligatoire'),
('Anglais', 'ANGL', 'Langue anglaise', '#F44336', 'obligatoire'),
('Mathématiques', 'MATH', 'Mathématiques', '#2196F3', 'obligatoire'),
('Histoire-Géographie', 'HIST_GEO', 'Histoire et Géographie', '#795548', 'obligatoire'),
('EPS', 'EPS', 'Éducation Physique et Sportive', '#FF5722', 'obligatoire'),
('ECM', 'ECM', 'Éducation à la Citoyenneté et à la Morale', '#FFC107', 'obligatoire'),
('Informatique', 'INFO', 'Informatique', '#3F51B5', 'obligatoire'),
('SVT', 'SVT', 'Sciences de la Vie et de la Terre', '#8BC34A', 'obligatoire'),
('Philosophie', 'PHIL', 'Philosophie', '#009688', 'obligatoire'),

-- Matières scientifiques
('PCT', 'PCT', 'Physique-Chimie-Technologie', '#FF9800', 'obligatoire'),
('Physique', 'PHYS', 'Physique', '#FF9800', 'obligatoire'),
('Chimie', 'CHIM', 'Chimie', '#4CAF50', 'obligatoire'),

-- Langues vivantes (optionnelles pour certains niveaux)
('Espagnol', 'ESP', 'Langue espagnole', '#E91E63', 'optionnelle'),
('Allemand', 'ALL', 'Langue allemande', '#FFEB3B', 'optionnelle'),
('Italien', 'ITA', 'Langue italienne', '#FF9800', 'optionnelle'),
('Chinois', 'CHI', 'Langue chinoise', '#F44336', 'optionnelle'),

-- Matières facultatives
('Musique', 'MUS', 'Éducation musicale', '#9C27B0', 'facultative'),
('Dessin', 'DESS', 'Arts plastiques', '#FF9800', 'facultative'),
('Théâtre', 'THEAT', 'Art dramatique', '#673AB7', 'facultative'),
('ESF', 'ESF', 'Économie Sociale et Familiale', '#00BCD4', 'facultative');

-- ===========================================
-- 6. POLITIQUES DE SÉCURITÉ (RLS)
-- ===========================================

-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE cours ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE options_reponse ENABLE ROW LEVEL SECURITY;
ALTER TABLE epreuves ENABLE ROW LEVEL SECURITY;
ALTER TABLE cours_progression ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_resultats ENABLE ROW LEVEL SECURITY;
ALTER TABLE epreuve_resultats ENABLE ROW LEVEL SECURITY;

-- Politiques pour les utilisateurs
CREATE POLICY "Les utilisateurs peuvent voir leur propre profil"
    ON users FOR SELECT
    USING (auth.uid() = uid);

CREATE POLICY "Les utilisateurs peuvent modifier leur propre profil"
    ON users FOR UPDATE
    USING (auth.uid() = uid);

CREATE POLICY "Les admins peuvent tout voir sur les utilisateurs"
    ON users FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE uid = auth.uid() AND role = 'admin'
        )
    );

-- Politiques pour le contenu éducatif (lecture publique, modification par les enseignants/admins)
CREATE POLICY "Contenu visible par tous"
    ON chapitres FOR SELECT
    TO authenticated
    USING (actif = true);

CREATE POLICY "Enseignants et admins peuvent créer du contenu"
    ON chapitres FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE uid = auth.uid() AND role IN ('enseignant', 'admin')
        )
    );

-- Politiques similaires pour cours, quiz, questions, etc.
CREATE POLICY "Cours visibles par tous"
    ON cours FOR SELECT
    TO authenticated
    USING (actif = true);

CREATE POLICY "Quiz visibles par tous"
    ON quiz FOR SELECT
    TO authenticated
    USING (actif = true);

CREATE POLICY "Questions visibles par tous"
    ON questions FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Options visibles par tous"
    ON options_reponse FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Épreuves visibles par tous"
    ON epreuves FOR SELECT
    TO authenticated
    USING (actif = true);

-- Politiques pour la progression (les utilisateurs ne voient que leurs données)
CREATE POLICY "Progression personnelle uniquement"
    ON cours_progression FOR ALL
    USING (user_id = auth.uid());

CREATE POLICY "Résultats quiz personnels uniquement"
    ON quiz_resultats FOR ALL
    USING (user_id = auth.uid());

CREATE POLICY "Résultats épreuves personnels uniquement"
    ON epreuve_resultats FOR ALL
    USING (user_id = auth.uid());

-- ===========================================
-- 7. FONCTIONS UTILITAIRES
-- ===========================================

-- Fonction pour calculer la progression d'un chapitre
CREATE OR REPLACE FUNCTION calculer_progression_chapitre(
    p_user_id UUID,
    p_chapitre_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    total_cours INTEGER;
    cours_termines INTEGER;
    progression INTEGER;
BEGIN
    -- Compter le total de cours dans le chapitre
    SELECT COUNT(*) INTO total_cours
    FROM cours
    WHERE chapitre_id = p_chapitre_id AND actif = true;

    -- Compter les cours terminés par l'utilisateur
    SELECT COUNT(*) INTO cours_termines
    FROM cours_progression cp
    JOIN cours c ON cp.cours_id = c.id
    WHERE cp.user_id = p_user_id
    AND c.chapitre_id = p_chapitre_id
    AND cp.termine = true;

    -- Calculer le pourcentage
    IF total_cours = 0 THEN
        progression := 0;
    ELSE
        progression := ROUND((cours_termines::DECIMAL / total_cours::DECIMAL) * 100);
    END IF;

    RETURN progression;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les matières d'un étudiant selon son niveau/série
CREATE OR REPLACE FUNCTION get_matieres_etudiant(
    p_niveau_code VARCHAR(10),
    p_serie_code VARCHAR(10)
) RETURNS TABLE (
    id INTEGER,
    nom VARCHAR(100),
    code VARCHAR(20),
    couleur VARCHAR(7),
    type VARCHAR(20),
    coefficient INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id,
        m.nom,
        m.code,
        m.couleur,
        m.type,
        mns.coefficient
    FROM matieres m
    JOIN matiere_niveau_serie mns ON m.id = mns.matiere_id
    WHERE mns.niveau_code = p_niveau_code
    AND mns.serie_code = p_serie_code
    ORDER BY m.type, m.nom;
END;
$$ LANGUAGE plpgsql;