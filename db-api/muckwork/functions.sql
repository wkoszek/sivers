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
