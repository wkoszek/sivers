SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS peeps CASCADE;
BEGIN;

CREATE SCHEMA peeps;
SET search_path = peeps;

-- Country codes used mainly for foreign key constraint on people.country
-- From http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 - data loaded below
-- No need for any API to update, insert, or delete from this table.
CREATE TABLE peeps.countries (
	code character(2) NOT NULL primary key,
	name text
);

-- Big master table for people
CREATE TABLE peeps.people (
	id serial primary key,
	email varchar(127) UNIQUE CONSTRAINT valid_email CHECK (email ~ '\A\S+@\S+\.\S+\Z'),
	name varchar(127) NOT NULL CONSTRAINT no_name CHECK (LENGTH(name) > 0),
	address varchar(64), --  not mailing address, but "how do I address you?".  Usually firstname.
	public_id char(4) UNIQUE, -- random used for public URLs
	hashpass varchar(72), -- user-chosen password, blowfish crypted using set_hashpass function below.
	lopass char(4), -- random used with id for low-security unsubscribe links to deter id spoofing
	newpass char(8) UNIQUE, -- random for "forgot my password" emails, erased when set_hashpass
	company varchar(127),
	city varchar(32),
	state varchar(16),
	country char(2) REFERENCES peeps.countries(code),
	notes text,
	email_count smallint not null default 0,
	listype varchar(4),
	categorize_as varchar(16), -- if not null, incoming emails.category set to this
	created_at date not null default CURRENT_DATE,
	checked_at timestamp(0),
	checked_by smallint
);
CREATE INDEX person_name ON peeps.people(name);
CREATE INDEX person_pid ON peeps.people(public_id);
CREATE INDEX person_checked_at ON peeps.people(checked_at);
CREATE INDEX person_checked_by ON peeps.people(checked_by);

-- People authorized to answer/create emails
CREATE TABLE peeps.emailers (
	id smallserial primary key,
	person_id integer NOT NULL UNIQUE REFERENCES peeps.people(id) ON DELETE RESTRICT,
	admin boolean NOT NULL DEFAULT 'f',
	profiles text[] NOT NULL DEFAULT '{}',  -- only allowed to view these emails.profile
	categories text[] NOT NULL DEFAULT '{}' -- only allowed to view these emails.category
);
ALTER TABLE peeps.people ADD FOREIGN KEY (checked_by) REFERENCES peeps.emailers(id);

-- Catch-all for any random facts about this person
CREATE TABLE peeps.stats (
	id serial primary key,
	person_id integer not null REFERENCES peeps.people(id) ON DELETE CASCADE,
	statkey varchar(32) not null CONSTRAINT statkey_format CHECK (statkey ~ '\A[a-z0-9._-]+\Z'),
	statvalue text not null CONSTRAINT statval_not_empty CHECK (length(statvalue) > 0),
	created_at date not null default CURRENT_DATE
);
CREATE INDEX stats_person ON peeps.stats(person_id);
CREATE INDEX stats_statkey ON peeps.stats(statkey);

-- This person's websites
CREATE TABLE peeps.urls (
	id serial primary key,
	person_id integer not null REFERENCES peeps.people(id) ON DELETE CASCADE,
	url varchar(255) CONSTRAINT url_format CHECK (url ~ '^https?://[0-9a-zA-Z_-]+\.[a-zA-Z0-9]+'),
	main boolean  -- means it's their main/home site
);
CREATE INDEX urls_person ON peeps.urls(person_id);

-- Logged-in users given a cookie with random string, to look up their person_id
CREATE TABLE peeps.logins (
	cookie char(32) not null primary key,
	person_id integer not null REFERENCES peeps.people(id) ON DELETE CASCADE,
	domain varchar(32) not null,
	created_at date not null default CURRENT_DATE
);
CREATE INDEX logins_person_id ON peeps.logins(person_id);

-- All incoming and outgoing emails
CREATE TABLE peeps.emails (
	id serial primary key,
	person_id integer REFERENCES peeps.people(id),
	profile varchar(18) not null CHECK (length(profile) > 0),  -- which email address sent to/from
	category varchar(16) not null CHECK (length(category) > 0),  -- like gmail's labels, but 1-to-1
	created_at timestamp(0) not null DEFAULT current_timestamp,
	created_by integer REFERENCES peeps.emailers(id),
	opened_at timestamp(0),
	opened_by integer REFERENCES peeps.emailers(id),
	closed_at timestamp(0),
	closed_by integer REFERENCES peeps.emailers(id),
	reference_id integer REFERENCES peeps.emails(id) DEFERRABLE, -- email this is replying to
	answer_id integer REFERENCES peeps.emails(id) DEFERRABLE, -- email replying to this one
	their_email varchar(127) NOT NULL CONSTRAINT valid_email CHECK (their_email ~ '\A\S+@\S+\.\S+\Z'),  -- their email address (whether incoming or outgoing)
	their_name varchar(127) NOT NULL,
	subject varchar(127),
	headers text,
	body text,
	message_id varchar(255) UNIQUE,
	outgoing boolean default 'f',
	flag integer  -- rarely used, to mark especially important emails 
);
CREATE INDEX emails_person_id ON peeps.emails(person_id);
CREATE INDEX emails_category ON peeps.emails(category);
CREATE INDEX emails_profile ON peeps.emails(profile);
CREATE INDEX emails_created_by ON peeps.emails(created_by);
CREATE INDEX emails_opened_by ON peeps.emails(opened_by);
CREATE INDEX emails_outgoing ON peeps.emails(outgoing);

-- Attachments sent with incoming emails
CREATE TABLE peeps.email_attachments (
	id serial primary key,
	email_id integer REFERENCES peeps.emails(id) ON DELETE CASCADE,
	mime_type text,
	filename text,
	bytes integer
);
CREATE INDEX email_attachments_email_id ON peeps.email_attachments(email_id);

-- Commonly used emails.body templates
CREATE TABLE peeps.formletters (
	id smallserial primary key,
	accesskey char(1) UNIQUE CHECK (accesskey ~ '[a-z0-9]'),
	title varchar(64) UNIQUE,
	explanation varchar(255),
	subject varchar(64),
	body text,
	created_at date not null default CURRENT_DATE
);

-- exists only for validiation of peeps.attributes.attribute
CREATE TABLE peeps.atkeys (
	atkey varchar(16) primary key CHECK (atkey ~ '\A[a-z-]+\Z'),
	description text
);

-- attributes like enthusiastic, connected, available
CREATE TABLE peeps.attributes (
	person_id integer NOT NULL REFERENCES peeps.people(id) ON DELETE CASCADE,
	attribute varchar(16) NOT NULL REFERENCES peeps.atkeys(atkey),
	plusminus boolean NOT NULL,  -- true if yes, false if no
	PRIMARY KEY (person_id, attribute)
);

-- exists only for validiation of peeps.interests.interest
CREATE TABLE peeps.inkeys (
	inkey varchar(32) primary key CHECK (inkey ~ '\A[a-z]+\Z'),
	description text
);

-- interests like ruby, spanish, china, marketing
CREATE TABLE peeps.interests (
	person_id integer NOT NULL REFERENCES peeps.people(id) ON DELETE CASCADE,
	interest varchar(32) NOT NULL REFERENCES peeps.inkeys(inkey),
	expert boolean DEFAULT NULL, -- true if expert, false if searching-for
	PRIMARY KEY (person_id, interest)
);
CREATE INDEX peepsints ON peeps.interests(person_id);

CREATE TABLE peeps.tweets (
	id bigint primary key,
	entire jsonb,
	created_at timestamp(0),
	person_id integer REFERENCES peeps.people(id) ON DELETE CASCADE,
	handle varchar(15),
	message text,
	reference_id bigint,
	seen boolean
);
CREATE INDEX stpi ON peeps.tweets(person_id);
CREATE INDEX sthandle ON peeps.tweets(handle);
CREATE INDEX stseen ON peeps.tweets(seen);

COMMIT;
