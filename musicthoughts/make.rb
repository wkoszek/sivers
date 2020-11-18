require 'erb'
require 'getdb'
db = getdb('musicthoughts')

def template(name)
	ERB.new(File.read("templates/#{name}.erb"), nil, '-').result
end

def thought1(thought)
	@thought1 = thought
	template('_thought')
end

def page(name)
	@bodyid = name
	@rand_id = rand_from(@random_thoughts)[:id]
	@rand_footer = thought1(rand_from(@random_thoughts))
	html = template('header')
	html << template(name)
	html << template('footer')
end

def h(str)
	ERB::Util.html_escape(str)
end

def file_writer(dir)
	Proc.new do |filename, contents|
		File.open(dir + '/' + filename, 'w') do |f|
			f.puts contents
		end
	end
end

def translations(lang)
	t = Object.new
	t9n = JSON.parse(File.read('t9n/' + lang + '.json'), symbolize_names: true)
	t9n.each do |k,v|
		t.define_singleton_method(k, Proc.new{v})
	end
	t
end

# for rel alternate header: returns hash of langcode => url
def alternates(thislang, thispage)
	others = {}
	(@languages.keys - [thislang]).each do |l|
		subdomain = (l == 'en') ? '' : "#{l}."
		others[l] = 'http://%smusicthoughts.com/%s' % [subdomain, thispage]
	end
	others
end

# Returns first 10 words or first 20 characters of quote
def snip_for_lang(str, language_code)
	if ['zh', 'ja'].include? language_code
		return (str[0,20] + '…')
	else
		return (str.split(' ')[0,10].join(' ') + '…')
	end
end

# returns just the id from one of these
def rand_from(thoughts)
	thoughts[rand(thoughts.size)]
end

@languages = {
	'en' => 'English',
	'es' => 'Español',
	'fr' => 'Français',
	'de' => 'Deutsch',
	'it' => 'Italiano',
	'pt' => 'Português',
	'ru' => 'Русский',
	'ar' => 'العربية',
	'ja' => '日本語',
	'zh' => '中文'}

@languages.each do |lang, langname|
	# file-writing shortcut used everywhere below
	f = file_writer('site/' + lang)

	ok, @random_thoughts = db.call('random_thoughts', lang)
	ok, @thoughts = db.call('approved_thoughts', lang)

	# vars for all templates
	@t = translations(lang)
	@lang = lang
	@dir = (lang == 'ar') ? 'rtl' : 'ltr'

	# write home
	@pagetitle = @t.musicthoughts
	@rel_alternate = alternates(lang, '')
	@rand_id2 = rand_from(@random_thoughts)[:id]
	f.call('home', page('home'))

	# write search
	@pagetitle = @t.search + ' ' + @t.musicthoughts
	@rel_alternate = alternates(lang, 'search')
	@site2search = (lang == 'en') ? '' : "#{lang}."
	@site2search << 'musicthoughts.com'
	f.call('search', page('search'))

	# write new
	@pagetitle = @t.new + ' ' + @t.musicthoughts
	@rel_alternate = alternates(lang, 'new')
	f.call('new', page('new'))

	# write thought pages
	@thoughts.each do |thought|
		ok, @thought = db.call('get_thought', lang, thought[:id])
		@pagetitle = (@t.author_quote_quote %
			[@thought[:author][:name], snip_for_lang(@thought[:thought], lang)])
		uri = 't/%d' % @thought[:id]
		@rel_alternate = alternates(lang, uri)
		f.call(uri, page('t'))
	end

	# write author pages
	ok, @authors = db.call('top_authors', nil)
	@pagetitle = @t.authors + ' ' + @t.musicthoughts
	@rel_alternate = alternates(lang, 'authors')
	f.call('authors', page('authors'))

	@authors.each do |author|
		ok, @author = db.call('get_author', lang, author[:id])
		@pagetitle = @author[:name] + ' ' + @t.musicthoughts
		uri = 'author/%d' % @author[:id]
		@rel_alternate = alternates(lang, uri)
		f.call(uri, page('author'))
	end

	# write contributor pages
	ok, @contributors = db.call('top_contributors', nil)
	@pagetitle = @t.contributors + ' ' + @t.musicthoughts
	@rel_alternate = alternates(lang, 'contributors')
	f.call('contributors', page('contributors'))

	@contributors.each do |contributor|
		ok, @contributor = db.call('get_contributor', lang, contributor[:id])
		@pagetitle = @contributor[:name] + ' ' + @t.musicthoughts
		uri = 'contributor/%d' % @contributor[:id]
		@rel_alternate = alternates(lang, uri)
		f.call(uri, page('contributor'))
	end

	# write about
	@pagetitle = @t.about + ' ' + @t.musicthoughts
	@rel_alternate = alternates(lang, 'about')
	f.call('about', page('about'))
end

