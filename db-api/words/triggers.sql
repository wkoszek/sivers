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

