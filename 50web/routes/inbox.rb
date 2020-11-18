LIVETEST = 'live'
LOG = 'inbox'
require_relative 'bureau'
require 'net/http'
require 'twitter'


class Inbox < Bureau

	configure do
		set :views, '/var/www/htdocs/50web/views/inbox'
	end

	helpers do
		def redirect_to_email_or_person(email_id, person_id)
			if email_id
				redirect to('/email/%d' % email_id)
			else
				redirect to('/person/%d' % person_id)
			end
		end

		def redirect_to_email_or_home(ok, email)
			if ok
				redirect to('/email/%d' % email[:id])
			else
				redirect to('/')
			end
		end

		# also in routes/sivers.data.rb
		def geturl(url)
			url.strip!
			url = ('http://' + url) unless %r{\Ahttps?://} === url
			res = Net::HTTP.get_response(URI(url))
			if res.code.start_with? '30'
				if res['location'].start_with? 'http'
					url = res['location']
				else
					url = 'http://' + URI(url).host + res['location']
				end
				return geturl(url)
			else
				return url
			end
		end

		# INPUT: id that's in sivers.tweets.id, plus my message (no handle)
		# posts it to live Twitter status updates
		# OUTPUT: id of new tweet sent
		def reply_to_tweet(tweet_id, message)
			# get the tweet I'm replying to
			ok, tweet = PDB.call('get_tweet', tweet_id)
			return unless ok
			# add their handle to the front of the message
			message = '@%s %s' % [tweet[:handle], message.strip]
			# config the API
			tw = Twitter::REST::Client.new do |config|
				config.consumer_key = get_config('twitter.sivers.ck')
				config.consumer_secret = get_config('twitter.sivers.cs')
				config.access_token = get_config('twitter.sivers.at')
				config.access_token_secret = get_config('twitter.sivers.as')
			end
			# tweet it, and return id
			res = tw.update(message, in_reply_to_status_id: tweet_id)
			res.id
		end
	end

	before do
		if authorize!
			@eid = @auth_id
		end
	end

	get '/' do
		ok, @unopened_email_count = PDB.call('unopened_email_count', @eid)
		ok, @open_emails = PDB.call('opened_emails', @eid)
		ok, @unknowns_count = PDB.call('count_unknowns', @eid)
		ok, @inspect = PDB.call('inspections_grouped')
		ok, @tweets = PDB.call('tweets_unseen', 20)
		@pagetitle = "inbox for #{@eid}"
		erb :home
	end

	get '/unknown' do
		ok, @unknown = PDB.call('get_next_unknown', @eid)
		redirect to('/') unless ok
		@search = (params[:search]) ? params[:search].strip : @unknown[:their_name]
		ok, @results = PDB.call('people_search', @search)
		@pagetitle = 'unknown'
		erb :unknown
	end
 
	post %r{\A/unknown/([1-9][0-9]{0,5})\Z} do |email_id|
		person_id = (params[:person_id]) ? params[:person_id].to_i : 0
		PDB.call('set_unknown_person', @eid, email_id, person_id)
		redirect to('/unknown')
	end

	post %r{\A/unknown/([1-9][0-9]{0,5})/delete\Z} do |email_id|
		PDB.call('delete_unknown', @eid, email_id)
		redirect to('/unknown')
	end

	get '/unopened' do
		ok, @emails = PDB.call('unopened_emails', @eid, params[:profile], params[:category])
		@pagetitle = 'unopened for %s: %s' % [params[:profile], params[:category]]
		erb :emails
	end

	get '/unemailed' do
		ok, @people = PDB.call('people_unemailed')
		@pagetitle = 'unemailed'
		erb :people
	end

	post '/next_unopened' do
		ok, email = PDB.call('open_next_email', @eid, params[:profile], params[:category])
		redirect_to_email_or_home(ok, email)
	end

	get %r{\A/email/([1-9][0-9]{0,5})\Z} do |id|
		ok, @email = PDB.call('get_email', @eid, id)
		halt 404 unless ok
		@person = @email[:person]
		ok, @attributes = PDB.call('person_attributes', @person[:id])
		ok, @interests = PDB.call('person_interests', @person[:id])
		@inkeys = PDB.call('interest_keys')[1].map {|x| x[:inkey]}
		@clash = (@email[:their_email] != @person[:email])
		@profiles = ['sivers']
		ok, @akformletters = PDB.call('get_accesskey_formletters')
		@akformletters.each_with_index do |v,k|
			# prep body for use in JavaScript object
			@akformletters[k][:body] = v[:body].gsub('"', '\\"').gsub("\r", '').gsub("\n", '\n')
			if v[:body].include? '{listlink}'
				@akformletters[k][:body].gsub!('{listlink}', 'https://sivers.org/list/%d/%s' % [@person[:id], @person[:lopass]])
			end
		end
		@pagetitle = 'email %d from %s' % [id, @person[:name]]
		erb :email
	end

	post %r{\A/email/([1-9][0-9]{0,5})\Z} do |id|
		PDB.call('update_email', @eid, id, params.to_json)
		redirect to('/email/%d' % id)
	end

	post %r{\A/email/([1-9][0-9]{0,5})/delete\Z} do |id|
		PDB.call('delete_email', @eid, id)
		redirect '/'
	end

	post %r{\A/email/([1-9][0-9]{0,5})/unread\Z} do |id|
		PDB.call('unread_email', @eid, id)
		redirect '/'
	end

	post %r{\A/email/([1-9][0-9]{0,5})/close\Z} do |id|
		PDB.call('close_email', @eid, id)
		ok, email = PDB.call('open_next_email', @eid, params[:profile], params[:category])
		redirect_to_email_or_home(ok, email)
	end

	post %r{\A/email/([1-9][0-9]{0,5})/reply\Z} do |id|
		redirect to("/email/#{id}") unless params[:reply].strip.size > 0
		PDB.call('reply_to_email', @eid, id, params[:reply])
		ok, email = PDB.call('open_next_email', @eid, params[:profile], params[:category])
		redirect_to_email_or_home(ok, email)
	end

	post %r{\A/email/([1-9][0-9]{0,5})/not_my\Z} do |id|
		PDB.call('not_my_email', @eid, id)
		ok, email = PDB.call('open_next_email', @eid, params[:profile], params[:category])
		redirect_to_email_or_home(ok, email)
	end

	post %r{\A/email/([1-9][0-9]{0,5})/quickcat\Z} do |id|
		PDB.call('update_email', @eid, id, {category: params[:new]}.to_json)
		PDB.call('unread_email', @eid, id)
		ok, email = PDB.call('open_next_email', @eid, params[:profile], params[:old])
		redirect_to_email_or_home(ok, email)
	end

	post %r{\A/email/([1-9][0-9]{0,5})/quickform\Z} do |id|
		ok, res = PDB.call('parsed_formletter', params[:person_id], params[:formletter_id])
		PDB.call('reply_to_email', @eid, id, res[:body])
		ok, email = PDB.call('open_next_email', @eid, params[:profile], params[:category])
		redirect_to_email_or_home(ok, email)
	end

	post '/person' do
		ok, person = PDB.call('create_person', params[:name], params[:email])
		redirect to('/person/%d' % person[:id])
	end

	get %r{\A/person/([1-9][0-9]{0,5})\Z} do |id|
		ok, @person = PDB.call('get_person', id)
		halt(404) unless ok
		ok, @emails = PDB.call('get_person_emails', id)
		@emails.reverse!
		ok, @attributes = PDB.call('person_attributes', id)
		ok, @interests = PDB.call('person_interests', id)
		@inkeys = PDB.call('interest_keys')[1].map {|x| x[:inkey]}
		ok, @tables = PDB.call('tables_with_person', id)
		scp = get_config('scp')
		@tables.sort.map! do |t|
			(t == 'sivers.comments') ?
				('<a href="' + (scp % id) + '">sivers.comments</a>') : t
		end
		@profiles = ['sivers', 'muckwork']
		@pagetitle = 'person %d = %s' % [id, @person[:name]]
		erb :personfull
	end

	post %r{\A/person/([1-9][0-9]{0,5})\Z} do |id|
		PDB.call('update_person', id, params.to_json)
		redirect_to_email_or_person(params[:email_id], id)
	end

	post %r{\A/person/([1-9][0-9]{0,5})/annihilate\Z} do |id|
		PDB.call('annihilate_person', id)
		redirect '/'
	end

	post %r{\A/person/([1-9][0-9]{0,5})/url.json\Z} do |id|
		if url = geturl(params[:url])
			ok, res = PDB.call('add_url', id, url)
			res.to_json
		end
	end

	post %r{\A/person/([1-9][0-9]{0,5})/stat.json\Z} do |id|
		ok, res = PDB.call('add_stat', id, params[:key], params[:value])
		res.to_json
	end

	post %r{\A/attribute/([1-9][0-9]{0,5})/([a-z-]+)/plus.json\Z} do |id, attribute|
		ok, res = PDB.call('person_set_attribute', id, attribute, true)
		res.to_json
	end

	post %r{\A/attribute/([1-9][0-9]{0,5})/([a-z-]+)/minus.json\Z} do |id, attribute|
		ok, res = PDB.call('person_set_attribute', id, attribute, false)
		res.to_json
	end

	post %r{\A/attribute/([1-9][0-9]{0,5})/([a-z-]+)/delete.json\Z} do |id, attribute|
		ok, res = PDB.call('person_delete_attribute', id, attribute)
		res.to_json
	end

	post %r{\A/interest/([1-9][0-9]{0,5})/([a-z-]+)/add.json\Z} do |id, interest|
		ok, res = PDB.call('person_add_interest', id, interest)
		res.to_json
	end

	post %r{\A/interest/([1-9][0-9]{0,5})/([a-z-]+)/update.json\Z} do |id, interest|
		expert = case params[:expert]
			when 'f' then false
			when 't' then true
			else nil
		end
		ok, res = PDB.call('person_update_interest', id, interest, expert)
		res.to_json
	end

	post %r{\A/interest/([1-9][0-9]{0,5})/([a-z-]+)/delete.json\Z} do |id, interest|
		ok, res = PDB.call('person_delete_interest', id, interest)
		res.to_json
	end

	post %r{\A/tweet/([0-9]+)/seen.json\Z} do |id|
		ok, res = PDB.call('tweet_seen', id)
		res.to_json
	end

	post %r{\A/tweet/([0-9]+)/reply.json\Z} do |id|
		new_id = reply_to_tweet(id, params[:message])
		'{"id":"%s"}' % new_id  # as string not integer, since id too big for JS int
	end

	get '/tweets_unknown' do
		@pagetitle = 'tweets unknown'
		@tweets = {
			'new' => PDB.call('tweets_unknown_new', 20)[1],
			'top' => PDB.call('tweets_unknown_top', 20)[1]}
		erb :tweets_unknown
	end

	post '/tweets_unknown' do
		PDB.call('tweets_handle_person', params[:handle], params[:person_id])
		redirect to('/tweets_unknown')
	end

	post %r{\A/person/([1-9][0-9]{0,5})/email\Z} do |id|
		PDB.call('new_email', @eid, id, params[:profile], params[:subject], params[:body])
		redirect to('/person/%d' % id)
	end

	post %r{\A/person/([1-9][0-9]{0,5})/match/([1-9][0-9]{0,5})\Z} do |person_id, email_id|
		ok, res = PDB.call('get_email', @eid, email_id)
		PDB.call('update_person', person_id, {email: res[:their_email]}.to_json)
		redirect to('/email/%d' % email_id)
	end

	post %r{\A/url/([1-9][0-9]{0,6})/delete.json\Z} do |id|
		ok, res = PDB.call('delete_url', id)
		res.to_json
	end

	post %r{\A/stat/([1-9][0-9]{0,6})/delete.json\Z} do |id|
		ok, res = PDB.call('delete_stat', id)
		res.to_json
	end

	post %r{\A/url/([1-9][0-9]{0,6}).json\Z} do |id|
		ok, res = PDB.call('update_url', id, {main: params[:star]}.to_json)
		res.to_json
	end

	get '/aikeys' do
		ok, @atkeys = PDB.call('attribute_keys')
		ok, @inkeys = PDB.call('interest_keys')
		@pagetitle = 'attribute and interest keys'
		erb :aikeys
	end

	post '/attribute' do
		PDB.call('add_attribute_key', params[:attribute])
		redirect '/aikeys'
	end

	post %r{\A/attribute/([a-z-]+)/delete\Z} do |attribute|
		PDB.call('delete_attribute_key', attribute)
		redirect '/aikeys'
	end

	post %r{\A/attribute/([a-z-]+)/update\Z} do |attribute|
		PDB.call('update_attribute_key', attribute, params[:description])
		redirect '/aikeys'
	end

	post '/interest' do
		PDB.call('add_interest_key', params[:interest])
		redirect '/aikeys'
	end

	post %r{\A/interest/([a-z-]+)/delete\Z} do |interest|
		PDB.call('delete_interest_key', interest)
		redirect '/aikeys'
	end

	post %r{\A/interest/([a-z-]+)/update\Z} do |interest|
		PDB.call('update_interest_key', interest, params[:description])
		redirect '/aikeys'
	end

	# to avoid external sites seeing my internal links:
	# <a href="/link?url=http://someothersite.com">someothersite.com</a>
	get '/link' do
		redirect to(params[:url])
	end

	get '/search' do
		@q = (params[:q]) ? params[:q] : false
		if @q
			ok, @results = PDB.call('people_search', @q)
		end
		@pagetitle = 'search'
		erb :search
	end

	get '/sent' do
		ok, @grouped = PDB.call('sent_emails_grouped')
		@pagetitle = 'sent emails'
		erb :sent
	end

	get '/formletters' do
		ok, @formletters = PDB.call('get_formletters')
		@pagetitle = 'form letters'
		erb :formletters
	end

	post '/formletters' do
		ok, res = PDB.call('create_formletter', params[:title])
		if ok
			redirect to('/formletter/%d' % res[:id])
		else
			redirect to('/formletters')
		end
	end

	get %r{\A/person/([1-9][0-9]{0,5})/formletter/([1-9][0-9]{0,2}).json\Z} do |person_id, formletter_id|
		ok, res = PDB.call('parsed_formletter', person_id, formletter_id)
		res.to_json
	end

	get %r{\A/formletter/([1-9][0-9]{0,2})\Z} do |id|
		ok, @formletter = PDB.call('get_formletter', id)
		halt(404) unless ok
		@pagetitle = 'formletter %d' % id
		erb :formletter
	end

	post %r{\A/formletter/([1-9][0-9]{0,2})\Z} do |id|
		PDB.call('update_formletter', id, params.to_json)
		redirect to('/formletter/%d' % id)
	end

	post %r{\A/formletter/([1-9][0-9]{0,2})/delete\Z} do |id|
		PDB.call('delete_formletter', id)
		redirect to('/formletters')
	end

	get '/countries' do
		ok, @countries = PDB.call('country_count')
		@pagetitle = 'countries'
		ok, @cc = PDB.call('country_names')
		erb :where_countries
	end

	get %r{\A/states/([A-Z][A-Z])\Z} do |country_code|
		@country = country_code
		ok, @states = PDB.call('state_count', country_code)
		@pagetitle = 'states for %s' % country_code
		erb :where_states
	end

	get %r{\A/cities/([A-Z][A-Z])\Z} do |country_code|
		@country = country_code
		ok, @cities = PDB.call('city_count', country_code)
		@state = nil
		@pagetitle = 'cities for %s' % country_code
		erb :where_cities
	end

	get %r{\A/cities/([A-Z][A-Z])/(\S+)\Z} do |country_code, state_name|
		@country = country_code
		ok, @cities = PDB.call('city_count', country_code, state_name)
		@state = state_name
		@pagetitle = 'cities for %s, %s' % [state_name, country_code]
		erb :where_cities
	end

	get %r{\A/where/([A-Z][A-Z])} do |country|
		city = params[:city]
		state = params[:state]
		if state && city
			ok, @people = PDB.call('people_from_state_city', country, state, city)
		elsif state
			ok, @people = PDB.call('people_from_state', country, state)
		elsif city
			ok, @people = PDB.call('people_from_city', country, city)
		else
			ok, @people = PDB.call('people_from_country', country)
		end
		@pagetitle = 'People in %s' % [city, state, country].compact.join(', ')
		erb :people
	end

	get %r{\A/stats/(\S+)/(\S+)\Z} do |statkey, statvalue| 
		ok, @stats = PDB.call('get_stats', statkey, statvalue)
		@statkey = statkey
		ok, @valuecount = PDB.call('get_stat_value_count', statkey)
		@pagetitle = '%s = %s' % [statkey, statvalue]
		erb :stats_people
	end

	get %r{\A/stats/(\S+)\Z} do |statkey| 
		ok, @stats = PDB.call('get_stats', statkey)
		@statkey = statkey
		ok, @valuecount = PDB.call('get_stat_value_count', statkey)
		@pagetitle = statkey
		erb :stats_people
	end

	get '/stats' do
		ok, @stats = PDB.call('get_stat_name_count')
		@pagetitle = 'stats'
		erb :stats_count
	end

	get '/merge' do
		@person1 = @person2 = nil
		@id1 = params[:id1].to_i
		if @id1 > 0
			ok, @person1 = PDB.call('get_person', @id1)
		end
		@id2 = params[:id2].to_i
		if @id2 > 0
			ok, @person2 = PDB.call('get_person', @id2)
		end
		@q = params[:q] || false
		if @q
			ok, @results = PDB.call('people_search', @q.strip)
		end
		@pagetitle = 'merge'
		erb :merge
	end

	post %r{\A/merge/([1-9][0-9]{0,5})\Z} do |id|
		ok, res = PDB.call('merge_person', id, params[:id2])
		if ok
			redirect to('/person/%d' % id)
		else
			redirect to('/merge?id1=%d&id2=%d' % [id, params[:id2]])
		end
	end

	get '/now' do
		now = getdb('now', LIVETEST)
		ok, @knowns = now.call('knowns')
		ok, @unknowns = now.call('unknowns')
		@pagetitle = 'now'
		erb :now
	end

	post '/now' do
		now = getdb('now', LIVETEST)
		# get short from long
		long = params[:long].strip
		short = long.gsub(/^https?:\/\//, '').gsub(/^www\./, '').gsub(/\/$/, '')
		ok, u = now.call('add_url', params[:person_id], short)
		if ok
			# if short worked, update with long
			nu = {long: long}.to_json
			now.call('update_url', u[:id], nu)
			# give them a newpass
			PDB.call('make_newpass', params[:person_id])
			# send them the formletter
			PDB.call('send_person_formletter', params[:person_id], 6, 'sivers')
		end
		redirect to('/now/%d' % params[:person_id])
	end

	get %r{\A/now/find/([1-9][0-9]{0,5})\Z} do |id|
		now = getdb('now', LIVETEST)
		ok, @now = now.call('url', id)
		ok, @people = now.call('unknown_find', id)
		@pagetitle = "now #{id}"
		erb :nowfind
	end

	post %r{\A/now/find/([1-9][0-9]{0,5})\Z} do |id|
		now = getdb('now', LIVETEST)
		now.call('unknown_assign', id, params[:person_id])
		redirect to('/now')
	end

	get %r{\A/now/([1-9][0-9]{0,5})\Z} do |person_id|
		now = getdb('now', LIVETEST)
		ok, @urls = now.call('urls_for_person', person_id)
		ok, @stats = now.call('stats_for_person', person_id)
		@person_id = person_id
		@pagetitle = "/now for #{person_id}"
		erb :now_person
	end

	post %r{\A/now/([1-9][0-9]{0,3})\Z} do |id|
		now = getdb('now', LIVETEST)
		now.call('update_url', id, params.to_json)
		redirect to('/now/%d' % params[:person_id])
	end

	post %r{\A/now/([1-9][0-9]{0,3})/delete\Z} do |id|
		now = getdb('now', LIVETEST)
		now.call('delete_url', id)
		redirect to('/')
	end

	post '/stats' do
		PDB.call('add_stat', params[:person_id], params[:name], params[:value])
		redirect to('/now/%d' % params[:person_id])
	end

	post %r{\A/stats/([1-9][0-9]{0,6})\Z} do |id|
		PDB.call('update_stat', id, {statvalue: params[:value]}.to_json)
		redirect to('/now/%d' % params[:person_id])
	end

	get '/inspector/peeps/people' do
		@pagetitle = 'inspector'
		ok, @inspect = PDB.call('inspect_peeps_people')
		erb :inspect_peeps_people
	end

	get '/inspector/peeps/urls' do
		@pagetitle = 'inspector'
		ok, @inspect = PDB.call('inspect_peeps_urls')
		erb :inspect_peeps_urls
	end

	get '/inspector/peeps/stats' do
		@pagetitle = 'inspector'
		ok, @inspect = PDB.call('inspect_peeps_stats')
		erb :inspect_peeps_stats
	end

	get '/inspector/now/urls' do
		@pagetitle = 'inspector'
		ok, @inspect = PDB.call('inspect_now_urls')
		erb :inspect_now_urls
	end

	post '/inspector' do
		ids = params[:ids].split(',').map(&:to_i)
		PDB.call('log_approve', ids.to_json)
		redirect to('/')
	end

	get '/people/interests' do
		interest = params[:interest]
		if 't' == params[:expert]
			expert = true
		elsif 'f' == params[:expert]
			expert = false
		else
			expert = nil
		end
		ok, @people = PDB.call('people_with_interest', interest, expert)
		@pagetitle = interest + ' = ' + params[:expert]
		erb :people
	end

	get '/people/attributes' do
		attribute = params[:attribute]
		plusminus = (params[:plusminus] == 't')
		ok, @people = PDB.call('people_with_attribute', attribute, plusminus)
		@pagetitle = attribute + ' = ' + params[:plusminus]
		erb :people
	end

	get '/comments' do
		db = getdb('sivers', LIVETEST)
		ok, @comments = db.call('new_comments')
		erb :comment_list
	end

	get %r{\A/comment/([0-9]+)\Z} do |id|
		db = getdb('sivers', LIVETEST)
		ok, @comment = db.call('get_comment', id)
		halt(404) unless ok
		erb :comment_edit
	end

	get %r{\A/person/([0-9]+)/comments\Z} do |id|
		db = getdb('sivers', LIVETEST)
		ok, @comments = db.call('comments_by_person', id)
		halt(404) unless ok
		erb :comment_list
	end

	post %r{\A/comment/([0-9]+)\Z} do |id|
		db = getdb('sivers', LIVETEST)
		db.call('update_comment', id, params.to_json)
		redirect '/comments'
	end

	post %r{\A/comment/([0-9]+)/reply\Z} do |id|
		db = getdb('sivers', LIVETEST)
		db.call('reply_to_comment', id, params[:reply])
		redirect '/comments'
	end

	post %r{\A/comment/([0-9]+)/delete\Z} do |id|
		db = getdb('sivers', LIVETEST)
		db.call('delete_comment', id)
		redirect '/comments'
	end

	post %r{\A/comment/([0-9]+)/spam\Z} do |id|
		db = getdb('sivers', LIVETEST)
		db.call('spam_comment', id)
		redirect '/comments'
	end

	get '/kykyc' do
		@kyp = {18 => 'A3', 19 => 'S3'}
		ok, @people = PDB.call('kyc_recent')
		@pagetitle = 'KYKYC'
		erb :kykyc
	end

	delete %r{\A/kykyc/([1-9][0-9]{0,5})\Z} do |id|
		ok, js = PDB.call('update_person', id, '{"checked_at": null}')
	end

	post %r{\A/kykyc/([1-9][0-9]{0,5})/([0-9]{1,2})\Z} do |id, eid|
		ok, js = PDB.call('update_person', id, {checked_by: eid,
			checked_at: Time.now().strftime('%Y-%m-%dT%H:%M:%S')}.to_json)
	end

end
