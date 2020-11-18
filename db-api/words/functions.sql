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
