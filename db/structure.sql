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
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: attachment_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.attachment_type AS ENUM (
    'response',
    'request',
    'ico_decision'
);


--
-- Name: cases_delivery_methods; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.cases_delivery_methods AS ENUM (
    'sent_by_email',
    'sent_by_post'
);


--
-- Name: request_types; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.request_types AS ENUM (
    'all_prison_records',
    'security_records',
    'nomis_records',
    'nomis_other',
    'nomis_contact_logs',
    'probation_records',
    'cctv_and_bwcf',
    'telephone_recordings',
    'telephone_pin_logs',
    'probation_archive',
    'mappa',
    'pdp',
    'court',
    'other'
);


--
-- Name: requester_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.requester_type AS ENUM (
    'academic_business_charity',
    'journalist',
    'member_of_the_public',
    'offender',
    'solicitor',
    'staff_judiciary',
    'what_do_they_know'
);


--
-- Name: search_query_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.search_query_type AS ENUM (
    'search',
    'filter',
    'list'
);


--
-- Name: state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.state AS ENUM (
    'pending',
    'rejected',
    'accepted',
    'bypassed'
);


--
-- Name: team_roles; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.team_roles AS ENUM (
    'managing',
    'responding',
    'approving'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'creator',
    'manager',
    'responder',
    'approver',
    'admin',
    'team_admin'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    id integer NOT NULL,
    state public.state DEFAULT 'pending'::public.state,
    case_id integer NOT NULL,
    team_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role public.team_roles,
    user_id integer,
    approved boolean DEFAULT false
);


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: case_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.case_attachments (
    id integer NOT NULL,
    case_id integer,
    type public.attachment_type,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    key character varying,
    preview_key character varying,
    upload_group character varying,
    user_id integer
);


--
-- Name: case_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.case_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.case_attachments_id_seq OWNED BY public.case_attachments.id;


--
-- Name: case_closure_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.case_closure_metadata (
    id integer NOT NULL,
    type character varying,
    subtype character varying,
    name character varying,
    abbreviation character varying,
    sequence_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    requires_refusal_reason boolean DEFAULT false,
    requires_exemption boolean DEFAULT false,
    active boolean DEFAULT true,
    omit_for_part_refused boolean DEFAULT false
);


--
-- Name: case_closure_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.case_closure_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_closure_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.case_closure_metadata_id_seq OWNED BY public.case_closure_metadata.id;


--
-- Name: case_number_counters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.case_number_counters (
    id integer NOT NULL,
    date date NOT NULL,
    counter integer DEFAULT 0
);


--
-- Name: case_number_counters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.case_number_counters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_number_counters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.case_number_counters_id_seq OWNED BY public.case_number_counters.id;


--
-- Name: case_transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.case_transitions (
    id integer NOT NULL,
    event character varying,
    to_state character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    sort_key integer NOT NULL,
    case_id integer NOT NULL,
    most_recent boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    acting_user_id integer,
    acting_team_id integer,
    target_user_id integer,
    target_team_id integer,
    to_workflow character varying
);


--
-- Name: case_transitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.case_transitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.case_transitions_id_seq OWNED BY public.case_transitions.id;


--
-- Name: cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cases (
    id integer NOT NULL,
    name character varying,
    email character varying,
    message text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    received_date date,
    postal_address character varying,
    subject character varying,
    properties jsonb,
    requester_type public.requester_type,
    number character varying NOT NULL,
    date_responded date,
    outcome_id integer,
    refusal_reason_id integer,
    current_state character varying,
    last_transitioned_at timestamp without time zone,
    delivery_method public.cases_delivery_methods,
    workflow character varying,
    deleted boolean DEFAULT false,
    info_held_status_id integer,
    type character varying,
    appeal_outcome_id integer,
    dirty boolean DEFAULT false,
    document_tsvector tsvector,
    reason_for_deletion character varying,
    user_id integer DEFAULT '-100'::integer NOT NULL,
    reason_for_lateness_id bigint,
    reason_for_lateness_note character varying
);


--
-- Name: cases_exemptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cases_exemptions (
    id integer NOT NULL,
    case_id integer,
    exemption_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cases_exemptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cases_exemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_exemptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cases_exemptions_id_seq OWNED BY public.cases_exemptions.id;


--
-- Name: cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cases_id_seq OWNED BY public.cases.id;


--
-- Name: cases_outcome_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cases_outcome_reasons (
    id bigint NOT NULL,
    case_id bigint,
    outcome_reason_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cases_outcome_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cases_outcome_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_outcome_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cases_outcome_reasons_id_seq OWNED BY public.cases_outcome_reasons.id;


--
-- Name: cases_users_transitions_trackers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cases_users_transitions_trackers (
    id integer NOT NULL,
    case_id integer,
    user_id integer,
    case_transition_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cases_users_transitions_trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cases_users_transitions_trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_users_transitions_trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cases_users_transitions_trackers_id_seq OWNED BY public.cases_users_transitions_trackers.id;


--
-- Name: category_references; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.category_references (
    id bigint NOT NULL,
    category character varying,
    code character varying,
    value character varying,
    display_order integer,
    deactivated boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: category_references_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.category_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: category_references_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.category_references_id_seq OWNED BY public.category_references.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id bigint NOT NULL,
    name character varying,
    address_line_1 character varying,
    address_line_2 character varying,
    town character varying,
    county character varying,
    postcode character varying,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    contact_type_id bigint
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: correspondence_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.correspondence_types (
    id integer NOT NULL,
    name character varying,
    abbreviation character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    properties jsonb DEFAULT '{}'::jsonb
);


--
-- Name: correspondence_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.correspondence_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: correspondence_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.correspondence_types_id_seq OWNED BY public.correspondence_types.id;


--
-- Name: data_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_migrations (
    version character varying NOT NULL
);


--
-- Name: data_request_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_request_logs (
    id integer NOT NULL,
    data_request_id integer NOT NULL,
    user_id integer NOT NULL,
    date_received date NOT NULL,
    num_pages integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: data_request_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_request_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_request_logs_id_seq OWNED BY public.data_request_logs.id;


--
-- Name: data_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_requests (
    id integer NOT NULL,
    case_id integer NOT NULL,
    user_id integer NOT NULL,
    location character varying NOT NULL,
    request_type public.request_types NOT NULL,
    date_requested date NOT NULL,
    cached_date_received date,
    cached_num_pages integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    request_type_note text DEFAULT ''::text NOT NULL,
    date_from date,
    date_to date,
    completed boolean DEFAULT false NOT NULL
);


--
-- Name: data_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_requests_id_seq OWNED BY public.data_requests.id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    id integer NOT NULL,
    content jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_id_seq OWNED BY public.feedback.id;


--
-- Name: letter_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.letter_templates (
    id integer NOT NULL,
    name character varying,
    abbreviation character varying,
    body character varying,
    template_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    letter_address character varying DEFAULT ''::character varying,
    base_template_file_ref character varying DEFAULT 'ims001.docx'::character varying
);


--
-- Name: letter_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.letter_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: letter_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.letter_templates_id_seq OWNED BY public.letter_templates.id;


--
-- Name: linked_cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.linked_cases (
    id integer NOT NULL,
    case_id integer NOT NULL,
    linked_case_id integer NOT NULL,
    type character varying DEFAULT 'related'::character varying
);


--
-- Name: linked_cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.linked_cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: linked_cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.linked_cases_id_seq OWNED BY public.linked_cases.id;


--
-- Name: report_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_types (
    id integer NOT NULL,
    abbr character varying NOT NULL,
    full_name character varying NOT NULL,
    class_name character varying NOT NULL,
    custom_report boolean DEFAULT false,
    seq_id integer NOT NULL,
    foi boolean DEFAULT false,
    sar boolean DEFAULT false,
    standard_report boolean DEFAULT false NOT NULL,
    default_reporting_period character varying DEFAULT 'year_to_date'::character varying,
    etl boolean DEFAULT false,
    offender_sar boolean DEFAULT false,
    offender_sar_complaint boolean DEFAULT false
);


--
-- Name: report_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_types_id_seq OWNED BY public.report_types.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id integer NOT NULL,
    report_type_id integer NOT NULL,
    period_start date,
    period_end date,
    report_data bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    guid character varying,
    properties jsonb
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- Name: retention_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.retention_schedules (
    id bigint NOT NULL,
    case_id bigint NOT NULL,
    planned_destruction_date date,
    erasure_date date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    state character varying
);


--
-- Name: retention_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.retention_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: retention_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.retention_schedules_id_seq OWNED BY public.retention_schedules.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: search_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.search_queries (
    id integer NOT NULL,
    user_id integer NOT NULL,
    query jsonb NOT NULL,
    num_results integer DEFAULT 0 NOT NULL,
    num_clicks integer DEFAULT 0 NOT NULL,
    highest_position integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parent_id integer,
    query_type public.search_query_type DEFAULT 'search'::public.search_query_type NOT NULL,
    filter_type character varying
);


--
-- Name: search_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.search_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: search_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.search_queries_id_seq OWNED BY public.search_queries.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    session_id character varying NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: team_correspondence_type_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_correspondence_type_roles (
    id integer NOT NULL,
    correspondence_type_id integer,
    team_id integer,
    view boolean DEFAULT false,
    edit boolean DEFAULT false,
    manage boolean DEFAULT false,
    respond boolean DEFAULT false,
    approve boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    administer_team boolean DEFAULT false NOT NULL
);


--
-- Name: team_correspondence_type_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_correspondence_type_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_correspondence_type_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_correspondence_type_roles_id_seq OWNED BY public.team_correspondence_type_roles.id;


--
-- Name: team_properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_properties (
    id integer NOT NULL,
    team_id integer,
    key character varying,
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_properties_id_seq OWNED BY public.team_properties.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    name character varying NOT NULL,
    email public.citext,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying,
    parent_id integer,
    role character varying,
    code character varying,
    deleted_at timestamp without time zone,
    moved_to_unit_id integer
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: teams_users_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams_users_roles (
    id integer NOT NULL,
    team_id integer,
    user_id integer,
    role public.user_role NOT NULL
);


--
-- Name: teams_users_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_users_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_users_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_users_roles_id_seq OWNED BY public.teams_users_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    full_name character varying NOT NULL,
    deleted_at timestamp without time zone,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: warehouse_case_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_case_reports (
    case_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    responding_team_id integer,
    responder_id integer,
    casework_officer_user_id integer,
    business_group_id integer,
    directorate_id integer,
    director_general_name_property_id integer,
    director_name_property_id integer,
    deputy_director_name_property_id integer,
    number character varying,
    case_type character varying,
    current_state character varying,
    responding_team character varying,
    responder character varying,
    date_received date,
    internal_deadline date,
    external_deadline date,
    date_responded date,
    date_compliant_draft_uploaded date,
    trigger character varying,
    name character varying,
    requester_type character varying,
    message character varying,
    info_held character varying,
    outcome character varying,
    refusal_reason character varying,
    exemptions character varying,
    postal_address character varying,
    email character varying,
    appeal_outcome character varying,
    third_party character varying,
    reply_method character varying,
    sar_subject_type character varying,
    sar_subject_full_name character varying,
    business_unit_responsible_for_late_response character varying,
    extended character varying,
    extension_count integer,
    deletion_reason character varying,
    casework_officer character varying,
    created_by character varying,
    date_created timestamp without time zone,
    business_group character varying,
    directorate_name character varying,
    director_general_name character varying,
    director_name character varying,
    deputy_director_name character varying,
    draft_in_time character varying,
    in_target character varying,
    number_of_days_late integer,
    info_held_status_id integer,
    refusal_reason_id integer,
    outcome_id integer,
    appeal_outcome_id integer,
    number_of_days_taken integer,
    number_of_exempt_pages integer,
    number_of_final_pages integer,
    third_party_company_name character varying,
    number_of_days_taken_after_extension integer,
    complaint_subtype character varying,
    priority character varying,
    total_cost numeric(10,2),
    settlement_cost numeric(10,2),
    user_dealing_with_vetting character varying,
    user_id_dealing_with_vetting integer,
    number_of_days_for_vetting integer,
    original_external_deadline date,
    original_internal_deadline date,
    num_days_late_against_original_deadline integer,
    request_method character varying
);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: case_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_attachments ALTER COLUMN id SET DEFAULT nextval('public.case_attachments_id_seq'::regclass);


--
-- Name: case_closure_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_closure_metadata ALTER COLUMN id SET DEFAULT nextval('public.case_closure_metadata_id_seq'::regclass);


--
-- Name: case_number_counters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_number_counters ALTER COLUMN id SET DEFAULT nextval('public.case_number_counters_id_seq'::regclass);


--
-- Name: case_transitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_transitions ALTER COLUMN id SET DEFAULT nextval('public.case_transitions_id_seq'::regclass);


--
-- Name: cases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases ALTER COLUMN id SET DEFAULT nextval('public.cases_id_seq'::regclass);


--
-- Name: cases_exemptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases_exemptions ALTER COLUMN id SET DEFAULT nextval('public.cases_exemptions_id_seq'::regclass);


--
-- Name: cases_outcome_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases_outcome_reasons ALTER COLUMN id SET DEFAULT nextval('public.cases_outcome_reasons_id_seq'::regclass);


--
-- Name: cases_users_transitions_trackers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases_users_transitions_trackers ALTER COLUMN id SET DEFAULT nextval('public.cases_users_transitions_trackers_id_seq'::regclass);


--
-- Name: category_references id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_references ALTER COLUMN id SET DEFAULT nextval('public.category_references_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: correspondence_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.correspondence_types ALTER COLUMN id SET DEFAULT nextval('public.correspondence_types_id_seq'::regclass);


--
-- Name: data_request_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_request_logs ALTER COLUMN id SET DEFAULT nextval('public.data_request_logs_id_seq'::regclass);


--
-- Name: data_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_requests ALTER COLUMN id SET DEFAULT nextval('public.data_requests_id_seq'::regclass);


--
-- Name: feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback ALTER COLUMN id SET DEFAULT nextval('public.feedback_id_seq'::regclass);


--
-- Name: letter_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_templates ALTER COLUMN id SET DEFAULT nextval('public.letter_templates_id_seq'::regclass);


--
-- Name: linked_cases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linked_cases ALTER COLUMN id SET DEFAULT nextval('public.linked_cases_id_seq'::regclass);


--
-- Name: report_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_types ALTER COLUMN id SET DEFAULT nextval('public.report_types_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- Name: retention_schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retention_schedules ALTER COLUMN id SET DEFAULT nextval('public.retention_schedules_id_seq'::regclass);


--
-- Name: search_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_queries ALTER COLUMN id SET DEFAULT nextval('public.search_queries_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: team_correspondence_type_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_correspondence_type_roles ALTER COLUMN id SET DEFAULT nextval('public.team_correspondence_type_roles_id_seq'::regclass);


--
-- Name: team_properties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_properties ALTER COLUMN id SET DEFAULT nextval('public.team_properties_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: teams_users_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users_roles ALTER COLUMN id SET DEFAULT nextval('public.teams_users_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: case_attachments case_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_attachments
    ADD CONSTRAINT case_attachments_pkey PRIMARY KEY (id);


--
-- Name: case_closure_metadata case_closure_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_closure_metadata
    ADD CONSTRAINT case_closure_metadata_pkey PRIMARY KEY (id);


--
-- Name: case_number_counters case_number_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_number_counters
    ADD CONSTRAINT case_number_counters_pkey PRIMARY KEY (id);


--
-- Name: case_transitions case_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_transitions
    ADD CONSTRAINT case_transitions_pkey PRIMARY KEY (id);


--
-- Name: cases_exemptions cases_exemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases_exemptions
    ADD CONSTRAINT cases_exemptions_pkey PRIMARY KEY (id);


--
-- Name: cases_outcome_reasons cases_outcome_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases_outcome_reasons
    ADD CONSTRAINT cases_outcome_reasons_pkey PRIMARY KEY (id);


--
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- Name: cases_users_transitions_trackers cases_users_transitions_trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases_users_transitions_trackers
    ADD CONSTRAINT cases_users_transitions_trackers_pkey PRIMARY KEY (id);


--
-- Name: category_references category_references_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_references
    ADD CONSTRAINT category_references_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: correspondence_types correspondence_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.correspondence_types
    ADD CONSTRAINT correspondence_types_pkey PRIMARY KEY (id);


--
-- Name: data_migrations data_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_migrations
    ADD CONSTRAINT data_migrations_pkey PRIMARY KEY (version);


--
-- Name: data_request_logs data_request_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_request_logs
    ADD CONSTRAINT data_request_logs_pkey PRIMARY KEY (id);


--
-- Name: data_requests data_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_requests
    ADD CONSTRAINT data_requests_pkey PRIMARY KEY (id);


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: letter_templates letter_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_templates
    ADD CONSTRAINT letter_templates_pkey PRIMARY KEY (id);


--
-- Name: linked_cases linked_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linked_cases
    ADD CONSTRAINT linked_cases_pkey PRIMARY KEY (id);


--
-- Name: report_types report_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_types
    ADD CONSTRAINT report_types_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: retention_schedules retention_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retention_schedules
    ADD CONSTRAINT retention_schedules_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: search_queries search_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.search_queries
    ADD CONSTRAINT search_queries_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: team_correspondence_type_roles team_correspondence_type_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_correspondence_type_roles
    ADD CONSTRAINT team_correspondence_type_roles_pkey PRIMARY KEY (id);


--
-- Name: team_properties team_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_properties
    ADD CONSTRAINT team_properties_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teams_users_roles teams_users_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users_roles
    ADD CONSTRAINT teams_users_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: warehouse_case_reports warehouse_case_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_case_reports
    ADD CONSTRAINT warehouse_case_reports_pkey PRIMARY KEY (case_id);


--
-- Name: cases_document_tsvector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_document_tsvector_index ON public.cases USING gin (document_tsvector);


--
-- Name: index_assignments_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_case_id ON public.assignments USING btree (case_id);


--
-- Name: index_assignments_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_state ON public.assignments USING btree (state);


--
-- Name: index_assignments_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_team_id ON public.assignments USING btree (team_id);


--
-- Name: index_assignments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_user_id ON public.assignments USING btree (user_id);


--
-- Name: index_case_attachments_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_case_attachments_on_case_id ON public.case_attachments USING btree (case_id);


--
-- Name: index_case_attachments_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_attachments_on_key ON public.case_attachments USING btree (key);


--
-- Name: index_case_number_counters_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_number_counters_on_date ON public.case_number_counters USING btree (date);


--
-- Name: index_case_transitions_parent_most_recent; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_transitions_parent_most_recent ON public.case_transitions USING btree (case_id, most_recent) WHERE most_recent;


--
-- Name: index_case_transitions_parent_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_transitions_parent_sort ON public.case_transitions USING btree (case_id, sort_key);


--
-- Name: index_cases_exemptions_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_exemptions_on_case_id ON public.cases_exemptions USING btree (case_id);


--
-- Name: index_cases_exemptions_on_exemption_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_exemptions_on_exemption_id ON public.cases_exemptions USING btree (exemption_id);


--
-- Name: index_cases_on_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_on_deleted ON public.cases USING btree (deleted);


--
-- Name: index_cases_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cases_on_number ON public.cases USING btree (number);


--
-- Name: index_cases_on_requester_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_on_requester_type ON public.cases USING btree (requester_type);


--
-- Name: index_cases_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_on_user_id ON public.cases USING btree (user_id);


--
-- Name: index_cases_outcome_reasons_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_outcome_reasons_on_case_id ON public.cases_outcome_reasons USING btree (case_id);


--
-- Name: index_cases_outcome_reasons_on_outcome_reason_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_outcome_reasons_on_outcome_reason_id ON public.cases_outcome_reasons USING btree (outcome_reason_id);


--
-- Name: index_cases_users_transitions_trackers_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_users_transitions_trackers_on_case_id ON public.cases_users_transitions_trackers USING btree (case_id);


--
-- Name: index_cases_users_transitions_trackers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_users_transitions_trackers_on_user_id ON public.cases_users_transitions_trackers USING btree (user_id);


--
-- Name: index_contacts_on_contact_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_contact_type_id ON public.contacts USING btree (contact_type_id);


--
-- Name: index_data_request_logs_on_data_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_request_logs_on_data_request_id ON public.data_request_logs USING btree (data_request_id);


--
-- Name: index_data_request_logs_on_data_request_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_request_logs_on_data_request_id_and_user_id ON public.data_request_logs USING btree (data_request_id, user_id);


--
-- Name: index_data_request_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_request_logs_on_user_id ON public.data_request_logs USING btree (user_id);


--
-- Name: index_data_requests_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_requests_on_case_id ON public.data_requests USING btree (case_id);


--
-- Name: index_data_requests_on_case_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_requests_on_case_id_and_user_id ON public.data_requests USING btree (case_id, user_id);


--
-- Name: index_data_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_requests_on_user_id ON public.data_requests USING btree (user_id);


--
-- Name: index_letter_templates_on_abbreviation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_letter_templates_on_abbreviation ON public.letter_templates USING btree (abbreviation);


--
-- Name: index_linked_cases_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_linked_cases_on_case_id ON public.linked_cases USING btree (case_id);


--
-- Name: index_linked_cases_on_case_id_and_linked_case_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_linked_cases_on_case_id_and_linked_case_id_and_type ON public.linked_cases USING btree (case_id, linked_case_id, type);


--
-- Name: index_report_types_on_abbr; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_report_types_on_abbr ON public.report_types USING btree (abbr);


--
-- Name: index_reports_on_report_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_report_type_id ON public.reports USING btree (report_type_id);


--
-- Name: index_retention_schedules_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_retention_schedules_on_case_id ON public.retention_schedules USING btree (case_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON public.sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON public.sessions USING btree (updated_at);


--
-- Name: index_team_correspondence_type_roles_on_type_id_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_correspondence_type_roles_on_type_id_and_team_id ON public.team_correspondence_type_roles USING btree (correspondence_type_id, team_id);


--
-- Name: index_team_properties_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_properties_on_team_id ON public.team_properties USING btree (team_id);


--
-- Name: index_team_properties_on_team_id_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_properties_on_team_id_and_key_and_value ON public.team_properties USING btree (team_id, key, value);


--
-- Name: index_team_table_team_id_role_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_table_team_id_role_user_id ON public.teams_users_roles USING btree (team_id, role, user_id);


--
-- Name: index_teams_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_teams_on_code ON public.teams USING btree (code);


--
-- Name: index_teams_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_email ON public.teams USING btree (email);


--
-- Name: index_teams_on_moved_to_unit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_moved_to_unit_id ON public.teams USING btree (moved_to_unit_id);


--
-- Name: index_teams_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_name ON public.teams USING btree (name);


--
-- Name: index_teams_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_parent_id ON public.teams USING btree (parent_id);


--
-- Name: index_teams_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_type ON public.teams USING btree (type);


--
-- Name: index_teams_on_type_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_teams_on_type_and_name ON public.teams USING btree (type, name);


--
-- Name: index_teams_users_roles_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_users_roles_on_team_id ON public.teams_users_roles USING btree (team_id);


--
-- Name: index_teams_users_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_users_roles_on_user_id ON public.teams_users_roles USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_warehouse_case_reports_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_case_reports_on_case_id ON public.warehouse_case_reports USING btree (case_id);


--
-- Name: data_request_logs fk_rails_274490f7ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_request_logs
    ADD CONSTRAINT fk_rails_274490f7ec FOREIGN KEY (data_request_id) REFERENCES public.data_requests(id);


--
-- Name: warehouse_case_reports fk_rails_2a80c865a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_case_reports
    ADD CONSTRAINT fk_rails_2a80c865a7 FOREIGN KEY (case_id) REFERENCES public.cases(id);


--
-- Name: cases fk_rails_5b2f8d9aa6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT fk_rails_5b2f8d9aa6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: retention_schedules fk_rails_5f5dbf6820; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retention_schedules
    ADD CONSTRAINT fk_rails_5f5dbf6820 FOREIGN KEY (case_id) REFERENCES public.cases(id);


--
-- Name: data_requests fk_rails_8ea0aff84a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_requests
    ADD CONSTRAINT fk_rails_8ea0aff84a FOREIGN KEY (case_id) REFERENCES public.cases(id);


--
-- Name: contacts fk_rails_b8815787ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT fk_rails_b8815787ee FOREIGN KEY (contact_type_id) REFERENCES public.category_references(id);


--
-- Name: data_request_logs fk_rails_fc711a84cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_request_logs
    ADD CONSTRAINT fk_rails_fc711a84cc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160722121207'),
('20160802130203'),
('20160802134012'),
('20160803094147'),
('20160804155742'),
('20160811181245'),
('20160811182008'),
('20160811185359'),
('20160815103852'),
('20161017062721'),
('20161017120533'),
('20161031133532'),
('20161103104520'),
('20161114143107'),
('20161116150744'),
('20161116153411'),
('20161125115930'),
('20161130164018'),
('20161209220224'),
('20170111115617'),
('20170111161049'),
('20170116161424'),
('20170118154824'),
('20170118154954'),
('20170128230814'),
('20170208133053'),
('20170222171317'),
('20170223130158'),
('20170303140119'),
('20170306093700'),
('20170307083809'),
('20170309134800'),
('20170309153815'),
('20170315152035'),
('20170320112822'),
('20170320121845'),
('20170406112015'),
('20170407091658'),
('20170420120713'),
('20170420122223'),
('20170424133127'),
('20170523131602'),
('20170609094110'),
('20170626153411'),
('20170627112545'),
('20170713094438'),
('20170727101532'),
('20170727112001'),
('20170727162325'),
('20170728154625'),
('20170731101430'),
('20170816155918'),
('20170818082409'),
('20170830162157'),
('20170831091142'),
('20170906130950'),
('20170908083205'),
('20170908142318'),
('20170913124313'),
('20170925142730'),
('20171003080427'),
('20171003153752'),
('20171013134445'),
('20171023134233'),
('20171023142558'),
('20171025142614'),
('20171027112328'),
('20171101171629'),
('20171114111458'),
('20171116102127'),
('20171123170106'),
('20171205092729'),
('20171205102155'),
('20171215103720'),
('20171220135129'),
('20171227223627'),
('20171228145707'),
('20171230113732'),
('20180106124709'),
('20180119121951'),
('20180123164057'),
('20180125100559'),
('20180125111431'),
('20180126120726'),
('20180202171348'),
('20180205120050'),
('20180206100800'),
('20180208161547'),
('20180214162943'),
('20180214163355'),
('20180222125345'),
('20180228174550'),
('20180321094200'),
('20180322183946'),
('20180406145035'),
('20180410142138'),
('20180410143714'),
('20180419103640'),
('20180419130340'),
('20180420173415'),
('20180424150445'),
('20180508131152'),
('20180517140929'),
('20180522132456'),
('20180524132031'),
('20180613141421'),
('20180620135756'),
('20180621094208'),
('20180622153909'),
('20180705184513'),
('20180711151118'),
('20180716150951'),
('20180717211105'),
('20180806100827'),
('20190228142249'),
('20190312104101'),
('20190325082640'),
('20190326113949'),
('20190609165906'),
('20190609185907'),
('20190730133328'),
('20190731151806'),
('20190817185027'),
('20190912142741'),
('20191002003615'),
('20191028094210'),
('20200705225914'),
('20200811151902'),
('20200811154406'),
('20200811222853'),
('20200812115318'),
('20200812142406'),
('20200819133514'),
('20200819171428'),
('20200824130200'),
('20200914160132'),
('20200925100514'),
('20201113130611'),
('20210115230915'),
('20210518085422'),
('20210625113911'),
('20210723160533'),
('20210727143427'),
('20210914110858'),
('20210914111215'),
('20210917113753'),
('20220117091139'),
('20220319002602'),
('20220401091216'),
('20220506131034'),
('20220511130149'),
('20220928103707');

