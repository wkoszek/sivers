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

