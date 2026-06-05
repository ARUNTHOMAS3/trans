--
-- PostgreSQL database dump
--

\restrict Ci4cHKCF19zVpEhkZrKTKIZwq3fzmpHLqR5UuiUYHfLTSnbNWvBN12T1jmU8fyI

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: drizzle; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA drizzle;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: supabase_migrations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA supabase_migrations;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: hypopg; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hypopg WITH SCHEMA extensions;


--
-- Name: EXTENSION hypopg; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hypopg IS 'Hypothetical indexes for PostgreSQL';


--
-- Name: index_advisor; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS index_advisor WITH SCHEMA extensions;


--
-- Name: EXTENSION index_advisor; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION index_advisor IS 'Query index advisor';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: account_group_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_group_enum AS ENUM (
    'Assets',
    'Liabilities',
    'Equity',
    'Income',
    'Expenses'
);


--
-- Name: account_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_type AS ENUM (
    'sales',
    'purchase',
    'inventory',
    'expense',
    'asset'
);


--
-- Name: account_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_type_enum AS ENUM (
    'Bank',
    'Cash',
    'Accounts Receivable',
    'Stock',
    'Payment Clearing Account',
    'Other Current Asset',
    'Fixed Asset',
    'Non Current Asset',
    'Intangible Asset',
    'Deferred Tax Asset',
    'Other Asset',
    'Credit Card',
    'Accounts Payable',
    'Other Current Liability',
    'Overseas Tax Payable',
    'Non Current Liability',
    'Deferred Tax Liability',
    'Other Liability',
    'Equity',
    'Income',
    'Other Income',
    'Cost Of Goods Sold',
    'Expense',
    'Other Expense'
);


--
-- Name: accounts_contact_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.accounts_contact_type AS ENUM (
    'customer',
    'vendor'
);


--
-- Name: accounts_journal_template_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.accounts_journal_template_type AS ENUM (
    'debit',
    'credit'
);


--
-- Name: accounts_manual_journal_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.accounts_manual_journal_status AS ENUM (
    'draft',
    'published'
);


--
-- Name: accounts_reporting_method; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.accounts_reporting_method AS ENUM (
    'accrual_and_cash',
    'accrual_only',
    'cash_only'
);


--
-- Name: adjustment_mode; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.adjustment_mode AS ENUM (
    'quantity',
    'value'
);


--
-- Name: branch_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.branch_type AS ENUM (
    'FOCO',
    'COCO',
    'FICO',
    'FOFO',
    'WAREHOUSE'
);


--
-- Name: challan_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.challan_type AS ENUM (
    'supply',
    'job_work',
    'other'
);


--
-- Name: composite_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.composite_type AS ENUM (
    'assembly',
    'kit'
);


--
-- Name: hsn_sac_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.hsn_sac_type AS ENUM (
    'HSN',
    'SAC'
);


--
-- Name: inventory_adjustment_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.inventory_adjustment_status AS ENUM (
    'draft',
    'submitted',
    'approved',
    'rejected',
    'cancelled'
);


--
-- Name: inventory_adjustment_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.inventory_adjustment_type AS ENUM (
    'quantity',
    'value'
);


--
-- Name: inventory_valuation_method; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.inventory_valuation_method AS ENUM (
    'FIFO',
    'LIFO',
    'Weighted Average',
    'Specific Identification',
    'FEFO'
);


--
-- Name: location_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.location_type AS ENUM (
    'business',
    'warehouse'
);


--
-- Name: product_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.product_type AS ENUM (
    'goods',
    'service'
);


--
-- Name: status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.status AS ENUM (
    'draft',
    'active',
    'inactive',
    'sent',
    'paid',
    'void',
    'open',
    'delivered',
    'invoiced',
    'returned',
    'assembled',
    'not_shipped',
    'shipped'
);


--
-- Name: tax_preference; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tax_preference AS ENUM (
    'taxable',
    'non-taxable',
    'exempt'
);


--
-- Name: tax_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tax_type AS ENUM (
    'IGST',
    'CGST',
    'SGST'
);


--
-- Name: unit_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.unit_type AS ENUM (
    'count',
    'weight',
    'volume',
    'length',
    'time',
    'temperature',
    'speed',
    'area',
    'energy',
    'pressure',
    'digital_storage'
);


--
-- Name: vendor_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.vendor_type AS ENUM (
    'manufacturer',
    'distributor',
    'wholesaler'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: graphql(text, text, jsonb, jsonb); Type: FUNCTION; Schema: graphql_public; Owner: -
--

CREATE FUNCTION graphql_public.graphql("operationName" text DEFAULT NULL::text, query text DEFAULT NULL::text, variables jsonb DEFAULT NULL::jsonb, extensions jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  BEGIN
      RAISE DEBUG 'PgBouncer auth request: %', p_usename;

      RETURN QUERY
      SELECT
          rolname::text,
          CASE WHEN rolvaliduntil < now()
              THEN null
              ELSE rolpassword::text
          END
      FROM pg_authid
      WHERE rolname=$1 and rolcanlogin;
  END;
  $_$;


--
-- Name: apply_inventory_adjustment_batch_txn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_inventory_adjustment_batch_txn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  delta numeric;
  branch_row_id uuid;
  current_stock_val numeric;
  reserved_stock_val numeric;
  adjustment_exists boolean;
BEGIN
  IF NEW.ref_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS(
    SELECT 1
    FROM public.inventory_adjustments
    WHERE id = NEW.ref_id
      AND entity_id = NEW.entity_id
  ) INTO adjustment_exists;

  -- Only process inventory adjustments and ignore other module writes.
  IF NOT adjustment_exists THEN
    RETURN NEW;
  END IF;

  delta := COALESCE(NEW.qty_in, 0) - COALESCE(NEW.qty_out, 0);

  -- Keep branch_inventory aligned for list-level stock visibility.
  SELECT id, current_stock, reserved_stock
    INTO branch_row_id, current_stock_val, reserved_stock_val
  FROM public.branch_inventory
  WHERE entity_id = NEW.entity_id
    AND product_id = NEW.product_id
  ORDER BY updated_at DESC
  LIMIT 1;

  IF branch_row_id IS NULL THEN
    INSERT INTO public.branch_inventory (
      entity_id, product_id, current_stock, reserved_stock, available_stock,
      min_stock_level, max_stock_level, last_stock_update, created_at, updated_at
    ) VALUES (
      NEW.entity_id, NEW.product_id, GREATEST(0, delta), 0, GREATEST(0, delta),
      0, 0, now(), now(), now()
    );
  ELSE
    UPDATE public.branch_inventory
    SET current_stock = GREATEST(0, COALESCE(current_stock_val, 0) + delta),
        available_stock = GREATEST(0, COALESCE(current_stock_val, 0) + delta - COALESCE(reserved_stock_val, 0)),
        last_stock_update = now(),
        updated_at = now()
    WHERE id = branch_row_id;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: apply_purchase_receive_stock(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_purchase_receive_stock(p_receive_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  r record;
  v_batch_id uuid;
  v_qty numeric;
  v_wh uuid;
  v_bin uuid;
begin
  for r in
    select
      pr.id as purchase_receive_id,
      pr.purchase_receive_number,
      pr.received_date,
      pr.entity_id,
      pri.id as purchase_receive_item_id,
      pri.item_id as product_id,
      coalesce(pri.warehouse_id, pr.warehouse_id, prib.warehouse_id) as warehouse_id,
      coalesce(pri.bin_id, pr.transaction_bin_id, prib.bin_id) as bin_id,
      prib.batch_no,
      prib.unit_pack,
      prib.mrp,
      prib.ptr,
      prib.quantity,
      prib.foc_qty,
      prib.manufacture_batch_number,
      prib.manufacture_date,
      prib.expiry_date
    from public.purchase_receives pr
    join public.purchase_receive_items pri
      on pri.purchase_receive_id = pr.id
    join public.purchase_receive_item_batches prib
      on prib.purchase_receive_item_id = pri.id
    where pr.id = p_receive_id
      and pr.status = 'received'
  loop
    v_qty := coalesce(r.quantity, 0) + coalesce(r.foc_qty, 0);
    v_wh := r.warehouse_id;
    v_bin := r.bin_id;

    if r.product_id is null then
      raise exception 'purchase_receive_item % is missing product_id', r.purchase_receive_item_id;
    end if;

    if v_wh is null then
      raise exception 'purchase_receive % cannot post stock without warehouse_id', r.purchase_receive_id;
    end if;

    if v_bin is null then
      raise exception 'purchase_receive % cannot post stock without bin_id', r.purchase_receive_id;
    end if;

    select bm.id
      into v_batch_id
    from public.batch_master bm
    where bm.product_id = r.product_id
      and bm.batch_no = r.batch_no
      and bm.expiry_date = r.expiry_date
    limit 1;

    if v_batch_id is null then
      insert into public.batch_master (
        product_id,
        batch_no,
        expiry_date,
        unit_pack,
        is_manufacture_details,
        manufacture_batch_number,
        manufacture_exp,
        is_active,
        created_by_entity_id,
        source_type
      )
      values (
        r.product_id,
        r.batch_no,
        r.expiry_date,
        r.unit_pack,
        case
          when r.manufacture_batch_number is not null or r.manufacture_date is not null then true
          else false
        end,
        r.manufacture_batch_number,
        r.manufacture_date,
        true,
        r.entity_id,
        'purchase_receive'
      )
      returning id into v_batch_id;
    end if;

    insert into public.batch_stock_layers (
      batch_id,
      product_id,
      entity_id,
      warehouse_id,
      bin_id,
      mrp,
      ptr,
      expiry_date,
      qty,
      foc_qty,
      ref_id,
      ref_type
    )
    values (
      v_batch_id,
      r.product_id,
      r.entity_id,
      v_wh,
      v_bin,
      r.mrp,
      r.ptr,
      r.expiry_date,
      coalesce(r.quantity, 0),
      coalesce(r.foc_qty, 0),
      r.purchase_receive_id,
      'PURCHASE_RECEIVE'
    );

    insert into public.batch_transactions (
      batch_id,
      product_id,
      entity_id,
      warehouse_id,
      bin_id,
      transaction_type,
      ref_id,
      ref_type,
      ref_no,
      qty_in,
      qty_out,
      rate,
      trans_date
    )
    values (
      v_batch_id,
      r.product_id,
      r.entity_id,
      v_wh,
      v_bin,
      'IN',
      r.purchase_receive_id,
      'PURCHASE_RECEIVE',
      r.purchase_receive_number,
      v_qty,
      0,
      r.ptr,
      now()
    );

    insert into public.branch_inventory (
      entity_id,
      product_id,
      current_stock,
      reserved_stock,
      batch_no,
      expiry_date,
      last_stock_update
    )
    values (
      r.entity_id,
      r.product_id,
      v_qty::integer,
      0,
      r.batch_no,
      r.expiry_date,
      now()
    )
    on conflict (entity_id, product_id, batch_no)
    do update set
      current_stock = public.branch_inventory.current_stock + excluded.current_stock,
      expiry_date = excluded.expiry_date,
      last_stock_update = now(),
      updated_at = now();
  end loop;
end;
$$;


--
-- Name: archive_audit_logs_monthly(interval); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.archive_audit_logs_monthly(p_keep_recent_interval interval DEFAULT '1 mon'::interval) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_cutoff timestamp with time zone;
  v_moved_count integer := 0;
BEGIN
  v_cutoff := date_trunc('month', now() - p_keep_recent_interval);

  WITH moved_rows AS (
    DELETE FROM public.audit_logs
    WHERE created_at < v_cutoff
    RETURNING *
  )
  INSERT INTO public.audit_logs_archive (
    id,
    table_name,
    schema_name,
    record_id,
    record_pk,
    action,
    old_values,
    new_values,
    user_id,
    created_at,
    org_id,
    outlet_id,
    actor_name,
    changed_columns,
    txid,
    source,
    module_name,
    request_id,
    archived_at
  )
  SELECT
    id,
    table_name,
    schema_name,
    record_id,
    record_pk,
    action,
    old_values,
    new_values,
    user_id,
    created_at,
    org_id,
    outlet_id,
    actor_name,
    changed_columns,
    txid,
    source,
    module_name,
    request_id,
    now()
  FROM moved_rows;

  GET DIAGNOSTICS v_moved_count = ROW_COUNT;
  RETURN v_moved_count;
END;
$$;


--
-- Name: attach_audit_triggers_to_new_tables(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attach_audit_triggers_to_new_tables() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
  v_schema text;
  v_table text;
BEGIN
  FOR obj IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
  LOOP
    IF obj.object_type = 'table' THEN
      v_schema := obj.schema_name;

      IF obj.schema_name IS NOT NULL AND obj.object_identity IS NOT NULL THEN
        v_table := regexp_replace(obj.object_identity, '^.*\.', '');
        v_table := replace(v_table, '"', '');

        IF v_schema = 'public'
           AND v_table NOT IN ('audit_logs', 'audit_logs_archive') THEN

          EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_audit_row ON %I.%I;',
            v_schema, v_table
          );

          EXECUTE format(
            'CREATE TRIGGER trg_audit_row
             AFTER INSERT OR UPDATE OR DELETE ON %I.%I
             FOR EACH ROW
             EXECUTE FUNCTION public.audit_row_changes();',
            v_schema, v_table
          );

          EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_audit_truncate ON %I.%I;',
            v_schema, v_table
          );

          EXECUTE format(
            'CREATE TRIGGER trg_audit_truncate
             AFTER TRUNCATE ON %I.%I
             FOR EACH STATEMENT
             EXECUTE FUNCTION public.audit_table_truncate();',
            v_schema, v_table
          );
        END IF;
      END IF;
    END IF;
  END LOOP;
END;
$$;


--
-- Name: audit_changed_columns(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_changed_columns(p_old jsonb, p_new jsonb) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT COALESCE(array_agg(key ORDER BY key), ARRAY[]::text[])
  FROM (
    SELECT key
    FROM jsonb_object_keys(COALESCE(p_old, '{}'::jsonb) || COALESCE(p_new, '{}'::jsonb)) AS key
    WHERE COALESCE(p_old -> key, 'null'::jsonb) IS DISTINCT FROM COALESCE(p_new -> key, 'null'::jsonb)
  ) s;
$$;


--
-- Name: audit_row_changes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_row_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN RETURN NULL; END; $$;


--
-- Name: audit_table_truncate(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_table_truncate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN RETURN NULL; END; $$;


--
-- Name: disable_rls_on_new_table(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.disable_rls_on_new_table() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj RECORD;
BEGIN
  FOR obj IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag = 'CREATE TABLE'
      AND schema_name = 'public'
  LOOP
    EXECUTE format('ALTER TABLE %s DISABLE ROW LEVEL SECURITY;', obj.object_identity);
  END LOOP;
END;
$$;


--
-- Name: pgrst_watch(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pgrst_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NOTIFY pgrst, 'reload schema';
END;
$$;


--
-- Name: prevent_audit_log_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_audit_log_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only';
END;
$$;


--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


--
-- Name: set_inventory_adjustment_attachments_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_inventory_adjustment_attachments_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: set_product_pack_sizes_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_product_pack_sizes_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: set_product_warehouse_stocks_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_product_warehouse_stocks_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: sync_branch_to_entity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_branch_to_entity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_parent_entity_id uuid;
BEGIN
    -- Resolve parent_id from the master table
    IF NEW.parent_branch_id IS NOT NULL THEN
        SELECT id INTO v_parent_entity_id FROM public.organisation_branch_master WHERE type = 'BRANCH' AND ref_id = NEW.parent_branch_id;
    ELSE
        SELECT id INTO v_parent_entity_id FROM public.organisation_branch_master WHERE type = 'ORG' AND ref_id = NEW.org_id;
    END IF;

    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.organisation_branch_master (name, type, ref_id, parent_id, is_active)
        VALUES (NEW.name, 'BRANCH', NEW.id, v_parent_entity_id, NEW.is_active)
        ON CONFLICT (type, ref_id) DO UPDATE SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, is_active = EXCLUDED.is_active;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.organisation_branch_master
        SET name = NEW.name, parent_id = v_parent_entity_id, is_active = NEW.is_active
        WHERE type = 'BRANCH' AND ref_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: sync_organization_to_entity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_organization_to_entity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.organisation_branch_master (name, type, ref_id, is_active)
        VALUES (NEW.name, 'ORG', NEW.id, NEW.is_active)
        ON CONFLICT (type, ref_id) DO UPDATE SET name = EXCLUDED.name, is_active = EXCLUDED.is_active;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.organisation_branch_master
        SET name = NEW.name, is_active = NEW.is_active
        WHERE type = 'ORG' AND ref_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: update_outlets_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_outlets_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_settings_branch_users_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_settings_branch_users_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: update_settings_branding_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_settings_branding_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_settings_locations_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_settings_locations_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_settings_user_location_access_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_settings_user_location_access_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- Name: update_users_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_users_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: zerpai_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zerpai_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
    -- Regclass of the table e.g. public.notes
    entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

    -- I, U, D, T: insert, update ...
    action realtime.action = (
        case wal ->> 'action'
            when 'I' then 'INSERT'
            when 'U' then 'UPDATE'
            when 'D' then 'DELETE'
            else 'ERROR'
        end
    );

    -- Is row level security enabled for the table
    is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

    subscriptions realtime.subscription[] = array_agg(subs)
        from
            realtime.subscription subs
        where
            subs.entity = entity_
            -- Filter by action early - only get subscriptions interested in this action
            -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
            and (subs.action_filter = '*' or subs.action_filter = action::text);

    -- Subscription vars
    working_role regrole;
    working_selected_columns text[];
    claimed_role regrole;
    claims jsonb;

    subscription_id uuid;
    subscription_has_access bool;
    visible_to_subscription_ids uuid[] = '{}';

    -- structured info for wal's columns
    columns realtime.wal_column[];
    -- previous identity values for update/delete
    old_columns realtime.wal_column[];

    error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

    -- Primary jsonb output for record
    output jsonb;

    -- Loop record for iterating unique roles (outer loop)
    role_record record;
    -- Loop record for iterating unique selected_columns within a role (inner loop)
    cols_record record;
    -- Subscription ids visible at the role level (before fanning out by selected_columns)
    visible_role_sub_ids uuid[] = '{}';

begin
    perform set_config('role', null, true);

    columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'columns') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    old_columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'identity') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    for role_record in
        select claims_role
        from (select distinct claims_role from unnest(subscriptions)) t
        order by claims_role::text
    loop
        working_role := role_record.claims_role;

        -- Update `is_selectable` for columns and old_columns (once per role)
        columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(columns) c;

        old_columns =
                array_agg(
                    (
                        c.name,
                        c.type_name,
                        c.type_oid,
                        c.value,
                        c.is_pkey,
                        pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                    )::realtime.wal_column
                )
                from
                    unnest(old_columns) c;

        if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
            -- Fan out 400 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 400: Bad Request, no primary key']
                )::realtime.wal_rls;
            end loop;

        -- The claims role does not have SELECT permission to the primary key of entity
        elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
            -- Fan out 401 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 401: Unauthorized']
                )::realtime.wal_rls;
            end loop;

        else
            -- Create the prepared statement (once per role)
            if is_rls_enabled and action <> 'DELETE' then
                if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                    deallocate walrus_rls_stmt;
                end if;
                execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
            end if;

            -- Collect all visible subscription IDs for this role (filter check + RLS check)
            visible_role_sub_ids = '{}';

            for subscription_id, claims in (
                    select
                        subs.subscription_id,
                        subs.claims
                    from
                        unnest(subscriptions) subs
                    where
                        subs.entity = entity_
                        and subs.claims_role = working_role
                        and (
                            realtime.is_visible_through_filters(columns, subs.filters)
                            or (
                              action = 'DELETE'
                              and realtime.is_visible_through_filters(old_columns, subs.filters)
                            )
                        )
            ) loop

                if not is_rls_enabled or action = 'DELETE' then
                    visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                else
                    -- Check if RLS allows the role to see the record
                    perform
                        -- Trim leading and trailing quotes from working_role because set_config
                        -- doesn't recognize the role as valid if they are included
                        set_config('role', trim(both '"' from working_role::text), true),
                        set_config('request.jwt.claims', claims::text, true);

                    execute 'execute walrus_rls_stmt' into subscription_has_access;

                    if subscription_has_access then
                        visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                    end if;
                end if;
            end loop;

            perform set_config('role', null, true);

            -- Inner loop: per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;

                output = jsonb_build_object(
                    'schema', wal ->> 'schema',
                    'table', wal ->> 'table',
                    'type', action,
                    'commit_timestamp', to_char(
                        ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                        'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
                    ),
                    'columns', (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'name', pa.attname,
                                    'type', pt.typname
                                )
                                order by pa.attnum asc
                            )
                        from
                            pg_attribute pa
                            join pg_type pt
                                on pa.atttypid = pt.oid
                            left join (
                                select unnest(conkey) as pkey_attnum
                                from pg_constraint
                                where conrelid = entity_ and contype = 'p'
                            ) pk on pk.pkey_attnum = pa.attnum
                        where
                            attrelid = entity_
                            and attnum > 0
                            and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
                            and (working_selected_columns is null or pa.attname = any(working_selected_columns) or pk.pkey_attnum is not null)
                    )
                )
                -- Add "record" key for insert and update
                || case
                    when action in ('INSERT', 'UPDATE') then
                        jsonb_build_object(
                            'record',
                            (
                                select
                                    jsonb_object_agg(
                                        -- if unchanged toast, get column name and value from old record
                                        coalesce((c).name, (oc).name),
                                        case
                                            when (c).name is null then (oc).value
                                            else (c).value
                                        end
                                    )
                                from
                                    unnest(columns) c
                                    full outer join unnest(old_columns) oc
                                        on (c).name = (oc).name
                                where
                                    coalesce((c).is_selectable, (oc).is_selectable)
                                    and (working_selected_columns is null or coalesce((c).name, (oc).name) = any(working_selected_columns) or coalesce((c).is_pkey, (oc).is_pkey))
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            )
                        )
                    else '{}'::jsonb
                end
                -- Add "old_record" key for update and delete
                || case
                    when action = 'UPDATE' then
                        jsonb_build_object(
                                'old_record',
                                (
                                    select jsonb_object_agg((c).name, (c).value)
                                    from unnest(old_columns) c
                                    where
                                        (c).is_selectable
                                        and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                        and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                )
                            )
                    when action = 'DELETE' then
                        jsonb_build_object(
                            'old_record',
                            (
                                select jsonb_object_agg((c).name, (c).value)
                                from unnest(old_columns) c
                                where
                                    (c).is_selectable
                                    and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                    and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                            )
                        )
                    else '{}'::jsonb
                end;

                -- Filter visible_role_sub_ids to those matching the current selected_columns group
                visible_to_subscription_ids = coalesce(
                    (
                        select array_agg(s.subscription_id)
                        from unnest(subscriptions) s
                        where s.claims_role = working_role
                          and (s.selected_columns is not distinct from working_selected_columns)
                          and s.subscription_id = any(visible_role_sub_ids)
                    ),
                    '{}'::uuid[]
                );

                return next (
                    output,
                    is_rls_enabled,
                    visible_to_subscription_ids,
                    case
                        when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                        else '{}'
                    end
                )::realtime.wal_rls;
            end loop;

        end if;
    end loop;

    perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS TABLE(wal jsonb, is_rls_enabled boolean, subscription_ids uuid[], errors text[], slot_changes_count bigint)
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
  WITH pub AS (
    SELECT
      concat_ws(
        ',',
        CASE WHEN bool_or(pubinsert) THEN 'insert' ELSE NULL END,
        CASE WHEN bool_or(pubupdate) THEN 'update' ELSE NULL END,
        CASE WHEN bool_or(pubdelete) THEN 'delete' ELSE NULL END
      ) AS w2j_actions,
      coalesce(
        string_agg(
          realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
          ','
        ) filter (WHERE ppt.tablename IS NOT NULL),
        ''
      ) AS w2j_add_tables
    FROM pg_publication pp
    LEFT JOIN pg_publication_tables ppt ON pp.pubname = ppt.pubname
    WHERE pp.pubname = publication
    GROUP BY pp.pubname
    LIMIT 1
  ),
  -- MATERIALIZED ensures pg_logical_slot_get_changes is called exactly once
  w2j AS MATERIALIZED (
    SELECT x.*, pub.w2j_add_tables
    FROM pub,
         pg_logical_slot_get_changes(
           slot_name, null, max_changes,
           'include-pk', 'true',
           'include-transaction', 'false',
           'include-timestamp', 'true',
           'include-type-oids', 'true',
           'format-version', '2',
           'actions', pub.w2j_actions,
           'add-tables', pub.w2j_add_tables
         ) x
  ),
  slot_count AS (
    SELECT count(*)::bigint AS cnt
    FROM w2j
    WHERE w2j.w2j_add_tables <> ''
  ),
  rls_filtered AS (
    SELECT xyz.wal, xyz.is_rls_enabled, xyz.subscription_ids, xyz.errors
    FROM w2j,
         realtime.apply_rls(
           wal := w2j.data::jsonb,
           max_record_bytes := max_record_bytes
         ) xyz(wal, is_rls_enabled, subscription_ids, errors)
    WHERE w2j.w2j_add_tables <> ''
      AND xyz.subscription_ids[1] IS NOT NULL
  )
  SELECT rf.wal, rf.is_rls_enabled, rf.subscription_ids, rf.errors, sc.cnt
  FROM rls_filtered rf, slot_count sc

  UNION ALL

  SELECT null, null, null, null, sc.cnt
  FROM slot_count sc
  WHERE NOT EXISTS (SELECT 1 FROM rls_filtered)
$$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT
    realtime.wal2json_escape_identifier(nsp.nspname::text)
    || '.'
    || realtime.wal2json_escape_identifier(pc.relname::text)
  FROM pg_class pc
  JOIN pg_namespace nsp ON pc.relnamespace = nsp.oid
  WHERE pc.oid = entity
$$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    -- Generate a new UUID for the id
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: send_binary(bytea, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, binary_payload, event, topic, private, extension)
    VALUES (generated_id, payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    col_names text[] = coalesce(
            array_agg(c.column_name order by c.ordinal_position),
            '{}'::text[]
        )
        from
            information_schema.columns c
        where
            format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
            and pg_catalog.has_column_privilege(
                (new.claims ->> 'role'),
                format('%I.%I', c.table_schema, c.table_name)::regclass,
                c.column_name,
                'SELECT'
            );
    table_col_names text[] = coalesce(
            array_agg(pa.attname),
            '{}'::text[]
        )
        from
            pg_attribute pa
        where
            pa.attrelid = new.entity
            and pa.attnum > 0;
    filter realtime.user_defined_filter;
    col_type regtype;
    in_val jsonb;
    selected_col text;
begin
    for filter in select * from unnest(new.filters) loop
        -- Filtered column is valid
        if not filter.column_name = any(col_names) then
            raise exception 'invalid column for filter %', filter.column_name;
        end if;

        -- Type is sanitized and safe for string interpolation
        col_type = (
            select atttypid::regtype
            from pg_catalog.pg_attribute
            where attrelid = new.entity
                  and attname = filter.column_name
        );
        if col_type is null then
            raise exception 'failed to lookup type for column %', filter.column_name;
        end if;
        if filter.op = 'in'::realtime.equality_op then
            in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
            if coalesce(jsonb_array_length(in_val), 0) > 100 then
                raise exception 'too many values for `in` filter. Maximum 100';
            end if;
        else
            -- raises an exception if value is not coercable to type
            perform realtime.cast(filter.value, col_type);
        end if;
    end loop;

    -- Validate that selected_columns reference columns the role can SELECT
    if new.selected_columns is not null then
        for selected_col in select * from unnest(new.selected_columns) loop
            if not selected_col = any(col_names) then
                raise exception 'invalid column for select %', selected_col;
            end if;
        end loop;
    end if;

    -- Apply consistent order to filters so the unique constraint on
    -- (subscription_id, entity, filters) can't be tricked by a different filter order
    new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value),
        '{}'
    ) from unnest(new.filters) f;

    -- Normalize selected_columns order so ARRAY['a','b'] and ARRAY['b','a'] are
    -- treated as the same subscription group in apply_rls
    new.selected_columns = (
        select array_agg(c order by c)
        from unnest(new.selected_columns) c
    );

    return new;
end;
$$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: wal2json_escape_identifier(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.wal2json_escape_identifier(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  -- Prefix `\`, `,`, `.`, and any whitespace with `\`
  SELECT regexp_replace(name, '([\\,.[:space:]])', '\\\1', 'g')
$$;


--
-- Name: allow_any_operation(text[]); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_any_operation(expected_operations text[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


--
-- Name: allow_only_operation(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_only_operation(expected_operation text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: webauthn_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    challenge_type text NOT NULL,
    session_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT webauthn_challenges_challenge_type_check CHECK ((challenge_type = ANY (ARRAY['signup'::text, 'registration'::text, 'authentication'::text])))
);


--
-- Name: webauthn_credentials; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    credential_id bytea NOT NULL,
    public_key bytea NOT NULL,
    attestation_type text DEFAULT ''::text NOT NULL,
    aaguid uuid,
    sign_count bigint DEFAULT 0 NOT NULL,
    transports jsonb DEFAULT '[]'::jsonb NOT NULL,
    backup_eligible boolean DEFAULT false NOT NULL,
    backed_up boolean DEFAULT false NOT NULL,
    friendly_name text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


--
-- Name: __drizzle_migrations; Type: TABLE; Schema: drizzle; Owner: -
--

CREATE TABLE drizzle.__drizzle_migrations (
    id integer NOT NULL,
    hash text NOT NULL,
    created_at bigint
);


--
-- Name: __drizzle_migrations_id_seq; Type: SEQUENCE; Schema: drizzle; Owner: -
--

CREATE SEQUENCE drizzle.__drizzle_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: __drizzle_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: drizzle; Owner: -
--

ALTER SEQUENCE drizzle.__drizzle_migrations_id_seq OWNED BY drizzle.__drizzle_migrations.id;


--
-- Name: account_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    transaction_date timestamp without time zone DEFAULT now() NOT NULL,
    transaction_type character varying(50),
    reference_number character varying(100),
    description text,
    debit numeric(15,2) DEFAULT 0.00,
    credit numeric(15,2) DEFAULT 0.00,
    created_at timestamp without time zone DEFAULT now(),
    source_id uuid,
    source_type character varying(50),
    contact_id uuid,
    contact_type character varying(50),
    entity_id uuid NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL
);


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    system_account_name character varying(255),
    account_code character varying(50),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    parent_id uuid,
    account_group public.account_group_enum DEFAULT 'Expenses'::public.account_group_enum NOT NULL,
    is_system boolean DEFAULT false,
    account_type public.account_type_enum NOT NULL,
    description text,
    account_number character varying(100),
    ifsc character varying(20),
    currency character varying(10) DEFAULT 'INR'::character varying,
    show_in_zerpai_expense boolean DEFAULT false,
    add_to_watchlist boolean DEFAULT false,
    is_deletable boolean DEFAULT true,
    user_account_name character varying(255),
    created_by uuid,
    is_deleted boolean DEFAULT false,
    modified_at timestamp with time zone DEFAULT now(),
    modified_by uuid,
    entity_id uuid NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    CONSTRAINT chk_account_group_type_match CHECK ((((account_group = 'Assets'::public.account_group_enum) AND (account_type = ANY (ARRAY['Bank'::public.account_type_enum, 'Cash'::public.account_type_enum, 'Accounts Receivable'::public.account_type_enum, 'Stock'::public.account_type_enum, 'Payment Clearing Account'::public.account_type_enum, 'Other Current Asset'::public.account_type_enum, 'Fixed Asset'::public.account_type_enum, 'Non Current Asset'::public.account_type_enum, 'Intangible Asset'::public.account_type_enum, 'Deferred Tax Asset'::public.account_type_enum, 'Other Asset'::public.account_type_enum]))) OR ((account_group = 'Liabilities'::public.account_group_enum) AND (account_type = ANY (ARRAY['Credit Card'::public.account_type_enum, 'Accounts Payable'::public.account_type_enum, 'Other Current Liability'::public.account_type_enum, 'Overseas Tax Payable'::public.account_type_enum, 'Non Current Liability'::public.account_type_enum, 'Deferred Tax Liability'::public.account_type_enum, 'Other Liability'::public.account_type_enum]))) OR ((account_group = 'Equity'::public.account_group_enum) AND (account_type = 'Equity'::public.account_type_enum)) OR ((account_group = 'Income'::public.account_group_enum) AND (account_type = ANY (ARRAY['Income'::public.account_type_enum, 'Other Income'::public.account_type_enum]))) OR ((account_group = 'Expenses'::public.account_group_enum) AND (account_type = ANY (ARRAY['Cost Of Goods Sold'::public.account_type_enum, 'Expense'::public.account_type_enum, 'Other Expense'::public.account_type_enum])))))
);


--
-- Name: assemblies_constituencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assemblies_constituencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    district_id uuid NOT NULL,
    code character varying(50),
    name character varying(150) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    table_name character varying(100) NOT NULL,
    record_id uuid NOT NULL,
    action character varying(10) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    user_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    actor_name text DEFAULT 'system'::text NOT NULL,
    schema_name text DEFAULT 'public'::text NOT NULL,
    record_pk text,
    changed_columns text[],
    txid bigint DEFAULT txid_current() NOT NULL,
    source text DEFAULT 'system'::text NOT NULL,
    module_name text,
    request_id text,
    entity_id uuid NOT NULL
);


--
-- Name: audit_logs_archive; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs_archive (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    table_name character varying(100) NOT NULL,
    record_id uuid NOT NULL,
    action character varying(10) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    user_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    actor_name text DEFAULT 'system'::text NOT NULL,
    schema_name text DEFAULT 'public'::text NOT NULL,
    record_pk text,
    changed_columns text[],
    txid bigint DEFAULT txid_current() NOT NULL,
    source text DEFAULT 'system'::text NOT NULL,
    module_name text,
    request_id text,
    archived_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: audit_logs_all; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.audit_logs_all AS
 SELECT audit_logs.id,
    audit_logs.table_name,
    audit_logs.record_id,
    audit_logs.action,
    audit_logs.old_values,
    audit_logs.new_values,
    audit_logs.user_id,
    audit_logs.created_at,
    audit_logs.org_id,
    audit_logs.actor_name,
    audit_logs.schema_name,
    audit_logs.record_pk,
    audit_logs.changed_columns,
    audit_logs.txid,
    audit_logs.source,
    audit_logs.module_name,
    audit_logs.request_id,
    audit_logs.entity_id,
    NULL::timestamp with time zone AS archived_at
   FROM public.audit_logs
UNION ALL
 SELECT audit_logs_archive.id,
    audit_logs_archive.table_name,
    audit_logs_archive.record_id,
    audit_logs_archive.action,
    audit_logs_archive.old_values,
    audit_logs_archive.new_values,
    audit_logs_archive.user_id,
    audit_logs_archive.created_at,
    audit_logs_archive.org_id,
    audit_logs_archive.actor_name,
    audit_logs_archive.schema_name,
    audit_logs_archive.record_pk,
    audit_logs_archive.changed_columns,
    audit_logs_archive.txid,
    audit_logs_archive.source,
    audit_logs_archive.module_name,
    audit_logs_archive.request_id,
    audit_logs_archive.entity_id,
    audit_logs_archive.archived_at
   FROM public.audit_logs_archive;


--
-- Name: branches_system_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.branches_system_id_seq
    START WITH 60000000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    branch_code character varying(50) NOT NULL,
    branch_type character varying(10),
    email character varying(255),
    phone character varying(50),
    website character varying(255),
    attention text,
    street text,
    place text,
    city character varying(100),
    state character varying(100),
    pincode character varying(20),
    country character varying(100) DEFAULT 'India'::character varying NOT NULL,
    gstin character varying(50),
    gstin_registration_type character varying(50),
    logo_url text,
    subscription_from date,
    subscription_to date,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_child_location boolean DEFAULT false NOT NULL,
    parent_branch_id uuid,
    primary_contact_id uuid,
    gstin_legal_name character varying(255),
    gstin_trade_name character varying(255),
    gstin_registered_on date,
    gstin_reverse_charge boolean DEFAULT false NOT NULL,
    gstin_import_export boolean DEFAULT false NOT NULL,
    gstin_import_export_account_id uuid,
    gstin_digital_services boolean DEFAULT false NOT NULL,
    default_transaction_series_id uuid,
    district_id uuid,
    local_body_id uuid,
    ward_id uuid,
    system_id character varying(20) DEFAULT (nextval('public.branches_system_id_seq'::regclass))::text NOT NULL,
    pan character varying,
    industry character varying,
    gst_treatment character varying,
    is_drug_registered boolean DEFAULT false NOT NULL,
    drug_licence_type character varying,
    drug_licence_20 character varying,
    drug_licence_21 character varying,
    drug_licence_20b character varying,
    drug_licence_21b character varying,
    is_fssai_registered boolean DEFAULT false NOT NULL,
    fssai_number character varying,
    is_msme_registered boolean DEFAULT false NOT NULL,
    msme_registration_type character varying,
    msme_number character varying,
    msme_type character varying(50),
    fiscal_year character varying,
    report_basis character varying DEFAULT 'accrual'::character varying,
    has_separate_payment_stub_address boolean DEFAULT false NOT NULL,
    payment_stub_address text,
    payment_stub_assembly_id uuid,
    assembly_id uuid
);


--
-- Name: organisation_branch_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisation_branch_master (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    type character varying(20) NOT NULL,
    ref_id uuid NOT NULL,
    parent_id uuid,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: audit_logs_with_branch_system_id; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.audit_logs_with_branch_system_id AS
 SELECT al.id,
    al.table_name,
    al.record_id,
    al.action,
    al.old_values,
    al.new_values,
    al.user_id,
    al.created_at,
    al.org_id,
    al.actor_name,
    al.schema_name,
    al.record_pk,
    al.changed_columns,
    al.txid,
    al.source,
    al.module_name,
    al.request_id,
    al.entity_id,
    b.system_id
   FROM ((public.audit_logs al
     JOIN public.organisation_branch_master obm ON ((al.entity_id = obm.id)))
     LEFT JOIN public.branches b ON ((obm.ref_id = b.id)));


--
-- Name: batch_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_master (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    batch_no character varying(100) NOT NULL,
    expiry_date date NOT NULL,
    unit_pack character varying,
    is_manufacture_details boolean DEFAULT false,
    manufacture_batch_number character varying(100),
    manufacture_exp date,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by_entity_id uuid,
    source_type character varying(30)
);


--
-- Name: batch_stock_layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_stock_layers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    product_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    bin_id uuid NOT NULL,
    vendor_id uuid,
    purchase_rate numeric(15,2) DEFAULT 0 NOT NULL,
    mrp numeric(15,2) DEFAULT 0 NOT NULL,
    qty numeric(15,3) DEFAULT 0 NOT NULL,
    foc_qty numeric(15,3) DEFAULT 0,
    ref_id uuid,
    ref_type character varying(30) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    reserved_qty numeric(15,3) DEFAULT 0 NOT NULL
);


--
-- Name: batch_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid,
    product_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    bin_id uuid,
    trans_type character varying(30) NOT NULL,
    ref_id uuid,
    ref_no character varying(50),
    qty_in numeric(15,3) DEFAULT 0,
    qty_out numeric(15,3) DEFAULT 0,
    rate numeric(15,2),
    trans_date timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: bill_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bill_id uuid NOT NULL,
    file_name character varying(255) NOT NULL,
    original_file_name character varying(255),
    file_url text NOT NULL,
    file_type character varying(100),
    file_size bigint,
    uploaded_by uuid,
    remarks text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: bill_item_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_item_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bill_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid,
    warehouse_id uuid,
    bin_id uuid,
    quantity numeric(15,3) DEFAULT 0 NOT NULL,
    foc_quantity numeric(15,3) DEFAULT 0,
    damage_quantity numeric(15,3) DEFAULT 0,
    purchase_rate numeric(15,2),
    mrp numeric(15,2),
    expiry_date date,
    manufacture_date date,
    manufacture_batch_no character varying(100),
    is_direct_bill boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: bill_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bill_id uuid NOT NULL,
    product_id uuid NOT NULL,
    purchase_receive_item_id uuid,
    account_id uuid,
    customer_id uuid,
    description text,
    quantity numeric(15,3) DEFAULT 0 NOT NULL,
    rate numeric(15,2) DEFAULT 0 NOT NULL,
    discount_type character varying(20),
    discount_value numeric(15,2) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    tax_id uuid,
    tax_percentage numeric(8,2) DEFAULT 0,
    tax_amount numeric(15,2) DEFAULT 0,
    line_total numeric(15,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    hsn_code numeric
);


--
-- Name: bill_landed_costs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_landed_costs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bill_id uuid NOT NULL,
    expense_account_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    allocation_method character varying(30),
    description text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: bills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bills (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    bill_number character varying(50) NOT NULL,
    order_number character varying(100),
    bill_date date NOT NULL,
    due_date date,
    payment_term_id uuid,
    reverse_charge_applicable boolean DEFAULT false,
    warehouse_id uuid,
    price_list_id uuid,
    landed_cost_allocation_type character varying(30),
    subject text,
    notes text,
    subtotal numeric(15,2) DEFAULT 0,
    discount_total numeric(15,2) DEFAULT 0,
    tax_total numeric(15,2) DEFAULT 0,
    shipping_charges numeric(15,2) DEFAULT 0,
    tds_total numeric(15,2) DEFAULT 0,
    tcs_total numeric(15,2) DEFAULT 0,
    adjustment_amount numeric(15,2) DEFAULT 0,
    round_off numeric(15,2) DEFAULT 0,
    grand_total numeric(15,2) DEFAULT 0,
    source_type character varying(30),
    source_id uuid,
    status character varying(30) DEFAULT 'draft'::character varying,
    created_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_delete boolean NOT NULL
);


--
-- Name: bin_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bin_master (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    zone_id uuid NOT NULL,
    bin_code character varying(100) NOT NULL,
    level_path text,
    bin_type character varying(20),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: branch_price_list_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch_price_list_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    price_list_id uuid NOT NULL,
    branch_entity_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: branch_transaction_series; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch_transaction_series (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_series_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: branch_user_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch_user_access (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid,
    is_default_branch boolean DEFAULT false,
    permissions jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: branch_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: branding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branding (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    accent_color character varying(7) DEFAULT '#22A95E'::character varying NOT NULL,
    theme_mode character varying(10) DEFAULT 'dark'::character varying NOT NULL,
    keep_branding boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL,
    CONSTRAINT settings_branding_theme_mode_check CHECK (((theme_mode)::text = ANY ((ARRAY['dark'::character varying, 'light'::character varying])::text[])))
);


--
-- Name: brands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brands (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: business_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    label character varying NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: buying_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.buying_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    buying_rule character varying(255) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    rule_description text,
    system_behavior text,
    associated_schedule_codes text[] DEFAULT ARRAY[]::text[] NOT NULL,
    requires_rx boolean DEFAULT false NOT NULL,
    requires_patient_info boolean DEFAULT false NOT NULL,
    is_saleable boolean DEFAULT true NOT NULL,
    log_to_special_register boolean DEFAULT false NOT NULL,
    requires_doctor_name boolean DEFAULT false NOT NULL,
    requires_prescription_date boolean DEFAULT false NOT NULL,
    requires_age_check boolean DEFAULT false NOT NULL,
    institutional_only boolean DEFAULT false NOT NULL,
    blocks_retail_sale boolean DEFAULT false NOT NULL,
    quantity_limit integer,
    allows_refill boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: carrier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.carrier (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    parent_id uuid,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: company_id_labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_id_labels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    label character varying(50) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order smallint DEFAULT 0 NOT NULL
);


--
-- Name: composite_item_branch_inventory_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.composite_item_branch_inventory_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    composite_item_id uuid NOT NULL,
    reorder_point integer DEFAULT 0 NOT NULL,
    reorder_term_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_by_id uuid,
    updated_by_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: composite_item_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.composite_item_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    composite_item_id uuid NOT NULL,
    component_product_id uuid NOT NULL,
    quantity numeric(15,3) NOT NULL,
    selling_price_override numeric(15,2),
    cost_price_override numeric(15,2),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: composite_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.composite_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type public.composite_type NOT NULL,
    product_name character varying(255) NOT NULL,
    sku character varying(100),
    unit_id uuid NOT NULL,
    category_id uuid,
    is_returnable boolean DEFAULT false,
    push_to_ecommerce boolean DEFAULT false,
    hsn_code character varying(50),
    tax_preference public.tax_preference,
    intra_state_tax_id uuid,
    inter_state_tax_id uuid,
    primary_image_url text,
    image_urls text,
    selling_price numeric(15,2),
    selling_price_currency character varying(10) DEFAULT 'INR'::character varying,
    ptr numeric(15,2),
    sales_account_id uuid,
    sales_description text,
    cost_price numeric(15,2),
    purchase_account_id uuid,
    preferred_vendor_id uuid,
    purchase_description text,
    length numeric(10,2),
    width numeric(10,2),
    height numeric(10,2),
    dimension_unit character varying(10) DEFAULT 'cm'::character varying,
    weight numeric(10,2),
    weight_unit character varying(10) DEFAULT 'kg'::character varying,
    manufacturer_id uuid,
    brand_id uuid,
    mpn character varying(100),
    upc character varying(20),
    isbn character varying(20),
    ean character varying(20),
    is_track_inventory boolean DEFAULT true,
    track_batches boolean DEFAULT false,
    track_serial_number boolean DEFAULT false,
    inventory_account_id uuid,
    inventory_valuation_method public.inventory_valuation_method,
    reorder_point integer DEFAULT 0,
    reorder_term_id uuid,
    is_active boolean DEFAULT true,
    is_lock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    created_by_id uuid,
    updated_at timestamp with time zone DEFAULT now(),
    updated_by_id uuid
);


--
-- Name: contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_name character varying NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    full_label character varying(255),
    phone_code character varying(20) NOT NULL,
    short_code character varying(10),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    primary_timezone_id uuid
);


--
-- Name: credit_note_item_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_note_item_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    credit_note_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid,
    warehouse_id uuid,
    bin_id uuid,
    quantity numeric(15,3) DEFAULT 0 NOT NULL,
    rate numeric(15,2),
    mrp numeric(15,2),
    ref_type character varying(30),
    ref_id uuid,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: credit_note_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_note_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    credit_note_id uuid NOT NULL,
    product_id uuid NOT NULL,
    invoice_item_id uuid,
    sales_return_item_id uuid,
    account_id uuid,
    description text,
    quantity numeric(15,3) DEFAULT 0 NOT NULL,
    rate numeric(15,2) DEFAULT 0 NOT NULL,
    discount_type character varying(20),
    discount_value numeric(15,2) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    tax_id uuid,
    tax_percentage numeric(8,2) DEFAULT 0,
    tax_amount numeric(15,2) DEFAULT 0,
    taxable_amount numeric(15,2) DEFAULT 0,
    line_total numeric(15,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: credit_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    credit_note_number character varying(50) NOT NULL,
    reference_number character varying(100),
    credit_note_date date NOT NULL,
    reason character varying(100),
    salesperson_id uuid,
    warehouse_id uuid,
    price_list_id uuid,
    subject text,
    customer_notes text,
    terms_conditions text,
    subtotal numeric(15,2) DEFAULT 0,
    discount_total numeric(15,2) DEFAULT 0,
    tax_total numeric(15,2) DEFAULT 0,
    shipping_charges numeric(15,2) DEFAULT 0,
    tds_total numeric(15,2) DEFAULT 0,
    tcs_total numeric(15,2) DEFAULT 0,
    adjustment_amount numeric(15,2) DEFAULT 0,
    round_off numeric(15,2) DEFAULT 0,
    grand_total numeric(15,2) DEFAULT 0,
    source_type character varying(30),
    source_id uuid,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL,
    created_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(100) NOT NULL,
    symbol character varying(10),
    decimals integer DEFAULT 2,
    format character varying(50),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: customer_contact_persons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_contact_persons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    salutation character varying(10),
    first_name character varying(100),
    last_name character varying(100),
    email character varying(255),
    work_phone character varying(20),
    mobile_phone character varying(20),
    display_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: TABLE customer_contact_persons; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.customer_contact_persons IS 'Alternative contact persons for customers';


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    display_name character varying(255) NOT NULL,
    customer_type character varying(50) DEFAULT 'Business'::character varying,
    salutation character varying(20),
    first_name character varying(255),
    last_name character varying(255),
    company_name character varying(255),
    email character varying(255),
    phone character varying(50),
    mobile_phone character varying(50),
    gstin character varying(50),
    pan character varying(50),
    payment_terms character varying(100),
    billing_address text,
    shipping_address text,
    is_active boolean DEFAULT true,
    receivables numeric(15,2) DEFAULT 0.00,
    created_at timestamp without time zone DEFAULT now(),
    customer_number character varying(50),
    designation character varying(100),
    department character varying(100),
    business_type character varying(50),
    customer_language character varying(50) DEFAULT 'English'::character varying,
    date_of_birth date,
    age integer,
    gender character varying(20),
    place_of_customer character varying(255),
    privilege_card_number character varying(100),
    parent_customer_id uuid,
    tax_preference character varying(100),
    exemption_reason text,
    drug_licence_type character varying(50),
    drug_license_20 character varying(100),
    drug_license_21 character varying(100),
    drug_license_20b character varying(100),
    drug_license_21b character varying(100),
    fssai character varying(100),
    msme_registration_type character varying(50),
    msme_number character varying(100),
    drug_license_20_doc_url text,
    drug_license_21_doc_url text,
    drug_license_20b_doc_url text,
    drug_license_21b_doc_url text,
    fssai_doc_url text,
    msme_doc_url text,
    opening_balance numeric(15,2) DEFAULT 0,
    credit_limit numeric(15,2),
    enable_portal boolean DEFAULT false,
    facebook_handle character varying(255),
    twitter_handle character varying(255),
    whatsapp_number character varying(20),
    is_recurring boolean DEFAULT false,
    gst_treatment character varying(50),
    place_of_supply character varying(100),
    website character varying(255),
    price_list_id uuid,
    receivable_balance numeric(15,2) DEFAULT 0,
    billing_address_street character varying(255),
    billing_address_place character varying(255),
    billing_address_city character varying(100),
    billing_address_zip character varying(20),
    billing_address_phone character varying(50),
    shipping_address_street character varying(255),
    shipping_address_place character varying(255),
    shipping_address_city character varying(100),
    shipping_address_zip character varying(20),
    shipping_address_phone character varying(50),
    remarks text,
    status character varying(20) DEFAULT 'active'::character varying,
    document_urls text,
    is_drug_registered boolean,
    is_fssai_registered boolean,
    is_msme_registered boolean,
    currency_id uuid,
    billing_address_state_id uuid,
    shipping_address_state_id uuid,
    billing_address_country_id uuid,
    shipping_address_country_id uuid,
    entity_id uuid NOT NULL,
    associated_branch_id uuid
);


--
-- Name: COLUMN customers.facebook_handle; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.facebook_handle IS 'Facebook profile handle';


--
-- Name: COLUMN customers.twitter_handle; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.twitter_handle IS 'X (Twitter) profile handle';


--
-- Name: COLUMN customers.whatsapp_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.whatsapp_number IS 'WhatsApp contact number';


--
-- Name: COLUMN customers.is_recurring; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.is_recurring IS 'Indicates if this is a recurring customer';


--
-- Name: COLUMN customers.gst_treatment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.gst_treatment IS 'GST treatment type for the customer';


--
-- Name: COLUMN customers.place_of_supply; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.place_of_supply IS 'Place of supply for GST purposes';


--
-- Name: COLUMN customers.website; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.website IS 'Customer website URL';


--
-- Name: COLUMN customers.receivable_balance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.receivable_balance IS 'Current receivable balance';


--
-- Name: COLUMN customers.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.customers.status IS 'Customer status (active/inactive)';


--
-- Name: date_format; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.date_format (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    format_pattern character varying NOT NULL,
    group_name character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: date_separator; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.date_separator (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    separator character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: drug_licence_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drug_licence_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: drug_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drug_schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    shedule_name character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    schedule_code character varying(30),
    reference_description text,
    requires_prescription boolean DEFAULT false NOT NULL,
    requires_h1_register boolean DEFAULT false NOT NULL,
    is_narcotic boolean DEFAULT false NOT NULL,
    requires_batch_tracking boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_common boolean DEFAULT false NOT NULL
);


--
-- Name: drug_strengths; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drug_strengths (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    strength_name character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: fiscal_year_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fiscal_year_presets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    label character varying NOT NULL,
    start_month smallint NOT NULL,
    end_month smallint NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: fiscal_years; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fiscal_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    name character varying(50) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: gst_treatments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gst_treatments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: gstin_registration_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gstin_registration_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: hsn_sac_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hsn_sac_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type public.hsn_sac_type NOT NULL,
    code character varying(15) NOT NULL,
    description text NOT NULL
);


--
-- Name: industries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.industries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order smallint DEFAULT 0 NOT NULL
);


--
-- Name: inventory_adjustment_account_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_adjustment_account_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    account_id uuid NOT NULL,
    debit numeric(18,2) DEFAULT 0 NOT NULL,
    credit numeric(18,2) DEFAULT 0 NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: inventory_adjustment_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_adjustment_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    adjustment_id uuid NOT NULL,
    file_name text NOT NULL,
    file_url text,
    storage_bucket text,
    storage_path text,
    mime_type text,
    file_size_bytes bigint,
    file_hash text,
    uploaded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT inventory_adjustment_attachments_file_size_bytes_check CHECK (((file_size_bytes IS NULL) OR (file_size_bytes >= 0)))
);


--
-- Name: inventory_adjustment_item_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_adjustment_item_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    adjustment_item_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    product_id uuid NOT NULL,
    warehouse_id uuid,
    bin_id uuid,
    batch_id uuid,
    batch_reference character varying(150),
    quantity_in numeric(15,2) DEFAULT 0 NOT NULL,
    quantity_out numeric(15,2) DEFAULT 0 NOT NULL,
    rate numeric(15,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    batch_stock_layer_id uuid
);


--
-- Name: inventory_adjustment_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_adjustment_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    product_id uuid NOT NULL,
    quantity_before numeric(15,2) DEFAULT 0 NOT NULL,
    quantity_adjusted numeric(15,2) DEFAULT 0 NOT NULL,
    quantity_after numeric(15,2) DEFAULT 0 NOT NULL,
    cost_price numeric(15,2),
    mrp numeric(15,2),
    adjustment_value numeric(15,2) DEFAULT 0 NOT NULL,
    batch_id uuid,
    batch_reference character varying(150),
    batch_allocations jsonb DEFAULT '[]'::jsonb NOT NULL,
    reporting_tags jsonb DEFAULT '{}'::jsonb NOT NULL,
    mfd_month_year character varying(7),
    expiry_month_year character varying(7),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_inv_adj_items_expiry_mm_yyyy CHECK (((expiry_month_year IS NULL) OR ((expiry_month_year)::text ~ '^(0[1-9]|1[0-2])/[0-9]{4}$'::text))),
    CONSTRAINT chk_inv_adj_items_mfd_mm_yyyy CHECK (((mfd_month_year IS NULL) OR ((mfd_month_year)::text ~ '^(0[1-9]|1[0-2])/[0-9]{4}$'::text)))
);


--
-- Name: inventory_adjustment_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_adjustment_reasons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid,
    name character varying(200) NOT NULL,
    code character varying(60),
    reason_type character varying(20) DEFAULT 'both'::character varying,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: inventory_adjustment_value_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_adjustment_value_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    product_id uuid NOT NULL,
    batch_id uuid,
    batch_stock_layer_id uuid,
    current_value numeric(18,2) DEFAULT 0 NOT NULL,
    changed_value numeric(18,2) DEFAULT 0 NOT NULL,
    adjusted_value numeric(18,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: inventory_adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_adjustments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    product_id uuid,
    warehouse_id uuid,
    adjustment_number character varying(100),
    adjustment_date timestamp with time zone DEFAULT now() NOT NULL,
    adjustment_type public.inventory_adjustment_type DEFAULT 'quantity'::public.inventory_adjustment_type NOT NULL,
    reason_id uuid,
    reason character varying(255),
    reference_number character varying(100),
    notes text,
    account_id uuid,
    status public.inventory_adjustment_status DEFAULT 'draft'::public.inventory_adjustment_status NOT NULL,
    quantity_before numeric(15,2),
    quantity_adjusted numeric(15,2),
    quantity_after numeric(15,2),
    cost_price numeric(15,2),
    adjustment_value numeric(15,2),
    adjusted_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: inventory_move_order_destination_bins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_move_order_destination_bins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_batch_row_id uuid NOT NULL,
    destination_bin_id uuid NOT NULL,
    qty_in numeric(18,4) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: inventory_move_order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_move_order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    move_order_id uuid NOT NULL,
    product_id uuid NOT NULL,
    qty numeric(18,4) NOT NULL,
    remarks text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: inventory_move_order_source_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_move_order_source_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    move_order_item_id uuid NOT NULL,
    source_layer_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    source_bin_id uuid NOT NULL,
    qty_out numeric(18,4) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: inventory_move_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_move_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    move_order_number character varying(50) NOT NULL,
    move_date timestamp without time zone NOT NULL,
    assignee_id uuid,
    notes text,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL,
    created_by uuid,
    completed_by uuid,
    completed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: inventory_package_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_package_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    package_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    product_id uuid NOT NULL,
    quantity numeric(15,3) DEFAULT 0 NOT NULL,
    sales_order_id uuid,
    picklist_id uuid,
    batch_no character varying,
    bin_location character varying,
    foc smallint
);


--
-- Name: inventory_package_sales_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_package_sales_orders (
    package_id uuid NOT NULL,
    sales_order_id uuid NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: inventory_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_packages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    package_number character varying NOT NULL,
    package_date date DEFAULT CURRENT_DATE NOT NULL,
    dimension_length numeric(15,2) DEFAULT 0,
    dimension_width numeric(15,2) DEFAULT 0,
    dimension_height numeric(15,2) DEFAULT 0,
    dimension_unit character varying(10) DEFAULT 'cm'::character varying,
    weight numeric(15,2) DEFAULT 0,
    weight_unit character varying(10) DEFAULT 'kg'::character varying,
    is_manual_mode boolean DEFAULT false,
    notes text,
    status character varying(50) DEFAULT 'Not Shipped'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    is_delete boolean NOT NULL
);


--
-- Name: inventory_shipment_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_shipment_packages (
    shipment_id uuid NOT NULL,
    package_id uuid NOT NULL
);


--
-- Name: inventory_shipment_sales_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_shipment_sales_orders (
    shipment_id uuid NOT NULL,
    sales_order_id uuid NOT NULL
);


--
-- Name: inventory_shipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_shipments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    shipment_number character varying(100) NOT NULL,
    customer_id uuid,
    date date NOT NULL,
    delivered_date timestamp without time zone,
    carrier character varying(255),
    tracking_number character varying(255),
    tracking_url text,
    shipping_charges numeric(15,2) DEFAULT 0 NOT NULL,
    notes text,
    is_delivered boolean DEFAULT false NOT NULL,
    send_notification boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_delete boolean NOT NULL
);


--
-- Name: inventory_stock_commitments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_stock_commitments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid,
    product_id uuid NOT NULL,
    source_type character varying(30) NOT NULL,
    source_id uuid NOT NULL,
    committed_qty numeric(15,3) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: invoice_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    file_name character varying(255),
    file_path text,
    uploaded_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    file_size character varying NOT NULL
);


--
-- Name: invoice_item_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_item_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid,
    warehouse_id uuid NOT NULL,
    bin_id uuid,
    quantity numeric(15,3) NOT NULL,
    foc_quantity numeric(15,3) DEFAULT 0,
    purchase_rate numeric(15,2),
    sales_rate numeric(15,2),
    mrp numeric(15,2),
    expiry_date date,
    manufacturer_batch character varying(100),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: invoice_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    product_id uuid NOT NULL,
    description text,
    quantity numeric(15,3) NOT NULL,
    rate numeric(15,2) NOT NULL,
    discount_type character varying(20),
    discount_value numeric(15,2) DEFAULT 0,
    tax_id uuid,
    tax_percentage numeric(8,2) DEFAULT 0,
    taxable_amount numeric(15,2) DEFAULT 0,
    tax_amount numeric(15,2) DEFAULT 0,
    line_total numeric(15,2) DEFAULT 0,
    foc_quantity numeric(15,3) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    hsn_code numeric NOT NULL,
    accounts uuid
);


--
-- Name: invoice_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_master (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    warehouse_id uuid,
    invoice_number character varying(50) NOT NULL,
    invoice_date date NOT NULL,
    due_date date,
    payment_terms character varying(100),
    salesperson_id uuid,
    subject text,
    customer_notes text,
    terms_conditions text,
    price_list_id uuid,
    shipping_charges numeric(15,2) DEFAULT 0,
    adjustment_amount numeric(15,2) DEFAULT 0,
    round_off numeric(15,2) DEFAULT 0,
    subtotal numeric(15,2) DEFAULT 0,
    tax_total numeric(15,2) DEFAULT 0,
    tds_total numeric(15,2) DEFAULT 0,
    tcs_total numeric(15,2) DEFAULT 0,
    grand_total numeric(15,2) DEFAULT 0,
    inventory_flow_type character varying(50),
    status character varying(30) DEFAULT 'draft'::character varying,
    is_batch_allocated boolean DEFAULT false,
    created_by uuid,
    approved_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_delete boolean NOT NULL,
    place_of_supply character varying
);


--
-- Name: invoice_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_packages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    package_id uuid NOT NULL
);


--
-- Name: invoice_sales_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_sales_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    sales_order_id uuid NOT NULL
);


--
-- Name: invoice_shipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_shipments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    shipment_id uuid NOT NULL
);


--
-- Name: journal_number_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_number_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    auto_generate boolean DEFAULT true,
    prefix character varying(20),
    next_number integer DEFAULT 1,
    is_manual_override_allowed boolean DEFAULT false,
    user_id uuid,
    entity_id uuid NOT NULL
);


--
-- Name: journal_template_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_template_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL,
    account_id uuid NOT NULL,
    description text,
    contact_id uuid,
    contact_type public.accounts_contact_type,
    type public.accounts_journal_template_type,
    debit numeric(15,2) DEFAULT 0.00,
    credit numeric(15,2) DEFAULT 0.00,
    sort_order integer,
    entity_id uuid NOT NULL
);


--
-- Name: journal_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name character varying(255) NOT NULL,
    reference_number character varying(100),
    notes text,
    reporting_method public.accounts_reporting_method,
    currency_code character varying(10) DEFAULT 'INR'::character varying,
    is_active boolean DEFAULT true,
    enter_amount boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: lsgd_districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsgd_districts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    state_id uuid NOT NULL,
    name character varying(150) NOT NULL,
    code character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: lsgd_local_bodies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsgd_local_bodies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    district_id uuid NOT NULL,
    name character varying(150) NOT NULL,
    code character varying(50),
    body_type character varying(30) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT settings_local_bodies_body_type_check CHECK (((body_type)::text = ANY (ARRAY[('grama_panchayat'::character varying)::text, ('municipality'::character varying)::text, ('corporation'::character varying)::text, ('town_panchayat'::character varying)::text])))
);


--
-- Name: lsgd_wards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsgd_wards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    local_body_id uuid NOT NULL,
    ward_no integer,
    name character varying(150) NOT NULL,
    code character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: manual_journal_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manual_journal_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    manual_journal_id uuid NOT NULL,
    file_name character varying(255) NOT NULL,
    file_path text NOT NULL,
    file_size integer,
    uploaded_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: manual_journal_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manual_journal_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    manual_journal_id uuid NOT NULL,
    account_id uuid NOT NULL,
    description text,
    contact_id uuid,
    contact_type public.accounts_contact_type,
    debit numeric(15,2) DEFAULT 0.00,
    credit numeric(15,2) DEFAULT 0.00,
    sort_order integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    contact_name character varying(255),
    entity_id uuid NOT NULL
);


--
-- Name: manual_journal_tag_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manual_journal_tag_mappings (
    manual_journal_item_id uuid NOT NULL,
    reporting_tag_id uuid NOT NULL
);


--
-- Name: manual_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manual_journals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    journal_number character varying(100) NOT NULL,
    fiscal_year_id uuid,
    reference_number character varying(100),
    journal_date date DEFAULT CURRENT_DATE,
    notes text,
    is_13th_month_adjustment boolean DEFAULT false,
    reporting_method public.accounts_reporting_method DEFAULT 'accrual_and_cash'::public.accounts_reporting_method,
    currency_code character varying(10) DEFAULT 'INR'::character varying,
    status public.accounts_manual_journal_status DEFAULT 'draft'::public.accounts_manual_journal_status,
    total_amount numeric(15,2) DEFAULT 0.00,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now(),
    recurring_journal_id uuid,
    updated_at timestamp with time zone DEFAULT now(),
    is_deleted boolean DEFAULT false NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: manufacturers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manufacturers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    contact_info jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: move_order_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.move_order_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    move_order_id uuid NOT NULL,
    file_name character varying(255) NOT NULL,
    original_file_name character varying(255),
    file_url text NOT NULL,
    file_size bigint,
    file_type character varying(100),
    uploaded_by uuid,
    uploaded_at timestamp with time zone DEFAULT now()
);


--
-- Name: organization_system_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organization_system_id_seq
    START WITH 60000000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    state_id uuid,
    industry character varying(255),
    logo_url text,
    base_currency character varying(10),
    fiscal_year character varying(50),
    timezone character varying(100),
    date_format character varying(50),
    date_separator character varying(5),
    company_id_label character varying(50),
    company_id_value character varying(100),
    payment_stub_address text,
    has_separate_payment_stub_address boolean DEFAULT false NOT NULL,
    system_id character varying(20) DEFAULT (nextval('public.organization_system_id_seq'::regclass))::text NOT NULL,
    base_currency_decimals smallint,
    base_currency_format character varying(50),
    organization_language character varying(50) DEFAULT 'English'::character varying,
    communication_languages text[] DEFAULT ARRAY['English'::text] NOT NULL,
    payment_stub_district_id uuid,
    payment_stub_local_body_id uuid,
    payment_stub_ward_id uuid,
    is_drug_registered boolean DEFAULT false NOT NULL,
    drug_licence_type character varying,
    drug_license_20 character varying,
    drug_license_21 character varying,
    drug_license_20b character varying,
    drug_license_21b character varying,
    is_fssai_registered boolean DEFAULT false NOT NULL,
    fssai_number character varying,
    is_msme_registered boolean DEFAULT false NOT NULL,
    msme_registration_type character varying,
    msme_number character varying,
    payment_stub_assembly_id uuid,
    attention text,
    street text,
    place text,
    city character varying(100),
    pincode character varying(20),
    phone character varying(50),
    district_id uuid,
    local_body_id uuid,
    assembly_id uuid,
    ward_id uuid,
    report_basis character varying(50) DEFAULT 'accrual'::character varying,
    drug_license_20_url text,
    drug_license_21_url text,
    drug_license_20b_url text,
    drug_license_21b_url text,
    fssai_url text,
    msme_url text,
    additional_fields jsonb,
    email character varying
);


--
-- Name: payment_received_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_received_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    payment_received_id uuid NOT NULL,
    sales_invoice_id uuid NOT NULL,
    allocated_amount numeric(15,2) DEFAULT 0 NOT NULL,
    allocation_date date NOT NULL,
    remarks text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: payment_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_terms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    term_name character varying(255) NOT NULL,
    number_of_days integer NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: payments_received; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments_received (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    payment_number character varying(50) NOT NULL,
    payment_type character varying(30) NOT NULL,
    payment_date date NOT NULL,
    payment_mode character varying(30),
    deposit_account_id uuid NOT NULL,
    currency_id uuid,
    exchange_rate numeric(15,6) DEFAULT 1,
    amount_received numeric(15,2) DEFAULT 0 NOT NULL,
    amount_allocated numeric(15,2) DEFAULT 0,
    excess_amount numeric(15,2) DEFAULT 0,
    refunded_amount numeric(15,2) DEFAULT 0,
    bank_charges numeric(15,2) DEFAULT 0,
    tds_amount numeric(15,2) DEFAULT 0,
    reference_number character varying(100),
    notes text,
    status character varying(30) DEFAULT 'draft'::character varying,
    created_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: picklist_batch_allocation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.picklist_batch_allocation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    picklist_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id character varying(100) NOT NULL,
    warehouse_id uuid NOT NULL,
    bin_id uuid NOT NULL,
    qty numeric(15,3) NOT NULL,
    foc_qty numeric(15,3) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: picklist_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.picklist_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    picklist_id uuid NOT NULL,
    product_id uuid NOT NULL,
    sales_order_id uuid,
    sales_order_line_id uuid,
    qty_ordered numeric(15,3),
    qty_to_pick numeric(15,3),
    qty_picked numeric(15,3) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    status text
);


--
-- Name: picklist_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.picklist_master (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    picklist_no character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    assignee_id uuid,
    picklist_date date NOT NULL,
    status text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    is_delete boolean NOT NULL,
    is_entrypass boolean NOT NULL
);


--
-- Name: price_list_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.price_list_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    price_list_id uuid NOT NULL,
    product_id uuid NOT NULL,
    custom_rate numeric(15,2),
    discount_percentage numeric(5,2),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: price_list_volume_ranges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.price_list_volume_ranges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    price_list_item_id uuid NOT NULL,
    start_quantity numeric(15,3) NOT NULL,
    end_quantity numeric(15,3),
    rate numeric(15,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: price_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.price_lists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text DEFAULT ''::text,
    currency character varying(20) DEFAULT 'INR'::character varying,
    pricing_scheme character varying(50) NOT NULL,
    details text DEFAULT ''::text,
    round_off_preference character varying(50) DEFAULT 'never_mind'::character varying,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    price_list_type character varying(50) DEFAULT 'all_items'::character varying,
    percentage_type character varying(20),
    percentage_value numeric(5,2),
    discount_enabled boolean DEFAULT false,
    transaction_type character varying(50) DEFAULT 'Sales'::character varying,
    entity_id uuid,
    created_by_entity_id uuid,
    price_scope character varying(30) DEFAULT 'SELF'::character varying NOT NULL,
    is_seasonal boolean DEFAULT false NOT NULL,
    valid_from date,
    valid_to date,
    associated_branches uuid
);


--
-- Name: COLUMN price_lists.pricing_scheme; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.price_lists.pricing_scheme IS 'unit_pricing or volume_pricing';


--
-- Name: COLUMN price_lists.price_list_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.price_lists.price_list_type IS 'all_items: applies percentage to all items, individual_items: custom pricing per item';


--
-- Name: COLUMN price_lists.percentage_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.price_lists.percentage_type IS 'Markup or Markdown (only for all_items type)';


--
-- Name: COLUMN price_lists.percentage_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.price_lists.percentage_value IS 'Percentage value for markup/markdown (only for all_items type)';


--
-- Name: product_bin_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_bin_mappings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    bin_id uuid NOT NULL,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    min_qty integer,
    max_qty integer,
    created_at timestamp without time zone DEFAULT now(),
    created_by_id uuid,
    updated_at timestamp without time zone DEFAULT now(),
    updated_by_id uuid
);


--
-- Name: product_branch_inventory_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_branch_inventory_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    product_id uuid NOT NULL,
    reorder_point integer DEFAULT 0 NOT NULL,
    reorder_term_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_by_id uuid,
    updated_by_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    content_id uuid,
    strength_id uuid,
    shedule_id uuid,
    display_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: product_entity_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_entity_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    sku character varying(100),
    reorder_point integer DEFAULT 0,
    reorder_term_id uuid,
    inventory_valuation_method public.inventory_valuation_method,
    preferred_vendor_id uuid,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    created_by_id uuid,
    updated_at timestamp without time zone DEFAULT now(),
    updated_by_id uuid,
    CONSTRAINT product_entity_settings_inventory_valuation_method_check CHECK (((inventory_valuation_method IS NULL) OR (inventory_valuation_method = ANY (ARRAY['FIFO'::public.inventory_valuation_method, 'LIFO'::public.inventory_valuation_method, 'FEFO'::public.inventory_valuation_method, 'Weighted Average'::public.inventory_valuation_method, 'Specific Identification'::public.inventory_valuation_method]))))
);


--
-- Name: product_pack_sizes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_pack_sizes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    pack_name character varying(120) NOT NULL,
    unit_pack numeric(15,2) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(120) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: product_vendor_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_vendor_mappings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_id uuid NOT NULL,
    item_id uuid NOT NULL,
    mapping_name character varying(255) NOT NULL,
    vendor_product_code character varying(255),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type public.product_type NOT NULL,
    product_name character varying(255) NOT NULL,
    billing_name character varying(255),
    item_code character varying(100) NOT NULL,
    unit_id uuid NOT NULL,
    category_id uuid,
    is_returnable boolean DEFAULT false,
    push_to_ecommerce boolean DEFAULT false,
    hsn_code character varying(50),
    tax_preference public.tax_preference,
    intra_state_tax_id uuid,
    inter_state_tax_id uuid,
    primary_image_url text,
    image_urls jsonb,
    selling_price numeric(15,2),
    selling_price_currency character varying(10) DEFAULT 'INR'::character varying,
    mrp numeric(15,2),
    ptr numeric(15,2),
    sales_account_id uuid,
    sales_description text,
    cost_price numeric(15,2),
    cost_price_currency character varying(10) DEFAULT 'INR'::character varying,
    purchase_account_id uuid,
    purchase_description text,
    length numeric(10,2),
    width numeric(10,2),
    height numeric(10,2),
    dimension_unit character varying(10) DEFAULT 'cm'::character varying,
    weight numeric(10,2),
    weight_unit character varying(10) DEFAULT 'kg'::character varying,
    brand_id uuid,
    mpn character varying(100),
    upc character varying(20),
    isbn character varying(20),
    ean character varying(20),
    track_assoc_ingredients boolean DEFAULT false,
    buying_rule_old character varying(100),
    schedule_of_drug_old character varying(50),
    is_track_inventory boolean DEFAULT true,
    track_bin_location boolean DEFAULT true,
    track_batches boolean DEFAULT true,
    inventory_account_id uuid,
    storage_id uuid,
    is_active boolean DEFAULT true,
    is_lock boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    created_by_id uuid,
    updated_at timestamp without time zone DEFAULT now(),
    updated_by_id uuid,
    track_serial_number boolean DEFAULT false,
    buying_rule_id uuid,
    schedule_of_drug_id uuid,
    lock_unit_pack numeric(15,2),
    storage_description text,
    about text,
    uses_description text,
    how_to_use text,
    dosage_description text,
    missed_dose_description text,
    safety_advice text,
    side_effects jsonb,
    faq_text jsonb,
    preferred_vendor_id uuid,
    sku character varying(100),
    exemption_reason character varying(255),
    inventory_valuation_method character varying(100),
    rack_id uuid,
    reorder_point integer DEFAULT 0,
    reorder_term_id uuid,
    rep_id uuid,
    manufacturer_id uuid,
    unit_pack character varying(50),
    product_type_id uuid
);


--
-- Name: COLUMN products.unit_pack; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.products.unit_pack IS 'Pack size label/value selected in item formulation flow, e.g. Box (10).';


--
-- Name: purchase_order_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_order_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_order_id uuid NOT NULL,
    file_name character varying(255) NOT NULL,
    file_path text NOT NULL,
    file_size character varying,
    file_type character varying(50),
    uploaded_at timestamp with time zone DEFAULT now()
);


--
-- Name: purchase_order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_order_id uuid NOT NULL,
    sort_order integer,
    is_header boolean DEFAULT false,
    header_text text,
    product_id uuid,
    description text,
    account_id uuid,
    quantity numeric(15,2) DEFAULT 0.00,
    rate numeric(15,2) DEFAULT 0.00,
    tax_id uuid,
    item_tax_rate numeric(5,2) DEFAULT 0.00,
    tax_amount numeric(15,2) DEFAULT 0.00,
    discount numeric(15,2) DEFAULT 0.00,
    discount_type character varying(20) DEFAULT 'percentage'::character varying,
    amount numeric(15,2) DEFAULT 0.00,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    entity_id uuid,
    accounts uuid,
    pricelist character varying,
    hsn_code numeric
);


--
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_number character varying(100) NOT NULL,
    order_date date NOT NULL,
    expected_delivery_date date,
    reference_number character varying(100),
    vendor_id uuid NOT NULL,
    payment_terms_id uuid,
    shipment_preference_id uuid,
    delivery_type character varying(20) DEFAULT 'warehouse'::character varying NOT NULL,
    delivery_warehouse_id uuid,
    delivery_customer_id uuid,
    warehouse_id uuid NOT NULL,
    discount_level character varying(20) DEFAULT 'transaction'::character varying,
    discount numeric(15,2) DEFAULT 0.00,
    discount_type character varying(20) DEFAULT 'percentage'::character varying,
    total_quantity numeric(15,2) DEFAULT 0.00,
    currency character varying(20) DEFAULT 'INR'::character varying,
    subtotal numeric(15,2) DEFAULT 0.00,
    tax_amount numeric(15,2) DEFAULT 0.00,
    tax_type character varying(20) DEFAULT 'exclusive'::character varying,
    tds_tcs_type character varying(10) DEFAULT 'none'::character varying,
    tds_id uuid,
    tds_tcs_amount numeric(15,2) DEFAULT 0.00,
    adjustment numeric(15,2) DEFAULT 0.00,
    total numeric(15,2) DEFAULT 0.00,
    status character varying(50) DEFAULT 'Draft'::character varying,
    notes text,
    terms_and_conditions text,
    is_reverse_charge boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    entity_id uuid NOT NULL,
    is_delete boolean NOT NULL,
    discount_account_id uuid NOT NULL
);


--
-- Name: purchase_receive_item_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_receive_item_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_receive_item_id uuid NOT NULL,
    product_id uuid NOT NULL,
    warehouse_id uuid,
    bin_id uuid,
    bin_label character varying,
    batch_no character varying NOT NULL,
    unit_pack character varying,
    mrp numeric,
    ptr numeric,
    quantity numeric DEFAULT 0 NOT NULL,
    foc_qty numeric DEFAULT 0 NOT NULL,
    manufacture_batch_number character varying,
    manufacture_date date,
    expiry_date date NOT NULL,
    is_damaged boolean DEFAULT false NOT NULL,
    damaged_qty numeric DEFAULT 0 NOT NULL,
    entity_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: purchase_receive_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_receive_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_receive_id uuid NOT NULL,
    item_id uuid,
    item_name character varying NOT NULL,
    description text,
    ordered numeric DEFAULT 0 NOT NULL,
    received numeric DEFAULT 0 NOT NULL,
    in_transit numeric DEFAULT 0 NOT NULL,
    quantity_to_receive numeric DEFAULT 0 NOT NULL,
    warehouse_id uuid,
    bin_id uuid,
    bin_label character varying,
    entity_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: purchase_receives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_receives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_receive_number character varying NOT NULL,
    received_date date NOT NULL,
    vendor_name character varying,
    purchase_order_id uuid,
    purchase_order_number character varying,
    warehouse_id uuid,
    transaction_bin_id uuid,
    transaction_bin_label character varying,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    notes text,
    entity_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_delete boolean NOT NULL,
    bill_no character varying,
    bill_date date,
    bill_invoice_total numeric
);


--
-- Name: purchase_return_item_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_return_item_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_return_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    bin_id uuid,
    quantity_out numeric(15,3) NOT NULL,
    foc_qty numeric(15,3) DEFAULT 0,
    damage_qty numeric(15,3) DEFAULT 0,
    unit_pack character varying(50),
    mrp numeric(15,2),
    purchase_rate numeric(15,2),
    expiry_date date,
    manufacture_date date,
    manufacture_batch_no character varying(100),
    remarks text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: purchase_return_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_return_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_return_id uuid NOT NULL,
    product_id uuid NOT NULL,
    bill_item_id uuid,
    account_id uuid,
    invoiced_qty numeric(15,3) DEFAULT 0,
    already_returned_qty numeric(15,3) DEFAULT 0,
    return_qty numeric(15,3) DEFAULT 0,
    credited_qty numeric(15,3) DEFAULT 0,
    pending_credit_qty numeric(15,3) DEFAULT 0,
    rate numeric(15,2) DEFAULT 0,
    discount_percent numeric(8,2) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    tax_id uuid,
    tax_amount numeric(15,2) DEFAULT 0,
    line_total numeric(15,2) DEFAULT 0,
    remarks text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: purchase_returns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_returns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    warehouse_id uuid,
    purchase_return_number character varying(50) NOT NULL,
    purchase_return_date date NOT NULL,
    bill_id uuid,
    reference_number character varying(100),
    reason text,
    subject text,
    notes text,
    subtotal numeric(15,2) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    tax_amount numeric(15,2) DEFAULT 0,
    adjustment_amount numeric(15,2) DEFAULT 0,
    total_amount numeric(15,2) DEFAULT 0,
    credit_status character varying(30) DEFAULT 'pending'::character varying,
    status character varying(30) DEFAULT 'draft'::character varying,
    created_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: racks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.racks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rack_code character varying(50) NOT NULL,
    rack_name character varying(255),
    storage_id uuid,
    capacity integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: recurring_journal_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurring_journal_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recurring_journal_id uuid NOT NULL,
    account_id uuid NOT NULL,
    description text,
    contact_id uuid,
    contact_type character varying,
    debit numeric DEFAULT 0.00,
    credit numeric DEFAULT 0.00,
    sort_order integer,
    contact_name character varying(255)
);


--
-- Name: recurring_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurring_journals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    profile_name character varying NOT NULL,
    repeat_every character varying NOT NULL,
    "interval" integer DEFAULT 1 NOT NULL,
    start_date date NOT NULL,
    end_date date,
    never_expires boolean DEFAULT true,
    reference_number character varying,
    notes text,
    currency_code character varying DEFAULT 'INR'::character varying,
    reporting_method character varying DEFAULT 'accrual_and_cash'::character varying,
    status character varying DEFAULT 'active'::character varying,
    last_generated_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    created_by uuid,
    entity_id uuid NOT NULL
);


--
-- Name: reorder_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reorder_terms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    term_name character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    quantity integer DEFAULT 1 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL,
    CONSTRAINT reorder_terms_quantity_positive CHECK ((quantity > 0))
);


--
-- Name: reporting_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reporting_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tag_name character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    entity_id uuid NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    label character varying(100) NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    permissions jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: sales_order_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_order_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sales_order_id uuid NOT NULL,
    file_name character varying(255) NOT NULL,
    file_path text NOT NULL,
    file_size character varying,
    file_type character varying(100),
    source character varying(50) DEFAULT 'upload'::character varying,
    uploaded_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: sales_order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sales_order_id uuid NOT NULL,
    line_no integer DEFAULT 1 NOT NULL,
    product_id uuid NOT NULL,
    description text,
    quantity numeric(15,3) DEFAULT 0.000 NOT NULL,
    free_quantity numeric(15,3) DEFAULT 0.000 NOT NULL,
    rate numeric(15,2) DEFAULT 0.00 NOT NULL,
    discount_type character varying(10) DEFAULT '%'::character varying,
    discount_value numeric(15,2) DEFAULT 0.00 NOT NULL,
    discount_amount numeric(15,2) DEFAULT 0.00 NOT NULL,
    tax_id uuid,
    tax_rate numeric(9,4) DEFAULT 0.0000 NOT NULL,
    tax_amount numeric(15,2) DEFAULT 0.00 NOT NULL,
    amount numeric(15,2) DEFAULT 0.00 NOT NULL,
    mrp numeric(15,2) DEFAULT 0.00 NOT NULL,
    batch_id uuid,
    warehouse_id uuid,
    line_meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL,
    hsn_code numeric NOT NULL,
    accounts uuid NOT NULL,
    pricelist character varying,
    is_invoiced boolean NOT NULL,
    CONSTRAINT sales_order_items_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['%'::character varying, 'value'::character varying])::text[])))
);


--
-- Name: sales_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    transaction_series character varying(100),
    sale_number character varying(100),
    reference character varying(100),
    sale_date timestamp without time zone DEFAULT now(),
    expected_shipment_date timestamp without time zone,
    delivery_method character varying(100),
    payment_terms character varying(100),
    payment_term_id uuid,
    salesperson_id character varying(255),
    salesperson_name character varying(255),
    warehouse_id uuid,
    warehouse_name character varying(255),
    price_list_id uuid,
    place_of_supply character varying(100),
    document_type character varying(50) NOT NULL,
    status character varying(50) DEFAULT 'Draft'::character varying,
    sub_total numeric(15,2) DEFAULT 0.00 NOT NULL,
    tax_total numeric(15,2) DEFAULT 0.00 NOT NULL,
    discount_total numeric(15,2) DEFAULT 0.00 NOT NULL,
    shipping_charges numeric(15,2) DEFAULT 0.00 NOT NULL,
    tds_tcs_type character varying(10) DEFAULT 'TDS'::character varying,
    tds_tcs_tax_id uuid,
    tds_tcs_amount numeric(15,2) DEFAULT 0.00 NOT NULL,
    adjustment numeric(15,2) DEFAULT 0.00 NOT NULL,
    round_off numeric(15,2) DEFAULT 0.00 NOT NULL,
    total_quantity numeric(15,3) DEFAULT 0.000 NOT NULL,
    total numeric(15,2) DEFAULT 0.00 NOT NULL,
    currency character varying(20) DEFAULT 'INR'::character varying,
    customer_notes text,
    terms_and_conditions text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL,
    is_delete boolean NOT NULL,
    CONSTRAINT sales_orders_tds_tcs_type_check CHECK (((tds_tcs_type)::text = ANY ((ARRAY['TDS'::character varying, 'TCS'::character varying])::text[])))
);


--
-- Name: sales_payment_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_payment_links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    link_url text NOT NULL,
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: sales_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    payment_number character varying(100),
    payment_date timestamp without time zone DEFAULT now(),
    payment_mode character varying(50),
    amount numeric(15,2) NOT NULL,
    bank_charges numeric(15,2) DEFAULT 0.00,
    reference character varying(100),
    deposit_to character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: sales_reps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_reps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    entity_id uuid,
    name character varying(255) NOT NULL,
    number character varying(100),
    brand_id uuid,
    division character varying(255),
    area character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sales_return_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_return_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sales_return_id uuid NOT NULL,
    product_id uuid NOT NULL,
    sales_invoice_item_id uuid,
    invoiced_qty numeric(15,3) DEFAULT 0,
    already_returned_qty numeric(15,3) DEFAULT 0,
    return_qty numeric(15,3) DEFAULT 0,
    receivable_qty numeric(15,3) DEFAULT 0,
    credit_only_qty numeric(15,3) DEFAULT 0,
    remarks text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: sales_return_receive_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_return_receive_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sales_return_receive_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid,
    warehouse_id uuid NOT NULL,
    bin_id uuid NOT NULL,
    quantity numeric(15,3) DEFAULT 0 NOT NULL,
    foc_quantity numeric(15,3) DEFAULT 0,
    purchase_rate numeric(15,2),
    mrp numeric(15,2),
    expiry_date date,
    manufacture_date date,
    manufacture_batch_no character varying(100),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: sales_return_receive_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_return_receive_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sales_return_receive_id uuid NOT NULL,
    sales_return_item_id uuid,
    product_id uuid NOT NULL,
    return_qty numeric(15,3) DEFAULT 0,
    already_received_qty numeric(15,3) DEFAULT 0,
    receiving_qty numeric(15,3) DEFAULT 0,
    remarks text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: sales_return_receives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_return_receives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sales_return_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    receive_number character varying(50) NOT NULL,
    receive_date date NOT NULL,
    warehouse_id uuid,
    notes text,
    status character varying(30) DEFAULT 'received'::character varying,
    created_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: sales_returns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_returns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    rma_number character varying(50) NOT NULL,
    return_date date NOT NULL,
    warehouse_id uuid,
    reason text,
    reference_number character varying(100),
    contains_credit_only_goods boolean DEFAULT false NOT NULL,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL,
    notes text,
    created_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: shipment_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shipment_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.states (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    state_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(10),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: storage_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.storage_conditions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_name character varying(255) NOT NULL,
    temperature_range character varying(50),
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    display_text character varying(255),
    common_examples text,
    min_temp_c numeric(5,2),
    max_temp_c numeric(5,2),
    is_cold_chain boolean DEFAULT false NOT NULL,
    requires_fridge boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    storage_type character varying(255)
);


--
-- Name: tax_group_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_group_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tax_group_id uuid,
    tax_id uuid,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: tax_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tax_group_name character varying(100) NOT NULL,
    tax_rate numeric(5,2) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: tax_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tax_name character varying(100) NOT NULL,
    tax_rate numeric(5,2) NOT NULL,
    tax_type public.tax_type,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: tds_group_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tds_group_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tds_group_id uuid,
    tds_rate_id uuid,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: tds_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tds_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_name character varying(255) NOT NULL,
    applicable_from timestamp without time zone,
    applicable_to timestamp without time zone,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: tds_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tds_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tax_name character varying(255) NOT NULL,
    section_id uuid,
    base_rate numeric(5,2) NOT NULL,
    surcharge_rate numeric(5,2) DEFAULT 0.00,
    cess_rate numeric(5,2) DEFAULT 0.00,
    payable_account_id uuid,
    receivable_account_id uuid,
    is_higher_rate boolean DEFAULT false,
    reason_higher_rate text,
    applicable_from timestamp without time zone,
    applicable_to timestamp without time zone,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: tds_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tds_sections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    section_name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: timezones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timezones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    tzdb_name character varying(100) NOT NULL,
    utc_offset character varying(10) NOT NULL,
    display character varying(255) NOT NULL,
    country_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    sort_order smallint DEFAULT 0 NOT NULL
);


--
-- Name: transaction_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_locks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    module_name character varying(100) NOT NULL,
    lock_date timestamp without time zone NOT NULL,
    reason text,
    updated_at timestamp without time zone DEFAULT now(),
    entity_id uuid NOT NULL
);


--
-- Name: transaction_series; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_series (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid,
    name character varying(255) NOT NULL,
    modules jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    code character varying(50),
    branch_code character varying(50),
    warehouse_code character varying(50),
    entity_id uuid NOT NULL
);


--
-- Name: transaction_series_modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_series_modules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transaction_series_placeholders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_series_placeholders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    token character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transaction_series_restart_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_series_restart_options (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    label character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transactional_sequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactional_sequences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    module character varying NOT NULL,
    prefix character varying DEFAULT ''::character varying NOT NULL,
    suffix character varying DEFAULT ''::character varying,
    next_number integer DEFAULT 1 NOT NULL,
    padding integer DEFAULT 5 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    entity_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: transfer_order_destination_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfer_order_destination_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_item_id uuid NOT NULL,
    source_batch_id uuid NOT NULL,
    destination_batch_id uuid NOT NULL,
    destination_warehouse_id uuid NOT NULL,
    destination_bin_id uuid NOT NULL,
    qty numeric(15,3) NOT NULL,
    CONSTRAINT transfer_order_destination_batches_qty_chk CHECK ((qty > (0)::numeric))
);


--
-- Name: transfer_order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfer_order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_order_id uuid NOT NULL,
    product_id uuid NOT NULL,
    qty_requested numeric(15,3) NOT NULL,
    qty_transferred numeric(15,3) DEFAULT 0 NOT NULL,
    unit character varying(20),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT transfer_order_items_qty_requested_chk CHECK ((qty_requested > (0)::numeric)),
    CONSTRAINT transfer_order_items_qty_transferred_chk CHECK ((qty_transferred >= (0)::numeric))
);


--
-- Name: transfer_order_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfer_order_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_order_id uuid NOT NULL,
    action character varying(50) NOT NULL,
    action_by uuid,
    action_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transfer_order_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfer_order_master (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_no character varying(50) NOT NULL,
    transfer_date date NOT NULL,
    entity_id uuid NOT NULL,
    source_warehouse_id uuid NOT NULL,
    destination_warehouse_id uuid NOT NULL,
    status character varying(30) DEFAULT 'DRAFT'::character varying NOT NULL,
    reason text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT transfer_order_master_source_dest_diff_chk CHECK ((source_warehouse_id <> destination_warehouse_id)),
    CONSTRAINT transfer_order_master_status_chk CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'INITIATED'::character varying, 'RECEIVED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: transfer_order_source_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfer_order_source_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    bin_id uuid NOT NULL,
    qty numeric(15,3) NOT NULL,
    CONSTRAINT transfer_order_source_batches_qty_chk CHECK ((qty > (0)::numeric))
);


--
-- Name: units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    unit_name character varying(50) NOT NULL,
    unit_type public.unit_type,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    unit_symbol character varying(10),
    uqc_id uuid
);


--
-- Name: uqc; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uqc (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    uqc_code character varying(20) NOT NULL,
    description character varying(255) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: user_branch_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_branch_access (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    user_id uuid NOT NULL,
    is_default_business boolean DEFAULT false NOT NULL,
    is_default_warehouse boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'user'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id uuid NOT NULL,
    default_warehouse_id uuid
);


--
-- Name: v_accounting_stock; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_accounting_stock AS
 SELECT product_id,
    entity_id,
    warehouse_id,
    sum((qty_in - qty_out)) AS stock_on_hand,
    (0)::numeric AS committed_stock,
    sum((qty_in - qty_out)) AS available_stock
   FROM public.batch_transactions bt
  WHERE ((trans_type)::text = ANY ((ARRAY['BILL'::character varying, 'INVOICE'::character varying, 'CREDIT_NOTE'::character varying, 'VENDOR_CREDIT'::character varying, 'ADJUSTMENT'::character varying, 'TRANSFER_IN'::character varying, 'TRANSFER_OUT'::character varying])::text[]))
  GROUP BY product_id, entity_id, warehouse_id;


--
-- Name: v_batch_wise_stock; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_batch_wise_stock AS
 SELECT bsl.batch_id,
    bm.batch_no,
    bm.expiry_date,
    bsl.product_id,
    bsl.entity_id,
    bsl.warehouse_id,
    sum(bsl.qty) AS stock_on_hand,
    sum(bsl.reserved_qty) AS committed_stock,
    sum((bsl.qty - bsl.reserved_qty)) AS available_stock
   FROM (public.batch_stock_layers bsl
     JOIN public.batch_master bm ON ((bm.id = bsl.batch_id)))
  GROUP BY bsl.batch_id, bm.batch_no, bm.expiry_date, bsl.product_id, bsl.entity_id, bsl.warehouse_id;


--
-- Name: v_bin_wise_stock; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_bin_wise_stock AS
 SELECT product_id,
    entity_id,
    warehouse_id,
    bin_id,
    sum(qty) AS stock_on_hand,
    sum(reserved_qty) AS committed_stock,
    sum((qty - reserved_qty)) AS available_stock
   FROM public.batch_stock_layers bsl
  GROUP BY product_id, entity_id, warehouse_id, bin_id;


--
-- Name: v_physical_stock; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_physical_stock AS
 SELECT product_id,
    entity_id,
    warehouse_id,
    sum(qty) AS stock_on_hand,
    sum(reserved_qty) AS committed_stock,
    sum((qty - reserved_qty)) AS available_stock
   FROM public.batch_stock_layers bsl
  GROUP BY product_id, entity_id, warehouse_id;


--
-- Name: v_product_stock_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_product_stock_summary AS
 SELECT p.id AS product_id,
    p.product_name,
    ps.entity_id,
    ps.warehouse_id,
    COALESCE(ps.stock_on_hand, (0)::numeric) AS physical_stock,
    COALESCE(ac.stock_on_hand, (0)::numeric) AS accounting_stock,
    COALESCE(ps.committed_stock, (0)::numeric) AS committed_stock,
    COALESCE(ps.available_stock, (0)::numeric) AS available_stock,
    (COALESCE(ps.stock_on_hand, (0)::numeric) - COALESCE(ac.stock_on_hand, (0)::numeric)) AS stock_variance
   FROM ((public.products p
     LEFT JOIN public.v_physical_stock ps ON ((ps.product_id = p.id)))
     LEFT JOIN public.v_accounting_stock ac ON (((ac.product_id = p.id) AND (ac.entity_id = ps.entity_id) AND (ac.warehouse_id = ps.warehouse_id))));


--
-- Name: vendor_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    address_type character varying(30) DEFAULT 'additional'::character varying NOT NULL,
    attention text,
    address_street text,
    address_place text,
    city text,
    state text,
    pincode text,
    country_region text DEFAULT 'India'::text,
    phone text,
    fax text,
    email character varying(255),
    mobile character varying(50),
    gstin character varying(50),
    gst_treatment character varying(100),
    is_default_billing boolean DEFAULT false NOT NULL,
    is_default_shipping boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT vendor_addresses_address_type_check CHECK (((address_type)::text = ANY ((ARRAY['billing'::character varying, 'shipping'::character varying, 'additional'::character varying])::text[])))
);


--
-- Name: vendor_bank_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_bank_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_id uuid,
    holder_name text,
    bank_name text,
    account_number text,
    ifsc text,
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: vendor_contact_persons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_contact_persons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_id uuid,
    salutation text,
    first_name text,
    last_name text,
    email text,
    work_phone text,
    mobile_phone text,
    designation text,
    department text,
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: vendor_credit_item_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_credit_item_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_credit_item_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    layer_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    bin_id uuid,
    quantity_out numeric(15,3) NOT NULL,
    foc_qty numeric(15,3) DEFAULT 0,
    unit_pack character varying(50),
    mrp numeric(15,2),
    purchase_rate numeric(15,2),
    expiry_date date,
    manufacture_date date,
    manufacture_batch_no character varying(100),
    remarks text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: vendor_credit_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_credit_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_credit_id uuid NOT NULL,
    purchase_return_item_id uuid,
    product_id uuid NOT NULL,
    bill_item_id uuid,
    account_id uuid,
    quantity numeric(15,3) DEFAULT 0,
    rate numeric(15,2) DEFAULT 0,
    discount_percent numeric(8,2) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    tax_id uuid,
    tax_amount numeric(15,2) DEFAULT 0,
    line_total numeric(15,2) DEFAULT 0,
    remarks text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: vendor_credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_credits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    warehouse_id uuid,
    vendor_credit_number character varying(50) NOT NULL,
    vendor_credit_date date NOT NULL,
    source_type character varying(30) DEFAULT 'DIRECT'::character varying,
    purchase_return_id uuid,
    bill_id uuid,
    reference_number character varying(100),
    subject text,
    notes text,
    reverse_charge_applicable boolean DEFAULT false,
    subtotal numeric(15,2) DEFAULT 0,
    discount_amount numeric(15,2) DEFAULT 0,
    tax_amount numeric(15,2) DEFAULT 0,
    adjustment_amount numeric(15,2) DEFAULT 0,
    total_amount numeric(15,2) DEFAULT 0,
    status character varying(30) DEFAULT 'draft'::character varying,
    created_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: vendors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_number character varying(100),
    display_name character varying(255) NOT NULL,
    salutation character varying(20),
    first_name character varying(255),
    last_name character varying(255),
    company_name character varying(255),
    email character varying(255),
    phone character varying(50),
    mobile_phone character varying(50),
    designation character varying(255),
    department character varying(255),
    website character varying(255),
    vendor_language character varying(50) DEFAULT 'English'::character varying,
    gst_treatment character varying(100),
    gstin character varying(50),
    source_of_supply character varying(100),
    pan character varying(50),
    currency character varying(20) DEFAULT 'INR'::character varying,
    payment_terms character varying(100),
    is_msme_registered boolean DEFAULT false,
    msme_registration_type character varying(100),
    msme_registration_number character varying(100),
    is_drug_registered boolean DEFAULT false,
    drug_licence_type character varying(100),
    drug_license_20 character varying(100),
    drug_license_21 character varying(100),
    drug_license_20b character varying(100),
    drug_license_21b character varying(100),
    is_fssai_registered boolean DEFAULT false,
    fssai_number character varying(100),
    tds_rate_id character varying(100),
    enable_portal boolean DEFAULT false,
    remarks text,
    x_handle character varying(255),
    facebook_handle character varying(255),
    whatsapp_number character varying(255),
    source character varying(50) DEFAULT 'User'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    price_list_id uuid,
    entity_id uuid NOT NULL
);


--
-- Name: warehouses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    attention text,
    street text,
    place text,
    city text,
    state text,
    phone character varying(50),
    email character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    warehouse_code character varying(50),
    pincode character varying(20),
    country character varying(100) DEFAULT 'India'::character varying NOT NULL,
    customer_id uuid,
    vendor_id uuid,
    district_id uuid,
    local_body_id uuid,
    ward_id uuid,
    assembly_id uuid,
    entity_id uuid NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    source_branch_id uuid,
    is_default_for_branch boolean DEFAULT false NOT NULL
);


--
-- Name: zone_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zone_levels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    zone_id uuid NOT NULL,
    level_no integer NOT NULL,
    level_name character varying(100),
    alias character varying(50),
    delimiter character varying(5) DEFAULT '-'::character varying,
    total integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: zone_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zone_master (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    zone_name character varying(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    selected_columns text[],
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb,
    metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: supabase_migrations; Owner: -
--

CREATE TABLE supabase_migrations.schema_migrations (
    version text NOT NULL,
    statements text[],
    name text,
    created_by text,
    idempotency_key text,
    rollback text[]
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: __drizzle_migrations id; Type: DEFAULT; Schema: drizzle; Owner: -
--

ALTER TABLE ONLY drizzle.__drizzle_migrations ALTER COLUMN id SET DEFAULT nextval('drizzle.__drizzle_migrations_id_seq'::regclass);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webauthn_challenges webauthn_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: __drizzle_migrations __drizzle_migrations_pkey; Type: CONSTRAINT; Schema: drizzle; Owner: -
--

ALTER TABLE ONLY drizzle.__drizzle_migrations
    ADD CONSTRAINT __drizzle_migrations_pkey PRIMARY KEY (id);


--
-- Name: account_transactions account_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_account_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_account_code_unique UNIQUE (account_code);


--
-- Name: fiscal_years accounts_fiscal_years_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fiscal_years
    ADD CONSTRAINT accounts_fiscal_years_pkey PRIMARY KEY (id);


--
-- Name: journal_number_settings accounts_journal_number_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_number_settings
    ADD CONSTRAINT accounts_journal_number_settings_pkey PRIMARY KEY (id);


--
-- Name: journal_template_items accounts_journal_template_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_template_items
    ADD CONSTRAINT accounts_journal_template_items_pkey PRIMARY KEY (id);


--
-- Name: journal_templates accounts_journal_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_templates
    ADD CONSTRAINT accounts_journal_templates_pkey PRIMARY KEY (id);


--
-- Name: manual_journal_attachments accounts_manual_journal_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_attachments
    ADD CONSTRAINT accounts_manual_journal_attachments_pkey PRIMARY KEY (id);


--
-- Name: manual_journal_items accounts_manual_journal_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_items
    ADD CONSTRAINT accounts_manual_journal_items_pkey PRIMARY KEY (id);


--
-- Name: manual_journal_tag_mappings accounts_manual_journal_tag_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_tag_mappings
    ADD CONSTRAINT accounts_manual_journal_tag_mappings_pkey PRIMARY KEY (manual_journal_item_id, reporting_tag_id);


--
-- Name: manual_journals accounts_manual_journals_journal_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journals
    ADD CONSTRAINT accounts_manual_journals_journal_number_unique UNIQUE (journal_number);


--
-- Name: manual_journals accounts_manual_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journals
    ADD CONSTRAINT accounts_manual_journals_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey1 PRIMARY KEY (id);


--
-- Name: recurring_journal_items accounts_recurring_journal_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_journal_items
    ADD CONSTRAINT accounts_recurring_journal_items_pkey PRIMARY KEY (id);


--
-- Name: recurring_journals accounts_recurring_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_journals
    ADD CONSTRAINT accounts_recurring_journals_pkey PRIMARY KEY (id);


--
-- Name: reporting_tags accounts_reporting_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reporting_tags
    ADD CONSTRAINT accounts_reporting_tags_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_system_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_system_name_unique UNIQUE (system_account_name);


--
-- Name: audit_logs_archive audit_logs_archive_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs_archive
    ADD CONSTRAINT audit_logs_archive_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: batch_master batch_master_batch_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_master
    ADD CONSTRAINT batch_master_batch_no_key UNIQUE (batch_no);


--
-- Name: batch_stock_layers batch_stock_layers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_stock_layers
    ADD CONSTRAINT batch_stock_layers_pkey PRIMARY KEY (id);


--
-- Name: batch_transactions batch_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_transactions
    ADD CONSTRAINT batch_transactions_pkey PRIMARY KEY (id);


--
-- Name: batch_master batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_master
    ADD CONSTRAINT batches_pkey PRIMARY KEY (id);


--
-- Name: bill_attachments bill_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_attachments
    ADD CONSTRAINT bill_attachments_pkey PRIMARY KEY (id);


--
-- Name: bill_item_batches bill_item_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_item_batches
    ADD CONSTRAINT bill_item_batches_pkey PRIMARY KEY (id);


--
-- Name: bill_items bill_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_items
    ADD CONSTRAINT bill_items_pkey PRIMARY KEY (id);


--
-- Name: bill_landed_costs bill_landed_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_landed_costs
    ADD CONSTRAINT bill_landed_costs_pkey PRIMARY KEY (id);


--
-- Name: bills bills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bills
    ADD CONSTRAINT bills_pkey PRIMARY KEY (id);


--
-- Name: bin_master bin_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_master
    ADD CONSTRAINT bin_master_pkey PRIMARY KEY (id);


--
-- Name: branch_price_list_assignments branch_price_list_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_price_list_assignments
    ADD CONSTRAINT branch_price_list_assignments_pkey PRIMARY KEY (id);


--
-- Name: branch_price_list_assignments branch_price_list_assignments_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_price_list_assignments
    ADD CONSTRAINT branch_price_list_assignments_unique UNIQUE (price_list_id, branch_entity_id);


--
-- Name: brands brands_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_name_unique UNIQUE (name);


--
-- Name: brands brands_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey1 PRIMARY KEY (id);


--
-- Name: buying_rules buying_rules_buying_rule_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.buying_rules
    ADD CONSTRAINT buying_rules_buying_rule_key UNIQUE (buying_rule);


--
-- Name: buying_rules buying_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.buying_rules
    ADD CONSTRAINT buying_rules_pkey PRIMARY KEY (id);


--
-- Name: carrier carrier_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carrier
    ADD CONSTRAINT carrier_name_key UNIQUE (name);


--
-- Name: carrier carrier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carrier
    ADD CONSTRAINT carrier_pkey PRIMARY KEY (id);


--
-- Name: categories categories_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_unique UNIQUE (name);


--
-- Name: categories categories_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey1 PRIMARY KEY (id);


--
-- Name: company_id_labels company_id_labels_label_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_id_labels
    ADD CONSTRAINT company_id_labels_label_key UNIQUE (label);


--
-- Name: company_id_labels company_id_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_id_labels
    ADD CONSTRAINT company_id_labels_pkey PRIMARY KEY (id);


--
-- Name: composite_item_branch_inventory_settings composite_item_branch_inventory_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_branch_inventory_settings
    ADD CONSTRAINT composite_item_branch_inventory_settings_pkey PRIMARY KEY (id);


--
-- Name: composite_item_parts composite_item_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_parts
    ADD CONSTRAINT composite_item_parts_pkey PRIMARY KEY (id);


--
-- Name: composite_items composite_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_pkey PRIMARY KEY (id);


--
-- Name: composite_items composite_items_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_sku_key UNIQUE (sku);


--
-- Name: contents contents_content_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contents
    ADD CONSTRAINT contents_content_name_key UNIQUE (content_name);


--
-- Name: contents contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);


--
-- Name: countries countries_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_name_key UNIQUE (name);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: credit_note_item_batches credit_note_item_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_item_batches
    ADD CONSTRAINT credit_note_item_batches_pkey PRIMARY KEY (id);


--
-- Name: credit_note_items credit_note_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_items
    ADD CONSTRAINT credit_note_items_pkey PRIMARY KEY (id);


--
-- Name: credit_notes credit_notes_credit_note_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_notes
    ADD CONSTRAINT credit_notes_credit_note_number_key UNIQUE (credit_note_number);


--
-- Name: credit_notes credit_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_notes
    ADD CONSTRAINT credit_notes_pkey PRIMARY KEY (id);


--
-- Name: currencies currencies_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_code_key UNIQUE (code);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: customer_contact_persons customer_contact_persons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contact_persons
    ADD CONSTRAINT customer_contact_persons_pkey PRIMARY KEY (id);


--
-- Name: customers customers_customer_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_customer_number_key UNIQUE (customer_number);


--
-- Name: customers customers_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey1 PRIMARY KEY (id);


--
-- Name: hsn_sac_codes hsn_sac_codes_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hsn_sac_codes
    ADD CONSTRAINT hsn_sac_codes_code_key UNIQUE (code);


--
-- Name: hsn_sac_codes hsn_sac_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hsn_sac_codes
    ADD CONSTRAINT hsn_sac_codes_pkey PRIMARY KEY (id);


--
-- Name: transaction_locks idx_org_module_lock; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_locks
    ADD CONSTRAINT idx_org_module_lock UNIQUE (org_id, module_name);


--
-- Name: industries industries_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.industries
    ADD CONSTRAINT industries_name_key UNIQUE (name);


--
-- Name: industries industries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.industries
    ADD CONSTRAINT industries_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustment_account_entries inventory_adjustment_account_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_account_entries
    ADD CONSTRAINT inventory_adjustment_account_entries_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustment_attachments inventory_adjustment_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_attachments
    ADD CONSTRAINT inventory_adjustment_attachments_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustment_items inventory_adjustment_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_items
    ADD CONSTRAINT inventory_adjustment_items_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustment_reasons inventory_adjustment_reasons_entity_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_reasons
    ADD CONSTRAINT inventory_adjustment_reasons_entity_id_name_key UNIQUE (entity_id, name);


--
-- Name: inventory_adjustment_reasons inventory_adjustment_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_reasons
    ADD CONSTRAINT inventory_adjustment_reasons_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustment_value_items inventory_adjustment_value_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_value_items
    ADD CONSTRAINT inventory_adjustment_value_items_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustments inventory_adjustments_adjustment_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_adjustment_number_key UNIQUE (adjustment_number);


--
-- Name: inventory_adjustments inventory_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_pkey PRIMARY KEY (id);


--
-- Name: inventory_move_order_destination_bins inventory_move_order_destination_bins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_order_destination_bins
    ADD CONSTRAINT inventory_move_order_destination_bins_pkey PRIMARY KEY (id);


--
-- Name: inventory_move_order_items inventory_move_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_order_items
    ADD CONSTRAINT inventory_move_order_items_pkey PRIMARY KEY (id);


--
-- Name: inventory_move_order_source_batches inventory_move_order_source_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_order_source_batches
    ADD CONSTRAINT inventory_move_order_source_batches_pkey PRIMARY KEY (id);


--
-- Name: inventory_move_orders inventory_move_orders_move_order_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_orders
    ADD CONSTRAINT inventory_move_orders_move_order_number_key UNIQUE (move_order_number);


--
-- Name: inventory_move_orders inventory_move_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_orders
    ADD CONSTRAINT inventory_move_orders_pkey PRIMARY KEY (id);


--
-- Name: inventory_package_items inventory_package_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_package_items
    ADD CONSTRAINT inventory_package_items_pkey PRIMARY KEY (id);


--
-- Name: inventory_package_sales_orders inventory_package_sales_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_package_sales_orders
    ADD CONSTRAINT inventory_package_sales_orders_pkey PRIMARY KEY (package_id, sales_order_id);


--
-- Name: inventory_packages inventory_packages_package_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_packages
    ADD CONSTRAINT inventory_packages_package_number_key UNIQUE (package_number);


--
-- Name: inventory_packages inventory_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_packages
    ADD CONSTRAINT inventory_packages_pkey PRIMARY KEY (id);


--
-- Name: inventory_shipment_packages inventory_shipment_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipment_packages
    ADD CONSTRAINT inventory_shipment_packages_pkey PRIMARY KEY (shipment_id, package_id);


--
-- Name: inventory_shipment_sales_orders inventory_shipment_sales_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipment_sales_orders
    ADD CONSTRAINT inventory_shipment_sales_orders_pkey PRIMARY KEY (shipment_id, sales_order_id);


--
-- Name: inventory_shipments inventory_shipments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipments
    ADD CONSTRAINT inventory_shipments_pkey PRIMARY KEY (id);


--
-- Name: inventory_shipments inventory_shipments_shipment_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipments
    ADD CONSTRAINT inventory_shipments_shipment_number_unique UNIQUE (shipment_number);


--
-- Name: inventory_stock_commitments inventory_stock_commitments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_stock_commitments
    ADD CONSTRAINT inventory_stock_commitments_pkey PRIMARY KEY (id);


--
-- Name: invoice_attachments invoice_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_attachments
    ADD CONSTRAINT invoice_attachments_pkey PRIMARY KEY (id);


--
-- Name: invoice_item_batches invoice_item_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item_batches
    ADD CONSTRAINT invoice_item_batches_pkey PRIMARY KEY (id);


--
-- Name: invoice_items invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);


--
-- Name: invoice_master invoice_master_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_master
    ADD CONSTRAINT invoice_master_invoice_number_key UNIQUE (invoice_number);


--
-- Name: invoice_master invoice_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_master
    ADD CONSTRAINT invoice_master_pkey PRIMARY KEY (id);


--
-- Name: invoice_packages invoice_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_packages
    ADD CONSTRAINT invoice_packages_pkey PRIMARY KEY (id);


--
-- Name: invoice_sales_orders invoice_sales_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_sales_orders
    ADD CONSTRAINT invoice_sales_orders_pkey PRIMARY KEY (id);


--
-- Name: invoice_shipments invoice_shipments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_shipments
    ADD CONSTRAINT invoice_shipments_pkey PRIMARY KEY (id);


--
-- Name: product_vendor_mappings item_vendor_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_vendor_mappings
    ADD CONSTRAINT item_vendor_mappings_pkey PRIMARY KEY (id);


--
-- Name: manufacturers manufacturers_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_name_unique UNIQUE (name);


--
-- Name: manufacturers manufacturers_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_pkey1 PRIMARY KEY (id);


--
-- Name: move_order_attachments move_order_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.move_order_attachments
    ADD CONSTRAINT move_order_attachments_pkey PRIMARY KEY (id);


--
-- Name: organisation_branch_master organisation_branch_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisation_branch_master
    ADD CONSTRAINT organisation_branch_master_pkey PRIMARY KEY (id);


--
-- Name: organisation_branch_master organisation_branch_master_ref_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisation_branch_master
    ADD CONSTRAINT organisation_branch_master_ref_id_key UNIQUE (ref_id);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organization organization_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_slug_key UNIQUE (slug);


--
-- Name: payment_received_allocations payment_received_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_received_allocations
    ADD CONSTRAINT payment_received_allocations_pkey PRIMARY KEY (id);


--
-- Name: payment_terms payment_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_terms
    ADD CONSTRAINT payment_terms_pkey PRIMARY KEY (id);


--
-- Name: payment_terms payment_terms_term_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_terms
    ADD CONSTRAINT payment_terms_term_name_key UNIQUE (term_name);


--
-- Name: payments_received payments_received_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments_received
    ADD CONSTRAINT payments_received_pkey PRIMARY KEY (id);


--
-- Name: picklist_batch_allocation picklist_batch_allocation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.picklist_batch_allocation
    ADD CONSTRAINT picklist_batch_allocation_pkey PRIMARY KEY (id);


--
-- Name: picklist_items picklist_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.picklist_items
    ADD CONSTRAINT picklist_items_pkey PRIMARY KEY (id);


--
-- Name: picklist_master picklist_master_picklist_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.picklist_master
    ADD CONSTRAINT picklist_master_picklist_no_key UNIQUE (picklist_no);


--
-- Name: picklist_master picklist_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.picklist_master
    ADD CONSTRAINT picklist_master_pkey PRIMARY KEY (id);


--
-- Name: price_list_items price_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_pkey PRIMARY KEY (id);


--
-- Name: price_list_items price_list_items_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_unique UNIQUE (price_list_id, product_id);


--
-- Name: price_list_volume_ranges price_list_volume_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_volume_ranges
    ADD CONSTRAINT price_list_volume_ranges_pkey PRIMARY KEY (id);


--
-- Name: price_lists price_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_lists
    ADD CONSTRAINT price_lists_pkey PRIMARY KEY (id);


--
-- Name: product_bin_mappings product_bin_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_bin_mappings
    ADD CONSTRAINT product_bin_mappings_pkey PRIMARY KEY (id);


--
-- Name: product_bin_mappings product_bin_mappings_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_bin_mappings
    ADD CONSTRAINT product_bin_mappings_unique UNIQUE (product_id, entity_id, warehouse_id, bin_id);


--
-- Name: product_branch_inventory_settings product_branch_inventory_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_branch_inventory_settings
    ADD CONSTRAINT product_branch_inventory_settings_pkey PRIMARY KEY (id);


--
-- Name: product_contents product_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_contents
    ADD CONSTRAINT product_contents_pkey PRIMARY KEY (id);


--
-- Name: product_entity_settings product_entity_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_entity_settings
    ADD CONSTRAINT product_entity_settings_pkey PRIMARY KEY (id);


--
-- Name: product_entity_settings product_entity_settings_product_entity_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_entity_settings
    ADD CONSTRAINT product_entity_settings_product_entity_unique UNIQUE (product_id, entity_id);


--
-- Name: product_entity_settings product_entity_settings_sku_entity_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_entity_settings
    ADD CONSTRAINT product_entity_settings_sku_entity_unique UNIQUE (entity_id, sku);


--
-- Name: product_pack_sizes product_pack_sizes_name_unit_pack_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_pack_sizes
    ADD CONSTRAINT product_pack_sizes_name_unit_pack_unique UNIQUE (pack_name, unit_pack);


--
-- Name: product_pack_sizes product_pack_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_pack_sizes
    ADD CONSTRAINT product_pack_sizes_pkey PRIMARY KEY (id);


--
-- Name: product_types product_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_pkey PRIMARY KEY (id);


--
-- Name: products products_item_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_item_code_unique UNIQUE (item_code);


--
-- Name: products products_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey1 PRIMARY KEY (id);


--
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- Name: purchase_orders purchase_orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_order_number_key UNIQUE (order_number);


--
-- Name: purchase_receive_item_batches purchase_receive_item_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_item_batches
    ADD CONSTRAINT purchase_receive_item_batches_pkey PRIMARY KEY (id);


--
-- Name: purchase_receive_items purchase_receive_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_items
    ADD CONSTRAINT purchase_receive_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_receives purchase_receives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receives
    ADD CONSTRAINT purchase_receives_pkey PRIMARY KEY (id);


--
-- Name: purchase_receives purchase_receives_purchase_receive_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receives
    ADD CONSTRAINT purchase_receives_purchase_receive_number_key UNIQUE (purchase_receive_number);


--
-- Name: purchase_return_item_batches purchase_return_item_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_return_item_batches
    ADD CONSTRAINT purchase_return_item_batches_pkey PRIMARY KEY (id);


--
-- Name: purchase_return_items purchase_return_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_return_items
    ADD CONSTRAINT purchase_return_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_returns purchase_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_returns
    ADD CONSTRAINT purchase_returns_pkey PRIMARY KEY (id);


--
-- Name: purchase_order_attachments purchases_purchase_order_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_attachments
    ADD CONSTRAINT purchases_purchase_order_attachments_pkey PRIMARY KEY (id);


--
-- Name: purchase_order_items purchases_purchase_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchases_purchase_order_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders purchases_purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_pkey PRIMARY KEY (id);


--
-- Name: racks racks_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.racks
    ADD CONSTRAINT racks_pkey1 PRIMARY KEY (id);


--
-- Name: racks racks_rack_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.racks
    ADD CONSTRAINT racks_rack_code_unique UNIQUE (rack_code);


--
-- Name: reorder_terms reorder_terms_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reorder_terms
    ADD CONSTRAINT reorder_terms_pkey1 PRIMARY KEY (id);


--
-- Name: sales_order_attachments sales_order_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_attachments
    ADD CONSTRAINT sales_order_attachments_pkey PRIMARY KEY (id);


--
-- Name: sales_order_items sales_order_items_line_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_line_unique UNIQUE (sales_order_id, line_no);


--
-- Name: sales_order_items sales_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_pkey PRIMARY KEY (id);


--
-- Name: sales_orders sales_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_pkey PRIMARY KEY (id);


--
-- Name: sales_orders sales_orders_sale_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_sale_number_key UNIQUE (sale_number);


--
-- Name: sales_payment_links sales_payment_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_payment_links
    ADD CONSTRAINT sales_payment_links_pkey PRIMARY KEY (id);


--
-- Name: sales_payments sales_payments_payment_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_payments
    ADD CONSTRAINT sales_payments_payment_number_unique UNIQUE (payment_number);


--
-- Name: sales_payments sales_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_payments
    ADD CONSTRAINT sales_payments_pkey PRIMARY KEY (id);


--
-- Name: sales_reps sales_reps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_reps
    ADD CONSTRAINT sales_reps_pkey PRIMARY KEY (id);


--
-- Name: sales_return_items sales_return_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_items
    ADD CONSTRAINT sales_return_items_pkey PRIMARY KEY (id);


--
-- Name: sales_return_receive_batches sales_return_receive_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_batches
    ADD CONSTRAINT sales_return_receive_batches_pkey PRIMARY KEY (id);


--
-- Name: sales_return_receive_items sales_return_receive_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_items
    ADD CONSTRAINT sales_return_receive_items_pkey PRIMARY KEY (id);


--
-- Name: sales_return_receives sales_return_receives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receives
    ADD CONSTRAINT sales_return_receives_pkey PRIMARY KEY (id);


--
-- Name: sales_returns sales_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_returns
    ADD CONSTRAINT sales_returns_pkey PRIMARY KEY (id);


--
-- Name: drug_schedules schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_schedules
    ADD CONSTRAINT schedules_pkey PRIMARY KEY (id);


--
-- Name: drug_schedules schedules_shedule_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_schedules
    ADD CONSTRAINT schedules_shedule_name_key UNIQUE (shedule_name);


--
-- Name: assemblies_constituencies settings_assemblies_district_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assemblies_constituencies
    ADD CONSTRAINT settings_assemblies_district_name_unique UNIQUE (district_id, name);


--
-- Name: assemblies_constituencies settings_assemblies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assemblies_constituencies
    ADD CONSTRAINT settings_assemblies_pkey PRIMARY KEY (id);


--
-- Name: branch_transaction_series settings_branch_transaction_series_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_transaction_series
    ADD CONSTRAINT settings_branch_transaction_series_pkey PRIMARY KEY (id);


--
-- Name: branch_user_access settings_branch_user_access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_user_access
    ADD CONSTRAINT settings_branch_user_access_pkey PRIMARY KEY (id);


--
-- Name: branch_users settings_branch_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_users
    ADD CONSTRAINT settings_branch_users_pkey PRIMARY KEY (id);


--
-- Name: branches settings_branches_org_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_org_code_unique UNIQUE (org_id, branch_code);


--
-- Name: branches settings_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_pkey PRIMARY KEY (id);


--
-- Name: branding settings_branding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branding
    ADD CONSTRAINT settings_branding_pkey PRIMARY KEY (id);


--
-- Name: business_types settings_business_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_types
    ADD CONSTRAINT settings_business_types_code_key UNIQUE (code);


--
-- Name: business_types settings_business_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_types
    ADD CONSTRAINT settings_business_types_pkey PRIMARY KEY (id);


--
-- Name: date_format settings_date_format_options_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.date_format
    ADD CONSTRAINT settings_date_format_options_code_key UNIQUE (code);


--
-- Name: date_format settings_date_format_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.date_format
    ADD CONSTRAINT settings_date_format_options_pkey PRIMARY KEY (id);


--
-- Name: date_separator settings_date_separator_options_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.date_separator
    ADD CONSTRAINT settings_date_separator_options_code_key UNIQUE (code);


--
-- Name: date_separator settings_date_separator_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.date_separator
    ADD CONSTRAINT settings_date_separator_options_pkey PRIMARY KEY (id);


--
-- Name: lsgd_districts settings_districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsgd_districts
    ADD CONSTRAINT settings_districts_pkey PRIMARY KEY (id);


--
-- Name: drug_licence_types settings_drug_licence_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_licence_types
    ADD CONSTRAINT settings_drug_licence_types_code_key UNIQUE (code);


--
-- Name: drug_licence_types settings_drug_licence_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_licence_types
    ADD CONSTRAINT settings_drug_licence_types_pkey PRIMARY KEY (id);


--
-- Name: fiscal_year_presets settings_fiscal_year_presets_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fiscal_year_presets
    ADD CONSTRAINT settings_fiscal_year_presets_code_key UNIQUE (code);


--
-- Name: fiscal_year_presets settings_fiscal_year_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fiscal_year_presets
    ADD CONSTRAINT settings_fiscal_year_presets_pkey PRIMARY KEY (id);


--
-- Name: gst_treatments settings_gst_treatments_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gst_treatments
    ADD CONSTRAINT settings_gst_treatments_code_key UNIQUE (code);


--
-- Name: gst_treatments settings_gst_treatments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gst_treatments
    ADD CONSTRAINT settings_gst_treatments_pkey PRIMARY KEY (id);


--
-- Name: gstin_registration_types settings_gstin_registration_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gstin_registration_types
    ADD CONSTRAINT settings_gstin_registration_types_code_key UNIQUE (code);


--
-- Name: gstin_registration_types settings_gstin_registration_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gstin_registration_types
    ADD CONSTRAINT settings_gstin_registration_types_pkey PRIMARY KEY (id);


--
-- Name: lsgd_local_bodies settings_local_bodies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsgd_local_bodies
    ADD CONSTRAINT settings_local_bodies_pkey PRIMARY KEY (id);


--
-- Name: product_types settings_product_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT settings_product_types_name_key UNIQUE (name);


--
-- Name: roles settings_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT settings_roles_pkey PRIMARY KEY (id);


--
-- Name: transaction_series_modules settings_transaction_modules_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series_modules
    ADD CONSTRAINT settings_transaction_modules_code_key UNIQUE (code);


--
-- Name: transaction_series_modules settings_transaction_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series_modules
    ADD CONSTRAINT settings_transaction_modules_pkey PRIMARY KEY (id);


--
-- Name: transaction_series_placeholders settings_transaction_prefix_placeholders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series_placeholders
    ADD CONSTRAINT settings_transaction_prefix_placeholders_pkey PRIMARY KEY (id);


--
-- Name: transaction_series_placeholders settings_transaction_prefix_placeholders_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series_placeholders
    ADD CONSTRAINT settings_transaction_prefix_placeholders_token_key UNIQUE (token);


--
-- Name: transaction_series_restart_options settings_transaction_restart_options_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series_restart_options
    ADD CONSTRAINT settings_transaction_restart_options_code_key UNIQUE (code);


--
-- Name: transaction_series_restart_options settings_transaction_restart_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series_restart_options
    ADD CONSTRAINT settings_transaction_restart_options_pkey PRIMARY KEY (id);


--
-- Name: transaction_series settings_transaction_series_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series
    ADD CONSTRAINT settings_transaction_series_pkey PRIMARY KEY (id);


--
-- Name: user_branch_access settings_user_location_access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_branch_access
    ADD CONSTRAINT settings_user_location_access_pkey PRIMARY KEY (id);


--
-- Name: lsgd_wards settings_wards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsgd_wards
    ADD CONSTRAINT settings_wards_pkey PRIMARY KEY (id);


--
-- Name: shipment_preferences shipment_preferences_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_preferences
    ADD CONSTRAINT shipment_preferences_name_key UNIQUE (name);


--
-- Name: shipment_preferences shipment_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_preferences
    ADD CONSTRAINT shipment_preferences_pkey PRIMARY KEY (id);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: storage_conditions storage_locations_location_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storage_conditions
    ADD CONSTRAINT storage_locations_location_name_unique UNIQUE (location_name);


--
-- Name: storage_conditions storage_locations_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storage_conditions
    ADD CONSTRAINT storage_locations_pkey1 PRIMARY KEY (id);


--
-- Name: drug_strengths strengths_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_strengths
    ADD CONSTRAINT strengths_pkey PRIMARY KEY (id);


--
-- Name: drug_strengths strengths_strength_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_strengths
    ADD CONSTRAINT strengths_strength_name_key UNIQUE (strength_name);


--
-- Name: tax_group_rates tax_group_taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_group_rates
    ADD CONSTRAINT tax_group_taxes_pkey PRIMARY KEY (id);


--
-- Name: tax_groups tax_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_groups
    ADD CONSTRAINT tax_groups_pkey PRIMARY KEY (id);


--
-- Name: tax_groups tax_groups_tax_group_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_groups
    ADD CONSTRAINT tax_groups_tax_group_name_key UNIQUE (tax_group_name);


--
-- Name: tax_rates tax_rates_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_rates
    ADD CONSTRAINT tax_rates_pkey1 PRIMARY KEY (id);


--
-- Name: tax_rates tax_rates_tax_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_rates
    ADD CONSTRAINT tax_rates_tax_name_unique UNIQUE (tax_name);


--
-- Name: tds_group_items tds_group_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_group_items
    ADD CONSTRAINT tds_group_items_pkey PRIMARY KEY (id);


--
-- Name: tds_groups tds_groups_group_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_groups
    ADD CONSTRAINT tds_groups_group_name_unique UNIQUE (group_name);


--
-- Name: tds_groups tds_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_groups
    ADD CONSTRAINT tds_groups_pkey PRIMARY KEY (id);


--
-- Name: tds_rates tds_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_rates
    ADD CONSTRAINT tds_rates_pkey PRIMARY KEY (id);


--
-- Name: tds_rates tds_rates_tax_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_rates
    ADD CONSTRAINT tds_rates_tax_name_unique UNIQUE (tax_name);


--
-- Name: tds_sections tds_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_sections
    ADD CONSTRAINT tds_sections_pkey PRIMARY KEY (id);


--
-- Name: tds_sections tds_sections_section_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_sections
    ADD CONSTRAINT tds_sections_section_name_unique UNIQUE (section_name);


--
-- Name: timezones timezones_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timezones
    ADD CONSTRAINT timezones_name_key UNIQUE (name);


--
-- Name: timezones timezones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timezones
    ADD CONSTRAINT timezones_pkey PRIMARY KEY (id);


--
-- Name: transaction_locks transaction_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_locks
    ADD CONSTRAINT transaction_locks_pkey PRIMARY KEY (id);


--
-- Name: transactional_sequences transactional_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactional_sequences
    ADD CONSTRAINT transactional_sequences_pkey PRIMARY KEY (id);


--
-- Name: transactional_sequences transactional_sequences_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactional_sequences
    ADD CONSTRAINT transactional_sequences_unique UNIQUE (module, entity_id);


--
-- Name: transfer_order_destination_batches transfer_order_destination_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_destination_batches
    ADD CONSTRAINT transfer_order_destination_batches_pkey PRIMARY KEY (id);


--
-- Name: transfer_order_items transfer_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_items
    ADD CONSTRAINT transfer_order_items_pkey PRIMARY KEY (id);


--
-- Name: transfer_order_logs transfer_order_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_logs
    ADD CONSTRAINT transfer_order_logs_pkey PRIMARY KEY (id);


--
-- Name: transfer_order_master transfer_order_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_master
    ADD CONSTRAINT transfer_order_master_pkey PRIMARY KEY (id);


--
-- Name: transfer_order_source_batches transfer_order_source_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_source_batches
    ADD CONSTRAINT transfer_order_source_batches_pkey PRIMARY KEY (id);


--
-- Name: organisation_branch_master unique_entity; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisation_branch_master
    ADD CONSTRAINT unique_entity UNIQUE (type, ref_id);


--
-- Name: batch_master unique_product_batch; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_master
    ADD CONSTRAINT unique_product_batch UNIQUE (product_id, batch_no);


--
-- Name: units units_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey1 PRIMARY KEY (id);


--
-- Name: units units_unit_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_unit_name_unique UNIQUE (unit_name);


--
-- Name: composite_item_branch_inventory_settings uq_cibis_item_entity; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_branch_inventory_settings
    ADD CONSTRAINT uq_cibis_item_entity UNIQUE (composite_item_id, entity_id);


--
-- Name: product_branch_inventory_settings uq_pbis_product_entity; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_branch_inventory_settings
    ADD CONSTRAINT uq_pbis_product_entity UNIQUE (product_id, entity_id);


--
-- Name: uqc uqc_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uqc
    ADD CONSTRAINT uqc_pkey PRIMARY KEY (id);


--
-- Name: uqc uqc_uqc_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uqc
    ADD CONSTRAINT uqc_uqc_code_key UNIQUE (uqc_code);


--
-- Name: user_branch_access user_branch_access_org_user_entity_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_branch_access
    ADD CONSTRAINT user_branch_access_org_user_entity_unique UNIQUE (org_id, user_id, entity_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: batch_stock_layers ux_batch_stock_layers_unique_layer_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_stock_layers
    ADD CONSTRAINT ux_batch_stock_layers_unique_layer_key UNIQUE (batch_id, product_id, entity_id, warehouse_id, bin_id);


--
-- Name: vendor_addresses vendor_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_addresses
    ADD CONSTRAINT vendor_addresses_pkey PRIMARY KEY (id);


--
-- Name: vendor_bank_accounts vendor_bank_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_bank_accounts
    ADD CONSTRAINT vendor_bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: vendor_contact_persons vendor_contact_persons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_contact_persons
    ADD CONSTRAINT vendor_contact_persons_pkey PRIMARY KEY (id);


--
-- Name: vendor_credit_item_batches vendor_credit_item_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credit_item_batches
    ADD CONSTRAINT vendor_credit_item_batches_pkey PRIMARY KEY (id);


--
-- Name: vendor_credit_items vendor_credit_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credit_items
    ADD CONSTRAINT vendor_credit_items_pkey PRIMARY KEY (id);


--
-- Name: vendor_credits vendor_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credits
    ADD CONSTRAINT vendor_credits_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_vendor_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_vendor_number_unique UNIQUE (vendor_number);


--
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);


--
-- Name: zone_levels zone_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_levels
    ADD CONSTRAINT zone_levels_pkey PRIMARY KEY (id);


--
-- Name: zone_master zone_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_master
    ADD CONSTRAINT zone_master_pkey PRIMARY KEY (id);


--
-- Name: messages messages_payload_exclusive; Type: CHECK CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages
    ADD CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL))) NOT VALID;


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_idempotency_key_key; Type: CONSTRAINT; Schema: supabase_migrations; Owner: -
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: -
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: webauthn_challenges_expires_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_expires_at_idx ON auth.webauthn_challenges USING btree (expires_at);


--
-- Name: webauthn_challenges_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_user_id_idx ON auth.webauthn_challenges USING btree (user_id);


--
-- Name: webauthn_credentials_credential_id_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX webauthn_credentials_credential_id_key ON auth.webauthn_credentials USING btree (credential_id);


--
-- Name: webauthn_credentials_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_credentials_user_id_idx ON auth.webauthn_credentials USING btree (user_id);


--
-- Name: audit_logs_archive_action_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_archive_action_created_at_idx ON public.audit_logs_archive USING btree (action, created_at DESC);


--
-- Name: audit_logs_archive_org_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_archive_org_id_created_at_idx ON public.audit_logs_archive USING btree (org_id, created_at DESC);


--
-- Name: audit_logs_archive_table_name_record_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_archive_table_name_record_id_idx ON public.audit_logs_archive USING btree (table_name, record_id);


--
-- Name: audit_logs_archive_table_name_record_pk_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_archive_table_name_record_pk_idx ON public.audit_logs_archive USING btree (table_name, record_pk);


--
-- Name: audit_logs_archive_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_archive_user_id_created_at_idx ON public.audit_logs_archive USING btree (user_id, created_at DESC);


--
-- Name: idx_account_transactions_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_account_transactions_contact_id ON public.account_transactions USING btree (contact_id);


--
-- Name: idx_account_transactions_contact_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_account_transactions_contact_type ON public.account_transactions USING btree (contact_type);


--
-- Name: idx_accounts_active_system_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_active_system_name ON public.accounts USING btree (is_active, system_account_name);


--
-- Name: idx_accounts_active_user_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_active_user_name ON public.accounts USING btree (is_active, user_account_name);


--
-- Name: idx_accounts_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_group ON public.accounts USING btree (account_group);


--
-- Name: idx_accounts_lookup_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_lookup_name_trgm ON public.accounts USING gin (lower((COALESCE(user_account_name, system_account_name))::text) public.gin_trgm_ops);


--
-- Name: idx_accounts_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_parent ON public.accounts USING btree (parent_id);


--
-- Name: idx_audit_logs_action_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_action_created ON public.audit_logs USING btree (action, created_at DESC);


--
-- Name: idx_audit_logs_archive_org_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_archive_org_created ON public.audit_logs_archive USING btree (org_id, created_at DESC);


--
-- Name: idx_audit_logs_archive_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_archive_request_id ON public.audit_logs_archive USING btree (request_id);


--
-- Name: idx_audit_logs_module_request; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_module_request ON public.audit_logs USING btree (module_name, request_id);


--
-- Name: idx_audit_logs_org_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_org_created ON public.audit_logs USING btree (org_id, created_at DESC);


--
-- Name: idx_audit_logs_record_pk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_record_pk ON public.audit_logs USING btree (table_name, record_pk);


--
-- Name: idx_audit_logs_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_request_id ON public.audit_logs USING btree (request_id);


--
-- Name: idx_audit_logs_schema_table_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_schema_table_record ON public.audit_logs USING btree (schema_name, table_name, record_id);


--
-- Name: idx_audit_logs_table_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_table_record ON public.audit_logs USING btree (table_name, record_id);


--
-- Name: idx_audit_logs_table_record_pk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_table_record_pk ON public.audit_logs USING btree (table_name, record_pk);


--
-- Name: idx_audit_logs_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user_created ON public.audit_logs USING btree (user_id, created_at DESC);


--
-- Name: idx_batch_stock_layers_bin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_batch_stock_layers_bin_id ON public.batch_stock_layers USING btree (bin_id);


--
-- Name: idx_bin_master_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bin_master_zone ON public.bin_master USING btree (zone_id);


--
-- Name: idx_branch_price_list_assignments_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branch_price_list_assignments_branch ON public.branch_price_list_assignments USING btree (branch_entity_id);


--
-- Name: idx_branch_price_list_assignments_price_list; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branch_price_list_assignments_price_list ON public.branch_price_list_assignments USING btree (price_list_id);


--
-- Name: idx_brands_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_brands_active_name ON public.brands USING btree (is_active, name);


--
-- Name: idx_brands_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_brands_name_trgm ON public.brands USING gin (lower((name)::text) public.gin_trgm_ops);


--
-- Name: idx_buying_rules_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_buying_rules_active_name ON public.buying_rules USING btree (is_active, buying_rule);


--
-- Name: idx_categories_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_active_name ON public.categories USING btree (is_active, name);


--
-- Name: idx_cibis_composite_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cibis_composite_item_id ON public.composite_item_branch_inventory_settings USING btree (composite_item_id);


--
-- Name: idx_cibis_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cibis_entity_id ON public.composite_item_branch_inventory_settings USING btree (entity_id);


--
-- Name: idx_contact_persons_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_persons_customer_id ON public.customer_contact_persons USING btree (customer_id);


--
-- Name: idx_customers_associated_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customers_associated_branch_id ON public.customers USING btree (associated_branch_id);


--
-- Name: idx_hsn_sac_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hsn_sac_code ON public.hsn_sac_codes USING btree (code);


--
-- Name: idx_hsn_sac_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hsn_sac_type ON public.hsn_sac_codes USING btree (type);


--
-- Name: idx_iab_adjustment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iab_adjustment_id ON public.inventory_adjustment_item_batches USING btree (adjustment_id);


--
-- Name: idx_iab_adjustment_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iab_adjustment_item_id ON public.inventory_adjustment_item_batches USING btree (adjustment_item_id);


--
-- Name: idx_iab_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iab_batch_id ON public.inventory_adjustment_item_batches USING btree (batch_id);


--
-- Name: idx_iab_batch_stock_layer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iab_batch_stock_layer_id ON public.inventory_adjustment_item_batches USING btree (batch_stock_layer_id);


--
-- Name: idx_iab_bin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iab_bin_id ON public.inventory_adjustment_item_batches USING btree (bin_id);


--
-- Name: idx_inv_adj_acc_entries_adj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_acc_entries_adj ON public.inventory_adjustment_account_entries USING btree (adjustment_id);


--
-- Name: idx_inv_adj_attach_adjustment_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_attach_adjustment_created ON public.inventory_adjustment_attachments USING btree (adjustment_id, created_at DESC);


--
-- Name: idx_inv_adj_attach_entity_adjustment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_attach_entity_adjustment ON public.inventory_adjustment_attachments USING btree (entity_id, adjustment_id);


--
-- Name: idx_inv_adj_attach_uploaded_by_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_attach_uploaded_by_created ON public.inventory_adjustment_attachments USING btree (uploaded_by, created_at DESC);


--
-- Name: idx_inv_adj_entity_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_entity_date ON public.inventory_adjustments USING btree (entity_id, adjustment_date DESC);


--
-- Name: idx_inv_adj_entity_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_entity_status ON public.inventory_adjustments USING btree (entity_id, status);


--
-- Name: idx_inv_adj_item_batches_adj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_item_batches_adj ON public.inventory_adjustment_item_batches USING btree (adjustment_id, adjustment_item_id);


--
-- Name: idx_inv_adj_item_batches_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_item_batches_entity ON public.inventory_adjustment_item_batches USING btree (entity_id, product_id, batch_id);


--
-- Name: idx_inv_adj_items_adj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_items_adj ON public.inventory_adjustment_items USING btree (adjustment_id);


--
-- Name: idx_inv_adj_items_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_items_entity ON public.inventory_adjustment_items USING btree (entity_id, product_id);


--
-- Name: idx_inv_adj_value_items_adj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_value_items_adj ON public.inventory_adjustment_value_items USING btree (adjustment_id);


--
-- Name: idx_inv_adj_value_items_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_adj_value_items_entity ON public.inventory_adjustment_value_items USING btree (entity_id, product_id, batch_id);


--
-- Name: idx_inventory_adjustments_status_approved_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_adjustments_status_approved_by ON public.inventory_adjustments USING btree (status, approved_by);


--
-- Name: idx_inventory_move_order_destination_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_move_order_destination_source ON public.inventory_move_order_destination_bins USING btree (source_batch_row_id);


--
-- Name: idx_inventory_move_order_items_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_move_order_items_order ON public.inventory_move_order_items USING btree (move_order_id);


--
-- Name: idx_inventory_move_order_source_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_move_order_source_item ON public.inventory_move_order_source_batches USING btree (move_order_item_id);


--
-- Name: idx_inventory_move_orders_entity_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_move_orders_entity_date ON public.inventory_move_orders USING btree (entity_id, move_date DESC);


--
-- Name: idx_inventory_shipment_packages_package_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_shipment_packages_package_id ON public.inventory_shipment_packages USING btree (package_id);


--
-- Name: idx_inventory_shipment_packages_shipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_shipment_packages_shipment_id ON public.inventory_shipment_packages USING btree (shipment_id);


--
-- Name: idx_inventory_shipment_sales_orders_sales_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_shipment_sales_orders_sales_order_id ON public.inventory_shipment_sales_orders USING btree (sales_order_id);


--
-- Name: idx_inventory_shipment_sales_orders_shipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_shipment_sales_orders_shipment_id ON public.inventory_shipment_sales_orders USING btree (shipment_id);


--
-- Name: idx_inventory_shipments_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_shipments_customer_id ON public.inventory_shipments USING btree (customer_id);


--
-- Name: idx_inventory_shipments_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_shipments_date ON public.inventory_shipments USING btree (date);


--
-- Name: idx_inventory_shipments_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_shipments_entity_id ON public.inventory_shipments USING btree (entity_id);


--
-- Name: idx_manufacturers_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_manufacturers_active_name ON public.manufacturers USING btree (is_active, name);


--
-- Name: idx_manufacturers_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_manufacturers_name_trgm ON public.manufacturers USING gin (lower((name)::text) public.gin_trgm_ops);


--
-- Name: idx_organisation_branch_master_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organisation_branch_master_parent_id ON public.organisation_branch_master USING btree (parent_id);


--
-- Name: idx_organisation_branch_master_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organisation_branch_master_type ON public.organisation_branch_master USING btree (type);


--
-- Name: idx_organization_assembly_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organization_assembly_id ON public.organization USING btree (assembly_id);


--
-- Name: idx_organization_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organization_district_id ON public.organization USING btree (district_id);


--
-- Name: idx_organization_local_body_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organization_local_body_id ON public.organization USING btree (local_body_id);


--
-- Name: idx_organization_payment_stub_assembly_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organization_payment_stub_assembly_id ON public.organization USING btree (payment_stub_assembly_id);


--
-- Name: idx_organization_ward_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organization_ward_id ON public.organization USING btree (ward_id);


--
-- Name: idx_pbis_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pbis_entity_id ON public.product_branch_inventory_settings USING btree (entity_id);


--
-- Name: idx_pbis_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pbis_product_id ON public.product_branch_inventory_settings USING btree (product_id);


--
-- Name: idx_pr_item_batches_batch_no; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pr_item_batches_batch_no ON public.purchase_receive_item_batches USING btree (batch_no);


--
-- Name: idx_pr_item_batches_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pr_item_batches_entity_id ON public.purchase_receive_item_batches USING btree (entity_id);


--
-- Name: idx_pr_item_batches_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pr_item_batches_item_id ON public.purchase_receive_item_batches USING btree (purchase_receive_item_id);


--
-- Name: idx_pr_item_batches_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pr_item_batches_product_id ON public.purchase_receive_item_batches USING btree (product_id);


--
-- Name: idx_price_list_items_price_list; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_list_items_price_list ON public.price_list_items USING btree (price_list_id);


--
-- Name: idx_price_list_items_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_list_items_product ON public.price_list_items USING btree (product_id);


--
-- Name: idx_price_list_volume_ranges_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_list_volume_ranges_item ON public.price_list_volume_ranges USING btree (price_list_item_id);


--
-- Name: idx_price_lists_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_lists_entity ON public.price_lists USING btree (entity_id);


--
-- Name: idx_price_lists_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_lists_scope ON public.price_lists USING btree (price_scope);


--
-- Name: idx_price_lists_transaction_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_lists_transaction_type ON public.price_lists USING btree (transaction_type);


--
-- Name: idx_product_bin_mappings_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_bin_mappings_active ON public.product_bin_mappings USING btree (is_active);


--
-- Name: idx_product_bin_mappings_bin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_bin_mappings_bin_id ON public.product_bin_mappings USING btree (bin_id);


--
-- Name: idx_product_bin_mappings_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_bin_mappings_entity_id ON public.product_bin_mappings USING btree (entity_id);


--
-- Name: idx_product_bin_mappings_product_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_bin_mappings_product_entity ON public.product_bin_mappings USING btree (product_id, entity_id);


--
-- Name: idx_product_bin_mappings_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_bin_mappings_product_id ON public.product_bin_mappings USING btree (product_id);


--
-- Name: idx_product_bin_mappings_warehouse_bin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_bin_mappings_warehouse_bin ON public.product_bin_mappings USING btree (warehouse_id, bin_id);


--
-- Name: idx_product_bin_mappings_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_bin_mappings_warehouse_id ON public.product_bin_mappings USING btree (warehouse_id);


--
-- Name: idx_product_entity_settings_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_entity_settings_entity_id ON public.product_entity_settings USING btree (entity_id);


--
-- Name: idx_product_entity_settings_entity_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_entity_settings_entity_product ON public.product_entity_settings USING btree (entity_id, product_id);


--
-- Name: idx_product_entity_settings_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_entity_settings_product_id ON public.product_entity_settings USING btree (product_id);


--
-- Name: idx_product_entity_settings_reorder_term; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_entity_settings_reorder_term ON public.product_entity_settings USING btree (reorder_term_id);


--
-- Name: idx_product_entity_settings_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_entity_settings_sku ON public.product_entity_settings USING btree (entity_id, sku);


--
-- Name: idx_product_entity_settings_vendor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_entity_settings_vendor ON public.product_entity_settings USING btree (preferred_vendor_id);


--
-- Name: idx_product_pack_sizes_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_pack_sizes_active ON public.product_pack_sizes USING btree (is_active, pack_name);


--
-- Name: idx_products_active_created_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_active_created_id ON public.products USING btree (is_active, created_at DESC, id DESC);


--
-- Name: idx_products_ean; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_ean ON public.products USING btree (ean);


--
-- Name: idx_products_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_name_trgm ON public.products USING gin (lower((product_name)::text) public.gin_trgm_ops);


--
-- Name: idx_products_product_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_product_type_id ON public.products USING btree (product_type_id);


--
-- Name: idx_purchase_receive_items_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_receive_items_entity_id ON public.purchase_receive_items USING btree (entity_id);


--
-- Name: idx_purchase_receive_items_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_receive_items_item_id ON public.purchase_receive_items USING btree (item_id);


--
-- Name: idx_purchase_receive_items_receive_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_receive_items_receive_id ON public.purchase_receive_items USING btree (purchase_receive_id);


--
-- Name: idx_purchase_receives_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_receives_entity_id ON public.purchase_receives USING btree (entity_id);


--
-- Name: idx_purchase_receives_purchase_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_receives_purchase_order_id ON public.purchase_receives USING btree (purchase_order_id);


--
-- Name: idx_purchase_receives_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_receives_warehouse_id ON public.purchase_receives USING btree (warehouse_id);


--
-- Name: idx_racks_active_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_racks_active_code ON public.racks USING btree (is_active, rack_code);


--
-- Name: idx_reorder_terms_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reorder_terms_active_name ON public.reorder_terms USING btree (is_active, term_name);


--
-- Name: idx_sales_order_attachments_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_order_attachments_sale_id ON public.sales_order_attachments USING btree (sales_order_id);


--
-- Name: idx_sales_order_items_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_order_items_product_id ON public.sales_order_items USING btree (product_id);


--
-- Name: idx_sales_order_items_sales_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_order_items_sales_order_id ON public.sales_order_items USING btree (sales_order_id);


--
-- Name: idx_sales_reps_entity_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_reps_entity_active_name ON public.sales_reps USING btree (entity_id, is_active, name);


--
-- Name: idx_schedules_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_schedules_active_name ON public.drug_schedules USING btree (is_active, shedule_name);


--
-- Name: idx_settings_assemblies_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_assemblies_district_id ON public.assemblies_constituencies USING btree (district_id);


--
-- Name: idx_settings_branch_transaction_series_series_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branch_transaction_series_series_id ON public.branch_transaction_series USING btree (transaction_series_id);


--
-- Name: idx_settings_branch_transaction_series_transaction_series_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branch_transaction_series_transaction_series_id ON public.branch_transaction_series USING btree (transaction_series_id);


--
-- Name: idx_settings_branch_user_access_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branch_user_access_role_id ON public.branch_user_access USING btree (role_id);


--
-- Name: idx_settings_branch_user_access_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branch_user_access_user_id ON public.branch_user_access USING btree (user_id);


--
-- Name: idx_settings_branch_users_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branch_users_user_id ON public.branch_users USING btree (user_id);


--
-- Name: idx_settings_branches_assembly_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_assembly_id ON public.branches USING btree (assembly_id);


--
-- Name: idx_settings_branches_default_transaction_series_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_default_transaction_series_id ON public.branches USING btree (default_transaction_series_id);


--
-- Name: idx_settings_branches_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_district_id ON public.branches USING btree (district_id);


--
-- Name: idx_settings_branches_fiscal_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_fiscal_year ON public.branches USING btree (fiscal_year);


--
-- Name: idx_settings_branches_local_body_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_local_body_id ON public.branches USING btree (local_body_id);


--
-- Name: idx_settings_branches_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_org_id ON public.branches USING btree (org_id);


--
-- Name: idx_settings_branches_parent_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_parent_branch_id ON public.branches USING btree (parent_branch_id);


--
-- Name: idx_settings_branches_payment_stub_assembly_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_payment_stub_assembly_id ON public.branches USING btree (payment_stub_assembly_id);


--
-- Name: idx_settings_branches_primary_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_primary_contact_id ON public.branches USING btree (primary_contact_id);


--
-- Name: idx_settings_branches_report_basis; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_report_basis ON public.branches USING btree (report_basis);


--
-- Name: idx_settings_branches_ward_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_branches_ward_id ON public.branches USING btree (ward_id);


--
-- Name: idx_settings_districts_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_districts_state_id ON public.lsgd_districts USING btree (state_id);


--
-- Name: idx_settings_local_bodies_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_local_bodies_district_id ON public.lsgd_local_bodies USING btree (district_id);


--
-- Name: idx_settings_transaction_series_branch_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_transaction_series_branch_code ON public.transaction_series USING btree (branch_code);


--
-- Name: idx_settings_transaction_series_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_transaction_series_org_id ON public.transaction_series USING btree (org_id);


--
-- Name: idx_settings_transaction_series_warehouse_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_transaction_series_warehouse_code ON public.transaction_series USING btree (warehouse_code);


--
-- Name: idx_settings_ts_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_ts_org_id ON public.transaction_series USING btree (org_id);


--
-- Name: idx_settings_user_location_access_org_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_user_location_access_org_user ON public.user_branch_access USING btree (org_id, user_id);


--
-- Name: idx_settings_wards_local_body_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_wards_local_body_id ON public.lsgd_wards USING btree (local_body_id);


--
-- Name: idx_storage_locations_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_storage_locations_active_name ON public.storage_conditions USING btree (is_active, location_name);


--
-- Name: idx_strengths_active_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_strengths_active_name ON public.drug_strengths USING btree (is_active, strength_name);


--
-- Name: idx_transactional_sequences_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactional_sequences_entity_id ON public.transactional_sequences USING btree (entity_id);


--
-- Name: idx_transactional_sequences_module; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactional_sequences_module ON public.transactional_sequences USING btree (module);


--
-- Name: idx_transfer_order_destination_batches_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_order_destination_batches_item ON public.transfer_order_destination_batches USING btree (transfer_item_id);


--
-- Name: idx_transfer_order_items_order_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_order_items_order_product ON public.transfer_order_items USING btree (transfer_order_id, product_id);


--
-- Name: idx_transfer_order_logs_order_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_order_logs_order_time ON public.transfer_order_logs USING btree (transfer_order_id, action_at DESC);


--
-- Name: idx_transfer_order_master_entity_date_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_order_master_entity_date_status ON public.transfer_order_master USING btree (entity_id, transfer_date DESC, status);


--
-- Name: idx_transfer_order_source_batches_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_order_source_batches_item ON public.transfer_order_source_batches USING btree (transfer_item_id);


--
-- Name: idx_transfer_order_source_batches_layer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_order_source_batches_layer ON public.transfer_order_source_batches USING btree (layer_id);


--
-- Name: idx_vendor_addresses_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendor_addresses_active ON public.vendor_addresses USING btree (is_active);


--
-- Name: idx_vendor_addresses_default_billing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendor_addresses_default_billing ON public.vendor_addresses USING btree (vendor_id, is_default_billing) WHERE (is_default_billing = true);


--
-- Name: idx_vendor_addresses_default_shipping; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendor_addresses_default_shipping ON public.vendor_addresses USING btree (vendor_id, is_default_shipping) WHERE (is_default_shipping = true);


--
-- Name: idx_vendor_addresses_entity_vendor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendor_addresses_entity_vendor ON public.vendor_addresses USING btree (entity_id, vendor_id);


--
-- Name: idx_vendor_addresses_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendor_addresses_type ON public.vendor_addresses USING btree (address_type);


--
-- Name: idx_vendor_addresses_vendor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendor_addresses_vendor_id ON public.vendor_addresses USING btree (vendor_id);


--
-- Name: idx_vendors_active_display_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendors_active_display_name ON public.vendors USING btree (is_active, display_name);


--
-- Name: idx_vendors_display_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendors_display_name_trgm ON public.vendors USING gin (lower((display_name)::text) public.gin_trgm_ops);


--
-- Name: idx_warehouses_assembly_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_warehouses_assembly_id ON public.warehouses USING btree (assembly_id);


--
-- Name: idx_warehouses_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_warehouses_customer_id ON public.warehouses USING btree (customer_id);


--
-- Name: idx_warehouses_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_warehouses_district_id ON public.warehouses USING btree (district_id);


--
-- Name: idx_warehouses_local_body_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_warehouses_local_body_id ON public.warehouses USING btree (local_body_id);


--
-- Name: idx_warehouses_one_default_per_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_warehouses_one_default_per_branch ON public.warehouses USING btree (source_branch_id) WHERE (is_default_for_branch = true);


--
-- Name: idx_warehouses_source_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_warehouses_source_branch_id ON public.warehouses USING btree (source_branch_id);


--
-- Name: idx_warehouses_vendor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_warehouses_vendor_id ON public.warehouses USING btree (vendor_id);


--
-- Name: idx_warehouses_ward_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_warehouses_ward_id ON public.warehouses USING btree (ward_id);


--
-- Name: idx_zone_levels_zone_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_zone_levels_zone_level ON public.zone_levels USING btree (zone_id, level_no);


--
-- Name: idx_zone_master_entity_warehouse; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_zone_master_entity_warehouse ON public.zone_master USING btree (entity_id, warehouse_id);


--
-- Name: inventory_adjustments_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_adjustments_created_at_idx ON public.inventory_adjustments USING btree (created_at);


--
-- Name: manufacturers_is_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX manufacturers_is_active_idx ON public.manufacturers USING btree (is_active);


--
-- Name: organization_system_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX organization_system_id_key ON public.organization USING btree (system_id);


--
-- Name: product_bin_mappings_one_default_per_warehouse; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX product_bin_mappings_one_default_per_warehouse ON public.product_bin_mappings USING btree (product_id, entity_id, warehouse_id) WHERE (is_default = true);


--
-- Name: product_contents_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_contents_product_id_idx ON public.product_contents USING btree (product_id);


--
-- Name: product_contents_product_id_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_contents_product_id_idx1 ON public.product_contents USING btree (product_id);


--
-- Name: products_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_created_at_idx ON public.products USING btree (created_at);


--
-- Name: products_created_at_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_created_at_idx1 ON public.products USING btree (created_at);


--
-- Name: roles_entity_id_label_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX roles_entity_id_label_unique ON public.roles USING btree (entity_id, lower((label)::text));


--
-- Name: sales_returns_entity_rma_number_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sales_returns_entity_rma_number_uidx ON public.sales_returns USING btree (entity_id, rma_number);


--
-- Name: settings_assemblies_district_code_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_assemblies_district_code_unique ON public.assemblies_constituencies USING btree (district_id, code) WHERE (code IS NOT NULL);


--
-- Name: settings_branches_system_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_branches_system_id_key ON public.branches USING btree (system_id);


--
-- Name: settings_districts_state_id_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_districts_state_id_code_key ON public.lsgd_districts USING btree (state_id, code) WHERE (code IS NOT NULL);


--
-- Name: settings_districts_state_id_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_districts_state_id_name_key ON public.lsgd_districts USING btree (state_id, name);


--
-- Name: settings_local_bodies_district_type_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_local_bodies_district_type_code_key ON public.lsgd_local_bodies USING btree (district_id, body_type, code) WHERE (code IS NOT NULL);


--
-- Name: settings_local_bodies_district_type_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_local_bodies_district_type_name_key ON public.lsgd_local_bodies USING btree (district_id, body_type, name);


--
-- Name: settings_transaction_series_org_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_transaction_series_org_code_key ON public.transaction_series USING btree (org_id, code) WHERE (code IS NOT NULL);


--
-- Name: settings_wards_local_body_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_wards_local_body_code_key ON public.lsgd_wards USING btree (local_body_id, code) WHERE (code IS NOT NULL);


--
-- Name: settings_wards_local_body_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_wards_local_body_name_key ON public.lsgd_wards USING btree (local_body_id, name);


--
-- Name: settings_wards_local_body_ward_no_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_wards_local_body_ward_no_key ON public.lsgd_wards USING btree (local_body_id, ward_no) WHERE (ward_no IS NOT NULL);


--
-- Name: strengths_is_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX strengths_is_active_idx ON public.drug_strengths USING btree (is_active);


--
-- Name: uq_bin_master_zone_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_bin_master_zone_code ON public.bin_master USING btree (zone_id, lower((bin_code)::text));


--
-- Name: uq_vendor_default_billing_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_vendor_default_billing_address ON public.vendor_addresses USING btree (vendor_id) WHERE ((is_default_billing = true) AND (is_active = true));


--
-- Name: uq_vendor_default_shipping_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_vendor_default_shipping_address ON public.vendor_addresses USING btree (vendor_id) WHERE ((is_default_shipping = true) AND (is_active = true));


--
-- Name: uq_zone_master_entity_warehouse_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_zone_master_entity_warehouse_name ON public.zone_master USING btree (entity_id, warehouse_id, lower((zone_name)::text));


--
-- Name: ux_inv_adj_attach_adjustment_storage_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_inv_adj_attach_adjustment_storage_path ON public.inventory_adjustment_attachments USING btree (adjustment_id, storage_path) WHERE (storage_path IS NOT NULL);


--
-- Name: ux_inv_adj_reasons_entity_name_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_inv_adj_reasons_entity_name_ci ON public.inventory_adjustment_reasons USING btree (entity_id, lower(TRIM(BOTH FROM name))) WHERE (entity_id IS NOT NULL);


--
-- Name: ux_inv_adj_reasons_global_name_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_inv_adj_reasons_global_name_ci ON public.inventory_adjustment_reasons USING btree (lower(TRIM(BOTH FROM name))) WHERE (entity_id IS NULL);


--
-- Name: ux_transfer_order_master_entity_transfer_no; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_transfer_order_master_entity_transfer_no ON public.transfer_order_master USING btree (entity_id, transfer_no);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_selec; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_selec ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter, COALESCE(selected_columns, '{}'::text[]));


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: batch_transactions trg_apply_inventory_adjustment_batch_txn; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_apply_inventory_adjustment_batch_txn AFTER INSERT ON public.batch_transactions FOR EACH ROW EXECUTE FUNCTION public.apply_inventory_adjustment_batch_txn();


--
-- Name: account_transactions trg_audit_account_transactions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_account_transactions AFTER INSERT OR DELETE OR UPDATE ON public.account_transactions FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: accounts trg_audit_accounts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_accounts AFTER INSERT OR DELETE OR UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: manual_journal_items trg_audit_accounts_manual_journal_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_accounts_manual_journal_items AFTER INSERT OR DELETE OR UPDATE ON public.manual_journal_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: manual_journals trg_audit_accounts_manual_journals; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_accounts_manual_journals AFTER INSERT OR DELETE OR UPDATE ON public.manual_journals FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: recurring_journal_items trg_audit_accounts_recurring_journal_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_accounts_recurring_journal_items AFTER INSERT OR DELETE OR UPDATE ON public.recurring_journal_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: recurring_journals trg_audit_accounts_recurring_journals; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_accounts_recurring_journals AFTER INSERT OR DELETE OR UPDATE ON public.recurring_journals FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: account_transactions trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.account_transactions FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: accounts trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: assemblies_constituencies trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.assemblies_constituencies FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: batch_master trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.batch_master FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: batch_stock_layers trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.batch_stock_layers FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: batch_transactions trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.batch_transactions FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: bill_attachments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.bill_attachments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: bill_item_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.bill_item_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: bill_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.bill_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: bill_landed_costs trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.bill_landed_costs FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: bills trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.bills FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: bin_master trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.bin_master FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: branch_price_list_assignments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.branch_price_list_assignments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: branch_transaction_series trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.branch_transaction_series FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: branch_user_access trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.branch_user_access FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: branch_users trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.branch_users FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: branches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.branches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: branding trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.branding FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: brands trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.brands FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: business_types trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.business_types FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: buying_rules trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.buying_rules FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: carrier trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.carrier FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: categories trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: company_id_labels trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.company_id_labels FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: composite_item_branch_inventory_settings trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.composite_item_branch_inventory_settings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: composite_item_parts trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.composite_item_parts FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: composite_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.composite_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: contents trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.contents FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: countries trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.countries FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: credit_note_item_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.credit_note_item_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: credit_note_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.credit_note_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: credit_notes trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.credit_notes FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: currencies trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.currencies FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: customer_contact_persons trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.customer_contact_persons FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: customers trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: date_format trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.date_format FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: date_separator trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.date_separator FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: drug_licence_types trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.drug_licence_types FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: drug_schedules trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.drug_schedules FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: drug_strengths trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.drug_strengths FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: fiscal_year_presets trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.fiscal_year_presets FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: fiscal_years trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.fiscal_years FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: gst_treatments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.gst_treatments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: gstin_registration_types trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.gstin_registration_types FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: hsn_sac_codes trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.hsn_sac_codes FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: industries trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.industries FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_adjustment_account_entries trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_adjustment_account_entries FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_adjustment_attachments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_adjustment_attachments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_adjustment_item_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_adjustment_item_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_adjustment_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_adjustment_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_adjustment_reasons trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_adjustment_reasons FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_adjustment_value_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_adjustment_value_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_adjustments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_adjustments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_move_order_destination_bins trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_move_order_destination_bins FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_move_order_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_move_order_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_move_order_source_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_move_order_source_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_move_orders trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_move_orders FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_package_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_package_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_package_sales_orders trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_package_sales_orders FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_packages trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_packages FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_shipment_packages trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_shipment_packages FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_shipment_sales_orders trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_shipment_sales_orders FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_shipments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_shipments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: inventory_stock_commitments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.inventory_stock_commitments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: invoice_attachments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.invoice_attachments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: invoice_item_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.invoice_item_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: invoice_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.invoice_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: invoice_master trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.invoice_master FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: invoice_packages trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.invoice_packages FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: invoice_sales_orders trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.invoice_sales_orders FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: invoice_shipments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.invoice_shipments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: journal_number_settings trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.journal_number_settings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: journal_template_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.journal_template_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: journal_templates trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.journal_templates FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: lsgd_districts trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.lsgd_districts FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: lsgd_local_bodies trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.lsgd_local_bodies FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: lsgd_wards trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.lsgd_wards FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: manual_journal_attachments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.manual_journal_attachments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: manual_journal_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.manual_journal_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: manual_journal_tag_mappings trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.manual_journal_tag_mappings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: manual_journals trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.manual_journals FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: manufacturers trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.manufacturers FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: move_order_attachments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.move_order_attachments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: organisation_branch_master trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.organisation_branch_master FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: organization trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.organization FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: payment_received_allocations trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.payment_received_allocations FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: payment_terms trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.payment_terms FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: payments_received trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.payments_received FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: picklist_batch_allocation trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.picklist_batch_allocation FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: picklist_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.picklist_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: picklist_master trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.picklist_master FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: price_list_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.price_list_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: price_list_volume_ranges trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.price_list_volume_ranges FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: price_lists trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.price_lists FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_bin_mappings trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.product_bin_mappings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_branch_inventory_settings trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.product_branch_inventory_settings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_contents trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.product_contents FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_entity_settings trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.product_entity_settings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_pack_sizes trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.product_pack_sizes FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_types trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.product_types FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_vendor_mappings trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.product_vendor_mappings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: products trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_order_attachments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_order_attachments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_order_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_order_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_orders trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_orders FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_receive_item_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_receive_item_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_receive_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_receive_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_receives trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_receives FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_return_item_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_return_item_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_return_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_return_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: purchase_returns trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.purchase_returns FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: racks trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.racks FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: recurring_journal_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.recurring_journal_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: recurring_journals trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.recurring_journals FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: reorder_terms trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.reorder_terms FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: reporting_tags trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.reporting_tags FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: roles trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_order_attachments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_order_attachments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_order_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_order_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_orders trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_orders FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_payment_links trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_payment_links FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_payments trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_payments FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_reps trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_reps FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_return_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_return_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_return_receive_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_return_receive_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_return_receive_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_return_receive_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_return_receives trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_return_receives FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: sales_returns trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.sales_returns FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: shipment_preferences trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.shipment_preferences FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: states trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.states FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: storage_conditions trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.storage_conditions FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: tax_group_rates trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.tax_group_rates FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: tax_groups trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.tax_groups FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: tax_rates trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.tax_rates FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: tds_group_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.tds_group_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: tds_groups trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.tds_groups FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: tds_rates trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.tds_rates FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: tds_sections trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.tds_sections FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: timezones trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.timezones FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transaction_locks trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transaction_locks FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transaction_series trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transaction_series FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transaction_series_modules trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transaction_series_modules FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transaction_series_placeholders trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transaction_series_placeholders FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transaction_series_restart_options trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transaction_series_restart_options FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transactional_sequences trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transactional_sequences FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transfer_order_destination_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transfer_order_destination_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transfer_order_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transfer_order_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transfer_order_logs trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transfer_order_logs FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transfer_order_master trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transfer_order_master FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: transfer_order_source_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.transfer_order_source_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: units trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.units FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: uqc trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.uqc FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: user_branch_access trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.user_branch_access FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: users trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendor_addresses trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendor_addresses FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendor_bank_accounts trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendor_bank_accounts FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendor_contact_persons trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendor_contact_persons FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendor_credit_item_batches trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendor_credit_item_batches FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendor_credit_items trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendor_credit_items FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendor_credits trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendor_credits FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendors trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendors FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: warehouses trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.warehouses FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: zone_levels trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.zone_levels FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: zone_master trg_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.zone_master FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_bin_mappings trg_audit_row_product_bin_mappings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row_product_bin_mappings AFTER INSERT OR DELETE OR UPDATE ON public.product_bin_mappings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: product_entity_settings trg_audit_row_product_entity_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_row_product_entity_settings AFTER INSERT OR DELETE OR UPDATE ON public.product_entity_settings FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: account_transactions trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.account_transactions FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: accounts trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.accounts FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: assemblies_constituencies trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.assemblies_constituencies FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: batch_master trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.batch_master FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: batch_stock_layers trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.batch_stock_layers FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: batch_transactions trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.batch_transactions FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: bill_attachments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.bill_attachments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: bill_item_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.bill_item_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: bill_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.bill_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: bill_landed_costs trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.bill_landed_costs FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: bills trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.bills FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: bin_master trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.bin_master FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: branch_price_list_assignments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.branch_price_list_assignments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: branch_transaction_series trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.branch_transaction_series FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: branch_user_access trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.branch_user_access FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: branch_users trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.branch_users FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: branches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.branches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: branding trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.branding FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: brands trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.brands FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: business_types trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.business_types FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: buying_rules trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.buying_rules FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: carrier trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.carrier FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: categories trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.categories FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: company_id_labels trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.company_id_labels FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: composite_item_branch_inventory_settings trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.composite_item_branch_inventory_settings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: composite_item_parts trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.composite_item_parts FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: composite_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.composite_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: contents trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.contents FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: countries trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.countries FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: credit_note_item_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.credit_note_item_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: credit_note_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.credit_note_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: credit_notes trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.credit_notes FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: currencies trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.currencies FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: customer_contact_persons trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.customer_contact_persons FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: customers trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.customers FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: date_format trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.date_format FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: date_separator trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.date_separator FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: drug_licence_types trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.drug_licence_types FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: drug_schedules trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.drug_schedules FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: drug_strengths trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.drug_strengths FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: fiscal_year_presets trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.fiscal_year_presets FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: fiscal_years trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.fiscal_years FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: gst_treatments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.gst_treatments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: gstin_registration_types trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.gstin_registration_types FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: hsn_sac_codes trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.hsn_sac_codes FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: industries trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.industries FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustment_account_entries trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_adjustment_account_entries FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustment_attachments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_adjustment_attachments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustment_item_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_adjustment_item_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustment_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_adjustment_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustment_reasons trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_adjustment_reasons FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustment_value_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_adjustment_value_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_adjustments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_move_order_destination_bins trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_move_order_destination_bins FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_move_order_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_move_order_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_move_order_source_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_move_order_source_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_move_orders trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_move_orders FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_package_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_package_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_package_sales_orders trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_package_sales_orders FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_packages trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_packages FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_shipment_packages trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_shipment_packages FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_shipment_sales_orders trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_shipment_sales_orders FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_shipments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_shipments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_stock_commitments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.inventory_stock_commitments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: invoice_attachments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.invoice_attachments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: invoice_item_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.invoice_item_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: invoice_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.invoice_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: invoice_master trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.invoice_master FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: invoice_packages trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.invoice_packages FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: invoice_sales_orders trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.invoice_sales_orders FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: invoice_shipments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.invoice_shipments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: journal_number_settings trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.journal_number_settings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: journal_template_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.journal_template_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: journal_templates trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.journal_templates FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: lsgd_districts trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.lsgd_districts FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: lsgd_local_bodies trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.lsgd_local_bodies FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: lsgd_wards trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.lsgd_wards FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: manual_journal_attachments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.manual_journal_attachments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: manual_journal_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.manual_journal_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: manual_journal_tag_mappings trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.manual_journal_tag_mappings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: manual_journals trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.manual_journals FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: manufacturers trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.manufacturers FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: move_order_attachments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.move_order_attachments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: organisation_branch_master trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.organisation_branch_master FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: organization trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.organization FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: payment_received_allocations trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.payment_received_allocations FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: payment_terms trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.payment_terms FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: payments_received trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.payments_received FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: picklist_batch_allocation trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.picklist_batch_allocation FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: picklist_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.picklist_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: picklist_master trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.picklist_master FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: price_list_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.price_list_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: price_list_volume_ranges trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.price_list_volume_ranges FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: price_lists trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.price_lists FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_bin_mappings trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.product_bin_mappings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_branch_inventory_settings trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.product_branch_inventory_settings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_contents trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.product_contents FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_entity_settings trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.product_entity_settings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_pack_sizes trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.product_pack_sizes FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_types trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.product_types FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_vendor_mappings trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.product_vendor_mappings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: products trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.products FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_order_attachments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_order_attachments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_order_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_order_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_orders trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_orders FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_receive_item_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_receive_item_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_receive_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_receive_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_receives trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_receives FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_return_item_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_return_item_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_return_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_return_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: purchase_returns trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.purchase_returns FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: racks trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.racks FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: recurring_journal_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.recurring_journal_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: recurring_journals trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.recurring_journals FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: reorder_terms trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.reorder_terms FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: reporting_tags trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.reporting_tags FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: roles trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.roles FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_order_attachments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_order_attachments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_order_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_order_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_orders trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_orders FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_payment_links trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_payment_links FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_payments trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_payments FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_reps trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_reps FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_return_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_return_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_return_receive_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_return_receive_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_return_receive_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_return_receive_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_return_receives trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_return_receives FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: sales_returns trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.sales_returns FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: shipment_preferences trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.shipment_preferences FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: states trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.states FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: storage_conditions trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.storage_conditions FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: tax_group_rates trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.tax_group_rates FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: tax_groups trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.tax_groups FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: tax_rates trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.tax_rates FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: tds_group_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.tds_group_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: tds_groups trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.tds_groups FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: tds_rates trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.tds_rates FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: tds_sections trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.tds_sections FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: timezones trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.timezones FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transaction_locks trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transaction_locks FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transaction_series trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transaction_series FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transaction_series_modules trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transaction_series_modules FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transaction_series_placeholders trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transaction_series_placeholders FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transaction_series_restart_options trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transaction_series_restart_options FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transactional_sequences trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transactional_sequences FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transfer_order_destination_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transfer_order_destination_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transfer_order_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transfer_order_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transfer_order_logs trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transfer_order_logs FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transfer_order_master trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transfer_order_master FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: transfer_order_source_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.transfer_order_source_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: units trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.units FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: uqc trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.uqc FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: user_branch_access trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.user_branch_access FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: users trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.users FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendor_addresses trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.vendor_addresses FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendor_bank_accounts trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.vendor_bank_accounts FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendor_contact_persons trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.vendor_contact_persons FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendor_credit_item_batches trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.vendor_credit_item_batches FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendor_credit_items trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.vendor_credit_items FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendor_credits trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.vendor_credits FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendors trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.vendors FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: warehouses trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.warehouses FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: zone_levels trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.zone_levels FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: zone_master trg_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate AFTER TRUNCATE ON public.zone_master FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_bin_mappings trg_audit_truncate_product_bin_mappings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate_product_bin_mappings AFTER TRUNCATE ON public.product_bin_mappings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: product_entity_settings trg_audit_truncate_product_entity_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_truncate_product_entity_settings AFTER TRUNCATE ON public.product_entity_settings FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: inventory_adjustment_account_entries trg_inv_adj_acc_entries_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_inv_adj_acc_entries_updated_at BEFORE UPDATE ON public.inventory_adjustment_account_entries FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();


--
-- Name: inventory_adjustment_item_batches trg_inv_adj_item_batches_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_inv_adj_item_batches_updated_at BEFORE UPDATE ON public.inventory_adjustment_item_batches FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();


--
-- Name: inventory_adjustment_items trg_inv_adj_items_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_inv_adj_items_updated_at BEFORE UPDATE ON public.inventory_adjustment_items FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();


--
-- Name: inventory_adjustments trg_inv_adj_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_inv_adj_updated_at BEFORE UPDATE ON public.inventory_adjustments FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();


--
-- Name: inventory_adjustment_value_items trg_inv_adj_value_items_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_inv_adj_value_items_updated_at BEFORE UPDATE ON public.inventory_adjustment_value_items FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();


--
-- Name: audit_logs_archive trg_prevent_audit_log_archive_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_prevent_audit_log_archive_update BEFORE DELETE OR UPDATE ON public.audit_logs_archive FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_log_mutation();


--
-- Name: audit_logs trg_prevent_audit_log_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_prevent_audit_log_update BEFORE DELETE OR UPDATE ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_log_mutation();


--
-- Name: product_pack_sizes trg_product_pack_sizes_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_product_pack_sizes_updated_at BEFORE UPDATE ON public.product_pack_sizes FOR EACH ROW EXECUTE FUNCTION public.set_product_pack_sizes_updated_at();


--
-- Name: inventory_adjustment_attachments trg_set_inventory_adjustment_attachments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_inventory_adjustment_attachments_updated_at BEFORE UPDATE ON public.inventory_adjustment_attachments FOR EACH ROW EXECUTE FUNCTION public.set_inventory_adjustment_attachments_updated_at();


--
-- Name: branch_users trg_settings_branch_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_settings_branch_users_updated_at BEFORE UPDATE ON public.branch_users FOR EACH ROW EXECUTE FUNCTION public.update_settings_branch_users_updated_at();


--
-- Name: branding trg_settings_branding_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_settings_branding_updated_at BEFORE UPDATE ON public.branding FOR EACH ROW EXECUTE FUNCTION public.update_settings_branding_updated_at();


--
-- Name: user_branch_access trg_settings_user_location_access_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_settings_user_location_access_updated_at BEFORE UPDATE ON public.user_branch_access FOR EACH ROW EXECUTE FUNCTION public.update_settings_user_location_access_updated_at();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_users_updated_at();


--
-- Name: vendor_addresses trg_vendor_addresses_audit_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_vendor_addresses_audit_row AFTER INSERT OR DELETE OR UPDATE ON public.vendor_addresses FOR EACH ROW EXECUTE FUNCTION public.audit_row_changes();


--
-- Name: vendor_addresses trg_vendor_addresses_audit_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_vendor_addresses_audit_truncate AFTER TRUNCATE ON public.vendor_addresses FOR EACH STATEMENT EXECUTE FUNCTION public.audit_table_truncate();


--
-- Name: vendor_addresses trg_vendor_addresses_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_vendor_addresses_set_updated_at BEFORE UPDATE ON public.vendor_addresses FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: branches trigger_sync_branch_to_entity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_sync_branch_to_entity AFTER INSERT OR UPDATE ON public.branches FOR EACH ROW EXECUTE FUNCTION public.sync_branch_to_entity();


--
-- Name: organization trigger_sync_org_to_entity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_sync_org_to_entity AFTER INSERT OR UPDATE ON public.organization FOR EACH ROW EXECUTE FUNCTION public.sync_organization_to_entity();


--
-- Name: customer_contact_persons update_customer_contact_persons_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_customer_contact_persons_updated_at BEFORE UPDATE ON public.customer_contact_persons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: webauthn_challenges webauthn_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: account_transactions account_transactions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_transactions account_transactions_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: accounts accounts_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: journal_template_items accounts_journal_template_items_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_template_items
    ADD CONSTRAINT accounts_journal_template_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: journal_template_items accounts_journal_template_items_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_template_items
    ADD CONSTRAINT accounts_journal_template_items_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.journal_templates(id) ON DELETE CASCADE;


--
-- Name: manual_journal_attachments accounts_manual_journal_attachments_manual_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_attachments
    ADD CONSTRAINT accounts_manual_journal_attachments_manual_journal_id_fkey FOREIGN KEY (manual_journal_id) REFERENCES public.manual_journals(id) ON DELETE CASCADE;


--
-- Name: manual_journal_items accounts_manual_journal_items_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_items
    ADD CONSTRAINT accounts_manual_journal_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: manual_journal_items accounts_manual_journal_items_manual_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_items
    ADD CONSTRAINT accounts_manual_journal_items_manual_journal_id_fkey FOREIGN KEY (manual_journal_id) REFERENCES public.manual_journals(id) ON DELETE CASCADE;


--
-- Name: manual_journal_tag_mappings accounts_manual_journal_tag_mapping_manual_journal_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_tag_mappings
    ADD CONSTRAINT accounts_manual_journal_tag_mapping_manual_journal_item_id_fkey FOREIGN KEY (manual_journal_item_id) REFERENCES public.manual_journal_items(id) ON DELETE CASCADE;


--
-- Name: manual_journal_tag_mappings accounts_manual_journal_tag_mappings_reporting_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_tag_mappings
    ADD CONSTRAINT accounts_manual_journal_tag_mappings_reporting_tag_id_fkey FOREIGN KEY (reporting_tag_id) REFERENCES public.reporting_tags(id) ON DELETE CASCADE;


--
-- Name: manual_journals accounts_manual_journals_fiscal_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journals
    ADD CONSTRAINT accounts_manual_journals_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES public.fiscal_years(id);


--
-- Name: manual_journals accounts_manual_journals_recurring_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journals
    ADD CONSTRAINT accounts_manual_journals_recurring_journal_id_fkey FOREIGN KEY (recurring_journal_id) REFERENCES public.recurring_journals(id) ON DELETE SET NULL;


--
-- Name: recurring_journal_items accounts_recurring_journal_items_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_journal_items
    ADD CONSTRAINT accounts_recurring_journal_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: recurring_journal_items accounts_recurring_journal_items_recur_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_journal_items
    ADD CONSTRAINT accounts_recurring_journal_items_recur_journal_id_fkey FOREIGN KEY (recurring_journal_id) REFERENCES public.recurring_journals(id) ON DELETE CASCADE;


--
-- Name: audit_logs_archive audit_logs_archive_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs_archive
    ADD CONSTRAINT audit_logs_archive_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: audit_logs audit_logs_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: batch_stock_layers batch_stock_layers_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_stock_layers
    ADD CONSTRAINT batch_stock_layers_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: batch_stock_layers batch_stock_layers_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_stock_layers
    ADD CONSTRAINT batch_stock_layers_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: batch_stock_layers batch_stock_layers_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_stock_layers
    ADD CONSTRAINT batch_stock_layers_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: batch_stock_layers batch_stock_layers_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_stock_layers
    ADD CONSTRAINT batch_stock_layers_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: batch_master batches_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_master
    ADD CONSTRAINT batches_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: bill_item_batches bill_item_batches_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_item_batches
    ADD CONSTRAINT bill_item_batches_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id);


--
-- Name: bill_item_batches bill_item_batches_bill_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_item_batches
    ADD CONSTRAINT bill_item_batches_bill_item_id_fkey FOREIGN KEY (bill_item_id) REFERENCES public.bill_items(id) ON DELETE CASCADE;


--
-- Name: bill_item_batches bill_item_batches_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_item_batches
    ADD CONSTRAINT bill_item_batches_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: bill_item_batches bill_item_batches_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_item_batches
    ADD CONSTRAINT bill_item_batches_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: bill_item_batches bill_item_batches_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_item_batches
    ADD CONSTRAINT bill_item_batches_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: bill_items bill_items_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_items
    ADD CONSTRAINT bill_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: bill_items bill_items_bill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_items
    ADD CONSTRAINT bill_items_bill_id_fkey FOREIGN KEY (bill_id) REFERENCES public.bills(id) ON DELETE CASCADE;


--
-- Name: bill_items bill_items_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_items
    ADD CONSTRAINT bill_items_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE SET NULL;


--
-- Name: bill_items bill_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_items
    ADD CONSTRAINT bill_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: bill_items bill_items_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_items
    ADD CONSTRAINT bill_items_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.tax_groups(id);


--
-- Name: bill_landed_costs bill_landed_costs_bill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_landed_costs
    ADD CONSTRAINT bill_landed_costs_bill_id_fkey FOREIGN KEY (bill_id) REFERENCES public.bills(id) ON DELETE CASCADE;


--
-- Name: bills bills_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bills
    ADD CONSTRAINT bills_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: bills bills_payment_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bills
    ADD CONSTRAINT bills_payment_term_id_fkey FOREIGN KEY (payment_term_id) REFERENCES public.payment_terms(id);


--
-- Name: bills bills_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bills
    ADD CONSTRAINT bills_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: bills bills_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bills
    ADD CONSTRAINT bills_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: bin_master bin_master_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_master
    ADD CONSTRAINT bin_master_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: branch_price_list_assignments branch_price_list_assignments_branch_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_price_list_assignments
    ADD CONSTRAINT branch_price_list_assignments_branch_entity_id_fkey FOREIGN KEY (branch_entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE CASCADE;


--
-- Name: branch_price_list_assignments branch_price_list_assignments_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_price_list_assignments
    ADD CONSTRAINT branch_price_list_assignments_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id) ON DELETE CASCADE;


--
-- Name: branch_transaction_series branch_transaction_series_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_transaction_series
    ADD CONSTRAINT branch_transaction_series_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: branch_user_access branch_user_access_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_user_access
    ADD CONSTRAINT branch_user_access_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: branch_users branch_users_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_users
    ADD CONSTRAINT branch_users_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: branches branches_id_to_registry_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_id_to_registry_fkey FOREIGN KEY (id) REFERENCES public.organisation_branch_master(ref_id) ON DELETE CASCADE;


--
-- Name: branding branding_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branding
    ADD CONSTRAINT branding_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: categories categories_parent_id_categories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_categories_id_fk FOREIGN KEY (parent_id) REFERENCES public.categories(id);


--
-- Name: composite_item_branch_inventory_settings cibis_composite_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_branch_inventory_settings
    ADD CONSTRAINT cibis_composite_item_id_fkey FOREIGN KEY (composite_item_id) REFERENCES public.composite_items(id) ON DELETE CASCADE;


--
-- Name: composite_item_branch_inventory_settings cibis_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_branch_inventory_settings
    ADD CONSTRAINT cibis_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE CASCADE;


--
-- Name: composite_item_branch_inventory_settings cibis_reorder_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_branch_inventory_settings
    ADD CONSTRAINT cibis_reorder_term_id_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id) ON DELETE SET NULL;


--
-- Name: composite_item_parts composite_item_parts_component_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_parts
    ADD CONSTRAINT composite_item_parts_component_product_id_fkey FOREIGN KEY (component_product_id) REFERENCES public.products(id);


--
-- Name: composite_item_parts composite_item_parts_composite_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_item_parts
    ADD CONSTRAINT composite_item_parts_composite_item_id_fkey FOREIGN KEY (composite_item_id) REFERENCES public.composite_items(id) ON DELETE CASCADE;


--
-- Name: composite_items composite_items_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- Name: composite_items composite_items_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: composite_items composite_items_inter_state_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_inter_state_tax_id_fkey FOREIGN KEY (inter_state_tax_id) REFERENCES public.tax_rates(id);


--
-- Name: composite_items composite_items_intra_state_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_intra_state_tax_id_fkey FOREIGN KEY (intra_state_tax_id) REFERENCES public.tax_rates(id);


--
-- Name: composite_items composite_items_inventory_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_inventory_account_id_fkey FOREIGN KEY (inventory_account_id) REFERENCES public.accounts(id);


--
-- Name: composite_items composite_items_manufacturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(id);


--
-- Name: composite_items composite_items_purchase_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_purchase_account_id_fkey FOREIGN KEY (purchase_account_id) REFERENCES public.accounts(id);


--
-- Name: composite_items composite_items_reorder_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_reorder_term_id_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id);


--
-- Name: composite_items composite_items_sales_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_sales_account_id_fkey FOREIGN KEY (sales_account_id) REFERENCES public.accounts(id);


--
-- Name: composite_items composite_items_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_items
    ADD CONSTRAINT composite_items_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: countries countries_primary_timezone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_primary_timezone_id_fkey FOREIGN KEY (primary_timezone_id) REFERENCES public.timezones(id) ON DELETE SET NULL;


--
-- Name: credit_note_item_batches credit_note_item_batches_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_item_batches
    ADD CONSTRAINT credit_note_item_batches_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id);


--
-- Name: credit_note_item_batches credit_note_item_batches_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_item_batches
    ADD CONSTRAINT credit_note_item_batches_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: credit_note_item_batches credit_note_item_batches_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_item_batches
    ADD CONSTRAINT credit_note_item_batches_item_id_fkey FOREIGN KEY (credit_note_item_id) REFERENCES public.credit_note_items(id) ON DELETE CASCADE;


--
-- Name: credit_note_item_batches credit_note_item_batches_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_item_batches
    ADD CONSTRAINT credit_note_item_batches_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: credit_note_item_batches credit_note_item_batches_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_item_batches
    ADD CONSTRAINT credit_note_item_batches_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: credit_note_items credit_note_items_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_items
    ADD CONSTRAINT credit_note_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: credit_note_items credit_note_items_credit_note_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_items
    ADD CONSTRAINT credit_note_items_credit_note_id_fkey FOREIGN KEY (credit_note_id) REFERENCES public.credit_notes(id) ON DELETE CASCADE;


--
-- Name: credit_note_items credit_note_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_note_items
    ADD CONSTRAINT credit_note_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: credit_notes credit_notes_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_notes
    ADD CONSTRAINT credit_notes_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: credit_notes credit_notes_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_notes
    ADD CONSTRAINT credit_notes_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: credit_notes credit_notes_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_notes
    ADD CONSTRAINT credit_notes_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id);


--
-- Name: credit_notes credit_notes_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_notes
    ADD CONSTRAINT credit_notes_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: customer_contact_persons customer_contact_persons_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contact_persons
    ADD CONSTRAINT customer_contact_persons_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: customer_contact_persons customer_contact_persons_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_contact_persons
    ADD CONSTRAINT customer_contact_persons_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: customers customers_associated_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_associated_branch_id_fkey FOREIGN KEY (associated_branch_id) REFERENCES public.branches(id) ON DELETE SET NULL;


--
-- Name: customers customers_billing_address_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_billing_address_country_id_fkey FOREIGN KEY (billing_address_country_id) REFERENCES public.countries(id);


--
-- Name: customers customers_billing_address_state_id_states_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_billing_address_state_id_states_id_fk FOREIGN KEY (billing_address_state_id) REFERENCES public.states(id);


--
-- Name: customers customers_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: customers customers_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: customers customers_gst_treatment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_gst_treatment_fkey FOREIGN KEY (gst_treatment) REFERENCES public.gst_treatments(code);


--
-- Name: customers customers_parent_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_parent_customer_id_fkey FOREIGN KEY (parent_customer_id) REFERENCES public.customers(id);


--
-- Name: customers customers_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id);


--
-- Name: customers customers_shipping_address_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_shipping_address_country_id_fkey FOREIGN KEY (shipping_address_country_id) REFERENCES public.countries(id);


--
-- Name: customers customers_shipping_address_state_id_states_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_shipping_address_state_id_states_id_fk FOREIGN KEY (shipping_address_state_id) REFERENCES public.states(id);


--
-- Name: fiscal_years fiscal_years_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fiscal_years
    ADD CONSTRAINT fiscal_years_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: accounts fk_accounts_parent; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_accounts_parent FOREIGN KEY (parent_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: batch_stock_layers fk_batch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_stock_layers
    ADD CONSTRAINT fk_batch FOREIGN KEY (batch_id) REFERENCES public.batch_master(id) ON DELETE CASCADE;


--
-- Name: bill_attachments fk_bill_attachments_bill; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_attachments
    ADD CONSTRAINT fk_bill_attachments_bill FOREIGN KEY (bill_id) REFERENCES public.bills(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustments fk_inventory_adjustments_reason_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT fk_inventory_adjustments_reason_id FOREIGN KEY (reason_id) REFERENCES public.inventory_adjustment_reasons(id) ON DELETE SET NULL;


--
-- Name: purchase_return_item_batches fk_purchase_return_batch_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_return_item_batches
    ADD CONSTRAINT fk_purchase_return_batch_item FOREIGN KEY (purchase_return_item_id) REFERENCES public.purchase_return_items(id) ON DELETE CASCADE;


--
-- Name: purchase_return_item_batches fk_purchase_return_batch_layer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_return_item_batches
    ADD CONSTRAINT fk_purchase_return_batch_layer FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: purchase_return_item_batches fk_purchase_return_batch_master; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_return_item_batches
    ADD CONSTRAINT fk_purchase_return_batch_master FOREIGN KEY (batch_id) REFERENCES public.batch_master(id);


--
-- Name: purchase_returns fk_purchase_return_bill; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_returns
    ADD CONSTRAINT fk_purchase_return_bill FOREIGN KEY (bill_id) REFERENCES public.bills(id);


--
-- Name: purchase_return_items fk_purchase_return_items_master; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_master FOREIGN KEY (purchase_return_id) REFERENCES public.purchase_returns(id) ON DELETE CASCADE;


--
-- Name: purchase_returns fk_purchase_return_vendor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_returns
    ADD CONSTRAINT fk_purchase_return_vendor FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: vendor_credit_item_batches fk_vendor_credit_batch_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credit_item_batches
    ADD CONSTRAINT fk_vendor_credit_batch_item FOREIGN KEY (vendor_credit_item_id) REFERENCES public.vendor_credit_items(id) ON DELETE CASCADE;


--
-- Name: vendor_credit_item_batches fk_vendor_credit_batch_layer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credit_item_batches
    ADD CONSTRAINT fk_vendor_credit_batch_layer FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: vendor_credit_item_batches fk_vendor_credit_batch_master; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credit_item_batches
    ADD CONSTRAINT fk_vendor_credit_batch_master FOREIGN KEY (batch_id) REFERENCES public.batch_master(id);


--
-- Name: vendor_credits fk_vendor_credit_bill; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credits
    ADD CONSTRAINT fk_vendor_credit_bill FOREIGN KEY (bill_id) REFERENCES public.bills(id);


--
-- Name: vendor_credit_items fk_vendor_credit_items_master; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credit_items
    ADD CONSTRAINT fk_vendor_credit_items_master FOREIGN KEY (vendor_credit_id) REFERENCES public.vendor_credits(id) ON DELETE CASCADE;


--
-- Name: vendor_credits fk_vendor_credit_purchase_return; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credits
    ADD CONSTRAINT fk_vendor_credit_purchase_return FOREIGN KEY (purchase_return_id) REFERENCES public.purchase_returns(id);


--
-- Name: vendor_credits fk_vendor_credit_vendor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_credits
    ADD CONSTRAINT fk_vendor_credit_vendor FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: bin_master fk_zone; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_master
    ADD CONSTRAINT fk_zone FOREIGN KEY (zone_id) REFERENCES public.zone_master(id);


--
-- Name: zone_levels fk_zone; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_levels
    ADD CONSTRAINT fk_zone FOREIGN KEY (zone_id) REFERENCES public.zone_master(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_account_entries inventory_adjustment_account_entries_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_account_entries
    ADD CONSTRAINT inventory_adjustment_account_entries_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustment_account_entries inventory_adjustment_account_entries_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_account_entries
    ADD CONSTRAINT inventory_adjustment_account_entries_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_account_entries inventory_adjustment_account_entries_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_account_entries
    ADD CONSTRAINT inventory_adjustment_account_entries_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustment_attachments inventory_adjustment_attachments_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_attachments
    ADD CONSTRAINT inventory_adjustment_attachments_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_attachments inventory_adjustment_attachments_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_attachments
    ADD CONSTRAINT inventory_adjustment_attachments_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: inventory_adjustment_attachments inventory_adjustment_attachments_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_attachments
    ADD CONSTRAINT inventory_adjustment_attachments_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_adjustment_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_adjustment_item_id_fkey FOREIGN KEY (adjustment_item_id) REFERENCES public.inventory_adjustment_items(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id) ON DELETE SET NULL;


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_batch_stock_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_batch_stock_layer_id_fkey FOREIGN KEY (batch_stock_layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustment_item_batches inventory_adjustment_item_batches_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_item_batches
    ADD CONSTRAINT inventory_adjustment_item_batches_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id) ON DELETE SET NULL;


--
-- Name: inventory_adjustment_items inventory_adjustment_items_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_items
    ADD CONSTRAINT inventory_adjustment_items_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_items inventory_adjustment_items_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_items
    ADD CONSTRAINT inventory_adjustment_items_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id) ON DELETE SET NULL;


--
-- Name: inventory_adjustment_items inventory_adjustment_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_items
    ADD CONSTRAINT inventory_adjustment_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustment_items inventory_adjustment_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_items
    ADD CONSTRAINT inventory_adjustment_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustment_reasons inventory_adjustment_reasons_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_reasons
    ADD CONSTRAINT inventory_adjustment_reasons_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_value_items inventory_adjustment_value_items_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_value_items
    ADD CONSTRAINT inventory_adjustment_value_items_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustment_value_items inventory_adjustment_value_items_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_value_items
    ADD CONSTRAINT inventory_adjustment_value_items_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id) ON DELETE SET NULL;


--
-- Name: inventory_adjustment_value_items inventory_adjustment_value_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_value_items
    ADD CONSTRAINT inventory_adjustment_value_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustment_value_items inventory_adjustment_value_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustment_value_items
    ADD CONSTRAINT inventory_adjustment_value_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustments inventory_adjustments_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: inventory_adjustments inventory_adjustments_adjusted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_adjusted_by_fkey FOREIGN KEY (adjusted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: inventory_adjustments inventory_adjustments_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: inventory_adjustments inventory_adjustments_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustments inventory_adjustments_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: inventory_adjustments inventory_adjustments_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id) ON DELETE SET NULL;


--
-- Name: inventory_move_order_destination_bins inventory_move_order_destination_bins_source_batch_row_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_order_destination_bins
    ADD CONSTRAINT inventory_move_order_destination_bins_source_batch_row_id_fkey FOREIGN KEY (source_batch_row_id) REFERENCES public.inventory_move_order_source_batches(id) ON DELETE CASCADE;


--
-- Name: inventory_move_order_items inventory_move_order_items_move_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_order_items
    ADD CONSTRAINT inventory_move_order_items_move_order_id_fkey FOREIGN KEY (move_order_id) REFERENCES public.inventory_move_orders(id) ON DELETE CASCADE;


--
-- Name: inventory_move_order_source_batches inventory_move_order_source_batches_move_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_move_order_source_batches
    ADD CONSTRAINT inventory_move_order_source_batches_move_order_item_id_fkey FOREIGN KEY (move_order_item_id) REFERENCES public.inventory_move_order_items(id) ON DELETE CASCADE;


--
-- Name: inventory_package_items inventory_package_items_entity_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_package_items
    ADD CONSTRAINT inventory_package_items_entity_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: inventory_package_items inventory_package_items_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_package_items
    ADD CONSTRAINT inventory_package_items_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.inventory_packages(id) ON DELETE CASCADE;


--
-- Name: inventory_package_items inventory_package_items_picklist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_package_items
    ADD CONSTRAINT inventory_package_items_picklist_id_fkey FOREIGN KEY (picklist_id) REFERENCES public.picklist_master(id);


--
-- Name: inventory_package_items inventory_package_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_package_items
    ADD CONSTRAINT inventory_package_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: inventory_package_sales_orders inventory_package_sales_orders_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_package_sales_orders
    ADD CONSTRAINT inventory_package_sales_orders_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.inventory_packages(id) ON DELETE CASCADE;


--
-- Name: inventory_packages inventory_packages_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_packages
    ADD CONSTRAINT inventory_packages_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: inventory_packages inventory_packages_entity_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_packages
    ADD CONSTRAINT inventory_packages_entity_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: inventory_shipment_packages inventory_shipment_packages_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipment_packages
    ADD CONSTRAINT inventory_shipment_packages_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.inventory_packages(id) ON DELETE CASCADE;


--
-- Name: inventory_shipment_packages inventory_shipment_packages_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipment_packages
    ADD CONSTRAINT inventory_shipment_packages_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES public.inventory_shipments(id) ON DELETE CASCADE;


--
-- Name: inventory_shipment_sales_orders inventory_shipment_sales_orders_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipment_sales_orders
    ADD CONSTRAINT inventory_shipment_sales_orders_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_orders(id) ON DELETE CASCADE;


--
-- Name: inventory_shipment_sales_orders inventory_shipment_sales_orders_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipment_sales_orders
    ADD CONSTRAINT inventory_shipment_sales_orders_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES public.inventory_shipments(id) ON DELETE CASCADE;


--
-- Name: inventory_shipments inventory_shipments_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipments
    ADD CONSTRAINT inventory_shipments_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: inventory_shipments inventory_shipments_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_shipments
    ADD CONSTRAINT inventory_shipments_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: invoice_attachments invoice_attachments_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_attachments
    ADD CONSTRAINT invoice_attachments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_master(id) ON DELETE CASCADE;


--
-- Name: invoice_item_batches invoice_item_batches_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item_batches
    ADD CONSTRAINT invoice_item_batches_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id);


--
-- Name: invoice_item_batches invoice_item_batches_invoice_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item_batches
    ADD CONSTRAINT invoice_item_batches_invoice_item_id_fkey FOREIGN KEY (invoice_item_id) REFERENCES public.invoice_items(id) ON DELETE CASCADE;


--
-- Name: invoice_item_batches invoice_item_batches_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_item_batches
    ADD CONSTRAINT invoice_item_batches_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: invoice_items invoice_items_accounts_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_accounts_fkey FOREIGN KEY (accounts) REFERENCES public.accounts(id);


--
-- Name: invoice_items invoice_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_master(id) ON DELETE CASCADE;


--
-- Name: invoice_master invoice_master_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_master
    ADD CONSTRAINT invoice_master_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: invoice_packages invoice_packages_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_packages
    ADD CONSTRAINT invoice_packages_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_master(id) ON DELETE CASCADE;


--
-- Name: invoice_packages invoice_packages_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_packages
    ADD CONSTRAINT invoice_packages_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.inventory_packages(id) ON DELETE CASCADE;


--
-- Name: invoice_sales_orders invoice_sales_orders_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_sales_orders
    ADD CONSTRAINT invoice_sales_orders_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_master(id) ON DELETE CASCADE;


--
-- Name: invoice_sales_orders invoice_sales_orders_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_sales_orders
    ADD CONSTRAINT invoice_sales_orders_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_orders(id) ON DELETE CASCADE;


--
-- Name: invoice_shipments invoice_shipments_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_shipments
    ADD CONSTRAINT invoice_shipments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_master(id) ON DELETE CASCADE;


--
-- Name: invoice_shipments invoice_shipments_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_shipments
    ADD CONSTRAINT invoice_shipments_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES public.inventory_shipments(id) ON DELETE CASCADE;


--
-- Name: product_vendor_mappings item_vendor_mappings_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_vendor_mappings
    ADD CONSTRAINT item_vendor_mappings_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: journal_number_settings journal_number_settings_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_number_settings
    ADD CONSTRAINT journal_number_settings_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: journal_template_items journal_template_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_template_items
    ADD CONSTRAINT journal_template_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: journal_templates journal_templates_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_templates
    ADD CONSTRAINT journal_templates_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: manual_journal_attachments manual_journal_attachments_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_attachments
    ADD CONSTRAINT manual_journal_attachments_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: manual_journal_items manual_journal_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journal_items
    ADD CONSTRAINT manual_journal_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: manual_journals manual_journals_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manual_journals
    ADD CONSTRAINT manual_journals_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: move_order_attachments move_order_attachments_move_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.move_order_attachments
    ADD CONSTRAINT move_order_attachments_move_order_id_fkey FOREIGN KEY (move_order_id) REFERENCES public.inventory_move_orders(id) ON DELETE CASCADE;


--
-- Name: organization organization_assembly_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_assembly_id_fkey FOREIGN KEY (assembly_id) REFERENCES public.assemblies_constituencies(id) ON DELETE SET NULL;


--
-- Name: organization organization_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.lsgd_districts(id) ON DELETE SET NULL;


--
-- Name: organization organization_id_to_registry_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_id_to_registry_fkey FOREIGN KEY (id) REFERENCES public.organisation_branch_master(ref_id) ON DELETE CASCADE;


--
-- Name: organization organization_local_body_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_local_body_id_fkey FOREIGN KEY (local_body_id) REFERENCES public.lsgd_local_bodies(id) ON DELETE SET NULL;


--
-- Name: organization organization_payment_stub_assembly_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_payment_stub_assembly_id_fkey FOREIGN KEY (payment_stub_assembly_id) REFERENCES public.assemblies_constituencies(id);


--
-- Name: organization organization_payment_stub_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_payment_stub_district_id_fkey FOREIGN KEY (payment_stub_district_id) REFERENCES public.lsgd_districts(id);


--
-- Name: organization organization_payment_stub_local_body_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_payment_stub_local_body_id_fkey FOREIGN KEY (payment_stub_local_body_id) REFERENCES public.lsgd_local_bodies(id);


--
-- Name: organization organization_payment_stub_ward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_payment_stub_ward_id_fkey FOREIGN KEY (payment_stub_ward_id) REFERENCES public.lsgd_wards(id);


--
-- Name: organization organization_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id);


--
-- Name: organization organization_ward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.lsgd_wards(id) ON DELETE SET NULL;


--
-- Name: payment_received_allocations payment_received_allocations_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_received_allocations
    ADD CONSTRAINT payment_received_allocations_invoice_id_fkey FOREIGN KEY (sales_invoice_id) REFERENCES public.invoice_master(id);


--
-- Name: payment_received_allocations payment_received_allocations_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_received_allocations
    ADD CONSTRAINT payment_received_allocations_payment_id_fkey FOREIGN KEY (payment_received_id) REFERENCES public.payments_received(id) ON DELETE CASCADE;


--
-- Name: payments_received payments_received_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments_received
    ADD CONSTRAINT payments_received_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: picklist_batch_allocation picklist_batch_allocation_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.picklist_batch_allocation
    ADD CONSTRAINT picklist_batch_allocation_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: picklist_batch_allocation picklist_batch_allocation_picklist_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.picklist_batch_allocation
    ADD CONSTRAINT picklist_batch_allocation_picklist_item_id_fkey FOREIGN KEY (picklist_item_id) REFERENCES public.picklist_items(id);


--
-- Name: picklist_batch_allocation picklist_batch_allocation_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.picklist_batch_allocation
    ADD CONSTRAINT picklist_batch_allocation_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: price_list_items price_list_items_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id) ON DELETE CASCADE;


--
-- Name: price_list_items price_list_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: price_list_volume_ranges price_list_volume_ranges_price_list_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_volume_ranges
    ADD CONSTRAINT price_list_volume_ranges_price_list_item_id_fkey FOREIGN KEY (price_list_item_id) REFERENCES public.price_list_items(id) ON DELETE CASCADE;


--
-- Name: price_lists price_lists_created_by_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_lists
    ADD CONSTRAINT price_lists_created_by_entity_id_fkey FOREIGN KEY (created_by_entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: price_lists price_lists_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_lists
    ADD CONSTRAINT price_lists_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: product_bin_mappings product_bin_mappings_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_bin_mappings
    ADD CONSTRAINT product_bin_mappings_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_branch_inventory_settings product_branch_inventory_settings_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_branch_inventory_settings
    ADD CONSTRAINT product_branch_inventory_settings_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id) ON DELETE CASCADE;


--
-- Name: product_branch_inventory_settings product_branch_inventory_settings_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_branch_inventory_settings
    ADD CONSTRAINT product_branch_inventory_settings_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_branch_inventory_settings product_branch_inventory_settings_reorder_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_branch_inventory_settings
    ADD CONSTRAINT product_branch_inventory_settings_reorder_term_id_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id) ON DELETE SET NULL;


--
-- Name: product_contents product_contents_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_contents
    ADD CONSTRAINT product_contents_content_id_fkey FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: product_contents product_contents_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_contents
    ADD CONSTRAINT product_contents_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_contents product_contents_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_contents
    ADD CONSTRAINT product_contents_schedule_id_fkey FOREIGN KEY (shedule_id) REFERENCES public.drug_schedules(id);


--
-- Name: product_contents product_contents_strength_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_contents
    ADD CONSTRAINT product_contents_strength_id_fkey FOREIGN KEY (strength_id) REFERENCES public.drug_strengths(id);


--
-- Name: product_entity_settings product_entity_settings_preferred_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_entity_settings
    ADD CONSTRAINT product_entity_settings_preferred_vendor_id_fkey FOREIGN KEY (preferred_vendor_id) REFERENCES public.vendors(id) ON DELETE SET NULL;


--
-- Name: product_entity_settings product_entity_settings_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_entity_settings
    ADD CONSTRAINT product_entity_settings_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_entity_settings product_entity_settings_reorder_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_entity_settings
    ADD CONSTRAINT product_entity_settings_reorder_term_id_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id) ON DELETE SET NULL;


--
-- Name: products products_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- Name: products products_buying_rule_id_buying_rules_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_buying_rule_id_buying_rules_id_fk FOREIGN KEY (buying_rule_id) REFERENCES public.buying_rules(id) ON DELETE SET NULL;


--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: products products_inter_state_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_inter_state_tax_id_fkey FOREIGN KEY (inter_state_tax_id) REFERENCES public.tax_rates(id) ON DELETE RESTRICT;


--
-- Name: products products_intra_state_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_intra_state_tax_id_fkey FOREIGN KEY (intra_state_tax_id) REFERENCES public.tax_groups(id) ON DELETE RESTRICT;


--
-- Name: products products_inventory_account_id_accounts_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_inventory_account_id_accounts_id_fk FOREIGN KEY (inventory_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: products products_manufacturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(id);


--
-- Name: products products_preferred_vendor_id_vendors_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_preferred_vendor_id_vendors_id_fk FOREIGN KEY (preferred_vendor_id) REFERENCES public.vendors(id) ON DELETE SET NULL;


--
-- Name: products products_product_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_product_type_id_fkey FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- Name: products products_purchase_account_id_accounts_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_purchase_account_id_accounts_id_fk FOREIGN KEY (purchase_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: products products_rack_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_rack_id_fk FOREIGN KEY (rack_id) REFERENCES public.racks(id) ON DELETE SET NULL;


--
-- Name: products products_reorder_term_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_reorder_term_id_fk FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id) ON DELETE SET NULL;


--
-- Name: products products_rep_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_rep_id_fkey FOREIGN KEY (rep_id) REFERENCES public.sales_reps(id);


--
-- Name: products products_sales_account_id_accounts_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sales_account_id_accounts_id_fk FOREIGN KEY (sales_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: products products_schedule_of_drug_id_schedules_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_schedule_of_drug_id_schedules_id_fk FOREIGN KEY (schedule_of_drug_id) REFERENCES public.drug_schedules(id) ON DELETE SET NULL;


--
-- Name: products products_storage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_storage_id_fkey FOREIGN KEY (storage_id) REFERENCES public.storage_conditions(id);


--
-- Name: products products_unit_id_units_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_unit_id_units_id_fk FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: purchase_order_items purchase_order_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchase_order_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: purchase_orders purchase_orders_discount_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_discount_account_id_fkey FOREIGN KEY (discount_account_id) REFERENCES public.accounts(id);


--
-- Name: purchase_orders purchase_orders_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: purchase_receive_item_batches purchase_receive_item_batches_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_item_batches
    ADD CONSTRAINT purchase_receive_item_batches_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: purchase_receive_item_batches purchase_receive_item_batches_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_item_batches
    ADD CONSTRAINT purchase_receive_item_batches_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: purchase_receive_item_batches purchase_receive_item_batches_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_item_batches
    ADD CONSTRAINT purchase_receive_item_batches_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: purchase_receive_item_batches purchase_receive_item_batches_purchase_receive_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_item_batches
    ADD CONSTRAINT purchase_receive_item_batches_purchase_receive_item_id_fkey FOREIGN KEY (purchase_receive_item_id) REFERENCES public.purchase_receive_items(id) ON DELETE CASCADE;


--
-- Name: purchase_receive_item_batches purchase_receive_item_batches_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_item_batches
    ADD CONSTRAINT purchase_receive_item_batches_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: purchase_receive_items purchase_receive_items_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_items
    ADD CONSTRAINT purchase_receive_items_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: purchase_receive_items purchase_receive_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_items
    ADD CONSTRAINT purchase_receive_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: purchase_receive_items purchase_receive_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_items
    ADD CONSTRAINT purchase_receive_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.products(id);


--
-- Name: purchase_receive_items purchase_receive_items_purchase_receive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_items
    ADD CONSTRAINT purchase_receive_items_purchase_receive_id_fkey FOREIGN KEY (purchase_receive_id) REFERENCES public.purchase_receives(id) ON DELETE CASCADE;


--
-- Name: purchase_receive_items purchase_receive_items_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receive_items
    ADD CONSTRAINT purchase_receive_items_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: purchase_receives purchase_receives_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receives
    ADD CONSTRAINT purchase_receives_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: purchase_receives purchase_receives_transaction_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receives
    ADD CONSTRAINT purchase_receives_transaction_bin_id_fkey FOREIGN KEY (transaction_bin_id) REFERENCES public.bin_master(id);


--
-- Name: purchase_receives purchase_receives_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_receives
    ADD CONSTRAINT purchase_receives_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: purchase_order_attachments purchases_purchase_order_attachments_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_attachments
    ADD CONSTRAINT purchases_purchase_order_attachments_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(id) ON DELETE CASCADE;


--
-- Name: purchase_order_items purchases_purchase_order_items_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchases_purchase_order_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: purchase_order_items purchases_purchase_order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchases_purchase_order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: purchase_order_items purchases_purchase_order_items_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchases_purchase_order_items_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(id) ON DELETE CASCADE;


--
-- Name: purchase_orders purchases_purchase_orders_delivery_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_delivery_customer_id_fkey FOREIGN KEY (delivery_customer_id) REFERENCES public.customers(id);


--
-- Name: purchase_orders purchases_purchase_orders_delivery_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_delivery_warehouse_id_fkey FOREIGN KEY (delivery_warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: purchase_orders purchases_purchase_orders_payment_terms_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_payment_terms_id_fkey FOREIGN KEY (payment_terms_id) REFERENCES public.payment_terms(id);


--
-- Name: purchase_orders purchases_purchase_orders_shipment_preference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_shipment_preference_id_fkey FOREIGN KEY (shipment_preference_id) REFERENCES public.carrier(id);


--
-- Name: purchase_orders purchases_purchase_orders_tds_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_tds_id_fkey FOREIGN KEY (tds_id) REFERENCES public.tds_rates(id);


--
-- Name: purchase_orders purchases_purchase_orders_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: purchase_orders purchases_purchase_orders_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchases_purchase_orders_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id) ON DELETE SET NULL;


--
-- Name: recurring_journals recurring_journals_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_journals
    ADD CONSTRAINT recurring_journals_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: reorder_terms reorder_terms_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reorder_terms
    ADD CONSTRAINT reorder_terms_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: reporting_tags reporting_tags_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reporting_tags
    ADD CONSTRAINT reporting_tags_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: roles roles_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: sales_order_attachments sales_order_attachments_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_attachments
    ADD CONSTRAINT sales_order_attachments_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: sales_order_attachments sales_order_attachments_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_attachments
    ADD CONSTRAINT sales_order_attachments_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_orders(id) ON DELETE CASCADE;


--
-- Name: sales_order_items sales_order_items_accounts_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_accounts_fkey FOREIGN KEY (accounts) REFERENCES public.accounts(id);


--
-- Name: sales_order_items sales_order_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: sales_order_items sales_order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: sales_order_items sales_order_items_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_orders(id) ON DELETE CASCADE;


--
-- Name: sales_order_items sales_order_items_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.tax_rates(id);


--
-- Name: sales_order_items sales_order_items_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order_items
    ADD CONSTRAINT sales_order_items_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: sales_orders sales_orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: sales_orders sales_orders_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: sales_orders sales_orders_payment_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_payment_term_id_fkey FOREIGN KEY (payment_term_id) REFERENCES public.payment_terms(id);


--
-- Name: sales_orders sales_orders_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id);


--
-- Name: sales_orders sales_orders_tds_tcs_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_tds_tcs_tax_id_fkey FOREIGN KEY (tds_tcs_tax_id) REFERENCES public.tds_rates(id);


--
-- Name: sales_orders sales_orders_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_orders
    ADD CONSTRAINT sales_orders_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: sales_payment_links sales_payment_links_customer_id_customers_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_payment_links
    ADD CONSTRAINT sales_payment_links_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: sales_payment_links sales_payment_links_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_payment_links
    ADD CONSTRAINT sales_payment_links_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: sales_payments sales_payments_customer_id_customers_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_payments
    ADD CONSTRAINT sales_payments_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: sales_payments sales_payments_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_payments
    ADD CONSTRAINT sales_payments_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: sales_reps sales_reps_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_reps
    ADD CONSTRAINT sales_reps_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- Name: sales_reps sales_reps_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_reps
    ADD CONSTRAINT sales_reps_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: sales_return_items sales_return_items_sales_return_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_items
    ADD CONSTRAINT sales_return_items_sales_return_id_fkey FOREIGN KEY (sales_return_id) REFERENCES public.sales_returns(id) ON DELETE CASCADE;


--
-- Name: sales_return_receive_batches sales_return_receive_batches_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_batches
    ADD CONSTRAINT sales_return_receive_batches_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id);


--
-- Name: sales_return_receive_batches sales_return_receive_batches_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_batches
    ADD CONSTRAINT sales_return_receive_batches_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: sales_return_receive_batches sales_return_receive_batches_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_batches
    ADD CONSTRAINT sales_return_receive_batches_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: sales_return_receive_batches sales_return_receive_batches_receive_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_batches
    ADD CONSTRAINT sales_return_receive_batches_receive_item_id_fkey FOREIGN KEY (sales_return_receive_item_id) REFERENCES public.sales_return_receive_items(id) ON DELETE CASCADE;


--
-- Name: sales_return_receive_batches sales_return_receive_batches_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_batches
    ADD CONSTRAINT sales_return_receive_batches_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: sales_return_receive_items sales_return_receive_items_receive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_items
    ADD CONSTRAINT sales_return_receive_items_receive_id_fkey FOREIGN KEY (sales_return_receive_id) REFERENCES public.sales_return_receives(id) ON DELETE CASCADE;


--
-- Name: sales_return_receive_items sales_return_receive_items_return_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receive_items
    ADD CONSTRAINT sales_return_receive_items_return_item_id_fkey FOREIGN KEY (sales_return_item_id) REFERENCES public.sales_return_items(id) ON DELETE CASCADE;


--
-- Name: sales_return_receives sales_return_receives_sales_return_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receives
    ADD CONSTRAINT sales_return_receives_sales_return_id_fkey FOREIGN KEY (sales_return_id) REFERENCES public.sales_returns(id) ON DELETE CASCADE;


--
-- Name: sales_return_receives sales_return_receives_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_return_receives
    ADD CONSTRAINT sales_return_receives_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: sales_returns sales_returns_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_returns
    ADD CONSTRAINT sales_returns_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: assemblies_constituencies settings_assemblies_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assemblies_constituencies
    ADD CONSTRAINT settings_assemblies_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.lsgd_districts(id) ON DELETE CASCADE;


--
-- Name: branch_transaction_series settings_branch_transaction_series_transaction_series_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_transaction_series
    ADD CONSTRAINT settings_branch_transaction_series_transaction_series_id_fkey FOREIGN KEY (transaction_series_id) REFERENCES public.transaction_series(id) ON DELETE CASCADE;


--
-- Name: branch_user_access settings_branch_user_access_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_user_access
    ADD CONSTRAINT settings_branch_user_access_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: branch_user_access settings_branch_user_access_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_user_access
    ADD CONSTRAINT settings_branch_user_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: branch_users settings_branch_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_users
    ADD CONSTRAINT settings_branch_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: branches settings_branches_assembly_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_assembly_id_fkey FOREIGN KEY (assembly_id) REFERENCES public.assemblies_constituencies(id) ON DELETE SET NULL;


--
-- Name: branches settings_branches_branch_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_branch_type_fkey FOREIGN KEY (branch_type) REFERENCES public.business_types(code) NOT VALID;


--
-- Name: branches settings_branches_default_transaction_series_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_default_transaction_series_id_fkey FOREIGN KEY (default_transaction_series_id) REFERENCES public.transaction_series(id) ON DELETE SET NULL;


--
-- Name: branches settings_branches_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.lsgd_districts(id) ON DELETE SET NULL;


--
-- Name: branches settings_branches_gst_treatment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_gst_treatment_fkey FOREIGN KEY (gst_treatment) REFERENCES public.gst_treatments(code) NOT VALID;


--
-- Name: branches settings_branches_gstin_import_export_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_gstin_import_export_account_id_fkey FOREIGN KEY (gstin_import_export_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: branches settings_branches_gstin_registration_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_gstin_registration_type_fkey FOREIGN KEY (gstin_registration_type) REFERENCES public.gstin_registration_types(code) NOT VALID;


--
-- Name: branches settings_branches_local_body_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_local_body_id_fkey FOREIGN KEY (local_body_id) REFERENCES public.lsgd_local_bodies(id) ON DELETE SET NULL;


--
-- Name: branches settings_branches_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: branches settings_branches_parent_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_parent_branch_id_fkey FOREIGN KEY (parent_branch_id) REFERENCES public.branches(id) ON DELETE SET NULL;


--
-- Name: branches settings_branches_payment_stub_assembly_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_payment_stub_assembly_id_fkey FOREIGN KEY (payment_stub_assembly_id) REFERENCES public.assemblies_constituencies(id);


--
-- Name: branches settings_branches_ward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT settings_branches_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.lsgd_wards(id) ON DELETE SET NULL;


--
-- Name: lsgd_districts settings_districts_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsgd_districts
    ADD CONSTRAINT settings_districts_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: lsgd_local_bodies settings_local_bodies_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsgd_local_bodies
    ADD CONSTRAINT settings_local_bodies_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.lsgd_districts(id) ON DELETE CASCADE;


--
-- Name: user_branch_access settings_user_location_access_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_branch_access
    ADD CONSTRAINT settings_user_location_access_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: lsgd_wards settings_wards_local_body_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsgd_wards
    ADD CONSTRAINT settings_wards_local_body_id_fkey FOREIGN KEY (local_body_id) REFERENCES public.lsgd_local_bodies(id) ON DELETE CASCADE;


--
-- Name: states states_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.countries(id) ON DELETE CASCADE;


--
-- Name: tax_group_rates tax_group_taxes_tax_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_group_rates
    ADD CONSTRAINT tax_group_taxes_tax_group_id_fkey FOREIGN KEY (tax_group_id) REFERENCES public.tax_groups(id) ON DELETE CASCADE;


--
-- Name: tax_group_rates tax_group_taxes_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_group_rates
    ADD CONSTRAINT tax_group_taxes_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.tax_rates(id) ON DELETE CASCADE;


--
-- Name: tds_group_items tds_group_items_tds_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_group_items
    ADD CONSTRAINT tds_group_items_tds_group_id_fkey FOREIGN KEY (tds_group_id) REFERENCES public.tds_groups(id) ON DELETE CASCADE;


--
-- Name: tds_group_items tds_group_items_tds_rate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_group_items
    ADD CONSTRAINT tds_group_items_tds_rate_id_fkey FOREIGN KEY (tds_rate_id) REFERENCES public.tds_rates(id) ON DELETE CASCADE;


--
-- Name: tds_rates tds_rates_payable_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_rates
    ADD CONSTRAINT tds_rates_payable_account_id_fkey FOREIGN KEY (payable_account_id) REFERENCES public.accounts(id);


--
-- Name: tds_rates tds_rates_receivable_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_rates
    ADD CONSTRAINT tds_rates_receivable_account_id_fkey FOREIGN KEY (receivable_account_id) REFERENCES public.accounts(id);


--
-- Name: tds_rates tds_rates_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tds_rates
    ADD CONSTRAINT tds_rates_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.tds_sections(id);


--
-- Name: timezones timezones_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timezones
    ADD CONSTRAINT timezones_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id) ON DELETE SET NULL;


--
-- Name: transaction_locks transaction_locks_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_locks
    ADD CONSTRAINT transaction_locks_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: transaction_series transaction_series_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_series
    ADD CONSTRAINT transaction_series_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: transactional_sequences transactional_sequences_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactional_sequences
    ADD CONSTRAINT transactional_sequences_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: transfer_order_destination_batches transfer_order_destination_batches_bin_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_destination_batches
    ADD CONSTRAINT transfer_order_destination_batches_bin_fkey FOREIGN KEY (destination_bin_id) REFERENCES public.bin_master(id);


--
-- Name: transfer_order_destination_batches transfer_order_destination_batches_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_destination_batches
    ADD CONSTRAINT transfer_order_destination_batches_item_fkey FOREIGN KEY (transfer_item_id) REFERENCES public.transfer_order_items(id) ON DELETE CASCADE;


--
-- Name: transfer_order_destination_batches transfer_order_destination_batches_wh_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_destination_batches
    ADD CONSTRAINT transfer_order_destination_batches_wh_fkey FOREIGN KEY (destination_warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: transfer_order_items transfer_order_items_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_items
    ADD CONSTRAINT transfer_order_items_product_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: transfer_order_items transfer_order_items_transfer_order_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_items
    ADD CONSTRAINT transfer_order_items_transfer_order_fkey FOREIGN KEY (transfer_order_id) REFERENCES public.transfer_order_master(id) ON DELETE CASCADE;


--
-- Name: transfer_order_logs transfer_order_logs_transfer_order_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_logs
    ADD CONSTRAINT transfer_order_logs_transfer_order_fkey FOREIGN KEY (transfer_order_id) REFERENCES public.transfer_order_master(id) ON DELETE CASCADE;


--
-- Name: transfer_order_master transfer_order_master_destination_wh_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_master
    ADD CONSTRAINT transfer_order_master_destination_wh_fkey FOREIGN KEY (destination_warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: transfer_order_master transfer_order_master_entity_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_master
    ADD CONSTRAINT transfer_order_master_entity_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: transfer_order_master transfer_order_master_source_wh_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_master
    ADD CONSTRAINT transfer_order_master_source_wh_fkey FOREIGN KEY (source_warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: transfer_order_source_batches transfer_order_source_batches_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_source_batches
    ADD CONSTRAINT transfer_order_source_batches_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_master(id);


--
-- Name: transfer_order_source_batches transfer_order_source_batches_bin_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_source_batches
    ADD CONSTRAINT transfer_order_source_batches_bin_fkey FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);


--
-- Name: transfer_order_source_batches transfer_order_source_batches_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_source_batches
    ADD CONSTRAINT transfer_order_source_batches_item_fkey FOREIGN KEY (transfer_item_id) REFERENCES public.transfer_order_items(id) ON DELETE CASCADE;


--
-- Name: transfer_order_source_batches transfer_order_source_batches_layer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_source_batches
    ADD CONSTRAINT transfer_order_source_batches_layer_fkey FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id);


--
-- Name: transfer_order_source_batches transfer_order_source_batches_wh_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_order_source_batches
    ADD CONSTRAINT transfer_order_source_batches_wh_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: units units_uqc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_uqc_id_fkey FOREIGN KEY (uqc_id) REFERENCES public.uqc(id);


--
-- Name: user_branch_access user_branch_access_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_branch_access
    ADD CONSTRAINT user_branch_access_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: users users_default_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_default_warehouse_id_fkey FOREIGN KEY (default_warehouse_id) REFERENCES public.warehouses(id) ON DELETE SET NULL;


--
-- Name: users users_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: vendor_addresses vendor_addresses_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_addresses
    ADD CONSTRAINT vendor_addresses_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: vendor_addresses vendor_addresses_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_addresses
    ADD CONSTRAINT vendor_addresses_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id) ON DELETE CASCADE;


--
-- Name: vendor_bank_accounts vendor_bank_accounts_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_bank_accounts
    ADD CONSTRAINT vendor_bank_accounts_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id) ON DELETE CASCADE;


--
-- Name: vendor_contact_persons vendor_contact_persons_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_contact_persons
    ADD CONSTRAINT vendor_contact_persons_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id) ON DELETE CASCADE;


--
-- Name: vendors vendors_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: warehouses warehouses_assembly_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_assembly_id_fkey FOREIGN KEY (assembly_id) REFERENCES public.assemblies_constituencies(id) ON DELETE SET NULL;


--
-- Name: warehouses warehouses_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE SET NULL;


--
-- Name: warehouses warehouses_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.lsgd_districts(id) ON DELETE SET NULL;


--
-- Name: warehouses warehouses_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);


--
-- Name: warehouses warehouses_local_body_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_local_body_id_fkey FOREIGN KEY (local_body_id) REFERENCES public.lsgd_local_bodies(id) ON DELETE SET NULL;


--
-- Name: warehouses warehouses_source_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_source_branch_id_fkey FOREIGN KEY (source_branch_id) REFERENCES public.branches(id);


--
-- Name: warehouses warehouses_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id) ON DELETE SET NULL;


--
-- Name: warehouses warehouses_ward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.lsgd_wards(id) ON DELETE SET NULL;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: payment_terms Allow all operations on payment_terms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations on payment_terms" ON public.payment_terms USING (true) WITH CHECK (true);


--
-- Name: tds_group_items Allow all operations on tds_group_items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations on tds_group_items" ON public.tds_group_items USING (true) WITH CHECK (true);


--
-- Name: tds_groups Allow all operations on tds_groups; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations on tds_groups" ON public.tds_groups USING (true) WITH CHECK (true);


--
-- Name: tds_rates Allow all operations on tds_rates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations on tds_rates" ON public.tds_rates USING (true) WITH CHECK (true);


--
-- Name: tds_sections Allow all operations on tds_sections; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations on tds_sections" ON public.tds_sections USING (true) WITH CHECK (true);


--
-- Name: audit_logs_archive audit_logs_archive_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audit_logs_archive_read_all ON public.audit_logs_archive FOR SELECT TO authenticated, anon, service_role USING (true);


--
-- Name: audit_logs audit_logs_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audit_logs_read_all ON public.audit_logs FOR SELECT TO authenticated, anon, service_role USING (true);


--
-- Name: roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

--
-- Name: branding service_role_full_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_full_access ON public.branding USING (true) WITH CHECK (true);


--
-- Name: roles service_role_full_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_full_access ON public.roles USING (true) WITH CHECK (true);


--
-- Name: user_branch_access service_role_full_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_full_access ON public.user_branch_access USING (true) WITH CHECK (true);


--
-- Name: users service_role_full_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_full_access ON public.users USING (true) WITH CHECK (true);


--
-- Name: user_branch_access; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_branch_access ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime drug_strengths; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.drug_strengths;


--
-- Name: disable_rls_on_create; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER disable_rls_on_create ON ddl_command_end
         WHEN TAG IN ('CREATE TABLE')
   EXECUTE FUNCTION public.disable_rls_on_new_table();


--
-- Name: etrg_attach_audit_triggers_on_create_table; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER etrg_attach_audit_triggers_on_create_table ON ddl_command_end
         WHEN TAG IN ('CREATE TABLE')
   EXECUTE FUNCTION public.attach_audit_triggers_to_new_tables();


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- Name: pgrst_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_watch ON ddl_command_end
   EXECUTE FUNCTION public.pgrst_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict Ci4cHKCF19zVpEhkZrKTKIZwq3fzmpHLqR5UuiUYHfLTSnbNWvBN12T1jmU8fyI

