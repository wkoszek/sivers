SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS core CASCADE;
BEGIN;

CREATE SCHEMA core;
SET search_path = core;

CREATE TYPE core.currency AS ENUM ('AUD','BGN','BRL','BTC','CAD','CHF','CNY','CZK','DKK','EUR','GBP','HKD','HRK','HUF','IDR','ILS','INR','JPY','KRW','LTL','MXN','MYR','NOK','NZD','PHP','PLN','RON','RUB','SEK','SGD','THB','TRY','USD','ZAR');
CREATE TYPE core.currency_amount AS (currency core.currency, amount numeric);

CREATE TABLE core.currencies (
	code core.currency NOT NULL primary key,
	name text
);

CREATE TABLE core.currency_rates (
	code core.currency NOT NULL,
	day date not null default CURRENT_DATE,
	rate numeric,
	PRIMARY KEY (code, day)
);

CREATE TABLE core.configs (
	k varchar(32) primary key,
	v text not null CONSTRAINT val_not_empty CHECK (length(v) > 0)
);

CREATE TABLE core.changelog (
	id serial primary key,
	person_id integer NOT NULL REFERENCES peeps.people(id),
	created_at date NOT NULL DEFAULT CURRENT_DATE,
	schema_name varchar(16),
	table_name varchar(32),
	table_id integer,
	approved boolean DEFAULT false
);
CREATE INDEX changelog_person_id ON core.changelog(person_id);
CREATE INDEX changelog_approved ON core.changelog(approved);

COMMIT;
