----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

--Route{
-- api = "muckwork.auth_client",
-- args = {"email", "password"},
-- method = "GET",
-- url = "/auth/client",
-- params = {"email", "password"},
-- note = "RESPONSE: {client_id: #, person_id: #} or not found",
--}
CREATE OR REPLACE FUNCTION muckwork.auth_client(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	p peeps.people;
	i integer;
BEGIN
	SELECT * INTO p FROM peeps.person_email_pass($1, $2);
	IF p IS NULL THEN m4_NOTFOUND ELSE
		SELECT id INTO i
		FROM muckwork.clients
		WHERE person_id = p.id;
		IF i IS NULL THEN m4_NOTFOUND ELSE
			status := 200;
			js := json_build_object('client_id', i, 'person_id', p.id);
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.auth_worker",
-- args = {"email", "password"},
-- method = "GET",
-- url = "/auth/worker",
-- params = {"email", "password"},
-- note = "RESPONSE: {worker_id: #, person_id: #} or not found",
--}
CREATE OR REPLACE FUNCTION muckwork.auth_worker(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	p peeps.people;
	i integer;
BEGIN
	SELECT * INTO p FROM peeps.person_email_pass($1, $2);
	IF p IS NULL THEN m4_NOTFOUND ELSE
		SELECT id INTO i
		FROM muckwork.workers
		WHERE person_id = p.id;
		IF i IS NULL THEN m4_NOTFOUND ELSE
			status := 200;
			js := json_build_object('worker_id', i, 'person_id', p.id);
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.auth_manager",
-- args = {"email", "password"},
-- method = "GET",
-- url = "/auth/manager",
-- params = {"email", "password"},
-- note = "RESPONSE: {manager_id: #, person_id: #} or not found",
--}
CREATE OR REPLACE FUNCTION muckwork.auth_manager(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	p peeps.people;
	i integer;
BEGIN
	SELECT * INTO p FROM peeps.person_email_pass($1, $2);
	IF p IS NULL THEN m4_NOTFOUND ELSE
		SELECT id INTO i
		FROM muckwork.managers
		WHERE person_id = p.id;
		IF i IS NULL THEN m4_NOTFOUND ELSE
			status := 200;
			js := json_build_object('manager_id', i, 'person_id', p.id);
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.client_owns_project",
-- args = {"client_id", "project_id"},
-- method = "GET",
-- url = "/client/([0-9]+)/project/([0-9]+)/owned",
-- captures = {"client_id", "project_id"},
-- note = "boolean response",
--}
CREATE OR REPLACE FUNCTION muckwork.client_owns_project(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	PERFORM 1
	FROM muckwork.projects
	WHERE client_id = $1
	AND id = $2;
	IF FOUND IS TRUE THEN
		status := 200;
		js := '{"ok": true}';
	ELSE
		status := 404;
		js := '{"ok": false}';
	END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.worker_owns_task",
-- args = {"worker_id", "task_id"},
-- method = "GET",
-- url = "/worker/([0-9]+)/task/([0-9]+)/owned",
-- captures = {"worker_id", "task_id"},
-- note = "boolean response",
--}
CREATE OR REPLACE FUNCTION muckwork.worker_owns_task(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	PERFORM 1
	FROM muckwork.tasks
	WHERE worker_id = $1
	AND id = $2;
	IF FOUND IS TRUE THEN
		status := 200;
		js := '{"ok": true}';
	ELSE
		status := 404;
		js := '{"ok": false}';
	END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.project_has_progress",
-- args = {"project_id", "progress"},
-- method = "GET",
-- url = "/projects/([0-9]+)/progress/([a-z]+)/has",
-- captures = {"project_id", "progress"},
-- note = "boolean. progress must be: created, quoted, approved, refused, stated, finished",
--}
CREATE OR REPLACE FUNCTION muckwork.project_has_progress(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	PERFORM 1
	FROM muckwork.projects
	WHERE id = $1
	AND progress = $2::progress;
	IF FOUND IS TRUE THEN
		status := 200;
		js := '{"ok": true}';
	ELSE
		status := 404;
		js := '{"ok": false}';
	END IF;
EXCEPTION WHEN OTHERS THEN -- if illegal progress text passed into params
	status := 404;
	js := '{"ok": false}';
END;
$$ LANGUAGE plpgsql;


-- api = "muckwork.task_has_progress",
-- args = {"task_id", "progress"},
-- method = "GET",
-- url = "/tasks/([0-9]+)/progress/([a-z]+)/has",
-- captures = {"task_id", "progress"},
-- note = "boolean. progress must be: created, quoted, approved, refused, stated, finished",
--}
CREATE OR REPLACE FUNCTION muckwork.task_has_progress(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	PERFORM 1
	FROM muckwork.tasks
	WHERE id = $1
	AND progress = $2::progress;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
EXCEPTION WHEN OTHERS THEN -- if illegal progress text passed into params
	js := '{"ok": false}';
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.get_managers",
-- method = "GET",
-- url = "/managers",
--}
CREATE OR REPLACE FUNCTION muckwork.get_managers(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT m.*, p.name, p.email
		FROM muckwork.managers m, peeps.people p
		WHERE m.person_id = p.id
		ORDER BY id DESC
	) r;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_manager",
-- args = {"id"},
-- method = "GET",
-- url = "/managers/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.get_manager(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT m.*
		, p.name
		, p.email
		, p.address
		, p.company
		, p.city
		, p.state
		, p.country
		, p.phone
		FROM muckwork.managers m
		, peeps.people p
		WHERE m.person_id = p.id
		AND m.id = $1
	) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_clients",
-- method = "GET",
-- url = "/clients",
--}
CREATE OR REPLACE FUNCTION muckwork.get_clients(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT c.*, p.name, p.email
		FROM muckwork.clients c
		, peeps.people p
		WHERE c.person_id = p.id
		ORDER BY id DESC
	) r;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_client",
-- args = {"id"},
-- method = "GET",
-- url = "/clients/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.get_client(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT c.*
		, p.name
		, p.email
		, p.address
		, p.company
		, p.city
		, p.state
		, p.country
		, p.phone
		, muckwork.client_balance($1) AS balance
		FROM muckwork.clients c
		, peeps.people p
		WHERE c.person_id = p.id
		AND c.id = $1
	) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.create_client",
-- args = {"person_id"},
-- method = "POST",
-- url = "/clients",
-- params = {"person_id"},
-- note = "RESPONSE: {client_id: #, person_id: #}",
--}
CREATE OR REPLACE FUNCTION muckwork.create_client(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	i integer;
m4_ERRVARS
BEGIN
	SELECT id INTO i
	FROM muckwork.clients
	WHERE person_id = $1;
	IF NOT FOUND THEN
		INSERT INTO muckwork.clients(person_id)
		VALUES ($1)
		RETURNING id INTO i;
	END IF;
	status := 200;
	js := json_build_object('client_id', i, 'person_id', $1);
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.update_client",
-- args = {"id", "json"},
-- method = "PUT",
-- url = "/clients/([0-9]+)",
-- captures = {"id"},
-- params = {"json"},
-- note = "JSON of key = >values to update",
--}
CREATE OR REPLACE FUNCTION muckwork.update_client(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT person_id INTO pid
	FROM muckwork.clients
	WHERE id = $1;
	PERFORM core.jsonupdate('peeps.people', pid, $2,
		ARRAY['name'
		, 'email'
		, 'address'
		, 'company'
		, 'city'
		, 'state'
		, 'country'
		, 'phone']);
	PERFORM core.jsonupdate('muckwork.clients', $1, $2,
		ARRAY['person_id', 'currency']);
	SELECT x.status, x.js INTO status, js FROM muckwork.get_client($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_workers",
-- method = "GET",
-- url = "/workers",
--}
CREATE OR REPLACE FUNCTION muckwork.get_workers(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT w.*
		, p.name
		, p.email
		FROM muckwork.workers w
		, peeps.people p
		WHERE w.person_id = p.id
		ORDER BY id DESC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_worker",
-- args = {"id"},
-- method = "GET",
-- url = "/workers/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.get_worker(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT w.*
		, p.name
		, p.email
		, p.address
		, p.company
		, p.city
		, p.state
		, p.country
		, p.phone
		FROM muckwork.workers w
		, peeps.people p
		WHERE w.person_id = p.id
		AND w.id = $1
	) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.create_worker",
-- args = {"person_id"},
-- method = "POST",
-- url = "/workers",
-- params = {"person_id"},
--}
CREATE OR REPLACE FUNCTION muckwork.create_worker(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.workers(person_id)
	VALUES ($1)
	RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_worker(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;




--Route{
-- api = "muckwork.update_worker",
-- args = {"id"},
-- method = "PUT",
-- url = "/workers/([0-9]+)",
-- captures = {"id"},
-- params = {"json"},
-- note = "JSON of key = >values to update",
--}
CREATE OR REPLACE FUNCTION muckwork.update_worker(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT person_id INTO pid
		FROM muckwork.workers
		WHERE id = $1;
	PERFORM core.jsonupdate('peeps.people', pid, $2,
		ARRAY['name'
		, 'email'
		, 'address'
		, 'company'
		, 'city'
		, 'state'
		, 'country'
		, 'phone']);
	PERFORM core.jsonupdate('muckwork.workers', $1, $2,
		ARRAY['person_id', 'hourly_rate']);
	SELECT x.status, x.js INTO status, js FROM muckwork.get_worker($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_projects",
-- method = "GET",
-- url = "/projects",
--}
CREATE OR REPLACE FUNCTION muckwork.get_projects(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM muckwork.project_view
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.client_get_projects",
-- args = {"client_id"},
-- method = "GET",
-- url = "/clients/([0-9]+)/projects",
-- captures = {"client_id"},
--}
CREATE OR REPLACE FUNCTION muckwork.client_get_projects(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM muckwork.project_view
		WHERE id IN (
			SELECT id
			FROM muckwork.projects
			WHERE client_id = $1
		)
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_projects_with_progress",
-- args = {"progress"},
-- method = "GET",
-- url = "/projects/progress/([a-z]+)",
-- captures = {"progress"},
-- note = "progress = created, quoted, approved, refused, started or finished", 
--}
CREATE OR REPLACE FUNCTION muckwork.get_projects_with_progress(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM muckwork.project_view
		WHERE progress = $1::progress
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
EXCEPTION WHEN OTHERS THEN -- if illegal progress text passed into params
	js := '[]';
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.get_tasks_with_progress",
-- args = {"progress"},
-- method = "GET",
-- url = "/tasks/progress/([a-z]+)",
-- captures = {"progress"},
-- note = "progress = created, quoted, approved, refused, started or finished", 
--}
CREATE OR REPLACE FUNCTION muckwork.get_tasks_with_progress(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM muckwork.task_view
		WHERE progress = $1::progress
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
EXCEPTION WHEN OTHERS THEN -- if illegal progress text passed into params
	js := '[]';
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.get_project",
-- args = {"id"},
-- method = "GET",
-- url = "/projects/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.get_project(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
		FROM muckwork.project_detail_view r
		WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;




--Route{
-- api = "muckwork.create_project",
-- args = {"client_id", "title", "description"},
-- method = "POST",
-- url = "/clients/([0-9]+)/projects",
-- captures = {"client_id"},
-- params = {"title", "description"},
--}
CREATE OR REPLACE FUNCTION muckwork.create_project(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
	new_id integer;
BEGIN
	INSERT INTO muckwork.projects
	(client_id, title, description)
	VALUES
	($1, $2, $3)
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*) FROM muckwork.project_view r WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.update_project",
-- args = {"id", "title", "description"},
-- method = "PUT",
-- url = "/projects/([0-9]+)",
-- captures = {"id"},
-- params = {"title", "description"},
--}
CREATE OR REPLACE FUNCTION muckwork.update_project(integer, text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects
	SET title = $2
	, description = $3
	WHERE id = $1;
	status := 200;
	js := row_to_json(r.*) FROM muckwork.project_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.quote_project",
-- args = {"id", "ratetype", "currency", "amount"},
-- method = "PUT",
-- url = "/projects/([0-9]+)/quote",
-- captures = {"id"},
-- params = {"ratetype", "currency", "amount"},
-- note = "ratetype = fix|time, currency = USD, amount = float",
--}
CREATE OR REPLACE FUNCTION muckwork.quote_project(integer, text, core.currency, numeric,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects
	SET quoted_at = NOW()
	, quoted_ratetype = $2
	, quoted_money = ($3, $4)
	WHERE id = $1;
	UPDATE muckwork.tasks
	SET progress = 'quoted'
	WHERE project_id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_project($1) x;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.approve_quote",
-- args = {"id"},
-- method = "POST",
-- url = "/projects/([0-9]+)/quote/approval",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.approve_quote(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects
	SET approved_at = NOW()
	WHERE id = $1;
	UPDATE muckwork.tasks
	SET progress = 'approved'
	WHERE project_id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_project($1) x;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.refuse_quote",
-- args = {"id", "explanation"},
-- method = "POST",
-- url = "/projects/([0-9]+)/quote/refusal",
-- captures = {"id"},
-- params = {"explanation"},
--}
CREATE OR REPLACE FUNCTION muckwork.refuse_quote(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	note_id integer;
BEGIN
	UPDATE muckwork.projects
	SET progress = 'refused'
	WHERE id = $1
	AND progress = 'quoted';
	IF FOUND IS FALSE THEN m4_NOTFOUND ELSE
		INSERT INTO muckwork.notes
		(project_id
		, client_id
		, note)
		VALUES
		($1
		, (SELECT client_id FROM muckwork.projects WHERE id = $1)
		, $2)
		RETURNING id INTO note_id;
		status := 200;
		js := row_to_json(r.*)
		FROM muckwork.notes r
		WHERE id = note_id;
	END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_task",
-- args = {"id"},
-- method = "GET",
-- url = "/task/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.get_task(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.task_view r
	WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.get_project_task",
-- args = {"project_id", "task_id"},
-- method = "GET",
-- url = "/projects/([0-9]+)/tasks/([0-9]+)",
-- captures = {"project_id", "task_id"},
-- note = "Same as get_task but including project_id for ownership verification",
--}
CREATE OR REPLACE FUNCTION muckwork.get_project_task(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.task_view r
	WHERE project_id = $1
	AND id = $2;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.create_task",
-- args = {"project_id", "title", "description", "sortid"},
-- method = "POST",
-- url = "/projects/([0-9]+)/tasks",
-- captures = {"project_id"},
-- params = {"title", "description", "sortid"},
-- note = "sortid can be NULL for default",
--}
CREATE OR REPLACE FUNCTION muckwork.create_task(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.tasks
	(project_id, title, description, sortid)
	VALUES
	($1, $2, $3, $4)
	RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, title, description, sortid(or NULL)
--Route{
-- api = "muckwork.update_task",
-- args = {"id", "title", "description", "sortid"},
-- method = "PUT",
-- url = "/tasks/([0-9]+)",
-- captures = {"id"},
-- params = {"title", "description", "sortid"},
-- note = "sortid can be NULL for default",
--}
CREATE OR REPLACE FUNCTION muckwork.update_task(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks
	SET title = $2
	, description = $3
	, sortid = $4
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.claim_task",
-- args = {"task_id", "worker_id"},
-- method = "PUT",
-- url = "/tasks/([0-9]+)/workers/([0-9]+)",
-- captures = {"task_id", "worker_id"},
--}
CREATE OR REPLACE FUNCTION muckwork.claim_task(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks
	SET worker_id = $2
	, claimed_at = NOW()
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.unclaim_task",
-- args = {"id"},
-- method = "DELETE",
-- url = "/tasks/([0-9]+)/workers",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.unclaim_task(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks
	SET worker_id = NULL
	, claimed_at = NULL
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.start_task",
-- args = {"id"},
-- method = "PUT",
-- url = "/tasks/([0-9]+)/start",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.start_task(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks
	SET started_at = NOW()
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.finish_task",
-- args = {"id"},
-- method = "PUT",
-- url = "/tasks/([0-9]+)/finish",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.finish_task(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks
	SET finished_at = NOW()
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.worker_get_tasks",
-- args = {"worker_id"},
-- method = "GET",
-- url = "/workers/([0-9]+)/tasks",
-- captures = {"worker_id"},
--}
CREATE OR REPLACE FUNCTION muckwork.worker_get_tasks(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM muckwork.task_view
		WHERE id IN
		(
		SELECT id
		FROM muckwork.tasks
		WHERE worker_id = $1)
		ORDER BY id DESC) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.next_available_tasks",
-- method = "GET",
-- url = "/tasks/available",
-- note = "lists just the next unclaimed task (lowest sortid) for each project. use this to avoid workers claiming tasks out of order",
--}
CREATE OR REPLACE FUNCTION muckwork.next_available_tasks(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM muckwork.task_view
		WHERE (project_id, sortid) IN (
		SELECT project_id, MIN(sortid)
			FROM muckwork.tasks
		WHERE progress = 'approved'
			AND worker_id IS NULL
		AND claimed_at IS NULL
			GROUP BY project_id) 
		ORDER BY project_id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.manager_project_note",
-- args = {"manager_id", "project_id", "note"},
-- method = "POST",
-- url = "/managers/([0-9]+)/projects/([0-9]+)/notes",
-- captures = {"manager_id", "project_id"},
-- params = {"note"},
--}
CREATE OR REPLACE FUNCTION muckwork.manager_project_note(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.notes
	(manager_id, project_id, note)
	VALUES
	($1, $2, $3)
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*)
		FROM muckwork.notes r
		WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.manager_task_note",
-- args = {"manager_id", "task_id", "note"},
-- method = "POST",
-- url = "/managers/([0-9]+)/tasks/([0-9]+)/notes",
-- captures = {"manager_id", "task_id"},
-- params = {"note"},
--}
CREATE OR REPLACE FUNCTION muckwork.manager_task_note(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.notes
	(manager_id, task_id, note, project_id)
	VALUES
	($1, $2, $3, (
		SELECT project_id
		FROM muckwork.tasks
		WHERE id = $2
	))
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.notes r
	WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.client_project_note",
-- args = {"client_id", "project_id", "note"},
-- method = "POST",
-- url = "/clients/([0-9]+)/projects/([0-9]+)/notes",
-- captures = {"client_id", "project_id"},
-- params = {"note"},
--}
CREATE OR REPLACE FUNCTION muckwork.client_project_note(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.notes
	(client_id, project_id, note)
	VALUES
	($1, $2, $3)
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*)
		FROM muckwork.notes r
		WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.client_task_note",
-- args = {"client_id", "task_id", "note"},
-- method = "POST",
-- url = "/clients/([0-9]+)/tasks/([0-9]+)/notes",
-- captures = {"client_id", "task_id"},
-- params = {"note"},
--}
CREATE OR REPLACE FUNCTION muckwork.client_task_note(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.notes
	(client_id, task_id, note, project_id)
	VALUES
	($1, $2, $3, (
		SELECT project_id
		FROM muckwork.tasks
		WHERE id = $2
	))
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.notes r
	WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.worker_project_note",
-- args = {"worker_id", "project_id", "note"},
-- method = "POST",
-- url = "/workers/([0-9]+)/projects/([0-9]+)/notes",
-- captures = {"worker_id", "project_id"},
-- params = {"note"},
--}
CREATE OR REPLACE FUNCTION muckwork.worker_project_note(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.notes
	(worker_id, project_id, note)
	VALUES
	($1, $2, $3)
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.notes r
	WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.worker_task_note",
-- args = {"worker_id", "task_id", "note"},
-- method = "POST",
-- url = "/workers/([0-9]+)/tasks/([0-9]+)/notes",
-- captures = {"worker_id", "task_id"},
-- params = {"note"},
--}
CREATE OR REPLACE FUNCTION muckwork.worker_task_note(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.notes
	(worker_id, task_id, note, project_id)
	VALUES
	($1, $2, $3, (
		SELECT project_id
		FROM muckwork.tasks
		WHERE id = $2
	))
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*)
		FROM muckwork.notes r
		WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.update_note",
-- args = {"id", "note"},
-- method = "PUT",
-- url = "/notes/([0-9]+)",
-- captures = {"id"},
-- params = {"note"},
--}
CREATE OR REPLACE FUNCTION muckwork.update_note(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.notes
	SET note = $2
	WHERE id = $1;
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.notes r
	WHERE id = $1;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



--Route{
-- api = "muckwork.delete_note",
-- args = {"id"},
-- method = "DELETE",
-- url = "/notes/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION muckwork.delete_note(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.notes r
	WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND ELSE
		DELETE FROM muckwork.notes WHERE id = $1;
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.client_charges",
-- args = {"client_id"},
-- method = "GET",
-- url = "/clients/([0-9]+)/charges",
-- captures = {"client_id"},
--}
CREATE OR REPLACE FUNCTION muckwork.client_charges(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT c.id
		, c.created_at
		, c.money
		, c.notes
		, json_build_object('id', p.id, 'title', p.title) AS project
		FROM muckwork.client_charges c
		JOIN muckwork.projects p
		ON c.project_id = p.id
		WHERE p.client_id = $1
		ORDER BY c.id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.client_payments",
-- args = {"client_id"},
-- method = "GET",
-- url = "/clients/([0-9]+)/payments",
-- captures = {"client_id"},
--}
CREATE OR REPLACE FUNCTION muckwork.client_payments(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id
		, created_at
		, money
		, notes
		FROM muckwork.client_payments
		WHERE client_id = $1
		ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "muckwork.add_client_payment",
-- args = {"client_id", "currency", "amount", "notes"},
-- method = "POST",
-- url = "/clients/([0-9]+)/payments",
-- captures = {"client_id"},
-- params = {"currency", "amount", "notes"},
--}
CREATE OR REPLACE FUNCTION muckwork.add_client_payment(integer, core.currency, numeric, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
	new_id integer;
BEGIN
	INSERT INTO muckwork.client_payments
	(client_id, money, notes)
	VALUES
	($1, ($2, $3), $4)
	RETURNING id INTO new_id;
	status := 200;
	js := json_build_object('id', new_id);
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- check finality of project
-- email customer
