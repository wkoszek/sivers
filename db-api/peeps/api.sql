----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- TODO: why am I using json vs jsonb?  switch to jsonb entirely?

-- API REQUIRES AUTHENTICATION. User must be in peeps.emailers
-- peeps.emailers.id needed as first argument to many functions here


-- Grouped summary of howmany unopened emails in each profile/category
-- JSON format: {profiles:{categories:howmany}}
--{"sivers":{"sivers":43,"derek":2,"programmer":1},
-- "woodegg":{"woodeggRESEARCH":1,"woodegg":1}}
--Route{
--  api = "peeps.unopened_email_count",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unopened/([0-9]+)",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.unopened_email_count(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_object_agg(profile, cats) FROM (
		WITH unopened AS (
			SELECT profile, category
			FROM peeps.emails
			WHERE id IN (
				SELECT * FROM peeps.unopened_email_ids($1)
			)
		)
		SELECT profile, (
			SELECT json_object_agg(category, num)
			FROM (
				SELECT category, COUNT(*) AS num
				FROM unopened u2
				WHERE u2.profile = unopened.profile
				GROUP BY category
				ORDER BY num DESC
			)
		rr) AS cats
		FROM unopened
		GROUP BY profile
	) r;  
	status := 200;
	IF js IS NULL THEN js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.unopened_emails",
--  args = {"emailer_id", "profile", "category"},
--  method = "GET",
--  url = "/unopened/([0-9]+)/([a-z@]+)/([a-zA-Z@.-]+)",
--  captures = {"emailer_id", "profile", "category"},
--}
CREATE OR REPLACE FUNCTION peeps.unopened_emails(integer, text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_view
		WHERE id IN (
			SELECT id
			FROM peeps.emails
			WHERE id IN (
				SELECT * FROM peeps.unopened_email_ids($1)
			)
			AND profile = $2
			AND category = $3
		) ORDER BY id
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- Opens email (updates status as opened by this emailer) then returns view
--Route{
--  api = "peeps.open_next_email",
--  args = {"emailer_id", "profile", "category"},
--  method = "POST",
--  url = "/next/([0-9]+)/([a-z@]+)/([a-zA-Z@.-]+)",
--  captures = {"emailer_id", "profile", "category"},
--}
CREATE OR REPLACE FUNCTION peeps.open_next_email(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	SELECT id INTO email_id
	FROM peeps.emails
	-- TODO: OPTIMIZE THIS: WHERE id IN (SELECT * FROM peeps.unopened_email_ids($1))
	WHERE opened_by IS NULL
	AND profile = $2
	AND category = $3
	ORDER BY id LIMIT 1;
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	PERFORM peeps.open_email($1, email_id);
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.opened_emails",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/opened/([0-9]+)",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.opened_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT e.id,
			subject,
			opened_at,
			p.name
		FROM peeps.emails e
			JOIN peeps.emailers r ON e.opened_by=r.id
			JOIN peeps.people p ON r.person_id=p.id
		WHERE e.id IN (
			SELECT * FROM peeps.opened_email_ids($1)
		)
		ORDER BY opened_at
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_email",
--  args = {"emailer_id", "email_id"},
--  method = "POST",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	email_id := peeps.open_email($1, $2);
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.update_email",
--  args = {"emailer_id", "email_id", "json"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_email(integer, integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
m4_ERRVARS
BEGIN
	email_id := peeps.ok_email($1, $2);
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	PERFORM core.jsonupdate('peeps.emails', email_id, $3,
		core.cols2update('peeps', 'emails', ARRAY['id', 'created_at']));
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_email",
--  args = {"emailer_id", "email_id"},
--  method = "DELETE",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	email_id := peeps.ok_email($1, $2);
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
	DELETE FROM peeps.emails WHERE id = email_id;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.close_email",
--  args = {"emailer_id", "email_id"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)/close",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.close_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	email_id := peeps.ok_email($1, $2);
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	UPDATE peeps.emails
	SET closed_at=NOW(), closed_by=$1
	WHERE id = email_id;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.unread_email",
--  args = {"emailer_id", "email_id"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)/unread",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.unread_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	email_id := peeps.ok_email($1, $2);
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	UPDATE peeps.emails
	SET opened_at=NULL, opened_by=NULL, closed_at=NULL, closed_by=NULL
	WHERE id = email_id;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.not_my_email",
--  args = {"emailer_id", "email_id"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)/punt",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.not_my_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	email_id := peeps.ok_email($1, $2);
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	UPDATE peeps.emails
	SET opened_at=NULL, opened_by=NULL, closed_at=NULL, closed_by=NULL,
	category=(
		SELECT substring(
			concat('not-', split_part(people.email,'@',1))
			from 1 for 8)
		FROM peeps.emailers
			JOIN peeps.people ON emailers.person_id=people.id
		WHERE emailers.id = $1
	)
	WHERE id = email_id;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.reply_to_email",
--  args = {"emailer_id", "email_id", "body"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--  params = {"body"},
--}
CREATE OR REPLACE FUNCTION peeps.reply_to_email(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
	e peeps.emails;
	new_id integer;
m4_ERRVARS
BEGIN
	IF $3 IS NULL OR (regexp_replace($3, '\s', '', 'g') = '') THEN
		RAISE 'body must not be empty';
	END IF;
	email_id := peeps.ok_email($1, $2);
	IF email_id IS NULL THEN m4_NOTFOUND RETURN; END IF;
	SELECT * INTO e FROM peeps.emails WHERE id = email_id;
	IF e IS NULL THEN m4_NOTFOUND RETURN; END IF;
	-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id 
	SELECT * INTO new_id
	FROM peeps.outgoing_email($1,
		e.person_id,
		e.profile,
		e.profile,
		concat('re: ', regexp_replace(e.subject, 're: ', '', 'ig')),
		$3,
		$2);
	UPDATE peeps.emails
	SET answer_id = new_id
	, closed_at = NOW()
	, closed_by = $1
	WHERE id = $2;
	js := json_build_object('id', new_id);
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.count_unknowns",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unknowns/([0-9]+)/count",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.count_unknowns(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_build_object('count', (
		SELECT COUNT(*) FROM peeps.unknown_email_ids($1)
	));
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_unknowns",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unknowns/([0-9]+)",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_unknowns(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_view
		WHERE id IN (
			SELECT * FROM peeps.unknown_email_ids($1)
		)
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_next_unknown",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unknowns/([0-9]+)/next",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_next_unknown(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.unknown_view r
	WHERE id IN (
		SELECT * FROM peeps.unknown_email_ids($1)
		LIMIT 1
	);
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- person_id=0 to create new
--Route{
--  api = "peeps.set_unknown_person",
--  args = {"emailer_id", "email_id", "person_id"},
--  method = "PUT",
--  url = "/unknowns/([0-9]+)/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id", "person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.set_unknown_person(integer, integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	this_e peeps.emails;
	newperson peeps.people;
	rowcount integer;
m4_ERRVARS
BEGIN
	SELECT * INTO this_e
	FROM peeps.emails
	WHERE id IN (
		SELECT * FROM peeps.unknown_email_ids($1)
	) AND id = $2;
	GET DIAGNOSTICS rowcount = ROW_COUNT;
	IF rowcount = 0 THEN m4_NOTFOUND RETURN; END IF;
	IF $3 = 0 THEN
		SELECT * INTO newperson
		FROM peeps.person_create(this_e.their_name, this_e.their_email);
	ELSE
		SELECT * INTO newperson
		FROM peeps.people
		WHERE id = $3;
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount = 0 THEN m4_NOTFOUND RETURN; END IF;
		UPDATE peeps.people
		SET email = this_e.their_email,
		notes = concat('OLD EMAIL: ', email, E'\n', notes)
		WHERE id = $3;
	END IF;
	UPDATE peeps.emails
	SET person_id = newperson.id, category = profile
	WHERE id = $2;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_unknown",
--  args = {"emailer_id", "email_id"},
--  method = "DELETE",
--  url = "/unknowns/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_unknown(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.unknown_view r
	WHERE id IN (
		SELECT * FROM peeps.unknown_email_ids($1)
	) AND id = $2;
	IF js IS NULL THEN m4_NOTFOUND RETURN; END IF;
	status := 200;
	DELETE FROM peeps.emails WHERE id = $2;
END;
$$ LANGUAGE plpgsql;

COMMIT;


--Route{
--  api = "peeps.create_person",
--  args = {"name", "email"},
--  method = "POST",
--  url = "/person",
--  params = {"name", "email"},
--}
CREATE OR REPLACE FUNCTION peeps.create_person(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT id INTO pid FROM peeps.person_create($1, $2);
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = pid;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.make_newpass",
--  args = {"person_id"},
--  method = "POST",
--  url = "/password/([0-9]+)",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.make_newpass(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.people
		SET newpass = core.unique_for_table_field(8, 'peeps.people', 'newpass')
		WHERE id = $1
		AND newpass IS NULL;
	SELECT json_build_object('id', id, 'newpass', newpass) INTO js
		FROM peeps.people
		WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_person",
--  args = {"person_id"},
--  method = "GET",
--  url = "/person/([0-9]+)",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_person_email",
--  args = {"email"},
--  method = "GET",
--  url = "/person",
--  params = {"email"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_email(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid
	FROM peeps.get_person_id_from_email($1);
	IF pid IS NULL THEN m4_NOTFOUND END IF;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = pid;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_person_lopass",
--  args = {"person_id", "lopass"},
--  method = "GET",
--  url = "/person/([0-9]+)/([a-zA-Z0-9]{4})",
--  captures = {"person_id", "lopass"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_lopass(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid
	FROM peeps.people
	WHERE id = $1
	AND lopass = $2;
	IF pid IS NULL THEN m4_NOTFOUND RETURN; END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_person_newpass",
--  args = {"person_id", "newpass"},
--  method = "GET",
--  url = "/person/([0-9]+)/([a-zA-Z0-9]{8})",
--  captures = {"person_id", "newpass"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_newpass(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.people WHERE id = $1 AND newpass = $2;
	IF pid IS NULL THEN m4_NOTFOUND RETURN; END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_person_password",
--  args = {"email", "password"},
--  method = "GET",
--  url = "/person",
--  params = {"email", "password"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_password(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
		FROM peeps.get_person(peeps.pid_from_email_pass($1, $2)) x;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_person_cookie",
--  args = {"cookie"},
--  method = "GET",
--  url = "/person/([a-zA-Z0-9]{32}",
--  captures = {"cookie"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_cookie(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
		FROM peeps.get_person(peeps.get_person_id_from_cookie($1)) x;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.person_in_table",
--  args = {"person_id", "schema.table"},
--  method = "GET",
--  url = "/person/([0-9]+)/([a-z0-9.]+)",
--  captures = {"person_id", "tablename"},
--}
CREATE OR REPLACE FUNCTION peeps.person_in_table(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	EXECUTE FORMAT ('
		SELECT row_to_json(r)
		FROM (
			SELECT id FROM %s WHERE person_id=%s
		) r', $2, $1
	) INTO js;
	IF js IS NULL THEN m4_NOTFOUND RETURN; END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.cookie_from_id",
--  args = {"person_id", "domain"},
--  method = "POST",
--  url = "/login/([0-9]+)/([a-z0-9.-]+)",
--  captures = {"person_id", "domain"},
--}
CREATE OR REPLACE FUNCTION peeps.cookie_from_id(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT cookie FROM peeps.login_person_domain($1, $2)
	) r;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.cookie_from_login",
--  args = {"email", "password", "domain"},
--  method = "POST",
--  url = "/login/([a-z0-9.-]+)",
--  captures = {"domain"},
--  params = {"email", "password"},
--}
CREATE OR REPLACE FUNCTION peeps.cookie_from_login(text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT p.pid INTO pid FROM peeps.pid_from_email_pass($1, $2) p;
	IF pid IS NULL THEN m4_NOTFOUND RETURN; END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.cookie_from_id(pid, $3) x;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.set_password",
--  args = {"person_id", "password"},
--  method = "PUT",
--  url = "/person/([0-9]+)/password",
--  captures = {"person_id"},
--  params = {"password"},
--}
CREATE OR REPLACE FUNCTION peeps.set_password(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM peeps.set_hashpass($1, $2);
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.update_person",
--  args = {"person_id", "json"},
--  method = "PUT",
--  url = "/person/([0-9]+)",
--  captures = {"person_id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_person(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.people',
		$1,
		$2,
		core.cols2update('peeps', 'people', ARRAY['id', 'created_at']));
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_person",
--  args = {"person_id"},
--  method = "DELETE",
--  url = "/person/([0-9]+)",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND RETURN; END IF;
	DELETE FROM peeps.people WHERE id = $1;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.annihilate_person",
--  args = {"person_id"},
--  method = "DELETE",
--  url = "/person/([0-9]+)/annihilate",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.annihilate_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	res RECORD;
m4_ERRVARS
BEGIN
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND RETURN; END IF;
	FOR res IN SELECT * FROM core.tables_referencing('peeps', 'people', 'id') LOOP
		EXECUTE format ('DELETE FROM %s WHERE %I=%s',
			res.tablename, res.colname, $1);
	END LOOP;
	DELETE FROM peeps.people WHERE id = $1;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.add_url",
--  args = {"person_id", "url"},
--  method = "POST",
--  url = "/person/([0-9]+)/urls",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.add_url(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	WITH nu AS (
		INSERT INTO peeps.urls(person_id, url)
		VALUES ($1, $2)
		RETURNING *
	)
	SELECT row_to_json(r.*) INTO js FROM nu r;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.add_stat",
--  args = {"person_id", "name", "value"},
--  method = "POST",
--  url = "/person/([0-9]+)/stats",
--  captures = {"person_id"},
--  params = {"name", "value"},
--}
CREATE OR REPLACE FUNCTION peeps.add_stat(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	WITH nu AS (
		INSERT INTO peeps.stats(person_id, statkey, statvalue)
		VALUES ($1, $2, $3)
		RETURNING *
	)
	SELECT row_to_json(r) INTO js FROM (
		SELECT id, created_at, statkey AS name, statvalue AS value FROM nu
	) r;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.new_email",
--  args = {"emailer_id", "person_id", "profile", "subject", "body"},
--  method = "POST",
--  url = "/person/([0-9]+)/emails/([0-9]+)",
--  captures = {"person_id", "emailer_id"},
--  params = {"profile", "subject", "body"},
--}
CREATE OR REPLACE FUNCTION peeps.new_email(integer, integer, text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id (NULL unless reply)
	SELECT * INTO new_id FROM peeps.outgoing_email($1, $2, $3, $3, $4, $5, NULL);
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = new_id;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_person_emails",
--  args = {"person_id"},
--  method = "GET",
--  url = "/person/([0-9]+)/emails",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_full_view
		WHERE person_id = $1
		ORDER BY id
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.merge_person",
--  args = {"keeper_id", "old_id"},
--  method = "POST",
--  url = "/merge/([0-9]+)/([0-9]+)",
--  captures = {"keeper_id", "old_id"},
--}
CREATE OR REPLACE FUNCTION peeps.merge_person(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM person_merge_from_to($2, $1);
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.people_unemailed",
--  method = "GET",
--  url = "/people/unemailed",
--}
CREATE OR REPLACE FUNCTION peeps.people_unemailed(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE email_count = 0
		ORDER BY id DESC
		LIMIT 200
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.people_search",
--  args = {"q"},
--  method = "GET",
--  url = "/people/search",
--  params = {"q"},
--}
CREATE OR REPLACE FUNCTION peeps.people_search(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	q text;
m4_ERRVARS
BEGIN
	q := concat('%', btrim($1, E'\t\r\n '), '%');
	IF LENGTH(q) < 4 THEN
		RAISE 'search term too short';
	END IF;
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT id
			FROM peeps.people
			WHERE name ILIKE q
			OR company ILIKE q
			OR email ILIKE q
		)
		ORDER BY email_count DESC, id DESC
	) r;
	status := 200;
	IF js IS NULL THEN js := '{}'; END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_stat",
--  args = {"id"},
--  method = "GET",
--  url = "/stats/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_stat(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.stats_view r WHERE id=$1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
--  api = "peeps.update_stat",
--  args = {"id", "json"},
--  method = "PUT",
--  url = "/stats/([0-9]+)",
--  captures = {"id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_stat(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.stats', $1, $2,
		core.cols2update('peeps', 'stats', ARRAY['id', 'created_at']));
	js := row_to_json(r.*) FROM peeps.stats_view r WHERE id=$1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_stat",
--  args = {"id"},
--  method = "DELETE",
--  url = "/stats/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_stat(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.stats_view r WHERE id=$1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND RETURN; END IF;
	DELETE FROM peeps.stats WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_url",
--  args = {"id"},
--  method = "GET",
--  url = "/urls/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.urls r WHERE id=$1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_url",
--  args = {"id"},
--  method = "DELETE",
--  url = "/urls/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.urls r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND RETURN; END IF;
	DELETE FROM peeps.urls WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


--JSON allowed: person_id::int, url::text, main::boolean
--Route{
--  api = "peeps.update_url",
--  args = {"id", "json"},
--  method = "PUT",
--  url = "/urls/([0-9]+)",
--  captures = {"id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_url(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.urls', $1, $2,
		core.cols2update('peeps', 'urls', ARRAY['id']));
	js := row_to_json(r.*) FROM peeps.urls r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_formletters",
--  method = "GET",
--  url = "/formletters",
--}
CREATE OR REPLACE FUNCTION peeps.get_formletters(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.formletters_view
		ORDER BY accesskey, title
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


-- TODO: fixtures and tests
CREATE OR REPLACE FUNCTION peeps.get_accesskey_formletters(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT accesskey, title, body
		FROM peeps.formletters
		WHERE accesskey IS NOT NULL
		ORDER BY accesskey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.create_formletter",
--  args = {"title"},
--  method = "POST",
--  url = "/formletters",
--  params = {"title"},
--}
CREATE OR REPLACE FUNCTION peeps.create_formletter(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO peeps.formletters(title) VALUES ($1) RETURNING id INTO new_id;
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = new_id;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_formletter",
--  args = {"id"},
--  method = "GET",
--  url = "/formletters/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_formletter(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--JSON keys: accesskey, title, explanation, body, subject
--Route{
--  api = "peeps.update_formletter",
--  args = {"id", "json"},
--  method = "PUT",
--  url = "/formletters/([0-9]+)",
--  captures = {"id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_formletter(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.formletters', $1, $2,
		core.cols2update('peeps', 'formletters', ARRAY['id', 'created_at']));
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_formletter",
--  args = {"id"},
--  method = "DELETE",
--  url = "/formletters/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_formletter(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND RETURN; END IF;
	DELETE FROM peeps.formletters WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


-- response is a simple JSON object: {"body": "The parsed text here, Derek."}
-- If wrong IDs given, value is null
--Route{
--  api = "peeps.parsed_formletter",
--  args = {"person_id", "formletter_id"},
--  method = "GET",
--  url = "/parsed_fomletter/([0-9]+)/([0-9]+)",
--  captures = {"person_id", "formletter_id"},
--}
CREATE OR REPLACE FUNCTION peeps.parsed_formletter(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_build_object('body', parse_formletter_body($1, $2));
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.send_person_formletter",
--  args = {"person_id", "formletter_id", "profile"},
--  method = "POST",
--  url = "/send_fomletter/([0-9]+)/([0-9]+)/([a-z@]+)",
--  captures = {"person_id", "formletter_id", "profile"},
--}
CREATE OR REPLACE FUNCTION peeps.send_person_formletter(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	-- outgoing_email params: emailer_id (2=robot), person_id, profile, category,
	-- subject, body, reference_id
	SELECT outgoing_email INTO email_id
	FROM peeps.outgoing_email(2, $1, $3, $3,
		(SELECT subject FROM peeps.parse_formletter_subject($1, $2)),
		(SELECT body FROM peeps.parse_formletter_body($1, $2)),
		NULL);
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;


-- sets newpass if none, sends email if not already sent recently
--Route{
--  api = "peeps.reset_email",
--  args = {"formletter_id", "email"},
--  method = "POST",
--  url = "/reset_email/([0-9]+)",
--  captures = {"formletter_id"},
--  params = {"email"},
--}
CREATE OR REPLACE FUNCTION peeps.reset_email(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.get_person_id_from_email($2);
	IF pid IS NULL THEN m4_NOTFOUND ELSE
		PERFORM peeps.make_newpass(pid);
		SELECT x.status, x.js INTO status, js
		FROM peeps.send_person_formletter(pid, $1, 'sivers') x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- RETURNS array of objects:
-- [{"code":"AF","name":"Afghanistan"},{"code":"AX","name":"Åland Islands"}..]
--Route{
--  api = "peeps.all_countries",
--  method = "GET",
--  url = "/countries",
--}
CREATE OR REPLACE FUNCTION peeps.all_countries(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (SELECT * FROM peeps.countries ORDER BY name) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


-- RETURNS single code:name object:
-- {"AD":"Andorra","AE":"United Arab Emirates...  }
--Route{
--  api = "peeps.country_names",
--  method = "GET",
--  url = "/country/names",
--}
CREATE OR REPLACE FUNCTION peeps.country_names(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_object(
		ARRAY(SELECT code FROM countries ORDER BY code),
		ARRAY(SELECT name FROM countries ORDER BY code));
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.country_count",
--  method = "GET",
--  url = "/country/count",
--}
CREATE OR REPLACE FUNCTION peeps.country_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT country, COUNT(*)
		FROM peeps.people
		WHERE country IS NOT NULL
		GROUP BY country
		ORDER BY COUNT(*) DESC, country
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.state_count",
--  args = {"country"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/states",
--  captures = {"country"},
--}
CREATE OR REPLACE FUNCTION peeps.state_count(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT state, COUNT(*)
		FROM peeps.people
		WHERE country = $1
		AND state IS NOT NULL
		AND state != ''
		GROUP BY state
		ORDER BY COUNT(*) DESC, state
	) r;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.city_count",
--  args = {"country", "state"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/([^/]+)/cities",
--  captures = {"country", "state"},
--}
CREATE OR REPLACE FUNCTION peeps.city_count(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT city, COUNT(*)
		FROM peeps.people
		WHERE country = $1
		AND state = $2
		AND (city IS NOT NULL AND city != '')
		GROUP BY city
		ORDER BY COUNT(*) DESC, city
	) r;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.city_count",
--  args = {"country"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/cities",
--  captures = {"country"},
--}
CREATE OR REPLACE FUNCTION peeps.city_count(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT city, COUNT(*)
		FROM peeps.people
		WHERE country = $1
		AND (city IS NOT NULL AND city != '')
		GROUP BY city
		ORDER BY COUNT(*) DESC, city
	) r;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.people_from_country",
--  args = {"country"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/people",
--  captures = {"country"},
--}
CREATE OR REPLACE FUNCTION peeps.people_from_country(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT id FROM peeps.people WHERE country=$1
		)
		ORDER BY email_count DESC, name
	) r;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.people_from_state",
--  args = {"country", "state"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/([^/]+)/people",
--  captures = {"country", "state"},
--}
CREATE OR REPLACE FUNCTION peeps.people_from_state(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT id
			FROM peeps.people
			WHERE country = $1
			AND state = $2
		)
		ORDER BY email_count DESC, name
	) r;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.people_from_city",
--  args = {"country", "city"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/city/([^/]+)/people",
--  captures = {"country", "city"},
--}
CREATE OR REPLACE FUNCTION peeps.people_from_city(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT id
			FROM peeps.people
			WHERE country = $1
			AND city = $2
		)
		ORDER BY email_count DESC, name
	) r;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.people_from_state_city",
--  args = {"country", "state", "city"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/([^/]+)/([^/]+)/people",
--  captures = {"country", "state", "city"},
--}
CREATE OR REPLACE FUNCTION peeps.people_from_state_city(char(2), text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT id
			FROM peeps.people
			WHERE country = $1
			AND state = $2
			AND city = $3
		)
		ORDER BY email_count DESC, name
	) r;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
--  api = "peeps.get_stats",
--  args = {"name", "value"},
--  method = "GET",
--  url = "/stats/([a-z0-9._-]+)/value/(.+)",
--  captures = {"name", "value"},
--}
CREATE OR REPLACE FUNCTION peeps.get_stats(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.stats_view
		WHERE name = $1
		AND value = $2
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_stats",
--  args = {"name"},
--  method = "GET",
--  url = "/stats/([a-z0-9._-]+)",
--  captures = {"name"},
--}
CREATE OR REPLACE FUNCTION peeps.get_stats(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT * FROM peeps.stats_view WHERE name = $1
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_stat_value_count",
--  args = {"name"},
--  method = "GET",
--  url = "/stats/([a-z0-9._-]+)/count",
--  captures = {"name"},
--}
CREATE OR REPLACE FUNCTION peeps.get_stat_value_count(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT statvalue AS value, COUNT(*) AS count
		FROM peeps.stats
		WHERE statkey = $1
		GROUP BY statvalue
		ORDER BY statvalue
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_stat_name_count",
--  method = "GET",
--  url = "/stats",
--}
CREATE OR REPLACE FUNCTION peeps.get_stat_name_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT statkey AS name, COUNT(*) AS count
		FROM peeps.stats
		GROUP BY statkey
		ORDER BY statkey
	) r;
END;
$$ LANGUAGE plpgsql;


--JSON keys: profile category message_id their_email their_name subject headers body
--Route{
--  api = "peeps.import_email",
--  args = {"json"},
--  method = "POST",
--  url = "/email/import",
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.import_email(json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
	pid integer;
	rid integer;
m4_ERRVARS
BEGIN
	-- insert as-is (easier to update once in database)
	-- created_by = 2  TODO: created_by=NULL for imports?
	INSERT INTO peeps.emails (
		created_by,
		profile,
		category,
		message_id,
		their_email,
		their_name,
		subject,
		headers,
		body
	) SELECT
		2 AS created_by,
		profile,
		category,
		message_id,
		their_email,
		their_name,
		subject,
		headers,
		body
	FROM json_populate_record(null::peeps.emails, $1)
	RETURNING id INTO eid;
	-- if references.message_id found, update person_id, reference_id, category
	IF json_array_length($1 -> 'references') > 0 THEN
		UPDATE peeps.emails
		SET person_id = ref.person_id,
		reference_id = ref.id,
		category = COALESCE(peeps.people.categorize_as, peeps.emails.profile)
		FROM peeps.emails ref, peeps.people
		WHERE peeps.emails.id = eid
		AND ref.person_id = peeps.people.id
		AND ref.message_id IN (
			SELECT * FROM json_array_elements_text($1 -> 'references')
		)
		RETURNING emails.person_id, ref.id INTO pid, rid;
		IF rid IS NOT NULL THEN
			UPDATE peeps.emails SET answer_id = eid WHERE id = rid;
		END IF;
	END IF;
	-- if their_email is found, update person_id, category
	IF pid IS NULL THEN
		UPDATE peeps.emails e
		SET person_id = p.id,
			category = COALESCE(p.categorize_as, e.profile)
		FROM peeps.people p
		WHERE e.id = eid
		AND (p.email = e.their_email OR p.company = e.their_email)
		RETURNING e.person_id INTO pid;
	END IF;
	-- if still not found, set category to fix-client (TODO: make this unnecessary)
	IF pid IS NULL THEN
		UPDATE peeps.emails
		SET category = 'fix-client'
		WHERE id = eid
		RETURNING person_id INTO pid;
	END IF;
	-- insert attachments
	IF json_array_length($1 -> 'attachments') > 0 THEN
		INSERT INTO peeps.email_attachments(email_id, mime_type, filename, bytes)
		SELECT eid AS email_id, mime_type, filename, bytes
		FROM json_populate_recordset(null::peeps.email_attachments, $1 -> 'attachments');
	END IF;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- Update mailing list settings for this person (whether new or existing)
-- listype should be: all, some, none, or dead
--Route{
--  api = "peeps.list_update",
--  args = {"name", "email", "listype"},
--  method = "POST",
--  url = "/list",
--  params = {"name", " email", " listype"},
--}
CREATE OR REPLACE FUNCTION peeps.list_update(text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	clean3 text;
m4_ERRVARS
BEGIN
	clean3 := regexp_replace($3, '[^a-z]', '', 'g');
	SELECT id INTO pid
	FROM peeps.person_create($1, $2);
	INSERT INTO peeps.stats(person_id, statkey, statvalue)
	VALUES (pid, 'listype', clean3);
	UPDATE peeps.people
	SET listype = clean3
	WHERE id = pid;
	status := 200;
	js := json_build_object('list', clean3);
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.queued_emails",
--  method = "GET",
--  url = "/emails/queued",
--}
CREATE OR REPLACE FUNCTION peeps.queued_emails(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT e.id,
		e.profile,
		e.their_email,
		e.subject,
		e.body,
		e.message_id,
		ref.message_id AS referencing,
		peeps.quoted(ref.body) AS reftext
		FROM peeps.emails e
			LEFT JOIN peeps.emails ref ON e.reference_id = ref.id
		WHERE e.outgoing IS NULL
		ORDER BY e.id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.email_is_sent",
--  args = {"id"},
--  method = "PUT",
--  url = "/emails/([0-9]+)/sent",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.email_is_sent(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.emails
	SET outgoing = TRUE
	WHERE id = $1;
	IF NOT FOUND THEN m4_NOTFOUND RETURN; END IF;
	js := json_build_object('sent', $1);
	status := 200;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.sent_emails",
--  args = {"howmany"},
--  method = "GET",
--  url = "/emails/sent/([0-9]+)",
--  captures = {"howmany"},
--}
CREATE OR REPLACE FUNCTION peeps.sent_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_view
		WHERE id IN (
			SELECT id
			FROM peeps.emails
			WHERE outgoing IS TRUE
			ORDER BY id DESC
			LIMIT $1
		)
		ORDER BY id DESC
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.sent_emails_grouped",
--  method = "GET",
--  url = "/emails/sent",
--}
CREATE OR REPLACE FUNCTION peeps.sent_emails_grouped(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT p.id, p.name, (
			SELECT json_agg(x) AS sent
			FROM (
				SELECT id, subject, created_at, their_name, their_email
				FROM peeps.emails
				WHERE closed_by = e.id
				AND outgoing IS TRUE
				AND closed_at > (NOW() - interval '9 days')
				ORDER BY id DESC
			) x
		)
		FROM peeps.emailers e, peeps.people p
		WHERE e.person_id = p.id
		AND e.id IN (
			SELECT DISTINCT(created_by)
			FROM peeps.emails
			WHERE closed_at > (NOW() - interval '9 days')
			AND outgoing IS TRUE
		)
		ORDER BY e.id DESC
	) r;
END;
$$ LANGUAGE plpgsql;


--returns array of {person_id: 1234, twitter: 'username'}
--Route{
--  api = "peeps.twitter_unfollowed",
--  method = "GET",
--  url = "/twitter/unfollowed",
--}
CREATE OR REPLACE FUNCTION peeps.twitter_unfollowed(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT person_id,
		regexp_replace(regexp_replace(url, 'https?://twitter.com/', ''), '/$', '')
		AS twitter
		FROM peeps.urls
		WHERE url LIKE '%twitter.com%'
		AND person_id NOT IN (
			SELECT person_id
			FROM peeps.stats
			WHERE statkey = 'twitter'
		)
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.dead_email",
--  args = {"person_id"},
--  method = "PUT",
--  url = "/person/([0-9]+)/dead",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.dead_email(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.people
	SET
		email = NULL,
		listype = NULL,
		notes = CONCAT('DEAD EMAIL: ', email, E'\n', notes)
	WHERE id = $1
	AND email IS NOT NULL;
	IF NOT FOUND THEN m4_NOTFOUND RETURN; END IF;
	status := 200;
	js := json_build_object('ok', $1);
END;
$$ LANGUAGE plpgsql;


-- ARRAY of schema.tablenames where with this person_id
--Route{
--  api = "peeps.tables_with_person",
--  args = {"id"},
--  method = "GET",
--  url = "/person/([0-9]+)/tables",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.tables_with_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	res RECORD;
	tablez text[] := ARRAY[]::text[];
	rowcount integer;
BEGIN
	FOR res IN
		SELECT *
		FROM core.tables_referencing('peeps', 'people', 'id')
	LOOP
		EXECUTE format ('SELECT 1 FROM %s WHERE %I = %s',
			res.tablename, res.colname, $1);
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount > 0 THEN
			tablez := tablez || res.tablename;
		END IF;
	END LOOP;
	status := 200;
	js := array_to_json(tablez);
END;
$$ LANGUAGE plpgsql;


-- Array of people's [[id, email, address, lopass]] for emailing
-- PARAMS: key,val to be used in WHERE _key_ = _val_
--Route{
--  api = "peeps.ieal_where",
--  args = {"k", "v"},
--  method = "GET",
--  url = "/list/([a-z_]+)/(.+)",
--  captures = {"k", "v"},
--}
CREATE OR REPLACE FUNCTION peeps.ieal_where(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	EXECUTE format ('
		SELECT json_agg(j)
		FROM (
			SELECT json_build_array(id, email, address, lopass) AS j
			FROM peeps.people
			WHERE email IS NOT NULL
			AND %I = %L
			ORDER BY id
		) r', $1, $2
	) INTO js;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.log",
--  args = {"person_id", "schema", "table", "id"},
--  method = "POST",
--  url = "/log/([0-9]+)/([a-z]+)/([a-z_]+)/([0-9]+)",
--  captures = {"person_id", "schema", "table", "id"},
--}
CREATE OR REPLACE FUNCTION peeps.log(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := '{}';
	INSERT INTO core.changelog(person_id, schema_name, table_name, table_id)
		VALUES($1, $2, $3, $4);
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.inspections_grouped",
--  method = "GET",
--  url = "/inspect",
--}
CREATE OR REPLACE FUNCTION peeps.inspections_grouped(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT schema_name, table_name, COUNT(*)
		FROM core.changelog
		WHERE approved IS FALSE
		GROUP BY schema_name, table_name
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.inspect_peeps_people",
--  method = "GET",
--  url = "/inspect/people",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_peeps_people(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, city, state, country, email
		FROM core.changelog c
			LEFT JOIN peeps.people p
			ON c.table_id=p.id
		WHERE c.approved IS FALSE
		AND schema_name='peeps'
		AND table_name='people'
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.inspect_peeps_urls",
--  method = "GET",
--  url = "/inspect/urls",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_peeps_urls(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, url
		FROM core.changelog c
			LEFT JOIN peeps.urls u
			ON c.table_id = u.id
		WHERE c.approved IS FALSE
		AND schema_name = 'peeps'
		AND table_name = 'urls'
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.inspect_peeps_stats",
--  method = "GET",
--  url = "/inspect/stats",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_peeps_stats(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, statkey, statvalue
		FROM core.changelog c
			LEFT JOIN peeps.stats s
			ON c.table_id = s.id
		WHERE c.approved IS FALSE
		AND schema_name = 'peeps'
		AND table_name = 'stats'
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.inspect_now_urls",
--  method = "GET",
--  url = "/inspect/now",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_now_urls(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, short, long
		FROM core.changelog c
			LEFT JOIN now.urls u
			ON c.table_id = u.id
		WHERE c.approved IS FALSE
		AND schema_name = 'now'
		AND table_name = 'urls'
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: JSON array of integer ids: core.changelog.id
--Route{
--  api = "peeps.log_approve",
--  args = {"json"},
--  method = "POST",
--  url = "/inspect",
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.log_approve(json,
	OUT status smallint, OUT js json) AS $$
BEGIN
-- TODO: cast JSON array elements as ::integer instead of casting id::text
	UPDATE core.changelog
	SET approved=TRUE
	WHERE id::text IN (
		SELECT * FROM json_array_elements_text($1)
	);
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;


-- *all* attribute keys, sorted, and if we have attributes for this person,
-- then those values are here, but returns null values for any not found
--Route{
--  api = "peeps.person_attributes",
--  args = {"id"},
--  method = "GET",
--  url = "/person/([0-9]+)/attributes",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.person_attributes(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT atkey, plusminus
		FROM peeps.atkeys
			LEFT JOIN peeps.attributes ON (
				peeps.atkeys.atkey = peeps.attributes.attribute
				AND peeps.attributes.person_id = $1
			)
		ORDER BY peeps.atkeys.atkey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


-- list of interests and boolean expert flag (not null) for person_id
-- expertises first, wantings last
--Route{
--  api = "peeps.person_interests",
--  args = {"id"},
--  method = "GET",
--  url = "/person/([0-9]+)/interests",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.person_interests(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT interest, expert
		FROM peeps.interests
		WHERE person_id = $1
		ORDER BY expert DESC, interest ASC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.person_set_attribute",
--  args = {"id", "attribute", "true"},
--  method = "PUT",
--  url = "/person/([0-9]+)/attributes/([a-z-]+)/plus",
--  captures = {"id", "attribute"},
--}
CREATE OR REPLACE FUNCTION peeps.person_set_attribute(integer, text, boolean,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.attributes
	SET plusminus = $3
	WHERE person_id = $1
	AND attribute = $2;
	IF NOT FOUND THEN
		INSERT INTO peeps.attributes VALUES ($1, $2, $3);
	END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.person_attributes($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.person_set_attribute",
--  args = {"id", "attribute", "false"},
--  method = "PUT",
--  url = "/person/([0-9]+)/attributes/([a-z-]+)/minus",
--  captures = {"id", "attribute"},
--}
CREATE OR REPLACE FUNCTION peeps.person_delete_attribute(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM peeps.attributes
	WHERE person_id = $1
	AND attribute = $2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_attributes($1) x;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.person_add_interest",
--  args = {"id", "interest"},
--  method = "POST",
--  url = "/person/([0-9]+)/interests/([a-z]+)",
--  captures = {"id", "interest"},
--}
CREATE OR REPLACE FUNCTION peeps.person_add_interest(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM 1 FROM peeps.interests
	WHERE person_id = $1
	AND interest = $2;
	IF NOT FOUND THEN
		INSERT INTO peeps.interests(person_id, interest) VALUES ($1, $2);
	END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- use to set expert flag to existing
--Route{
--  api = "peeps.person_update_interest",
--  args = {"id", "interest", "true"},
--  method = "POST",
--  url = "/person/([0-9]+)/interests/([a-z]+)/plus",
--  captures = {"id", "interest"},
--}
CREATE OR REPLACE FUNCTION peeps.person_update_interest(integer, text, boolean,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.interests
	SET expert = $3
	WHERE person_id = $1
	AND interest = $2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.person_delete_interest",
--  args = {"id", "interest"},
--  method = "DELETE",
--  url = "/person/([0-9]+)/interests/([a-z]+)",
--  captures = {"id", "interest"},
--}
CREATE OR REPLACE FUNCTION peeps.person_delete_interest(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM peeps.interests
	WHERE person_id = $1
	AND interest = $2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.attribute_keys",
--  method = "GET",
--  url = "/attributes",
--}
CREATE OR REPLACE FUNCTION peeps.attribute_keys(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT atkey, description
		FROM peeps.atkeys
		ORDER BY atkey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.add_attribute_key",
--  args = {"attribute"},
--  method = "POST",
--  url = "/attributes/([a-z-]+)",
--  captures = {"attribute"},
--}
CREATE OR REPLACE FUNCTION peeps.add_attribute_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	INSERT INTO peeps.atkeys(atkey) VALUES ($1);
	SELECT x.status, x.js INTO status, js FROM peeps.attribute_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_attribute_key",
--  args = {"attribute"},
--  method = "DELETE",
--  url = "/attributes/([a-z-]+)",
--  captures = {"attribute"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_attribute_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	DELETE FROM peeps.atkeys WHERE atkey = $1;
	SELECT x.status, x.js INTO status, js FROM peeps.attribute_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.update_attribute_key",
--  args = {"attribute", "description"},
--  method = "PUT",
--  url = "/attributes/([a-z-]+)",
--  captures = {"attribute"},
--  params = {"description"},
--}
CREATE OR REPLACE FUNCTION peeps.update_attribute_key(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.atkeys
	SET description = $2
	WHERE atkey = $1;
	SELECT x.status, x.js INTO status, js FROM peeps.attribute_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.interest_keys",
--  method = "GET",
--  url = "/interests",
--}
CREATE OR REPLACE FUNCTION peeps.interest_keys(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT inkey, description
		FROM peeps.inkeys
		ORDER BY inkey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.add_interest_key",
--  args = {"interest"},
--  method = "POST",
--  url = "/interests/([a-z]+)",
--  captures = {"interest"},
--}
CREATE OR REPLACE FUNCTION peeps.add_interest_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	INSERT INTO peeps.inkeys(inkey) VALUES ($1);
	SELECT x.status, x.js INTO status, js FROM peeps.interest_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.delete_interest_key",
--  args = {"interest"},
--  method = "DELETE",
--  url = "/interests/([a-z]+)",
--  captures = {"interest"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_interest_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	DELETE FROM peeps.inkeys
	WHERE inkey = $1;
	SELECT x.status, x.js INTO status, js FROM peeps.interest_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.update_interest_key",
--  args = {"interest", "description"},
--  method = "PUT",
--  url = "/interests/([a-z]+)",
--  captures = {"interest"},
--  params = {"description"},
--}
CREATE OR REPLACE FUNCTION peeps.update_interest_key(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.inkeys
	SET description = $2
	WHERE inkey = $1;
	SELECT x.status, x.js INTO status, js FROM peeps.interest_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- Finds interest words in email body that are not yet in person's interests
--Route{
--  api = "peeps.interests_in_email",
--  args = {"id"},
--  method = "GET",
--  url = "/emails/([0-9]+)/interests",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.interests_in_email(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := to_json(ARRAY(
		SELECT inkey
		FROM peeps.inkeys
		WHERE inkey IN (
			SELECT regexp_split_to_table(lower(body), '[^a-z]+')
			FROM peeps.emails
			WHERE id = $1
		)
		AND inkey NOT IN (
			SELECT interest
			FROM peeps.interests
				JOIN peeps.emails
				ON peeps.emails.person_id = peeps.interests.person_id
			WHERE peeps.emails.id = $1
		)
	));
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.people_with_interest",
--  args = {"interest", "expert"},
--  method = "GET",
--  url = "/people/interest",
--  params = {"interest", "expert"},
--}
CREATE OR REPLACE FUNCTION peeps.people_with_interest(text, boolean,
	OUT status smallint, OUT js json) AS $$
BEGIN
	-- if invalid interest key, return 404 instead of query
	PERFORM 1 FROM peeps.inkeys WHERE inkey = $1;
	IF NOT FOUND THEN m4_NOTFOUND RETURN; END IF;
	status := 200;
	-- if 2nd param is NULL then ignore expert flag, else use it
	IF $2 IS NULL THEN
		js := json_agg(r) FROM (
			SELECT *
			FROM peeps.people_view
			WHERE id IN (
				SELECT person_id
				FROM peeps.interests
				WHERE interest = $1
			)
			ORDER BY email_count DESC, id DESC
		) r;
	ELSE
		js := json_agg(r) FROM (
			SELECT *
			FROM peeps.people_view
			WHERE id IN (
				SELECT person_id
				FROM peeps.interests
				WHERE interest = $1
				AND expert = $2
			)
			ORDER BY email_count DESC, id DESC
		) r;
	END IF;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- NOTE: plusminus but NOT be NULL (unlike interests.expert param)
--Route{
--  api = "peeps.people_with_attribute",
--  args = {"attribute", "plusminus"},
--  method = "GET",
--  url = "/people/attribute",
--  params = {"attribute", "plusminus"},
--}
CREATE OR REPLACE FUNCTION peeps.people_with_attribute(text, boolean,
	OUT status smallint, OUT js json) AS $$
BEGIN
	-- if plusminus is null, return 404 instead of query
	IF $2 IS NULL THEN m4_NOTFOUND RETURN; END IF;
	-- if invalid attribute key, return 404 instead of query
	PERFORM 1 FROM peeps.atkeys WHERE atkey = $1;
	IF NOT FOUND THEN m4_NOTFOUND RETURN; END IF;
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT person_id
			FROM peeps.attributes
			WHERE attribute = $1
			AND plusminus = $2
		)
		ORDER BY email_count DESC, id DESC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.tweets_by_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, created_at, message, reference_id
		FROM peeps.tweets
		WHERE person_id = $1
		ORDER BY id DESC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: tweets.id
CREATE OR REPLACE FUNCTION peeps.get_tweet(bigint,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id,
			created_at,
			person_id,
			handle,
			message,
			reference_id,
			seen
		FROM peeps.tweets
		WHERE id = $1
	) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: json from Twitter API as seen here:
-- https://dev.twitter.com/rest/reference/get/statuses/mentions_timeline
CREATE OR REPLACE FUNCTION peeps.add_tweet(jsonb,
	OUT status smallint, OUT js jsonb) AS $$
DECLARE
	new_id bigint;
	new_ca timestamp(0) with time zone;
	new_handle varchar(15);
	new_pid integer;
	new_msg text;
	new_ref bigint;
	r record;
m4_ERRVARS
BEGIN
	new_id := ($1->>'id')::bigint;
	status := 200;
	js := json_build_object('id', new_id);
	-- If already exists, don't insert. just return status+js now.
	PERFORM 1 FROM peeps.tweets WHERE id = new_id;
	IF FOUND THEN RETURN; END IF;
	new_ca := $1->>'created_at';
	new_handle := $1->'user'->>'screen_name';
	new_pid := peeps.pid_for_twitter_handle(new_handle);
	new_msg := replace($1->>'text', E'\n', ' ');
	FOR r IN
		SELECT *
		FROM jsonb_array_elements($1->'entities'->'urls')
	LOOP
		new_msg := replace(new_msg, r.value->>'url', r.value->>'expanded_url');
	END LOOP;
	IF LENGTH($1->>'in_reply_to_status_id') > 0 THEN
		new_ref := ($1->>'in_reply_to_status_id')::bigint;
	END IF;
	INSERT INTO peeps.tweets (
		entire,
		id,
		created_at,
		handle,
		person_id,
		message,
		reference_id
	) VALUES (
		$1,
		new_id,
		new_ca,
		new_handle,
		new_pid,
		new_msg,
		new_ref
	);
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: limit number to see
CREATE OR REPLACE FUNCTION peeps.tweets_unseen(integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id,
			handle,
			person_id,
			message,
			entire->'user'->>'name' AS name
		FROM peeps.tweets
		WHERE seen IS NOT TRUE
		ORDER BY id DESC
		LIMIT $1
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: peeps.tweets.id
-- marks a tweet as seen
CREATE OR REPLACE FUNCTION peeps.tweet_seen(bigint,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	UPDATE peeps.tweets
	SET seen = TRUE
	WHERE id = $1;
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: peeps.tweets.id, person_id
-- marks a tweets.handle as being this person
CREATE OR REPLACE FUNCTION peeps.tweets_handle_person(text, integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	UPDATE peeps.tweets
	SET person_id = $2
	WHERE handle = $1;
	SELECT x.status, x.js INTO status, js FROM peeps.tweets_by_person($2) x;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: limit number to see
CREATE OR REPLACE FUNCTION peeps.tweets_unknown_new(integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT handle, entire->'user'->>'name' AS name
		FROM peeps.tweets
		WHERE person_id IS NULL
		ORDER BY id DESC
		LIMIT $1
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: limit number to see
CREATE OR REPLACE FUNCTION peeps.tweets_unknown_top(integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT handle, entire->'user'->>'name' AS name
		FROM peeps.tweets
		WHERE person_id IS NULL
		GROUP BY handle, name
		ORDER BY COUNT(*) DESC
		LIMIT $1
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: emailer_id
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
			ORDER BY id DESC LIMIT 1;
		UPDATE peeps.people
			SET checked_by = $1
			WHERE id = person_id;
	END IF;
	status := 200;
	js := jsonb_build_object('person_id', person_id);
END;
$$ LANGUAGE plpgsql;


-- status only: this emailer_id has permission to update this person_id?
-- PARAMS: emailer_id, person_id
CREATE OR REPLACE FUNCTION peeps.kyc_ok_person(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := '{}';
	PERFORM 1 FROM peeps.people
		WHERE id = $2
		AND checked_by = $1
		AND checked_at IS NULL;
	IF NOT FOUND THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: emailer_id, person_id
CREATE OR REPLACE FUNCTION peeps.kyc_get_person(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.kyc_view r
		WHERE id = $2
		AND checked_by = $1
		AND checked_at IS NULL;
	status := 200;
	IF js IS NULL THEN m4_NOTFOUND END IF;
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


CREATE OR REPLACE FUNCTION peeps.kyc_recent(
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, name, email, checked_by, checked_at
		FROM peeps.people
		WHERE checked_by IN (18, 19)
		ORDER BY checked_by ASC, checked_at DESC
		LIMIT 500
	) r;
END;
$$ LANGUAGE plpgsql;

