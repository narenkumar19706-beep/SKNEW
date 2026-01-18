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

CREATE TABLE IF NOT EXISTS sos (
  id uuid PRIMARY KEY,
  device_id uuid NOT NULL,
  status text NOT NULL,
  district text,
  last_lat double precision,
  last_lng double precision,
  last_accuracy double precision,
  last_location_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE TABLE IF NOT EXISTS sos_updates (
  id uuid PRIMARY KEY,
  sos_id uuid NOT NULL,
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sos_locations (
  id uuid PRIMARY KEY,
  sos_id uuid NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  accuracy double precision,
  captured_at timestamptz NOT NULL DEFAULT now()
);
