\set ON_ERROR_STOP on

-- Shared permission groups for the DCID PostgreSQL database.
-- Run as the application/database owner (`dcid`). No passwords are stored here.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dcid_readonly') THEN
        CREATE ROLE dcid_readonly NOLOGIN INHERIT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dcid_editor') THEN
        CREATE ROLE dcid_editor NOLOGIN INHERIT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dcid_maintainer') THEN
        CREATE ROLE dcid_maintainer NOLOGIN INHERIT;
    END IF;
END
$$;

-- Higher roles inherit the permissions of the lower roles.
GRANT dcid_readonly TO dcid_editor;
GRANT dcid_editor TO dcid_maintainer;

GRANT CONNECT ON DATABASE dcid TO dcid_readonly, dcid_editor, dcid_maintainer;
GRANT USAGE ON SCHEMA public TO dcid_readonly, dcid_editor, dcid_maintainer;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO dcid_readonly;

GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dcid_editor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dcid_editor;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO dcid_editor;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dcid_maintainer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dcid_maintainer;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO dcid_maintainer;
GRANT CREATE ON SCHEMA public TO dcid_maintainer;

-- Preserve permissions for tables/sequences/functions created later by Flyway.
ALTER DEFAULT PRIVILEGES FOR ROLE dcid IN SCHEMA public
    GRANT SELECT ON TABLES TO dcid_readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE dcid IN SCHEMA public
    GRANT INSERT, UPDATE, DELETE ON TABLES TO dcid_editor;
ALTER DEFAULT PRIVILEGES FOR ROLE dcid IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO dcid_editor;
ALTER DEFAULT PRIVILEGES FOR ROLE dcid IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO dcid_editor;
ALTER DEFAULT PRIVILEGES FOR ROLE dcid IN SCHEMA public
    GRANT ALL PRIVILEGES ON TABLES TO dcid_maintainer;
ALTER DEFAULT PRIVILEGES FOR ROLE dcid IN SCHEMA public
    GRANT ALL PRIVILEGES ON SEQUENCES TO dcid_maintainer;
ALTER DEFAULT PRIVILEGES FOR ROLE dcid IN SCHEMA public
    GRANT ALL PRIVILEGES ON FUNCTIONS TO dcid_maintainer;

