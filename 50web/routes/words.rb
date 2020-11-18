LIVETEST = 'test'
LOG = 'words'
require_relative 'bureau'
WDB = getdb('words', LIVETEST)

class Words < Bureau

	configure do
		set :views, '/var/www/htdocs/50web/views/words'
	end

	before do
		if authorize!
			ok, @translator = WDB.call('get_translator', @auth_id)
		end
	end

	get '/' do
		@pagetitle = @person[:name]
		ok, @unfinished = WDB.call('unfinished_articles', @translator[:lang])
		ok, @finished = WDB.call('finished_articles', @translator[:lang])
		erb :home
	end

	get %r{\A/article/([0-9]+)/([a-z]{2})\Z} do |id, lang|
		ok, @article = WDB.call('get_article_lang', id, lang)
		sorry 'notfound' unless ok
		@pagetitle = "article #{id}"
		erb :article
	end

	get %r{\A/sentence/([a-zA-Z0-9]{8})/([a-z]{2})\Z} do |code, lang|
		ok, @sentence = WDB.call('get_sentence_lang', code, lang)
		sorry 'notfound' unless ok
		@article_url = '/article/%s/%s' % [@sentence[:article_id], @translator[:lang]]
		@post_url = '/translation/%d' % [@sentence[:id]]
		@pagetitle = "sentence #{code}"
		erb :sentence
	end

	post %r{\A/translation/([0-9]+)\Z} do |id|
		ok, trn = WDB.call('get_translation', id)
		sorry 'notfound' unless ok
		next_url = '/sentence/%s/%s' % [trn[:sentence_code], trn[:lang]]
		sorry 'missing' unless String(params[:translation]).size > 0
		ok, _ = WDB.call('update_translation', id, params[:translation])
		sorry 'update' unless ok
		redirect to(next_url)
	end
end
__END__
Words API:
WDB.call('get_translator', integer)
WDB.call('unfinished_articles',char(2))
WDB.call('finished_articles', char(2))
WDB.call('get_article_lang', integer, char(2))
WDB.call('get_sentence_lang', char(8), char(2))
WDB.call('next_sentence_for_article_lang', integer, char(2))
WDB.call('get_translation', integer)
WDB.call('update_translation', integer, text)

