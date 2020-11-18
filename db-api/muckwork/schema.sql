SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS muckwork CASCADE;
BEGIN;

CREATE SCHEMA muckwork;
SET search_path = muckwork;

CREATE TABLE muckwork.managers (
	id serial primary key,
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
----------------------------
------------------ TRIGGERS:
----------------------------

CREATE OR REPLACE FUNCTION muckwork.project_progress() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.quoted_at IS NULL THEN
		NEW.progress := 'created';
	ELSIF NEW.approved_at IS NULL THEN
		NEW.progress := 'quoted';
	ELSIF NEW.started_at IS NULL THEN
		NEW.progress := 'approved';
	ELSIF NEW.finished_at IS NULL THEN
		NEW.progress := 'started';
	ELSE
		NEW.progress := 'finished';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS project_progress ON muckwork.projects CASCADE;
CREATE TRIGGER project_progress BEFORE UPDATE OF
	quoted_at, approved_at, started_at, finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.project_progress();


-- Dates must always exist in this order:
-- created_at, quoted_at, approved_at, started_at, finished_at
CREATE OR REPLACE FUNCTION muckwork.project_dates_in_order() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.approved_at IS NOT NULL AND NEW.quoted_at IS NULL)
		OR (NEW.started_at IS NOT NULL AND NEW.approved_at IS NULL)
		OR (NEW.finished_at IS NOT NULL AND NEW.started_at IS NULL)
		THEN RAISE 'dates_out_of_order';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS project_dates_in_order ON muckwork.projects CASCADE;
CREATE TRIGGER project_dates_in_order BEFORE UPDATE OF
	quoted_at, approved_at, started_at, finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.project_dates_in_order();


-- can't update existing timestamps
-- not sure what's better: one trigger for all dates, or one trigger per field.
CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_pc() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.created_at IS NOT NULL AND OLD.created_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pc ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pc BEFORE UPDATE OF created_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pc();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_pq() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.quoted_at IS NOT NULL AND OLD.quoted_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pq ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pq BEFORE UPDATE OF quoted_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pq();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_pa() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.approved_at IS NOT NULL AND OLD.approved_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pa ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pa BEFORE UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pa();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_ps() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.started_at IS NOT NULL AND OLD.started_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_ps ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_ps BEFORE UPDATE OF started_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_ps();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_pf() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND OLD.finished_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pf ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pf BEFORE UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pf();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_tc() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.created_at IS NOT NULL AND OLD.created_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_tc ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_tc BEFORE UPDATE OF created_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tc();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_tl() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.claimed_at IS NOT NULL AND OLD.claimed_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_tl ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_tl BEFORE UPDATE OF claimed_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tl();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_ts() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.started_at IS NOT NULL AND OLD.started_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_ts ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_ts BEFORE UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_ts();

CREATE OR REPLACE FUNCTION muckwork.dates_cant_change_tf() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND OLD.finished_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_tf ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_tf BEFORE UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tf();



CREATE OR REPLACE FUNCTION muckwork.task_progress() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.started_at IS NULL THEN
		NEW.progress := 'created';
	ELSIF NEW.finished_at IS NULL THEN
		NEW.progress := 'started';
	ELSE
		NEW.progress := 'finished';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_progress ON muckwork.tasks CASCADE;
CREATE TRIGGER task_progress BEFORE UPDATE OF
	started_at, finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.task_progress();


-- Dates must always exist in this order:
-- created_at, started_at, finished_at
CREATE OR REPLACE FUNCTION muckwork.task_dates_in_order() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND NEW.started_at IS NULL)
		OR (NEW.started_at IS NOT NULL AND NEW.claimed_at IS NULL)
		THEN RAISE 'dates_out_of_order';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_dates_in_order ON muckwork.tasks CASCADE;
CREATE TRIGGER task_dates_in_order BEFORE UPDATE OF
	claimed_at, started_at, finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.task_dates_in_order();


-- tasks.claimed_at and tasks.worker_id must match (both|neither)
-- also means can't update a worker_id to another. have to go NULL inbetween.
CREATE OR REPLACE FUNCTION muckwork.tasks_claimed_pair() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.claimed_at IS NOT NULL AND NEW.worker_id IS NULL)
	OR (NEW.worker_id IS NOT NULL AND NEW.claimed_at IS NULL)
	OR (NEW.worker_id IS NOT NULL AND OLD.worker_id IS NOT NULL)
		THEN RAISE 'tasks_claimed_pair';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS tasks_claimed_pair ON muckwork.tasks CASCADE;
CREATE TRIGGER tasks_claimed_pair BEFORE UPDATE OF
	worker_id, claimed_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.tasks_claimed_pair();


-- can't claim a task unless it's approved
CREATE OR REPLACE FUNCTION muckwork.only_claim_approved_task() RETURNS TRIGGER AS $$
BEGIN
	IF (OLD.progress != 'approved') THEN
		RAISE 'only_claim_approved_task';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS only_claim_approved_task ON muckwork.tasks CASCADE;
CREATE TRIGGER only_claim_approved_task
	BEFORE UPDATE OF worker_id ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.worker_id IS NOT NULL)
	EXECUTE PROCEDURE muckwork.only_claim_approved_task();


-- Controversial business rule: can't claim a task unless available
CREATE OR REPLACE FUNCTION muckwork.only_claim_when_done() RETURNS TRIGGER AS $$
BEGIN
	IF muckwork.is_worker_available(NEW.worker_id) IS FALSE THEN
		RAISE 'only_claim_when_done';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS only_claim_when_done ON muckwork.tasks CASCADE;
CREATE TRIGGER only_claim_when_done
	BEFORE UPDATE OF worker_id ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.worker_id IS NOT NULL)
	EXECUTE PROCEDURE muckwork.only_claim_when_done();


-- can't delete started projects or tasks
CREATE OR REPLACE FUNCTION muckwork.no_delete_started() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.started_at IS NOT NULL 
		THEN RAISE 'no_delete_started';
	END IF;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS no_delete_started_project ON muckwork.projects CASCADE;
CREATE TRIGGER no_delete_started_project BEFORE DELETE ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_delete_started();
DROP TRIGGER IF EXISTS no_delete_started_task ON muckwork.tasks CASCADE;
CREATE TRIGGER no_delete_started_task BEFORE DELETE ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_delete_started();


-- can't update title, description of quoted project
CREATE OR REPLACE FUNCTION muckwork.no_update_quoted_project() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.quoted_at IS NOT NULL 
		THEN RAISE 'no_update_quoted';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS no_update_quoted_project ON muckwork.projects CASCADE;
CREATE TRIGGER no_update_quoted_project BEFORE UPDATE OF
	title, description ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_update_quoted_project();


-- can't update title, description of started task
CREATE OR REPLACE FUNCTION muckwork.no_update_started_task() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.started_at IS NOT NULL 
		THEN RAISE 'no_update_started';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS no_update_started_task ON muckwork.tasks CASCADE;
CREATE TRIGGER no_update_started_task BEFORE UPDATE OF
	title, description ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_update_started_task();


-- first task started marks project as started (see reverse below)
CREATE OR REPLACE FUNCTION muckwork.task_starts_project() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects SET started_at=NOW()
		WHERE id=OLD.project_id AND started_at IS NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_starts_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_starts_project AFTER UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.started_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_starts_project();

-- only started task un-started marks project as un-started
CREATE OR REPLACE FUNCTION muckwork.task_unstarts_project() RETURNS TRIGGER AS $$
DECLARE
	pi integer;
BEGIN
	SELECT project_id INTO pi FROM muckwork.tasks
		WHERE project_id=OLD.project_id
		AND started_at IS NOT NULL LIMIT 1;
	IF pi IS NULL THEN
		UPDATE muckwork.projects SET started_at=NULL WHERE id=OLD.project_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_unstarts_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_unstarts_project AFTER UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.started_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_unstarts_project();


-- last task finished marks project as finished (see reverse below)
CREATE OR REPLACE FUNCTION muckwork.task_finishes_project() RETURNS TRIGGER AS $$
DECLARE
	pi integer;
BEGIN
	-- any unfinished tasks left for this project?
	SELECT project_id INTO pi FROM muckwork.tasks
		WHERE project_id=OLD.project_id
		AND finished_at IS NULL LIMIT 1;
	-- ... if not, then mark project as finished_at time of last finished_at task
	IF pi IS NULL THEN
		UPDATE muckwork.projects SET finished_at =
			(SELECT MAX(finished_at) FROM tasks WHERE project_id=OLD.project_id)
			WHERE id=OLD.project_id AND finished_at IS NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_finishes_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_finishes_project AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_finishes_project();

-- last finished task un-finished marks project as un-finished again
CREATE OR REPLACE FUNCTION muckwork.task_unfinishes_project() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects SET finished_at=NULL
		WHERE id=OLD.project_id AND finished_at IS NOT NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_unfinishes_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_unfinishes_project AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_unfinishes_project();


-- task finished creates worker_charge  (see reverse below)
CREATE OR REPLACE FUNCTION muckwork.task_creates_charge() RETURNS TRIGGER AS $$
BEGIN
	WITH x AS (
		SELECT NEW.id AS task_id, muckwork.worker_charge_for_task(NEW.id) AS money)
	INSERT INTO muckwork.worker_charges (task_id, money) SELECT * FROM x;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_creates_charge ON muckwork.tasks CASCADE;
CREATE TRIGGER task_creates_charge AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_creates_charge();

-- task UN-finished deletes associated charge
CREATE OR REPLACE FUNCTION muckwork.task_uncreates_charge() RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM muckwork.worker_charges WHERE task_id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_uncreates_charge ON muckwork.tasks CASCADE;
CREATE TRIGGER task_uncreates_charge AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_uncreates_charge();

-- approving project makes tasks approved
CREATE OR REPLACE FUNCTION muckwork.approve_project_tasks() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.tasks SET progress='approved'
		WHERE project_id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS approve_project_tasks ON muckwork.projects CASCADE;
CREATE TRIGGER approve_project_tasks AFTER UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.approved_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.approve_project_tasks();

-- UN-approving project makes tasks UN-approved 
CREATE OR REPLACE FUNCTION muckwork.unapprove_project_tasks() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.tasks SET progress='quoted'
		WHERE project_id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS unapprove_project_tasks ON muckwork.projects CASCADE;
CREATE TRIGGER unapprove_project_tasks AFTER UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.approved_at IS NULL)
	EXECUTE PROCEDURE muckwork.unapprove_project_tasks();


-- project finished creates charge
-- SOME DAY: fixed vs hourly (& hey maybe I should profit?)
CREATE OR REPLACE FUNCTION muckwork.project_creates_charge() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects
		SET final_money = muckwork.final_project_charges(NEW.id)
		WHERE id = NEW.id;
	INSERT INTO muckwork.client_charges (project_id, money)
		VALUES (NEW.id, muckwork.final_project_charges(NEW.id));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS project_creates_charge ON muckwork.projects CASCADE;
CREATE TRIGGER project_creates_charge AFTER UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.project_creates_charge();


-- project UN-finished UN-creates charge
CREATE OR REPLACE FUNCTION muckwork.project_uncreates_charge() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects SET final_money = NULL WHERE id = NEW.id;
	DELETE FROM muckwork.client_charges WHERE project_id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS project_uncreates_charge ON muckwork.projects CASCADE;
CREATE TRIGGER project_uncreates_charge AFTER UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.project_uncreates_charge();


-- get the sortid for the tasks
CREATE OR REPLACE FUNCTION muckwork.auto_sortid() RETURNS TRIGGER AS $$
DECLARE
	i integer;
BEGIN
	SELECT COALESCE(MAX(sortid), 0) INTO i
		FROM muckwork.tasks WHERE project_id=NEW.project_id;
	NEW.sortid = (i + 1);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS auto_sortid ON muckwork.tasks CASCADE;
CREATE TRIGGER auto_sortid BEFORE INSERT ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.sortid IS NULL)
	EXECUTE PROCEDURE muckwork.auto_sortid();


-- template
-- CREATE OR REPLACE FUNCTION muckwork.xx() RETURNS TRIGGER AS $$
-- BEGIN
-- 	RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
-- DROP TRIGGER IF EXISTS xx ON muckwork.projects CASCADE;
-- CREATE TRIGGER xx AFTER UPDATE OF yy ON muckwork.projects
-- 	FOR EACH ROW WHEN (NEW.yy IS NULL)
-- 	EXECUTE PROCEDURE muckwork.xx();

--------------------------------------
--------------------------- FUNCTIONS:
--------------------------------------

-- PARAMS: tasks.id
-- USAGE: SELECT SUM(seconds_per_task(id)) FROM muckwork.tasks WHERE project_id=1;
CREATE OR REPLACE FUNCTION muckwork.seconds_per_task(integer, OUT seconds integer) AS $$
BEGIN
	seconds := (EXTRACT(EPOCH FROM finished_at) - EXTRACT(EPOCH FROM started_at))
		FROM muckwork.tasks
		WHERE id = $1
		AND finished_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: tasks.id
CREATE OR REPLACE FUNCTION muckwork.worker_charge_for_task(integer)
	RETURNS core.currency_amount AS $$
BEGIN
	RETURN (SELECT core.multiply_money(w.hourly_rate, muckwork.seconds_per_task(t.id) / 360.0)
		FROM muckwork.tasks t
		INNER JOIN muckwork.workers w ON t.worker_id=w.id
		WHERE t.id = $1
		AND t.finished_at IS NOT NULL);
END;
$$ LANGUAGE plpgsql;


-- Sum of all worker_charges for tasks in this project, *converted* to project currency
-- PARAMS: projects.id
CREATE OR REPLACE FUNCTION muckwork.final_project_charges(integer)
	RETURNS core.currency_amount AS $$
DECLARE
	wc muckwork.worker_charges;
	tot core.currency_amount;
BEGIN
	-- tot starts as 0 amount in client's currency
	tot := ((SELECT currency
			FROM muckwork.clients c
			JOIN muckwork.projects p ON c.id=p.client_id
			WHERE p.id = $1), 0);
	-- go through charges for this project:
	FOR wc IN (SELECT * FROM muckwork.worker_charges w
		JOIN muckwork.tasks t ON w.task_id=t.id
		WHERE t.project_id = $1) LOOP
		tot := core.add_money(tot, wc.money);
	END LOOP;
	RETURN core.round_money(tot);
END;
$$ LANGUAGE plpgsql;


-- Sum of all client_payments minus client_charges
-- PARAMS: client_id
CREATE OR REPLACE FUNCTION muckwork.client_balance(integer)
	RETURNS core.currency_amount AS $$
DECLARE
	tot core.currency_amount;
	cp muckwork.client_payments;
	cc muckwork.client_charges;
BEGIN
	-- tot starts as 0 amount in client's currency
	tot := ((SELECT currency FROM muckwork.clients WHERE id = $1), 0);
	-- add each payment
	FOR cp IN (SELECT * FROM muckwork.client_payments WHERE client_id=$1) LOOP
		tot := core.add_money(tot, cp.money);
	END LOOP;
	-- subtract each charge
	FOR cc IN (SELECT c.* FROM muckwork.client_charges c
		JOIN muckwork.projects p ON c.project_id=p.id
		WHERE p.client_id=$1) LOOP
		tot := core.subtract_money(tot, cc.money);
	END LOOP;
	RETURN core.round_money(tot);
END;
$$ LANGUAGE plpgsql;


-- Is this worker available to claim another task?
-- Current rule: not if they have another task claimed and unfinished
-- Rule might change, so that's why making it a separate function.
-- INPUT: worker_id
CREATE OR REPLACE FUNCTION muckwork.is_worker_available(integer) RETURNS boolean AS $$
BEGIN
	RETURN NOT EXISTS (SELECT 1 FROM muckwork.tasks
		WHERE worker_id=$1 AND finished_at IS NULL);
END;
$$ LANGUAGE plpgsql;


-- next tasks.sortid for project
-- tasks.sortid resort
----------------------------------------
--------------- VIEWS FOR JSON RESPONSES:
----------------------------------------

DROP VIEW IF EXISTS muckwork.note_view CASCADE;
CREATE VIEW muckwork.note_view AS SELECT id, note, created_at, project_id, task_id,
	(SELECT row_to_json(mx) FROM (SELECT managers.id, people.name
			FROM muckwork.managers
			JOIN peeps.people ON managers.person_id=people.id
			WHERE managers.id = notes.manager_id) mx) manager,
	(SELECT row_to_json(cx) FROM (SELECT clients.id, people.name
			FROM muckwork.clients
			JOIN peeps.people ON clients.person_id=people.id
			WHERE clients.id = notes.client_id) cx) client,
	(SELECT row_to_json(wx) FROM (SELECT workers.id, people.name
			FROM muckwork.workers
			JOIN peeps.people ON workers.person_id=people.id
			WHERE workers.id = notes.worker_id) wx) worker
	FROM muckwork.notes
	ORDER BY muckwork.notes.id;

DROP VIEW IF EXISTS muckwork.project_view CASCADE;
CREATE VIEW muckwork.project_view AS SELECT id, title, description, created_at,
	quoted_at, approved_at, started_at, finished_at, progress,
	(SELECT row_to_json(cx) AS client FROM
		(SELECT c.id, p.name, p.email
			FROM muckwork.clients c, peeps.people p
			WHERE c.person_id=p.id AND c.id=client_id) cx),
	quoted_ratetype, quoted_money, final_money
	FROM muckwork.projects
	ORDER BY muckwork.projects.id DESC;

DROP VIEW IF EXISTS muckwork.task_view CASCADE;
CREATE VIEW muckwork.task_view AS SELECT t.*,
	(SELECT row_to_json(px) AS project FROM
		(SELECT id, title, description
			FROM muckwork.projects
			WHERE muckwork.projects.id=t.project_id) px),
	(SELECT row_to_json(wx) AS worker FROM
		(SELECT w.id, p.name, p.email
			FROM muckwork.workers w, peeps.people p
			WHERE w.person_id=p.id AND w.id=t.worker_id) wx),
	(SELECT json_agg(nx) AS notes FROM
		(SELECT * FROM muckwork.note_view WHERE task_id = t.id) nx)
	FROM muckwork.tasks t
	ORDER BY t.sortid ASC;

DROP VIEW IF EXISTS muckwork.project_detail_view CASCADE;
CREATE VIEW muckwork.project_detail_view AS SELECT id, title, description, created_at,
	quoted_at, approved_at, started_at, finished_at, progress,
	(SELECT row_to_json(cx) AS client FROM
		(SELECT c.id, p.name, p.email
			FROM muckwork.clients c, peeps.people p
			WHERE c.person_id=p.id AND c.id=client_id) cx),
	quoted_ratetype, quoted_money, final_money,
	(SELECT json_agg(tx) AS tasks FROM
		(SELECT t.*,
			(SELECT row_to_json(wx) AS worker FROM
				(SELECT w.id, p.name, p.email
					FROM muckwork.workers w, peeps.people p
					WHERE w.person_id=p.id AND w.id=t.worker_id) wx)
			FROM muckwork.tasks t
			WHERE t.project_id = j.id
			ORDER BY t.sortid ASC) tx),
	(SELECT json_agg(nx) AS notes FROM
		(SELECT * FROM muckwork.note_view WHERE project_id = j.id) nx)
	FROM muckwork.projects j;

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
	IF p IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
		SELECT id INTO i
		FROM muckwork.clients
		WHERE person_id = p.id;
		IF i IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
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
	IF p IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
		SELECT id INTO i
		FROM muckwork.workers
		WHERE person_id = p.id;
		IF i IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
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
	IF p IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
		SELECT id INTO i
		FROM muckwork.managers
		WHERE person_id = p.id;
		IF i IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO muckwork.workers(person_id)
	VALUES ($1)
	RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_worker(new_id) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

	new_id integer;
BEGIN
	INSERT INTO muckwork.projects
	(client_id, title, description)
	VALUES
	($1, $2, $3)
	RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*) FROM muckwork.project_view r WHERE id = new_id;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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
	IF FOUND IS FALSE THEN 
	status := 404;
	js := '{}';
 ELSE
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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO muckwork.tasks
	(project_id, title, description, sortid)
	VALUES
	($1, $2, $3, $4)
	RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task(new_id) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks
	SET title = $2
	, description = $3
	, sortid = $4
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks
	SET worker_id = $2
	, claimed_at = NOW()
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks
	SET worker_id = NULL
	, claimed_at = NULL
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks
	SET started_at = NOW()
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks
	SET finished_at = NOW()
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

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

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.notes
	SET note = $2
	WHERE id = $1;
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.notes r
	WHERE id = $1;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	status := 200;
	js := row_to_json(r.*)
	FROM muckwork.notes r
	WHERE id = $1;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
		DELETE FROM muckwork.notes WHERE id = $1;
	END IF;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

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

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

	new_id integer;
BEGIN
	INSERT INTO muckwork.client_payments
	(client_id, money, notes)
	VALUES
	($1, ($2, $3), $4)
	RETURNING id INTO new_id;
	status := 200;
	js := json_build_object('id', new_id);

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);

END;
$$ LANGUAGE plpgsql;



-- check finality of project
-- email customer

