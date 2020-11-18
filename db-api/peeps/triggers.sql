-- Strip spaces and lowercase email address before validating & storing
CREATE OR REPLACE FUNCTION peeps.clean_email() RETURNS TRIGGER AS $$
BEGIN
	NEW.email = lower(regexp_replace(NEW.email, '\s', '', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_email ON peeps.people CASCADE;
CREATE TRIGGER clean_email
	BEFORE INSERT OR UPDATE OF email ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_email();


CREATE OR REPLACE FUNCTION peeps.clean_their_email() RETURNS TRIGGER AS $$
BEGIN
	NEW.their_name = core.strip_tags(btrim(regexp_replace(NEW.their_name, '\s+', ' ', 'g')));
	NEW.their_email = lower(regexp_replace(NEW.their_email, '\s', '', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_their_email ON peeps.emails CASCADE;
CREATE TRIGGER clean_their_email
	BEFORE INSERT OR UPDATE OF their_name, their_email ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_their_email();


-- Strip all line breaks and spaces around name before storing
CREATE OR REPLACE FUNCTION peeps.clean_name() RETURNS TRIGGER AS $$
BEGIN
	NEW.name = core.strip_tags(btrim(regexp_replace(NEW.name, '\s+', ' ', 'g')));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_name ON peeps.people CASCADE;
CREATE TRIGGER clean_name
	BEFORE INSERT OR UPDATE OF name ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_name();


-- Statkey has no whitespace at all. Statvalue trimmed but keeps inner whitespace.
CREATE OR REPLACE FUNCTION peeps.clean_stats() RETURNS TRIGGER AS $$
BEGIN
	NEW.statkey = lower(regexp_replace(NEW.statkey, '[^[:alnum:]._-]', '', 'g'));
	IF NEW.statkey = '' THEN
		RAISE 'stats.key must not be empty';
	END IF;
	NEW.statvalue = btrim(NEW.statvalue, E'\r\n\t ');
	IF NEW.statvalue = '' THEN
		RAISE 'stats.value must not be empty';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_stats ON peeps.stats CASCADE;
CREATE TRIGGER clean_stats
	BEFORE INSERT OR UPDATE OF statkey, statvalue ON peeps.stats
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_stats();


-- urls.url remove all whitespace, then add http:// if not there
CREATE OR REPLACE FUNCTION peeps.clean_url() RETURNS TRIGGER AS $$
BEGIN
	NEW.url = regexp_replace(NEW.url, '\s', '', 'g');
	IF NEW.url !~ '^https?://' THEN
		NEW.url = 'http://' || NEW.url;
	END IF;
	IF NEW.url !~ '^https?://[0-9a-zA-Z_-]+\.[a-zA-Z0-9]+' THEN
		RAISE 'bad url';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_url ON peeps.urls CASCADE;
CREATE TRIGGER clean_url
	BEFORE INSERT OR UPDATE OF url ON peeps.urls
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_url();


-- Create "address" (first word of name) and random password upon insert of new person
CREATE OR REPLACE FUNCTION peeps.generated_person_fields() RETURNS TRIGGER AS $$
BEGIN
	NEW.address = split_part(btrim(regexp_replace(NEW.name, '\s+', ' ', 'g')), ' ', 1);
	NEW.lopass = core.random_string(4);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS generate_person_fields ON peeps.people CASCADE;
CREATE TRIGGER generate_person_fields
	BEFORE INSERT ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.generated_person_fields();


-- If something sets any of these fields to '', change it to NULL before saving
CREATE OR REPLACE FUNCTION peeps.null_person_fields() RETURNS TRIGGER AS $$
BEGIN
	IF btrim(NEW.country) = '' THEN
		NEW.country = NULL;
	END IF;
	IF btrim(NEW.email) = '' THEN
		NEW.email = NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS null_person_fields ON peeps.people CASCADE;
CREATE TRIGGER null_person_fields
	BEFORE INSERT OR UPDATE OF country, email ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.null_person_fields();


-- No whitespace, all lowercase, for emails.profile and emails.category
CREATE OR REPLACE FUNCTION peeps.clean_emails_fields() RETURNS TRIGGER AS $$
BEGIN
	NEW.profile = regexp_replace(lower(NEW.profile), '[^[:alnum:]_@-]', '', 'g');
	IF TG_OP = 'INSERT' AND (NEW.category IS NULL OR trim(both ' ' from NEW.category) = '') THEN
		NEW.category = NEW.profile;
	ELSE
		NEW.category = regexp_replace(lower(NEW.category), '[^[:alnum:]_@-]', '', 'g');
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_emails_fields ON peeps.emails CASCADE;
CREATE TRIGGER clean_emails_fields
	BEFORE INSERT OR UPDATE OF profile, category ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_emails_fields();


-- Update people.email_count when number of emails for this person_id changes
CREATE OR REPLACE FUNCTION peeps.update_email_count() RETURNS TRIGGER AS $$
DECLARE
	pid integer := NULL;
BEGIN
	IF ((TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.person_id IS NOT NULL) THEN
		pid := NEW.person_id;
	ELSIF (TG_OP = 'UPDATE' AND OLD.person_id IS NOT NULL) THEN
		pid := OLD.person_id;  -- in case updating to set person_id = NULL, recalcuate old one
	ELSIF (TG_OP = 'DELETE' AND OLD.person_id IS NOT NULL) THEN
		pid := OLD.person_id;
	END IF;
	IF pid IS NOT NULL THEN
		UPDATE peeps.people SET email_count=
			(SELECT COUNT(*) FROM peeps.emails WHERE person_id = pid AND outgoing IS FALSE)
			WHERE id = pid;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS update_email_count ON peeps.emails CASCADE;
CREATE TRIGGER update_email_count
	AFTER INSERT OR DELETE OR UPDATE OF person_id ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.update_email_count();


-- Setting a URL to be the "main" one sets all other URLs for that person to be NOT main
CREATE OR REPLACE FUNCTION peeps.one_main_url() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.main = 't' THEN
		UPDATE peeps.urls SET main=FALSE WHERE person_id=NEW.person_id AND id != NEW.id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS one_main_url ON peeps.urls CASCADE;
CREATE TRIGGER one_main_url
	AFTER INSERT OR UPDATE OF main ON peeps.urls
	FOR EACH ROW EXECUTE PROCEDURE peeps.one_main_url();


-- generate message_id for outgoing emails
CREATE OR REPLACE FUNCTION peeps.make_message_id() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.message_id IS NULL AND (NEW.outgoing IS TRUE OR NEW.outgoing IS NULL) THEN
		NEW.message_id = CONCAT(
			to_char(current_timestamp, 'YYYYMMDDHH24MISSMS'),
			'.', NEW.person_id, '@sivers.org');
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS make_message_id ON peeps.emails CASCADE;
CREATE TRIGGER make_message_id
	BEFORE INSERT ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.make_message_id();


-- categorize_as can't be empty string. make it NULL if empty
CREATE OR REPLACE FUNCTION peeps.null_categorize_as() RETURNS TRIGGER AS $$
BEGIN
	NEW.categorize_as = lower(regexp_replace(NEW.categorize_as, '\s', '', 'g'));
	IF NEW.categorize_as = '' THEN
		NEW.categorize_as = NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS null_categorize_as ON peeps.people CASCADE;
CREATE TRIGGER null_categorize_as
	BEFORE INSERT OR UPDATE ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.null_categorize_as();


-- atkey lower a-z or -
CREATE OR REPLACE FUNCTION peeps.clean_atkey() RETURNS TRIGGER AS $$
BEGIN
	NEW.atkey = regexp_replace(lower(NEW.atkey), '[^a-z-]', '', 'g');
	IF NEW.atkey = '' THEN
		RAISE 'atkeys.atkey must not be empty';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_atkey ON peeps.atkey CASCADE;
CREATE TRIGGER clean_atkey
	BEFORE INSERT OR UPDATE OF atkey ON peeps.atkeys
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_atkey();


-- inkey lower a-z or -
CREATE OR REPLACE FUNCTION peeps.clean_inkey() RETURNS TRIGGER AS $$
BEGIN
	NEW.inkey = regexp_replace(lower(NEW.inkey), '[^a-z-]', '', 'g');
	IF NEW.inkey = '' THEN
		RAISE 'inkeys.inkey must not be empty';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_inkey ON peeps.inkey CASCADE;
CREATE TRIGGER clean_inkey
	BEFORE INSERT OR UPDATE OF inkey ON peeps.inkeys
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_inkey();


-- If formletters.accesskey is '', change it to NULL before saving
CREATE OR REPLACE FUNCTION peeps.null_accesskey() RETURNS TRIGGER AS $$
BEGIN
	IF btrim(NEW.accesskey) = '' THEN
		NEW.accesskey = NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS null_accesskey ON peeps.people CASCADE;
CREATE TRIGGER null_accesskey
	BEFORE INSERT OR UPDATE OF accesskey ON peeps.formletters
	FOR EACH ROW EXECUTE PROCEDURE peeps.null_accesskey();


CREATE OR REPLACE FUNCTION peeps.generated_login_fields() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.cookie IS NULL THEN
		NEW.cookie = core.random_string(32);
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS generate_login_fields ON peeps.people CASCADE;
CREATE TRIGGER generate_login_fields
	BEFORE INSERT ON peeps.logins
	FOR EACH ROW EXECUTE PROCEDURE peeps.generated_login_fields();

