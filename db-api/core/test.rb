require '../test_tools.rb'

class CoreTest < Minitest::Test
	include JDB

	def setup
		@raw = "<!-- This is a title -->\r\n<p>\r\n\tAnd this?\r\n\tThis is a translation.\r\n</p>"
		@lines = ['This is a title', 'And this?', 'This is a translation.']
		@fr = ['Ceci est un titre', 'Et ça?', 'Ceci est une phrase.']
		super
	end

	def test_strip_tags
		res = DB.exec_params("SELECT core.strip_tags($1)", ['þ <script>alert("poop")</script> <a href="http://something.net">yuck</a>'])
		assert_equal 'þ alert("poop") yuck', res[0]['strip_tags']
	end

	def test_escape_html
		res = DB.exec_params("SELECT core.escape_html($1)", [%q{I'd "like" <&>}])
		assert_equal 'I&#39;d &quot;like&quot; &lt;&amp;&gt;', res[0]['escape_html']
	end

	def test_currency_from_to
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'USD', 'EUR')")
		assert (881..882).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'EUR', 'USD')")
		assert (1135..1136).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'JPY', 'EUR')")
		assert (7..8).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'EUR', 'BTC')")
		assert (4..5).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(9, 'BTC', 'JPY')")
		assert (248635..248636).cover? res[0]['amount'].to_f 
	end
	
	def test_money_to
		res = DB.exec("SELECT * FROM core.money_to(('USD',1000), 'EUR')")
		assert (881..882).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.money_to(('EUR',1000), 'USD')")
		assert (1135..1136).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.money_to(('JPY',1000), 'EUR')")
		assert (7..8).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.money_to(('EUR',1000), 'BTC')")
		assert (4..5).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.money_to(('BTC',9), 'JPY')")
		assert (248635..248636).cover? res[0]['amount'].to_f 
	end

	def test_add_money
		res = DB.exec("SELECT * FROM core.add_money(('USD', 10), ('EUR', 10))")
		assert_equal 'USD', res[0]['currency']
		assert (21..22).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.add_money(('EUR', 10), ('USD', 10))")
		assert_equal 'EUR', res[0]['currency']
		assert (18..19).cover? res[0]['amount'].to_f 
	end

	def test_subtract_money
		res = DB.exec("SELECT * FROM core.subtract_money(('USD', 20), ('EUR', 10))")
		assert_equal 'USD', res[0]['currency']
		assert (8..9).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.subtract_money(('EUR', 20), ('USD', 10))")
		assert_equal 'EUR', res[0]['currency']
		assert (11..12).cover? res[0]['amount'].to_f 
	end

	def test_multiply_money
		res = DB.exec("SELECT * FROM core.multiply_money(('USD', 20), 0.456789)")
		assert_equal 'USD', res[0]['currency']
		assert_equal 9.13578, res[0]['amount'].to_f
		res = DB.exec("SELECT * FROM core.multiply_money(('EUR', 20), 1.55)")
		assert_equal 'EUR', res[0]['currency']
		assert_equal 31, res[0]['amount'].to_f
	end

	def test_all_currencies
		qry("core.all_currencies()")
		assert_equal 34, @j.size
		assert_equal({code: 'AUD', name: 'Australian Dollar'}, @j[0])
		assert_equal({code: 'ZAR', name: 'South African Rand'}, @j[33])
	end

	def test_currency_names
		qry("core.currency_names()")
		assert_equal 34, @j.size
		assert_equal 'Singapore Dollar', @j[:SGD]
		assert_equal 'Euro', @j[:EUR]
	end

	def test_changelog_nodupe
		DB.exec("INSERT INTO core.changelog(person_id, schema_name, table_name, table_id) VALUES (1, 'now', 'urls', 1)")
		res = DB.exec("SELECT * FROM core.changelog WHERE person_id=1")
		assert_equal 1, res.ntuples
		assert_equal '1', res[0]['id']
		DB.exec("INSERT INTO core.changelog(person_id, schema_name, table_name, table_id) VALUES (1, 'now', 'urls', 1)")
		res = DB.exec("SELECT * FROM core.changelog WHERE person_id=1")
		assert_equal 1, res.ntuples
		DB.exec("UPDATE core.changelog SET approved=TRUE WHERE id=1")
		DB.exec("INSERT INTO core.changelog(person_id, schema_name, table_name, table_id) VALUES (1, 'now', 'urls', 1)")
		res = DB.exec("SELECT * FROM core.changelog WHERE person_id=1")
		assert_equal 2, res.ntuples
	end

end
