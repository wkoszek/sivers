DROP VIEW IF EXISTS peeps.person_view CASCADE;
CREATE VIEW peeps.person_view AS
	SELECT id,
	name,
	address,
	email,
	company,
	city,
	state,
	country,
	notes,
	lopass,
	listype,
	categorize_as,
	created_at, (
		SELECT json_agg(s) AS stats
		FROM (
			SELECT id,
			created_at,
			statkey AS name,
			statvalue AS value
			FROM peeps.stats
			WHERE person_id = peeps.people.id
			ORDER BY id
		) s
	), (
		SELECT json_agg(u) AS urls
		FROM (
			SELECT id,
			url,
			main
			FROM peeps.urls
			WHERE person_id = peeps.people.id
			ORDER BY main DESC NULLS LAST, id
		) u
	), (
		SELECT json_agg(e) AS emails
		FROM (
			SELECT id,
			created_at,
			subject,
			outgoing FROM peeps.emails
			WHERE person_id = peeps.people.id
			ORDER BY id
		) e
	)
	FROM peeps.people;

DROP VIEW IF EXISTS peeps.email_view CASCADE;
CREATE VIEW peeps.email_view AS
	SELECT id,
	profile,
	category,
	created_at, (
		SELECT row_to_json(p1) AS creator
		FROM (
			SELECT emailers.id, people.name
			FROM peeps.emailers
				JOIN peeps.people
				ON emailers.person_id = people.id
			WHERE peeps.emailers.id = created_by
		) p1
	),
	opened_at, (
		SELECT row_to_json(p2) AS openor
		FROM (
			SELECT emailers.id, people.name
			FROM peeps.emailers
				JOIN peeps.people
				ON emailers.person_id = people.id
			WHERE peeps.emailers.id = opened_by
		) p2
	),
	closed_at, (
		SELECT row_to_json(p3) AS closor
		FROM (
			SELECT emailers.id, people.name
			FROM peeps.emailers
				JOIN peeps.people
				ON emailers.person_id = people.id
			WHERE peeps.emailers.id = closed_by
		) p3
	),
	message_id,
	outgoing,
	reference_id,
	answer_id,
	their_email,
	their_name,
	headers,
	subject,
	body,
	to_json(ARRAY(SELECT core.urls_in_text(body))) AS urls, (
		SELECT json_agg(a) AS attachments
		FROM (
			SELECT id, filename
			FROM peeps.email_attachments
			WHERE email_id = peeps.emails.id
		) a
	), (
		SELECT row_to_json(p) AS person
		FROM (
			SELECT *
			FROM peeps.person_view
			WHERE id = person_id
		) p
	)
	FROM peeps.emails;

ALTER TABLE peeps.people DROP COLUMN phone;
ALTER TABLE peeps.people DROP COLUMN confirmed;
ALTER TABLE peeps.people ADD COLUMN checked_at date; 
ALTER TABLE peeps.people ADD COLUMN checked_by smallint; 
CREATE INDEX person_checked_at ON peeps.people(checked_at);
CREATE INDEX person_checked_by ON peeps.people(checked_by);
ALTER TABLE peeps.people ADD FOREIGN KEY (checked_by) REFERENCES peeps.emailers(id);

--DROP TABLE peeps.emailer_times;  -- never existed anyway?
DROP FUNCTION peeps.emailer_times(integer);
DROP FUNCTION peeps.emailer_times_per_day(integer, text);
DROP FUNCTION peeps.active_emailers();
DROP FUNCTION peeps.etimes_in_month(integer, text);

CREATE OR REPLACE FUNCTION peeps.kyc_next_person(integer,
	OUT status smallint, OUT js jsonb) AS $$
DECLARE
	person_id integer;
BEGIN
	-- does this emailer have a person open but not finished yet?
	SELECT id INTO person_id
		FROM peeps.people
		WHERE checked_at IS NULL
		AND checked_by = $1;
	IF NOT FOUND THEN
		-- if not, find next and immediately tag with this emailer_id
		SELECT id INTO person_id
			FROM peeps.people
			WHERE checked_at IS NULL
			AND checked_by IS NULL
			AND email IS NOT NULL
			AND email_count > 0
			ORDER BY id ASC LIMIT 1;
		UPDATE peeps.people
			SET checked_by = $1
			WHERE id = person_id;
	END IF;
	status := 200;
	js := jsonb_build_object('person_id', person_id);
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id
-- TODO: if I want to get strict: error checking, auth checking emailer_id matches, and that it's not done already
CREATE OR REPLACE FUNCTION peeps.kyc_done_person(integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	UPDATE peeps.people SET checked_at=NOW() WHERE id = $1;
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;

