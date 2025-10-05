-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.activity_logs (
  id bigint NOT NULL DEFAULT nextval('activity_logs_id_seq'::regclass),
  user_id uuid,
  action character varying NOT NULL,
  target_type character varying,
  target_id text,
  details jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT activity_logs_pkey PRIMARY KEY (id),
  CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.chapitres (
  id integer NOT NULL DEFAULT nextval('chapitres_id_seq'::regclass),
  matiere_id integer,
  niveau_code character varying,
  serie_code character varying,
  nom character varying NOT NULL,
  description text,
  ordre integer NOT NULL DEFAULT 0,
  duree_estimee integer,
  objectifs ARRAY,
  prerequis ARRAY,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT chapitres_pkey PRIMARY KEY (id),
  CONSTRAINT chapitres_matiere_id_fkey FOREIGN KEY (matiere_id) REFERENCES public.matieres(id),
  CONSTRAINT chapitres_niveau_code_fkey FOREIGN KEY (niveau_code) REFERENCES public.niveaux(code),
  CONSTRAINT chapitres_serie_code_fkey FOREIGN KEY (serie_code) REFERENCES public.series(code),
  CONSTRAINT chapitres_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.cours (
  id integer NOT NULL DEFAULT nextval('cours_id_seq'::regclass),
  chapitre_id integer,
  nom character varying NOT NULL,
  description text,
  contenu jsonb,
  ordre integer NOT NULL DEFAULT 0,
  duree_estimee integer,
  type character varying DEFAULT 'text_rich'::character varying,
  url_media character varying,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  ordre_par_type jsonb,
  CONSTRAINT cours_pkey PRIMARY KEY (id),
  CONSTRAINT cours_chapitre_id_fkey FOREIGN KEY (chapitre_id) REFERENCES public.chapitres(id),
  CONSTRAINT cours_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.cours_progression (
  id bigint NOT NULL DEFAULT nextval('cours_progression_id_seq'::regclass),
  user_id uuid,
  cours_id integer,
  commence boolean DEFAULT false,
  termine boolean DEFAULT false,
  temps_passe integer DEFAULT 0,
  pourcentage_progression integer DEFAULT 0 CHECK (pourcentage_progression >= 0 AND pourcentage_progression <= 100),
  derniere_position jsonb,
  notes_personnelles text,
  started_at timestamp with time zone,
  completed_at timestamp with time zone,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cours_progression_pkey PRIMARY KEY (id),
  CONSTRAINT cours_progression_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT cours_progression_cours_id_fkey FOREIGN KEY (cours_id) REFERENCES public.cours(id)
);
CREATE TABLE public.epreuve_soumissions (
  id bigint NOT NULL DEFAULT nextval('epreuve_soumissions_id_seq'::regclass),
  user_id uuid,
  epreuve_id integer,
  fichier_soumission_url character varying,
  reponses_texte text,
  score numeric,
  note_sur_bareme_epreuve numeric,
  temps_passe integer,
  statut character varying NOT NULL DEFAULT 'en_cours'::character varying CHECK (statut::text = ANY (ARRAY['en_cours'::character varying, 'soumis'::character varying, 'corrige'::character varying, 'annule'::character varying]::text[])),
  commentaires_etudiant text,
  commentaires_correcteur text,
  corrige_par uuid,
  started_at timestamp with time zone DEFAULT now(),
  submitted_at timestamp with time zone,
  corrected_at timestamp with time zone,
  CONSTRAINT epreuve_soumissions_pkey PRIMARY KEY (id),
  CONSTRAINT epreuve_soumissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT epreuve_soumissions_epreuve_id_fkey FOREIGN KEY (epreuve_id) REFERENCES public.epreuves(id),
  CONSTRAINT epreuve_soumissions_corrige_par_fkey FOREIGN KEY (corrige_par) REFERENCES public.profiles(id)
);
CREATE TABLE public.epreuves (
  id integer NOT NULL DEFAULT nextval('epreuves_id_seq'::regclass),
  matiere_id integer,
  niveau_code character varying,
  nom character varying NOT NULL,
  type character varying NOT NULL,
  annee integer NOT NULL,
  session character varying,
  duree integer NOT NULL,
  bareme numeric DEFAULT 20.0,
  fichier_url character varying,
  corrige_url character varying,
  description text,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  series_codes ARRAY,
  nom_etablissement text,
  ville_etablissement text,
  date_composition_college date,
  statut text NOT NULL DEFAULT 'brouillon'::text CHECK (statut = ANY (ARRAY['brouillon'::text, 'publiee'::text, 'programmee'::text, 'archivee'::text])),
  date_publication_programmee timestamp with time zone,
  CONSTRAINT epreuves_pkey PRIMARY KEY (id),
  CONSTRAINT epreuves_matiere_id_fkey FOREIGN KEY (matiere_id) REFERENCES public.matieres(id),
  CONSTRAINT epreuves_niveau_code_fkey FOREIGN KEY (niveau_code) REFERENCES public.niveaux(code),
  CONSTRAINT epreuves_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.matiere_niveau_serie (
  id integer NOT NULL DEFAULT nextval('matiere_niveau_serie_id_seq'::regclass),
  matiere_id integer,
  niveau_code character varying,
  serie_code character varying,
  coefficient integer NOT NULL DEFAULT 1,
  obligatoire boolean NOT NULL DEFAULT true,
  CONSTRAINT matiere_niveau_serie_pkey PRIMARY KEY (id),
  CONSTRAINT matiere_niveau_serie_matiere_id_fkey FOREIGN KEY (matiere_id) REFERENCES public.matieres(id),
  CONSTRAINT matiere_niveau_serie_niveau_code_fkey FOREIGN KEY (niveau_code) REFERENCES public.niveaux(code),
  CONSTRAINT matiere_niveau_serie_serie_code_fkey FOREIGN KEY (serie_code) REFERENCES public.series(code)
);
CREATE TABLE public.matieres (
  id integer NOT NULL DEFAULT nextval('matieres_id_seq'::regclass),
  nom character varying NOT NULL,
  code character varying NOT NULL UNIQUE,
  description text,
  couleur character varying DEFAULT '#2196F3'::character varying,
  icone character varying DEFAULT 'book'::character varying,
  type character varying NOT NULL CHECK (type::text = ANY (ARRAY['obligatoire'::character varying, 'optionnelle'::character varying, 'facultative'::character varying]::text[])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT matieres_pkey PRIMARY KEY (id)
);
CREATE TABLE public.niveau_serie_config (
  id integer NOT NULL DEFAULT nextval('niveau_serie_config_id_seq'::regclass),
  niveau_code character varying,
  serie_code character varying,
  valide boolean DEFAULT true,
  CONSTRAINT niveau_serie_config_pkey PRIMARY KEY (id),
  CONSTRAINT niveau_serie_config_niveau_code_fkey FOREIGN KEY (niveau_code) REFERENCES public.niveaux(code),
  CONSTRAINT niveau_serie_config_serie_code_fkey FOREIGN KEY (serie_code) REFERENCES public.series(code)
);
CREATE TABLE public.niveaux (
  id integer NOT NULL DEFAULT nextval('niveaux_id_seq'::regclass),
  code character varying NOT NULL UNIQUE,
  nom character varying NOT NULL,
  description text,
  ordre integer NOT NULL,
  CONSTRAINT niveaux_pkey PRIMARY KEY (id)
);
CREATE TABLE public.options_reponse (
  id integer NOT NULL DEFAULT nextval('options_reponse_id_seq'::regclass),
  question_id integer,
  texte text NOT NULL,
  est_correcte boolean DEFAULT false,
  ordre integer NOT NULL DEFAULT 0,
  feedback_specifique text,
  CONSTRAINT options_reponse_pkey PRIMARY KEY (id),
  CONSTRAINT options_reponse_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  full_name text,
  first_name text,
  last_name text,
  avatar_url text,
  role USER-DEFINED NOT NULL DEFAULT 'student'::user_role,
  student_level_code character varying,
  student_serie_code character varying,
  phone_number character varying,
  date_of_birth date,
  teacher_specialty text,
  bio text,
  website_url text,
  is_active boolean DEFAULT true,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT fk_student_level FOREIGN KEY (student_level_code) REFERENCES public.niveaux(code),
  CONSTRAINT fk_student_serie FOREIGN KEY (student_serie_code) REFERENCES public.series(code)
);
CREATE TABLE public.questions (
  id integer NOT NULL DEFAULT nextval('questions_id_seq'::regclass),
  quiz_id integer,
  texte text NOT NULL,
  type character varying NOT NULL CHECK (type::text = ANY (ARRAY['qcm_unique'::character varying, 'qcm_multiple'::character varying, 'vrai_faux'::character varying, 'texte_libre'::character varying, 'numerique'::character varying, 'association'::character varying]::text[])),
  ordre integer NOT NULL DEFAULT 0,
  points numeric DEFAULT 1.0,
  explication text,
  image_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT questions_pkey PRIMARY KEY (id),
  CONSTRAINT questions_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quiz(id)
);
CREATE TABLE public.quiz (
  id integer NOT NULL DEFAULT nextval('quiz_id_seq'::regclass),
  chapitre_id integer,
  matiere_id integer,
  niveau_code character varying,
  serie_code character varying,
  nom character varying NOT NULL,
  description text,
  instructions text,
  temps_limite integer,
  nombre_questions integer DEFAULT 0,
  note_passage numeric DEFAULT 10.0,
  tentatives_max integer DEFAULT 3,
  melanger_questions boolean DEFAULT true,
  melanger_reponses boolean DEFAULT true,
  feedback_immediat boolean DEFAULT false,
  afficher_correction_finale boolean DEFAULT true,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT quiz_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_chapitre_id_fkey FOREIGN KEY (chapitre_id) REFERENCES public.chapitres(id),
  CONSTRAINT quiz_matiere_id_fkey FOREIGN KEY (matiere_id) REFERENCES public.matieres(id),
  CONSTRAINT quiz_niveau_code_fkey FOREIGN KEY (niveau_code) REFERENCES public.niveaux(code),
  CONSTRAINT quiz_serie_code_fkey FOREIGN KEY (serie_code) REFERENCES public.series(code),
  CONSTRAINT quiz_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.quiz_sessions (
  id bigint NOT NULL DEFAULT nextval('quiz_sessions_id_seq'::regclass),
  user_id uuid,
  quiz_id integer,
  tentative integer NOT NULL DEFAULT 1,
  score numeric NOT NULL,
  note_sur_bareme_quiz numeric,
  temps_passe integer NOT NULL,
  termine boolean DEFAULT false,
  reussi boolean,
  reponses_utilisateur jsonb,
  started_at timestamp with time zone DEFAULT now(),
  completed_at timestamp with time zone,
  CONSTRAINT quiz_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT quiz_sessions_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quiz(id)
);
CREATE TABLE public.series (
  id integer NOT NULL DEFAULT nextval('series_id_seq'::regclass),
  code character varying NOT NULL UNIQUE,
  nom character varying NOT NULL,
  description text,
  type character varying NOT NULL,
  CONSTRAINT series_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_chapter_progress (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  chapitre_id integer NOT NULL,
  is_completed boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_chapter_progress_pkey PRIMARY KEY (id),
  CONSTRAINT user_chapter_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_chapter_progress_chapitre_id_fkey FOREIGN KEY (chapitre_id) REFERENCES public.chapitres(id)
);