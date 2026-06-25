--
-- PostgreSQL database dump
--

\restrict cQ0IZmk7CmuBRAaRAY3q6I4m0Ns6oTCSxJjW2yw33lkLrh3xbs3CwJQaeDZGPzy

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9 (Ubuntu 17.9-1.pgdg24.04+1)

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
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


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
    'in',
    'like',
    'ilike',
    'is',
    'match',
    'imatch',
    'isdistinct'
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
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.profiles (user_id, display_name, preferred_language)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email,'@',1)),
    COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'en')
  );
  RETURN NEW;
END; $$;


--
-- Name: touch_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;


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
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
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
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
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
            array_agg(a.attname order by a.attnum),
            '{}'::text[]
        )
        from
            pg_catalog.pg_attribute a
        where
            a.attrelid = new.entity
            and a.attnum > 0
            and not a.attisdropped
            and pg_catalog.has_column_privilege(
                (new.claims ->> 'role'),
                a.attrelid,
                a.attnum,
                'SELECT'
            );
    filter realtime.user_defined_filter;
    col_type regtype;
    in_val jsonb;
    selected_col text;
begin
    for filter in select * from unnest(new.filters) loop
        if not filter.column_name = any(col_names) then
            raise exception 'invalid column for filter %', filter.column_name;
        end if;

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
            perform realtime.cast(filter.value, col_type);
        end if;
    end loop;

    if new.selected_columns is not null then
        for selected_col in select * from unnest(new.selected_columns) loop
            if not selected_col = any(col_names) then
                raise exception 'invalid column for select %', selected_col;
            end if;
        end loop;
    end if;

    new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value),
        '{}'
    ) from unnest(new.filters) f;

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
-- Name: concepts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.concepts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_id uuid NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    name_bn text,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: knowledge_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_state (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    sub_skill_id uuid NOT NULL,
    mastery numeric DEFAULT 0.3 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    correct integer DEFAULT 0 NOT NULL,
    error_tags text[] DEFAULT '{}'::text[] NOT NULL,
    last_practiced_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    image_url text,
    sub_skill_id uuid,
    was_sanitized boolean DEFAULT false NOT NULL,
    feedback text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT messages_feedback_check CHECK ((feedback = ANY (ARRAY['got_it'::text, 'confused'::text, 'more_help'::text]))),
    CONSTRAINT messages_role_check CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text])))
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    display_name text,
    preferred_language text DEFAULT 'en'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profiles_preferred_language_check CHECK ((preferred_language = ANY (ARRAY['en'::text, 'bn'::text])))
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    subject_id uuid,
    title text DEFAULT 'New session'::text NOT NULL,
    scratchpad jsonb DEFAULT '{"goal": null, "turn": 0, "summary": ""}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    visualization jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: sub_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sub_skills (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    concept_id uuid NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    name_bn text,
    description text,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subjects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    name_bn text,
    sort_order integer DEFAULT 0 NOT NULL
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
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.custom_oauth_providers (id, provider_type, identifier, name, client_id, client_secret, acceptable_client_ids, scopes, pkce_enabled, attribute_mapping, authorization_params, enabled, email_optional, issuer, discovery_url, skip_nonce_check, cached_discovery, discovery_cached_at, authorization_url, token_url, userinfo_url, jwks_uri, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at, invite_token, referrer, oauth_client_state_id, linking_target_id, email_optional) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
38501783-2e12-4cc4-abe1-31737816340a	38501783-2e12-4cc4-abe1-31737816340a	{"sub": "38501783-2e12-4cc4-abe1-31737816340a", "email": "nafiu.rahman@gmail.com", "display_name": "Md Nafiu Rahman", "email_verified": true, "phone_verified": false, "preferred_language": "en"}	email	2026-04-27 13:50:25.930353+00	2026-04-27 13:50:25.930413+00	2026-04-27 13:50:25.930413+00	1e49b915-0cff-487a-ad00-2b8ac4aa05a0
e17aeb55-28e7-4b44-969e-f89325b5e56b	e17aeb55-28e7-4b44-969e-f89325b5e56b	{"sub": "e17aeb55-28e7-4b44-969e-f89325b5e56b", "email": "ahmedsadif67@gmail.com", "display_name": "Sadif Ahmed", "email_verified": false, "phone_verified": false, "preferred_language": "en"}	email	2026-04-28 14:27:19.34666+00	2026-04-28 14:27:19.346716+00	2026-04-28 14:27:19.346716+00	3a11a830-0876-4660-a08b-8e89d423c0ac
c754f0e7-139c-4006-9d13-45e409056a53	c754f0e7-139c-4006-9d13-45e409056a53	{"sub": "c754f0e7-139c-4006-9d13-45e409056a53", "email": "siam11651@outlook.com", "display_name": "Mustafa Siam-ur-Rafique", "email_verified": true, "phone_verified": false, "preferred_language": "en"}	email	2026-04-28 14:33:24.483126+00	2026-04-28 14:33:24.483178+00	2026-04-28 14:33:24.483178+00	534e9b03-ff0c-407a-836f-319e198a967e
94ee6215-3442-47d2-8662-7a6908d1f898	94ee6215-3442-47d2-8662-7a6908d1f898	{"sub": "94ee6215-3442-47d2-8662-7a6908d1f898", "email": "nafiu.rahman@bracu.ac.bd", "display_name": "Md Nafiu Rahman Brac", "email_verified": true, "phone_verified": false, "preferred_language": "en"}	email	2026-04-28 17:48:13.208153+00	2026-04-28 17:48:13.208198+00	2026-04-28 17:48:13.208198+00	545a275e-b5cb-4990-9992-1d7d0b12efd4
30f06ea4-5c7f-4611-a44d-0f6b81b51453	30f06ea4-5c7f-4611-a44d-0f6b81b51453	{"sub": "30f06ea4-5c7f-4611-a44d-0f6b81b51453", "email": "darkdefender574@gmail.com", "display_name": "Sadif Ahmed", "email_verified": false, "phone_verified": false, "preferred_language": "en"}	email	2026-05-18 08:15:49.03211+00	2026-05-18 08:15:49.032152+00	2026-05-18 08:15:49.032152+00	b2b5d305-6338-449f-94b0-55796eb8a191
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
ac3636ab-9dbb-4ca9-ba84-6a8c3125e7de	2026-04-28 14:35:34.69344+00	2026-04-28 14:35:34.69344+00	otp	10bb93b2-0091-48a8-9fe3-b7bd86790dc2
7d00b0b9-7ea4-47a3-b7bb-b3e2d0afacfc	2026-04-28 14:54:14.973908+00	2026-04-28 14:54:14.973908+00	password	49b6ca64-a0b6-4b9d-8add-305af4bd28e7
856683c8-4749-47dc-982f-0703d3a2cb25	2026-05-18 08:43:22.08908+00	2026-05-18 08:43:22.08908+00	password	d1377901-3d8e-4316-b85e-6929bbc99651
8823a530-95e8-48f3-8f24-1f0c44b61990	2026-05-18 08:55:53.444638+00	2026-05-18 08:55:53.444638+00	password	be1c9548-7fcd-457e-bae7-b66bac7b4d16
6096767c-0597-44b5-95f7-733220d96593	2026-05-18 09:07:51.143749+00	2026-05-18 09:07:51.143749+00	password	02dbfaed-efa7-4e0d-808d-0766534599fe
bbfd0435-3414-44b2-9e3e-03216927d821	2026-05-18 12:06:49.491568+00	2026-05-18 12:06:49.491568+00	password	ad1df06d-73bd-42f2-935d-6439eb340c7c
9e352523-c46f-42ea-971d-d8c2f93cc7cf	2026-06-25 14:23:24.676891+00	2026-06-25 14:23:24.676891+00	password	a2af2259-d00c-4d16-9cb6-1c9ab25cd842
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at, nonce) FROM stdin;
\.


--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_client_states (id, provider_type, code_verifier, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type, token_endpoint_auth_method) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
62c5a7a3-667b-4d20-86ba-2e826535c46f	e17aeb55-28e7-4b44-969e-f89325b5e56b	confirmation_token	73d1f1fc38a8906280ae2c3c770e6983ce795fecb6c24480cce38e38	ahmedsadif67@gmail.com	2026-04-28 14:27:20.777978	2026-04-28 14:27:20.777978
e9f0f979-bb1f-4502-8266-ae4f24933444	30f06ea4-5c7f-4611-a44d-0f6b81b51453	confirmation_token	8d0f56f53448abdd773adbc796d0a2d2adc301dd9f22d34f6c60bdfb	darkdefender574@gmail.com	2026-05-18 08:15:50.281443	2026-05-18 08:15:50.281443
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
00000000-0000-0000-0000-000000000000	55	dnxdlfqfpx3e	38501783-2e12-4cc4-abe1-31737816340a	f	2026-05-18 08:43:22.07695+00	2026-05-18 08:43:22.07695+00	\N	856683c8-4749-47dc-982f-0703d3a2cb25
00000000-0000-0000-0000-000000000000	56	sjjudsmqca6k	38501783-2e12-4cc4-abe1-31737816340a	f	2026-05-18 08:55:53.433012+00	2026-05-18 08:55:53.433012+00	\N	8823a530-95e8-48f3-8f24-1f0c44b61990
00000000-0000-0000-0000-000000000000	57	gzdlxndxdhvs	38501783-2e12-4cc4-abe1-31737816340a	t	2026-05-18 09:07:51.134066+00	2026-05-18 12:22:04.004694+00	\N	6096767c-0597-44b5-95f7-733220d96593
00000000-0000-0000-0000-000000000000	59	he2mtmy2gifs	38501783-2e12-4cc4-abe1-31737816340a	f	2026-05-18 12:22:04.012726+00	2026-05-18 12:22:04.012726+00	gzdlxndxdhvs	6096767c-0597-44b5-95f7-733220d96593
00000000-0000-0000-0000-000000000000	58	vyamricvo4cc	38501783-2e12-4cc4-abe1-31737816340a	t	2026-05-18 12:06:49.458892+00	2026-05-18 13:19:09.028019+00	\N	bbfd0435-3414-44b2-9e3e-03216927d821
00000000-0000-0000-0000-000000000000	60	kyh2tvbmjkza	38501783-2e12-4cc4-abe1-31737816340a	f	2026-05-18 13:19:09.038244+00	2026-05-18 13:19:09.038244+00	vyamricvo4cc	bbfd0435-3414-44b2-9e3e-03216927d821
00000000-0000-0000-0000-000000000000	61	guajjig3sqe3	38501783-2e12-4cc4-abe1-31737816340a	f	2026-06-25 14:23:24.657389+00	2026-06-25 14:23:24.657389+00	\N	9e352523-c46f-42ea-971d-d8c2f93cc7cf
00000000-0000-0000-0000-000000000000	18	gbc5rac64swa	c754f0e7-139c-4006-9d13-45e409056a53	f	2026-04-28 14:35:34.69019+00	2026-04-28 14:35:34.69019+00	\N	ac3636ab-9dbb-4ca9-ba84-6a8c3125e7de
00000000-0000-0000-0000-000000000000	21	7jccjn2fws66	c754f0e7-139c-4006-9d13-45e409056a53	f	2026-04-28 14:54:14.969525+00	2026-04-28 14:54:14.969525+00	\N	7d00b0b9-7ea4-47a3-b7bb-b3e2d0afacfc
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
20251104100000
20251111201300
20251201000000
20260115000000
20260121000000
20260219120000
20260302000000
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) FROM stdin;
ac3636ab-9dbb-4ca9-ba84-6a8c3125e7de	c754f0e7-139c-4006-9d13-45e409056a53	2026-04-28 14:35:34.680865+00	2026-04-28 14:35:34.680865+00	\N	aal1	\N	\N	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36	59.153.103.255	\N	\N	\N	\N	\N
7d00b0b9-7ea4-47a3-b7bb-b3e2d0afacfc	c754f0e7-139c-4006-9d13-45e409056a53	2026-04-28 14:54:14.963019+00	2026-04-28 14:54:14.963019+00	\N	aal1	\N	\N	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	59.153.103.255	\N	\N	\N	\N	\N
856683c8-4749-47dc-982f-0703d3a2cb25	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 08:43:22.053716+00	2026-05-18 08:43:22.053716+00	\N	aal1	\N	\N	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	103.111.165.4	\N	\N	\N	\N	\N
8823a530-95e8-48f3-8f24-1f0c44b61990	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 08:55:53.421874+00	2026-05-18 08:55:53.421874+00	\N	aal1	\N	\N	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	165.101.132.141	\N	\N	\N	\N	\N
6096767c-0597-44b5-95f7-733220d96593	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 09:07:51.121242+00	2026-05-18 12:22:04.028458+00	\N	aal1	\N	2026-05-18 12:22:04.028328	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	165.101.132.137	\N	\N	\N	\N	\N
bbfd0435-3414-44b2-9e3e-03216927d821	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 12:06:49.416305+00	2026-05-18 13:19:09.058345+00	\N	aal1	\N	2026-05-18 13:19:09.058235	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	165.101.132.141	\N	\N	\N	\N	\N
9e352523-c46f-42ea-971d-d8c2f93cc7cf	38501783-2e12-4cc4-abe1-31737816340a	2026-06-25 14:23:24.636191+00	2026-06-25 14:23:24.636191+00	\N	aal1	\N	\N	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	45.248.151.131	\N	\N	\N	\N	\N
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	e17aeb55-28e7-4b44-969e-f89325b5e56b	authenticated	authenticated	ahmedsadif67@gmail.com	$2a$10$MYwf.XctaUHlHogw51BLKOvDR5qxED4CuOLEb0SdreBuDyRjmmX5K	\N	\N	73d1f1fc38a8906280ae2c3c770e6983ce795fecb6c24480cce38e38	2026-04-28 14:27:19.356121+00		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"sub": "e17aeb55-28e7-4b44-969e-f89325b5e56b", "email": "ahmedsadif67@gmail.com", "display_name": "Sadif Ahmed", "email_verified": false, "phone_verified": false, "preferred_language": "en"}	\N	2026-04-28 14:27:19.315246+00	2026-04-28 14:27:20.772659+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	38501783-2e12-4cc4-abe1-31737816340a	authenticated	authenticated	nafiu.rahman@gmail.com	$2a$10$vdHLpBeyBZykxT8HIDdQy.yYkGszNKeKKMIdsLUArT5PE/g23PUnq	2026-04-27 13:50:45.974397+00	\N		2026-04-27 13:50:25.937473+00		\N			\N	2026-06-25 14:23:24.635019+00	{"provider": "email", "providers": ["email"]}	{"sub": "38501783-2e12-4cc4-abe1-31737816340a", "email": "nafiu.rahman@gmail.com", "display_name": "Md Nafiu Rahman", "email_verified": true, "phone_verified": false, "preferred_language": "en"}	\N	2026-04-27 13:50:25.896895+00	2026-06-25 14:23:24.668343+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	30f06ea4-5c7f-4611-a44d-0f6b81b51453	authenticated	authenticated	darkdefender574@gmail.com	$2a$10$esKSYd.pnAgKsu/0vm/I5uhyPgyRw0idZkVoFEG6/sPmHyrcczNcm	\N	\N	8d0f56f53448abdd773adbc796d0a2d2adc301dd9f22d34f6c60bdfb	2026-05-18 08:15:49.034181+00		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"sub": "30f06ea4-5c7f-4611-a44d-0f6b81b51453", "email": "darkdefender574@gmail.com", "display_name": "Sadif Ahmed", "email_verified": false, "phone_verified": false, "preferred_language": "en"}	\N	2026-05-18 08:15:49.02943+00	2026-05-18 08:15:50.273271+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	c754f0e7-139c-4006-9d13-45e409056a53	authenticated	authenticated	siam11651@outlook.com	$2a$10$C4E8mFzY4GKcC0KAseuKGu1NHddAXLT3xVjX5CKsGN.ks.YEx4FI6	2026-04-28 14:35:34.66932+00	\N		2026-04-28 14:33:24.49005+00		\N			\N	2026-04-28 14:54:14.962911+00	{"provider": "email", "providers": ["email"]}	{"sub": "c754f0e7-139c-4006-9d13-45e409056a53", "email": "siam11651@outlook.com", "display_name": "Mustafa Siam-ur-Rafique", "email_verified": true, "phone_verified": false, "preferred_language": "en"}	\N	2026-04-28 14:33:24.459588+00	2026-04-28 14:54:14.971831+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	94ee6215-3442-47d2-8662-7a6908d1f898	authenticated	authenticated	nafiu.rahman@bracu.ac.bd	$2a$10$GtMivC6/CpC62g5ePLm7dOICkvEhrsFMAsJGAeNgA0EAJhorWjDDq	2026-04-28 17:48:50.460067+00	\N		2026-04-28 17:48:13.212851+00		\N			\N	2026-04-28 17:48:59.174927+00	{"provider": "email", "providers": ["email"]}	{"sub": "94ee6215-3442-47d2-8662-7a6908d1f898", "email": "nafiu.rahman@bracu.ac.bd", "display_name": "Md Nafiu Rahman Brac", "email_verified": true, "phone_verified": false, "preferred_language": "en"}	\N	2026-04-28 17:48:13.163299+00	2026-04-28 17:48:59.177307+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.webauthn_challenges (id, user_id, challenge_type, session_data, created_at, expires_at) FROM stdin;
\.


--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.webauthn_credentials (id, user_id, credential_id, public_key, attestation_type, aaguid, sign_count, transports, backup_eligible, backed_up, friendly_name, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- Data for Name: concepts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.concepts (id, subject_id, slug, name, name_bn, sort_order) FROM stdin;
521ac0d8-1fa0-45b4-9c4e-bec902195ccc	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	algebra	Algebra	বীজগণিত	1
76e36c1a-0b76-4da8-8a7a-a0fb122e66ca	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	geometry	Geometry	জ্যামিতি	2
3034868a-7252-43cb-a820-e77595c2e3bc	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	calculus	Calculus	ক্যালকুলাস	3
e7ffc2e1-758b-4b66-a526-eeaa9dbbfe04	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	trigonometry	Trigonometry	ত্রিকোণমিতি	4
e1ecf748-85b2-4e51-bac8-7ece1c6d8ca3	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	probability	Probability	সম্ভাব্যতা	5
4b02cada-30b5-4d44-8c25-fbdd83b95ca7	d49b8e43-74fa-46f2-86c3-d2d008be9527	mechanics	Mechanics	বলবিদ্যা	1
94b9f9cc-7378-4e8b-95cf-def6a6a9b737	d49b8e43-74fa-46f2-86c3-d2d008be9527	thermodynamics	Thermodynamics	তাপগতিবিদ্যা	2
d232ddaa-7bee-402a-a4ff-172db6f51440	d49b8e43-74fa-46f2-86c3-d2d008be9527	electromagnetism	Electromagnetism	তড়িৎ-চুম্বকত্ব	3
e475dc02-79f9-492d-be40-f482a50ddda0	d49b8e43-74fa-46f2-86c3-d2d008be9527	waves-optics	Waves & Optics	তরঙ্গ ও আলোকবিজ্ঞান	4
94e55821-8ca1-4c38-af35-f2abb0a51469	ee980a11-c022-4142-8381-895b4b3295dd	atomic	Atomic structure	পারমাণবিক গঠন	1
d16929d9-c89e-4998-9972-bb0b8f6f72bc	ee980a11-c022-4142-8381-895b4b3295dd	reactions	Chemical reactions	রাসায়নিক বিক্রিয়া	2
291f7af1-7826-4971-9b16-8c8037d3f0c0	ee980a11-c022-4142-8381-895b4b3295dd	organic	Organic chemistry	জৈব রসায়ন	3
9917d02e-5a40-4736-a07b-e6f3c37be8dc	ee980a11-c022-4142-8381-895b4b3295dd	solutions	Solutions & acids	দ্রবণ ও অ্যাসিড	4
dd1df910-26b4-4ccf-980f-c08f88fdabeb	026a9e35-dc20-4b28-8775-f10e329670df	cell	Cell biology	কোষ জীববিজ্ঞান	1
342fcd10-caef-4505-989a-05e6cd3e70fc	026a9e35-dc20-4b28-8775-f10e329670df	genetics	Genetics	জিনতত্ত্ব	2
2f7978e8-1f54-4f3b-ad08-0659c74d4651	026a9e35-dc20-4b28-8775-f10e329670df	physiology	Physiology	শারীরবিদ্যা	3
4f731b33-645b-4f43-93fe-63bda88466e2	026a9e35-dc20-4b28-8775-f10e329670df	ecology	Ecology	বাস্তুবিদ্যা	4
\.


--
-- Data for Name: knowledge_state; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_state (id, user_id, sub_skill_id, mastery, attempts, correct, error_tags, last_practiced_at, created_at, updated_at) FROM stdin;
133a57ce-9d7e-4c15-a046-910e076e9444	38501783-2e12-4cc4-abe1-31737816340a	2046e63c-e5ba-421a-901b-0b9778bc80c2	0.5764705882352941	2	1	{}	2026-04-28 12:30:53.034+00	2026-04-28 09:34:36.491131+00	2026-04-28 12:30:53.100999+00
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.messages (id, session_id, user_id, role, content, image_url, sub_skill_id, was_sanitized, feedback, created_at) FROM stdin;
0a712652-360c-4c22-9009-bf7ff2c21d6f	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	user	hi solve 2x+6=0 for me	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 08:50:38.83488+00
a6dbfd82-223e-4bd0-84bb-4cb4bf274313	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	assistant	Hello! Let's work through this equation together step by step. \n\nTo start solving $2x + 6 = 0$, our first goal is to get the term with the variable, $2x$, all by itself on one side. What operation can we perform on both sides of the equation to cancel out the $+6$?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 08:50:41.755375+00
63268c4b-2d1a-4446-b9b4-b428eb006ff8	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	user	subtraction	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 09:04:24.92832+00
259097d4-29ae-41ae-b198-f4568d348fa5	b602aa96-07d2-4fa4-a9ff-05f28d6fbb94	38501783-2e12-4cc4-abe1-31737816340a	user	do you know about the movie mission impossible?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 11:57:34.010326+00
358e3c76-2a8b-4525-a310-08f3a469c8b3	b602aa96-07d2-4fa4-a9ff-05f28d6fbb94	38501783-2e12-4cc4-abe1-31737816340a	assistant	Those movies are certainly packed with high-stakes action! Since I am here to help you with your mathematical missions, would you like to start by solving a linear equation, such as finding $x$ in $2x + 5 = 11$?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	confused	2026-04-28 11:57:47.231363+00
65df32ac-cc55-435f-a447-f2de79796bdb	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	assistant	You are exactly right that subtraction is the correct operation to use here! To get the $2x$ term all by itself on one side of the equation, what specific number should we subtract from both sides?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	got_it	2026-04-28 09:04:40.615275+00
a321a060-c54a-4a93-aeea-ec88783110be	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	user	1	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:31:07.39189+00
8da29876-4914-497b-aaca-fd323cd4573d	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	assistant	That's exactly right! Subtracting 1 is the perfect next step to isolate the $2x$ term. \n\nWhat does the resulting equation look like after you perform that subtraction on both sides?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:31:16.786674+00
9f7b4441-e6ad-4b61-9553-2158f6c34c37	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	user	2x=0	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:31:38.710106+00
5a24a572-4a03-4ea3-a910-d7d410f58336	b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	assistant	Great work getting the equation to the form $2x = 0$. Since $x$ is currently being multiplied by $2$, what is the opposite operation you can perform on both sides to isolate $x$?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:31:42.605305+00
5d3f1b4a-24b9-4565-8385-006013933029	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	hi solve 2x+6=0 for me	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:51:12.581288+00
b868f347-d842-4512-9264-de8ca44823f3	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant	To solve for $x$, our first goal is to isolate the term $2x$ on one side of the equation. \n\nWhat operation could you perform on both sides of $$2x + 6 = 0$$ to get $2x$ by itself?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:51:29.179986+00
6de3c199-177c-40a5-9e98-a18cf64d353f	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	subtraction	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:51:52.608364+00
cd0dacc0-2a6d-4993-9979-fb0a8345f0b1	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant	Spot on! If you subtract 6 from both sides of the equation $$2x + 6 = 0$$, what is the resulting equation?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:51:54.856352+00
ab3e06c8-d8fd-470b-b444-588480369d97	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	2x=1	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:52:21.365839+00
524fde89-682d-4c7d-8277-2fc512c973f4	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant	You correctly simplified the left side to $2x$ by subtracting 6. However, looking at the right side, if you start at $0$ and subtract $6$, what is the result?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:52:23.402421+00
603d01f9-90f6-43ac-9cfb-6b4971c571e6	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	2x=-6	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:52:46.553443+00
105caca3-c445-4413-bbef-3edb1a9867e9	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant	Great job correctly simplifying the equation to $2x = -6$. \n\nNow that you have isolated the $2x$ term, what operation can you perform to solve for just a single $x$?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:52:48.892618+00
6749f838-30ba-41f3-b2f3-3ed6aec77dfb	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	division?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:53:24.96389+00
6606cc9c-e587-4b1c-b21a-6183226c1d49	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant	Exactly right! Since $x$ is being multiplied by $2$, division is the perfect way to undo that. \n\nIf you divide both sides of the equation $$2x = -6$$ by $2$, what value do you find for $x$?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 12:53:45.789349+00
e746ec23-5514-4879-9dec-87d26716728a	e94fb7d5-58cf-4b4d-81f6-dea92fe4bbc1	c754f0e7-139c-4006-9d13-45e409056a53	user	hello	\N	4739c1b8-73c6-4a8f-9d4e-0cc6889b02c5	f	\N	2026-04-28 14:54:41.851357+00
b1217f2a-d643-467d-a63f-94c02b4e4fd9	e94fb7d5-58cf-4b4d-81f6-dea92fe4bbc1	c754f0e7-139c-4006-9d13-45e409056a53	assistant		\N	4739c1b8-73c6-4a8f-9d4e-0cc6889b02c5	f	\N	2026-04-28 14:54:44.29373+00
d9d99131-703f-448e-b0f0-eb45e5ad305f	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	-3	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 16:56:03.031181+00
9611a2a5-1a86-4317-9874-2e950a296f87	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant		\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 16:56:04.268776+00
98e9f26c-2cd6-40dd-b639-ada3ac41ec0a	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	-3	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 16:59:08.560231+00
a80ff95c-62ad-4518-b951-2624e1df27cd	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant	That is exactly correct, $x = -3$ is the solution! \n\nTo be absolutely sure of your result, what value do you get for the left side of the equation if you substitute $-3$ back into the original expression $$2x + 6$$?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 16:59:11.728702+00
4308d9c3-afd7-446b-8530-616c8386074f	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	user	0	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 16:59:23.579658+00
de3b803a-00a9-4ac2-b144-e1d5338595a2	80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	assistant	Since you found that $2(-3) + 6 = 0$, and the original equation was $2x + 6 = 0$, your solution $x = -3$ is perfectly verified. Excellent work following the steps to isolate $x$ and check your answer!\n\nDo you feel confident applying these same steps—subtracting then dividing—to solve other linear equations?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 16:59:26.422004+00
e283925b-2ab3-4e85-bf08-0f72994c51ec	cbff8001-9723-4578-a54d-3f162a2c4694	38501783-2e12-4cc4-abe1-31737816340a	user	hi	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 17:00:59.407526+00
d159ab88-3f4f-47a9-a84b-23bedb235fc9	cbff8001-9723-4578-a54d-3f162a2c4694	38501783-2e12-4cc4-abe1-31737816340a	assistant	Hello! I'm happy to help you work through some mathematics today. What specific topic or problem would you like to practice together?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 17:01:04.338447+00
a2b305dc-3202-4145-b117-1553a8acba41	a3b7bd8d-6957-40d5-b608-093b65ea9f62	38501783-2e12-4cc4-abe1-31737816340a	user	explain projectile motion	\N	4739c1b8-73c6-4a8f-9d4e-0cc6889b02c5	f	\N	2026-04-28 18:06:21.811872+00
79348eba-ef0e-47d8-a6b8-d2ec01e11179	a3b7bd8d-6957-40d5-b608-093b65ea9f62	38501783-2e12-4cc4-abe1-31737816340a	assistant	Projectile motion involves an object moving through the air, and we analyze it by breaking the path into two independent parts: a horizontal component and a vertical component. To begin our analysis, what forces are acting on the object while it is in flight, assuming we ignore air resistance?	\N	4739c1b8-73c6-4a8f-9d4e-0cc6889b02c5	f	\N	2026-04-28 18:06:26.245928+00
a36d394b-0662-4f94-a3e8-bd8541daae34	0e4cb914-66e1-48e6-b074-8c8ab5019e80	38501783-2e12-4cc4-abe1-31737816340a	user	explain the slope of a straight line	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 18:13:06.677415+00
99de5787-2721-443b-b2a4-0e649aec1823	0e4cb914-66e1-48e6-b074-8c8ab5019e80	38501783-2e12-4cc4-abe1-31737816340a	assistant	To understand the slope of a straight line, it helps to imagine you are walking up a hill or climbing a staircase. The slope is simply a numerical way to describe the "steepness" of that incline.\n\nIf you were comparing two different hills, what specific measurements do you think you would need to take to determine which one is steeper?	\N	2046e63c-e5ba-421a-901b-0b9778bc80c2	f	\N	2026-04-28 18:13:09.23479+00
e35eca99-d850-4ade-adea-12f4b9d252bb	9871df2a-3889-4a36-8359-bd0c2142cf2d	38501783-2e12-4cc4-abe1-31737816340a	user	how to solve x^2+5x+6=0	\N	799c39c4-f302-4007-a0c6-b66aa4c5d7ad	f	\N	2026-04-28 19:12:34.026824+00
b1f2d430-35a2-458b-8ff6-b520426c0e6a	9871df2a-3889-4a36-8359-bd0c2142cf2d	38501783-2e12-4cc4-abe1-31737816340a	assistant	To solve the equation $x^2 + 5x + 6 = 0$, we can start by trying to factor the expression on the left side. Can you find two numbers that multiply together to give $6$ and also add up to $5$?	\N	799c39c4-f302-4007-a0c6-b66aa4c5d7ad	f	\N	2026-04-28 19:12:36.939359+00
c2cca208-265d-4961-9f65-e9c29e243bb5	6e9c5213-1e44-4e48-a9e4-d49998e928ef	38501783-2e12-4cc4-abe1-31737816340a	user	Explain friedel crafts alkylation	\N	17d43af4-803c-4754-993d-389090e9a677	f	\N	2026-04-29 02:39:17.272956+00
5712a95b-e769-47e9-8074-ce16a7bdf39e	6e9c5213-1e44-4e48-a9e4-d49998e928ef	38501783-2e12-4cc4-abe1-31737816340a	assistant	Friedel-Crafts alkylation is a classic organic reaction used to attach an alkyl group to an aromatic system. To understand how this transformation occurs, what three essential components—specifically an organic starting material, a reagent to provide the alkyl group, and a specific type of catalyst—are required for this reaction to take place?	\N	17d43af4-803c-4754-993d-389090e9a677	f	\N	2026-04-29 02:39:20.172641+00
c4eace44-32d1-459a-becf-764f792a2b63	c29baf40-ea41-40af-9ede-50a9eeb67bb1	38501783-2e12-4cc4-abe1-31737816340a	user	Explain friedel crafts alkylation	\N	17d43af4-803c-4754-993d-389090e9a677	f	\N	2026-04-29 03:00:08.48382+00
3762e745-9081-418d-8baa-8dbe1bd9a0e7	c29baf40-ea41-40af-9ede-50a9eeb67bb1	38501783-2e12-4cc4-abe1-31737816340a	assistant	Friedel-Crafts alkylation is a classic electrophilic aromatic substitution reaction used to attach an alkyl group to an aromatic ring. To understand how this transformation occurs, what are the two primary organic starting materials required, and what type of catalyst is typically used to facilitate the reaction?	\N	17d43af4-803c-4754-993d-389090e9a677	f	\N	2026-04-29 03:00:12.094869+00
8bb8e7d0-d436-4c5d-9e3d-d9869c97e341	9e4785be-b96d-486b-9e60-a7336d404b27	38501783-2e12-4cc4-abe1-31737816340a	user	Explain friedel crafts alkylation	\N	17d43af4-803c-4754-993d-389090e9a677	f	\N	2026-04-29 03:18:54.17625+00
f7f1ebb0-4423-496b-b60c-0ea35ded3a18	9e4785be-b96d-486b-9e60-a7336d404b27	38501783-2e12-4cc4-abe1-31737816340a	assistant	To understand Friedel-Crafts alkylation, let's start with the basic components of the reaction. What are the typical starting materials required to perform this transformation, and what specific type of catalyst is needed to activate the process?	\N	17d43af4-803c-4754-993d-389090e9a677	f	\N	2026-04-29 03:18:56.258462+00
f913f5fd-b76e-4a11-b821-5883c45bda8a	33fc6119-fcda-4086-ab89-b48cc3f1a32e	38501783-2e12-4cc4-abe1-31737816340a	user	explain first derivative of sinx	\N	854978fd-8b12-4a5e-903d-6ec32d70ceeb	f	\N	2026-04-29 03:21:40.480458+00
ee24dd75-0090-4fec-b29d-2f59b7ae0d60	33fc6119-fcda-4086-ab89-b48cc3f1a32e	38501783-2e12-4cc4-abe1-31737816340a	assistant	To find the derivative of $f(x) = \\sin(x)$ from first principles, we start with the formal limit definition of a derivative. \n\nUsing the general formula $f'(x) = \\lim_{h \\to 0} \\frac{f(x+h) - f(x)}{h}$, how would you set up this expression specifically for the function $f(x) = \\sin(x)$?	\N	854978fd-8b12-4a5e-903d-6ec32d70ceeb	f	\N	2026-04-29 03:21:43.244106+00
bd71a048-29c6-4788-9051-16b95d6a9fe0	020e40b3-c5ec-4094-9d1f-6d62024026ac	38501783-2e12-4cc4-abe1-31737816340a	user	explain the kreb's cycle to me	\N	2a2c60ba-8818-4fe4-a4ab-a085c19bfcd7	f	\N	2026-04-29 05:22:24.416584+00
4f436338-c5c9-461c-a4e3-124ba2aa23e1	020e40b3-c5ec-4094-9d1f-6d62024026ac	38501783-2e12-4cc4-abe1-31737816340a	assistant	The Krebs cycle, also known as the citric acid cycle, is a central sequence of reactions used by all aerobic organisms to generate energy. To begin our exploration, do you know which specific part of the cell this cycle takes place in and what two-carbon molecule enters the cycle to start the process?	\N	2a2c60ba-8818-4fe4-a4ab-a085c19bfcd7	f	\N	2026-04-29 05:22:27.665991+00
0c037d52-b94b-4734-8cf6-59fdac5c7fc9	d14af1ce-d480-49f0-9a59-8a2e45e61aab	38501783-2e12-4cc4-abe1-31737816340a	user	explain the kreb's cycle to me	\N	2a2c60ba-8818-4fe4-a4ab-a085c19bfcd7	f	\N	2026-04-29 05:44:13.358362+00
a7e6c07c-915f-4508-a242-4537403b50b4	d14af1ce-d480-49f0-9a59-8a2e45e61aab	38501783-2e12-4cc4-abe1-31737816340a	assistant	I would be happy to help you explore the Krebs cycle, also known as the citric acid cycle. To get us started, do you know where specifically within the cell this process takes place and what its main purpose is in cellular respiration?	\N	2a2c60ba-8818-4fe4-a4ab-a085c19bfcd7	f	\N	2026-04-29 05:44:16.452593+00
2271c3ca-7588-4478-9736-a8838f487950	fc6c44ed-b2bf-427b-974a-86aa8f966833	38501783-2e12-4cc4-abe1-31737816340a	user	teach me about circle equation	\N	aad06b1d-4686-46fc-9ac7-f796b8ba7dd2	f	\N	2026-05-18 08:16:15.706243+00
e2aee9e0-c30b-4883-a658-5cf4fd05a62b	fc6c44ed-b2bf-427b-974a-86aa8f966833	38501783-2e12-4cc4-abe1-31737816340a	assistant	The standard equation for a circle in a coordinate plane is $(x - h)^2 + (y - k)^2 = r^2$, where $(h, k)$ represents the center and $r$ is the radius. This formula is actually a specific application of the distance formula, which helps us ensure every point on the circle is exactly $r$ units away from the center. Are you familiar with the Pythagorean theorem, $a^2 + b^2 = c^2$, for right triangles?	\N	aad06b1d-4686-46fc-9ac7-f796b8ba7dd2	f	\N	2026-05-18 08:16:25.88303+00
245568e8-087a-4471-a9f5-87588a13031f	451b6de1-17c2-42e3-99c0-55a45c712091	38501783-2e12-4cc4-abe1-31737816340a	user	Can you each me about ellipse equation?	\N	aad06b1d-4686-46fc-9ac7-f796b8ba7dd2	f	\N	2026-05-18 08:24:34.724398+00
4aadb401-1df2-46ea-b5f7-c00d7203ae6d	451b6de1-17c2-42e3-99c0-55a45c712091	38501783-2e12-4cc4-abe1-31737816340a	assistant	An ellipse is essentially a circle that has been stretched or compressed along its axes. The standard form for an ellipse centered at the origin is:\n$$\\frac{x^2}{a^2} + \\frac{y^2}{b^2} = 1$$\nBefore we explore what the variables $a$ and $b$ represent, do you recall the standard equation for a circle centered at the origin with radius $r$?	\N	aad06b1d-4686-46fc-9ac7-f796b8ba7dd2	f	\N	2026-05-18 08:24:45.081122+00
be45be86-4d1e-4f01-91c4-d1704d92d4c3	fc6c44ed-b2bf-427b-974a-86aa8f966833	38501783-2e12-4cc4-abe1-31737816340a	user	Yes I know about it	\N	aad06b1d-4686-46fc-9ac7-f796b8ba7dd2	f	\N	2026-05-18 08:30:35.374271+00
a8b2403a-55ce-48e9-968e-32ad5a91545f	fc6c44ed-b2bf-427b-974a-86aa8f966833	38501783-2e12-4cc4-abe1-31737816340a	assistant	That's perfect! If we imagine a right triangle where the hypotenuse connects the center $(h, k)$ to any point $(x, y)$ on the circle, how would you express the horizontal and vertical lengths of that triangle's legs using those coordinates?	\N	aad06b1d-4686-46fc-9ac7-f796b8ba7dd2	f	\N	2026-05-18 08:30:59.64398+00
e26249be-020d-4636-9301-19a56d746bf1	bbb7d83f-2678-4405-948c-d0d77cb4e36d	38501783-2e12-4cc4-abe1-31737816340a	user	explain to me	https://cehdpstgbhgwwmnqekek.supabase.co/storage/v1/object/sign/problem-images/38501783-2e12-4cc4-abe1-31737816340a/bbb7d83f-2678-4405-948c-d0d77cb4e36d/1779094776132-img.jpg?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9iZDRjYmM0OS1kYWJkLTQ1OTQtOGFkZC1hYTBjMDM5OWZkNGQiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJwcm9ibGVtLWltYWdlcy8zODUwMTc4My0yZTEyLTRjYzQtYWJlMS0zMTczNzgxNjM0MGEvYmJiN2Q4M2YtMjY3OC00NDA1LTk0OGMtZDBkNzdjYjRlMzZkLzE3NzkwOTQ3NzYxMzItaW1nLmpwZyIsImlhdCI6MTc3OTA5NDc3NywiZXhwIjoxNzc5MDk4Mzc3fQ.dTAe1XO0CARGOutEuF29r-K_5I45jkmBiyU1Dh0ZbJw	049284a6-f721-4f5e-8ede-3ea65ca25b34	f	\N	2026-05-18 08:59:49.366583+00
4fe2ae57-8b46-4432-ae33-3f5ddce17078	bbb7d83f-2678-4405-948c-d0d77cb4e36d	38501783-2e12-4cc4-abe1-31737816340a	assistant	To begin solving a cubic equation like $x^3 - 6x^2 + 11x - 6 = 0$, we first want to find a value for $x$ that makes the expression equal to zero. This value is called a "root" of the equation.\n\nWhat value do you get for the expression if you substitute $x = 1$ into the equation?	\N	049284a6-f721-4f5e-8ede-3ea65ca25b34	f	\N	2026-05-18 08:59:57.85122+00
71f9253c-1490-4ae1-adc3-ab4064b59d18	b7c7338b-dc8c-4b44-802d-6906c5dc4c77	38501783-2e12-4cc4-abe1-31737816340a	user	explain to me	https://cehdpstgbhgwwmnqekek.supabase.co/storage/v1/object/sign/problem-images/38501783-2e12-4cc4-abe1-31737816340a/b7c7338b-dc8c-4b44-802d-6906c5dc4c77/1779095291255-img.jpg?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9iZDRjYmM0OS1kYWJkLTQ1OTQtOGFkZC1hYTBjMDM5OWZkNGQiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJwcm9ibGVtLWltYWdlcy8zODUwMTc4My0yZTEyLTRjYzQtYWJlMS0zMTczNzgxNjM0MGEvYjdjNzMzOGItZGM4Yy00YjQ0LTgwMmQtNjkwNmM1ZGM0Yzc3LzE3NzkwOTUyOTEyNTUtaW1nLmpwZyIsImlhdCI6MTc3OTA5NTI5MSwiZXhwIjoxNzc5MDk4ODkxfQ.B9K_z-_XUhxjvS7qxXn_I90c-85jDUZrX0ssZPXJNkA	049284a6-f721-4f5e-8ede-3ea65ca25b34	f	\N	2026-05-18 09:08:26.263848+00
244cbbf1-3153-4017-87a0-22e03865ed57	b7c7338b-dc8c-4b44-802d-6906c5dc4c77	38501783-2e12-4cc4-abe1-31737816340a	assistant	To begin solving the polynomial equation $x^3 - 6x^2 + 11x - 6 = 0$, we can look for integer roots among the divisors of the constant term, $-6$. \n\nGiven that the divisors are $\\pm 1, \\pm 2, \\pm 3,$ and $\\pm 6$, what value do you get if you substitute $x = 1$ into the equation?	\N	049284a6-f721-4f5e-8ede-3ea65ca25b34	f	\N	2026-05-18 09:08:32.073933+00
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.profiles (id, user_id, display_name, preferred_language, created_at, updated_at) FROM stdin;
0be9cff4-3eff-465d-8072-b27168e4f831	38501783-2e12-4cc4-abe1-31737816340a	Md Nafiu Rahman	en	2026-04-27 13:50:25.89654+00	2026-04-27 13:50:25.89654+00
c0006539-a167-4902-a921-de016f36e147	c754f0e7-139c-4006-9d13-45e409056a53	Mustafa Siam-ur-Rafique	en	2026-04-28 14:33:24.45883+00	2026-04-28 14:33:24.45883+00
e8df1518-a933-49ed-b0b4-a4ed8bd04226	94ee6215-3442-47d2-8662-7a6908d1f898	Md Nafiu Rahman Brac	en	2026-04-28 17:48:13.162968+00	2026-04-28 17:48:13.162968+00
7627d481-9a6c-4abe-894b-555184e41a70	30f06ea4-5c7f-4611-a44d-0f6b81b51453	Sadif Ahmed	en	2026-05-18 08:15:49.029096+00	2026-05-18 08:15:49.029096+00
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sessions (id, user_id, subject_id, title, scratchpad, created_at, updated_at, visualization) FROM stdin;
80b06467-2197-4493-8816-c497f9c73303	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Confirm the verification and wrap up the problem.", "turn": 8, "summary": "[turn 8] subgoal: Confirm the verification and wrap up the problem.\\nlast diagnosis: none"}	2026-04-28 12:50:58.215246+00	2026-04-28 16:59:23.751644+00	{}
b602aa96-07d2-4fa4-a9ff-05f28d6fbb94	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Acknowledge the movie reference briefly and pivot back to asking if the student has a math question they'd like to work on.", "turn": 1, "summary": "[turn 1] subgoal: Acknowledge the movie reference briefly and pivot back to asking if the student has a math question they'd like to work on.\\nlast diagnosis: Off-topic inquiry."}	2026-04-28 11:57:03.325621+00	2026-04-28 11:57:34.197664+00	{}
cbff8001-9723-4578-a54d-3f162a2c4694	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Engage the student and invite them to share a problem or topic they'd like to practice.", "turn": 1, "summary": "[turn 1] subgoal: Engage the student and invite them to share a problem or topic they'd like to practice.\\nlast diagnosis: first attempt"}	2026-04-28 17:00:49.969787+00	2026-04-28 17:00:59.793001+00	{}
b6efc1b0-8fd4-4a15-85e9-77acddbcb024	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Acknowledge the correct simplification and ask the student how to isolate x when it is being multiplied by 2.", "turn": 4, "summary": "[turn 4] subgoal: Acknowledge the correct simplification and ask the student how to isolate x when it is being multiplied by 2.\\nlast diagnosis: first attempt at this simplified step"}	2026-04-28 08:48:37.25293+00	2026-04-28 12:31:38.941541+00	{}
a3b7bd8d-6957-40d5-b608-093b65ea9f62	38501783-2e12-4cc4-abe1-31737816340a	d49b8e43-74fa-46f2-86c3-d2d008be9527	Physics session	{"goal": "Introduce the idea of decomposing motion into horizontal and vertical components and ask the student to identify which forces act on the object while it's in the air.", "turn": 1, "summary": "[turn 1] subgoal: Introduce the idea of decomposing motion into horizontal and vertical components and ask the student to identify which forces act on the object while it's in the air.\\nlast diagnosis: first attempt"}	2026-04-28 18:05:54.581358+00	2026-04-28 18:06:54.211705+00	{"title": "Projectile Motion Explorer", "concept": "projectile_motion", "p5_code": "let position;\\nlet velocity;\\nlet gravity;\\nlet path = [];\\nlet isFlying = false;\\nlet launchPoint;\\n\\nconst ACCENT_COLOR_X = \\"#16A085\\"; // Teal for horizontal\\nconst ACCENT_COLOR_Y = \\"#C0392B\\"; // Crimson for vertical\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  launchPoint = createVector(60, 380);\\n  gravity = createVector(0, 0.2);\\n  resetSketch();\\n}\\n\\nfunction draw() {\\n  background(255);\\n  drawGround();\\n\\n  if (isFlying) {\\n    velocity.add(gravity);\\n    position.add(velocity);\\n    path.push(position.copy());\\n\\n    if (position.y >= launchPoint.y && path.length > 1) {\\n      position.y = launchPoint.y;\\n      isFlying = false;\\n    }\\n  } else {\\n    let launchVector = createVector(mouseX - launchPoint.x, mouseY - launchPoint.y);\\n    drawAimArrow(launchVector);\\n  }\\n\\n  drawPath();\\n  drawBall();\\n\\n  if (isFlying) {\\n    drawVelocityVectors();\\n  }\\n\\n  drawLabels();\\n}\\n\\nfunction mousePressed() {\\n  if (mouseX < 0 || mouseX > width || mouseY < 0 || mouseY > height) {\\n    return;\\n  }\\n  if (!isFlying) {\\n    let launchVector = createVector(mouseX - launchPoint.x, mouseY - launchPoint.y);\\n    launchVector.mult(0.1);\\n    launchVector.limit(15);\\n    velocity = launchVector;\\n    position = launchPoint.copy();\\n    isFlying = true;\\n    path = [];\\n  } else {\\n    resetSketch();\\n  }\\n}\\n\\nfunction resetSketch() {\\n  isFlying = false;\\n  position = launchPoint.copy();\\n  velocity = createVector(0, 0);\\n  path = [];\\n}\\n\\nfunction drawGround() {\\n  stroke(0);\\n  strokeWeight(2);\\n  line(0, launchPoint.y, width, launchPoint.y);\\n}\\n\\nfunction drawAimArrow(vec) {\\n  push();\\n  stroke(0);\\n  strokeWeight(2);\\n  translate(launchPoint.x, launchPoint.y);\\n  line(0, 0, vec.x, vec.y);\\n  pop();\\n}\\n\\nfunction drawPath() {\\n  noFill();\\n  stroke(0, 50);\\n  strokeWeight(2);\\n  beginShape();\\n  for (let p of path) {\\n    vertex(p.x, p.y);\\n  }\\n  endShape();\\n}\\n\\nfunction drawBall() {\\n  noStroke();\\n  fill(0);\\n  ellipse(position.x, position.y, 16, 16);\\n}\\n\\nfunction drawVelocityVectors() {\\n  let scaleFactor = 5;\\n\\n  push();\\n  translate(position.x, position.y);\\n  \\n  // Horizontal Velocity (vx)\\n  stroke(ACCENT_COLOR_X);\\n  strokeWeight(3);\\n  line(0, 0, velocity.x * scaleFactor, 0);\\n  fill(ACCENT_COLOR_X);\\n  noStroke();\\n  text(\\"vx\\", velocity.x * scaleFactor + 5, 5);\\n\\n  // Vertical Velocity (vy)\\n  stroke(ACCENT_COLOR_Y);\\n  strokeWeight(3);\\n  line(0, 0, 0, velocity.y * scaleFactor);\\n  fill(ACCENT_COLOR_Y);\\n  noStroke();\\n  textAlign(CENTER);\\n  text(\\"vy\\", 0, velocity.y * scaleFactor + 15);\\n  \\n  pop();\\n}\\n\\nfunction drawLabels() {\\n  fill(0);\\n  noStroke();\\n  textSize(14);\\n  textAlign(LEFT);\\n  if (!isFlying) {\\n      text(\\"Move mouse to aim. Click to launch.\\", 10, 20);\\n  } else {\\n      text(\\"Click to reset.\\", 10, 20);\\n  }\\n  \\n  fill(ACCENT_COLOR_X);\\n  text(\\"Horizontal velocity (vx) is constant.\\", 10, height - 40);\\n  fill(ACCENT_COLOR_Y);\\n  text(\\"Vertical velocity (vy) changes due to gravity.\\", 10, height - 20);\\n}\\n", "explanation": "This simulation shows that projectile motion is made of two independent parts: constant horizontal velocity (teal vector) and constant vertical acceleration (crimson vector). The combination creates the curved, parabolic path.", "interaction_hint": "Move the mouse to set the launch angle and speed, then click to launch the ball. Click again to reset."}
e94fb7d5-58cf-4b4d-81f6-dea92fe4bbc1	c754f0e7-139c-4006-9d13-45e409056a53	d49b8e43-74fa-46f2-86c3-d2d008be9527	Physics session	{"goal": "Greet the student warmly and encourage them to present a physics problem or concept they'd like to explore, perhaps by mentioning the main areas like Mechanics, Thermodynamics, Electromagnetism, or Waves.", "turn": 1, "summary": "[turn 1] subgoal: Greet the student warmly and encourage them to present a physics problem or concept they'd like to explore, perhaps by mentioning the main areas like Mechanics, Thermodynamics, Electromagnetism, or Waves.\\nlast diagnosis: first attempt"}	2026-04-28 14:54:18.558993+00	2026-04-28 14:54:42.613894+00	{}
0e4cb914-66e1-48e6-b074-8c8ab5019e80	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Introduce the conceptual meaning of slope using an analogy (like a staircase or a hill) and prompt the student to describe how they might measure that steepness.", "turn": 1, "summary": "[turn 1] subgoal: Introduce the conceptual meaning of slope using an analogy (like a staircase or a hill) and prompt the student to describe how they might measure that steepness.\\nlast diagnosis: first attempt"}	2026-04-28 18:12:48.718611+00	2026-04-28 18:13:30.060776+00	{"title": "Interactive Slope of a Line", "concept": "slope", "p5_code": "\\nconst AXIS_COLOR = 50;\\nconst BG_COLOR = 255;\\nconst ACCENT_COLOR = \\"#C0392B\\"; // Crimson\\nconst COMPONENT_COLOR = \\"#16A085\\"; // Teal\\nconst GRID_COLOR = 230;\\nconst TEXT_COLOR = 0;\\nconst SCALE = 40; // Pixels per unit\\n\\nlet originX, originY;\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  originX = width / 2;\\n  originY = height / 2;\\n  textFont(\\"sans-serif\\");\\n}\\n\\nfunction draw() {\\n  background(BG_COLOR);\\n  drawGridAndAxes();\\n\\n  // Convert mouse pixel coordinates to our custom Cartesian coordinates\\n  let cartesianX = (mouseX - originX) / SCALE;\\n  let cartesianY = (originY - mouseY) / SCALE; // Y is inverted in p5.js\\n\\n  drawSlopeTriangle(cartesianX, cartesianY);\\n  displayInfo(cartesianX, cartesianY);\\n}\\n\\nfunction drawGridAndAxes() {\\n  // Draw grid lines\\n  stroke(GRID_COLOR);\\n  strokeWeight(1);\\n  for (let x = 0; x < width; x += SCALE) {\\n    line(x, 0, x, height);\\n  }\\n  for (let y = 0; y < height; y += SCALE) {\\n    line(0, y, width, y);\\n  }\\n\\n  // Draw main axes\\n  stroke(AXIS_COLOR);\\n  strokeWeight(2);\\n  line(originX, 0, originX, height); // Y-axis\\n  line(0, originY, width, originY); // X-axis\\n\\n  // Axis labels\\n  fill(AXIS_COLOR);\\n  noStroke();\\n  textSize(14);\\n  textAlign(LEFT, TOP);\\n  text(\\"y\\", originX + 5, 5);\\n  textAlign(RIGHT, BOTTOM);\\n  text(\\"x\\", width - 5, originY - 5);\\n}\\n\\nfunction drawSlopeTriangle(cx, cy) {\\n  // Convert Cartesian coordinates back to pixel coordinates for drawing\\n  let px = originX + cx * SCALE;\\n  let py = originY - cy * SCALE;\\n\\n  // Draw the \\"run\\" (Δx)\\n  stroke(COMPONENT_COLOR);\\n  strokeWeight(2.5);\\n  line(originX, originY, px, originY);\\n\\n\\n  // Draw the \\"rise\\" (Δy)\\n  line(px, originY, px, py);\\n\\n  // Draw the main line (hypotenuse)\\n  stroke(ACCENT_COLOR);\\n  strokeWeight(3);\\n  line(originX, originY, px, py);\\n\\n  // Draw the interactive point\\n  fill(ACCENT_COLOR);\\n  noStroke();\\n  ellipse(px, py, 12, 12);\\n  \\n  // Draw labels for rise and run\\n  fill(TEXT_COLOR);\\n  noStroke();\\n  textSize(15);\\n  textAlign(CENTER, TOP);\\n  text(\\"run (Δx) = \\" + cx.toFixed(2), (originX + px) / 2, originY + 8);\\n  textAlign(LEFT, CENTER);\\n  text(\\"rise (Δy) = \\" + cy.toFixed(2), px + 8, (originY + py) / 2);\\n\\n}\\n\\nfunction displayInfo(cx, cy) {\\n  let slope;\\n  let slopeText;\\n\\n  // Handle vertical line case to avoid division by zero\\n  if (abs(cx) < 0.01) {\\n    slopeText = \\"undefined\\";\\n  } else {\\n    slope = cy / cx;\\n    slopeText = \\"= \\" + slope.toFixed(2);\\n  }\\n\\n  fill(TEXT_COLOR);\\n  noStroke();\\n  textSize(18);\\n  textAlign(LEFT, TOP);\\n  text(\\"Slope = rise / run\\", 20, 20);\\n  text(slopeText, 20, 45);\\n}\\n", "explanation": "This visualization shows how the slope of a line is calculated from its 'rise' (vertical change) and 'run' (horizontal change). The slope measures the line's steepness and direction.", "interaction_hint": "Move your mouse to change the red point and see how the rise, run, and slope value change."}
9871df2a-3889-4a36-8359-bd0c2142cf2d	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Guide the student to identify the two numbers needed to factor the quadratic trinomial.", "turn": 1, "summary": "[turn 1] subgoal: Guide the student to identify the two numbers needed to factor the quadratic trinomial.\\nlast diagnosis: first attempt"}	2026-04-28 19:12:12.021978+00	2026-04-28 19:12:49.522237+00	{"title": "Visualizing Quadratic Equations", "concept": "quadratic_equation", "p5_code": "let sliderA, sliderB, sliderC;\\nlet scaleFactor = 25;\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  \\n  // Create sliders for coefficients a, b, and c\\n  sliderA = createSlider(-5, 5, 1, 0.1);\\n  sliderA.position(10, 10);\\n  sliderB = createSlider(-10, 10, 5, 0.1);\\n  sliderB.position(10, 40);\\n  sliderC = createSlider(-10, 10, 6, 0.1);\\n  sliderC.position(10, 70);\\n  \\n  textSize(16);\\n}\\n\\nfunction draw() {\\n  background(255);\\n  \\n  let a = sliderA.value();\\n  let b = sliderB.value();\\n  let c = sliderC.value();\\n\\n  // Draw axis labels and equation\\n  noStroke();\\n  fill(0);\\n  text(\\"a = \\" + a.toFixed(1), 150, 25);\\n  text(\\"b = \\" + b.toFixed(1), 150, 55);\\n  text(\\"c = \\" + c.toFixed(1), 150, 85);\\n  \\n  let signB = b < 0 ? \\"-\\" : \\"+\\";\\n  let signC = c < 0 ? \\"-\\" : \\"+\\";\\n  let equation = `y = ${a.toFixed(1)}x² ${signB} ${abs(b).toFixed(1)}x ${signC} ${abs(c).toFixed(1)}`;\\n  textAlign(CENTER);\\n  text(equation, width / 2, 30);\\n\\n  // Set up coordinate system\\n  translate(width / 2, height / 2 + 50);\\n  scale(1, -1);\\n\\n  // Draw axes\\n  stroke(150);\\n  line(-width / 2, 0, width / 2, 0); // x-axis\\n  line(0, -height / 2 - 50, 0, height / 2); // y-axis\\n  \\n  // Draw grid lines\\n  for (let i = -width/2; i < width/2; i += scaleFactor) {\\n    line(i, -height, i, height);\\n  }\\n  for (let i = -height/2; i < height/2; i += scaleFactor) {\\n    line(-width, i, width, i);\\n  }\\n\\n\\n  // Draw the parabola\\n  noFill();\\n  stroke(\\"#C0392B\\");\\n  strokeWeight(2);\\n  beginShape();\\n  for (let x = -width / (2 * scaleFactor); x < width / (2 * scaleFactor); x += 0.1) {\\n    let y = a * x * x + b * x + c;\\n    vertex(x * scaleFactor, y * scaleFactor);\\n  }\\n  endShape();\\n  strokeWeight(1);\\n\\n  // Calculate and display roots\\n  let discriminant = b * b - 4 * a * c;\\n  \\n  // Flip text back\\n  scale(1, -1);\\n  textAlign(LEFT);\\n  fill(0);\\n  noStroke();\\n\\n  if (abs(a) < 0.01) {\\n    text(\\"This is a line, not a parabola!\\", -width/2 + 20, -height/2 + 20);\\n  } else if (discriminant >= 0) {\\n    let x1 = (-b + sqrt(discriminant)) / (2 * a);\\n    let x2 = (-b - sqrt(discriminant)) / (2 * a);\\n    \\n    // Draw circles at the roots\\n    stroke(\\"#C0392B\\");\\n    fill(255);\\n    ellipse(x1 * scaleFactor, 0, 10, 10);\\n    ellipse(x2 * scaleFactor, 0, 10, 10);\\n    \\n    // Label the roots\\n    noStroke();\\n    fill(0);\\n    text(\\"Roots: \\" + x1.toFixed(2) + \\", \\" + x2.toFixed(2), -width/2 + 20, -height/2 + 20);\\n\\n  } else {\\n    text(\\"No real roots\\", -width/2 + 20, -height/2 + 20);\\n  }\\n}", "explanation": "This sketch graphs the parabola y = ax² + bx + c. The 'solutions' or 'roots' of the equation ax² + bx + c = 0 are the x-values where the parabola crosses the horizontal x-axis (where y = 0).", "interaction_hint": "Use the sliders to change the coefficients a, b, and c, and see how the parabola and its roots change."}
6e9c5213-1e44-4e48-a9e4-d49998e928ef	38501783-2e12-4cc4-abe1-31737816340a	ee980a11-c022-4142-8381-895b4b3295dd	Chemistry session	{"goal": "Guide the student to identify the three main components required for a Friedel-Crafts alkylation reaction.", "turn": 1, "summary": "[turn 1] subgoal: Guide the student to identify the three main components required for a Friedel-Crafts alkylation reaction.\\nlast diagnosis: first attempt"}	2026-04-29 02:38:46.339185+00	2026-04-29 02:40:40.573279+00	{"title": "Friedel-Crafts Alkylation Mechanism", "concept": "friedel_crafts_alkylation", "p5_code": "// p5.js sketch for Friedel-Crafts Alkylation\\n\\n// GLOBAL STATE\\nlet state; // \\"start\\", \\"carbocation_formed\\", \\"product_formed\\"\\n\\n// MOLECULES (will be objects with pos, size, etc.)\\nlet benzene, alkylGroup, halide, catalyst, carbocation, catalystComplex;\\nlet originalAlkylGroupR;\\n\\n// DRAGGING STATE\\nlet draggedItem = null;\\n\\n// COLORS\\nconst C_BG = \\"#FFFFFF\\";\\nconst C_TEXT = \\"#000000\\";\\nconst C_BENZENE = \\"#34495E\\";\\nconst C_ACCENT = \\"#C0392B\\"; // Reactive species\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  textAlign(CENTER, CENTER);\\n  textSize(14);\\n  initializeState();\\n}\\n\\nfunction draw() {\\n  background(C_BG);\\n  drawTitles();\\n  \\n  switch (state) {\\n    case \\"start\\":\\n      drawStartState();\\n      break;\\n    case \\"carbocation_formed\\":\\n      drawCarbocationState();\\n      break;\\n    case \\"product_formed\\":\\n      drawProductState();\\n      break;\\n  }\\n}\\n\\nfunction initializeState() {\\n  state = \\"start\\";\\n  benzene = { x: 150, y: 210, r: 50 };\\n  const alkylHalideStart = { x: 420, y: 120 };\\n  alkylGroup = { x: alkylHalideStart.x - 20, y: alkylHalideStart.y, r: 20, label: \\"R\\" };\\n  originalAlkylGroupR = alkylGroup.r;\\n  halide = { x: alkylHalideStart.x + 20, y: alkylHalideStart.y, r: 15, label: \\"Cl\\" };\\n  catalyst = { x: 420, y: 320, w: 60, h: 40, label: \\"AlCl₃\\" };\\n  carbocation = null;\\n  catalystComplex = null;\\n  draggedItem = null;\\n}\\n\\nfunction drawStartState() {\\n  drawBenzene(benzene.x, benzene.y, benzene.r, true);\\n  drawAlkylHalide(alkylGroup.x, alkylGroup.y, halide.x, halide.y);\\n  drawCatalyst(catalyst.x, catalyst.y, catalyst.w, catalyst.h, catalyst.label);\\n}\\n\\nfunction drawCarbocationState() {\\n  drawBenzene(benzene.x, benzene.y, benzene.r, true);\\n  if(carbocation) {\\n      drawCarbocation(carbocation.x, carbocation.y, carbocation.r, carbocation.label);\\n  }\\n  if(catalystComplex) {\\n      drawCatalystComplex(catalystComplex.x, catalystComplex.y, \\"[AlCl₄]⁻\\");\\n  }\\n}\\n\\nfunction drawProductState() {\\n  drawAlkylatedBenzene(benzene.x, benzene.y, benzene.r);\\n  drawCatalyst(420, 320, 60, 40, \\"AlCl₃\\");\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(16);\\n  text(\\"(+ HCl)\\", 420, 260);\\n  drawResetButton();\\n}\\n\\nfunction drawTitles() {\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(20);\\n  text(\\"Friedel-Crafts Alkylation Mechanism\\", width / 2, 30);\\n  textSize(14);\\n  let instruction = \\"\\";\\n  if (state === \\"start\\") {\\n    instruction = \\"Drag the catalyst (AlCl₃) to the alkyl halide (R-Cl).\\";\\n  } else if (state === \\"carbocation_formed\\") {\\n    instruction = \\"Drag the reactive carbocation (R+) to the benzene ring.\\";\\n  } else if (state === \\"product_formed\\") {\\n    instruction = \\"Reaction Complete! A new C-C bond is formed.\\";\\n  }\\n  text(instruction, width / 2, 60);\\n}\\n\\nfunction drawBenzene(x, y, r, isAromatic) {\\n  stroke(C_BENZENE);\\n  strokeWeight(3);\\n  noFill();\\n  beginShape();\\n  for (let i = 0; i < 6; i++) {\\n    let angle = TWO_PI / 6 * i - PI / 6;\\n    vertex(x + r * cos(angle), y + r * sin(angle));\\n  }\\n  endShape(CLOSE);\\n  if (isAromatic) {\\n    ellipse(x, y, r * 1.2, r * 1.2);\\n  }\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(12);\\n  text(\\"Benzene\\", x, y + r + 20);\\n}\\n\\nfunction drawAlkylHalide(rx, ry, clx, cly) {\\n  stroke(C_TEXT);\\n  strokeWeight(2);\\n  line(rx, ry, clx, cly);\\n  fill(C_BENZENE);\\n  noStroke();\\n  ellipse(rx, ry, alkylGroup.r * 2);\\n  fill(C_BG);\\n  textSize(16);\\n  text(alkylGroup.label, rx, ry);\\n  fill(C_BENZENE);\\n  noStroke();\\n  ellipse(clx, cly, halide.r * 2);\\n  fill(C_BG);\\n  textSize(12);\\n  text(halide.label, clx, cly);\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(12);\\n  text(\\"Alkyl Halide\\", (rx + clx) / 2, ry - 40);\\n}\\n\\nfunction drawCatalyst(x, y, w, h, label) {\\n  rectMode(CENTER);\\n  stroke(C_ACCENT);\\n  strokeWeight(2);\\n  fill(255, 240, 240);\\n  rect(x, y, w, h, 5);\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(12);\\n  text(label, x, y);\\n  text(\\"Catalyst\\", x, y + h / 2 + 15);\\n  rectMode(CORNER);\\n}\\n\\nfunction drawCarbocation(x, y, r, label) {\\n  noStroke();\\n  fill(C_ACCENT, 50);\\n  ellipse(x, y, r * 3);\\n  fill(C_ACCENT);\\n  stroke(C_BG);\\n  strokeWeight(2);\\n  ellipse(x, y, r * 2);\\n  fill(C_BG);\\n  noStroke();\\n  textSize(18);\\n  text(label, x, y);\\n  fill(C_ACCENT);\\n  textSize(25);\\n  text(\\"+\\", x + r * 0.8, y - r * 0.8);\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(12);\\n  text(\\"Carbocation (Electrophile)\\", x, y + r + 20);\\n}\\n\\nfunction drawCatalystComplex(x, y, label) {\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(16);\\n  text(label, x, y);\\n}\\n\\nfunction drawAlkylatedBenzene(x, y, r) {\\n  drawBenzene(x, y, r, true);\\n  let attachX = x + r * cos(-PI / 6);\\n  let attachY = y + r * sin(-PI / 6);\\n  let rGroupX = attachX + 30;\\n  let rGroupY = attachY - 30;\\n  stroke(C_BENZENE);\\n  strokeWeight(3);\\n  line(attachX, attachY, rGroupX, rGroupY);\\n  fill(C_BENZENE);\\n  noStroke();\\n  ellipse(rGroupX, rGroupY, originalAlkylGroupR * 2);\\n  fill(C_BG);\\n  textSize(16);\\n  text(\\"R\\", rGroupX, rGroupY);\\n  fill(C_TEXT);\\n  noStroke();\\n  textSize(12);\\n  text(\\"Alkylated Product\\", x, y + r + 20);\\n}\\n\\nfunction drawResetButton() {\\n  let btn = { x: width - 110, y: height - 50, w: 100, h: 35 };\\n  stroke(C_TEXT);\\n  strokeWeight(1);\\n  fill(230);\\n  rect(btn.x, btn.y, btn.w, btn.h, 5);\\n  noStroke();\\n  fill(C_TEXT);\\n  textSize(16);\\n  text(\\"Reset\\", btn.x + btn.w / 2, btn.y + btn.h / 2);\\n}\\n\\nfunction mousePressed() {\\n  if (state === \\"start\\" && mouseX > catalyst.x - catalyst.w / 2 && mouseX < catalyst.x + catalyst.w / 2 && mouseY > catalyst.y - catalyst.h / 2 && mouseY < catalyst.y + catalyst.h / 2) {\\n    draggedItem = catalyst;\\n  } else if (state === \\"carbocation_formed\\" && carbocation && dist(mouseX, mouseY, carbocation.x, carbocation.y) < carbocation.r * 1.5) {\\n    draggedItem = carbocation;\\n  } else if (state === \\"product_formed\\") {\\n    let btn = { x: width - 110, y: height - 50, w: 100, h: 35 };\\n    if (mouseX > btn.x && mouseX < btn.x + btn.w && mouseY > btn.y && mouseY < btn.y + btn.h) {\\n      initializeState();\\n    }\\n  }\\n}\\n\\nfunction mouseDragged() {\\n  if (draggedItem) {\\n    draggedItem.x = mouseX;\\n    draggedItem.y = mouseY;\\n  }\\n}\\n\\nfunction mouseReleased() {\\n  if (!draggedItem) return;\\n  if (state === \\"start\\" && draggedItem === catalyst) {\\n    let alkylHalideCenterX = (alkylGroup.x + halide.x) / 2;\\n    if (dist(catalyst.x, catalyst.y, alkylHalideCenterX, alkylGroup.y) < 60) {\\n      state = \\"carbocation_formed\\";\\n      carbocation = { x: alkylGroup.x, y: alkylGroup.y, r: alkylGroup.r, label: \\"R\\" };\\n      catalystComplex = { x: catalyst.x, y: catalyst.y };\\n    }\\n  } else if (state === \\"carbocation_formed\\" && draggedItem === carbocation) {\\n    if (dist(carbocation.x, carbocation.y, benzene.x, benzene.y) < benzene.r) {\\n      state = \\"product_formed\\";\\n    }\\n  }\\n  draggedItem = null;\\n}\\n", "explanation": "This visualization shows how a Lewis acid catalyst is used to generate a reactive carbocation (an electrophile). The electron-rich benzene ring then attacks this electrophile to form a new carbon-carbon bond.", "interaction_hint": "Drag the catalyst (AlCl₃) to the alkyl halide (R-Cl), then drag the resulting carbocation (R+) to the benzene ring."}
33fc6119-fcda-4086-ab89-b48cc3f1a32e	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Guide the student to set up the limit definition for the derivative of sin(x).", "turn": 1, "summary": "[turn 1] subgoal: Guide the student to set up the limit definition for the derivative of sin(x).\\nlast diagnosis: first attempt"}	2026-04-29 03:21:12.225565+00	2026-04-29 03:22:07.218413+00	{"title": "Derivative of sin(x) as Slope", "concept": "derivative", "p5_code": "\\n// GLOBAL VARIABLES\\nlet scale = 60; // Pixels per unit\\nlet x_offset, y_offset;\\n\\n// p5.js SETUP FUNCTION\\nfunction setup() {\\n  createCanvas(560, 420);\\n  x_offset = 80;\\n  y_offset = height / 2;\\n  textFont(\\"Georgia\\");\\n}\\n\\n// p5.js DRAW FUNCTION\\nfunction draw() {\\n  background(255);\\n  translate(x_offset, y_offset);\\n\\n  drawAxes();\\n  drawCurve(sin, color(0, 0, 0), 2); // Main sin(x) curve\\n  \\n  // Let the mouse control the x-value\\n  let x_val = (mouseX - x_offset) / scale;\\n  \\n  // Clamp x_val to be within the visible range to avoid weirdness at edges\\n  let min_x = -x_offset / scale;\\n  let max_x = (width - x_offset) / scale;\\n  x_val = constrain(x_val, min_x, max_x);\\n\\n  let y_val = sin(x_val);\\n  let slope = cos(x_val); // The derivative of sin(x) is cos(x)\\n\\n  drawTangent(x_val, y_val, slope);\\n  drawDerivativeValue(x_val, slope);\\n\\n  // Draw the main point on the sin(x) curve\\n  fill(\\"#C0392B\\"); // Crimson red\\n  noStroke();\\n  circle(x_val * scale, -y_val * scale, 12);\\n  \\n  drawLabels(x_val, y_val, slope);\\n}\\n\\n\\n// HELPER FUNCTIONS\\nfunction drawAxes() {\\n  stroke(200);\\n  strokeWeight(1);\\n  // X-axis\\n  line(-x_offset, 0, width, 0);\\n  // Y-axis\\n  line(0, -height / 2, 0, height / 2);\\n\\n  // Axis labels\\n  noStroke();\\n  fill(100);\\n  textSize(12);\\n  textAlign(CENTER, TOP);\\n  for (let i = -1; i < 8; i++) {\\n    text(i, i * scale, 5);\\n  }\\n  textAlign(RIGHT, CENTER);\\n  for (let i = -1; i <= 1; i++) {\\n    if (i !== 0) text(i, -8, -i * scale);\\n  }\\n  text(\\"π\\", PI * scale, 20);\\n  text(\\"2π\\", 2*PI * scale, 20);\\n\\n}\\n\\nfunction drawCurve(func, c, weight) {\\n  stroke(c);\\n  strokeWeight(weight);\\n  noFill();\\n  beginShape();\\n  for (let x = -x_offset; x < width - x_offset; x++) {\\n    let angle = x / scale;\\n    let y = -func(angle) * scale;\\n    vertex(x, y);\\n  }\\n  endShape();\\n}\\n\\nfunction drawTangent(x, y, m) {\\n  let x_px = x * scale;\\n  let y_px = -y * scale;\\n  let len = scale * 0.75;\\n  \\n  stroke(\\"#C0392B\\"); // Crimson red\\n  strokeWeight(2);\\n\\n  // Find angle of slope and draw a line\\n  let angle = atan(m);\\n  let dx = len * cos(angle);\\n  let dy = len * sin(angle);\\n  line(x_px - dx, y_px - dy, x_px + dx, y_px + dy);\\n}\\n\\nfunction drawDerivativeValue(x, slope) {\\n  // Plot the cos(x) curve for reference\\n  drawCurve(cos, color(22, 160, 133, 100), 4);\\n\\n  let x_px = x * scale;\\n  let y_px_deriv = -slope * scale;\\n  \\n  // Draw the point representing the slope value\\n  fill(\\"#16A085\\"); // Teal green\\n  noStroke();\\n  circle(x_px, y_px_deriv, 12);\\n\\n  // Draw a dashed line from the point to the y-axis to show its value\\n  stroke(22, 160, 133, 150);\\n  strokeWeight(1);\\n  drawingContext.setLineDash([5, 5]);\\n  line(0, y_px_deriv, x_px, y_px_deriv);\\n  drawingContext.setLineDash([]);\\n}\\n\\nfunction drawLabels(x, y, m) {\\n  // Use resetMatrix to draw in screen-space, ignoring translate()\\n  resetMatrix(); \\n  noStroke();\\n  fill(0);\\n  textSize(16);\\n  textAlign(LEFT, TOP);\\n\\n  text(\\"y = sin(x)\\", 10, 10);\\n  \\n  fill(\\"#16A085\\");\\n  text(\\"y' = cos(x)\\", 10, 35);\\n  \\n  fill(\\"#C0392B\\");\\n  let slopeText = \\"Slope = \\" + m.toFixed(2);\\n  // Position label near the mouse cursor\\n  let textX = mouseX > width - 150 ? mouseX - 150 : mouseX + 20;\\n  let textY = mouseY > height - 50 ? mouseY - 40 : mouseY + 20;\\n  text(slopeText, textX, textY);\\n}\\n\\n", "explanation": "The derivative of a function at a point is the slope of the line tangent to the curve at that point. This sketch shows the graph of sin(x) and its tangent line; the y-coordinate of the green dot represents the slope of this tangent line.", "interaction_hint": "Move your mouse left and right to slide the red point along the sin(x) curve and watch how the slope changes."}
c29baf40-ea41-40af-9ede-50a9eeb67bb1	38501783-2e12-4cc4-abe1-31737816340a	ee980a11-c022-4142-8381-895b4b3295dd	Chemistry session	{"goal": "Prompt the student to identify the starting materials and the type of catalyst required for a Friedel-Crafts alkylation.", "turn": 1, "summary": "[turn 1] subgoal: Prompt the student to identify the starting materials and the type of catalyst required for a Friedel-Crafts alkylation.\\nlast diagnosis: first attempt"}	2026-04-29 03:00:00.86364+00	2026-04-29 03:00:34.620036+00	{"title": "Friedel-Crafts Alkylation Mechanism", "concept": "friedel_crafts_alkylation", "p5_code": "let stage = 0;\\nlet dragging = false;\\n\\n// Positions\\nlet benzenePos;\\nlet catalystPos;\\nlet alkylHalidePos;\\nlet rPos, clPos;\\n\\nlet rOffset;\\n\\nconst ALKYL_COLOR = \\"#C0392B\\"; // crimson\\nconst TEXT_COLOR = \\"#000000\\";\\nconst BG_COLOR = \\"#FFFFFF\\";\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  resetSketch();\\n  textAlign(CENTER, CENTER);\\n  textSize(16);\\n  rOffset = createVector(-15, 0);\\n}\\n\\nfunction resetSketch() {\\n  stage = 0;\\n  benzenePos = createVector(150, height / 2);\\n  catalystPos = createVector(450, height * 0.25);\\n  alkylHalidePos = createVector(450, height * 0.75);\\n  rPos = p5.Vector.add(alkylHalidePos, rOffset);\\n  clPos = p5.Vector.add(alkylHalidePos, p5.Vector.mult(rOffset, -1));\\n}\\n\\nfunction draw() {\\n  background(BG_COLOR);\\n  \\n  // Handle dragging logic\\n  if (dragging) {\\n    alkylHalidePos.x = mouseX;\\n    alkylHalidePos.y = mouseY;\\n    // Update R and Cl based on the parent alkylHalidePos\\n    rPos = p5.Vector.add(alkylHalidePos, rOffset);\\n    clPos = p5.Vector.add(alkylHalidePos, p5.Vector.mult(rOffset, -1));\\n  }\\n\\n  // Draw static components and text based on stage\\n  drawBenzene(benzenePos.x, benzenePos.y);\\n  drawCatalyst(catalystPos.x, catalystPos.y);\\n  drawLabels();\\n  \\n  // State machine for the reaction\\n  if (stage === 0) {\\n    // Stage 0: Drag R-Cl to the catalyst\\n    drawAlkylHalide(alkylHalidePos.x, alkylHalidePos.y);\\n    let d = dist(alkylHalidePos.x, alkylHalidePos.y, catalystPos.x, catalystPos.y);\\n    if (d < 40 && !dragging) {\\n      stage = 1;\\n      // Animate Cl moving to the catalyst\\n      clPos = catalystPos.copy().add(0, 25);\\n    }\\n  } else if (stage === 1) {\\n    // Stage 1: Drag R+ to the benzene ring\\n    drawCarbocation(alkylHalidePos.x, alkylHalidePos.y);\\n    drawCatalystComplex(catalystPos.x, catalystPos.y);\\n    let d = dist(alkylHalidePos.x, alkylHalidePos.y, benzenePos.x, benzenePos.y);\\n    if (d < 60 && !dragging) {\\n      stage = 2;\\n    }\\n  } else if (stage === 2) {\\n    // Stage 2: Reaction complete\\n    drawFinalProduct(benzenePos.x, benzenePos.y);\\n    drawCatalyst(catalystPos.x, catalystPos.y);\\n    drawHCl();\\n    fill(TEXT_COLOR);\\n    text(\\"Reaction Complete! Click to reset.\\", width / 2, height - 30);\\n  }\\n}\\n\\nfunction drawLabels() {\\n  fill(TEXT_COLOR);\\n  noStroke();\\n  textSize(16);\\n  text(\\"Benzene Ring\\", benzenePos.x, benzenePos.y + 70);\\n  \\n  if (stage < 2) {\\n    text(\\"Lewis Acid Catalyst\\", catalystPos.x, catalystPos.y + 35);\\n  } else {\\n    text(\\"Catalyst Regenerated\\", catalystPos.x, catalystPos.y + 35);\\n  }\\n  \\n  textSize(18);\\n  fill(TEXT_COLOR);\\n  let hint = \\"\\";\\n  if (stage === 0) {\\n    hint = \\"Step 1: Drag the Alkyl Halide (R-Cl) to the catalyst.\\";\\n  } else if (stage === 1) {\\n    hint = \\"Step 2: Drag the Carbocation (R+) to the benzene ring.\\";\\n  }\\n  text(hint, width / 2, 30);\\n}\\n\\nfunction drawBenzene(x, y) {\\n  stroke(TEXT_COLOR);\\n  strokeWeight(2);\\n  noFill();\\n  beginShape();\\n  for (let i = 0; i < 6; i++) {\\n    let angle = TWO_PI / 6 * i + PI / 6;\\n    vertex(x + 50 * cos(angle), y + 50 * sin(angle));\\n  }\\n  endShape(CLOSE);\\n  \\n  // Draw inner circle for aromaticity\\n  ellipse(x, y, 60, 60);\\n\\n  if (stage < 2) {\\n    // Show a hydrogen that will be replaced\\n    fill(TEXT_COLOR);\\n    noStroke();\\n    text(\\"H\\", x + 55, y);\\n  }\\n}\\n\\nfunction drawFinalProduct(x, y) {\\n    stroke(TEXT_COLOR);\\n    strokeWeight(2);\\n    noFill();\\n    beginShape();\\n    for (let i = 0; i < 6; i++) {\\n        let angle = TWO_PI / 6 * i + PI / 6;\\n        vertex(x + 50 * cos(angle), y + 50 * sin(angle));\\n    }\\n    endShape(CLOSE);\\n    ellipse(x, y, 60, 60);\\n    \\n    // Draw attached R group\\n    stroke(ALKYL_COLOR);\\n    line(x + 43, y, x + 70, y);\\n    fill(ALKYL_COLOR);\\n    noStroke();\\n    textSize(22);\\n    text(\\"R\\", x + 80, y);\\n}\\n\\n\\nfunction drawCatalyst(x, y) {\\n  fill(TEXT_COLOR);\\n  noStroke();\\n  textSize(20);\\n  text(\\"AlCl₃\\", x, y);\\n}\\n\\nfunction drawCatalystComplex(x, y) {\\n    fill(TEXT_COLOR);\\n    noStroke();\\n    textSize(20);\\n    text(\\"[AlCl₄]⁻\\", x, y);\\n}\\n\\n\\nfunction drawAlkylHalide(x, y) {\\n  stroke(TEXT_COLOR);\\n  strokeWeight(2);\\n  line(rPos.x, rPos.y, clPos.x, clPos.y);\\n\\n  // R group\\n  fill(ALKYL_COLOR);\\n  noStroke();\\n  textSize(22);\\n  text(\\"R\\", rPos.x, rPos.y);\\n\\n  // Cl group\\n  fill(TEXT_COLOR);\\n  noStroke();\\n  textSize(22);\\n  text(\\"Cl\\", clPos.x, clPos.y);\\n}\\n\\nfunction drawCarbocation(x, y) {\\n  // R group\\n  fill(ALKYL_COLOR);\\n  noStroke();\\n  textSize(22);\\n  text(\\"R\\", rPos.x, rPos.y);\\n  textSize(20);\\n  text(\\"+\\", rPos.x + 12, rPos.y - 10);\\n}\\n\\nfunction drawHCl() {\\n    fill(TEXT_COLOR);\\n    noStroke();\\n    textSize(20);\\n    text(\\"H-Cl\\", catalystPos.x, height * 0.75);\\n}\\n\\nfunction mousePressed() {\\n  if (stage < 2) {\\n    let d = dist(mouseX, mouseY, alkylHalidePos.x, alkylHalidePos.y);\\n    if (d < 30) {\\n      dragging = true;\\n    }\\n  } else {\\n      resetSketch();\\n  }\\n}\\n\\nfunction mouseReleased() {\\n  dragging = false;\\n}\\n", "explanation": "This visualization shows the key steps of Friedel-Crafts Alkylation. You will activate an alkyl halide with a Lewis acid catalyst to create a carbocation, which is then attacked by the electron-rich benzene ring.", "interaction_hint": "Drag the 'R-Cl' molecule to the catalyst, then drag the resulting 'R+' to the benzene ring to complete the reaction."}
9e4785be-b96d-486b-9e60-a7336d404b27	38501783-2e12-4cc4-abe1-31737816340a	ee980a11-c022-4142-8381-895b4b3295dd	Chemistry session	{"goal": "Invite the student to identify the necessary reagents and the role of the Lewis acid catalyst in Friedel-Crafts alkylation.", "turn": 1, "summary": "[turn 1] subgoal: Invite the student to identify the necessary reagents and the role of the Lewis acid catalyst in Friedel-Crafts alkylation.\\nlast diagnosis: first attempt"}	2026-04-29 03:18:33.438012+00	2026-04-29 03:19:49.547383+00	{"title": "Friedel-Crafts Alkylation Mechanism", "concept": "friedel_crafts_alkylation", "p5_code": "let benzene;\\nlet electrophile;\\nlet isDragging = false;\\n\\nconst BENZENE_RADIUS = 60;\\nconst R_GROUP_RADIUS = 25;\\nconst ACCENT_COLOR = \\"#C0392B\\"; // Crimson\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  benzene = createVector(width * 0.3, height / 2);\\n  electrophile = createVector(width * 0.75, height / 2);\\n  textAlign(CENTER, CENTER);\\n  textFont(\\"sans-serif\\");\\n  strokeJoin(ROUND);\\n}\\n\\nfunction draw() {\\n  background(255);\\n  updateElectrophile();\\n\\n  let d = dist(electrophile.x, electrophile.y, benzene.x, benzene.y);\\n  // Activation progress from 0 to 1 based on distance\\n  let activation = constrain(map(d, 250, BENZENE_RADIUS + R_GROUP_RADIUS + 10, 0, 1), 0, 1);\\n\\n  drawLabels(activation);\\n  drawBenzene(benzene.x, benzene.y);\\n  drawElectrophileComplex(electrophile.x, electrophile.y, activation);\\n  drawAttackArrow(activation);\\n}\\n\\nfunction updateElectrophile() {\\n  if (isDragging) {\\n    electrophile.x = constrain(mouseX, R_GROUP_RADIUS, width - R_GROUP_RADIUS);\\n    electrophile.y = constrain(mouseY, R_GROUP_RADIUS, height - R_GROUP_RADIUS);\\n  }\\n}\\n\\nfunction drawLabels(activation) {\\n  noStroke();\\n  fill(0);\\n  textSize(16);\\n  text(\\"Benzene (Nucleophile)\\", benzene.x, benzene.y + BENZENE_RADIUS + 25);\\n  text(\\"Alkyl Group (Electrophile)\\", electrophile.x, electrophile.y + R_GROUP_RADIUS + 25);\\n\\n  if (activation > 0.9) {\\n    textSize(18);\\n    fill(ACCENT_COLOR);\\n    text(\\"New C-C bond forms!\\", width / 2, height - 30);\\n  } else {\\n    textSize(14);\\n    fill(100);\\n    text(\\"Drag the red 'R' group towards the benzene ring\\", width / 2, 30);\\n  }\\n}\\n\\nfunction drawBenzene(x, y) {\\n  stroke(0);\\n  strokeWeight(3);\\n  noFill();\\n  // Hexagon\\n  beginShape();\\n  for (let i = 0; i < 6; i++) {\\n    let angle = TWO_PI / 6 * i + PI / 6;\\n    vertex(x + BENZENE_RADIUS * cos(angle), y + BENZENE_RADIUS * sin(angle));\\n  }\\n  endShape(CLOSE);\\n  // Pi circle\\n  strokeWeight(2);\\n  ellipse(x, y, BENZENE_RADIUS * 1.1, BENZENE_RADIUS * 1.1);\\n  fill(0);\\n  noStroke();\\n  textSize(14);\\n  text(\\"e⁻ rich\\", x, y);\\n}\\n\\nfunction drawElectrophileComplex(x, y, activation) {\\n  // --- Leaving Group [Cl-AlCl3] ---\\n  let leavingGroupX = x + R_GROUP_RADIUS + 15 + 30 * (1 - activation * 0.8);\\n  \\n  noStroke();\\n  fill(100, 255 * (1-activation)); // Fades out\\n  textSize(16);\\n  text(\\"[Cl—AlCl₃]\\", leavingGroupX + 40, y);\\n\\n  // --- Bond between R and Cl ---\\n  // This bond breaks as activation increases\\n  if (activation < 0.99) {\\n    stroke(0);\\n    strokeWeight(2);\\n    line(x + R_GROUP_RADIUS, y, leavingGroupX, y);\\n  }\\n\\n  // --- R-group (the draggable part) ---\\n  stroke(0);\\n  strokeWeight(3);\\n  fill(ACCENT_COLOR);\\n  ellipse(x, y, R_GROUP_RADIUS * 2, R_GROUP_RADIUS * 2);\\n  fill(255);\\n  noStroke();\\n  textSize(28);\\n  text(\\"R\\", x, y);\\n\\n  // --- Carbocation '+' sign ---\\n  // Fades in as the leaving group moves away\\n  noStroke();\\n  fill(255, 255, 255, 255 * activation);\\n  textSize(40);\\n  text(\\"+\\", x + 1, y + 2);\\n}\\n\\nfunction drawAttackArrow(activation) {\\n    if (activation > 0.05) {\\n        let arrowColor = color(30, 130, 76, 255 * activation); // Green\\n        stroke(arrowColor);\\n        fill(arrowColor);\\n        strokeWeight(2.5);\\n        drawingContext.setLineDash([6, 6]);\\n\\n        let angle = atan2(electrophile.y - benzene.y, electrophile.x - benzene.x);\\n        let startX = benzene.x + (BENZENE_RADIUS * 0.6) * cos(angle);\\n        let startY = benzene.y + (BENZENE_RADIUS * 0.6) * sin(angle);\\n        let endX = electrophile.x - R_GROUP_RADIUS * cos(angle);\\n        let endY = electrophile.y - R_GROUP_RADIUS * sin(angle);\\n\\n        line(startX, startY, endX, endY);\\n        \\n        push();\\n        translate(endX, endY);\\n        rotate(angle);\\n        triangle(0, 0, -10, -5, -10, 5);\\n        pop();\\n        \\n        drawingContext.setLineDash([]); // Reset line dash\\n\\n        noStroke();\\n        textSize(14);\\n        let midX = (startX + endX) / 2;\\n        let midY = (startY + endY) / 2 - 15;\\n        text(\\"Nucleophilic Attack\\", midX, midY);\\n  }\\n}\\n\\nfunction mousePressed() {\\n  let d = dist(mouseX, mouseY, electrophile.x, electrophile.y);\\n  if (d < R_GROUP_RADIUS) {\\n    isDragging = true;\\n  }\\n}\\n\\nfunction mouseReleased() {\\n  isDragging = false;\\n}", "explanation": "This shows the key step in Friedel-Crafts Alkylation. A Lewis acid catalyst helps form an electron-poor carbocation (R+), which is then \\"attacked\\" by the electron-rich benzene ring to form a new bond.", "interaction_hint": "Drag the red \\"R\\" group (the electrophile) towards the benzene ring (the nucleophile) to see the reaction happen."}
d14af1ce-d480-49f0-9a59-8a2e45e61aab	38501783-2e12-4cc4-abe1-31737816340a	026a9e35-dc20-4b28-8775-f10e329670df	Biology session	{"goal": "Determine the student's prior knowledge regarding the location and purpose of the Krebs cycle within cellular respiration.", "turn": 1, "summary": "[turn 1] subgoal: Determine the student's prior knowledge regarding the location and purpose of the Krebs cycle within cellular respiration.\\nlast diagnosis: first attempt"}	2026-04-29 05:37:56.691751+00	2026-04-29 05:44:46.544635+00	{"title": "The Krebs Cycle: An Interactive View", "concept": "krebs_cycle", "p5_code": "let progressSlider;\\nlet cycleRadius;\\nlet centerX, centerY;\\n\\n// Colors for molecules\\nlet acetylCoAColor, nadhColor, fadh2Color, atpColor, co2Color, mainMoleculeColor;\\n\\n// Data for cycle steps and outputs\\nlet cycleSteps;\\nlet outputs;\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  centerX = width / 2;\\n  centerY = 200;\\n  cycleRadius = 130;\\n\\n  progressSlider = createSlider(0, TWO_PI, 0, 0.01);\\n  progressSlider.position(20, height - 50);\\n  progressSlider.style(\\"width\\", \\"520px\\");\\n\\n  // Initialize colors\\n  acetylCoAColor = color(\\"#E67E22\\"); // Orange\\n  nadhColor = color(\\"#3498DB\\");      // Blue\\n  fadh2Color = color(\\"#9B59B6\\");     // Purple\\n  atpColor = color(\\"#F1C40F\\");       // Yellow\\n  co2Color = color(\\"#95A5A6\\");       // Gray\\n  mainMoleculeColor = color(\\"#27AE60\\"); // Green\\n\\n  // Define the major intermediates in the cycle\\n  cycleSteps = [\\n    { label: \\"Oxaloacetate (4C)\\", angle: 0 },\\n    { label: \\"Citrate (6C)\\", angle: 0.8 },\\n    { label: \\"α-Ketoglutarate (5C)\\", angle: 2.1 },\\n    { label: \\"Succinyl-CoA (4C)\\", angle: 3.14 },\\n    { label: \\"Malate (4C)\\", angle: 4.8 }\\n  ];\\n  \\n  // Define the outputs released at different points in the cycle\\n  outputs = [\\n    { label: \\"NADH\\", color: nadhColor, angle: 2.0, dir: createVector(1, -1) },\\n    { label: \\"CO2\\", color: co2Color, angle: 2.2, dir: createVector(-1, -1) },\\n    { label: \\"NADH\\", color: nadhColor, angle: 3.0, dir: createVector(1, -1) },\\n    { label: \\"CO2\\", color: co2Color, angle: 3.2, dir: createVector(-1, -1) },\\n    { label: \\"ATP\\", color: atpColor, angle: 3.8, dir: createVector(-1, 1) },\\n    { label: \\"FADH2\\", color: fadh2Color, angle: 4.5, dir: createVector(1, 1) },\\n    { label: \\"NADH\\", color: nadhColor, angle: 5.2, dir: createVector(1, 1) }\\n  ];\\n}\\n\\nfunction draw() {\\n  background(255);\\n  let angle = progressSlider.value();\\n\\n  drawLegend();\\n  drawCyclePath();\\n  drawInput(angle);\\n  drawOutputs(angle);\\n  drawMainMolecule(angle);\\n  \\n  // UI Text\\n  fill(0);\\n  noStroke();\\n  textAlign(CENTER);\\n  textSize(18);\\n  text(\\"The Krebs Cycle\\", centerX, 30);\\n  textSize(12);\\n  text(\\"Drag the slider to control the cycle's progress.\\", centerX, height - 20);\\n}\\n\\nfunction drawCyclePath() {\\n  // Draw the main circle path\\n  stroke(200);\\n  noFill();\\n  strokeWeight(3);\\n  ellipse(centerX, centerY, cycleRadius * 2, cycleRadius * 2);\\n\\n  // Draw the static labels for the intermediate molecules\\n  for (let step of cycleSteps) {\\n    let x = centerX + cycleRadius * cos(step.angle);\\n    let y = centerY + cycleRadius * sin(step.angle);\\n    fill(100);\\n    noStroke();\\n    textAlign(CENTER, CENTER);\\n    text(step.label, x, y + (step.angle > PI ? 30 : -30));\\n    fill(150);\\n    ellipse(x, y, 10, 10);\\n  }\\n}\\n\\nfunction drawInput(angle) {\\n  // Show Acetyl-CoA entering the cycle at the beginning\\n  if (angle < 0.8) {\\n    let startX = centerX - cycleRadius - 60;\\n    let startY = centerY - 60;\\n    let endX = centerX + cycleRadius * cos(0);\\n    let endY = centerY + cycleRadius * sin(0);\\n    \\n    let interp = map(angle, 0, 0.8, 0, 1, true);\\n    let inputX = lerp(startX, endX, interp);\\n    let inputY = lerp(startY, endY, interp);\\n    let alpha = lerp(255, 0, interp);\\n\\n    fill(acetylCoAColor, alpha);\\n    stroke(0, alpha);\\n    ellipse(inputX, inputY, 25, 25);\\n    \\n    noStroke();\\n    fill(0, alpha);\\n    textAlign(CENTER);\\n    text(\\"Acetyl-CoA\\", startX, startY - 20);\\n  }\\n}\\n\\nfunction drawMainMolecule(angle) {\\n  // Draw the primary molecule moving along the cycle path\\n  let x = centerX + cycleRadius * cos(angle);\\n  let y = centerY + cycleRadius * sin(angle);\\n  fill(mainMoleculeColor);\\n  stroke(0);\\n  strokeWeight(2);\\n  ellipse(x, y, 30, 30);\\n}\\n\\nfunction drawOutputs(currentAngle) {\\n  // Check each defined output to see if it should be \\"released\\"\\n  for (let output of outputs) {\\n    let releaseStartAngle = output.angle;\\n    let releaseEndAngle = output.angle + 0.5; // Animation duration\\n    \\n    if (currentAngle > releaseStartAngle && currentAngle < releaseEndAngle) {\\n      let progress = map(currentAngle, releaseStartAngle, releaseEndAngle, 0, 1);\\n      \\n      let startX = centerX + cycleRadius * cos(releaseStartAngle);\\n      let startY = centerY + cycleRadius * sin(releaseStartAngle);\\n      \\n      let particleX = startX + output.dir.x * 60 * progress;\\n      let particleY = startY + output.dir.y * 60 * progress;\\n      let alpha = lerp(255, 0, progress);\\n      \\n      fill(output.color, alpha);\\n      stroke(0, alpha);\\n      ellipse(particleX, particleY, 20, 20);\\n      \\n      noStroke();\\n      fill(0, alpha);\\n      textAlign(CENTER, CENTER);\\n      text(output.label, particleX, particleY);\\n    }\\n  }\\n}\\n\\nfunction drawLegend() {\\n  let legendX = 20;\\n  let legendY = 20;\\n  let spacing = 22;\\n  \\n  textAlign(LEFT, CENTER);\\n  noStroke();\\n  textSize(12);\\n\\n  fill(acetylCoAColor);\\n  ellipse(legendX, legendY, 15, 15);\\n  fill(0);\\n  text(\\"Input: Acetyl-CoA\\", legendX + 15, legendY);\\n\\n  fill(atpColor);\\n  ellipse(legendX, legendY + spacing, 15, 15);\\n  fill(0);\\n  text(\\"Output: ATP (Energy)\\", legendX + 15, legendY + spacing);\\n\\n  fill(nadhColor);\\n  ellipse(legendX, legendY + spacing * 2, 15, 15);\\n  fill(0);\\n  text(\\"Output: NADH\\", legendX + 15, legendY + spacing * 2);\\n\\n  fill(fadh2Color);\\n  ellipse(legendX, legendY + spacing * 3, 15, 15);\\n  fill(0);\\n  text(\\"Output: FADH2\\", legendX + 15, legendY + spacing * 3);\\n  \\n  fill(co2Color);\\n  ellipse(legendX, legendY + spacing * 4, 15, 15);\\n  fill(0);\\n  text(\\"Output: CO2 (Waste)\\", legendX + 15, legendY + spacing * 4);\\n}", "explanation": "This is a simplified view of the Krebs Cycle, a key energy-producing process in cells. See how Acetyl-CoA enters the cycle, releasing energy carriers (NADH, FADH2, ATP) and CO2 as it progresses.", "interaction_hint": "Drag the slider to move the reaction forward and see what is produced at each stage."}
020e40b3-c5ec-4094-9d1f-6d62024026ac	38501783-2e12-4cc4-abe1-31737816340a	026a9e35-dc20-4b28-8775-f10e329670df	Biology session	{"goal": "Establish the context of the Krebs cycle within cellular respiration by asking where it takes place and what goes into it.", "turn": 1, "summary": "[turn 1] subgoal: Establish the context of the Krebs cycle within cellular respiration by asking where it takes place and what goes into it.\\nlast diagnosis: first attempt — no work to verify yet"}	2026-04-29 05:22:00.289351+00	2026-04-29 07:18:26.280636+00	{"title": "The Krebs Cycle Engine", "concept": "krebs_cycle", "p5_code": "let angle = -Math.PI / 2;\\nlet targetAngle = -Math.PI / 2;\\nlet isAnimating = false;\\nlet particles = [];\\nlet cycleSteps = [];\\nlet centerX, centerY, radius;\\n\\nconst ACCENT_COLOR = '#16A085'; // Teal\\nconst MOVING_DOT_COLOR = '#C0392B'; // Crimson\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  centerX = width / 2;\\n  centerY = height / 2 + 20;\\n  radius = 120;\\n  \\n  // Define the key steps and their outputs\\n  cycleSteps = [\\n    { name: \\"Citrate\\", angle: -PI / 2, carbons: 6 },\\n    { name: \\"Isocitrate\\", angle: -PI / 4, carbons: 6, output: \\"NADH\\", outputType: \\"energy\\" },\\n    { name: \\"α-Ketoglutarate\\", angle: 0, carbons: 5, output: \\"CO2\\", outputType: \\"waste\\" },\\n    { name: \\"Succinyl-CoA\\", angle: PI / 4, carbons: 4, output: \\"NADH\\", outputType: \\"energy\\" },\\n    { name: \\"Succinate\\", angle: PI / 2, carbons: 4, output: \\"ATP\\", outputType: \\"energy\\" },\\n    { name: \\"Fumarate\\", angle: 3 * PI / 4, carbons: 4, output: \\"FADH2\\", outputType: \\"energy\\" },\\n    { name: \\"Malate\\", angle: PI, carbons: 4 },\\n    { name: \\"Oxaloacetate\\", angle: 5 * PI / 4, carbons: 4, output: \\"NADH\\", outputType: \\"energy\\" }\\n  ];\\n\\n  // Keep track of which outputs have been spawned for the current cycle turn\\n  for (let step of cycleSteps) {\\n    step.spawned = false;\\n  }\\n}\\n\\nfunction draw() {\\n  background(245);\\n  \\n  // Title and labels\\n  noStroke();\\n  fill(0);\\n  textAlign(CENTER, CENTER);\\n  textSize(20);\\n  text(\\"The Krebs Cycle Engine\\", width / 2, 30);\\n  \\n  // Draw the cycle path\\n  stroke(200);\\n  strokeWeight(10);\\n  noFill();\\n  ellipse(centerX, centerY, radius * 2, radius * 2);\\n\\n  // Draw the steps on the cycle\\n  for (let step of cycleSteps) {\\n    let x = centerX + radius * cos(step.angle);\\n    let y = centerY + radius * sin(step.angle);\\n    \\n    fill(255);\\n    stroke(100);\\n    strokeWeight(2);\\n    ellipse(x, y, 15, 15);\\n    \\n    noStroke();\\n    fill(80);\\n    textAlign(LEFT, CENTER);\\n    let labelX = centerX + (radius + 20) * cos(step.angle);\\n    let labelY = centerY + (radius + 20) * sin(step.angle);\\n    if (step.angle > -PI/2 && step.angle < PI/2) {\\n        textAlign(LEFT, CENTER);\\n    } else {\\n        textAlign(RIGHT, CENTER);\\n    }\\n    text(step.name, labelX, labelY);\\n  }\\n\\n  // Animate the cycle if it's running\\n  if (isAnimating) {\\n    angle += 0.02;\\n    if (angle >= targetAngle) {\\n      angle = -PI/2;\\n      isAnimating = false;\\n    }\\n    // Check for spawning outputs\\n    for (let step of cycleSteps) {\\n        if (step.output && !step.spawned && angle >= step.angle) {\\n            createParticles(step);\\n            step.spawned = true;\\n        }\\n    }\\n  }\\n\\n  // Update and display particles\\n  for (let i = particles.length - 1; i >= 0; i--) {\\n    particles[i].update();\\n    particles[i].display();\\n    if (particles[i].isOffscreen()) {\\n      particles.splice(i, 1);\\n    }\\n  }\\n\\n  // Draw the moving dot\\n  let dotX = centerX + radius * cos(angle);\\n  let dotY = centerY + radius * sin(angle);\\n  fill(MOVING_DOT_COLOR);\\n  noStroke();\\n  ellipse(dotX, dotY, 20, 20);\\n\\n  // Draw the button\\n  let buttonX = width / 2 - 100;\\n  let buttonY = height - 60;\\n  let buttonW = 200;\\n  let buttonH = 40;\\n  \\n  if (mouseX > buttonX && mouseX < buttonX + buttonW && mouseY > buttonY && mouseY < buttonY + buttonH) {\\n    fill(31, 139, 114); // Darker teal on hover\\n  } else {\\n    fill(ACCENT_COLOR);\\n  }\\n  rect(buttonX, buttonY, buttonW, buttonH, 5);\\n  \\n  fill(255);\\n  noStroke();\\n  textSize(16);\\n  textAlign(CENTER, CENTER);\\n  text(\\"Inject Acetyl-CoA\\", width / 2, height - 40);\\n}\\n\\nfunction mousePressed() {\\n  let buttonX = width / 2 - 100;\\n  let buttonY = height - 60;\\n  let buttonW = 200;\\n  let buttonH = 40;\\n\\n  if (!isAnimating && mouseX > buttonX && mouseX < buttonX + buttonW && mouseY > buttonY && mouseY < buttonY + buttonH) {\\n    isAnimating = true;\\n    angle = -PI / 2;\\n    targetAngle = -PI / 2 + TWO_PI;\\n    particles = [];\\n    for (let step of cycleSteps) {\\n        step.spawned = false;\\n    }\\n  }\\n}\\n\\nfunction createParticles(step) {\\n    let startX = centerX + radius * cos(step.angle);\\n    let startY = centerY + radius * sin(step.angle);\\n    \\n    let particleColor;\\n    if (step.output === 'NADH') particleColor = color(52, 152, 219, 200); // Blue\\n    else if (step.output === 'FADH2') particleColor = color(46, 204, 113, 200); // Green\\n    else if (step.output === 'ATP') particleColor = color(241, 196, 15, 200); // Yellow\\n    else if (step.output === 'CO2') particleColor = color(149, 165, 166, 200); // Gray\\n\\n    for (let i = 0; i < 5; i++) {\\n        particles.push(new Particle(startX, startY, particleColor, step.output));\\n    }\\n}\\n\\nclass Particle {\\n  constructor(x, y, col, label) {\\n    this.pos = createVector(x, y);\\n    this.vel = p5.Vector.random2D().mult(random(1, 3));\\n    this.lifespan = 255;\\n    this.col = col;\\n    this.label = label;\\n  }\\n\\n  update() {\\n    this.pos.add(this.vel);\\n    this.lifespan -= 2;\\n  }\\n\\n  display() {\\n    noStroke();\\n    let c = this.col;\\n    fill(red(c), green(c), blue(c), this.lifespan);\\n    ellipse(this.pos.x, this.pos.y, 10, 10);\\n    \\n    // Display label on the first particle\\n    if (this.lifespan > 250) {\\n        textSize(14);\\n        textAlign(CENTER, CENTER);\\n        text(this.label, this.pos.x, this.pos.y - 15);\\n    }\\n  }\\n\\n  isOffscreen() {\\n    return (this.lifespan < 0 || this.pos.x < 0 || this.pos.x > width || this.pos.y < 0 || this.pos.y > height);\\n  }\\n}\\n", "explanation": "This visualization shows the Krebs Cycle as an engine. Adding Acetyl-CoA (the fuel) turns the cycle, producing energy-carrying molecules (NADH, FADH2, ATP) and a waste product (CO2).", "interaction_hint": "Click the \\"Inject Acetyl-CoA\\" button to run one turn of the cycle and see the outputs."}
fc6c44ed-b2bf-427b-974a-86aa8f966833	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Guide the student to connect the Pythagorean theorem to the distance between a general point (x, y) and the center (h, k).", "turn": 2, "summary": "[turn 2] subgoal: Guide the student to connect the Pythagorean theorem to the distance between a general point (x, y) and the center (h, k).\\nlast diagnosis: first attempt"}	2026-05-18 08:15:46.539078+00	2026-05-18 08:30:36.104457+00	{"title": "The Equation of a Circle", "concept": "circle_equation", "p5_code": "\\nlet center;\\nlet pointP;\\n\\nlet isDraggingCenter = false;\\nlet isDraggingPoint = false;\\nconst handleRadius = 10;\\n\\n// Colors\\nconst bgColor = 255;\\nconst axisColor = 150;\\nconst mainColor = \\"#000000\\";\\nconst accentColor = \\"#C0392B\\"; // Crimson\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  \\n  center = createVector(width / 2, height / 2);\\n  pointP = createVector(width / 2 + 100, height / 2);\\n  \\n  textSize(16);\\n  textAlign(CENTER, CENTER);\\n  noStroke();\\n}\\n\\nfunction draw() {\\n  background(bgColor);\\n  \\n  // Define an origin at the center for a typical Cartesian plane\\n  const originX = width / 2;\\n  const originY = height / 2;\\n  \\n  // Draw axes\\n  stroke(axisColor);\\n  strokeWeight(1);\\n  line(0, originY, width, originY); // x-axis\\n  line(originX, 0, originX, height); // y-axis\\n  \\n  // Convert p5 vector positions to math coordinates (h, k) and (x, y)\\n  // p5's y-axis is inverted from a standard Cartesian plane.\\n  let h = center.x - originX;\\n  let k = originY - center.y;\\n  \\n  let x = pointP.x - originX;\\n  let y = originY - pointP.y;\\n  \\n  let r = dist(center.x, center.y, pointP.x, pointP.y);\\n  let dx_canvas = pointP.x - center.x;\\n  let dy_canvas = pointP.y - center.y;\\n  \\n  // --- Drawing ---\\n  \\n  // Draw the right triangle representing (x-h) and (y-k)\\n  stroke(accentColor);\\n  strokeWeight(2);\\n  drawingContext.setLineDash([5, 5]);\\n  line(center.x, center.y, pointP.x, center.y); // (x-h) side\\n  line(pointP.x, center.y, pointP.x, pointP.y); // (y-k) side\\n  drawingContext.setLineDash([]);\\n  \\n  // Draw the radius (hypotenuse)\\n  stroke(mainColor);\\n  strokeWeight(2.5);\\n  line(center.x, center.y, pointP.x, pointP.y);\\n  \\n  // Draw the circle itself\\n  noFill();\\n  stroke(mainColor);\\n  strokeWeight(2);\\n  if (r > 0.1) {\\n    circle(center.x, center.y, r * 2);\\n  }\\n  \\n  // Draw draggable handles\\n  noStroke();\\n  fill(mainColor);\\n  circle(center.x, center.y, handleRadius);\\n  fill(accentColor);\\n  circle(pointP.x, pointP.y, handleRadius);\\n  \\n  // --- Text and Labels ---\\n  \\n  // Display the circle equation\\n  fill(mainColor);\\n  noStroke();\\n  \\n  // Pretty print the equation with correct signs\\n  let xPart = abs(h) < 0.1 ? \\"x²\\" : `(x ${h > 0 ? \\"-\\" : \\"+\\"} ${abs(h).toFixed(0)})²`;\\n  let yPart = abs(k) < 0.1 ? \\"y²\\" : `(y ${k > 0 ? \\"-\\" : \\"+\\"} ${abs(k).toFixed(0)})²`;\\n  let rPart = `${r.toFixed(0)}²`;\\n  \\n  let equation = `${xPart} + ${yPart} = ${rPart}`;\\n  \\n  textAlign(CENTER, TOP);\\n  textSize(20);\\n  text(equation, width / 2, 10);\\n\\n  // Label the triangle sides\\n  fill(accentColor);\\n  textSize(14);\\n  textAlign(CENTER, CENTER);\\n  text(`|x - h|`, center.x + dx_canvas / 2, center.y - 15);\\n  textAlign(LEFT, CENTER);\\n  text(`|y - k|`, pointP.x + 10, center.y + dy_canvas / 2);\\n  \\n  // Label the radius\\n  push();\\n  translate((center.x + pointP.x) / 2, (center.y + pointP.y) / 2);\\n  rotate(atan2(dy_canvas, dx_canvas));\\n  fill(mainColor);\\n  textAlign(CENTER, BOTTOM);\\n  text(`r`, 0, -5);\\n  pop();\\n  \\n  // Label the points\\n  fill(mainColor);\\n  textAlign(CENTER, BOTTOM);\\n  text(`(h, k) = (${h.toFixed(0)}, ${k.toFixed(0)})`, center.x, center.y - 15);\\n  textAlign(CENTER, TOP);\\n  text(`(x, y) = (${x.toFixed(0)}, ${y.toFixed(0)})`, pointP.x, pointP.y + 15);\\n}\\n\\nfunction mousePressed() {\\n  if (dist(mouseX, mouseY, center.x, center.y) < handleRadius * 1.5) {\\n    isDraggingCenter = true;\\n  } else if (dist(mouseX, mouseY, pointP.x, pointP.y) < handleRadius * 1.5) {\\n    isDraggingPoint = true;\\n  }\\n}\\n\\nfunction mouseDragged() {\\n  if (isDraggingCenter) {\\n    // Move the whole circle formation as a rigid body\\n    let dx = mouseX - pmouseX;\\n    let dy = mouseY - pmouseY;\\n    center.x += dx;\\n    center.y += dy;\\n    pointP.x += dx;\\n    pointP.y += dy;\\n  } else if (isDraggingPoint) {\\n    // Move just the outer point, which changes the radius\\n    pointP.x = mouseX;\\n    pointP.y = mouseY;\\n  }\\n}\\n\\nfunction mouseReleased() {\\n  isDraggingCenter = false;\\n  isDraggingPoint = false;\\n}\\n", "explanation": "This sketch shows that a circle is the set of all points (x, y) at a fixed distance, the radius (r), from a center point (h, k). The relationship between these points is described by the Pythagorean theorem, which gives the equation of the circle.", "interaction_hint": "Drag the black dot to move the circle's center (h, k). Drag the red dot to change the point (x, y) on the circumference, which also changes the radius (r)."}
e072d122-8a64-47fc-958c-761ac3c0c65d	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": null, "turn": 0, "summary": ""}	2026-05-18 08:19:32.97179+00	2026-05-18 08:20:20.864046+00	{"title": "The Ellipse: Geometric Definition", "concept": "ellipse", "p5_code": "let sliderA;\\nlet foci1, foci2;\\nlet c;\\nlet accentColor;\\nlet labelFont;\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  accentColor = color(\\"#C0392B\\");\\n  c = 80;\\n  foci1 = createVector(-c, 0);\\n  foci2 = createVector(c, 0);\\n\\n  sliderA = createSlider(c + 5, 250, 150);\\n  sliderA.position(20, 20);\\n  sliderA.style(\\"width\\", \\"150px\\");\\n  \\n  labelFont = \\"sans-serif\\";\\n  textFont(labelFont);\\n}\\n\\nfunction draw() {\\n  background(255);\\n  \\n  let a = sliderA.value();\\n  // b^2 = a^2 - c^2. Ensure a > c to avoid taking the square root of a negative number.\\n  let b = sqrt(max(0, a * a - c * c));\\n\\n  // --- Main visualization (centered) ---\\n  translate(width / 2, height / 2);\\n\\n  // Draw axes\\n  stroke(220);\\n  strokeWeight(1);\\n  line(-width / 2 + 20, 0, width / 2 - 20, 0);\\n  line(0, -height / 2 + 20, 0, height / 2 - 20);\\n\\n  // Draw the ellipse path\\n  noFill();\\n  stroke(0);\\n  strokeWeight(2);\\n  ellipse(0, 0, 2 * a, 2 * b);\\n\\n  // Draw foci\\n  fill(0);\\n  noStroke();\\n  circle(foci1.x, foci1.y, 8);\\n  circle(foci2.x, foci2.y, 8);\\n  textAlign(CENTER, CENTER);\\n  text(\\"F1\\", foci1.x - 15, foci1.y);\\n  text(\\"F2\\", foci2.x + 15, foci2.y);\\n\\n  // Define the interactive point P on the ellipse\\n  let mx = mouseX - width / 2;\\n  mx = constrain(mx, -a + 1, a - 1); // Constrain to prevent issues at the edge\\n  let y_val = -b * sqrt(1 - (mx * mx) / (a * a)); \\n  let p = createVector(mx, y_val);\\n\\n  // Draw lines from P to the foci\\n  stroke(accentColor);\\n  strokeWeight(1.5);\\n  line(p.x, p.y, foci1.x, foci1.y);\\n  line(p.x, p.y, foci2.x, foci2.y);\\n\\n  // Draw point P\\n  fill(accentColor);\\n  noStroke();\\n  circle(p.x, p.y, 10);\\n  text(\\"P\\", p.x, p.y - 15);\\n\\n  // --- UI and Text (in screen space) ---\\n  resetMatrix(); // Reset transformations for UI text\\n  \\n  // Calculate distances for display\\n  let d1 = dist(p.x, p.y, foci1.x, foci1.y);\\n  let d2 = dist(p.x, p.y, foci2.x, foci2.y);\\n  let sumD = d1 + d2;\\n  \\n  // Explanatory text\\n  noStroke();\\n  fill(0);\\n  textAlign(LEFT, TOP);\\n  textSize(14);\\n  text(\\"Adjust major radius 'a'\\", 25, 45);\\n  \\n  fill(accentColor);\\n  text(\\"dist(P, F1) = \\" + d1.toFixed(1), 25, 80);\\n  text(\\"dist(P, F2) = \\" + d2.toFixed(1), 25, 100);\\n  \\n  fill(0);\\n  stroke(0);\\n  strokeWeight(0.5);\\n  line(25, 122, 220, 122);\\n  noStroke();\\n  text(\\"Sum = \\" + sumD.toFixed(1), 25, 125);\\n  \\n  fill(0, 102, 153);\\n  text(\\"Constant (2a) = \\" + (2*a).toFixed(1), 25, 145);\\n  \\n  // Display Equation\\n  textAlign(CENTER, CENTER);\\n  textSize(18);\\n  fill(0);\\n  let equation = \\"x²/\\" + a.toFixed(0) + \\"² + y²/\\" + b.toFixed(0) + \\"² = 1\\";\\n  text(equation, width / 2, height - 30);\\n}", "explanation": "This sketch demonstrates the geometric definition of an ellipse: the set of all points (P) where the sum of the distances to two fixed points (the foci, F1 and F2) is a constant. As you move the point P, notice that the individual distances change, but their sum remains the same.", "interaction_hint": "Move your mouse left and right to slide the red dot P along the ellipse. Use the slider to change the size and shape of the ellipse."}
451b6de1-17c2-42e3-99c0-55a45c712091	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Assess the student's familiarity with the circle equation to provide a foundation for understanding the ellipse equation.", "turn": 1, "summary": "[turn 1] subgoal: Assess the student's familiarity with the circle equation to provide a foundation for understanding the ellipse equation.\\nlast diagnosis: first attempt"}	2026-05-18 08:24:06.061428+00	2026-05-18 08:25:18.426279+00	{"title": "What is an Ellipse?", "concept": "ellipse", "p5_code": "let f1, f2; // Foci vectors\\nlet draggingF1 = false;\\nlet draggingF2 = false;\\n\\n// The constant sum of distances from any point on the ellipse to the two foci.\\nconst CONSTANT_SUM = 350;\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  f1 = createVector(width / 2 - 80, height / 2);\\n  f2 = createVector(width / 2 + 80, height / 2);\\n}\\n\\nfunction draw() {\\n  background(255);\\n\\n  // Handle dragging foci and enforce the maximum distance constraint.\\n  // The distance between foci can never be greater than the constant sum.\\n  if (draggingF1) {\\n    let new_f1 = createVector(mouseX, mouseY);\\n    let v_f2_f1 = p5.Vector.sub(new_f1, f2);\\n    if (v_f2_f1.mag() < CONSTANT_SUM) {\\n      f1 = new_f1;\\n    } else {\\n      v_f2_f1.setMag(CONSTANT_SUM - 1);\\n      f1 = p5.Vector.add(f2, v_f2_f1);\\n    }\\n  }\\n  if (draggingF2) {\\n    let new_f2 = createVector(mouseX, mouseY);\\n    let v_f1_f2 = p5.Vector.sub(new_f2, f1);\\n    if (v_f1_f2.mag() < CONSTANT_SUM) {\\n      f2 = new_f2;\\n    } else {\\n      v_f1_f2.setMag(CONSTANT_SUM - 1);\\n      f2 = p5.Vector.add(f1, v_f1_f2);\\n    }\\n  }\\n\\n  // Calculate ellipse properties based on foci positions\\n  let fociDist = dist(f1.x, f1.y, f2.x, f2.y);\\n  let center = p5.Vector.div(p5.Vector.add(f1, f2), 2);\\n  \\n  // Semi-major axis (a), and semi-minor axis (b)\\n  let a = CONSTANT_SUM / 2;\\n  let c = fociDist / 2;    // Distance from center to a focus\\n  let b = sqrt(a * a - c * c);\\n\\n  // Draw the full ellipse\\n  push();\\n  translate(center.x, center.y);\\n  let rotation = p5.Vector.sub(f2, f1).heading();\\n  rotate(rotation);\\n  noFill();\\n  stroke(0, 0, 0, 50);\\n  strokeWeight(2);\\n  beginShape();\\n  for (let angle = 0; angle < TWO_PI; angle += 0.01) {\\n    let x = a * cos(angle);\\n    let y = b * sin(angle);\\n    vertex(x, y);\\n  }\\n  endShape(CLOSE);\\n  pop();\\n\\n  // Determine point P on the ellipse based on the mouse's angle relative to the center\\n  let mouseVec = createVector(mouseX, mouseY);\\n  let centerToMouse = p5.Vector.sub(mouseVec, center);\\n  centerToMouse.rotate(-rotation);\\n  let theta = atan2(centerToMouse.y, centerToMouse.x);\\n  \\n  let p_relative = createVector(a * cos(theta), b * sin(theta));\\n  p_relative.rotate(rotation);\\n  let p = p5.Vector.add(p_relative, center);\\n\\n  // Draw lines from foci to P\\n  strokeWeight(1.5);\\n  stroke(150, 150, 150);\\n  line(f1.x, f1.y, p.x, p.y);\\n  line(f2.x, f2.y, p.x, p.y);\\n\\n  // Draw Foci (F1, F2) and Point (P)\\n  noStroke();\\n  fill(\\"#16A085\\"); // Teal\\n  ellipse(f1.x, f1.y, 12, 12);\\n  ellipse(f2.x, f2.y, 12, 12);\\n  fill(\\"#C0392B\\"); // Crimson\\n  ellipse(p.x, p.y, 12, 12);\\n\\n  // Display text labels and values\\n  let d1 = dist(p.x, p.y, f1.x, f1.y);\\n  let d2 = dist(p.x, p.y, f2.x, f2.y);\\n  let sum = d1 + d2;\\n\\n  fill(0);\\n  textSize(16);\\n  noStroke();\\n  text(\\"F1\\", f1.x + 12, f1.y);\\n  text(\\"F2\\", f2.x + 12, f2.y);\\n  text(\\"P\\", p.x + 12, p.y);\\n  \\n  let y_pos = height - 50;\\n  textAlign(LEFT, TOP);\\n  text(\\"dist(P, F1) = \\" + d1.toFixed(1), 15, y_pos);\\n  text(\\"dist(P, F2) = \\" + d2.toFixed(1), 15, y_pos + 20);\\n  \\n  textSize(18);\\n  textAlign(RIGHT, TOP);\\n  text(\\"Sum of Distances = \\" + sum.toFixed(1), width - 15, y_pos);\\n  \\n  textAlign(CENTER, TOP);\\n  fill(100);\\n  textSize(12);\\n  text(\\"Drag the teal foci (F1, F2) to change the ellipse's shape.\\\\nMove the mouse to slide the red point P along the curve.\\", width / 2, 10);\\n}\\n\\nfunction mousePressed() {\\n  if (dist(mouseX, mouseY, f1.x, f1.y) < 15) {\\n    draggingF1 = true;\\n  }\\n  if (dist(mouseX, mouseY, f2.x, f2.y) < 15) {\\n    draggingF2 = true;\\n  }\\n}\\n\\nfunction mouseReleased() {\\n  draggingF1 = false;\\n  draggingF2 = false;\\n}\\n", "explanation": "An ellipse is defined by two points called foci (F1, F2). For any point (P) on the ellipse, the sum of the distances from P to F1 and from P to F2 is always a constant number.", "interaction_hint": "Drag the teal foci (F1, F2) to change the ellipse's shape. Move the mouse to slide the red point P along the curve."}
bbb7d83f-2678-4405-948c-d0d77cb4e36d	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Prompt the student to test small integer values to find a root of the cubic equation, thereby introducing the Rational Root Theorem concept implicitly.", "turn": 1, "summary": "[turn 1] subgoal: Prompt the student to test small integer values to find a root of the cubic equation, thereby introducing the Rational Root Theorem concept implicitly.\\nlast diagnosis: first attempt"}	2026-05-18 08:53:13.949143+00	2026-05-18 08:59:50.692912+00	{"title": "Coordinates on a Plane", "concept": "cartesian_coordinates", "p5_code": "let centerX;\\nlet centerY;\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  centerX = width / 2;\\n  centerY = height / 2;\\n  textFont(\\"sans-serif\\");\\n}\\n\\nfunction draw() {\\n  background(250);\\n  drawGrid();\\n  drawAxes();\\n\\n  // Convert mouse position to Cartesian coordinates\\n  let cartesianX = mouseX - centerX;\\n  let cartesianY = centerY - mouseY; // p5's y-axis is inverted\\n\\n  // Draw the interactive point\\n  fill(\\"#C0392B\\"); // Crimson\\n  noStroke();\\n  ellipse(mouseX, mouseY, 10, 10);\\n\\n  // Display the coordinates as text\\n  fill(0);\\n  textSize(14);\\n  let label = `(${cartesianX.toFixed(0)}, ${cartesianY.toFixed(0)})`;\\n  \\n  // Position the text intelligently to avoid going off-screen\\n  let textX = mouseX + 15;\\n  let textY = mouseY - 15;\\n  if (textX + textWidth(label) > width) {\\n    textX = mouseX - 15 - textWidth(label);\\n  }\\n  if (textY < 20) {\\n    textY = mouseY + 25;\\n  }\\n  \\n  text(label, textX, textY);\\n}\\n\\nfunction drawAxes() {\\n  stroke(0);\\n  strokeWeight(2);\\n  // Y-axis\\n  line(centerX, 0, centerX, height);\\n  // X-axis\\n  line(0, centerY, width, centerY);\\n\\n  // Add labels\\n  fill(0);\\n  textSize(16);\\n  noStroke();\\n  text(\\"x\\", width - 20, centerY - 10);\\n  text(\\"y\\", centerX + 10, 20);\\n  text(\\"0\\", centerX - 15, centerY + 15);\\n}\\n\\nfunction drawGrid() {\\n  let spacing = 20;\\n  stroke(220);\\n  strokeWeight(1);\\n\\n  // Vertical lines\\n  for (let x = centerX + spacing; x < width; x += spacing) {\\n    line(x, 0, x, height);\\n  }\\n  for (let x = centerX - spacing; x > 0; x -= spacing) {\\n    line(x, 0, x, height);\\n  }\\n\\n  // Horizontal lines\\n  for (let y = centerY + spacing; y < height; y += spacing) {\\n    line(0, y, width, y);\\n  }\\n  for (let y = centerY - spacing; y > 0; y -= spacing) {\\n    line(0, y, width, y);\\n  }\\n}\\n", "explanation": "This sketch shows a 2D Cartesian plane. A point's position on the plane is described by its (x, y) coordinates, which measure its horizontal and vertical distance from the center.", "interaction_hint": "Move your mouse around the canvas to see the coordinates of the red dot change."}
b7c7338b-dc8c-4b44-802d-6906c5dc4c77	38501783-2e12-4cc4-abe1-31737816340a	dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	Mathematics session	{"goal": "Prompt the student to find one of the integer roots of the polynomial by testing the divisors of the constant term.", "turn": 1, "summary": "[turn 1] subgoal: Prompt the student to find one of the integer roots of the polynomial by testing the divisors of the constant term.\\nlast diagnosis: first attempt"}	2026-05-18 09:08:02.330065+00	2026-05-18 09:08:59.035137+00	{"title": "Visualizing the Roots of a Polynomial", "concept": "polynomial_roots", "p5_code": "// A cubic function to visualize.\\n// This function is similar in shape to the one in the problem but has different roots.\\n// The roots are at x = -2, x = 1, and x = 3.\\nfunction f(x) {\\n  return 0.5 * (x * x * x - 2 * x * x - 5 * x + 6);\\n}\\n\\n// World coordinate system bounds\\nlet xMin = -4;\\nlet xMax = 5;\\nlet yMin = -8;\\nlet yMax = 8;\\n\\nfunction setup() {\\n  createCanvas(560, 420);\\n  textFont(\\"sans-serif\\");\\n  textSize(14);\\n}\\n\\n// Convert from world (math) coordinates to screen (pixel) coordinates\\nfunction toScreenX(x) {\\n  return map(x, xMin, xMax, 0, width);\\n}\\n\\nfunction toScreenY(y) {\\n  return map(y, yMin, yMax, height, 0);\\n}\\n\\n// Convert from screen (pixel) coordinates to world (math) coordinates\\nfunction toWorldX(px) {\\n  return map(px, 0, width, xMin, xMax);\\n}\\n\\nfunction drawAxes() {\\n  stroke(150);\\n  strokeWeight(1);\\n  \\n  // X-Axis\\n  line(0, toScreenY(0), width, toScreenY(0));\\n  // Y-Axis\\n  line(toScreenX(0), 0, toScreenX(0), height);\\n\\n  // Ticks and labels for X-axis\\n  textAlign(CENTER, TOP);\\n  fill(100);\\n  for (let x = ceil(xMin); x <= floor(xMax); x++) {\\n    if (x === 0) continue;\\n    stroke(150);\\n    line(toScreenX(x), toScreenY(0) - 5, toScreenX(x), toScreenY(0) + 5);\\n    noStroke();\\n    text(x, toScreenX(x), toScreenY(0) + 8);\\n  }\\n  noStroke();\\n  text(\\"x\\", width - 15, toScreenY(0) - 20);\\n\\n  // Ticks and labels for Y-axis\\n  textAlign(RIGHT, CENTER);\\n  for (let y = ceil(yMin); y <= floor(yMax); y++) {\\n    if (y === 0) continue;\\n    stroke(150);\\n    line(toScreenX(0) - 5, toScreenY(y), toScreenX(0) + 5, toScreenY(y));\\n    noStroke();\\n    text(y, toScreenX(0) - 8, toScreenY(y));\\n  }\\n  noStroke();\\n  text(\\"y\\", toScreenX(0) + 20, 15);\\n}\\n\\nfunction drawCurve() {\\n  noFill();\\n  stroke(0);\\n  strokeWeight(2);\\n  beginShape();\\n  for (let px = 0; px <= width; px += 2) {\\n    let x = toWorldX(px);\\n    let y = f(x);\\n    if (abs(y) < yMax * 2) { // Avoid rendering extreme values if function goes off-screen\\n        vertex(px, toScreenY(y));\\n    }\\n  }\\n  endShape();\\n}\\n\\nfunction drawInteractivePoint() {\\n  let worldX = toWorldX(mouseX);\\n  worldX = constrain(worldX, xMin, xMax); // Keep point within the plotted bounds\\n  let worldY = f(worldX);\\n\\n  let screenX = toScreenX(worldX);\\n  let screenY = toScreenY(worldY);\\n\\n  // Dotted lines to the axes\\n  stroke(192, 57, 43, 150); // Crimson with alpha\\n  strokeWeight(1);\\n  drawingContext.setLineDash([5, 5]);\\n  line(screenX, screenY, screenX, toScreenY(0)); // Vertical line to x-axis\\n  line(screenX, screenY, toScreenX(0), screenY); // Horizontal line to y-axis\\n  drawingContext.setLineDash([]); // Reset to solid line\\n\\n  // The point on the curve\\n  noStroke();\\n  fill(192, 57, 43); // Crimson: #C0392B\\n  ellipse(screenX, screenY, 10, 10);\\n\\n  // Display coordinates\\n  textAlign(LEFT, TOP);\\n  fill(0);\\n  let coordText = `(x, y) = (${worldX.toFixed(2)}, ${worldY.toFixed(2)})`;\\n  text(coordText, 10, 10);\\n\\n  // Highlight when y is near zero (indicating a root)\\n  if (abs(worldY) < 0.25) {\\n    fill(192, 57, 43);\\n    textSize(16);\\n    textAlign(LEFT, TOP);\\n    text(\\"This is a 'root'—where the curve crosses the x-axis and y is 0!\\", 10, 35);\\n    textSize(14); // Reset text size\\n  }\\n}\\n\\nfunction draw() {\\n  background(255);\\n  drawAxes();\\n  drawCurve();\\n  drawInteractivePoint();\\n\\n  fill(0);\\n  noStroke();\\n  textAlign(CENTER, TOP);\\n  text(\\"Finding solutions for f(x) = 0\\", width / 2, 10);\\n}", "explanation": "This sketch graphs a cubic polynomial function. The 'roots' or 'solutions' to an equation like `f(x) = 0` are the x-values where the graph crosses the horizontal x-axis, making the y-value zero.", "interaction_hint": "Move your mouse left and right to slide the red dot along the curve. Observe how the `y` coordinate approaches zero when the dot gets near one of the \\"roots\\" where the graph intersects the x-axis."}
\.


--
-- Data for Name: sub_skills; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sub_skills (id, concept_id, slug, name, name_bn, description, sort_order) FROM stdin;
2046e63c-e5ba-421a-901b-0b9778bc80c2	521ac0d8-1fa0-45b4-9c4e-bec902195ccc	linear-eq	Linear equations	রৈখিক সমীকরণ	\N	1
799c39c4-f302-4007-a0c6-b66aa4c5d7ad	521ac0d8-1fa0-45b4-9c4e-bec902195ccc	quadratic-factoring	Quadratic factoring	দ্বিঘাত উৎপাদকীকরণ	\N	2
2bb2bcb8-ab69-4d51-8a5f-dbbd50f29522	521ac0d8-1fa0-45b4-9c4e-bec902195ccc	discriminant	Discriminant	ডিসক্রিমিন্যান্ট	\N	3
049284a6-f721-4f5e-8ede-3ea65ca25b34	521ac0d8-1fa0-45b4-9c4e-bec902195ccc	polynomials	Polynomials	বহুপদী	\N	4
e442b36e-e785-4847-a78e-7885e61be9a9	76e36c1a-0b76-4da8-8a7a-a0fb122e66ca	triangles	Triangles	ত্রিভুজ	\N	1
aad06b1d-4686-46fc-9ac7-f796b8ba7dd2	76e36c1a-0b76-4da8-8a7a-a0fb122e66ca	circles	Circles	বৃত্ত	\N	2
71b0e7a3-9f54-46a4-8a82-e7173287f0ee	76e36c1a-0b76-4da8-8a7a-a0fb122e66ca	area-volume	Area & Volume	ক্ষেত্রফল ও আয়তন	\N	3
854978fd-8b12-4a5e-903d-6ec32d70ceeb	3034868a-7252-43cb-a820-e77595c2e3bc	derivatives	Derivatives	অন্তরজ	\N	1
2270d92a-e28a-4f7c-8aad-ee155cf2e924	3034868a-7252-43cb-a820-e77595c2e3bc	integrals	Integrals	যোগজ	\N	2
0a1fe79b-09e4-438f-a958-c88aaf104fe4	3034868a-7252-43cb-a820-e77595c2e3bc	limits	Limits	সীমা	\N	3
0adfaaf4-2749-4830-9f7a-c00db8b58597	e7ffc2e1-758b-4b66-a526-eeaa9dbbfe04	identities	Identities	অভেদ	\N	1
4c3192ec-6a60-4f3e-9c28-3d60a3c740a5	e7ffc2e1-758b-4b66-a526-eeaa9dbbfe04	ratios	Trig ratios	ত্রিকোণমিতিক অনুপাত	\N	2
7fd652a8-ae6d-4056-9174-8353eb99e05a	e1ecf748-85b2-4e51-bac8-7ece1c6d8ca3	basic-prob	Basic probability	মৌলিক সম্ভাব্যতা	\N	1
23e20425-7b7b-4df6-a9f0-d93766cd03f7	e1ecf748-85b2-4e51-bac8-7ece1c6d8ca3	combinations	Combinations	সমাবেশ	\N	2
4739c1b8-73c6-4a8f-9d4e-0cc6889b02c5	4b02cada-30b5-4d44-8c25-fbdd83b95ca7	kinematics	Kinematics	গতিবিজ্ঞান	\N	1
d3df2a96-118e-48ae-876c-ca3f4050f7c8	4b02cada-30b5-4d44-8c25-fbdd83b95ca7	newtons-laws	Newton's laws	নিউটনের সূত্র	\N	2
dcc306f4-8a7c-4265-a889-e2bc585d9106	4b02cada-30b5-4d44-8c25-fbdd83b95ca7	momentum	Momentum	ভরবেগ	\N	3
886fd5e1-77c3-4ae1-bb89-890b613c7632	4b02cada-30b5-4d44-8c25-fbdd83b95ca7	energy-work	Energy & Work	শক্তি ও কাজ	\N	4
d1ccd065-41e7-4932-aeae-ce5cb2f7c0dc	94b9f9cc-7378-4e8b-95cf-def6a6a9b737	heat-temp	Heat & Temperature	তাপ ও তাপমাত্রা	\N	1
1043dde9-0086-4409-ae69-b0c458509b17	94b9f9cc-7378-4e8b-95cf-def6a6a9b737	laws-thermo	Laws of thermodynamics	তাপগতিবিদ্যার সূত্র	\N	2
a6dc0579-cdd4-400d-9c13-1ddbb56c2d7a	d232ddaa-7bee-402a-a4ff-172db6f51440	circuits	Circuits	বর্তনী	\N	1
e5c96b1b-fe2f-4853-a0c2-cc1f01340ce0	d232ddaa-7bee-402a-a4ff-172db6f51440	fields	Electric & magnetic fields	তড়িৎ ও চৌম্বক ক্ষেত্র	\N	2
8ce26dfc-5b45-480e-8428-191104ddff23	e475dc02-79f9-492d-be40-f482a50ddda0	wave-properties	Wave properties	তরঙ্গের ধর্ম	\N	1
a2076eda-6732-4d5d-9d48-c3d89b1fcdb5	e475dc02-79f9-492d-be40-f482a50ddda0	reflection-refraction	Reflection & refraction	প্রতিফলন ও প্রতিসরণ	\N	2
79b76399-805c-49fb-ad33-f8b71cb12966	94e55821-8ca1-4c38-af35-f2abb0a51469	periodic-table	Periodic table	পর্যায় সারণি	\N	1
8a6b8704-581c-4088-a320-a4d31fd8249b	94e55821-8ca1-4c38-af35-f2abb0a51469	electron-config	Electron configuration	ইলেকট্রন বিন্যাস	\N	2
a821d1e4-4d4a-428e-8c7e-29ada8afcd39	94e55821-8ca1-4c38-af35-f2abb0a51469	bonding	Chemical bonding	রাসায়নিক বন্ধন	\N	3
ef9156d9-fe3d-45db-98aa-a39772552bc5	d16929d9-c89e-4998-9972-bb0b8f6f72bc	balancing	Balancing equations	সমীকরণ সমতা	\N	1
436e7305-fb58-4420-b684-c92b8e726bc7	d16929d9-c89e-4998-9972-bb0b8f6f72bc	stoichiometry	Stoichiometry	স্টয়কিওমেট্রি	\N	2
d764ac27-0158-4d03-a5c5-2354cc2ea554	d16929d9-c89e-4998-9972-bb0b8f6f72bc	redox	Redox reactions	জারণ-বিজারণ	\N	3
17d43af4-803c-4754-993d-389090e9a677	291f7af1-7826-4971-9b16-8c8037d3f0c0	hydrocarbons	Hydrocarbons	হাইড্রোকার্বন	\N	1
7a3f96d9-58c8-4d2b-83a6-52e94c0a6d47	291f7af1-7826-4971-9b16-8c8037d3f0c0	functional-groups	Functional groups	ক্রিয়াশীল মূলক	\N	2
fb357709-2cb4-43ec-bedf-1772314255bc	9917d02e-5a40-4736-a07b-e6f3c37be8dc	ph-acids	pH & acids	pH ও অ্যাসিড	\N	1
43500350-77ca-4803-aa15-3d146cb0a58d	9917d02e-5a40-4736-a07b-e6f3c37be8dc	concentration	Concentration	গাঢ়ত্ব	\N	2
cf197f92-5a20-4c8b-9d15-289fcdae6092	dd1df910-26b4-4ccf-980f-c08f88fdabeb	cell-structure	Cell structure	কোষের গঠন	\N	1
1f7d9489-436c-4dc6-93e1-4ceb7783ad49	dd1df910-26b4-4ccf-980f-c08f88fdabeb	mitosis-meiosis	Mitosis & meiosis	মাইটোসিস ও মিয়োসিস	\N	2
0467869f-e92f-4bd2-9218-86ae0fabb2ff	dd1df910-26b4-4ccf-980f-c08f88fdabeb	photosynthesis	Photosynthesis	সালোকসংশ্লেষণ	\N	3
2a2c60ba-8818-4fe4-a4ab-a085c19bfcd7	dd1df910-26b4-4ccf-980f-c08f88fdabeb	respiration	Cellular respiration	কোষীয় শ্বসন	\N	4
08dd8c51-88e0-4c13-8102-28e19b4d3e15	342fcd10-caef-4505-989a-05e6cd3e70fc	dna-rna	DNA & RNA	ডিএনএ ও আরএনএ	\N	1
0277295b-9d8b-47e1-afc9-54d35687463d	342fcd10-caef-4505-989a-05e6cd3e70fc	mendelian	Mendelian genetics	মেন্ডেলীয় জিনতত্ত্ব	\N	2
1c248b2f-7eb6-44c0-bb1d-6865deae3b4b	2f7978e8-1f54-4f3b-ad08-0659c74d4651	circulation	Circulatory system	সংবহনতন্ত্র	\N	1
75d2a3b0-3233-447c-80f5-ee619d80037b	2f7978e8-1f54-4f3b-ad08-0659c74d4651	digestion	Digestive system	পরিপাকতন্ত্র	\N	2
5aa07451-0393-4a23-9daf-e60f70f3abcd	4f731b33-645b-4f43-93fe-63bda88466e2	ecosystems	Ecosystems	বাস্তুতন্ত্র	\N	1
8c8ecb89-e59e-4fc6-9bc1-c74a57ec87dc	4f731b33-645b-4f43-93fe-63bda88466e2	food-chains	Food chains	খাদ্য শৃঙ্খল	\N	2
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.subjects (id, slug, name, name_bn, sort_order) FROM stdin;
dcf7184f-08cf-4b9b-bd0b-f1a4abadf8ee	math	Mathematics	গণিত	1
d49b8e43-74fa-46f2-86c3-d2d008be9527	physics	Physics	পদার্থবিজ্ঞান	2
ee980a11-c022-4142-8381-895b4b3295dd	chemistry	Chemistry	রসায়ন	3
026a9e35-dc20-4b28-8775-f10e329670df	biology	Biology	জীববিজ্ঞান	4
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2026-04-27 13:32:16
20211116045059	2026-04-27 13:32:17
20211116050929	2026-04-27 13:32:18
20211116051442	2026-04-27 13:32:18
20211116212300	2026-04-27 13:32:19
20211116213355	2026-04-27 13:32:20
20211116213934	2026-04-27 13:32:20
20211116214523	2026-04-27 13:32:21
20211122062447	2026-04-27 13:32:22
20211124070109	2026-04-27 13:32:23
20211202204204	2026-04-27 13:32:23
20211202204605	2026-04-27 13:32:24
20211210212804	2026-04-27 13:32:26
20211228014915	2026-04-27 13:32:27
20220107221237	2026-04-27 13:32:28
20220228202821	2026-04-27 13:32:28
20220312004840	2026-04-27 13:32:29
20220603231003	2026-04-27 13:32:30
20220603232444	2026-04-27 13:32:31
20220615214548	2026-04-27 13:32:32
20220712093339	2026-04-27 13:32:32
20220908172859	2026-04-27 13:32:33
20220916233421	2026-04-27 13:32:34
20230119133233	2026-04-27 13:32:34
20230128025114	2026-04-27 13:32:35
20230128025212	2026-04-27 13:32:36
20230227211149	2026-04-27 13:32:37
20230228184745	2026-04-27 13:32:37
20230308225145	2026-04-27 13:32:38
20230328144023	2026-04-27 13:32:39
20231018144023	2026-04-27 13:32:40
20231204144023	2026-04-27 13:32:41
20231204144024	2026-04-27 13:32:41
20231204144025	2026-04-27 13:32:42
20240108234812	2026-04-27 13:32:43
20240109165339	2026-04-27 13:32:44
20240227174441	2026-04-27 13:32:45
20240311171622	2026-04-27 13:32:46
20240321100241	2026-04-27 13:32:47
20240401105812	2026-04-27 13:32:49
20240418121054	2026-04-27 13:32:50
20240523004032	2026-04-27 13:32:53
20240618124746	2026-04-27 13:32:53
20240801235015	2026-04-27 13:32:54
20240805133720	2026-04-27 13:32:55
20240827160934	2026-04-27 13:32:55
20240919163303	2026-04-27 13:32:56
20240919163305	2026-04-27 13:32:57
20241019105805	2026-04-27 13:32:58
20241030150047	2026-04-27 13:33:00
20241108114728	2026-04-27 13:33:01
20241121104152	2026-04-27 13:33:02
20241130184212	2026-04-27 13:33:03
20241220035512	2026-04-27 13:33:03
20241220123912	2026-04-27 13:33:04
20241224161212	2026-04-27 13:33:05
20250107150512	2026-04-27 13:33:05
20250110162412	2026-04-27 13:33:06
20250123174212	2026-04-27 13:33:07
20250128220012	2026-04-27 13:33:07
20250506224012	2026-04-27 13:33:08
20250523164012	2026-04-27 13:33:09
20250714121412	2026-04-27 13:33:09
20250905041441	2026-04-27 13:33:10
20251103001201	2026-04-27 13:33:11
20251120212548	2026-04-27 13:33:12
20251120215549	2026-04-27 13:33:12
20260218120000	2026-04-27 13:33:13
20260326120000	2026-04-27 13:33:14
20260514120000	2026-06-25 14:15:46
20260527120000	2026-06-25 14:15:48
20260528120000	2026-06-25 14:15:49
20260603120000	2026-06-25 14:15:50
20260605120000	2026-06-25 14:15:51
20260606110000	2026-06-25 14:15:51
20260616120000	2026-06-25 14:15:54
20260624120000	2026-06-25 14:15:55
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at, action_filter, selected_columns) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
problem-images	problem-images	\N	2026-04-27 13:38:21.501114+00	2026-04-27 13:38:21.501114+00	f	f	\N	\N	\N	STANDARD
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_analytics (name, type, format, created_at, updated_at, id, deleted_at) FROM stdin;
\.


--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_vectors (id, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2026-04-27 12:22:57.866988
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2026-04-27 12:22:57.932357
2	storage-schema	f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd	2026-04-27 12:22:57.941071
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2026-04-27 12:22:57.993764
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2026-04-27 12:22:58.012973
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2026-04-27 12:22:58.021963
6	change-column-name-in-get-size	ded78e2f1b5d7e616117897e6443a925965b30d2	2026-04-27 12:22:58.034027
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2026-04-27 12:22:58.044077
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2026-04-27 12:22:58.053228
9	fix-search-function	af597a1b590c70519b464a4ab3be54490712796b	2026-04-27 12:22:58.062706
10	search-files-search-function	b595f05e92f7e91211af1bbfe9c6a13bb3391e16	2026-04-27 12:22:58.072912
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2026-04-27 12:22:58.081951
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2026-04-27 12:22:58.091804
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2026-04-27 12:22:58.100994
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2026-04-27 12:22:58.11023
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2026-04-27 12:22:58.142723
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2026-04-27 12:22:58.151852
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2026-04-27 12:22:58.161037
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2026-04-27 12:22:58.170311
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2026-04-27 12:22:58.180953
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2026-04-27 12:22:58.190387
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2026-04-27 12:22:58.201904
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2026-04-27 12:22:58.222974
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2026-04-27 12:22:58.237321
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2026-04-27 12:22:58.246942
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2026-04-27 12:22:58.256189
26	objects-prefixes	215cabcb7f78121892a5a2037a09fedf9a1ae322	2026-04-27 12:22:58.265401
27	search-v2	859ba38092ac96eb3964d83bf53ccc0b141663a6	2026-04-27 12:22:58.273945
28	object-bucket-name-sorting	c73a2b5b5d4041e39705814fd3a1b95502d38ce4	2026-04-27 12:22:58.282643
29	create-prefixes	ad2c1207f76703d11a9f9007f821620017a66c21	2026-04-27 12:22:58.291728
30	update-object-levels	2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6	2026-04-27 12:22:58.301185
31	objects-level-index	b40367c14c3440ec75f19bbce2d71e914ddd3da0	2026-04-27 12:22:58.310421
32	backward-compatible-index-on-objects	e0c37182b0f7aee3efd823298fb3c76f1042c0f7	2026-04-27 12:22:58.319226
33	backward-compatible-index-on-prefixes	b480e99ed951e0900f033ec4eb34b5bdcb4e3d49	2026-04-27 12:22:58.327957
34	optimize-search-function-v1	ca80a3dc7bfef894df17108785ce29a7fc8ee456	2026-04-27 12:22:58.33666
35	add-insert-trigger-prefixes	458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc	2026-04-27 12:22:58.345399
36	optimise-existing-functions	6ae5fca6af5c55abe95369cd4f93985d1814ca8f	2026-04-27 12:22:58.35424
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2026-04-27 12:22:58.364094
38	iceberg-catalog-flag-on-buckets	02716b81ceec9705aed84aa1501657095b32e5c5	2026-04-27 12:22:58.378688
39	add-search-v2-sort-support	6706c5f2928846abee18461279799ad12b279b78	2026-04-27 12:22:58.401887
40	fix-prefix-race-conditions-optimized	7ad69982ae2d372b21f48fc4829ae9752c518f6b	2026-04-27 12:22:58.41072
41	add-object-level-update-trigger	07fcf1a22165849b7a029deed059ffcde08d1ae0	2026-04-27 12:22:58.419104
42	rollback-prefix-triggers	771479077764adc09e2ea2043eb627503c034cd4	2026-04-27 12:22:58.427848
43	fix-object-level	84b35d6caca9d937478ad8a797491f38b8c2979f	2026-04-27 12:22:58.436563
44	vector-bucket-type	99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3	2026-04-27 12:22:58.445782
45	vector-buckets	049e27196d77a7cb76497a85afae669d8b230953	2026-04-27 12:22:58.45535
46	buckets-objects-grants	fedeb96d60fefd8e02ab3ded9fbde05632f84aed	2026-04-27 12:22:58.470959
47	iceberg-table-metadata	649df56855c24d8b36dd4cc1aeb8251aa9ad42c2	2026-04-27 12:22:58.480576
48	iceberg-catalog-ids	e0e8b460c609b9999ccd0df9ad14294613eed939	2026-04-27 12:22:58.489803
49	buckets-objects-grants-postgres	072b1195d0d5a2f888af6b2302a1938dd94b8b3d	2026-04-27 12:22:58.510889
50	search-v2-optimised	6323ac4f850aa14e7387eb32102869578b5bd478	2026-04-27 12:22:58.520129
51	index-backward-compatible-search	2ee395d433f76e38bcd3856debaf6e0e5b674011	2026-04-27 12:22:58.993806
52	drop-not-used-indexes-and-functions	5cc44c8696749ac11dd0dc37f2a3802075f3a171	2026-04-27 12:22:58.996859
53	drop-index-lower-name	d0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854	2026-04-27 12:22:59.011721
54	drop-index-object-level	6289e048b1472da17c31a7eba1ded625a6457e67	2026-04-27 12:22:59.017097
55	prevent-direct-deletes	262a4798d5e0f2e7c8970232e03ce8be695d5819	2026-04-27 12:22:59.019985
57	s3-multipart-uploads-metadata	f127886e00d1b374fadbc7c6b31e09336aad5287	2026-04-27 12:22:59.040298
58	operation-ergonomics	00ca5d483b3fe0d522133d9002ccc5df98365120	2026-04-27 12:22:59.050599
56	fix-optimized-search-function	b823ed1e418101032fa01374edc9a436e54e3ed4	2026-04-27 12:22:59.029972
59	drop-unused-functions	38456f13e39691c2bbb4b5151d0d1cdbabd4a8c4	2026-05-07 15:45:18.669033
60	optimize-existing-functions-again	db35e1c91a9201e59f4fef8d972c2f277d68b157	2026-05-07 15:45:19.266527
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) FROM stdin;
0e873220-f0ce-4b87-818e-a6737a421fed	problem-images	38501783-2e12-4cc4-abe1-31737816340a/52440739-ef50-40c0-9a77-943b2fc4f981/1777298061278-Nafiu.jpg	38501783-2e12-4cc4-abe1-31737816340a	2026-04-27 13:54:22.000043+00	2026-04-27 13:54:22.000043+00	2026-04-27 13:54:22.000043+00	{"eTag": "\\"0fea8eb76cebebaeac06de5111a97b9b\\"", "size": 79727, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-04-27T13:54:22.000Z", "contentLength": 79727, "httpStatusCode": 200}	01a83c56-4445-4d02-add6-1c739788544c	38501783-2e12-4cc4-abe1-31737816340a	{}
4075d81c-57ec-4edb-9390-30b3206b8b05	problem-images	38501783-2e12-4cc4-abe1-31737816340a/bbb7d83f-2678-4405-948c-d0d77cb4e36d/1779094648441-img.jpg	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 08:57:29.093781+00	2026-05-18 08:57:29.093781+00	2026-05-18 08:57:29.093781+00	{"eTag": "\\"b0f0ff385ebbd2e9b6d4e8f0fe338ac5\\"", "size": 48755, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-05-18T08:57:30.000Z", "contentLength": 48755, "httpStatusCode": 200}	1fd0e99a-3d47-408f-b686-ce6f502999cc	38501783-2e12-4cc4-abe1-31737816340a	{}
00d943d3-e91b-4f2f-aefd-c6f632571075	problem-images	38501783-2e12-4cc4-abe1-31737816340a/bbb7d83f-2678-4405-948c-d0d77cb4e36d/1779094708672-img.jpg	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 08:58:29.082373+00	2026-05-18 08:58:29.082373+00	2026-05-18 08:58:29.082373+00	{"eTag": "\\"b0f0ff385ebbd2e9b6d4e8f0fe338ac5\\"", "size": 48755, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-05-18T08:58:30.000Z", "contentLength": 48755, "httpStatusCode": 200}	cfa04b76-6abd-42f1-a882-422c107f10d2	38501783-2e12-4cc4-abe1-31737816340a	{}
52c72312-c515-4a82-9dfe-65e0d6bca0df	problem-images	38501783-2e12-4cc4-abe1-31737816340a/bbb7d83f-2678-4405-948c-d0d77cb4e36d/1779094776132-img.jpg	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 08:59:36.806432+00	2026-05-18 08:59:36.806432+00	2026-05-18 08:59:36.806432+00	{"eTag": "\\"b0f0ff385ebbd2e9b6d4e8f0fe338ac5\\"", "size": 48755, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-05-18T08:59:37.000Z", "contentLength": 48755, "httpStatusCode": 200}	c1de4e6d-6ddc-4e39-8b56-437c270c45e1	38501783-2e12-4cc4-abe1-31737816340a	{}
09c674ae-e17d-46e5-bf11-1a815b421cc9	problem-images	38501783-2e12-4cc4-abe1-31737816340a/b7c7338b-dc8c-4b44-802d-6906c5dc4c77/1779095291255-img.jpg	38501783-2e12-4cc4-abe1-31737816340a	2026-05-18 09:08:11.600456+00	2026-05-18 09:08:11.600456+00	2026-05-18 09:08:11.600456+00	{"eTag": "\\"b0f0ff385ebbd2e9b6d4e8f0fe338ac5\\"", "size": 48755, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-05-18T09:08:12.000Z", "contentLength": 48755, "httpStatusCode": 200}	a5f2877d-3d4e-4ef3-99bd-a125d0a0c715	38501783-2e12-4cc4-abe1-31737816340a	{}
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata, metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.vector_indexes (id, name, bucket_id, data_type, dimension, distance_metric, metadata_configuration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 61, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


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
-- Name: concepts concepts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concepts
    ADD CONSTRAINT concepts_pkey PRIMARY KEY (id);


--
-- Name: concepts concepts_subject_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concepts
    ADD CONSTRAINT concepts_subject_id_slug_key UNIQUE (subject_id, slug);


--
-- Name: knowledge_state knowledge_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_state
    ADD CONSTRAINT knowledge_state_pkey PRIMARY KEY (id);


--
-- Name: knowledge_state knowledge_state_user_id_sub_skill_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_state
    ADD CONSTRAINT knowledge_state_user_id_sub_skill_id_key UNIQUE (user_id, sub_skill_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_key UNIQUE (user_id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sub_skills sub_skills_concept_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_skills
    ADD CONSTRAINT sub_skills_concept_id_slug_key UNIQUE (concept_id, slug);


--
-- Name: sub_skills sub_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_skills
    ADD CONSTRAINT sub_skills_pkey PRIMARY KEY (id);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: subjects subjects_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_slug_key UNIQUE (slug);


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
-- Name: idx_users_created_at_desc; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_created_at_desc ON auth.users USING btree (created_at DESC);


--
-- Name: idx_users_email; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_email ON auth.users USING btree (email);


--
-- Name: idx_users_last_sign_in_at_desc; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_last_sign_in_at_desc ON auth.users USING btree (last_sign_in_at DESC);


--
-- Name: idx_users_name; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_name ON auth.users USING btree (((raw_user_meta_data ->> 'name'::text))) WHERE ((raw_user_meta_data ->> 'name'::text) IS NOT NULL);


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
-- Name: idx_ks_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ks_user ON public.knowledge_state USING btree (user_id);


--
-- Name: idx_messages_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_session ON public.messages USING btree (session_id, created_at);


--
-- Name: idx_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_user ON public.sessions USING btree (user_id, created_at DESC);


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
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


--
-- Name: knowledge_state trg_ks_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ks_touch BEFORE UPDATE ON public.knowledge_state FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: profiles trg_profiles_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_profiles_touch BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: sessions trg_sessions_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sessions_touch BEFORE UPDATE ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


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
-- Name: concepts concepts_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concepts
    ADD CONSTRAINT concepts_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: knowledge_state knowledge_state_sub_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_state
    ADD CONSTRAINT knowledge_state_sub_skill_id_fkey FOREIGN KEY (sub_skill_id) REFERENCES public.sub_skills(id) ON DELETE CASCADE;


--
-- Name: knowledge_state knowledge_state_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_state
    ADD CONSTRAINT knowledge_state_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: messages messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(id) ON DELETE CASCADE;


--
-- Name: messages messages_sub_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sub_skill_id_fkey FOREIGN KEY (sub_skill_id) REFERENCES public.sub_skills(id) ON DELETE SET NULL;


--
-- Name: messages messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE SET NULL;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sub_skills sub_skills_concept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_skills
    ADD CONSTRAINT sub_skills_concept_id_fkey FOREIGN KEY (concept_id) REFERENCES public.concepts(id) ON DELETE CASCADE;


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
-- Name: concepts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.concepts ENABLE ROW LEVEL SECURITY;

--
-- Name: concepts concepts readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "concepts readable" ON public.concepts FOR SELECT TO authenticated, anon USING (true);


--
-- Name: knowledge_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.knowledge_state ENABLE ROW LEVEL SECURITY;

--
-- Name: knowledge_state ks delete own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "ks delete own" ON public.knowledge_state FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: knowledge_state ks insert own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "ks insert own" ON public.knowledge_state FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: knowledge_state ks select own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "ks select own" ON public.knowledge_state FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: knowledge_state ks update own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "ks update own" ON public.knowledge_state FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: messages messages delete own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "messages delete own" ON public.messages FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: messages messages insert own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "messages insert own" ON public.messages FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: messages messages select own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "messages select own" ON public.messages FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: messages messages update own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "messages update own" ON public.messages FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: profiles own profile insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "own profile insert" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: profiles own profile select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "own profile select" ON public.profiles FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: profiles own profile update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "own profile update" ON public.profiles FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions sessions delete own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "sessions delete own" ON public.sessions FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: sessions sessions insert own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "sessions insert own" ON public.sessions FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: sessions sessions select own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "sessions select own" ON public.sessions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: sessions sessions update own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "sessions update own" ON public.sessions FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: sub_skills; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sub_skills ENABLE ROW LEVEL SECURITY;

--
-- Name: sub_skills sub_skills readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "sub_skills readable" ON public.sub_skills FOR SELECT TO authenticated, anon USING (true);


--
-- Name: subjects; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

--
-- Name: subjects subjects readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "subjects readable" ON public.subjects FOR SELECT TO authenticated, anon USING (true);


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
-- Name: objects own folder delete; Type: POLICY; Schema: storage; Owner: -
--

CREATE POLICY "own folder delete" ON storage.objects FOR DELETE USING (((bucket_id = 'problem-images'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));


--
-- Name: objects own folder insert; Type: POLICY; Schema: storage; Owner: -
--

CREATE POLICY "own folder insert" ON storage.objects FOR INSERT WITH CHECK (((bucket_id = 'problem-images'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));


--
-- Name: objects own folder read; Type: POLICY; Schema: storage; Owner: -
--

CREATE POLICY "own folder read" ON storage.objects FOR SELECT USING (((bucket_id = 'problem-images'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));


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
-- PostgreSQL database dump complete
--

\unrestrict cQ0IZmk7CmuBRAaRAY3q6I4m0Ns6oTCSxJjW2yw33lkLrh3xbs3CwJQaeDZGPzy

