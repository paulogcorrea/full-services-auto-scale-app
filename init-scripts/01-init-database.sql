-- Database initialization script for Nomad Services Backend API
-- This script will be executed when the PostgreSQL container starts for the first time

-- Create extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- Create database user if it doesn't exist
DO
$do$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'nomad_services') THEN
      CREATE USER nomad_services WITH ENCRYPTED PASSWORD 'secure_password';
   END IF;
END
$do$;

-- Grant privileges to the nomad_services user
GRANT ALL PRIVILEGES ON DATABASE nomad_services TO nomad_services;
GRANT ALL PRIVILEGES ON SCHEMA public TO nomad_services;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO nomad_services;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO nomad_services;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO nomad_services;

-- Create some useful views for monitoring
CREATE OR REPLACE VIEW db_stats AS
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation,
    most_common_vals::text,
    most_common_freqs
FROM pg_stats
WHERE schemaname = 'public';

-- Create a simple function to get database size
CREATE OR REPLACE FUNCTION get_database_size()
RETURNS TEXT AS $$
BEGIN
    RETURN pg_size_pretty(pg_database_size(current_database()));
END;
$$ LANGUAGE plpgsql;

-- Log successful initialization
INSERT INTO pg_stat_activity (query) VALUES ('Database initialization completed successfully');

-- Print completion message
DO $$
BEGIN
    RAISE NOTICE 'Nomad Services database initialized successfully';
END
$$;
