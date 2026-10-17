-- Om Driving School: initial application schema
-- Password storage is temporarily plaintext for legacy API compatibility.
-- RLS is enabled; no unrestricted public policies are created.

CREATE TABLE IF NOT EXISTS public.drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    license_number TEXT,
    join_date DATE,
    status TEXT NOT NULL DEFAULT 'active',
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'driver',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_name TEXT NOT NULL,
    admission_date DATE DEFAULT CURRENT_DATE,
    status TEXT NOT NULL DEFAULT 'active',
    contact TEXT,
    email TEXT,
    sex TEXT,
    license_type TEXT,
    license_number TEXT,
    fees NUMERIC(12,2) NOT NULL DEFAULT 0,
    advance_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    duration TEXT,
    learning_license TEXT,
    driving_license TEXT,
    start_date DATE,
    additional_notes TEXT,
    rides_completed INTEGER NOT NULL DEFAULT 0,
    total_rides INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.rides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public.admissions(id) ON DELETE SET NULL,
    client_name TEXT,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    car TEXT,
    date DATE,
    time TEXT,
    status TEXT NOT NULL DEFAULT 'completed',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admission_id UUID REFERENCES public.admissions(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_type TEXT NOT NULL DEFAULT 'other',
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purpose TEXT NOT NULL,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for common lookups and joins.
CREATE INDEX IF NOT EXISTS idx_drivers_username
    ON public.drivers(username);

CREATE INDEX IF NOT EXISTS idx_admissions_admission_date
    ON public.admissions(admission_date DESC);

CREATE INDEX IF NOT EXISTS idx_admissions_status
    ON public.admissions(status);

CREATE INDEX IF NOT EXISTS idx_rides_client_id
    ON public.rides(client_id);

CREATE INDEX IF NOT EXISTS idx_rides_driver_id
    ON public.rides(driver_id);

CREATE INDEX IF NOT EXISTS idx_rides_date
    ON public.rides(date DESC);

CREATE INDEX IF NOT EXISTS idx_payments_admission_id
    ON public.payments(admission_id);

CREATE INDEX IF NOT EXISTS idx_payments_payment_date
    ON public.payments(payment_date DESC);

CREATE INDEX IF NOT EXISTS idx_expenses_date
    ON public.expenses(date DESC);

CREATE INDEX IF NOT EXISTS idx_expenses_driver_id
    ON public.expenses(driver_id);

-- Shared updated_at trigger function.
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS set_drivers_updated_at ON public.drivers;
CREATE TRIGGER set_drivers_updated_at
    BEFORE UPDATE ON public.drivers
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_admissions_updated_at ON public.admissions;
CREATE TRIGGER set_admissions_updated_at
    BEFORE UPDATE ON public.admissions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_rides_updated_at ON public.rides;
CREATE TRIGGER set_rides_updated_at
    BEFORE UPDATE ON public.rides
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_payments_updated_at ON public.payments;
CREATE TRIGGER set_payments_updated_at
    BEFORE UPDATE ON public.payments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_expenses_updated_at ON public.expenses;
CREATE TRIGGER set_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Enable Row Level Security on all application tables.
-- No public/anonymous policies are created. Server API routes should use
-- the server-side service-role key, with authorization added to each route.
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
