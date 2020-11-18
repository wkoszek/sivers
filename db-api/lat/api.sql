----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

--Route{
-- api = "lat.get_concepts",
-- method = "GET",
-- url = "/concepts",
--}
CREATE OR REPLACE FUNCTION lat.get_concepts(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM lat.concepts
		ORDER BY id
	) r;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.get_concept",
-- args = {"id"},
-- method = "GET",
-- url = "/concepts/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.get_concept(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
		FROM lat.concept_view r
		WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.get_concepts",
-- args = {"ids"},
-- method = "GET",
-- url = "/concepts/multi",
-- params = {"ids"},
-- note = "array of concept IDs"
--}
CREATE OR REPLACE FUNCTION lat.get_concepts(integer[],
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM lat.concept_view
		WHERE id = ANY($1)
		ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF; -- If none found, js is empty array
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.create_concept",
-- args = {"title", "concept"},
-- method = "POST",
-- url = "/concepts",
-- params = {"title", "concept"},
--}
CREATE OR REPLACE FUNCTION lat.create_concept(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO lat.concepts(title, concept)
	VALUES ($1, $2)
	RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM lat.get_concept(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.update_concept",
-- args = {"id", "title", "concept"},
-- method = "PUT",
-- url = "/concepts/([0-9]+)",
-- captures = {"id"},
-- params = {"title", "concept"},
--}
CREATE OR REPLACE FUNCTION lat.update_concept(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE lat.concepts
	SET title = $2
	,concept = $3
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM lat.get_concept($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.delete_concept",
-- args = {"id"},
-- method = "DELETE",
-- url = "/concepts/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.delete_concept(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js FROM lat.get_concept($1) x;
	DELETE FROM lat.concepts WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.tag_concept",
-- args = {"id", "tag"},
-- method = "POST",
-- url = "/concepts/([0-9]+)/tags",
-- captures = {"id"},
-- params = {"tag"},
--}
CREATE OR REPLACE FUNCTION lat.tag_concept(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	cid integer;
	tid integer;
m4_ERRVARS
BEGIN
	SELECT id INTO cid
	FROM lat.concepts
	WHERE id = $1;
	IF NOT FOUND THEN m4_NOTFOUND RETURN; END IF;
	SELECT id INTO tid
	FROM lat.tags
	WHERE tag = lower(btrim(regexp_replace($2, '\s+', ' ', 'g')));
	IF tid IS NULL THEN
		INSERT INTO lat.tags (tag)
		VALUES ($2)
		RETURNING id INTO tid;
	END IF;
	SELECT concept_id INTO cid
		FROM lat.concepts_tags
		WHERE concept_id = $1
		AND tag_id = tid;
	IF NOT FOUND THEN
		INSERT INTO lat.concepts_tags(concept_id, tag_id) VALUES ($1, tid);
	END IF;
	SELECT x.status, x.js INTO status, js FROM lat.get_concept($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.untag_concept",
-- args = {"concept_id", "tag_id"},
-- method = "DELETE",
-- url = "/concepts/([0-9]+)/tags/([0-9]+)",
-- captures = {"concept_id", "tag_id"},
--}
CREATE OR REPLACE FUNCTION lat.untag_concept(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM lat.concepts_tags
		WHERE concept_id = $1
		AND tag_id = $2;
	SELECT x.status, x.js INTO status, js FROM lat.get_concept($1) x;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.get_url",
-- args = {"id"},
-- method = "GET",
-- url = "/urls/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.get_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
		FROM lat.urls r
		WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.add_url",
-- args = {"concept_id", "url", "notes"},
-- method = "POST",
-- url = "/concepts/([0-9]+)/urls",
-- captures = {"concept_id"},
-- params = {"url", "notes"},
--}
CREATE OR REPLACE FUNCTION lat.add_url(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	uid integer;
m4_ERRVARS
BEGIN
	INSERT INTO lat.urls (url, notes)
	VALUES ($2, $3)
	RETURNING id INTO uid;
	INSERT INTO lat.concepts_urls (concept_id, url_id)
	VALUES ($1, uid);
	SELECT x.status, x.js INTO status, js FROM lat.get_url(uid) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.update_url",
-- args = {"id", "url", "notes"},
-- method = "PUT",
-- url = "/urls/([0-9]+)",
-- captures = {"id"},
-- params = {"url", "notes"},
--}
CREATE OR REPLACE FUNCTION lat.update_url(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE lat.urls
	SET url = $2
	, notes = $3
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM lat.get_url($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.delete_url",
-- args = {"id"},
-- method = "DELETE",
-- url = "/urls/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.delete_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js FROM lat.get_url($1) x;
	DELETE FROM lat.urls WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.tags",
-- method = "GET",
-- url = "/tags",
--}
CREATE OR REPLACE FUNCTION lat.tags(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM lat.tags
		ORDER BY RANDOM()
	) r;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.concepts_tagged",
-- args = {"tag"},
-- method = "GET",
-- url = "/concepts/tagged",
-- params = {"tag"},
-- note = "returns array of concepts or empty array if none found"
--}
CREATE OR REPLACE FUNCTION lat.concepts_tagged(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
	FROM lat.get_concepts(ARRAY(
		SELECT concept_id
		FROM lat.concepts_tags, lat.tags
		WHERE lat.tags.tag = $1
		AND lat.tags.id = lat.concepts_tags.tag_id
	)) x;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.untagged_concepts",
-- method = "GET",
-- url = "/concepts/untagged",
-- note = "returns array of concepts or empty array if none found"
--}
CREATE OR REPLACE FUNCTION lat.untagged_concepts(
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
	FROM lat.get_concepts(ARRAY(
		SELECT lat.concepts.id
		FROM lat.concepts
			LEFT JOIN lat.concepts_tags
			ON lat.concepts.id = lat.concepts_tags.concept_id
		WHERE lat.concepts_tags.tag_id IS NULL
	)) x;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.get_pairings",
-- method = "GET",
-- url = "/pairings",
--}
CREATE OR REPLACE FUNCTION lat.get_pairings(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT p.id
		, p.created_at
		, c1.title AS concept1
		, c2.title AS concept2
		FROM lat.pairings p
		INNER JOIN lat.concepts c1 ON p.concept1_id = c1.id
		INNER JOIN lat.concepts c2 ON p.concept2_id = c2.id
		ORDER BY p.id
	) r;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.get_pairing",
-- args = {"id"},
-- method = "GET",
-- url = "/pairings/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.get_pairing(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
		FROM lat.pairing_view r
		WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.create_pairing",
-- method = "POST",
-- url = "/pairings",
-- note = "randomly generated"
--}
CREATE OR REPLACE FUNCTION lat.create_pairing(
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT id INTO pid FROM lat.new_pairing();
	SELECT x.status, x.js INTO status, js FROM lat.get_pairing(pid) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.update_pairing",
-- args = {"id", "thoughts"},
-- method = "PUT",
-- url = "/pairings/([0-9]+)",
-- captures = {"id"},
-- params = {"thoughts"},
--}
CREATE OR REPLACE FUNCTION lat.update_pairing(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE lat.pairings SET thoughts = $2 WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM lat.get_pairing($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


--Route{
-- api = "lat.delete_pairing",
-- args = {"id"},
-- method = "DELETE",
-- url = "/pairings/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.delete_pairing(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js FROM lat.get_pairing($1) x;
	DELETE FROM lat.pairings WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: pairing.id, tag text
-- Adds that tag to both concepts in the pair
--Route{
-- api = "lat.tag_pairing",
-- args = {"id", "tag"},
-- method = "POST",
-- url = "/pairings/([0-9]+)/tags",
-- captures = {"id"},
-- params = {"tag"},
--}
CREATE OR REPLACE FUNCTION lat.tag_pairing(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	id1 integer;
	id2 integer;
m4_ERRVARS
BEGIN
	SELECT concept1_id, concept2_id INTO id1, id2
	FROM lat.pairings
	WHERE id = $1;
	PERFORM lat.tag_concept(id1, $2);
	PERFORM lat.tag_concept(id2, $2);
	SELECT x.status, x.js INTO status, js FROM lat.get_pairing($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;

