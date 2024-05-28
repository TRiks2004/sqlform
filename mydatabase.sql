--
-- PostgreSQL database dump
--

-- Dumped from database version 14.11
-- Dumped by pg_dump version 14.11 (Ubuntu 14.11-0ubuntu0.22.04.1)

-- Started on 2024-05-28 22:25:03 MSK

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3 (class 3079 OID 18262)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 3781 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 2 (class 3079 OID 18148)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3782 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 321 (class 1255 OID 18186)
-- Name: add_employee(character varying, character varying, character varying, character varying, timestamp with time zone, timestamp with time zone, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_employee(IN p_name character varying, IN p_surname character varying, IN p_patronymic character varying, IN p_phone character varying, IN p_dob timestamp with time zone, IN p_hire_date timestamp with time zone, IN p_position integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS(SELECT 1 FROM employees WHERE phone = p_phone) THEN
        RAISE EXCEPTION 'Телефонный номер уже существует.';
    END IF;

    INSERT INTO employees (name, surname, patronymic, phone, dob, hire_date, position)
    VALUES (p_name, p_surname, p_patronymic, p_phone, p_dob, p_hire_date, p_position);

    RAISE NOTICE 'Новый сотрудник добавлен.';
END;
$$;


ALTER PROCEDURE public.add_employee(IN p_name character varying, IN p_surname character varying, IN p_patronymic character varying, IN p_phone character varying, IN p_dob timestamp with time zone, IN p_hire_date timestamp with time zone, IN p_position integer) OWNER TO postgres;

--
-- TOC entry 323 (class 1255 OID 18190)
-- Name: audit_equipment(timestamp with time zone, timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.audit_equipment(IN p_start_date timestamp with time zone, IN p_end_date timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Логика аудита может быть сложной и зависит от деталей, здесь пример с выводом сообщения
    RAISE NOTICE 'Аудит оборудования выполнен за период с % до %.', p_start_date, p_end_date;
END;
$$;


ALTER PROCEDURE public.audit_equipment(IN p_start_date timestamp with time zone, IN p_end_date timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 336 (class 1255 OID 18314)
-- Name: audit_trigger_func(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (operation_type, table_name, new_data)
        VALUES ('I', TG_TABLE_NAME, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (operation_type, table_name, old_data, new_data)
        VALUES ('U', TG_TABLE_NAME, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (operation_type, table_name, old_data)
        VALUES ('D', TG_TABLE_NAME, to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL; -- Никогда не должно произойти
END;
$$;


ALTER FUNCTION public.audit_trigger_func() OWNER TO postgres;

--
-- TOC entry 329 (class 1255 OID 18189)
-- Name: calculate_building_energy_usage(integer, timestamp with time zone, timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.calculate_building_energy_usage(IN p_building_id integer, IN p_start_date timestamp with time zone, IN p_end_date timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_usage INTEGER;
BEGIN
    SELECT SUM(daily_readings + night_readings) INTO total_usage
    FROM meter_readings_v1
        join public.living_quarters lq on meter_readings_v1.living_quarter = lq.id
    WHERE lq.building = p_building_id AND date_application BETWEEN p_start_date AND p_end_date;



    RAISE NOTICE 'Общий расход электроэнергии за период: %', total_usage;
END;
$$;


ALTER PROCEDURE public.calculate_building_energy_usage(IN p_building_id integer, IN p_start_date timestamp with time zone, IN p_end_date timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 327 (class 1255 OID 18197)
-- Name: check_equipment_criticality(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_equipment_criticality() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.criticality > 10 THEN
        RAISE EXCEPTION 'Criticality cannot exceed 10.';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_equipment_criticality() OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 18164)
-- Name: check_value_exists(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_value_exists(p_table_name text, p_column_name text, p_value text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    l_query TEXT;
    l_exists BOOLEAN;
BEGIN
    -- Формирование строки запроса с параметрами, приводим значение к тексту
    l_query := format('SELECT EXISTS (SELECT 1 FROM %I WHERE CAST(%I AS TEXT) = $1)', p_table_name, p_column_name);

    -- Выполнение запроса с передачей значения в параметр
    EXECUTE l_query INTO l_exists USING p_value;

    -- Возврат результата функции
    RETURN l_exists;
END;
$_$;


ALTER FUNCTION public.check_value_exists(p_table_name text, p_column_name text, p_value text) OWNER TO postgres;

--
-- TOC entry 307 (class 1255 OID 18167)
-- Name: check_value_exists_application_type(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_value_exists_application_type(p_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Приведение p_id к тексту и передача в функцию check_value_exists
    RETURN check_value_exists('application_types', 'id', p_id::TEXT);
END;
$$;


ALTER FUNCTION public.check_value_exists_application_type(p_id integer) OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 18165)
-- Name: check_value_exists_employees(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_value_exists_employees(p_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Приведение p_id к тексту и передача в функцию check_value_exists
    RETURN check_value_exists('employees', 'id', p_id::TEXT);
END;
$$;


ALTER FUNCTION public.check_value_exists_employees(p_id integer) OWNER TO postgres;

--
-- TOC entry 333 (class 1255 OID 18301)
-- Name: create_user(character varying, text, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_user(_username character varying, _password text, _email character varying, _employee integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Проверка на существование пользователя с таким email или employee ID
    IF EXISTS (SELECT 1 FROM users WHERE email = _email OR employee = _employee) THEN
        RAISE EXCEPTION 'User with this email or employee ID already exists';
    END IF;

    -- Хеширование пароля
    INSERT INTO users (id, username, password_hash, email, employee)
    VALUES (gen_random_uuid(), _username, hash_password(_password), _email, _employee);
END;
$$;


ALTER FUNCTION public.create_user(_username character varying, _password text, _email character varying, _employee integer) OWNER TO postgres;

--
-- TOC entry 332 (class 1255 OID 18299)
-- Name: hash_password(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hash_password(password text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Генерация соли и хеширование пароля
    RETURN crypt(password, gen_salt('bf', 8));  -- 'bf' означает Blowfish, 8 - это стоимость вычислений
END;
$$;


ALTER FUNCTION public.hash_password(password text) OWNER TO postgres;

--
-- TOC entry 330 (class 1255 OID 18195)
-- Name: log_employee_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_employee_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO employee_audit_logs(employee_id, previous_data, new_data, changed_on)
    VALUES (
               OLD.id,
               row_to_json(OLD),  -- Сериализация старых данных в JSON
               row_to_json(NEW),  -- Сериализация новых данных в JSON
               now()
           );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_employee_update() OWNER TO postgres;

--
-- TOC entry 268 (class 1255 OID 18201)
-- Name: prevent_application_deletion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_application_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'Deletion of application records is not allowed.';
END;
$$;


ALTER FUNCTION public.prevent_application_deletion() OWNER TO postgres;

--
-- TOC entry 324 (class 1255 OID 18188)
-- Name: record_meter_reading(integer, integer, integer, timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.record_meter_reading(IN p_meter_id integer, IN p_daily_readings integer, IN p_night_readings integer, IN p_date_application timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO meter_readings_v1 (id, daily_readings, night_readings, date_application)
    VALUES (p_meter_id, p_daily_readings, p_night_readings, p_date_application);

    RAISE NOTICE 'Показания счётчика зарегистрированы.';
END;
$$;


ALTER PROCEDURE public.record_meter_reading(IN p_meter_id integer, IN p_daily_readings integer, IN p_night_readings integer, IN p_date_application timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 280 (class 1255 OID 18220)
-- Name: record_meter_reading(integer, integer, integer, timestamp with time zone, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.record_meter_reading(IN p_meter_id integer, IN p_daily_readings integer, IN p_night_readings integer, IN p_date_application timestamp with time zone, IN p_living_quarter integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO meter_readings_v1 (id, daily_readings, night_readings, date_application, living_quarter)
    VALUES (p_meter_id, p_daily_readings, p_night_readings, p_date_application, p_living_quarter);

    RAISE NOTICE 'Показания счётчика зарегистрированы.';
END;
$$;


ALTER PROCEDURE public.record_meter_reading(IN p_meter_id integer, IN p_daily_readings integer, IN p_night_readings integer, IN p_date_application timestamp with time zone, IN p_living_quarter integer) OWNER TO postgres;

--
-- TOC entry 267 (class 1255 OID 18159)
-- Name: simple_procedure(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.simple_procedure()
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Ваш SQL-код здесь
    RAISE NOTICE 'Процедура выполнена.';
END;
$$;


ALTER PROCEDURE public.simple_procedure() OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 18160)
-- Name: simple_procedure(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.simple_procedure(IN p_employees_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Ваш SQL-код здесь

    IF NOT (select check_value_exists_employees(p_employees_id)) THEN
        RAISE EXCEPTION 'Employees ID % не существует.', p_employees_id;
    END IF;



    RAISE NOTICE 'Процедура выполнена.';
END;
$$;


ALTER PROCEDURE public.simple_procedure(IN p_employees_id integer) OWNER TO postgres;

--
-- TOC entry 306 (class 1255 OID 18166)
-- Name: simple_procedure(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.simple_procedure(IN p_employees_id integer, IN p_application_type integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Ваш SQL-код здесь

    IF NOT (select check_value_exists_employees(p_employees_id)) THEN
        RAISE EXCEPTION 'Employees ID % не существует.', p_employees_id;
    END IF;


    IF NOT (select check_value_exists_application_type(p_application_type)) THEN
        RAISE EXCEPTION 'Application Type ID % не существует.', p_application_type;
    END IF;


    RAISE NOTICE 'Процедура выполнена.';
END;
$$;


ALTER PROCEDURE public.simple_procedure(IN p_employees_id integer, IN p_application_type integer) OWNER TO postgres;

--
-- TOC entry 322 (class 1255 OID 18187)
-- Name: update_application_status(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_application_status(IN p_application_id integer, IN p_new_status integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM applications WHERE id = p_application_id) THEN
        RAISE EXCEPTION 'Заявка с ID % не найдена.', p_application_id;
    END IF;

    UPDATE applications
    SET application_status = p_new_status
    WHERE id = p_application_id;

    RAISE NOTICE 'Статус заявки обновлён.';
END;
$$;


ALTER PROCEDURE public.update_application_status(IN p_application_id integer, IN p_new_status integer) OWNER TO postgres;

--
-- TOC entry 328 (class 1255 OID 18199)
-- Name: update_last_interaction(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_last_interaction() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE consumers SET last_interaction = CURRENT_TIMESTAMP WHERE id = NEW.id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_last_interaction() OWNER TO postgres;

--
-- TOC entry 326 (class 1255 OID 18193)
-- Name: user_tokens_before_insert_trg(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_tokens_before_insert_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.id := uuid_generate_v4();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.user_tokens_before_insert_trg() OWNER TO postgres;

--
-- TOC entry 325 (class 1255 OID 18191)
-- Name: users_before_insert_trg(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.users_before_insert_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.id := uuid_generate_v4();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.users_before_insert_trg() OWNER TO postgres;

--
-- TOC entry 334 (class 1255 OID 18300)
-- Name: verify_password(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_password(password text, stored_hash text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN (stored_hash = crypt(password, stored_hash));
END;
$$;


ALTER FUNCTION public.verify_password(password text, stored_hash text) OWNER TO postgres;

--
-- TOC entry 335 (class 1255 OID 18302)
-- Name: verify_user_password(character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_user_password(_username character varying, _password text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    stored_hash varchar(255);
BEGIN
    -- Получение хеша пароля из таблицы
    SELECT password_hash INTO stored_hash FROM users WHERE username = _username;

    IF stored_hash IS NULL THEN
        RETURN FALSE; -- Пользователь не найден
    END IF;

    -- Проверка пароля
    RETURN verify_password(_password, text(stored_hash));
END;
$$;


ALTER FUNCTION public.verify_user_password(_username character varying, _password text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 211 (class 1259 OID 17828)
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 17834)
-- Name: application_statuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.application_statuses (
    id integer NOT NULL,
    name character varying(70) NOT NULL
);


ALTER TABLE public.application_statuses OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 17833)
-- Name: application_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.application_statuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.application_statuses_id_seq OWNER TO postgres;

--
-- TOC entry 3785 (class 0 OID 0)
-- Dependencies: 212
-- Name: application_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.application_statuses_id_seq OWNED BY public.application_statuses.id;


--
-- TOC entry 215 (class 1259 OID 17844)
-- Name: application_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.application_types (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    type character varying(70) NOT NULL
);


ALTER TABLE public.application_types OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 17843)
-- Name: application_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.application_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.application_types_id_seq OWNER TO postgres;

--
-- TOC entry 3787 (class 0 OID 0)
-- Dependencies: 214
-- Name: application_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.application_types_id_seq OWNED BY public.application_types.id;


--
-- TOC entry 225 (class 1259 OID 17905)
-- Name: applications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.applications (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    description character varying NOT NULL,
    start_date timestamp with time zone NOT NULL,
    execution_end_date timestamp with time zone NOT NULL,
    application_status integer NOT NULL,
    employees integer NOT NULL,
    application_type integer NOT NULL
);


ALTER TABLE public.applications OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 17904)
-- Name: applications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.applications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.applications_id_seq OWNER TO postgres;

--
-- TOC entry 3792 (class 0 OID 0)
-- Dependencies: 224
-- Name: applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.applications_id_seq OWNED BY public.applications.id;


--
-- TOC entry 256 (class 1259 OID 18317)
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    log_id integer NOT NULL,
    operation_type character(1) NOT NULL,
    table_name text NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    changed_by text DEFAULT CURRENT_USER
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 18316)
-- Name: audit_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_log_log_id_seq OWNER TO postgres;

--
-- TOC entry 3794 (class 0 OID 0)
-- Dependencies: 255
-- Name: audit_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_log_id_seq OWNED BY public.audit_log.log_id;


--
-- TOC entry 229 (class 1259 OID 17947)
-- Name: buildings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.buildings (
    id integer NOT NULL,
    area character varying(70) NOT NULL,
    city character varying(70),
    community character varying(70),
    street character varying(70),
    house character varying(20),
    body character varying(20),
    electricity_accounting_system integer NOT NULL
);


ALTER TABLE public.buildings OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 17946)
-- Name: buildings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.buildings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.buildings_id_seq OWNER TO postgres;

--
-- TOC entry 3800 (class 0 OID 0)
-- Dependencies: 228
-- Name: buildings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.buildings_id_seq OWNED BY public.buildings.id;


--
-- TOC entry 217 (class 1259 OID 17856)
-- Name: consumers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.consumers (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    surname character varying(70) NOT NULL,
    patronymic character varying(70),
    phone character varying(10),
    last_interaction date
);


ALTER TABLE public.consumers OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 17855)
-- Name: consumers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.consumers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.consumers_id_seq OWNER TO postgres;

--
-- TOC entry 3802 (class 0 OID 0)
-- Dependencies: 216
-- Name: consumers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.consumers_id_seq OWNED BY public.consumers.id;


--
-- TOC entry 227 (class 1259 OID 17931)
-- Name: electricity_accounting_systems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.electricity_accounting_systems (
    id integer NOT NULL,
    name character varying(32) NOT NULL,
    accuracy_class integer NOT NULL,
    installation_date timestamp with time zone NOT NULL,
    responsible integer NOT NULL
);


ALTER TABLE public.electricity_accounting_systems OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 17930)
-- Name: electricity_accounting_systems_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.electricity_accounting_systems_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.electricity_accounting_systems_id_seq OWNER TO postgres;

--
-- TOC entry 3806 (class 0 OID 0)
-- Dependencies: 226
-- Name: electricity_accounting_systems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.electricity_accounting_systems_id_seq OWNED BY public.electricity_accounting_systems.id;


--
-- TOC entry 254 (class 1259 OID 18239)
-- Name: employee_audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee_audit_logs (
    id integer NOT NULL,
    employee_id integer,
    previous_data jsonb,
    new_data jsonb,
    changed_on date
);


ALTER TABLE public.employee_audit_logs OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 18238)
-- Name: employee_audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_audit_logs_id_seq OWNER TO postgres;

--
-- TOC entry 3808 (class 0 OID 0)
-- Dependencies: 253
-- Name: employee_audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employee_audit_logs_id_seq OWNED BY public.employee_audit_logs.id;


--
-- TOC entry 223 (class 1259 OID 17889)
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    surname character varying(70) NOT NULL,
    patronymic character varying(70),
    phone character varying(10),
    dob timestamp with time zone NOT NULL,
    hire_date timestamp with time zone NOT NULL,
    "position" integer NOT NULL
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 17888)
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employees_id_seq OWNER TO postgres;

--
-- TOC entry 3810 (class 0 OID 0)
-- Dependencies: 222
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employees_id_seq OWNED BY public.employees.id;


--
-- TOC entry 245 (class 1259 OID 18098)
-- Name: equipment_checks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment_checks (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    condition_description character varying NOT NULL,
    date_inspection timestamp with time zone NOT NULL,
    equipment_condition integer NOT NULL,
    equipment integer NOT NULL
);


ALTER TABLE public.equipment_checks OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 18097)
-- Name: equipment_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipment_checks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.equipment_checks_id_seq OWNER TO postgres;

--
-- TOC entry 3812 (class 0 OID 0)
-- Dependencies: 244
-- Name: equipment_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipment_checks_id_seq OWNED BY public.equipment_checks.id;


--
-- TOC entry 219 (class 1259 OID 17868)
-- Name: equipment_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment_conditions (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    criticality integer NOT NULL,
    CONSTRAINT check_criticality_range CHECK (((criticality >= 1) AND (criticality <= 10)))
);


ALTER TABLE public.equipment_conditions OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 17867)
-- Name: equipment_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipment_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.equipment_conditions_id_seq OWNER TO postgres;

--
-- TOC entry 3814 (class 0 OID 0)
-- Dependencies: 218
-- Name: equipment_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipment_conditions_id_seq OWNED BY public.equipment_conditions.id;


--
-- TOC entry 237 (class 1259 OID 18023)
-- Name: equipments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipments (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    description character varying NOT NULL,
    installation_date timestamp with time zone NOT NULL,
    inspection_period interval NOT NULL,
    technical_certificate character varying NOT NULL,
    transformer_point integer NOT NULL
);


ALTER TABLE public.equipments OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 18022)
-- Name: equipments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.equipments_id_seq OWNER TO postgres;

--
-- TOC entry 3816 (class 0 OID 0)
-- Dependencies: 236
-- Name: equipments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipments_id_seq OWNED BY public.equipments.id;


--
-- TOC entry 231 (class 1259 OID 17963)
-- Name: living_quarters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.living_quarters (
    id integer NOT NULL,
    building integer NOT NULL,
    entrance character varying(70) NOT NULL,
    floor integer NOT NULL,
    apartment character varying NOT NULL,
    living_space double precision NOT NULL,
    commercial boolean NOT NULL,
    electricity_accounting_system integer NOT NULL
);


ALTER TABLE public.living_quarters OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 18040)
-- Name: living_quarters_consumers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.living_quarters_consumers (
    id integer NOT NULL,
    consumer integer NOT NULL,
    living_quarter integer NOT NULL
);


ALTER TABLE public.living_quarters_consumers OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 18039)
-- Name: living_quarters_consumers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.living_quarters_consumers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.living_quarters_consumers_id_seq OWNER TO postgres;

--
-- TOC entry 3824 (class 0 OID 0)
-- Dependencies: 238
-- Name: living_quarters_consumers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.living_quarters_consumers_id_seq OWNED BY public.living_quarters_consumers.id;


--
-- TOC entry 230 (class 1259 OID 17962)
-- Name: living_quarters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.living_quarters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.living_quarters_id_seq OWNER TO postgres;

--
-- TOC entry 3825 (class 0 OID 0)
-- Dependencies: 230
-- Name: living_quarters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.living_quarters_id_seq OWNED BY public.living_quarters.id;


--
-- TOC entry 241 (class 1259 OID 18062)
-- Name: meter_readings_v1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.meter_readings_v1 (
    id integer NOT NULL,
    daily_readings integer NOT NULL,
    night_readings integer NOT NULL,
    date_application timestamp with time zone NOT NULL,
    living_quarter integer NOT NULL
);


ALTER TABLE public.meter_readings_v1 OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 18061)
-- Name: meter_readings_v1_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.meter_readings_v1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.meter_readings_v1_id_seq OWNER TO postgres;

--
-- TOC entry 3827 (class 0 OID 0)
-- Dependencies: 240
-- Name: meter_readings_v1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.meter_readings_v1_id_seq OWNED BY public.meter_readings_v1.id;


--
-- TOC entry 233 (class 1259 OID 17987)
-- Name: meter_readings_v2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.meter_readings_v2 (
    id integer NOT NULL,
    daily_readings integer NOT NULL,
    night_readings integer NOT NULL,
    date_application timestamp with time zone NOT NULL,
    building integer NOT NULL
);


ALTER TABLE public.meter_readings_v2 OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 17986)
-- Name: meter_readings_v2_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.meter_readings_v2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.meter_readings_v2_id_seq OWNER TO postgres;

--
-- TOC entry 3829 (class 0 OID 0)
-- Dependencies: 232
-- Name: meter_readings_v2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.meter_readings_v2_id_seq OWNED BY public.meter_readings_v2.id;


--
-- TOC entry 221 (class 1259 OID 17879)
-- Name: positions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.positions (
    id integer NOT NULL,
    name character varying(70) NOT NULL
);


ALTER TABLE public.positions OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 17878)
-- Name: positions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.positions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.positions_id_seq OWNER TO postgres;

--
-- TOC entry 3831 (class 0 OID 0)
-- Dependencies: 220
-- Name: positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.positions_id_seq OWNED BY public.positions.id;


--
-- TOC entry 252 (class 1259 OID 18221)
-- Name: total_usage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.total_usage (
    sum bigint
);


ALTER TABLE public.total_usage OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 18078)
-- Name: transformer_point_buildings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transformer_point_buildings (
    id integer NOT NULL,
    transformer_point integer NOT NULL,
    building integer NOT NULL,
    connection_date timestamp with time zone NOT NULL
);


ALTER TABLE public.transformer_point_buildings OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 18077)
-- Name: transformer_point_buildings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transformer_point_buildings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transformer_point_buildings_id_seq OWNER TO postgres;

--
-- TOC entry 3834 (class 0 OID 0)
-- Dependencies: 242
-- Name: transformer_point_buildings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transformer_point_buildings_id_seq OWNED BY public.transformer_point_buildings.id;


--
-- TOC entry 235 (class 1259 OID 18003)
-- Name: transformer_points; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transformer_points (
    id integer NOT NULL,
    building integer NOT NULL,
    responsible integer NOT NULL
);


ALTER TABLE public.transformer_points OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 18002)
-- Name: transformer_points_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transformer_points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transformer_points_id_seq OWNER TO postgres;

--
-- TOC entry 3836 (class 0 OID 0)
-- Dependencies: 234
-- Name: transformer_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transformer_points_id_seq OWNED BY public.transformer_points.id;


--
-- TOC entry 247 (class 1259 OID 18132)
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_tokens (
    id uuid NOT NULL,
    token character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.user_tokens OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 18118)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    username character varying(70) NOT NULL,
    password_hash character varying(255) NOT NULL,
    email character varying(70) NOT NULL,
    employee integer NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 18207)
-- Name: vw_application_status; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_application_status AS
 SELECT a.id,
    a.name,
    a.description,
    a.start_date,
    a.execution_end_date,
    st.name AS status,
    et.name AS type,
    (((emp.name)::text || ' '::text) || (emp.surname)::text) AS employee_responsible
   FROM (((public.applications a
     JOIN public.application_statuses st ON ((a.application_status = st.id)))
     JOIN public.application_types et ON ((a.application_type = et.id)))
     JOIN public.employees emp ON ((a.employees = emp.id)));


ALTER TABLE public.vw_application_status OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 18212)
-- Name: vw_building_energy_usage; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_building_energy_usage AS
SELECT
    NULL::integer AS id,
    NULL::character varying(70) AS area,
    NULL::character varying(70) AS city,
    NULL::bigint AS total_energy_usage;


ALTER TABLE public.vw_building_energy_usage OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 18203)
-- Name: vw_employee_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_employee_details AS
 SELECT e.id,
    e.name,
    e.surname,
    e.patronymic,
    e.phone,
    e.dob,
    e.hire_date,
    p.name AS position_name
   FROM (public.employees e
     JOIN public.positions p ON ((e."position" = p.id)));


ALTER TABLE public.vw_employee_details OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 18216)
-- Name: vw_equipment_maintenance_schedule; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_equipment_maintenance_schedule AS
 SELECT eq.id,
    eq.name,
    eq.description,
    eq.installation_date,
    eq.inspection_period,
    eq.technical_certificate,
    tp.id AS transformer_point_id,
    ec.name AS condition
   FROM ((public.equipments eq
     JOIN public.transformer_points tp ON ((eq.transformer_point = tp.id)))
     JOIN public.equipment_conditions ec ON ((eq.id = ec.id)));


ALTER TABLE public.vw_equipment_maintenance_schedule OWNER TO postgres;

--
-- TOC entry 3427 (class 2604 OID 17837)
-- Name: application_statuses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_statuses ALTER COLUMN id SET DEFAULT nextval('public.application_statuses_id_seq'::regclass);


--
-- TOC entry 3428 (class 2604 OID 17847)
-- Name: application_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_types ALTER COLUMN id SET DEFAULT nextval('public.application_types_id_seq'::regclass);


--
-- TOC entry 3434 (class 2604 OID 17908)
-- Name: applications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applications ALTER COLUMN id SET DEFAULT nextval('public.applications_id_seq'::regclass);


--
-- TOC entry 3446 (class 2604 OID 18320)
-- Name: audit_log log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN log_id SET DEFAULT nextval('public.audit_log_log_id_seq'::regclass);


--
-- TOC entry 3436 (class 2604 OID 17950)
-- Name: buildings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buildings ALTER COLUMN id SET DEFAULT nextval('public.buildings_id_seq'::regclass);


--
-- TOC entry 3429 (class 2604 OID 17859)
-- Name: consumers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consumers ALTER COLUMN id SET DEFAULT nextval('public.consumers_id_seq'::regclass);


--
-- TOC entry 3435 (class 2604 OID 17934)
-- Name: electricity_accounting_systems id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.electricity_accounting_systems ALTER COLUMN id SET DEFAULT nextval('public.electricity_accounting_systems_id_seq'::regclass);


--
-- TOC entry 3445 (class 2604 OID 18242)
-- Name: employee_audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_audit_logs ALTER COLUMN id SET DEFAULT nextval('public.employee_audit_logs_id_seq'::regclass);


--
-- TOC entry 3433 (class 2604 OID 17892)
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_id_seq'::regclass);


--
-- TOC entry 3444 (class 2604 OID 18101)
-- Name: equipment_checks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_checks ALTER COLUMN id SET DEFAULT nextval('public.equipment_checks_id_seq'::regclass);


--
-- TOC entry 3430 (class 2604 OID 17871)
-- Name: equipment_conditions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_conditions ALTER COLUMN id SET DEFAULT nextval('public.equipment_conditions_id_seq'::regclass);


--
-- TOC entry 3440 (class 2604 OID 18026)
-- Name: equipments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments ALTER COLUMN id SET DEFAULT nextval('public.equipments_id_seq'::regclass);


--
-- TOC entry 3437 (class 2604 OID 17966)
-- Name: living_quarters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters ALTER COLUMN id SET DEFAULT nextval('public.living_quarters_id_seq'::regclass);


--
-- TOC entry 3441 (class 2604 OID 18043)
-- Name: living_quarters_consumers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters_consumers ALTER COLUMN id SET DEFAULT nextval('public.living_quarters_consumers_id_seq'::regclass);


--
-- TOC entry 3442 (class 2604 OID 18065)
-- Name: meter_readings_v1 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v1 ALTER COLUMN id SET DEFAULT nextval('public.meter_readings_v1_id_seq'::regclass);


--
-- TOC entry 3438 (class 2604 OID 17990)
-- Name: meter_readings_v2 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v2 ALTER COLUMN id SET DEFAULT nextval('public.meter_readings_v2_id_seq'::regclass);


--
-- TOC entry 3432 (class 2604 OID 17882)
-- Name: positions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions ALTER COLUMN id SET DEFAULT nextval('public.positions_id_seq'::regclass);


--
-- TOC entry 3443 (class 2604 OID 18081)
-- Name: transformer_point_buildings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_point_buildings ALTER COLUMN id SET DEFAULT nextval('public.transformer_point_buildings_id_seq'::regclass);


--
-- TOC entry 3439 (class 2604 OID 18006)
-- Name: transformer_points id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_points ALTER COLUMN id SET DEFAULT nextval('public.transformer_points_id_seq'::regclass);


--
-- TOC entry 3734 (class 0 OID 17828)
-- Dependencies: 211
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
166351ff65fa
\.


--
-- TOC entry 3736 (class 0 OID 17834)
-- Dependencies: 213
-- Data for Name: application_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.application_statuses (id, name) FROM stdin;
1	Новая
2	В обработке
3	На рассмотрении
4	Одобрена
5	Отклонена
6	Отложена
7	Требует дополнительной информации
8	Завершена
\.


--
-- TOC entry 3738 (class 0 OID 17844)
-- Dependencies: 215
-- Data for Name: application_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.application_types (id, name, type) FROM stdin;
5	Замена счетчика	Техническая услуга
6	Отключение электроэнергии	Экстренная операция
7	Подключение нового объекта	Техническая услуга
8	Ремонт линий электропередач	Техническая услуга
9	Техническое обслуживание	Плановая проверка
10	Перерасчет платежей	Финансовая операция
11	Жалоба на качество обслуживания	Клиентская поддержка
12	Запрос технической документации	Информационная услуга
13	Изменение тарифного плана	Контрактная операция
14	Установка дополнительного оборудования	Техническая услуга
\.


--
-- TOC entry 3748 (class 0 OID 17905)
-- Dependencies: 225
-- Data for Name: applications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.applications (id, name, description, start_date, execution_end_date, application_status, employees, application_type) FROM stdin;
101	нг	реновация	2024-05-08 09:52:30.362+00	2024-05-10 09:52:36.251+00	8	1	5
\.


--
-- TOC entry 3775 (class 0 OID 18317)
-- Dependencies: 256
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (log_id, operation_type, table_name, old_data, new_data, changed_at, changed_by) FROM stdin;
1	U	users	{"id": "86f3b5fe-7a85-41e4-a8a3-95ab233456a4", "email": "rtrtrtrt1", "employee": 7, "username": "login12", "password_hash": "$2a$08$Pr4txk39E9b.426v/AeLIugWSvz8rW5XWHP0ZxbiYZO3U5Ng.FEp6"}	{"id": "86f3b5fe-7a85-41e4-a8a3-95ab233456a4", "email": "rtrtrtrt1", "employee": 7, "username": "login14", "password_hash": "$2a$08$Pr4txk39E9b.426v/AeLIugWSvz8rW5XWHP0ZxbiYZO3U5Ng.FEp6"}	2024-05-10 08:35:17.039248+00	postgres
2	I	users	\N	{"id": "f50b5a31-124a-49ed-8069-ff04590ebf56", "email": "rt@gmail.com", "employee": 8, "username": "login", "password_hash": "$2a$08$YKTB7BoTR8woJVWBiJrxJO.wFF17Ke.6/BP.8colJ8bHiqMTy9EZm"}	2024-05-10 09:17:45.642636+00	postgres
4	U	employees	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 3", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 4", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	2024-05-10 09:38:11.805235+00	postgres
5	U	employees	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 4", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 4", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	2024-05-10 09:39:00.535276+00	postgres
6	U	employees	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 4", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 4", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	2024-05-10 09:39:00.535276+00	postgres
7	I	users	\N	{"id": "9d0a9cf3-45e9-46ed-a64b-117ef857a15a", "email": "rt2@gmail.com", "employee": 9, "username": "login20", "password_hash": "$2a$08$IU16EK0KmjdR0CNSjRJfvu.SG.VSlpsoxl6ROQVPUj4ueYY.yFKhW"}	2024-05-10 09:40:14.6524+00	postgres
\.


--
-- TOC entry 3752 (class 0 OID 17947)
-- Dependencies: 229
-- Data for Name: buildings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.buildings (id, area, city, community, street, house, body, electricity_accounting_system) FROM stdin;
3	г	СПБ	\N	Строителей	3	\N	3
4	г	СПБ	\N	Строителей	4	\N	4
6	г	СПБ	\N	Строителей	4	2	7
\.


--
-- TOC entry 3740 (class 0 OID 17856)
-- Dependencies: 217
-- Data for Name: consumers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.consumers (id, name, surname, patronymic, phone, last_interaction) FROM stdin;
1	Иван	Иванов	Иванович	345678	\N
\.


--
-- TOC entry 3750 (class 0 OID 17931)
-- Dependencies: 227
-- Data for Name: electricity_accounting_systems; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.electricity_accounting_systems (id, name, accuracy_class, installation_date, responsible) FROM stdin;
3	rty-0000	3	2020-02-12 09:41:05.42+00	1
4	rty-0001	3	2022-04-02 09:41:26.31+00	1
5	rty-0004	3	2022-04-02 09:41:26.31+00	1
7	rty-0005	3	2022-04-02 09:41:26.31+00	2
\.


--
-- TOC entry 3773 (class 0 OID 18239)
-- Dependencies: 254
-- Data for Name: employee_audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee_audit_logs (id, employee_id, previous_data, new_data, changed_on) FROM stdin;
1	1	{"id": 1, "dob": "1994-11-04T00:00:00+00:00", "name": "Михаил", "phone": "7865314435", "surname": "Морозов", "position": 1, "hire_date": "2004-08-20T00:00:00+00:00", "patronymic": "Андреевич"}	{"id": 1, "dob": "1994-11-04T00:00:00+00:00", "name": "Михаил", "phone": "7865314435", "surname": "Морозов1", "position": 1, "hire_date": "2004-08-20T00:00:00+00:00", "patronymic": "Андреевич"}	2024-05-10
2	2	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 3", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	2024-05-10
3	2	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 3", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	{"id": 2, "dob": "1985-08-27T00:00:00+00:00", "name": "Мария", "phone": "7865170955", "surname": "Фролова 4", "position": 1, "hire_date": "2012-01-27T00:00:00+00:00", "patronymic": "Александровна"}	2024-05-10
\.


--
-- TOC entry 3746 (class 0 OID 17889)
-- Dependencies: 223
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (id, name, surname, patronymic, phone, dob, hire_date, "position") FROM stdin;
3	Макар	Никитин	Даниилович	7865679074	1980-12-01 00:00:00+00	2006-08-21 00:00:00+00	1
4	Ариана	Коновалова	Романовна	7865319947	1991-03-13 00:00:00+00	2004-07-13 00:00:00+00	1
5	Юлия	Полякова	Константиновна	7865406964	1999-03-24 00:00:00+00	2002-11-04 00:00:00+00	1
6	Ксения	Бочарова	Григорьевна	7865907442	1988-03-10 00:00:00+00	2004-11-23 00:00:00+00	1
7	Вера	Алексеева	Платоновна	7865767550	1997-11-19 00:00:00+00	2010-06-30 00:00:00+00	1
8	Эмма	Ильина	Глебовна	7865813256	1991-07-04 00:00:00+00	2007-08-17 00:00:00+00	1
9	Леонид	Гончаров	Захарович	7865469600	1990-12-13 00:00:00+00	2009-09-22 00:00:00+00	1
10	Андрей	Петров	Викторович	7865079155	1989-08-23 00:00:00+00	2003-12-29 00:00:00+00	1
11	Григорий	Пастухов	Артёмович	7865445070	1996-12-25 00:00:00+00	2004-03-01 00:00:00+00	1
12	Артур	Колесов	Владимирович	7865487435	1999-10-18 00:00:00+00	2009-08-14 00:00:00+00	1
13	Арина	Чернова	Игоревна	7865807436	1982-05-04 00:00:00+00	2007-02-08 00:00:00+00	1
14	Анна	Ковалева	Ярославовна	7865106176	1991-08-02 00:00:00+00	2008-01-01 00:00:00+00	2
15	Иван	Спиридонов	Тимофеевич	7865051536	1986-04-07 00:00:00+00	2005-03-17 00:00:00+00	2
16	Вера	Денисова	Львовна	7865676230	1986-01-24 00:00:00+00	2008-08-20 00:00:00+00	2
17	Захар	Захаров	Никитич	7865521190	1998-12-14 00:00:00+00	2010-04-06 00:00:00+00	2
18	Кирилл	Ткачев	Иванович	7865019661	2000-01-12 00:00:00+00	2005-09-23 00:00:00+00	2
19	Юлия	Власова	Ивановна	7865951044	1987-06-15 00:00:00+00	2006-02-15 00:00:00+00	2
20	Алёна	Медведева	Степановна	7865977927	2000-02-10 00:00:00+00	2007-02-14 00:00:00+00	2
1	Михаил	Морозов1	Андреевич	7865314435	1994-11-04 00:00:00+00	2004-08-20 00:00:00+00	1
2	Мария	Фролова 4	Александровна	7865170955	1985-08-27 00:00:00+00	2012-01-27 00:00:00+00	1
\.


--
-- TOC entry 3768 (class 0 OID 18098)
-- Dependencies: 245
-- Data for Name: equipment_checks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipment_checks (id, name, condition_description, date_inspection, equipment_condition, equipment) FROM stdin;
\.


--
-- TOC entry 3742 (class 0 OID 17868)
-- Dependencies: 219
-- Data for Name: equipment_conditions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipment_conditions (id, name, criticality) FROM stdin;
3	11	5
4	12	5
6	new	1
\.


--
-- TOC entry 3760 (class 0 OID 18023)
-- Dependencies: 237
-- Data for Name: equipments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipments (id, name, description, installation_date, inspection_period, technical_certificate, transformer_point) FROM stdin;
\.


--
-- TOC entry 3754 (class 0 OID 17963)
-- Dependencies: 231
-- Data for Name: living_quarters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.living_quarters (id, building, entrance, floor, apartment, living_space, commercial, electricity_accounting_system) FROM stdin;
1	3	2	1	1	30	f	5
\.


--
-- TOC entry 3762 (class 0 OID 18040)
-- Dependencies: 239
-- Data for Name: living_quarters_consumers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.living_quarters_consumers (id, consumer, living_quarter) FROM stdin;
\.


--
-- TOC entry 3764 (class 0 OID 18062)
-- Dependencies: 241
-- Data for Name: meter_readings_v1; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meter_readings_v1 (id, daily_readings, night_readings, date_application, living_quarter) FROM stdin;
1	150	120	2024-05-09 21:00:00+00	1
\.


--
-- TOC entry 3756 (class 0 OID 17987)
-- Dependencies: 233
-- Data for Name: meter_readings_v2; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meter_readings_v2 (id, daily_readings, night_readings, date_application, building) FROM stdin;
1	1000	500	2024-05-10 10:16:57.61+00	3
2	1000	500	2024-05-10 10:16:57.61+00	4
\.


--
-- TOC entry 3744 (class 0 OID 17879)
-- Dependencies: 221
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.positions (id, name) FROM stdin;
1	Электро-монтажник
2	Бугалтер
3	Администратор баз данных
\.


--
-- TOC entry 3771 (class 0 OID 18221)
-- Dependencies: 252
-- Data for Name: total_usage; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.total_usage (sum) FROM stdin;
\N
\.


--
-- TOC entry 3766 (class 0 OID 18078)
-- Dependencies: 243
-- Data for Name: transformer_point_buildings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transformer_point_buildings (id, transformer_point, building, connection_date) FROM stdin;
2	1	3	2024-05-10 10:20:29.747+00
\.


--
-- TOC entry 3758 (class 0 OID 18003)
-- Dependencies: 235
-- Data for Name: transformer_points; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transformer_points (id, building, responsible) FROM stdin;
1	6	5
\.


--
-- TOC entry 3770 (class 0 OID 18132)
-- Dependencies: 247
-- Data for Name: user_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_tokens (id, token, user_id, created_at) FROM stdin;
4bf5cc2a-bc75-4e4e-a879-cdd6aadc1335	0cf565b6d6b643d18d6a81175bd082a9	15c997b0-005d-40a0-90b7-7d9f47f96fda	2024-04-24 09:32:03.012991+00
3630dd79-9999-4fb3-b383-de1bf0935c0c	95fff4e9b9d84973b599b46badb405c2	34bdaa12-7895-4aee-91ad-91b8b2211b09	2024-04-24 15:12:31.816063+00
\.


--
-- TOC entry 3769 (class 0 OID 18118)
-- Dependencies: 246
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password_hash, email, employee) FROM stdin;
15c997b0-005d-40a0-90b7-7d9f47f96fda	Login	eXz07opZX2OXU3xk$/z55.k94wWJNvbACqsJUYeEY95KgBQeTip.7PEs70LoZE3n7lR1HwPIfUQmKosBKnYt1x3kFlJNDCqp2EryfG/	111111	1
34bdaa12-7895-4aee-91ad-91b8b2211b09	Login2	eXz07opZX2OXU3xk$/z55.k94wWJNvbACqsJUYeEY95KgBQeTip.7PEs70LoZE3n7lR1HwPIfUQmKosBKnYt1x3kFlJNDCqp2EryfG/	222222	2
65310dcd-2c16-4c69-b2fd-0cbf2cbcc6ad	Login3	eXz07opZX2OXU3xk$/z55.k94wWJNvbACqsJUYeEY95KgBQeTip.7PEs70LoZE3n7lR1HwPIfUQmKosBKnYt1x3kFlJNDCqp2EryfG/	333333	3
3c66cb41-a741-4bf5-8e5e-ab343744def2	Login4	eXz07opZX2OXU3xk$/z55.k94wWJNvbACqsJUYeEY95KgBQeTip.7PEs70LoZE3n7lR1HwPIfUQmKosBKnYt1x3kFlJNDCqp2EryfG/	444444	4
36b42d55-22e5-4bc8-8c48-e27cad2e3574	login10	$2a$08$gkFDZuhfa5ewq44/eszINePYwrEit8ujvFjFC4Pmp7E7Yo42ubbiS	rtrtrtrt	6
86f3b5fe-7a85-41e4-a8a3-95ab233456a4	login14	$2a$08$Pr4txk39E9b.426v/AeLIugWSvz8rW5XWHP0ZxbiYZO3U5Ng.FEp6	rtrtrtrt1	7
f50b5a31-124a-49ed-8069-ff04590ebf56	login	$2a$08$YKTB7BoTR8woJVWBiJrxJO.wFF17Ke.6/BP.8colJ8bHiqMTy9EZm	rt@gmail.com	8
9d0a9cf3-45e9-46ed-a64b-117ef857a15a	login20	$2a$08$IU16EK0KmjdR0CNSjRJfvu.SG.VSlpsoxl6ROQVPUj4ueYY.yFKhW	rt2@gmail.com	9
\.


--
-- TOC entry 3843 (class 0 OID 0)
-- Dependencies: 212
-- Name: application_statuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.application_statuses_id_seq', 8, true);


--
-- TOC entry 3844 (class 0 OID 0)
-- Dependencies: 214
-- Name: application_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.application_types_id_seq', 14, true);


--
-- TOC entry 3845 (class 0 OID 0)
-- Dependencies: 224
-- Name: applications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.applications_id_seq', 1, false);


--
-- TOC entry 3846 (class 0 OID 0)
-- Dependencies: 255
-- Name: audit_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_log_id_seq', 7, true);


--
-- TOC entry 3847 (class 0 OID 0)
-- Dependencies: 228
-- Name: buildings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.buildings_id_seq', 6, true);


--
-- TOC entry 3848 (class 0 OID 0)
-- Dependencies: 216
-- Name: consumers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.consumers_id_seq', 1, true);


--
-- TOC entry 3849 (class 0 OID 0)
-- Dependencies: 226
-- Name: electricity_accounting_systems_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.electricity_accounting_systems_id_seq', 7, true);


--
-- TOC entry 3850 (class 0 OID 0)
-- Dependencies: 253
-- Name: employee_audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_audit_logs_id_seq', 3, true);


--
-- TOC entry 3851 (class 0 OID 0)
-- Dependencies: 222
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_id_seq', 23, true);


--
-- TOC entry 3852 (class 0 OID 0)
-- Dependencies: 244
-- Name: equipment_checks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_checks_id_seq', 1, false);


--
-- TOC entry 3853 (class 0 OID 0)
-- Dependencies: 218
-- Name: equipment_conditions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_conditions_id_seq', 1, false);


--
-- TOC entry 3854 (class 0 OID 0)
-- Dependencies: 236
-- Name: equipments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipments_id_seq', 1, false);


--
-- TOC entry 3855 (class 0 OID 0)
-- Dependencies: 238
-- Name: living_quarters_consumers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.living_quarters_consumers_id_seq', 1, false);


--
-- TOC entry 3856 (class 0 OID 0)
-- Dependencies: 230
-- Name: living_quarters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.living_quarters_id_seq', 1, true);


--
-- TOC entry 3857 (class 0 OID 0)
-- Dependencies: 240
-- Name: meter_readings_v1_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.meter_readings_v1_id_seq', 1, false);


--
-- TOC entry 3858 (class 0 OID 0)
-- Dependencies: 232
-- Name: meter_readings_v2_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.meter_readings_v2_id_seq', 2, true);


--
-- TOC entry 3859 (class 0 OID 0)
-- Dependencies: 220
-- Name: positions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.positions_id_seq', 1, false);


--
-- TOC entry 3860 (class 0 OID 0)
-- Dependencies: 242
-- Name: transformer_point_buildings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transformer_point_buildings_id_seq', 2, true);


--
-- TOC entry 3861 (class 0 OID 0)
-- Dependencies: 234
-- Name: transformer_points_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transformer_points_id_seq', 1, true);


--
-- TOC entry 3450 (class 2606 OID 17832)
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- TOC entry 3452 (class 2606 OID 17841)
-- Name: application_statuses application_statuses_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_statuses
    ADD CONSTRAINT application_statuses_name_key UNIQUE (name);


--
-- TOC entry 3454 (class 2606 OID 17839)
-- Name: application_statuses application_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_statuses
    ADD CONSTRAINT application_statuses_pkey PRIMARY KEY (id);


--
-- TOC entry 3457 (class 2606 OID 17851)
-- Name: application_types application_types_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_types
    ADD CONSTRAINT application_types_name_key UNIQUE (name);


--
-- TOC entry 3459 (class 2606 OID 18147)
-- Name: application_types application_types_name_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_types
    ADD CONSTRAINT application_types_name_type_key UNIQUE (name, type);


--
-- TOC entry 3461 (class 2606 OID 17849)
-- Name: application_types application_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_types
    ADD CONSTRAINT application_types_pkey PRIMARY KEY (id);


--
-- TOC entry 3487 (class 2606 OID 17912)
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- TOC entry 3560 (class 2606 OID 18326)
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 3497 (class 2606 OID 17952)
-- Name: buildings buildings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buildings
    ADD CONSTRAINT buildings_pkey PRIMARY KEY (id);


--
-- TOC entry 3464 (class 2606 OID 17863)
-- Name: consumers consumers_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT consumers_phone_key UNIQUE (phone);


--
-- TOC entry 3466 (class 2606 OID 17861)
-- Name: consumers consumers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT consumers_pkey PRIMARY KEY (id);


--
-- TOC entry 3491 (class 2606 OID 17938)
-- Name: electricity_accounting_systems electricity_accounting_systems_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.electricity_accounting_systems
    ADD CONSTRAINT electricity_accounting_systems_name_key UNIQUE (name);


--
-- TOC entry 3493 (class 2606 OID 17936)
-- Name: electricity_accounting_systems electricity_accounting_systems_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.electricity_accounting_systems
    ADD CONSTRAINT electricity_accounting_systems_pkey PRIMARY KEY (id);


--
-- TOC entry 3558 (class 2606 OID 18244)
-- Name: employee_audit_logs employee_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_audit_logs
    ADD CONSTRAINT employee_audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 3481 (class 2606 OID 17896)
-- Name: employees employees_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_phone_key UNIQUE (phone);


--
-- TOC entry 3483 (class 2606 OID 17894)
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- TOC entry 3544 (class 2606 OID 18105)
-- Name: equipment_checks equipment_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_checks
    ADD CONSTRAINT equipment_checks_pkey PRIMARY KEY (id);


--
-- TOC entry 3471 (class 2606 OID 17874)
-- Name: equipment_conditions equipment_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_conditions
    ADD CONSTRAINT equipment_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 3521 (class 2606 OID 18030)
-- Name: equipments equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipments_pkey PRIMARY KEY (id);


--
-- TOC entry 3529 (class 2606 OID 18045)
-- Name: living_quarters_consumers living_quarters_consumers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters_consumers
    ADD CONSTRAINT living_quarters_consumers_pkey PRIMARY KEY (id);


--
-- TOC entry 3506 (class 2606 OID 17970)
-- Name: living_quarters living_quarters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters
    ADD CONSTRAINT living_quarters_pkey PRIMARY KEY (id);


--
-- TOC entry 3535 (class 2606 OID 18067)
-- Name: meter_readings_v1 meter_readings_v1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v1
    ADD CONSTRAINT meter_readings_v1_pkey PRIMARY KEY (id);


--
-- TOC entry 3512 (class 2606 OID 17992)
-- Name: meter_readings_v2 meter_readings_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v2
    ADD CONSTRAINT meter_readings_v2_pkey PRIMARY KEY (id);


--
-- TOC entry 3477 (class 2606 OID 17886)
-- Name: positions positions_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_name_key UNIQUE (name);


--
-- TOC entry 3479 (class 2606 OID 17884)
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- TOC entry 3542 (class 2606 OID 18083)
-- Name: transformer_point_buildings transformer_point_buildings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_point_buildings
    ADD CONSTRAINT transformer_point_buildings_pkey PRIMARY KEY (id);


--
-- TOC entry 3519 (class 2606 OID 18008)
-- Name: transformer_points transformer_points_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_points
    ADD CONSTRAINT transformer_points_pkey PRIMARY KEY (id);


--
-- TOC entry 3501 (class 2606 OID 17954)
-- Name: buildings uq_addresses; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buildings
    ADD CONSTRAINT uq_addresses UNIQUE (area, city, community, street, house, body);


--
-- TOC entry 3469 (class 2606 OID 17865)
-- Name: consumers uq_consumers; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT uq_consumers UNIQUE (name, surname, patronymic, phone);


--
-- TOC entry 3508 (class 2606 OID 17972)
-- Name: living_quarters uq_living_quarters; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters
    ADD CONSTRAINT uq_living_quarters UNIQUE (building, entrance, apartment);


--
-- TOC entry 3531 (class 2606 OID 18047)
-- Name: living_quarters_consumers uq_living_quarters_consumers; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters_consumers
    ADD CONSTRAINT uq_living_quarters_consumers UNIQUE (consumer, living_quarter);


--
-- TOC entry 3537 (class 2606 OID 18069)
-- Name: meter_readings_v1 uq_meter_readings_v1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v1
    ADD CONSTRAINT uq_meter_readings_v1 UNIQUE (date_application, living_quarter);


--
-- TOC entry 3514 (class 2606 OID 17994)
-- Name: meter_readings_v2 uq_meter_readings_v2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v2
    ADD CONSTRAINT uq_meter_readings_v2 UNIQUE (date_application, building);


--
-- TOC entry 3556 (class 2606 OID 18136)
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3550 (class 2606 OID 18124)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3552 (class 2606 OID 18122)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3455 (class 1259 OID 17842)
-- Name: ix_application_statuses_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_application_statuses_id ON public.application_statuses USING btree (id);


--
-- TOC entry 3462 (class 1259 OID 17854)
-- Name: ix_application_types_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_application_types_id ON public.application_types USING btree (id);


--
-- TOC entry 3488 (class 1259 OID 17928)
-- Name: ix_applications_application_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_applications_application_type ON public.applications USING btree (application_type);


--
-- TOC entry 3489 (class 1259 OID 17929)
-- Name: ix_applications_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_applications_id ON public.applications USING btree (id);


--
-- TOC entry 3498 (class 1259 OID 17960)
-- Name: ix_buildings_electricity_accounting_system; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_buildings_electricity_accounting_system ON public.buildings USING btree (electricity_accounting_system);


--
-- TOC entry 3499 (class 1259 OID 17961)
-- Name: ix_buildings_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_buildings_id ON public.buildings USING btree (id);


--
-- TOC entry 3467 (class 1259 OID 17866)
-- Name: ix_consumers_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_consumers_id ON public.consumers USING btree (id);


--
-- TOC entry 3494 (class 1259 OID 17944)
-- Name: ix_electricity_accounting_systems_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_electricity_accounting_systems_id ON public.electricity_accounting_systems USING btree (id);


--
-- TOC entry 3495 (class 1259 OID 17945)
-- Name: ix_electricity_accounting_systems_responsible; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_electricity_accounting_systems_responsible ON public.electricity_accounting_systems USING btree (responsible);


--
-- TOC entry 3484 (class 1259 OID 17902)
-- Name: ix_employees_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_employees_id ON public.employees USING btree (id);


--
-- TOC entry 3485 (class 1259 OID 17903)
-- Name: ix_employees_position; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_employees_position ON public.employees USING btree ("position");


--
-- TOC entry 3545 (class 1259 OID 18116)
-- Name: ix_equipment_checks_equipment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_equipment_checks_equipment ON public.equipment_checks USING btree (equipment);


--
-- TOC entry 3546 (class 1259 OID 18117)
-- Name: ix_equipment_checks_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_equipment_checks_id ON public.equipment_checks USING btree (id);


--
-- TOC entry 3472 (class 1259 OID 17875)
-- Name: ix_equipment_conditions_criticality; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_equipment_conditions_criticality ON public.equipment_conditions USING btree (criticality);


--
-- TOC entry 3473 (class 1259 OID 17876)
-- Name: ix_equipment_conditions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_equipment_conditions_id ON public.equipment_conditions USING btree (id);


--
-- TOC entry 3474 (class 1259 OID 17877)
-- Name: ix_equipment_conditions_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_equipment_conditions_name ON public.equipment_conditions USING btree (name);


--
-- TOC entry 3522 (class 1259 OID 18036)
-- Name: ix_equipments_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_equipments_id ON public.equipments USING btree (id);


--
-- TOC entry 3523 (class 1259 OID 18037)
-- Name: ix_equipments_installation_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_equipments_installation_date ON public.equipments USING btree (installation_date);


--
-- TOC entry 3524 (class 1259 OID 18038)
-- Name: ix_equipments_transformer_point; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_equipments_transformer_point ON public.equipments USING btree (transformer_point);


--
-- TOC entry 3502 (class 1259 OID 17983)
-- Name: ix_living_quarters_building; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_living_quarters_building ON public.living_quarters USING btree (building);


--
-- TOC entry 3525 (class 1259 OID 18058)
-- Name: ix_living_quarters_consumers_consumer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_living_quarters_consumers_consumer ON public.living_quarters_consumers USING btree (consumer);


--
-- TOC entry 3526 (class 1259 OID 18059)
-- Name: ix_living_quarters_consumers_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_living_quarters_consumers_id ON public.living_quarters_consumers USING btree (id);


--
-- TOC entry 3527 (class 1259 OID 18060)
-- Name: ix_living_quarters_consumers_living_quarter; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_living_quarters_consumers_living_quarter ON public.living_quarters_consumers USING btree (living_quarter);


--
-- TOC entry 3503 (class 1259 OID 17984)
-- Name: ix_living_quarters_electricity_accounting_system; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_living_quarters_electricity_accounting_system ON public.living_quarters USING btree (electricity_accounting_system);


--
-- TOC entry 3504 (class 1259 OID 17985)
-- Name: ix_living_quarters_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_living_quarters_id ON public.living_quarters USING btree (id);


--
-- TOC entry 3532 (class 1259 OID 18075)
-- Name: ix_meter_readings_v1_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_meter_readings_v1_id ON public.meter_readings_v1 USING btree (id);


--
-- TOC entry 3533 (class 1259 OID 18076)
-- Name: ix_meter_readings_v1_living_quarter; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_meter_readings_v1_living_quarter ON public.meter_readings_v1 USING btree (living_quarter);


--
-- TOC entry 3509 (class 1259 OID 18000)
-- Name: ix_meter_readings_v2_building; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_meter_readings_v2_building ON public.meter_readings_v2 USING btree (building);


--
-- TOC entry 3510 (class 1259 OID 18001)
-- Name: ix_meter_readings_v2_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_meter_readings_v2_id ON public.meter_readings_v2 USING btree (id);


--
-- TOC entry 3475 (class 1259 OID 17887)
-- Name: ix_positions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_positions_id ON public.positions USING btree (id);


--
-- TOC entry 3538 (class 1259 OID 18094)
-- Name: ix_transformer_point_buildings_building; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transformer_point_buildings_building ON public.transformer_point_buildings USING btree (building);


--
-- TOC entry 3539 (class 1259 OID 18095)
-- Name: ix_transformer_point_buildings_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transformer_point_buildings_id ON public.transformer_point_buildings USING btree (id);


--
-- TOC entry 3540 (class 1259 OID 18096)
-- Name: ix_transformer_point_buildings_transformer_point; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transformer_point_buildings_transformer_point ON public.transformer_point_buildings USING btree (transformer_point);


--
-- TOC entry 3515 (class 1259 OID 18019)
-- Name: ix_transformer_points_building; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_transformer_points_building ON public.transformer_points USING btree (building);


--
-- TOC entry 3516 (class 1259 OID 18020)
-- Name: ix_transformer_points_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transformer_points_id ON public.transformer_points USING btree (id);


--
-- TOC entry 3517 (class 1259 OID 18021)
-- Name: ix_transformer_points_responsible; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transformer_points_responsible ON public.transformer_points USING btree (responsible);


--
-- TOC entry 3553 (class 1259 OID 18142)
-- Name: ix_user_tokens_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_tokens_id ON public.user_tokens USING btree (id);


--
-- TOC entry 3554 (class 1259 OID 18143)
-- Name: ix_user_tokens_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_tokens_user_id ON public.user_tokens USING btree (user_id);


--
-- TOC entry 3547 (class 1259 OID 18130)
-- Name: ix_users_employee; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_employee ON public.users USING btree (employee);


--
-- TOC entry 3548 (class 1259 OID 18131)
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- TOC entry 3732 (class 2618 OID 18215)
-- Name: vw_building_energy_usage _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.vw_building_energy_usage AS
 SELECT b.id,
    b.area,
    b.city,
    sum((m.daily_readings + m.night_readings)) AS total_energy_usage
   FROM (public.buildings b
     JOIN public.meter_readings_v2 m ON ((m.building = b.id)))
  GROUP BY b.id;


--
-- TOC entry 3586 (class 2620 OID 18328)
-- Name: employees employees_table_audit_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER employees_table_audit_trigger AFTER INSERT OR DELETE OR UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- TOC entry 3585 (class 2620 OID 18327)
-- Name: employees example_table_audit_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER example_table_audit_trigger AFTER INSERT OR DELETE OR UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- TOC entry 3588 (class 2620 OID 18315)
-- Name: users example_table_audit_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER example_table_audit_trigger AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- TOC entry 3587 (class 2620 OID 18202)
-- Name: applications trg_application_before_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_application_before_delete BEFORE DELETE ON public.applications FOR EACH ROW EXECUTE FUNCTION public.prevent_application_deletion();


--
-- TOC entry 3582 (class 2620 OID 18200)
-- Name: consumers trg_consumer_after_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_consumer_after_update AFTER UPDATE ON public.consumers FOR EACH ROW EXECUTE FUNCTION public.update_last_interaction();


--
-- TOC entry 3584 (class 2620 OID 18196)
-- Name: employees trg_employee_after_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_employee_after_update AFTER UPDATE ON public.employees FOR EACH ROW WHEN ((((old.name)::text IS DISTINCT FROM (new.name)::text) OR ((old.surname)::text IS DISTINCT FROM (new.surname)::text) OR (old."position" IS DISTINCT FROM new."position"))) EXECUTE FUNCTION public.log_employee_update();


--
-- TOC entry 3583 (class 2620 OID 18198)
-- Name: equipment_conditions trg_equipment_before_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_equipment_before_insert BEFORE INSERT OR UPDATE ON public.equipment_conditions FOR EACH ROW EXECUTE FUNCTION public.check_equipment_criticality();


--
-- TOC entry 3590 (class 2620 OID 18194)
-- Name: user_tokens trg_user_tokens_before_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_user_tokens_before_insert BEFORE INSERT ON public.user_tokens FOR EACH ROW EXECUTE FUNCTION public.user_tokens_before_insert_trg();


--
-- TOC entry 3589 (class 2620 OID 18192)
-- Name: users trg_users_before_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_users_before_insert BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.users_before_insert_trg();


--
-- TOC entry 3562 (class 2606 OID 17913)
-- Name: applications applications_application_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_application_status_fkey FOREIGN KEY (application_status) REFERENCES public.application_statuses(id);


--
-- TOC entry 3564 (class 2606 OID 17923)
-- Name: applications applications_application_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_application_type_fkey FOREIGN KEY (application_type) REFERENCES public.application_types(id);


--
-- TOC entry 3563 (class 2606 OID 17918)
-- Name: applications applications_employees_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_employees_fkey FOREIGN KEY (employees) REFERENCES public.employees(id);


--
-- TOC entry 3566 (class 2606 OID 17955)
-- Name: buildings buildings_electricity_accounting_system_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buildings
    ADD CONSTRAINT buildings_electricity_accounting_system_fkey FOREIGN KEY (electricity_accounting_system) REFERENCES public.electricity_accounting_systems(id);


--
-- TOC entry 3565 (class 2606 OID 17939)
-- Name: electricity_accounting_systems electricity_accounting_systems_responsible_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.electricity_accounting_systems
    ADD CONSTRAINT electricity_accounting_systems_responsible_fkey FOREIGN KEY (responsible) REFERENCES public.employees(id);


--
-- TOC entry 3561 (class 2606 OID 17897)
-- Name: employees employees_position_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_position_fkey FOREIGN KEY ("position") REFERENCES public.positions(id);


--
-- TOC entry 3578 (class 2606 OID 18106)
-- Name: equipment_checks equipment_checks_equipment_condition_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_checks
    ADD CONSTRAINT equipment_checks_equipment_condition_fkey FOREIGN KEY (equipment_condition) REFERENCES public.equipment_conditions(id);


--
-- TOC entry 3579 (class 2606 OID 18111)
-- Name: equipment_checks equipment_checks_equipment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_checks
    ADD CONSTRAINT equipment_checks_equipment_fkey FOREIGN KEY (equipment) REFERENCES public.equipments(id);


--
-- TOC entry 3572 (class 2606 OID 18031)
-- Name: equipments equipments_transformer_point_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipments_transformer_point_fkey FOREIGN KEY (transformer_point) REFERENCES public.transformer_points(id);


--
-- TOC entry 3567 (class 2606 OID 17973)
-- Name: living_quarters living_quarters_building_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters
    ADD CONSTRAINT living_quarters_building_fkey FOREIGN KEY (building) REFERENCES public.buildings(id);


--
-- TOC entry 3573 (class 2606 OID 18048)
-- Name: living_quarters_consumers living_quarters_consumers_consumer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters_consumers
    ADD CONSTRAINT living_quarters_consumers_consumer_fkey FOREIGN KEY (consumer) REFERENCES public.consumers(id);


--
-- TOC entry 3574 (class 2606 OID 18053)
-- Name: living_quarters_consumers living_quarters_consumers_living_quarter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters_consumers
    ADD CONSTRAINT living_quarters_consumers_living_quarter_fkey FOREIGN KEY (living_quarter) REFERENCES public.living_quarters(id);


--
-- TOC entry 3568 (class 2606 OID 17978)
-- Name: living_quarters living_quarters_electricity_accounting_system_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.living_quarters
    ADD CONSTRAINT living_quarters_electricity_accounting_system_fkey FOREIGN KEY (electricity_accounting_system) REFERENCES public.electricity_accounting_systems(id);


--
-- TOC entry 3575 (class 2606 OID 18070)
-- Name: meter_readings_v1 meter_readings_v1_living_quarter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v1
    ADD CONSTRAINT meter_readings_v1_living_quarter_fkey FOREIGN KEY (living_quarter) REFERENCES public.living_quarters(id);


--
-- TOC entry 3569 (class 2606 OID 17995)
-- Name: meter_readings_v2 meter_readings_v2_building_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meter_readings_v2
    ADD CONSTRAINT meter_readings_v2_building_fkey FOREIGN KEY (building) REFERENCES public.buildings(id);


--
-- TOC entry 3577 (class 2606 OID 18089)
-- Name: transformer_point_buildings transformer_point_buildings_building_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_point_buildings
    ADD CONSTRAINT transformer_point_buildings_building_fkey FOREIGN KEY (building) REFERENCES public.buildings(id);


--
-- TOC entry 3576 (class 2606 OID 18084)
-- Name: transformer_point_buildings transformer_point_buildings_transformer_point_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_point_buildings
    ADD CONSTRAINT transformer_point_buildings_transformer_point_fkey FOREIGN KEY (transformer_point) REFERENCES public.transformer_points(id);


--
-- TOC entry 3570 (class 2606 OID 18009)
-- Name: transformer_points transformer_points_building_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_points
    ADD CONSTRAINT transformer_points_building_fkey FOREIGN KEY (building) REFERENCES public.buildings(id);


--
-- TOC entry 3571 (class 2606 OID 18014)
-- Name: transformer_points transformer_points_responsible_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transformer_points
    ADD CONSTRAINT transformer_points_responsible_fkey FOREIGN KEY (responsible) REFERENCES public.employees(id);


--
-- TOC entry 3581 (class 2606 OID 18137)
-- Name: user_tokens user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3580 (class 2606 OID 18125)
-- Name: users users_employee_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_employee_fkey FOREIGN KEY (employee) REFERENCES public.employees(id);


--
-- TOC entry 3783 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE alembic_version; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.alembic_version TO accountant;


--
-- TOC entry 3784 (class 0 OID 0)
-- Dependencies: 213
-- Name: TABLE application_statuses; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.application_statuses TO accountant;


--
-- TOC entry 3786 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE application_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.application_types TO accountant;


--
-- TOC entry 3788 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE applications; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.applications TO accountant;


--
-- TOC entry 3789 (class 0 OID 0)
-- Dependencies: 225 3788
-- Name: COLUMN applications.name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(name) ON TABLE public.applications TO user_role;


--
-- TOC entry 3790 (class 0 OID 0)
-- Dependencies: 225 3788
-- Name: COLUMN applications.description; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(description) ON TABLE public.applications TO user_role;


--
-- TOC entry 3791 (class 0 OID 0)
-- Dependencies: 225 3788
-- Name: COLUMN applications.start_date; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(start_date) ON TABLE public.applications TO user_role;


--
-- TOC entry 3793 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE audit_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.audit_log TO accountant;


--
-- TOC entry 3795 (class 0 OID 0)
-- Dependencies: 255
-- Name: SEQUENCE audit_log_log_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.audit_log_log_id_seq TO accountant;


--
-- TOC entry 3796 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE buildings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.buildings TO accountant;


--
-- TOC entry 3797 (class 0 OID 0)
-- Dependencies: 229 3796
-- Name: COLUMN buildings.area; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(area) ON TABLE public.buildings TO user_role;


--
-- TOC entry 3798 (class 0 OID 0)
-- Dependencies: 229 3796
-- Name: COLUMN buildings.city; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(city) ON TABLE public.buildings TO user_role;


--
-- TOC entry 3799 (class 0 OID 0)
-- Dependencies: 229 3796
-- Name: COLUMN buildings.street; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(street) ON TABLE public.buildings TO user_role;


--
-- TOC entry 3801 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE consumers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.consumers TO accountant;


--
-- TOC entry 3803 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE electricity_accounting_systems; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.electricity_accounting_systems TO accountant;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.electricity_accounting_systems TO electrician;


--
-- TOC entry 3804 (class 0 OID 0)
-- Dependencies: 227 3803
-- Name: COLUMN electricity_accounting_systems.name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(name) ON TABLE public.electricity_accounting_systems TO user_role;


--
-- TOC entry 3805 (class 0 OID 0)
-- Dependencies: 227 3803
-- Name: COLUMN electricity_accounting_systems.accuracy_class; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(accuracy_class) ON TABLE public.electricity_accounting_systems TO user_role;


--
-- TOC entry 3807 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE employee_audit_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.employee_audit_logs TO accountant;


--
-- TOC entry 3809 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE employees; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.employees TO accountant;


--
-- TOC entry 3811 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE equipment_checks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.equipment_checks TO accountant;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.equipment_checks TO electrician;


--
-- TOC entry 3813 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE equipment_conditions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.equipment_conditions TO accountant;


--
-- TOC entry 3815 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE equipments; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.equipments TO accountant;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.equipments TO electrician;


--
-- TOC entry 3817 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE living_quarters; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.living_quarters TO accountant;


--
-- TOC entry 3818 (class 0 OID 0)
-- Dependencies: 231 3817
-- Name: COLUMN living_quarters.building; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(building) ON TABLE public.living_quarters TO user_role;


--
-- TOC entry 3819 (class 0 OID 0)
-- Dependencies: 231 3817
-- Name: COLUMN living_quarters.entrance; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(entrance) ON TABLE public.living_quarters TO user_role;


--
-- TOC entry 3820 (class 0 OID 0)
-- Dependencies: 231 3817
-- Name: COLUMN living_quarters.apartment; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(apartment) ON TABLE public.living_quarters TO user_role;


--
-- TOC entry 3821 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE living_quarters_consumers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.living_quarters_consumers TO accountant;


--
-- TOC entry 3822 (class 0 OID 0)
-- Dependencies: 239 3821
-- Name: COLUMN living_quarters_consumers.consumer; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(consumer) ON TABLE public.living_quarters_consumers TO user_role;


--
-- TOC entry 3823 (class 0 OID 0)
-- Dependencies: 239 3821
-- Name: COLUMN living_quarters_consumers.living_quarter; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(living_quarter) ON TABLE public.living_quarters_consumers TO user_role;


--
-- TOC entry 3826 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE meter_readings_v1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.meter_readings_v1 TO accountant;


--
-- TOC entry 3828 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE meter_readings_v2; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.meter_readings_v2 TO accountant;


--
-- TOC entry 3830 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE positions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.positions TO accountant;


--
-- TOC entry 3832 (class 0 OID 0)
-- Dependencies: 252
-- Name: TABLE total_usage; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.total_usage TO accountant;


--
-- TOC entry 3833 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE transformer_point_buildings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.transformer_point_buildings TO accountant;


--
-- TOC entry 3835 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE transformer_points; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.transformer_points TO accountant;


--
-- TOC entry 3837 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE user_tokens; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.user_tokens TO accountant;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_tokens TO user_role;


--
-- TOC entry 3838 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.users TO accountant;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.users TO user_role;


--
-- TOC entry 3839 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE vw_application_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_application_status TO accountant;


--
-- TOC entry 3840 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE vw_building_energy_usage; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_building_energy_usage TO accountant;


--
-- TOC entry 3841 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE vw_employee_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_employee_details TO accountant;


--
-- TOC entry 3842 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE vw_equipment_maintenance_schedule; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_equipment_maintenance_schedule TO accountant;


--
-- TOC entry 2218 (class 826 OID 18169)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES  TO accountant;


-- Completed on 2024-05-28 22:25:07 MSK

--
-- PostgreSQL database dump complete
--

