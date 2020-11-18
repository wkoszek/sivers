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

