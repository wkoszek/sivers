SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS muckwork CASCADE;
BEGIN;

CREATE SCHEMA muckwork;
SET search_path = muckwork;

CREATE TABLE muckwork.managers (
	id smallserial primary key,
	person_id integer not null unique REFERENCES peeps.people(id)
);

CREATE TABLE muckwork.clients (
	id serial primary key,
	person_id integer not null unique REFERENCES peeps.people(id),
	currency core.currency not null default 'USD'
);

CREATE TABLE muckwork.workers (
	id serial primary key,
	person_id integer not null unique REFERENCES peeps.people(id),
	hourly_rate core.currency_amount not null default ('USD',10)
);

CREATE TYPE muckwork.progress AS ENUM('created', 'quoted', 'approved', 'refused', 'started', 'finished');

CREATE TABLE muckwork.projects (
	id serial primary key,
	client_id integer not null REFERENCES muckwork.clients(id),
	title text,
	description text,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	quoted_at timestamp(0) with time zone CHECK (quoted_at >= created_at),
	approved_at timestamp(0) with time zone CHECK (approved_at >= quoted_at),
	started_at timestamp(0) with time zone CHECK (started_at >= approved_at),
	finished_at timestamp(0) with time zone CHECK (finished_at >= started_at),
	progress progress not null default 'created',
	quoted_ratetype varchar(4) CHECK (quoted_ratetype = 'fix' OR quoted_ratetype = 'time'),
	quoted_money core.currency_amount,
	final_money core.currency_amount
);
CREATE INDEX pjci ON muckwork.projects(client_id);
CREATE INDEX pjst ON muckwork.projects(progress);

CREATE TABLE muckwork.tasks (
	id serial primary key,
	project_id integer REFERENCES muckwork.projects(id) ON DELETE CASCADE,
	worker_id integer REFERENCES muckwork.workers(id),
	sortid integer,
	title text,
	description text,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	claimed_at timestamp(0) with time zone CHECK (claimed_at >= created_at),
	started_at timestamp(0) with time zone CHECK (started_at >= claimed_at),
	finished_at timestamp(0) with time zone CHECK (finished_at >= started_at),
	progress muckwork.progress not null default 'created'
);
CREATE INDEX tpi ON muckwork.tasks(project_id);
CREATE INDEX twi ON muckwork.tasks(worker_id);
CREATE INDEX tst ON muckwork.tasks(progress);

CREATE TABLE muckwork.notes (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	project_id integer REFERENCES muckwork.projects(id),
	task_id integer REFERENCES muckwork.tasks(id),
	manager_id integer REFERENCES muckwork.managers(id),
	client_id integer REFERENCES muckwork.clients(id),
	worker_id integer REFERENCES muckwork.workers(id),
	note text not null CONSTRAINT note_not_empty CHECK (length(note) > 0)
);
CREATE INDEX notpi ON muckwork.notes(project_id);
CREATE INDEX notti ON muckwork.notes(task_id);

CREATE TABLE muckwork.client_charges (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	project_id integer REFERENCES muckwork.projects(id),
	money core.currency_amount not null,
	notes text
);
CREATE INDEX chpi ON muckwork.client_charges(project_id);

CREATE TABLE muckwork.client_payments (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	client_id integer REFERENCES muckwork.clients(id),
	money core.currency_amount not null,
	notes text
);
CREATE INDEX pyci ON muckwork.client_payments(client_id);

CREATE TABLE muckwork.worker_payments (
	id serial primary key,
	worker_id integer not null REFERENCES muckwork.workers(id),
	money core.currency_amount not null,
	created_at date not null default CURRENT_DATE,
	notes text
);
CREATE INDEX wpwi ON muckwork.worker_payments(worker_id);

CREATE TABLE muckwork.worker_charges (
	id serial primary key,
	task_id integer not null REFERENCES muckwork.tasks(id),
	money core.currency_amount not null,
	payment_id integer REFERENCES muckwork.worker_payments(id) -- NULL until paid
);
CREATE INDEX wcpi ON muckwork.worker_charges(payment_id);
CREATE INDEX wcti ON muckwork.worker_charges(task_id);

COMMIT;
