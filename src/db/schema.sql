CREATE TABLE IF NOT EXISTS devices (
  id uuid PRIMARY KEY,
  name text,
  phone text,
  address text,
  district text,
  fcm_token text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
