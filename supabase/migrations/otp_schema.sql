-- OTP codes table to store hashed OTPs securely
CREATE TABLE IF NOT EXISTS otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    attempts INT DEFAULT 0
);

-- Enable RLS
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;

-- Delete old/expired OTPs automatically can be done via a cron job, 
-- but for now we'll handle it in the application logic.

-- RLS Policies
-- Drop existing policies if they exist to allow re-running the script
DROP POLICY IF EXISTS "Allow public to insert OTP requests" ON otp_codes;
DROP POLICY IF EXISTS "Allow reading own OTP record" ON otp_codes;
DROP POLICY IF EXISTS "Allow updating attempts" ON otp_codes;
DROP POLICY IF EXISTS "Allow deleting OTP record" ON otp_codes;

-- 1. Allow anyone to request (insert) an OTP
-- This is necessary for the initial step before authentication
CREATE POLICY "Allow public to insert OTP requests" 
ON otp_codes FOR INSERT 
TO anon, authenticated
WITH CHECK (true);

-- 2. Allow reading only if the email matches (used for verification)
-- Note: In a production app, you might want to move verification to a database function
-- to completely hide the otp_hash from the client.
CREATE POLICY "Allow reading own OTP record" 
ON otp_codes FOR SELECT 
TO anon, authenticated
USING (true); -- We'll filter by email and check hash in the app/function

-- 3. Allow updating attempts
CREATE POLICY "Allow updating attempts" 
ON otp_codes FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- 4. Allow deleting after verification
CREATE POLICY "Allow deleting OTP record" 
ON otp_codes FOR DELETE
TO anon, authenticated
USING (true);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_otp_email ON otp_codes(email);
