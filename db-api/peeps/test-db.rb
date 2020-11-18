require '../test_tools.rb'

class TestPeeps < Minitest::Test

	# peeps.people.country must be 2 uppercase letters existing in peeps.countries.code, or NULL
	def test_country
		DB.exec("UPDATE people SET country='BE' WHERE id=1");
		err = assert_raises PG::ForeignKeyViolation do
			DB.exec("UPDATE people SET country='XX' WHERE id=1");
		end
		assert err.message.include? 'people_country_fkey'
		err = assert_raises PG::ForeignKeyViolation do
			DB.exec("UPDATE people SET country='be' WHERE id=1");
		end
		DB.exec("UPDATE people SET country=NULL WHERE id=1");
	end

	# peeps.people.email must be vaguely valid ("string@string.string") or NULL.
	# constraint name: 'valid_email'. UPDATE and INSERT trim and lowercase email first
	def test_people_email
		res = DB.exec("UPDATE people SET email='	BEE@cee.DEE	' WHERE id=1 RETURNING email");
		assert_equal 'bee@cee.dee', res[0]['email']
		DB.exec("UPDATE people SET email=NULL WHERE id=1");
		err = assert_raises PG::CheckViolation do
			DB.exec("UPDATE people SET email='missing@tld' WHERE id=1");
		end
		assert err.message.include? 'valid_email'
		# if given empty string, converts to NULL first
		DB.exec("UPDATE people SET email='' WHERE id=1");
		res = DB.exec("SELECT email FROM people WHERE id=1");
		assert_nil res[0]['email']
	end

	# peeps.people.name can't be null or empty. UPDATE and INSERT trim first.
	def test_people_name_empty
		err = assert_raises PG::CheckViolation do
			DB.exec("INSERT INTO people (name) VALUES ('')")
		end
		assert err.message.include? 'no_name'
		err = assert_raises PG::CheckViolation do
			DB.exec("INSERT INTO people (name) VALUES ('\r\n	\r\n ')")
		end
		err = assert_raises PG::CheckViolation do
			DB.exec("SELECT * FROM person_create('', 'dog@dog.com')")
		end
		assert err.message.include? 'no_name'
		err = assert_raises PG::NotNullViolation do
			DB.exec("INSERT INTO people (name) VALUES (NULL)")
		end
		assert err.message.include? 'column "name"'
		err = assert_raises PG::NotNullViolation do
			DB.exec("SELECT * FROM person_create(NULL, 'dog@dog.com')")
		end
		assert err.message.include? 'column "name"'
	end

	# peeps.people.name has linebreaks removed, spaces trimmed by INSERT and UPDATE
	def test_people_name_clean
		DB.exec("UPDATE people SET name='\n\r	Spaced Out \r\n' WHERE id=2")
		res = DB.exec("SELECT name, address FROM people WHERE id=2")
		assert_equal 'Spaced Out', res[0]['name']
		# updating name does not update address
		assert_equal 'Mr. Wonka', res[0]['address']
		DB.exec("UPDATE people SET name='<script>boo</script>' WHERE id=2")
		res = DB.exec("SELECT name, address FROM people WHERE id=2")
		assert_equal 'boo', res[0]['name']
	end

	# peeps.emailers.profiles is array of values in peeps.emails.profile that this person is allowed to access
	# peeps.emailers.categories is array of values in peeps.emails.category that this person is allowed to access
	# if either one is '{ALL}', then all approved.	empty array means none approved.
	def test_emailers
		res = DB.exec("SELECT * FROM emailers WHERE id=3")
		assert_equal '{sivers}', res[0]['profiles']
		assert_equal '{translator,not-derek}', res[0]['categories']
		# here's one way of converting these into arrays. safe because '{}' chars will never be used.
		assert_equal ['sivers'], res[0]['profiles'].delete('{}').split(',')
		assert_equal ['translator', 'not-derek'], res[0]['categories'].delete('{}').split(',')
	end

	# can't delete a person if they were ever an emailer with emails
	def test_emailers_restrict_delete
		err = assert_raises PG::ForeignKeyViolation do
			DB.exec("DELETE FROM people WHERE id=7")
		end
		assert err.message.include? 'emailers_person_id_fkey'
	end

	# statkey stripped of all whitespace, even internal, upon INSERT or UPDATE
	# statvalue trimmed but keeps inner whitespace
	def test_stats_clean
		res = DB.exec("INSERT INTO stats (person_id, statkey, statvalue) VALUES (5, ' \nd O G\r ', ' ro\n vER ') RETURNING stats.*")
		assert_equal 'dog', res[0]['statkey']
		assert_equal "ro\n vER", res[0]['statvalue']
		res = DB.exec("UPDATE stats SET statkey=' \nH i\r\r', statvalue='\n o H \r' WHERE id=1 RETURNING stats.*")
		assert_equal 'hi', res[0]['statkey']
		assert_equal 'o H', res[0]['statvalue']
	end

	# deleting a person deletes their stats
	def test_stats_cascade_delete
		res = DB.exec("SELECT person_id FROM stats WHERE id=8")
		assert_equal '5', res[0]['person_id']
		DB.exec("DELETE FROM people WHERE id=5")
		res = DB.exec("SELECT person_id FROM stats WHERE id=8")
		assert_equal 0, res.ntuples
	end

	# urls.url whitespace removed, and 'http://' added if not there, on UPDATE and INSERT
	def test_urls_clean
		res = DB.exec("UPDATE urls SET url='twitter.com/wonka' WHERE id=5 RETURNING url")
		assert_equal 'http://twitter.com/wonka', res[0]['url']
		res = DB.exec("INSERT INTO urls(person_id, url) VALUES (5, '	https:// mybank.com\r\n') RETURNING url")
		assert_equal 'https://mybank.com', res[0]['url']
		err = assert_raises PG::RaiseException do
			DB.exec("INSERT INTO urls(person_id, url) VALUES (5, '')")
		end
		err = assert_raises PG::RaiseException do
			DB.exec("INSERT INTO urls(person_id, url) VALUES (5, 'x')")
		end
		err = assert_raises PG::RaiseException do
			DB.exec("INSERT INTO urls(person_id, url) VALUES (5, 'me@aol.com')")
		end
	end

	# deleting a person deletes their urls
	def test_urls_cascade_delete
		res = DB.exec("SELECT person_id FROM urls WHERE id=8")
		assert_equal '5', res[0]['person_id']
		DB.exec("DELETE FROM people WHERE id=5")
		res = DB.exec("SELECT person_id FROM urls WHERE id=8")
		assert_equal 0, res.ntuples
	end

	# person_create(name, email) cleans then returns one peeps.people row
	# USE THIS for adding/inserting a new person into the database.
	def test_person_create
		res = DB.exec("SELECT * FROM person_create('	Miles Davis	', ' MILES@aol.COM')")
		x = res[0]
		assert_equal '9', x['id']
		assert_equal 'Miles Davis', x['name']
		# address auto-created from first word of name
		assert_equal 'Miles', x['address']
		assert_equal 'miles@aol.com', x['email']
		assert_nil x['hashpass']
		# INSERT creates default values
		assert_equal 4, x['lopass'].size
		assert_nil x['newpass']
		assert_equal '0', x['email_count']
		assert_equal Time.now.to_s[0,10], x['created_at']
		# if cleaned email exists in db already, returns that row
		res = DB.exec("SELECT * FROM person_create(' Miles Davis III', ' MILES@AOL.com')")
		assert_equal '9', res[0]['id']
		res = DB.exec("SELECT * FROM person_create('Name Ignored if Email Matches', 'derek@SIVERS.org')")
		assert_equal '1', res[0]['id']
		assert_equal 'Derek Sivers', res[0]['name']
		# can't create new person with NULL email, empty or invalid email
		err = assert_raises PG::RaiseException do
			DB.exec("SELECT * FROM person_create('Valid Name', NULL)")
		end
		assert err.message.include? 'missing_email'
		err = assert_raises PG::RaiseException do
			DB.exec("SELECT * FROM person_create('Valid Name', '	')")
		end
		assert err.message.include? 'missing_email'
		err = assert_raises PG::CheckViolation do
			DB.exec("SELECT * FROM person_create('Valid Name', 'bad@email')")
		end
		assert err.message.include? 'valid_email'
	end

	# people.email_count is a cache of howmany emails with this person_id, used for sorting search results.
	def test_update_email_count
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '4', res[0]['email_count']
		DB.exec("UPDATE emails SET person_id=3 WHERE id IN (5, 10)")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '6', res[0]['email_count']
		DB.exec("DELETE FROM emails WHERE id=9")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '5', res[0]['email_count']
		DB.exec("UPDATE emails SET person_id=NULL WHERE id IN (5, 10)")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '3', res[0]['email_count']
		DB.exec("INSERT INTO emails(person_id, profile, their_email, their_name) VALUES (3, 'sivers', 'x@x.x', 'x')")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '4', res[0]['email_count']
	end

	# emailer is a person with permission to access emails with certain profiles or categories
	# first param is emailer.id (logged-in user). second param is email.id
	# Returns emails.* for that email.id, or nothing if not allowed
	def test_emailer_get_email
		res = DB.exec("SELECT * FROM emailer_get_email(1, 1)")
		assert_equal 1, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(3, 1)")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(3, 2)")
		assert_equal 1, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(3, 7)")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(4, 7)")
		assert_equal 1, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(4, 2)")
		assert_equal 0, res.ntuples
	end

	# Returns unopened emails.* that this emailer is authorized to see
	def test_emailer_get_unopened
		res = DB.exec("SELECT id FROM emailer_get_unopened(1)")
		assert_equal %w(7 8 9), res.map {|x| x['id']}
		res = DB.exec("SELECT id FROM emailer_get_unopened(3)")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT id FROM emailer_get_unopened(4)")
		assert_equal %w(7 8), res.map {|x| x['id']}
	end

	# Returns string to be set as cookie, then used in get_person_id_from_cookie
	def test_login_person_domain
		res = DB.exec("SELECT * FROM login_person_domain(5, 'muckwork.com')")
		cookie = res[0]['cookie']
		assert_match /^[a-zA-Z0-9]{32}$/, cookie
		res = DB.exec("SELECT * FROM peeps.logins WHERE person_id=5")
		assert_equal 1, res.ntuples
		assert_equal 'muckwork.com', res[0]['domain']
		assert_equal cookie, res[0]['cookie']
		# returns same cookie if exists, not inserting another
		res = DB.exec("SELECT * FROM login_person_domain(5, 'muckwork.com')")
		assert_equal cookie, res[0]['cookie']
	end

	# Give cookie, get person_id or nil
	def test_get_person_id_from_cookie
		res = DB.exec("SELECT login_person_domain(5, 'muckwork.com')")
		cookie = res.getvalue(0, 0)
		res = DB.exec("SELECT * FROM get_person_id_from_cookie('%s')" % cookie)
		assert_equal 5, res[0]['person_id'].to_i
		cookie[0, 1] = 'Z'
		res = DB.exec("SELECT * FROM get_person_id_from_cookie('%s')" % cookie)
		assert_nil res[0]['person_id']
	end

	# Setting urls.main=true makes others for this person urls.main=false
	def test_url_main
		res = DB.exec("SELECT main FROM urls WHERE id=3")
		assert_equal 't', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=5")
		assert_nil res[0]['main']
		DB.exec("UPDATE urls SET main=TRUE WHERE id=5")
		res = DB.exec("SELECT main FROM urls WHERE id=5")
		assert_equal 't', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=3")
		assert_equal 'f', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=6")
		assert_nil res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=7")
		assert_nil res[0]['main']
		DB.exec("UPDATE urls SET main='t' WHERE id=6")
		res = DB.exec("SELECT main FROM urls WHERE id=6")
		assert_equal 't', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=7")
		assert_equal 'f', res[0]['main']
		DB.exec("INSERT INTO urls (person_id, url, main) VALUES (3, 'salt.biz', 't')")
		res = DB.exec("SELECT main FROM urls WHERE id=6")
		assert_equal 'f', res[0]['main']
	end

	# emails.profile and emails.category can not be null or empty
	# both cleaned to lowercase, strip all but a-z0-9_@-
	# for new emails, empty category set to match profile
	def test_emails_checks
		assert_raises PG::NotNullViolation do
			DB.exec("UPDATE emails SET profile=NULL WHERE id=1")
		end
		assert_raises PG::NotNullViolation do
			DB.exec("UPDATE emails SET category=NULL WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE emails SET profile='' WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE emails SET category='	!\r/ |\n~ & ^ ' WHERE id=1")	# <-- cleaned to ''
		end
		res = DB.exec("INSERT INTO emails (person_id, profile, their_email, their_name) VALUES (3, 'we@woodegg','x@x.x', 'x') RETURNING *")
		assert_equal 'we@woodegg', res[0]['category']
		res = DB.exec("INSERT INTO emails (person_id, profile, category, their_email, their_name) VALUES (3, 'sivers', '  ', 'x@x.x', 'x') RETURNING *")
		assert_equal 'sivers', res[0]['category']
		res = DB.exec("INSERT INTO emails (person_id, profile, category, their_email, their_name) VALUES (3, ' sIVers\r\n', ' !TH*&is-/tH_At	', 'x@x.x', 'x') RETURNING *")
		assert_equal 'sivers', res[0]['profile']
		assert_equal 'this-th_at', res[0]['category']
		res = DB.exec("UPDATE emails SET profile='!D@_s-!', category='\r\n\t%T\t\r\n ' WHERE id=8 RETURNING *")
		assert_equal 'd@_s-', res[0]['profile']
		assert_equal 't', res[0]['category']
	end

	# because of hashing crypting stuff, use this to set someone's password
	def test_set_hashpass
		res = DB.exec("SELECT hashpass FROM people WHERE id=1")
		old_hashpass = res[0]['hashpass']
		assert old_hashpass.size > 20
		DB.exec_params("SELECT set_hashpass($1, $2)", [1, 'bl00p€r'])
		res = DB.exec("SELECT hashpass FROM people WHERE id=1")
		refute_equal old_hashpass, res[0]['hashpass']
		assert res[0]['hashpass'].size > 20
		# password must be > 3 characters
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT set_hashpass($1, $2)", [1, 'x¥z'])
		end
		assert err.message.include? 'short_password'
	end

	def test_person_create_pass
		res = DB.exec_params("SELECT * FROM person_create_pass($1, $2, $3)",
			['Bob Dobalina', 'BOB@dobali.NA', 'mYPass!'])
		assert_equal '9', res[0]['id']
		assert_equal 'bob@dobali.na', res[0]['email']
		assert_equal 'Bob', res[0]['address']
		res = DB.exec_params("SELECT * FROM person_email_pass($1, $2)",
			['bob@dobali.na', 'mYPass!'])
		assert_equal '9', res[0]['id']
		# if person exists, password doesn't change:
		res = DB.exec_params("SELECT * FROM person_create_pass($1, $2, $3)",
			['Derek', 'derek@sivers.org', 'attack!'])
		assert_equal '1', res[0]['id']
		res = DB.exec_params("SELECT * FROM person_email_pass($1, $2)",
			['derek@sivers.org', 'derek'])
		assert_equal '1', res[0]['id']
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT * FROM person_create_pass($1, $2, $3)",
			['Derek', '', 'attack!'])
		end
		assert err.message.include? 'missing_email'
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT * FROM person_create_pass($1, $2, $3)",
			['New Person', 'new@person.cc', 'x'])
		end
		assert err.message.include? 'short_password'
	end

	# needs valid email and password 4+ chars.	use exec_params
	def test_person_email_pass
		res = DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['derek@sivers.org', 'derek'])
		assert_equal 'Derek Sivers', res[0]['name']
		nu_pass = 'bl00p€r'
		DB.exec_params("SELECT set_hashpass($1, $2)", [2, nu_pass])
		res = DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['willy@wonka.com', nu_pass])
		assert_equal 'Willy Wonka', res[0]['name']
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['willy@wonka', nu_pass])
		end
		assert err.message.include? 'bad_email'
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['willy@wonka.com', 'x1x'])
		end
		assert err.message.include?	'short_password'
	end

	def test_person_merge_from_to
		res = DB.exec("INSERT INTO people(name, email, state, notes) VALUES ('New Derek', 'derek@new.com', 'confusion', 'Soon to be.') RETURNING id")
		new_id = res[0]['id'].to_i
		res = DB.exec_params("SELECT * FROM person_merge_from_to($1, $2)", [1, new_id])
		res = DB.exec("SELECT * FROM people WHERE id = #{new_id}")
		assert_equal '50POP LLC', res[0]['company']
		assert_equal 'Singapore', res[0]['city']
		assert_equal 'confusion', res[0]['state']
		assert_equal "This is me.\nSoon to be.", res[0]['notes']
	end

	def test_id_from_email_pass
		res = DB.exec_params("SELECT pid FROM peeps.pid_from_email_pass($1, $2)", ['derek@sivers.org', 'derek'])
		assert_equal '1', res[0]['pid']
		res = DB.exec_params("SELECT pid FROM peeps.pid_from_email_pass($1, $2)", [' Derek@Sivers.org  ', 'derek'])
		assert_equal '1', res[0]['pid']
		res = DB.exec_params("SELECT pid FROM peeps.pid_from_email_pass($1, $2)", ['derek@sivers.org', 'deRek'])
		assert_nil res[0]['pid']
		res = DB.exec_params("SELECT pid FROM peeps.pid_from_email_pass($1, $2)", ['derek@sivers.org', ''])
		assert_nil res[0]['pid']
		res = DB.exec_params("SELECT pid FROM peeps.pid_from_email_pass($1, $2)", ['', 'derek'])
		assert_nil res[0]['pid']
		res = DB.exec("SELECT pid FROM peeps.pid_from_email_pass(NULL, NULL)")
		assert_nil res[0]['pid']
	end

	def test_null_categorize_as
		res = DB.exec("INSERT INTO people(name, email, categorize_as) VALUES ('Test1', 'test@test.is', ' ') RETURNING id")
		new_id = res[0]['id'].to_i
		res = DB.exec("SELECT categorize_as FROM people WHERE id=#{new_id}")
		assert_nil res[0]['categorize_as']
		DB.exec("UPDATE people SET categorize_as='' WHERE id=2")
		res = DB.exec("SELECT id FROM people WHERE id=2 AND categorize_as IS NULL")
		assert_equal '2', res[0]['id']
	end

	def test_get_person_id_from_email
		res = DB.exec_params("SELECT id FROM peeps.get_person_id_from_email($1)", [' Derek@siVERs . ORG '])
		assert_equal '1', res[0]['id']
		res = DB.exec_params("SELECT id FROM peeps.get_person_id_from_email($1)", ['sivers'])
		assert_nil res[0]['id']
		res = DB.exec("SELECT id FROM peeps.get_person_id_from_email('')")
		assert_nil res[0]['id']
		res = DB.exec("SELECT id FROM peeps.get_person_id_from_email(NULL)")
		assert_nil res[0]['id']
	end

	def test_parse_formletter_body
		res = DB.exec("SELECT js FROM peeps.make_newpass(1)")
		js = JSON.parse(res[0]['js'])
		newpass = js['newpass']
		res = DB.exec("SELECT * FROM peeps.parse_formletter_body(1, 1)")
		assert_equal("Your email is derek@sivers.org. Here is your URL: https://data.sivers.org/newpass/1/#{newpass} OK?", res[0]['body'])
		res = DB.exec("SELECT * FROM peeps.parse_formletter_body(1, 2)")
		assert_equal 'Hi Derek. Thank you for buying something on somedate. We will ship it to your address.', res[0]['body']
		res = DB.exec("SELECT * FROM peeps.parse_formletter_body(1, 3)")
		assert_equal 'meh', res[0]['body']
	end

	def test_parse_formletter_subject
		res = DB.exec("SELECT * FROM peeps.parse_formletter_subject(1, 1)")
		assert_equal 'Derek your email', res[0]['subject']
		res = DB.exec("SELECT * FROM peeps.parse_formletter_subject(1, 2)")
		assert_equal 'Derek thanks address', res[0]['subject']
		res = DB.exec("SELECT * FROM peeps.parse_formletter_subject(1, 3)")
		assert_nil res[0]['subject']
	end

	def test_pid_for_twitter_handle
		res = DB.exec("SELECT pid FROM peeps.pid_for_twitter_handle('@siVers')")
		assert_equal '1', res[0]['pid']
		res = DB.exec("SELECT pid FROM peeps.pid_for_twitter_handle('WONKa')")
		assert_equal '2', res[0]['pid']
		res = DB.exec("SELECT pid FROM peeps.pid_for_twitter_handle('notFound')")
		assert_nil res[0]['pid']
	end

	def test_email_signature
		res = DB.exec("SELECT sig FROM peeps.email_sig('sivers')")
		assert_equal 'Derek Sivers  derek@sivers.org  https://sivers.org/', res[0]['sig']
		res = DB.exec("SELECT sig FROM peeps.email_sig('woodegg')")
		assert_equal 'Wood Egg  we@woodegg.com  https://woodegg.com/', res[0]['sig']
		err = assert_raises PG::RaiseException do
			DB.exec("SELECT sig FROM peeps.email_sig('xxx')")
		end
	end
end

