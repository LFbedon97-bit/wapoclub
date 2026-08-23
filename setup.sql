-- Tabla de usuarios (clientes)
CREATE TABLE public.users (
    phone TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    birthdate TEXT,
    stamps INTEGER DEFAULT 0,
    prize TEXT,
    pin TEXT,
    blocked_prizes TEXT[] DEFAULT '{}',
    last_visit TEXT,
    total_cuts INTEGER DEFAULT 0,
    tracked BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla para el historial de visitas (sellos)
CREATE TABLE public.visits_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_phone TEXT REFERENCES public.users(phone) ON DELETE CASCADE,
    date TEXT NOT NULL,
    branch_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla para el historial de premios canjeados
CREATE TABLE public.prizes_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_phone TEXT REFERENCES public.users(phone) ON DELETE CASCADE,
    prize TEXT NOT NULL,
    date TEXT NOT NULL,
    branch_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla para ajustes administrativos
CREATE TABLE public.admin_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- Insertar el PIN de administrador por defecto
INSERT INTO public.admin_settings (key, value) VALUES ('admin_pin', '1234') ON CONFLICT (key) DO NOTHING;
INSERT INTO public.admin_settings (key, value) VALUES ('booking_url', 'https://booksy.com') ON CONFLICT (key) DO NOTHING;

-- Realtime solo para la tabla users, usado para actualizar sellos al instante.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'users'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
  END IF;
END $$;

-- Habilitar Seguridad de Nivel de Fila (RLS) en todas las tablas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visits_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prizes_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS públicas para acceso anónimo (lectura, inserción, actualización, eliminación)
CREATE POLICY "Permitir todo a usuarios anonimos" ON public.users FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Permitir todo a usuarios anonimos" ON public.visits_history FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Permitir todo a usuarios anonimos" ON public.prizes_history FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Permitir todo a usuarios anonimos" ON public.admin_settings FOR ALL TO anon USING (true) WITH CHECK (true);

-- Tabla para reservas (agendar citas)
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_name TEXT NOT NULL,
    client_phone TEXT NOT NULL,
    barber_name TEXT NOT NULL,
    booking_date TEXT NOT NULL,
    booking_time TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Habilitar RLS en bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Política RLS pública para bookings
CREATE POLICY "Permitir todo a usuarios anonimos" ON public.bookings FOR ALL TO anon USING (true) WITH CHECK (true);


