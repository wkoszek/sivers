LIVETEST = 'live'
LOG = 'data.sivers'
require_relative 'bureau'  # use PDB
require 'digest/md5'
require 'net/http'

# https://data.sivers.org/ CONTENTS:
# home: forms for email, city/state/country, listype, urls. link to /now
# routes to receive post of each of these ^ forms
# now: if no now.urls yet, form to enter one
# route to trim new now.url, check unique, visit it, get long, insert
# now profile questions. edit link to turn answer into form. [save] button.
# routes to receive post of each of these ^ forms, redirect to /now

class SiversData < Bureau

	configure do
		set :views, '/var/www/htdocs/50web/views/sivers.data'
	end

	helpers do
		# also in routes/inbox.rb
		def geturl(url)
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

		def gravatar_url(hash)
			'https://secure.gravatar.com/avatar/%s?s=300' % hash
		end

		def gravatar(person)
			stat = person[:stats].find {|s| s[:name] == 'gravatar'}
			return false if stat.nil?
			gravatar_url(stat[:value])
		end

		def get_gravatar(person, db)
			return gravatar(person) if gravatar(person)
			hash = Digest::MD5.hexdigest(person[:email])
			url = 'http://www.gravatar.com/avatar/%s?d=404' % hash
			res = Net::HTTP.get_response(URI(url))
			if res.code == '200'
				db.call('add_stat', person[:id], 'gravatar', hash)
				gravatar_url(hash)
			else
				false
			end
		end
	end

	before do
		if authorize!
			@person_id = @auth_id
		end
	end

##### ALL THESE ROUTES NEED AUTH COOKIE:

	# home: forms for email, city/state/country, listype, urls. link to /now
	get '/' do
		@pagetitle = 'your data'
		erb :home
	end

	# routes to receive post of each of these ^ forms...
	# update email, city, state, country, listype
	post '/update' do
		whitelist = %w(city state country email listype)
		update = params.select {|k,v| whitelist.include? k}
		ok, _ = PDB.call('update_person', @person_id, update.to_json)
		PDB.call('log', @person_id, 'peeps', 'people', @person_id) if ok
		sorry 'badupdate' unless ok
		redirect to('/?update=ok')
	end

	# delete a url
	post %r{\A/urls/delete/([1-9][0-9]{0,6})\Z} do |id|
		ok, u = PDB.call('get_url', id)
		if ok && u[:person_id] == @person_id
			PDB.call('delete_url', id)
		end
		redirect to('/urls')
	end

	# star a url
	post %r{\A/urls/star/([1-9][0-9]{0,6})\Z} do |id|
		ok, u = PDB.call('get_url', id)
		if ok && u[:person_id] == @person_id
			PDB.call('update_url', id, '{"main":true}')
		end
		redirect to('/urls')
	end

	# page for url forms
	get '/urls' do
		ok, @person = PDB.call('get_person', @person_id)
		@urls = @person[:urls] || []
		@pagetitle = 'your URLs'
		erb :urls
	end

	# add a url
	post '/urls' do
		if url = geturl(params[:url])
			ok, u = PDB.call('add_url', @person_id, url)
			PDB.call('log', @person_id, 'peeps', 'urls', u[:id]) if ok
		end
		redirect to('/urls')
	end

	# update now page
	post %r{\A/now/([1-9][0-9]{0,3})\Z} do |id|
		n = getdb('now', LIVETEST)
		ok, u = n.call('url', id)
		if ok && u[:person_id] == @person_id
			ok, _ = n.call('update_url', id, params.to_json)
			PDB.call('log', @person_id, 'now', 'urls', u[:id]) if ok
		end
		redirect to('/now')
	end

	# delete now page
	post %r{\A/now/delete/([1-9][0-9]{0,4})\Z} do |id|
		n = getdb('now', LIVETEST)
		ok, u = n.call('url', id)
		if ok && u[:person_id] == @person_id
			n.call('delete_url', id)
		end
		redirect to('/now')
	end

	# page for /now forms
	get '/now' do
		@gravatar = (@person[:stats]) ? get_gravatar(@person, PDB) : false
		n = getdb('now', LIVETEST)
		ok, @nows = n.call('urls_for_person', @person_id)
		@pagetitle = 'your /now page'
		erb :now
	end

	# route to trim new now.url, check unique, visit it, get long, insert
	post '/now' do
		n = getdb('now', LIVETEST)
		ok, u = n.call('add_url', @person_id, params[:url])
		if ok
			PDB.call('log', @person_id, 'now', 'urls', u[:id])
			n.call('update_url', u[:id], {long: params[:url]}.to_json)
		end
		redirect to('/now')
	end

	# now profile questions. edit link to turn answer into form. [save] button.
	get '/profile' do
		n = getdb('now', LIVETEST)
		ok, nows = n.call('urls_for_person', @person_id)
		if nows.size == 0
			redirect to('/now')
		end
		ok, @stats = n.call('stats_for_person', @person_id)
		@pagetitle = 'your profile for nownownow.com'
		erb :profile
	end

	# update profile answers
	post %r{\A/profile/([1-9][0-9]{0,6})\Z} do |id|
		ok, stat = PDB.call('get_stat', id)
		if stat[:person][:id] == @person_id
			ok, _ = PDB.call('update_stat', id, {statvalue: params[:statvalue]}.to_json)
			PDB.call('log', @person_id, 'peeps', 'stats', id) if ok
		end
		redirect to('/profile')
	end

	# add profile answers
	post '/profile' do
		whitelist = %w(now-title now-red now-why now-liner now-thought)
		if whitelist.include?(params[:statkey]) && params[:statvalue].size > 2
			ok, s = PDB.call('add_stat', @person_id, params[:statkey], params[:statvalue])
			PDB.call('log', @person_id, 'peeps', 'stats', s[:id]) if ok
		end
		redirect to('/profile')
	end

end
