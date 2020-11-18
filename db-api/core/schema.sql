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
---------------------------------
---------------------- FUNCTIONS:
---------------------------------

CREATE OR REPLACE FUNCTION core.gen_random_bytes(integer) RETURNS bytea AS '$libdir/pgcrypto', 'pg_random_bytes' LANGUAGE c STRICT;


-- used by other functions, below, for any random strings needed
CREATE OR REPLACE FUNCTION core.random_string(length integer) RETURNS text AS $$
DECLARE
	chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
	result text := '';
	i integer := 0;
	rand bytea;
BEGIN
	-- Generate secure random bytes and convert them to a string of chars.
	-- Since our charset contains 62 characters, we will have a small
	-- modulo bias, which is acceptable for our uses.
	rand := core.gen_random_bytes(length);
	FOR i IN 0..length-1 LOOP
		result := result || chars[1 + (get_byte(rand, i) % array_length(chars, 1))];
		-- note: rand indexing is zero-based, chars is 1-based.
	END LOOP;
	RETURN result;
END;
$$ LANGUAGE plpgsql;


-- ensure unique unused value for any table.field.
CREATE OR REPLACE FUNCTION core.unique_for_table_field(str_len integer, table_name text, field_name text) RETURNS text AS $$
DECLARE
	nu text;
BEGIN
	nu := core.random_string(str_len);
	LOOP
		EXECUTE 'SELECT 1 FROM ' || table_name || ' WHERE ' || field_name || ' = ' || quote_literal(nu);
		IF NOT FOUND THEN
			RETURN nu; 
		END IF;
		nu := core.random_string(str_len);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- For updating foreign keys, tables referencing this column
-- tablename in schema.table format like 'woodegg.researchers' colname: 'person_id'
-- PARAMS: schema, table, column
CREATE OR REPLACE FUNCTION core.tables_referencing(text, text, text)
	RETURNS TABLE(tablename text, colname name) AS $$
BEGIN
	RETURN QUERY SELECT CONCAT(n.nspname, '.', k.relname), a.attname
		FROM pg_constraint c
		INNER JOIN pg_class k ON c.conrelid = k.oid
		INNER JOIN pg_attribute a ON c.conrelid = a.attrelid
		INNER JOIN pg_namespace n ON k.relnamespace = n.oid
		WHERE c.confrelid = (SELECT oid FROM pg_class WHERE relname = $2 
			AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = $1))
		AND ARRAY[a.attnum] <@ c.conkey
		AND c.confkey @> (SELECT array_agg(attnum) FROM pg_attribute
			WHERE attname = $3 AND attrelid = c.confrelid);
END;
$$ LANGUAGE plpgsql;


-- RETURNS: array of column names that ARE allowed to be updated
-- PARAMS: schema name, table name, array of col names NOT allowed to be updated
CREATE OR REPLACE FUNCTION core.cols2update(text, text, text[]) RETURNS text[] AS $$
BEGIN
	RETURN array(SELECT column_name::text FROM information_schema.columns
		WHERE table_schema=$1 AND table_name=$2 AND column_name != ALL($3));
END;
$$ LANGUAGE plpgsql;


-- PARAMS: table name, id, json, array of cols that ARE allowed to be updated
CREATE OR REPLACE FUNCTION core.jsonupdate(text, integer, json, text[]) RETURNS VOID AS $$
DECLARE
	col record;
BEGIN
	FOR col IN SELECT name FROM json_object_keys($3) AS name LOOP
		CONTINUE WHEN col.name != ALL($4);
		EXECUTE format ('UPDATE %s SET %I =
			(SELECT %I FROM json_populate_record(null::%s, $1)) WHERE id = %L',
			$1, col.name, col.name, $1, $2) USING $3;
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: any text that needs to be stripped of HTML tags
CREATE OR REPLACE FUNCTION core.strip_tags(text) RETURNS text AS $$
BEGIN
	RETURN regexp_replace($1 , '</?[^>]+?>', '', 'g');
END;
$$ LANGUAGE plpgsql;


-- PARAMS: any text that needs HTML escape
CREATE OR REPLACE FUNCTION core.escape_html(text) RETURNS text AS $$
DECLARE
	nu text;
BEGIN
	nu := replace($1, '&', '&amp;');
	nu := replace(nu, '''', '&#39;');
	nu := replace(nu, '"', '&quot;');
	nu := replace(nu, '<', '&lt;');
	nu := replace(nu, '>', '&gt;');
	RETURN nu;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: any text that might have URLs
-- returns all words with dot between not-whitespace chars (very liberal)
-- normalized without https?://, trailing dot, any <>
CREATE OR REPLACE FUNCTION core.urls_in_text(text) RETURNS SETOF text AS $$
BEGIN
	RETURN QUERY SELECT regexp_replace(
		(regexp_matches($1, '\S+\.\S+', 'g'))[1],
		'<|>|https?://|\.$', '', 'g');  
END;
$$ LANGUAGE plpgsql;


-- PARAMS: JSON of currency rates https://openexchangerates.org/documentation
CREATE OR REPLACE FUNCTION core.update_currency_rates(jsonb) RETURNS void AS $$
DECLARE
	rates jsonb;
	acurrency core.currencies;
	acode core.currency;
	arate numeric;
BEGIN
	rates := jsonb_extract_path($1, 'rates');
	FOR acurrency IN SELECT * FROM core.currencies LOOP
		acode := acurrency.code;
		arate := CAST((rates ->> CAST(acode AS text)) AS numeric);
		INSERT INTO core.currency_rates (code, rate) VALUES (acode, arate);
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: amount, from.code to.code
CREATE OR REPLACE FUNCTION core.currency_from_to(numeric, core.currency, core.currency, OUT amount numeric) AS $$
BEGIN
	IF $2 = 'USD' THEN
		SELECT ($1 * rate) INTO amount
			FROM core.currency_rates WHERE code = $3
			ORDER BY day DESC LIMIT 1;
	ELSIF $3 = 'USD' THEN
		SELECT ($1 / rate) INTO amount
			FROM core.currency_rates WHERE code = $2
			ORDER BY day DESC LIMIT 1;
	ELSE
		SELECT (
			(SELECT $1 / rate
				FROM core.currency_rates WHERE code = $2
				ORDER BY day DESC LIMIT 1) * rate) INTO amount
			FROM core.currency_rates WHERE code = $3
			ORDER BY day DESC LIMIT 1;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: money, new_currency_code
CREATE OR REPLACE FUNCTION core.money_to(core.currency_amount, core.currency)
	RETURNS core.currency_amount AS $$
BEGIN
	IF $1.currency = 'USD' THEN
		RETURN (SELECT ($2, ($1.amount * rate)) 
			FROM core.currency_rates WHERE code = $2
			ORDER BY day DESC LIMIT 1);
	ELSIF $2 = 'USD' THEN
		RETURN (SELECT ($2, ($1.amount / rate))
			FROM core.currency_rates WHERE code = $1.currency
			ORDER BY day DESC LIMIT 1);
	ELSE
		RETURN (SELECT ($2, ((SELECT $1.amount / rate
			FROM core.currency_rates WHERE code = $1.currency
			ORDER BY day DESC LIMIT 1) * rate))
			FROM core.currency_rates WHERE code = $2
			ORDER BY day DESC LIMIT 1);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: money1 + money2. Uses money1.currency!
CREATE OR REPLACE FUNCTION core.add_money(core.currency_amount, core.currency_amount)
	RETURNS core.currency_amount AS $$
BEGIN
	IF $1.currency = $2.currency THEN
		RETURN ($1.currency, ($1.amount + $2.amount));
	ELSE
		RETURN ($1.currency, ($1.amount + (core.money_to($2, $1.currency)).amount));
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: money1 - money2. Uses money1.currency!
CREATE OR REPLACE FUNCTION core.subtract_money(core.currency_amount, core.currency_amount)
	RETURNS core.currency_amount AS $$
BEGIN
	IF $1.currency = $2.currency THEN
		RETURN ($1.currency, ($1.amount - $2.amount));
	ELSE
		RETURN ($1.currency, ($1.amount - (core.money_to($2, $1.currency)).amount));
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: money, number to multiply it by
CREATE OR REPLACE FUNCTION core.multiply_money(core.currency_amount, numeric)
	RETURNS core.currency_amount AS $$
BEGIN
	RETURN ($1.currency, ($1.amount * $2));
END;
$$ LANGUAGE plpgsql;


-- PARAMS: money
CREATE OR REPLACE FUNCTION core.round_money(core.currency_amount)
	RETURNS core.currency_amount AS $$
BEGIN
	RETURN ($1.currency, round($1.amount, 2));
END;
$$ LANGUAGE plpgsql;

---------------------
------------ TRIGGERS
---------------------

CREATE OR REPLACE FUNCTION core.changelog_nodupe() RETURNS TRIGGER AS $$
DECLARE
	cid integer;
BEGIN
	SELECT id INTO cid FROM core.changelog
		WHERE person_id=NEW.person_id
		AND schema_name=NEW.schema_name
		AND table_name=NEW.table_name
		AND table_id=NEW.table_id
		AND approved IS NOT TRUE LIMIT 1;
	IF cid IS NULL THEN
		RETURN NEW;
	ELSE
		RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS changelog_nodupe ON core.changelog CASCADE;
CREATE TRIGGER changelog_nodupe
	BEFORE INSERT ON core.changelog
	FOR EACH ROW EXECUTE PROCEDURE core.changelog_nodupe();

------------------------------------------------
-------------------------------------- JSON API:
------------------------------------------------ 


-- GET /currencies
-- PARAMS: -none-
-- RETURNS array of objects:
-- [{"code":"AUD","name":"Australian Dollar"},{"code":"BGN","name":"Bulgarian Lev"}... ]
CREATE OR REPLACE FUNCTION core.all_currencies(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT code::text, name FROM core.currencies ORDER BY code) r;
END;
$$ LANGUAGE plpgsql;


-- GET /currency_names
-- PARAMS: -none-
-- RETURNS single code:name object:
-- {"AUD":"Australian Dollar", "BGN":"Bulgarian Lev", ...}
CREATE OR REPLACE FUNCTION core.currency_names(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_object(
		ARRAY(SELECT code::text FROM core.currencies ORDER BY code),
		ARRAY(SELECT name FROM core.currencies ORDER BY code));
END;
$$ LANGUAGE plpgsql;



