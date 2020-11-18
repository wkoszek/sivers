require '../test_tools.rb'

class WordsAPITest < Minitest::Test
	include JDB

	def test_get_translator
		qry('words.get_translator(1)')
		assert_equal 1, @j[:id]
		assert_equal 7, @j[:person_id]
		assert_equal 'zh', @j[:lang]
		assert_equal '巩俐', @j[:name]
		assert_equal 'gong@li.cn', @j[:email]
		assert_equal '巩俐', @j[:address]
		assert_equal 'Gong Li', @j[:company]
		assert_equal 'Shanghai', @j[:city]
		assert_nil @j[:state]
		assert_equal 'CN', @j[:country]
		assert_nil @j[:phone]
	end

	def test_unfinished_articles
		qry('words.unfinished_articles($1)', ['fr'])
		assert_equal @j, [{id:2, filename:'unfinished'}]
		qry('words.unfinished_articles($1)', ['zh'])
		assert_equal @j, []
	end

	def test_finished_articles
		qry('words.finished_articles($1)', ['fr'])
		assert_equal @j, [{id:1, filename:'finished'}]
		qry('words.finished_articles($1)', ['zh'])
		assert_equal @j, [{id:1, filename:'finished'},{id:2, filename:'unfinished'}]
	end

	def test_get_article_lang
		qry('words.get_article_lang($1, $2)', [1, 'fr'])
		# response comes back as one big hash, but testing individual keys here:
		assert_equal 1, @j[:id]
		assert_equal 'finished', @j[:filename]
		assert_equal '<!-- {aaaaaaaa} -->
<p>
	{aaaaaaab}
	{aaaaaaac}
	{aaaaaaad}
</p>', @j[:template]
		assert_equal '<!-- headline here -->
<p>
	Some <strong>bold words</strong>.
	Now <a href="/">linked and <em>italic</em> words</a>.
	See <a href="/about">about</a> <a href="/">this</a>?
</p>', @j[:raw]
		assert_equal '<!-- titre ici -->
<p>
	quelques <strong>mots en gras</strong>
	maintenant <a href="/">liés et mots <em>italiques</em></a>
	voir <a href="/about">à ce</a> <a href="/">sujet</a>
</p>', @j[:merged]
		assert_equal({sortid:1,
			code: 'aaaaaaaa',
			replacements: [],
			raw: 'titre ici',
			merged: 'titre ici'},
			@j[:sentences][0])
		assert_equal({sortid:2,
			code: 'aaaaaaab',
			replacements: ['<strong>','</strong>'],
			raw: 'quelques <mots en gras>',
			merged: 'quelques <strong>mots en gras</strong>'},
			@j[:sentences][1])
		assert_equal({sortid:3,
			code: 'aaaaaaac',
			replacements: ['<a href="/">', '<em>', '</em>', '</a>'],
			raw: 'maintenant <liés et mots <italiques>>',
			merged: 'maintenant <a href="/">liés et mots <em>italiques</em></a>'},
			@j[:sentences][2])
		assert_equal({sortid:4,
			code: 'aaaaaaad',
			replacements: ['<a href="/about">', '</a>', '<a href="/">', '</a>'],
			raw: 'voir <à ce> <sujet>',
			merged: 'voir <a href="/about">à ce</a> <a href="/">sujet</a>'},
			@j[:sentences][3])
	end

	def test_get_sentence_lang
		qry('words.get_sentence_lang($1, $2)', ['aaaaaaab', 'zh'])
		assert_equal 8, @j[:id]
		assert_equal '一些大<胆的话>', @j[:translation]
		assert_equal 'zh', @j[:lang]
		assert_equal 'aaaaaaab', @j[:code]
		assert_equal 1, @j[:article_id]
		assert_equal 2, @j[:sortid]
		assert_equal %w(<strong> </strong>), @j[:replacements]
		assert_equal 'Some <bold words>.', @j[:sentence]
		assert_equal '一些大<strong>胆的话</strong>', @j[:merged]
	end

	def test_next_sentence_for_article_lang
		qry('words.next_sentence_for_article_lang($1, $2)', [2, 'es'])
		assert_equal 22, @j[:id]
		assert_equal 'not done yet', @j[:sentence]
		qry('words.next_sentence_for_article_lang($1, $2)', [2, 'zh'])
		assert_equal({}, @j)  # none = done
	end

	def test_get_translation
		qry('words.get_translation(8)')
		assert_equal({id: 8, sentence_code: 'aaaaaaab', lang: 'zh', translation: '一些大<胆的话>'}, @j)
	end

	def test_update_translation
		qry('words.update_translation($1, $2)', [8, '<你好>'])
		assert_equal({id: 8, sentence_code: 'aaaaaaab', lang: 'zh', translation: '<你好>'}, @j)
	end
end
