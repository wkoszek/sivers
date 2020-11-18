require '../test_tools.rb'

class WordsTest < Minitest::Test
	include JDB

	def setup
		@raw = "<!-- This is a title -->\r\n<p>\r\n\tAnd this?\r\n\tThis is a translation.\r\n</p>"
		@lines = ['This is a title', 'And this?', 'This is a translation.']
		@fr = ['Ceci est un titre', 'Et ça?', 'Ceci est une phrase.']
		super
	end

	def test_code
		res = DB.exec("INSERT INTO words.sentences (sentence) VALUES ('hello') RETURNING code")
		hellocode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hellocode
		res = DB.exec("INSERT INTO words.sentences (sentence) VALUES ('hi') RETURNING code")
		hicode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hicode
		res = DB.exec("SELECT sentence FROM words.sentences WHERE code = '%s'" % hellocode)
		assert_equal 'hello', res[0]['sentence']
		res = DB.exec("SELECT sentence FROM words.sentences WHERE code = '%s'" % hicode)
		assert_equal 'hi', res[0]['sentence']
	end

	def test_parse_article
		DB.exec_params("INSERT INTO words.articles(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM words.parse_article(3)")
		res = DB.exec("SELECT * FROM words.sentences WHERE article_id = 3")
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal '1', res[0]['sortid']
		assert_equal @lines[0], res[0]['sentence']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal '2', res[1]['sortid']
		assert_equal @lines[1], res[1]['sentence']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal '3', res[2]['sortid']
		assert_equal @lines[2], res[2]['sentence']
		res = DB.exec("SELECT template FROM words.articles WHERE id = 3")
		assert_match /<!-- \{[A-Za-z0-9]{8}\} -->\n<p>\n\{[A-Za-z0-9]{8}\}\n\{[A-Za-z0-9]{8}\}\n<\/p>/, res[0]['template']
	end

	def test_tags_match_replacements
		# no test for this now, because I'm not using it yet.
		# see comment above function definition
	end

	def test_merge_replacements
		res = DB.exec("SELECT merged FROM words.merge_replacements('oh, <ok>!', ARRAY['<b>','</b>'])")
		assert_equal 'oh, <b>ok</b>!', res[0]['merged']
		# if more tags than replacements, replaces with empty:
		res = DB.exec("SELECT merged FROM words.merge_replacements('oh, <ok>!', '{}')")
		assert_equal 'oh, ok!', res[0]['merged']
		# if more replacements than tags, adds them to end! (should never happen)
		res = DB.exec("SELECT merged FROM words.merge_replacements('oh, <ok>!', ARRAY['<b>','</b>','<i>','</i>'])")
		assert_equal 'oh, <b>ok</b>!<i></i>', res[0]['merged']
	end

	def test_merge_article
		res = DB.exec("SELECT merged FROM words.merge_article(1, 'fr')")
		assert_equal res[0]['merged'], '<!-- titre ici -->
<p>
	quelques <strong>mots en gras</strong>
	maintenant <a href="/">liés et mots <em>italiques</em></a>
	voir <a href="/about">à ce</a> <a href="/">sujet</a>
</p>'
		# English merged should be same as raw
		res = DB.exec("SELECT raw FROM words.articles WHERE id=1")
		raw = res[0]['raw']
		res = DB.exec("SELECT merged FROM words.merge_article(1, 'en')")
		merged = res[0]['merged']
		assert_equal raw, merged
	end
end
