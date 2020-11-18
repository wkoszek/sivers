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

