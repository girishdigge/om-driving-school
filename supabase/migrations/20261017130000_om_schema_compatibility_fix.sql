-- Om Driving School: forward-only schema compatibility fix.
-- Does not drop tables, delete rows, or modify the legacy migration archive.

BEGIN;

-- 1. Drivers: restore the legacy total_rides field required by CSV imports.
ALTER TABLE public.drivers
    ADD COLUMN IF NOT EXISTS total_rides INTEGER DEFAULT 0;

UPDATE public.drivers
SET total_rides = 0
WHERE total_rides IS NULL;

ALTER TABLE public.drivers
    ALTER COLUMN total_rides SET DEFAULT 0,
    ALTER COLUMN total_rides SET NOT NULL;

ALTER TABLE public.drivers
    ALTER COLUMN join_date SET DEFAULT CURRENT_DATE;

-- Preserve nullable emails for application compatibility, but enforce
-- uniqueness for non-NULL email values, as in the established schema.
CREATE UNIQUE INDEX IF NOT EXISTS drivers_email_unique_idx
    ON public.drivers (email)
    WHERE email IS NOT NULL;

-- 2. Rides: require the legacy identifying fields and support the
-- application's pending/completed/cancelled statuses.
UPDATE public.rides
SET client_name = ''
WHERE client_name IS NULL;

UPDATE public.rides
SET date = CURRENT_DATE
WHERE date IS NULL;

ALTER TABLE public.rides
    ALTER COLUMN client_name SET NOT NULL,
    ALTER COLUMN date SET NOT NULL,
    ALTER COLUMN date SET DEFAULT CURRENT_DATE,
    ALTER COLUMN status SET DEFAULT 'completed';

-- Do not retain a legacy check that permits only completed rides.
ALTER TABLE public.rides
    DROP CONSTRAINT IF EXISTS rides_status_check;

ALTER TABLE public.rides
    ADD CONSTRAINT rides_status_check
    CHECK (status IN ('pending', 'completed', 'cancelled'));

-- 3. Payments: every payment must reference an admission.
-- This is safe for the currently empty Om tables.
ALTER TABLE public.payments
    ALTER COLUMN admission_id SET NOT NULL;

ALTER TABLE public.payments
    ALTER COLUMN payment_type DROP DEFAULT;

ALTER TABLE public.payments
    DROP CONSTRAINT IF EXISTS payments_payment_type_check;

ALTER TABLE public.payments
    ADD CONSTRAINT payments_payment_type_check
    CHECK (
        payment_type IN (
            'advance',
            'installment_1',
            'installment_2',
            'installment_3',
            'other'
        )
    );

-- 4. Keep Row Level Security enabled. Do not add public access policies.
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

COMMIT;
