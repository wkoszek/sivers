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
	IF js IS NULL THEN m4_NOTFOUND END IF;
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
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
	IF code1 IS NULL THEN m4_NOTFOUND ELSE
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.update_translation(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE words.translations SET translation = $2 WHERE id = $1;
	SELECT x.status, x.js INTO status, js
	FROM words.get_translation($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- TODO: previous sentence (before this one), next sentence (after this one)

