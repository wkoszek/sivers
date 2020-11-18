-- Use to verify new (from Gengo) translations, to quickly few on screen whether
-- they look like they match up or not. Unused, saving because it's a cool query.
-- PARAMS:  articles.id, translation file from translator
CREATE OR REPLACE FUNCTION words.txn_compare(integer, text) RETURNS
	TABLE(sortid integer, code char(8), en text, theirs text) AS $$
BEGIN
	RETURN QUERY WITH t2 AS (SELECT * FROM
		UNNEST(regexp_split_to_array(replace($2, E'\r', ''), E'\n'))
		WITH ORDINALITY AS theirs)
	SELECT t1.sortid, t1.code, t1.sentence, t2.theirs FROM words.sentences t1
		INNER JOIN t2 ON t1.sortid=t2.ordinality
		WHERE t1.article_id=$1
		ORDER BY t1.sortid;
END;
$$ LANGUAGE plpgsql;


-- PARAMS:  articles.id, 2-char lang code, translation file from translator
CREATE OR REPLACE FUNCTION words.txn_update(integer, text, text) RETURNS boolean AS $$
DECLARE
	atxn RECORD;
BEGIN
	FOR atxn IN SELECT code, theirs FROM words.txn_compare($1, $3) LOOP
		EXECUTE 'UPDATE words.sentences SET ' || quote_ident($2) || ' = $2 WHERE code = $1'
			USING atxn.code, atxn.theirs;
	END LOOP;
	RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


