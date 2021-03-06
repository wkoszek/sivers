----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- POST /login
-- PARAMS: email, password
CREATE OR REPLACE FUNCTION woodegg.login(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	cook text;
BEGIN
	SELECT p.id INTO pid
		FROM peeps.person_email_pass($1, $2) p, woodegg.customers c
		WHERE p.id=c.person_id;
	IF pid IS NOT NULL THEN
		SELECT cookie INTO cook FROM peeps.login_person_domain(pid, 'woodegg.com');
	END IF;
	IF cook IS NULL THEN m4_NOTFOUND ELSE
		status := 200;
		js := json_build_object('cookie', cook);
	END IF;
EXCEPTION WHEN OTHERS THEN m4_NOTFOUND
END;
$$ LANGUAGE plpgsql;


-- GET /customer/{cookie}
-- PARAMS: cookie string
CREATE OR REPLACE FUNCTION woodegg.get_customer(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT c.id, p.name
		FROM peeps.people p, woodegg.customers c
		WHERE p.id = peeps.get_person_id_from_cookie($1)
		AND p.id = c.person_id
	) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /reset/{reset_string}
-- PARAMS: 8-char string from https://woodegg.com/reset/:str
CREATE OR REPLACE FUNCTION woodegg.get_customer_reset(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	cid integer;
BEGIN
	SELECT p.id, c.id INTO pid, cid
		FROM peeps.people p, woodegg.customers c
		WHERE p.newpass=$1
		AND p.id=c.person_id;
	IF pid IS NULL THEN m4_NOTFOUND ELSE
		status := 200;
		-- this is just acknowledgement that it's approved to show reset form:
		js := json_build_object('person_id', pid, 'customer_id', cid, 'reset', $1);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- POST /reset/{reset_string}
-- PARAMS: reset string, new password
CREATE OR REPLACE FUNCTION woodegg.set_customer_password(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	cid integer;
m4_ERRVARS
BEGIN
	SELECT p.id, c.id INTO pid, cid
		FROM peeps.people p, woodegg.customers c
		WHERE p.newpass=$1
		AND p.id=c.person_id;
	IF pid IS NULL THEN m4_NOTFOUND ELSE
		PERFORM peeps.set_hashpass(pid, $2);
		status := 200;
		-- this is just acknowledgement that it's done:
		js := row_to_json(r) FROM (SELECT id, name, email, address
			FROM peeps.people WHERE id=pid) r;
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- POST /register
-- PARAMS: name, email, password, proof
CREATE OR REPLACE FUNCTION woodegg.register(text, text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT id INTO pid FROM peeps.person_create_pass($1, $2, $3);
	INSERT INTO peeps.stats(person_id, statkey, statvalue)
		VALUES (pid, 'proof-we14asia', $4);
	status := 200;
	js := row_to_json(r) FROM (SELECT id, name, email, address
		FROM peeps.people WHERE id=pid) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- POST /forgot
-- PARAMS: email
CREATE OR REPLACE FUNCTION woodegg.forgot(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	pnp text;
m4_ERRVARS
BEGIN
	SELECT p.id, p.newpass INTO pid, pnp FROM peeps.people p, woodegg.customers c
		WHERE p.id=c.person_id AND p.email = lower(regexp_replace($1, '\s', '', 'g'));
	IF pid IS NULL THEN m4_NOTFOUND ELSE
		IF pnp IS NULL THEN
			UPDATE peeps.people SET
			newpass = core.unique_for_table_field(8, 'peeps.people', 'newpass')
			WHERE id = pid RETURNING newpass INTO pnp;
		END IF;
		-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id
		PERFORM peeps.outgoing_email(1, pid, 'we@woodegg', 'we@woodegg',
			'your Wood Egg password reset link',
			'Click to reset your password:\n\nhttps://woodegg.com/reset/' || pnp,
			NULL);
		status := 200;
		js := row_to_json(r) FROM (SELECT id, name, email, address
			FROM peeps.people WHERE id=pid) r;
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /researchers/1
-- PARAMS: researcher_id
CREATE OR REPLACE FUNCTION woodegg.get_researcher(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.researcher_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /writers/1
-- PARAMS: writer_id
CREATE OR REPLACE FUNCTION woodegg.get_writer(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.writer_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /editors/1
-- PARAMS: editor_id
CREATE OR REPLACE FUNCTION woodegg.get_editor(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.editor_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /country/KR
-- PARAMS: country code
CREATE OR REPLACE FUNCTION woodegg.get_country(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	rowcount integer;
BEGIN
	-- stop here if country code invalid (using books because least # of rows)
	SELECT COUNT(*) INTO rowcount FROM woodegg.books WHERE country=$1;
	IF rowcount = 0 THEN m4_NOTFOUND RETURN; END IF;
	status := 200;
	-- JSON here instead of VIEW because needs $1 for q.country join inside query
	js := json_agg(cv) FROM (SELECT id, topic, (SELECT json_agg(st) AS subtopics FROM
		(SELECT id, subtopic, (SELECT json_agg(qs) AS questions FROM
			(SELECT q.id, q.question FROM woodegg.questions q, woodegg.template_questions tq
				WHERE q.template_question_id=tq.id AND subtopic_id=sub.id
				AND q.country=$1 ORDER BY q.id) qs)
			FROM woodegg.subtopics sub WHERE woodegg.topics.id=topic_id ORDER BY id) st)
		FROM woodegg.topics ORDER BY id) cv;
END;
$$ LANGUAGE plpgsql;


-- GET /questions/1234
-- PARAMS: question id
CREATE OR REPLACE FUNCTION woodegg.get_question(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.question_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /books/23 
-- PARAMS: book id
CREATE OR REPLACE FUNCTION woodegg.get_book(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.book_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /templates
CREATE OR REPLACE FUNCTION woodegg.get_templates(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM woodegg.templates_view) r;
END;
$$ LANGUAGE plpgsql;


-- GET /templates/123
-- PARAMS: template id
CREATE OR REPLACE FUNCTION woodegg.get_template(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.template_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /topics/5
-- PARAMS: topic id
CREATE OR REPLACE FUNCTION woodegg.get_topic(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.templates_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /uploads/KR
-- PARAMS: country code
CREATE OR REPLACE FUNCTION woodegg.get_uploads(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM woodegg.uploads_view WHERE country=$1) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /uploads/33
-- PARAMS: upload id#
CREATE OR REPLACE FUNCTION woodegg.get_upload(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM woodegg.upload_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- ADMIN ONLY:
CREATE OR REPLACE FUNCTION woodegg.proofs(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT u.id, u.person_id, u.statvalue AS value,
		u.created_at, p.email, p.name
		FROM peeps.stats u
		INNER JOIN peeps.people p ON u.person_id=p.id
		WHERE statkey LIKE 'proof%' ORDER BY u.id) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- ADMIN ONLY:
-- PARAMS: stats.id
CREATE OR REPLACE FUNCTION woodegg.proof_to_customer(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	cid integer;
BEGIN
	UPDATE peeps.stats SET statkey=REPLACE(statkey, 'proof', 'bought')
		WHERE id=$1 RETURNING person_id INTO pid;
	SELECT id INTO cid FROM woodegg.customers WHERE person_id=pid;
	IF cid IS NULL THEN
		INSERT INTO woodegg.customers(person_id) VALUES (pid) RETURNING id INTO cid;
	END IF;
	PERFORM peeps.send_person_formletter(pid, 2, 'sivers');
	status := 200;
	js := json_build_object('person_id', pid, 'customer_id', cid);
END;
$$ LANGUAGE plpgsql;


