SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS words CASCADE;
BEGIN;

CREATE SCHEMA words;
SET search_path = words;

CREATE TABLE words.translators (
	id smallserial primary key,
	person_id integer NOT NULL REFERENCES peeps.people(id),
	lang char(2) NOT NULL
);

-- "article" meaning ordered collection of sentences, with HTML markup
CREATE TABLE words.articles (
	id smallserial primary key,
	filename varchar(64) not null unique,
	raw text,
	template text
);

CREATE TABLE words.sentences (
	code char(8) primary key,
	article_id smallint REFERENCES words.articles(id),
	sortid smallint,
	replacements text[],
	sentence text
);

CREATE TABLE words.translations (
	id serial primary key,
	sentence_code char(8) NOT NULL REFERENCES words.sentences(code),
	lang char(2) not null,
	translation text,
	UNIQUE (sentence_code, lang)
);

COMMIT;
---------------------------------
---------------------- FUNCTIONS:
---------------------------------

-- Takes the articles.raw and turns it into individual sentences,
-- then creates and saves articles.template using the newly generated codes.
-- PARAMS: articles.id
CREATE OR REPLACE FUNCTION words.parse_article(integer) RETURNS text AS $$
DECLARE
	lines text[];
	line text;
	templine text;
	new_template text := '';
	sortnum integer := 0;
	one_code char(8);
BEGIN
	-- go through every line of words.articles.raw
	SELECT regexp_split_to_array(raw, E'\n') INTO lines
	FROM words.articles
	WHERE id = $1;
	FOREACH line IN ARRAY lines LOOP
		-- if it's indented with a tab, insert it into words.sentences
		IF E'\t' = substring(line from 1 for 1) THEN
			sortnum := sortnum + 1;
			INSERT INTO words.sentences(article_id, sortid, sentence)
				VALUES ($1, sortnum, btrim(line, E'\t'))
				RETURNING code INTO one_code;
			-- use the put the generated code into the template
			new_template := new_template || '{' || one_code || '}' || E'\n';
		-- HTML comments should also be translated
		ELSIF line ~ '<!-- (.*) -->' THEN
			sortnum := sortnum + 1;
			SELECT unnest(regexp_matches) INTO templine
				FROM regexp_matches(line, '<!-- (.*) -->');
			INSERT INTO words.sentences(article_id, sortid, sentence)
				VALUES ($1, sortnum, btrim(templine))
				RETURNING code INTO one_code;
			new_template := new_template || '<!-- {' || one_code || '} -->' || E'\n';
		ELSE
			-- non-translated line (usually HTML markup), just add to template
			new_template := new_template || line || E'\n';
		END IF;
	END LOOP;
	-- and update articles with the new template
	UPDATE words.articles SET template = rtrim(new_template, E'\n') WHERE id = $1;
	RETURN rtrim(new_template, E'\n');
END;
$$ LANGUAGE plpgsql;


-- PARAMS: $1 = "the <sentence text> like <this>", $2 = array of replacements
-- BOOLEAN : does the number of <> match the number of replacements in array?
-- NOTE: This query will show translations that don't match replacements:
-- SELECT translations.id, replacements, translation FROM words.translations
-- JOIN words.sentences ON translations.sentence_code=sentences.code
-- WHERE words.tags_match_replacements(translation, replacements) IS FALSE;
-- NOTE: If that ends up being my main usage for it, then this isn't needed as
-- a separate function, could just use the brackets-to-cardinality comparison
-- in the query itself.
-- NOTE: Though it might be a UI thing for translators: let them know it's ok or not
CREATE OR REPLACE FUNCTION words.tags_match_replacements(text, text[], OUT ok boolean) AS $$
DECLARE
	howmany_brackets integer;
BEGIN
	SELECT COUNT(*) INTO howmany_brackets FROM regexp_matches($1, E'[<>]', 'g');
	IF (howmany_brackets = cardinality($2)) THEN
		ok := true;
	ELSE
		ok := false;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: $1 = "the <sentence text> like <this>", $2 = array of replacements
-- OUT: 'the <a href="/something">sentence text</a> like <strong>this</strong>'
CREATE OR REPLACE FUNCTION words.merge_replacements(text, text[], OUT merged text) AS $$
DECLARE
	split_text text[];
BEGIN
	-- make array of text bits *around* and inbetween the < and > (not including them)
	split_text := regexp_split_to_array($1, E'[<>]');
	-- take all the j, below, merged into one string
	merged := string_agg(j, '') FROM (
		-- unnest returns 2 columns, renamed to a and b, then concat that pair into j
		SELECT CONCAT(a, b) AS j
		FROM unnest(split_text, $2) x(a, b)
	) r;
END;
$$ LANGUAGE plpgsql;


-- Get the entire translated text for this article, merged into template
-- PARAMS: articles.id, 2-char lang code
CREATE OR REPLACE FUNCTION words.merge_article(integer, char(2), OUT merged text) AS $$
DECLARE
	a RECORD;
BEGIN
	SELECT template INTO merged
	FROM words.articles
	WHERE id = $1;
	-- if English, get from sentences.sentence, not translations.translation
	IF $2 = 'en' THEN
		FOR a IN
			SELECT code,
				words.merge_replacements(sentence, replacements) AS txn
			FROM words.sentences
			WHERE article_id = $1
			LOOP
				merged := replace(merged, '{' || a.code || '}', a.txn);
			END LOOP;
	ELSE
		FOR a IN
			SELECT code,
				words.merge_replacements(translation, replacements) AS txn
			FROM words.sentences
				JOIN words.translations
				ON sentences.code = translations.sentence_code
			WHERE article_id = $1
			AND lang = $2
			LOOP
				merged := replace(merged, '{' || a.code || '}', a.txn);
			END LOOP;
	END IF;
END;
$$ LANGUAGE plpgsql;
---------------------
------------ TRIGGERS
---------------------

CREATE OR REPLACE FUNCTION words.clean_raw() RETURNS TRIGGER AS $$
BEGIN
	NEW.raw = replace(NEW.raw, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_raw ON words.articles CASCADE;
CREATE TRIGGER clean_raw
	BEFORE INSERT OR UPDATE OF raw ON words.articles
	FOR EACH ROW EXECUTE PROCEDURE words.clean_raw();


CREATE OR REPLACE FUNCTION words.sentences_code_gen() RETURNS TRIGGER AS $$
BEGIN
	NEW.code = core.unique_for_table_field(8, 'words.sentences', 'code');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS sentences_code_gen ON words.sentences CASCADE;
CREATE TRIGGER sentences_code_gen
	BEFORE INSERT ON words.sentences
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE words.sentences_code_gen();

------------------------------------------------
-------------------------------------- JSON API:
------------------------------------------------ 

--Route{
--  api = "words.get_translator",
--  args = {"id"},
--  method = "GET",
--  url = "/translators/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION words.get_translator(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT t.*,
			p.name,
			p.email,
			p.address,
			p.company,
			p.city,
			p.state,
			p.country,
			p.phone
		FROM words.translators t, peeps.people p
		WHERE t.person_id = p.id
		AND t.id = $1
	) r;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "words.unfinished_articles",
--  args = {"lang"},
--  method = "GET",
--  url = "/articles/unfinished/([a-z]{2})",
--  captures = {"lang"},
-- note = "RESPONSE: [{id:2,filename:yep}] or []"
--}
CREATE OR REPLACE FUNCTION words.unfinished_articles(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT DISTINCT(articles.id), filename
		FROM words.articles
			JOIN words.sentences ON articles.id = sentences.article_id
			JOIN words.translations ON sentences.code = translations.sentence_code
		WHERE lang = $1
		AND translation IS NULL
		ORDER BY articles.id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "words.finished_articles",
--  args = {"lang"},
--  method = "GET",
--  url = "/articles/finished/([a-z]{2})",
--  captures = {"lang"},
-- note = "RESPONSE: [{id:2,filename:yep}] or []"
--}
CREATE OR REPLACE FUNCTION words.finished_articles(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, filename
		FROM words.articles
		WHERE id NOT IN (
			SELECT DISTINCT(article_id)
			FROM words.sentences
			WHERE code IN (
				SELECT sentence_code
				FROM words.translations
				WHERE lang = $1
				AND translation IS NULL
			)
		) ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- Full complete representation of an article, with all parts that might be used to edit.
-- id, filename, template, raw, merged, sentences: [{sortid, code, replacements, raw, merged}]
-- TODO: might need translations.id, but then English wouldn't have it. Treat differently?
-- PARAMS: article_id, lang
CREATE OR REPLACE FUNCTION words.get_article_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	-- English comes directly from sentences.sentence not translations.translation
	IF $2 = 'en' THEN js := row_to_json(r) FROM (
		SELECT id,
			filename,
			template,
			raw,
			words.merge_article($1, $2) AS merged, (
			SELECT json_agg(s) AS sentences FROM (
				SELECT sortid,
					code,
					replacements,
					sentence AS raw,
					words.merge_replacements(sentence, replacements) AS merged
				FROM words.sentences 
				WHERE article_id = $1
				ORDER BY sortid
			) s)
		FROM words.articles
		WHERE id = $1
	) r;
	-- Everything but English is in translations table
	ELSE js := row_to_json(r) FROM (
		SELECT id,
			filename,
			template,
			raw,
			words.merge_article($1, $2) AS merged, (
			SELECT json_agg(s) AS sentences FROM (
				SELECT sortid,
					code,
					replacements,
					translation AS raw,
					words.merge_replacements(translation, replacements) AS merged
				FROM words.sentences
					JOIN words.translations
					ON (sentences.code = translations.sentence_code
						AND translations.lang = $2)
				WHERE article_id = $1
				ORDER BY sortid
			) s)
		FROM words.articles
		WHERE id = $1
	) r;
	END IF;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;



-- Full complete representation of a sentence/translation, with all parts that might be used to edit.
-- {translations.id, translation, lang, code, article_id, sortid, replacements, sentence, merged}
-- PARAMS: code, lang
CREATE OR REPLACE FUNCTION words.get_sentence_lang(char(8), char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT translations.id,
			translation,
			lang,
			code,
			article_id,
			sortid,
			replacements,
			sentence,
			words.merge_replacements(translation, replacements) AS merged
		FROM words.sentences
			JOIN words.translations
			ON sentences.code = translations.sentence_code
		WHERE code = $1
		AND lang = $2
	) r;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;



-- next sentence not done yet
-- PARAMS: article_id, lang
CREATE OR REPLACE FUNCTION words.next_sentence_for_article_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
DECLARE
	code1 char(8);
BEGIN
	SELECT code INTO code1
	FROM words.sentences
		JOIN words.translations ON sentences.code = translations.sentence_code
	WHERE article_id = $1
	AND lang = $2
	AND translation IS NULL
	ORDER BY id
	LIMIT 1;
	IF code1 IS NULL THEN 
	status := 404;
	js := '{}';
 ELSE
		SELECT x.status, x.js INTO status, js
		FROM words.get_sentence_lang(code1, $2) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.get_translation(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r) FROM (
		SELECT id, sentence_code, lang, translation
		FROM words.translations
		WHERE id = $1
	) r;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.update_translation(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE words.translations SET translation = $2 WHERE id = $1;
	SELECT x.status, x.js INTO status, js
	FROM words.get_translation($1) x;

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


-- TODO: previous sentence (before this one), next sentence (after this one)


