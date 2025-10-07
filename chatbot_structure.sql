
-- Table pour stocker les conversations du chatbot
CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- Table pour stocker les messages d'une conversation
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  conversation_id uuid NOT NULL,
  content text NOT NULL,
  role text NOT NULL CHECK (role IN ('user', 'model')),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE
);

-- Activer la Row Level Security pour les nouvelles tables
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Politiques RLS : les utilisateurs ne peuvent voir et gérer que leurs propres conversations et messages
CREATE POLICY "Users can manage their own conversations." ON public.conversations
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage messages in their own conversations." ON public.messages
  FOR ALL USING (auth.uid() = (SELECT user_id FROM public.conversations WHERE id = conversation_id));
