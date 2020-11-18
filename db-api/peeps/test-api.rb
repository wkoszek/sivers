require '../test_tools.rb'

class TestPeepsAPI < Minitest::Test
	include JDB

	def test_unopened_email_count
		qry("unopened_email_count(1)")
		assert_equal %i(sivers woodegg), @j.keys
		assert_equal({:woodegg => 1, :'not-derek' => 1}, @j[:'woodegg'])
		qry("unopened_email_count(4)")
		assert_equal %i(woodegg), @j.keys
		qry("unopened_email_count(3)")
		assert_equal({}, @j)
	end

	def test_unopened_emails
		qry("unopened_emails(1, 'woodegg', 'woodegg')")
		assert_instance_of Array, @j
		assert_equal 1, @j.size
		assert_equal 'I refuse to wait', @j[0][:subject]
		assert_nil @j[0][:body]
		qry("unopened_emails(3, 'woodegg', 'woodegg')")
		assert_equal [], @j
	end

	def test_open_next_email
		qry("open_next_email(1, 'woodegg', 'woodegg')")
		assert_equal 8, @j[:id]
		assert_equal 1, @j[:openor][:id]
		assert_equal 'Derek Sivers', @j[:openor][:name]
		assert_match /^\d{4}-\d{2}-\d{2}/, @j[:opened_at]
		assert_equal 'I refuse to wait', @j[:subject]
		assert_equal 'I refuse to wait', @j[:body]
		qry("open_next_email(1, 'woodegg', 'woodegg')")
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_opened_emails
		qry("opened_emails(1)")
		assert_instance_of Array, @j
		assert_equal 1, @j.size
		assert_equal 'I want that Wood Egg book now', @j[0][:subject]
		qry("opened_emails(3)")
		assert_equal [], @j
	end

	def test_get_email
		qry("get_email(1, 2)")
		assert_equal 4, @j[:answer_id]
		qry("get_email(1, 4)")
		assert_equal 2, @j[:reference_id]
		qry("get_email(1, 8)")
		assert_equal 'I refuse to wait', @j[:subject]
		assert_equal 'Derek Sivers', @j[:openor][:name]
		qry("get_email(1, 6)")
		assert_equal '2014-05-21', @j[:opened_at][0,10]
		qry("get_email(3, 6)")
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_update_email
		qry("update_email(1, 8, $1)", ['{"subject":"boop", "ig":"nore"}'])
		assert_equal 'boop', @j[:subject]
		qry("update_email(3, 8, $1)", ['{"subject":"boop", "ig":"nore"}'])
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_update_email_errors
		qry("update_email(1, 8, $1)", ['{"opened_by":"boop"}'])
		assert_equal '500', @res[0]['status']
		assert @j[:code].include? '22P02'
		assert @j[:message].include? 'invalid input syntax for integer'
		assert @j[:context].include? 'jsonupdate'
	end

	def test_delete_email
		qry("delete_email(1, 8)")
		assert_equal '200', @res[0]['status']
		assert_equal 'I refuse to wait', @j[:subject]
		qry("delete_email(1, 8)")
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
		qry("delete_email(3, 1)")
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_close_email
		qry("close_email(4, 6)")
		assert_equal 4, @j[:closor][:id]
	end

	def test_unread_email
		qry("unread_email(4, 6)")
		assert_nil @j[:opened_at]
		assert_nil @j[:openor]
	end

	def test_not_my_email
		qry("not_my_email(4, 6)")
		assert_nil @j[:opened_at]
		assert_nil @j[:openor]
		assert_equal 'not-gong', @j[:category]
	end

	def test_reply_to_email
		qry("reply_to_email(4, 8, 'Groovy, baby')")
		assert_equal 11, @j[:id]
		qry("get_email(4, 11)")
		assert_equal 3, @j[:person][:id]
		assert_match /\A[0-9]{17}\.3@sivers.org\Z/, @j[:message_id]
		assert_equal @j[:message_id][0,12], Time.now.strftime('%Y%m%d%H%M')
		assert @j[:body].include? 'Groovy, baby'
		assert_match /\AHi Veruca -/, @j[:body]
		refute_match /I refuse to wait/, @j[:body] # no more quoted body
		assert_match %r{^Wood Egg  we@woodegg.com  https://woodegg.com\/$}, @j[:body]
		assert_nil @j[:outgoing]
		assert_equal 're: I refuse to wait', @j[:subject]
		assert_match %r{^20}, @j[:created_at]
		assert_match %r{^20}, @j[:opened_at]
		assert_match %r{^20}, @j[:closed_at]
		assert_equal '巩俐', @j[:creator][:name]
		assert_equal '巩俐', @j[:openor][:name]
		assert_equal '巩俐', @j[:closor][:name]
		assert_equal 'Veruca Salt', @j[:their_name]
		assert_equal 'veruca@salt.com', @j[:their_email]
		# and it also closes the original email
		qry("get_email(4, 8)")
		assert_equal 11, @j[:answer_id]
		assert_match %r{^20}, @j[:closed_at]
		assert_equal '巩俐', @j[:closor][:name]
	end

	def test_count_unknowns
		qry("count_unknowns(1)")
		assert_equal({count: 2}, @j)
		qry("count_unknowns(4)")
		assert_equal({count: 0}, @j)
	end

	def test_get_unknowns
		qry("get_unknowns(1)")
		assert_instance_of Array, @j
		assert_equal 2, @j.size
		assert_equal [5, 10], @j.map{|x| x[:id]}
		qry("get_unknowns(4)")
		assert_equal [], @j
	end

	def test_get_next_unknown
		qry("get_next_unknown(1)")
		assert_equal 'New Stranger', @j[:their_name]
		assert @j[:body].include? 'I have a question'
		assert @j[:headers].include? 'new@stranger.com'
		qry("get_next_unknown(4)")
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_set_unknown_person
		qry("set_unknown_person(1, 5, 0)")
		assert_equal 9, @j[:person][:id]
		qry("set_unknown_person(1, 10, 5)")
		assert_equal 5, @j[:person][:id]
		qry("get_person(5)")
		assert_equal 'OLD EMAIL: oompa@loompa.mm', @j[:notes].strip
	end

	def test_set_unknown_person_fail
		qry("set_unknown_person(1, 99, 5)")
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
		qry("set_unknown_person(1, 5, 99)")
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_delete_unknown
		qry("delete_unknown(1, 5)")
		assert_equal 'random question', @j[:subject]
		qry("delete_unknown(1, 8)")
		assert_equal({}, @j)
		qry("delete_unknown(4, 10)")
		assert_equal({}, @j)
		qry("delete_unknown(3, 10)")
		assert_equal 'remember me?', @j[:subject]
	end

	def test_create_person
		qry("create_person('  Bob Dobalina', 'MISTA@DOBALINA.COM')")
		assert_equal 9, @j[:id]
		assert_equal 'Bob', @j[:address]
		assert_equal 'mista@dobalina.com', @j[:email]
		%i(stats urls emails).each do |k|
			assert @j.keys.include? k
			assert_nil @j[k]
		end
	end

	def test_create_person_fail
		qry("create_person('', 'a@b.c')")
		assert @j[:message].include? 'no_name'
		qry("create_person('Name', 'a@b')")
		assert @j[:message].include? 'valid_email'
	end

	def test_get_person
		qry("get_person(99)")
		assert_equal({}, @j)
		qry("get_person(2)")
		assert_equal 'http://www.wonka.com/', @j[:urls][0][:url]
		assert_equal 'you coming by?', @j[:emails][0][:subject]
		assert_equal 'musicthoughts', @j[:stats][1][:name]
		assert_equal 'clicked', @j[:stats][1][:value]
	end

	def test_make_newpass
		qry("make_newpass(1)")
		newpass1 = @j[:newpass]
		qry("make_newpass(1)")
		assert_equal({id: 1, newpass: newpass1}, @j)
		qry("make_newpass(8)")
		assert_equal 8, @j[:id]
		assert_match /\A[a-zA-Z0-9]{8}\Z/, @j[:newpass]
		newpass8 = @j[:newpass]
		qry("make_newpass(8)")
		assert_equal newpass8, @j[:newpass]
		qry("make_newpass(99)")
		assert_equal({}, @j)
		qry("make_newpass(NULL)")
		assert_equal({}, @j)
	end

	def test_get_person_lopass
		qry("get_person_lopass(2, 'bad1')")
		assert_equal({}, @j)
		qry("get_person_lopass(2, 'R5Gf')")
		assert_equal 'http://www.wonka.com/', @j[:urls][0][:url]
		assert_equal 'you coming by?', @j[:emails][0][:subject]
		assert_equal 'musicthoughts', @j[:stats][1][:name]
		assert_equal 'clicked', @j[:stats][1][:value]
	end

	def test_get_person_newpass
		qry("get_person_newpass(2, 'Another1')")
		assert_equal({}, @j)
		qry("make_newpass(2)")
		newpass = @j[:newpass]
		qry("get_person_newpass(2, $1)", [newpass])
		assert_equal 'http://www.wonka.com/', @j[:urls][0][:url]
		assert_equal 'you coming by?', @j[:emails][0][:subject]
		assert_equal 'musicthoughts', @j[:stats][1][:name]
		assert_equal 'clicked', @j[:stats][1][:value]
	end

	def test_get_person_password
		qry("get_person_password($1, $2)", ['derek@sivers.org', 'derek'])
		assert_equal 'Derek Sivers', @j[:name]
		qry("get_person_password($1, $2)", [' Derek@Sivers.org  ', 'derek'])
		assert_equal 'Derek Sivers', @j[:name]
		qry("get_person_password($1, $2)", ['derek@sivers.org', 'deRek'])
		assert_equal({}, @j)
		qry("get_person_password($1, $2)", ['derek@sivers.org', ''])
		assert_equal({}, @j)
		qry("get_person_password($1, $2)", ['', 'derek'])
		assert_equal({}, @j)
		qry("get_person_password(NULL, NULL)")
		assert_equal({}, @j)
	end

	def test_get_person_cookie
		qry("get_person_cookie($1)", ['NOugliNn5k67qJUuXEk8UGr6SCMAA645'])
		assert_equal 'Derek Sivers', @j[:name]
		qry("get_person_cookie($1)", ['NOugliNn5k67qJUuXEk8UGr6SCMAA645x'])
		assert_equal({}, @j)
	end

	def test_person_in_table
		qry("person_in_table(1, 'muckwork.clients')")
		assert_equal({}, @j)
		qry("person_in_table(2, 'muckwork.clients')")
		assert_equal({id: 1}, @j)
		qry("person_in_table(2, 'duckwork.clients')")
		assert @j[:message].include? 'does not exist'
	end

	def test_cookie_from_id
		qry("cookie_from_id($1, $2)", [3, 'woodegg.com'])
		assert_match /\A[a-zA-Z0-9]{32}\Z/, @j[:cookie]
		qry("get_person_cookie($1)", [@j[:cookie]])
		assert_equal 'Veruca Salt', @j[:name]
		qry("cookie_from_id(99, 'woodegg.com')")
		assert @j[:message].include? 'foreign key constraint'
		qry("cookie_from_id(NULL, 'woodegg.com')")
		assert @j[:message].include? 'not-null constraint'
		qry("cookie_from_id(4, NULL)")
		assert @j[:message].include? 'not-null constraint'
	end

	def test_cookie_from_login
		qry("cookie_from_login($1, $2, $3)", ['derek@sivers.org', 'derek', 'sivers.org'])
		assert_match /\A[a-zA-Z0-9]{32}\Z/, @j[:cookie]
		qry("cookie_from_login($1, $2, $3)", [' Derek@Sivers.org  ', 'derek', 'muckwork.com'])
		assert_match /\A[a-zA-Z0-9]{32}\Z/, @j[:cookie]
		qry("cookie_from_login($1, $2, $3)", ['derek@sivers.org', 'deRek', 'sivers.org'])
		assert_equal({}, @j)
		qry("cookie_from_login($1, $2, $3)", ['', 'derek', 'muckwork.com'])
		assert_equal({}, @j)
		qry("cookie_from_login(NULL, NULL, NULL)")
		assert_equal({}, @j)
		qry("cookie_from_login($1, $2, $3)", ['veruca@salt.com', 'veruca', 'muckwork.com'])
		qry("get_person_cookie($1)", [@j[:cookie]])
		assert_equal 'Veruca Salt', @j[:name]
	end

	def test_set_password
		nupass = 'þíŋø¥|ǫ©'
		qry("set_password($1, $2)", [1, nupass])
		assert_equal 'Derek Sivers', @j[:name]
		qry("get_person_password($1, $2)", ['derek@sivers.org', nupass])
		assert_equal 'Derek Sivers', @j[:name]
		qry("set_password($1, $2)", [1, 'x'])
		assert_equal 'short_password', @j[:message]
		qry("set_password(1, NULL)")
		assert_equal 'short_password', @j[:message]
		qry("set_password(9999, 'anOKpass')")
		assert_equal({}, @j)
	end

	def test_update_person
		qry("update_person(8, $1)", ['{"address":"Ms. Ono", "city": "NY", "ig":"nore"}'])
		assert_equal 'Ms. Ono', @j[:address]
		assert_equal 'NY', @j[:city]
	end

	def test_update_person_fail
		qry("update_person(99, $1)", ['{"country":"XXX"}'])
		assert_equal({}, @j)
		qry("update_person(1, $1)", ['{"country":"XXX"}'])
		assert @j[:message].include? 'value too long'
	end

	def test_delete_person
		qry("delete_person(1)")
		assert @j[:message].include? 'violates foreign key'
		qry("delete_person(99)")
		assert_equal({}, @j)
		qry("delete_person(5)")
		assert_equal 'Oompa Loompa', @j[:name]
	end

	def test_annihilate_person
		qry("annihilate_person(99)")
		assert_equal({}, @j)
		qry("annihilate_person(2)")
		assert_equal 'Willy Wonka', @j[:name]
		qry("get_person(2)")
		assert_equal({}, @j)
		qry("get_email(1, 1)")
		assert_equal({}, @j)
		qry("get_email(1, 3)")
		assert_equal({}, @j)
		qry("get_url(3)")
		assert_equal({}, @j)
		# can't delete an emailer
		qry("annihilate_person(1)")
		assert @j[:message].include? 'foreign key constraint "emails_created_by_fkey"'
	end

	def test_add_url
		qry("add_url(5, 'bank.com')")
		assert_equal 'http://bank.com', @j[:url]
		assert_equal 9, @j[:id]
		qry("add_url(5, 'x')")
		assert_equal 'bad url', @j[:message]
		qry("add_url(999, 'http://good.com')")
		assert @j[:message].include? 'violates foreign key'
		qry("add_url(1, $1)", ["http://#{'x.' * 200}"])
		assert @j[:message].include? 'value too long'
	end

	def test_add_stat
		qry("add_stat(5, ' s OM e ', '  v alu e ')")
		assert_equal 14, @j[:id]
		assert_equal 'some', @j[:name]
		assert_equal 'v alu e', @j[:value]
		qry("add_stat(5, '  ', 'val')")
		assert_equal 'stats.key must not be empty', @j[:message]
		qry("add_stat(5, 'key', ' ')")
		assert_equal 'stats.value must not be empty', @j[:message]
		qry("add_stat(99, 'a key', 'a val')")
		assert @j[:message].include? 'violates foreign key'
	end

	def test_new_email
		qry("new_email(4, 5, 'woodegg', 'a subject', 'a body')")
		assert_equal 'a subject', @j[:subject]
		assert_equal "Hi Oompa Loompa -\n\na body\n\n--\nWood Egg  we@woodegg.com  https://woodegg.com/", @j[:body]
		qry("new_email(4, 99, 'woodegg', 'a subject', 'a body')")
		assert_equal 'person_id not found', @j[:message]
		qry("new_email(4, 1, 'xxxx', 'a subject', 'a body')")
		assert_equal 'email signature not found', @j[:message]
		qry("new_email(4, 1, 'woodegg', 'a subject', '  ')")
		assert_equal 'body must not be empty', @j[:message]
	end
	
	def test_get_person_emails
		qry("get_person_emails(3)")
		assert_equal 4, @j.size
		assert_equal [6, 7, 8, 9], @j.map {|x| x[:id]}
		assert @j[0][:body]
		assert @j[1][:message_id]
		assert @j[2][:headers]
		assert_equal false, @j[3][:outgoing]
		qry("get_person_emails(99)")
		assert_equal [], @j
	end

	def test_people_unemailed
		qry("people_unemailed()")
		assert_equal [8, 6, 5, 4, 1], @j.map {|x| x[:id]}
		qry("new_email(4, 5, 'woodegg', 'subject', 'body')")
		qry("people_unemailed()")
		assert_equal [8, 6, 4, 1], @j.map {|x| x[:id]}
	end

	def test_people_search
		qry("people_search('on')")
		assert_instance_of Array, @j
		assert_equal [7, 2, 8], @j.map {|x| x[:id]}
		qry("people_search('x')")
		assert_equal 'search term too short', @j[:message]
	end

	def test_get_stat
		qry("get_stat(8)")
		assert_equal 'media', @j[:name]
		assert_equal 'interview', @j[:value]
		assert_equal 5, @j[:person][:id]
		assert_equal 'oompa@loompa.mm', @j[:person][:email]
		assert_equal 'Oompa Loompa', @j[:person][:name]
	end

	def test_delete_stat
		qry("delete_stat(8)")
		assert_equal 'interview', @j[:value]
		qry("get_stat(8)")
		assert_equal({}, @j)
	end

	# note for now it's statkey & statvalue, not name & value
	def test_update_stat
		qry("update_stat(8, $1)", ['{"statkey":"m", "statvalue": "i"}'])
		assert_equal 'm', @j[:name]
		assert_equal 'i', @j[:value]
		qry("update_stat(99, $1)", ['{"statkey":"x"}'])
		assert_equal({}, @j)
		qry("update_stat(8, $1)", ['{"person_id":"boop"}'])
		assert @j[:message].include? 'invalid input syntax'
	end

	def test_get_url
		qry("get_url(2)")
		assert_equal 1, @j[:person_id]
		assert_equal 'http://sivers.org/', @j[:url]
		assert_equal true, @j[:main]
	end

	def test_delete_url
		qry("delete_url(8)")
		assert_equal 'http://oompa.loompa', @j[:url]
		qry("delete_url(8)")
		assert_equal({}, @j)
	end

	def test_update_url
		qry("update_url(8, $1)", ['{"url":"http://oompa.com", "main": true}'])
		assert_equal 'http://oompa.com', @j[:url]
		assert_equal true, @j[:main]
		qry("update_url(99, $1)", ['{"url":"http://oompa.com"}'])
		assert_equal({}, @j)
		qry("update_url(8, $1)", ['{"main":"boop"}'])
		assert @j[:message].include? 'invalid input syntax'
	end

	def test_get_formletters
		qry("get_formletters()")
		assert_equal %w(one five six two four muckcs three), @j.map {|x| x[:title]} # alphabetized
	end

	def test_create_formletter
		qry("create_formletter('nu title')")
		assert_equal 8, @j[:id]
		assert_nil @j[:accesskey]
		assert_nil @j[:body]
		assert_nil @j[:explanation]
		assert_nil @j[:subject]
		assert_equal 'nu title', @j[:title]
	end

	def test_update_formletter
		qry("update_formletter(6, $1)", ['{"title":"nu title", "accesskey":"x", "body":"a body", "explanation":"weak", "ignore":"this"}'])
		assert_equal 'nu title', @j[:title]
		assert_equal 'a body', @j[:body]
		assert_equal 'x', @j[:accesskey]
		assert_equal 'weak', @j[:explanation]
		qry("update_formletter(6, $1)", ['{"title":"one"}'])
		assert_equal '500', @res[0]['status']
		assert @j[:message].include? 'unique constraint'
		qry("update_formletter(99, $1)", ['{"title":"one"}'])
		assert_equal({}, @j)
	end

	def test_delete_formletter
		qry("delete_formletter(6)")
		assert_equal 'meh', @j[:body]
		qry("delete_formletter(6)")
		assert_equal({}, @j)
	end

	def test_parsed_formletter
		qry("parsed_formletter(1, 2)")
		assert @j[:body].start_with? 'Hi Derek'
		qry("parsed_formletter(99, 1)")
		assert_nil @j[:body]
		qry("parsed_formletter(1, 99)")
		assert_nil @j[:body]
	end

	def test_country_names
		qry("country_names()")
		assert_equal 242, @j.size
		assert_equal 'Singapore', @j[:SG]
		assert_equal 'New Zealand', @j[:NZ]
	end

	def test_country_count
		qry("country_count()")
		assert_equal 6, @j.size
		assert_equal({country: 'US', count: 3}, @j[0])
		assert_equal({country: 'CN', count: 1}, @j[1])
	end

	def test_state_count
		qry("state_count('US')")
		assert_equal({state: 'PA', count: 3}, @j[0])
		qry("state_count('IT')")
		assert_equal({}, @j)
	end

	def test_city_count
		qry("city_count('GB')")
		assert_equal({city: 'London', count: 1}, @j[0])
		qry("city_count('US', 'PA')")
		assert_equal({city: 'Hershey', count: 3}, @j[0])
		qry("city_count('US', 'CA')")
		assert_equal({}, @j)
	end

	def test_people_from
		qry("people_from_country('SG')")
		assert_equal 'Derek Sivers', @j[0][:name]
		qry("people_from_state('GB', 'England')")
		assert_equal 'Veruca Salt', @j[0][:name]
		qry("people_from_city('CN', 'Shanghai')")
		assert_equal 'gong@li.cn', @j[0][:email]
		qry("people_from_state_city('US', 'PA', 'Hershey')")
		assert_equal 3, @j.size
		assert_equal [2, 4, 5], @j.map {|x| x[:id]}
	end

	def test_get_stats
		qry("get_stats('listype')")
		assert_equal 'some', @j[0][:value]
		assert_equal 'Willy Wonka', @j[0][:person][:name]
		qry("get_stats('listype', 'all')")
		assert_equal 'all', @j[0][:value]
		assert_equal 'Derek Sivers', @j[0][:person][:name]
		qry("get_stats('nothing')")
		assert_equal [], @j
	end

	def test_get_stat_count
		qry("get_stat_value_count('listype')")
		assert_equal %w(all some), @j.map {|x| x[:value]}
		qry("get_stat_name_count()")
		assert_equal({name: 'listype', count: 2}, @j[1])
	end

	def test_import_email
		nu = {profile: 'sivers', category: 'sivers', message_id: 'abcdefghijk@yep',
			their_email: 'Charlie@BUCKET.ORG', their_name: 'Charles Buckets', subject: 'yip',
			headers: 'To: Derek Sivers <derek@sivers.org>', body: 'hi Derek',
			references: [], attachments: []}
		qry("import_email($1)", [nu.to_json])
		assert_equal 11, @j[:id]
		assert_equal 'charlie@bucket.org', @j[:their_email]
		assert_equal 2, @j[:creator][:id]
		assert_equal 4, @j[:person][:id]
		assert_equal 'sivers', @j[:category]
		assert_nil @j[:reference_id]
		assert_nil @j[:attachments]
	end

	def test_import_email_references
		nu = {profile: 'sivers', category: 'sivers', message_id: 'abcdefghijk@yep',
			their_email: 'wonka@gmail.com', their_name: 'W Wonka', subject: 're: you coming by?',
			headers: 'To: Derek Sivers <derek@sivers.org>', body: 'kthxbai',
			references: ['not@thisone', '20130719234701.2@sivers.org'], attachments: []}
		qry("import_email($1)", [nu.to_json])
		assert_equal 11, @j[:id]
		assert_equal 2, @j[:person][:id]
		assert_equal 3, @j[:reference_id]
		assert_equal 'sivers', @j[:category]
		qry("get_email(1, 3)")
		assert_equal 11, @j[:answer_id]
	end

	def test_import_email_attachments
		atch = []
		atch << {mime_type: 'image/gif', filename: 'cute.gif', bytes: 1234}
		atch << {mime_type: 'audio/mp3', filename: 'fun.mp3', bytes: 123456}
		nu = {profile: 'sivers', category: 'sivers', message_id: 'abcdefghijk@yep',
			their_email: 'Charlie@BUCKET.ORG', their_name: 'Charles Buckets', subject: 'yip',
			headers: 'To: Derek Sivers <derek@sivers.org>', body: 'hi Derek',
			references: [], attachments: atch}
		qry("import_email($1)", [nu.to_json])
		assert_equal 11, @j[:id]
		assert_equal [{id:3,filename:'cute.gif'},{id:4,filename:'fun.mp3'}], @j[:attachments]
	end

	def test_list_updates
		qry("list_update($1, $2, $3)", ['Willy Wonka', 'willy@wonka.com', 'none'])
		qry("get_person(2)")
		assert_equal 'none', @j[:listype]
		assert_equal 'none', @j[:stats][2][:value]
	end

	def test_list_update_create
		qry("list_update($1, $2, $3)", ['New Person', 'new@pers.on', 'all?'])
		qry("get_person(9)")
		assert_equal 'new@pers.on', @j[:email]
		assert_equal 'all', @j[:listype]
		assert_equal 'all', @j[:stats][0][:value]
	end

	def test_list_update_err
		qry("list_update($1, $2, $3)", ['New Person', 'new@pers.on', 'more-than-4-chars'])
		assert @j[:message].include? 'value too long'
	end

	def test_queued_emails
		qry("queued_emails()")
		assert_instance_of Array, @j
		assert_equal 1, @j.size
		assert_equal 4, @j[0][:id]
		assert_equal 're: translations almost done', @j[0][:subject]
		assert_equal 'CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn', @j[0][:referencing]
	end

	def test_email_is_sent
		qry("email_is_sent(4)")
		assert_equal({sent: 4}, @j)
		qry("queued_emails()")
		assert_equal([], @j)
		qry("email_is_sent(99)")
		assert_equal({}, @j)
	end

	def test_sent_emails
		qry("sent_emails(20)")
		assert_instance_of Array, @j
		assert_equal 1, @j.size  # only 1 outgoing in fixtures
		h = {id: 3, 
			subject: 're: you coming by?',
			created_at: '2013-07-20T03:47:01',
			their_name: 'Will Wonka',
			their_email: 'willy@wonka.com'}
		assert_equal(h, @j[0])
	end

	def test_twitter_unfollowed
		qry("twitter_unfollowed()")
		assert_equal([{person_id: 2, twitter: 'wonka'}], @j)
		qry("add_stat(2, 'twitter', '12325 = wonka')")
		qry("twitter_unfollowed()")
		assert_equal [], @j
	end

	def test_dead_email
		qry("dead_email(1)")
		assert_equal({ok: 1}, @j)
		qry("get_person(1)")
		assert_equal "DEAD EMAIL: derek@sivers.org\nThis is me.", @j[:notes]
		qry("dead_email(99)")
		assert_equal({}, @j)
		qry("dead_email(4)")
		assert_equal({ok: 4}, @j)
		qry("get_person(4)")
		assert_equal "DEAD EMAIL: charlie@bucket.org\n", @j[:notes]
	end

	def test_tables_with_person
		qry("tables_with_person(1)")
		assert_equal ['peeps.emailers','peeps.stats','peeps.interests','peeps.urls','peeps.logins'].sort, @j.sort
	end

	def test_ieal_where
		qry("ieal_where('listype', 'all')")
		assert_equal [[1,'derek@sivers.org','Derek','yTAy'],[4,'charlie@bucket.org','Charlie','AgA2']], @j
		qry("ieal_where('listype', 'some')")
		assert_equal [[2,'willy@wonka.com','Mr. Wonka','R5Gf'],[6,'augustus@gloop.de','Master Gloop','AKyv']], @j
		qry("ieal_where('country', 'US')")
		assert_equal [[2,'willy@wonka.com','Mr. Wonka','R5Gf'],[4,'charlie@bucket.org','Charlie','AgA2'],[5,'oompa@loompa.mm','Oompa Loompa','LYtp']], @j
		qry("ieal_where('country', 'XX')")
		assert_equal [], @j
	end

	def test_all_countries
		qry("all_countries()")
		assert_equal 242, @j.size
		assert_equal({code: 'AF', name: 'Afghanistan'}, @j[0])
		assert_equal({code: 'ZW', name: 'Zimbabwe'}, @j[240])
	end

	def test_send_person_formletter
		qry("send_person_formletter(1, 2, 'sivers')")
		assert_equal 11, @j[:id]
		assert_equal 'sivers', @j[:profile]
		assert_equal 'sivers', @j[:category]
		assert_equal 2, @j[:creator][:id]
		assert_equal 2, @j[:closor][:id]
		assert_nil @j[:outgoing]
		assert_equal 'Derek thanks address', @j[:subject]
		assert @j[:body].start_with? 'Hi Derek'
	end

	def test_reset_email_nu
		qry("reset_email(1, 'not@here.net')")
		assert_equal({}, @j)
	end

	def test_reset_email_reset
		qry("reset_email(1, 'yoko@ono.com')")
		assert_equal 11, @j[:id]
		assert_nil @j[:outgoing]
		assert @j[:body].include? 'Your email is yoko@ono.com'
		assert_match %r{data.sivers.org/newpass/8/[a-zA-Z0-9]{8}\s}, @j[:body]
	end

	def test_person_attributes
		qry("person_attributes(6)")
		assert_equal([
			{atkey: 'available', plusminus: true},
			{atkey: 'patient', plusminus: nil},
			{atkey: 'verbose', plusminus: false}], @j)
		qry("person_attributes(999)")
		assert_equal([
			{atkey: 'available', plusminus: nil},
			{atkey: 'patient', plusminus: nil},
			{atkey: 'verbose', plusminus: nil}], @j)
	end

	def test_person_interests
		qry("person_interests(7)")
		assert_equal([
			{interest: 'mandarin', expert: true},
			{interest: 'translation', expert: true}], @j)
		qry("person_interests(99)")
		assert_equal([], @j)
	end

	def test_person_set_attribute
		qry("person_set_attribute($1,$2,$3)", [1, 'patient', true])
		assert_equal([
			{atkey: 'available', plusminus: nil},
			{atkey: 'patient', plusminus: true},
			{atkey: 'verbose', plusminus: nil}], @j)
		qry("person_set_attribute($1,$2,$3)", [1, 'available', true])
		assert_equal([
			{atkey: 'available', plusminus: true},
			{atkey: 'patient', plusminus: true},
			{atkey: 'verbose', plusminus: nil}], @j)
		qry("person_set_attribute($1,$2,$3)", [1, 'available', false])
		assert_equal([
			{atkey: 'available', plusminus: false},
			{atkey: 'patient', plusminus: true},
			{atkey: 'verbose', plusminus: nil}], @j)
		qry("person_set_attribute($1,$2,$3)", [1, 'wrong', false])
		assert @j[:message].include? 'constraint'
		qry("person_set_attribute($1,$2,$3)", [99, 'patient', false])
		assert @j[:message].include? 'constraint'
		qry("person_set_attribute($1,$2,$3)", [1, 'patient', nil])
		assert @j[:message].include? 'constraint'
	end

	def test_person_delete_attribute
		qry("person_delete_attribute($1,$2)", [6, 'patient'])
		assert_equal([
			{atkey: 'available', plusminus: true},
			{atkey: 'patient', plusminus: nil},
			{atkey: 'verbose', plusminus: false}], @j)
		qry("person_delete_attribute($1,$2)", [6, 'available'])
		assert_equal([
			{atkey: 'available', plusminus: nil},
			{atkey: 'patient', plusminus: nil},
			{atkey: 'verbose', plusminus: false}], @j)
		qry("person_delete_attribute($1,$2)", [6, 'wrong'])
		assert_equal([
			{atkey: 'available', plusminus: nil},
			{atkey: 'patient', plusminus: nil},
			{atkey: 'verbose', plusminus: false}], @j)
		qry("person_delete_attribute($1,$2)", [99, 'wrong'])
		assert_equal([
			{atkey: 'available', plusminus: nil},
			{atkey: 'patient', plusminus: nil},
			{atkey: 'verbose', plusminus: nil}], @j)
	end

	def test_person_add_interest
		qry("person_add_interest($1, $2)", [4, 'mandarin'])
		assert_equal([
			{interest: 'mandarin', expert: nil}], @j)
		qry("person_add_interest($1, $2)", [4, 'mandarin'])
		assert_equal([
			{interest: 'mandarin', expert: nil}], @j)
		qry("person_add_interest($1, $2)", [4, 'chocolate'])
		assert_equal([
			{interest: 'chocolate', expert: nil},
			{interest: 'mandarin', expert: nil}], @j)
		qry("person_add_interest($1, $2)", [4, 'wrong'])
		assert @j[:message].include? 'constraint'
		qry("person_add_interest($1, $2)", [99, 'chocolate'])
		assert @j[:message].include? 'constraint'
	end

	def test_person_update_interest
		qry("person_update_interest($1,$2,$3)", [7, 'chocolate', true])
		assert_equal([
			{interest: 'mandarin', expert: true},
			{interest: 'translation', expert: true}], @j)
		qry("person_update_interest($1,$2,$3)", [7, 'mandarin', false])
		assert_equal([
			{interest: 'translation', expert: true},
			{interest: 'mandarin', expert: false}], @j)
		qry("person_update_interest($1,$2,$3)", [7, 'wrong', true])
		assert_equal([
			{interest: 'translation', expert: true},
			{interest: 'mandarin', expert: false}], @j)
		qry("person_update_interest($1,$2,$3)", [99, 'mandarin', false])
		assert_equal([], @j)
	end

	def test_person_delete_interest
		qry("person_delete_interest($1, $2)", [7, 'wrong'])
		assert_equal([
			{interest: 'mandarin', expert: true},
			{interest: 'translation', expert: true}], @j)
		qry("person_delete_interest($1, $2)", [7, 'mandarin'])
		assert_equal([
			{interest: 'translation', expert: true}], @j)
		qry("person_delete_interest($1, $2)", [7, 'translation'])
		assert_equal([], @j)
		qry("person_delete_interest($1, $2)", [99, 'translation'])
		assert_equal([], @j)
	end

	def test_attribute_keys
		qry("attribute_keys()")
		k = [{atkey: 'available', description: 'free to work or do new things'}, {atkey: 'patient', description: 'does not need it now'}, {atkey: 'verbose', description: 'uses lots of words to communicate'}]
		assert_equal k, @j
	end

	def test_add_attribute_key
		qry("add_attribute_key($1)", [' . ? ! '])
		assert @j[:message].include? 'empty'
		qry("add_attribute_key($1)", ['patient'])
		assert @j[:message].include? 'constraint'
		qry("add_attribute_key($1)", [" \r GORGEOUS! \n"])
		k = [{atkey: 'available', description: 'free to work or do new things'}, {atkey: 'gorgeous', description: nil}, {atkey: 'patient', description: 'does not need it now'}, {atkey: 'verbose', description: 'uses lots of words to communicate'}]
		assert_equal k, @j
	end

	def test_delete_attribute_key
		k1 = [{atkey: 'available', description: 'free to work or do new things'}, {atkey: 'patient', description: 'does not need it now'}, {atkey: 'verbose', description: 'uses lots of words to communicate'}]
		k2 = [{atkey: 'available', description: 'free to work or do new things'}, {atkey: 'patient', description: 'does not need it now'}, {atkey: 'verbose', description: 'uses lots of words to communicate'}, {atkey: 'wrong', description: nil}]
		qry("delete_attribute_key($1)", ['whatever'])
		assert_equal k1, @j
		qry("add_attribute_key($1)", ['wrong'])
		assert_equal k2, @j
		qry("delete_attribute_key($1)", ['wrong'])
		assert_equal k1, @j
		qry("delete_attribute_key($1)", ['patient'])
		assert @j[:message].include? 'constraint'
	end

	def test_update_attribute_key
		qry("update_attribute_key($1, $2)", ['patient', 'can wait'])
		k = [{atkey: 'available', description: 'free to work or do new things'}, {atkey: 'patient', description: 'can wait'}, {atkey: 'verbose', description: 'uses lots of words to communicate'}]
		assert_equal k, @j
		qry("update_attribute_key($1, $2)", ['dogfood', 'can eat'])
		assert_equal k, @j
	end

	def test_interest_keys
		qry("interest_keys()")
		k = [{inkey: 'chocolate', description: 'some make it. many eat it.'}, {inkey: 'lanterns', description: 'use for testing email body parsing email 2 person 7'}, {inkey: 'mandarin', description: 'speaks/writes Mandarin Chinese'}, {inkey: 'translation', description: 'does translation from English to another language'}]
		assert_equal k, @j
	end

	def test_add_interest_key
		qry("add_interest_key($1)", [' . ? ! '])
		assert @j[:message].include? 'empty'
		qry("add_interest_key($1)", ['chocolate'])
		assert @j[:message].include? 'constraint'
		qry("add_interest_key($1)", ['Java? Script!'])
		k = [{inkey: 'chocolate', description: 'some make it. many eat it.'}, {inkey: 'javascript', description: nil}, {inkey: 'lanterns', description: 'use for testing email body parsing email 2 person 7'}, {inkey: 'mandarin', description: 'speaks/writes Mandarin Chinese'}, {inkey: 'translation', description: 'does translation from English to another language'}]
		assert_equal k, @j
	end

	def test_delete_interest_key
		qry("delete_interest_key($1)", ['lanterns'])
		k = [{inkey: 'chocolate', description: 'some make it. many eat it.'}, {inkey: 'mandarin', description: 'speaks/writes Mandarin Chinese'}, {inkey: 'translation', description: 'does translation from English to another language'}]
		assert_equal k, @j
		qry("delete_interest_key($1)", ['lanterns'])
		assert_equal k, @j
		qry("delete_interest_key($1)", ['chocolate'])
		assert @j[:message].include? 'constraint'
	end

	def test_update_interest_key
		qry("update_interest_key($1, $2)", ['translation', 'wow'])
		k = [{inkey: 'chocolate', description: 'some make it. many eat it.'}, {inkey: 'lanterns', description: 'use for testing email body parsing email 2 person 7'}, {inkey: 'mandarin', description: 'speaks/writes Mandarin Chinese'}, {inkey: 'translation', description: 'wow'}]
		assert_equal k, @j
		qry("update_interest_key($1, $2)", ['chocolate', 'yum'])
		k = [{inkey: 'chocolate', description: 'yum'}, {inkey: 'lanterns', description: 'use for testing email body parsing email 2 person 7'}, {inkey: 'mandarin', description: 'speaks/writes Mandarin Chinese'}, {inkey: 'translation', description: 'wow'}]
		assert_equal k, @j
	end

	def test_interests_in_email
		qry("interests_in_email(2)")
		assert_equal(%w(lanterns), @j)
		qry("person_delete_interest($1, $2)", [7, 'translation'])
		qry("interests_in_email(2)")
		assert_equal(%w(lanterns translation).sort, @j.sort)
		qry("interests_in_email(1)")
		assert_equal([], @j)
		qry("interests_in_email(99)")
		assert_equal([], @j)
	end

	def test_people_with_interest
		qry("people_with_interest('goo', NULL)")
		assert_equal '404', @res[0]['status']
		qry("people_with_interest('lanterns', NULL)")
		assert_equal([], @j)
		qry("people_with_interest('mandarin', NULL)")
		assert_equal([{id:7,name:'巩俐',email:'gong@li.cn',email_count:2},{id:1,name:'Derek Sivers',email:'derek@sivers.org',email_count:0}], @j)
		qry("people_with_interest('mandarin', true)")
		assert_equal([{id:7,name:'巩俐',email:'gong@li.cn',email_count:2}], @j)
		qry("people_with_interest('mandarin', false)")
		assert_equal([{id:1,name:'Derek Sivers',email:'derek@sivers.org',email_count:0}], @j)
	end

	def test_people_with_attribute
		qry("people_with_attribute('patient', NULL)")
		assert_equal '404', @res[0]['status']
		qry("people_with_attribute('goo', true)")
		assert_equal '404', @res[0]['status']
		qry("people_with_attribute('verbose', true)")
		assert_equal([], @j)
		qry("people_with_attribute('verbose', false)")
		assert_equal([{id:3,name:'Veruca Salt',email:'veruca@salt.com',email_count:4},{id:6,name:'Augustus Gloop',email:'augustus@gloop.de',email_count:0}], @j)
	end

	def test_add_tweet_wonka
		js = '{"id": 659144551454498816, "geo": null, "lang": "en", "text": "I am jumping on the @sivers “Now Page” bandwagon: https://t.co/clKe9GeQnm With a @simonsinek twist to it", "user": {"id": 16725749, "url": "http://t.co/737x6qTfDe", "lang": "en", "name": "Willy Wonka", "id_str": "16725749", "entities": {"url": {"urls": [{"url": "http://t.co/737x6qTfDe", "indices": [0, 22], "display_url": "wonka.com", "expanded_url": "http://wonka.com/"}]}, "description": {"urls": []}}, "location": "Indianapolis, IN", "verified": false, "following": false, "protected": false, "time_zone": "Eastern Time (US & Canada)", "created_at": "Mon Oct 13 19:22:22 +0000 2008", "utc_offset": -14400, "description": "Testing Willy Wonka", "geo_enabled": true, "screen_name": "wonka", "listed_count": 20, "friends_count": 308, "is_translator": false, "notifications": false, "statuses_count": 2184, "default_profile": false, "followers_count": 458, "favourites_count": 1015, "profile_image_url": "http://pbs.twimg.com/profile_images/461357535094534144/fqa7fyp7_normal.jpeg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/16725749/1434601499", "profile_link_color": "2FC2EF", "profile_text_color": "666666", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": true, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": false, "profile_image_url_https": "https://pbs.twimg.com/profile_images/461357535094534144/fqa7fyp7_normal.jpeg", "profile_background_color": "000000", "profile_sidebar_fill_color": "252429", "profile_background_image_url": "http://pbs.twimg.com/profile_background_images/3440643/TwitterLogo2.gif", "profile_sidebar_border_color": "181A1E", "profile_use_background_image": true, "profile_background_image_url_https": "https://pbs.twimg.com/profile_background_images/3440643/TwitterLogo2.gif"}, "place": null, "id_str": "659144551454498816", "source": "<a href=\"https://about.twitter.com/products/tweetdeck\" rel=\"nofollow\">TweetDeck</a>", "entities": {"urls": [{"url": "https://t.co/clKe9GeQnm", "indices": [50, 73], "display_url": "wonka.com/now", "expanded_url": "http://wonka.com/now"}], "symbols": [], "hashtags": [], "user_mentions": [{"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [20, 27], "screen_name": "sivers"}, {"id": 15970050, "name": "Simon Sinek", "id_str": "15970050", "indices": [82, 93], "screen_name": "simonsinek"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Tue Oct 27 23:08:02 +0000 2015", "coordinates": null, "contributors": null, "retweet_count": 0, "favorite_count": 3, "is_quote_status": false, "possibly_sensitive": false, "in_reply_to_user_id": null, "in_reply_to_status_id": null, "in_reply_to_screen_name": null, "in_reply_to_user_id_str": null, "in_reply_to_status_id_str": null}'
		qry('peeps.add_tweet($1)', [js])
		qry('peeps.get_tweet($1)', [@j[:id]])
		assert_equal 659144551454498816, @j[:id]
		assert_equal 'I am jumping on the @sivers “Now Page” bandwagon: http://wonka.com/now With a @simonsinek twist to it', @j[:message]
		assert_equal 'wonka', @j[:handle]
		assert_equal 2, @j[:person_id]
		assert @j[:created_at].start_with? '2015-10-2'
		assert_nil @j[:seen]
		assert_nil @j[:reference_id]
	end

	def test_add_tweet_dobalina
		js = '{"id": 659196999443591168, "geo": null, "lang": "en", "text": "H/T to @tomcritchlow and @sivers for inspiration on the /now page :) https://t.co/E5dYdzU8Zz", "user": {"id": 15140557, "url": "https://t.co/9Y72rhUoW7", "lang": "en", "name": "Bob Dobalina", "id_str": "15140557", "entities": {"url": {"urls": [{"url": "https://t.co/9Y72rhUoW7", "indices": [0, 23], "display_url": "dobalina.com", "expanded_url": "http://dobalina.com/"}]}, "description": {"urls": []}}, "location": "NYC ", "verified": false, "following": false, "protected": false, "time_zone": "Eastern Time (US & Canada)", "created_at": "Tue Jun 17 00:50:35 +0000 2008", "utc_offset": -14400, "description": "Bob Dobalina description here", "geo_enabled": true, "screen_name": "MistaDobalina", "listed_count": 70, "friends_count": 815, "is_translator": false, "notifications": false, "statuses_count": 4673, "default_profile": false, "followers_count": 602, "favourites_count": 3423, "profile_image_url": "http://pbs.twimg.com/profile_images/622871742831116289/zM7tTguR_normal.jpg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/15140557/1408724422", "profile_link_color": "0A8080", "profile_text_color": "634047", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": false, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": false, "profile_image_url_https": "https://pbs.twimg.com/profile_images/622871742831116289/zM7tTguR_normal.jpg", "profile_background_color": "EDECE9", "profile_sidebar_fill_color": "E3E2DE", "profile_background_image_url": "http://abs.twimg.com/images/themes/theme3/bg.gif", "profile_sidebar_border_color": "D3D2CF", "profile_use_background_image": true, "profile_background_image_url_https": "https://abs.twimg.com/images/themes/theme3/bg.gif"}, "place": {"id": "01a9a39529b27f36", "url": "https://api.twitter.com/1.1/geo/id/01a9a39529b27f36.json", "name": "Manhattan", "country": "United States", "full_name": "Manhattan, NY", "attributes": {}, "place_type": "city", "bounding_box": {"type": "Polygon", "coordinates": [[[-74.026675, 40.683935], [-73.910408, 40.683935], [-73.910408, 40.877483], [-74.026675, 40.877483]]]}, "country_code": "US", "contained_within": []}, "id_str": "659196999443591168", "source": "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>", "entities": {"urls": [{"url": "https://t.co/E5dYdzU8Zz", "indices": [70, 93], "display_url": "dobalina.com/now/", "expanded_url": "http://www.dobalina.com/now/"}], "symbols": [], "hashtags": [], "user_mentions": [{"id": 6419982, "name": "Tom Critchlow", "id_str": "6419982", "indices": [7, 20], "screen_name": "tomcritchlow"}, {"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [25, 32], "screen_name": "sivers"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Wed Oct 28 02:36:26 +0000 2015", "coordinates": null, "contributors": null, "retweet_count": 0, "favorite_count": 1, "is_quote_status": false, "possibly_sensitive": false, "in_reply_to_user_id": 15140557, "in_reply_to_status_id": 659196273707327488, "in_reply_to_screen_name": "MistaDobalina", "in_reply_to_user_id_str": "15140557", "in_reply_to_status_id_str": "659196273707327488"}'
		qry('peeps.add_tweet($1)', [js])
		assert_equal 659196999443591168, @j[:id]
		qry('peeps.add_tweet($1)', [js])
		assert_equal 659196999443591168, @j[:id]
		qry('peeps.get_tweet($1)', [@j[:id]])
		assert_equal 'H/T to @tomcritchlow and @sivers for inspiration on the /now page :) http://www.dobalina.com/now/', @j[:message]
		assert_equal 'MistaDobalina', @j[:handle]
		assert_nil @j[:person_id]
		assert @j[:created_at].start_with? '2015-10-2'
		assert_nil @j[:seen]
		assert_equal 659196273707327488, @j[:reference_id]
	end

	def test_tweets_by_person
		qry("peeps.tweets_by_person(2)")
		assert_equal @j, [{id:58297459929088,created_at:"2016-08-18T11:45:05",message:"hey @sivers",reference_id:nil}]
		qry("peeps.tweets_by_person(3)")
		assert_equal @j, []
		qry("peeps.tweets_by_person(999)")
		assert_equal @j, []
	end

	def test_get_tweet
		qry("peeps.get_tweet(13562397593600)")
		t = {id: 13562397593600,
			created_at: "2016-08-18T08:47:19",
			person_id: nil,
			handle: "Cat",
			message: "@Claire @_xx can't use that phrase and not bring out this gem! https://youtu.be/fW8amMCVAJQ #firstfollower via @sivers",
			reference_id: nil,
			seen: nil}
		assert_equal t, @j
		qry("peeps.get_tweet(999)")
		assert_equal({}, @j)
		assert_equal '404', @res[0]['status']
	end

	def test_tweets_unseen
		qry("peeps.tweets_unseen(2)")
		r = [{id: 63322672267265,
			name: 'Mind the #Quote',
			handle: 'salt',
			message: "In the end, it's about what you want to be, not what you want to have. -  @sivers #quote",
			person_id: nil},
		{id: 58297459929088,
			name: 'Willy Wonka',
			handle: 'wonka',
			message: 'hey @sivers',
			person_id: 2}]
		assert_equal r, @j
		qry("peeps.tweet_seen(63322672267265)")
		qry("peeps.tweets_unseen(2)")
		r = [{id: 58297459929088,
			name: 'Willy Wonka',
			handle: 'wonka',
			message: 'hey @sivers',
			person_id: 2},
		{id: 40583764836353,
			name: 'J Buckets',
			handle: 'JBuckets3',
			message: '@Cat @Claire @_xx @sivers @YouTube love this',
			person_id: nil}]
		assert_equal r, @j
	end

	def test_tweet_seen
		qry("peeps.tweet_seen(13562397593600)")
		# might use this, might not, currently not. keep it here
		r = {id: 13562397593600,
			created_at: "2016-08-18T08:47:19",
			person_id: nil,
			handle: "Cat",
			message: "@Claire @_xx can't use that phrase and not bring out this gem! https://youtu.be/fW8amMCVAJQ #firstfollower via @sivers",
			reference_id: nil,
			seen: true}
		assert_equal({}, @j)
	end

	def test_tweets_handle_person
		qry("peeps.tweets_handle_person('salt', 3)")
		r = [{id: 63322672267265,
			message: "In the end, it's about what you want to be, not what you want to have. -  @sivers #quote",
			created_at: "2016-08-18T12:05:03",
			reference_id: nil}]
		assert_equal r, @j
	end

	def test_tweets_unknown_new
		qry("peeps.tweets_unknown_new(2)")
		r = [{name:'Mind the #Quote', handle:'salt'}, {name:'J Buckets', handle:'JBuckets3'}]
		assert_equal r, @j
	end

	def test_tweets_unknown_top
		qry("peeps.tweets_unknown_top(2)")
		r = [{name:'Mind the #Quote', handle:'salt'}, {name:'J Buckets', handle:'JBuckets3'}]
		assert_equal r, @j
	end
end

