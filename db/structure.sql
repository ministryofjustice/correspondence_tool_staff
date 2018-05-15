--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.10
-- Dumped by pg_dump version 9.5.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET search_path = public, pg_catalog;

--
-- Name: attachment_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE attachment_type AS ENUM (
    'response',
    'request'
);


--
-- Name: cases_delivery_methods; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE cases_delivery_methods AS ENUM (
    'sent_by_email',
    'sent_by_post'
);


--
-- Name: requester_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE requester_type AS ENUM (
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

CREATE TYPE search_query_type AS ENUM (
    'search',
    'filter',
    'list'
);


--
-- Name: state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE state AS ENUM (
    'pending',
    'rejected',
    'accepted',
    'bypassed'
);


--
-- Name: team_roles; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE team_roles AS ENUM (
    'managing',
    'responding',
    'approving'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE user_role AS ENUM (
    'creator',
    'manager',
    'responder',
    'approver',
    'admin'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assignments (
    id integer NOT NULL,
    state state DEFAULT 'pending'::state,
    case_id integer NOT NULL,
    team_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role team_roles,
    user_id integer,
    approved boolean DEFAULT false
);


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignments_id_seq OWNED BY assignments.id;


--
-- Name: case_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE case_attachments (
    id integer NOT NULL,
    case_id integer,
    type attachment_type,
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

CREATE SEQUENCE case_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_attachments_id_seq OWNED BY case_attachments.id;


--
-- Name: case_closure_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE case_closure_metadata (
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

CREATE SEQUENCE case_closure_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_closure_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_closure_metadata_id_seq OWNED BY case_closure_metadata.id;


--
-- Name: case_number_counters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE case_number_counters (
    id integer NOT NULL,
    date date NOT NULL,
    counter integer DEFAULT 0
);


--
-- Name: case_number_counters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_number_counters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_number_counters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_number_counters_id_seq OWNED BY case_number_counters.id;


--
-- Name: case_transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE case_transitions (
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

CREATE SEQUENCE case_transitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_transitions_id_seq OWNED BY case_transitions.id;


--
-- Name: cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cases (
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
    requester_type requester_type,
    number character varying NOT NULL,
    date_responded date,
    outcome_id integer,
    refusal_reason_id integer,
    current_state character varying,
    last_transitioned_at timestamp without time zone,
    delivery_method cases_delivery_methods,
    workflow character varying DEFAULT 'standard'::character varying,
    deleted boolean DEFAULT false,
    info_held_status_id integer,
    type character varying,
    appeal_outcome_id integer,
    dirty boolean DEFAULT false,
    document_tsvector tsvector
);


--
-- Name: cases_exemptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cases_exemptions (
    id integer NOT NULL,
    case_id integer,
    exemption_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cases_exemptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cases_exemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_exemptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cases_exemptions_id_seq OWNED BY cases_exemptions.id;


--
-- Name: cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cases_id_seq OWNED BY cases.id;


--
-- Name: cases_users_transitions_trackers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cases_users_transitions_trackers (
    id integer NOT NULL,
    case_id integer,
    user_id integer,
    case_transition_id integer
);


--
-- Name: cases_users_transitions_trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cases_users_transitions_trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_users_transitions_trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cases_users_transitions_trackers_id_seq OWNED BY cases_users_transitions_trackers.id;


--
-- Name: correspondence_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE correspondence_types (
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

CREATE SEQUENCE correspondence_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: correspondence_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE correspondence_types_id_seq OWNED BY correspondence_types.id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE feedback (
    id integer NOT NULL,
    content jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feedback_id_seq OWNED BY feedback.id;


--
-- Name: linked_cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE linked_cases (
    id integer NOT NULL,
    case_id integer NOT NULL,
    linked_case_id integer NOT NULL
);


--
-- Name: linked_cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE linked_cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: linked_cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE linked_cases_id_seq OWNED BY linked_cases.id;


--
-- Name: report_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE report_types (
    id integer NOT NULL,
    abbr character varying NOT NULL,
    full_name character varying NOT NULL,
    class_name character varying NOT NULL,
    custom_report boolean DEFAULT false,
    seq_id integer NOT NULL
);


--
-- Name: report_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE report_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_types_id_seq OWNED BY report_types.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE reports (
    id integer NOT NULL,
    report_type_id integer NOT NULL,
    period_start date,
    period_end date,
    report_data bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: search_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE search_queries (
    id integer NOT NULL,
    user_id integer NOT NULL,
    query jsonb NOT NULL,
    num_results integer NOT NULL,
    num_clicks integer DEFAULT 0 NOT NULL,
    highest_position integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parent_id integer,
    query_type search_query_type DEFAULT 'search'::search_query_type NOT NULL,
    filter_type character varying
);


--
-- Name: search_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE search_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: search_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE search_queries_id_seq OWNED BY search_queries.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: team_correspondence_type_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE team_correspondence_type_roles (
    id integer NOT NULL,
    correspondence_type_id integer,
    team_id integer,
    view boolean DEFAULT false,
    edit boolean DEFAULT false,
    manage boolean DEFAULT false,
    respond boolean DEFAULT false,
    approve boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_correspondence_type_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE team_correspondence_type_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_correspondence_type_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_correspondence_type_roles_id_seq OWNED BY team_correspondence_type_roles.id;


--
-- Name: team_properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE team_properties (
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

CREATE SEQUENCE team_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_properties_id_seq OWNED BY team_properties.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams (
    id integer NOT NULL,
    name character varying NOT NULL,
    email citext,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying,
    parent_id integer,
    role character varying,
    code character varying,
    deleted_at timestamp without time zone
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: teams_users_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams_users_roles (
    id integer NOT NULL,
    team_id integer,
    user_id integer,
    role user_role NOT NULL
);


--
-- Name: teams_users_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_users_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_users_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_users_roles_id_seq OWNED BY teams_users_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
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

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
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

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments ALTER COLUMN id SET DEFAULT nextval('assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_attachments ALTER COLUMN id SET DEFAULT nextval('case_attachments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_closure_metadata ALTER COLUMN id SET DEFAULT nextval('case_closure_metadata_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_number_counters ALTER COLUMN id SET DEFAULT nextval('case_number_counters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_transitions ALTER COLUMN id SET DEFAULT nextval('case_transitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cases ALTER COLUMN id SET DEFAULT nextval('cases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cases_exemptions ALTER COLUMN id SET DEFAULT nextval('cases_exemptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cases_users_transitions_trackers ALTER COLUMN id SET DEFAULT nextval('cases_users_transitions_trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY correspondence_types ALTER COLUMN id SET DEFAULT nextval('correspondence_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedback ALTER COLUMN id SET DEFAULT nextval('feedback_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY linked_cases ALTER COLUMN id SET DEFAULT nextval('linked_cases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_types ALTER COLUMN id SET DEFAULT nextval('report_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_queries ALTER COLUMN id SET DEFAULT nextval('search_queries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_correspondence_type_roles ALTER COLUMN id SET DEFAULT nextval('team_correspondence_type_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_properties ALTER COLUMN id SET DEFAULT nextval('team_properties_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams_users_roles ALTER COLUMN id SET DEFAULT nextval('teams_users_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: case_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_attachments
    ADD CONSTRAINT case_attachments_pkey PRIMARY KEY (id);


--
-- Name: case_closure_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_closure_metadata
    ADD CONSTRAINT case_closure_metadata_pkey PRIMARY KEY (id);


--
-- Name: case_number_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_number_counters
    ADD CONSTRAINT case_number_counters_pkey PRIMARY KEY (id);


--
-- Name: case_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY case_transitions
    ADD CONSTRAINT case_transitions_pkey PRIMARY KEY (id);


--
-- Name: cases_exemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cases_exemptions
    ADD CONSTRAINT cases_exemptions_pkey PRIMARY KEY (id);


--
-- Name: cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- Name: cases_users_transitions_trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cases_users_transitions_trackers
    ADD CONSTRAINT cases_users_transitions_trackers_pkey PRIMARY KEY (id);


--
-- Name: correspondence_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY correspondence_types
    ADD CONSTRAINT correspondence_types_pkey PRIMARY KEY (id);


--
-- Name: feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: linked_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY linked_cases
    ADD CONSTRAINT linked_cases_pkey PRIMARY KEY (id);


--
-- Name: report_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_types
    ADD CONSTRAINT report_types_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: search_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_queries
    ADD CONSTRAINT search_queries_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: team_correspondence_type_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_correspondence_type_roles
    ADD CONSTRAINT team_correspondence_type_roles_pkey PRIMARY KEY (id);


--
-- Name: team_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_properties
    ADD CONSTRAINT team_properties_pkey PRIMARY KEY (id);


--
-- Name: teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teams_users_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams_users_roles
    ADD CONSTRAINT teams_users_roles_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: cases_document_tsvector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_document_tsvector_index ON cases USING gin (document_tsvector);


--
-- Name: index_assignments_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_case_id ON assignments USING btree (case_id);


--
-- Name: index_assignments_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_state ON assignments USING btree (state);


--
-- Name: index_assignments_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_team_id ON assignments USING btree (team_id);


--
-- Name: index_assignments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_user_id ON assignments USING btree (user_id);


--
-- Name: index_case_attachments_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_case_attachments_on_case_id ON case_attachments USING btree (case_id);


--
-- Name: index_case_attachments_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_attachments_on_key ON case_attachments USING btree (key);


--
-- Name: index_case_number_counters_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_number_counters_on_date ON case_number_counters USING btree (date);


--
-- Name: index_case_transitions_parent_most_recent; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_transitions_parent_most_recent ON case_transitions USING btree (case_id, most_recent) WHERE most_recent;


--
-- Name: index_case_transitions_parent_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_transitions_parent_sort ON case_transitions USING btree (case_id, sort_key);


--
-- Name: index_cases_exemptions_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_exemptions_on_case_id ON cases_exemptions USING btree (case_id);


--
-- Name: index_cases_exemptions_on_exemption_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_exemptions_on_exemption_id ON cases_exemptions USING btree (exemption_id);


--
-- Name: index_cases_on_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_on_deleted ON cases USING btree (deleted);


--
-- Name: index_cases_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cases_on_number ON cases USING btree (number);


--
-- Name: index_cases_on_requester_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_on_requester_type ON cases USING btree (requester_type);


--
-- Name: index_cases_users_transitions_trackers_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_users_transitions_trackers_on_case_id ON cases_users_transitions_trackers USING btree (case_id);


--
-- Name: index_cases_users_transitions_trackers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cases_users_transitions_trackers_on_user_id ON cases_users_transitions_trackers USING btree (user_id);


--
-- Name: index_linked_cases_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_linked_cases_on_case_id ON linked_cases USING btree (case_id);


--
-- Name: index_linked_cases_on_case_id_and_linked_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_linked_cases_on_case_id_and_linked_case_id ON linked_cases USING btree (case_id, linked_case_id);


--
-- Name: index_report_types_on_abbr; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_report_types_on_abbr ON report_types USING btree (abbr);


--
-- Name: index_reports_on_report_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_report_type_id ON reports USING btree (report_type_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_team_correspondence_type_roles_on_type_id_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_correspondence_type_roles_on_type_id_and_team_id ON team_correspondence_type_roles USING btree (correspondence_type_id, team_id);


--
-- Name: index_team_properties_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_properties_on_team_id ON team_properties USING btree (team_id);


--
-- Name: index_team_properties_on_team_id_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_properties_on_team_id_and_key_and_value ON team_properties USING btree (team_id, key, value);


--
-- Name: index_team_table_team_id_role_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_table_team_id_role_user_id ON teams_users_roles USING btree (team_id, role, user_id);


--
-- Name: index_teams_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_teams_on_code ON teams USING btree (code);


--
-- Name: index_teams_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_email ON teams USING btree (email);


--
-- Name: index_teams_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_name ON teams USING btree (name);


--
-- Name: index_teams_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_parent_id ON teams USING btree (parent_id);


--
-- Name: index_teams_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_type ON teams USING btree (type);


--
-- Name: index_teams_on_type_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_teams_on_type_and_name ON teams USING btree (type, name);


--
-- Name: index_teams_users_roles_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_users_roles_on_team_id ON teams_users_roles USING btree (team_id);


--
-- Name: index_teams_users_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_users_roles_on_user_id ON teams_users_roles USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


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
('20180508131152');


