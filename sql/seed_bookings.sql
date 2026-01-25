-- Seed booking row for testing
INSERT INTO bookings (property_id, user_id, visit_date, status)
VALUES (
  'b1ffcf70-2ddb-4791-a4c0-2cbbf21aa97b',
  auth.uid(),
  '2026-02-01',
  'pending'
);

-- Notes:
-- - You can run this in the Supabase SQL editor (recommended) where auth.uid() is available
--   or replace auth.uid() with a real user UUID and run via psql against your DB.
-- - To run locally with psql, replace auth.uid() with the actual user id string.
