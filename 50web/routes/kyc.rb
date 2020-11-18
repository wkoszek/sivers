LIVETEST = 'live'
LOG = 'kyc'
require_relative 'bureau'
require 'net/http'

class KYC < Bureau

	configure do
		set :views, '/var/www/htdocs/50web/views/kyc'
	end

	helpers do
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
	end

	before do
		if authorize!
			@eid = @auth_id
		end
	end

	get '/' do
		@pagetitle = "KYC for #{@eid}"
		erb :home
	end

	get '/link' do
		url = (%r{\Ahttps?://} === params[:url]) ? params[:url] : ('http://' + params[:url])
		redirect to(url)
	end

	post '/next' do
		ok, js = PDB.call('kyc_next_person', @eid)
		redirect to('/person1/%d' % js[:person_id])
	end

	# update: name address company country city state
	post %r{\A/update1/([1-9][0-9]{0,5})\Z} do |id|
		redirect to('/person1/%d' % id) unless params[:name].strip.size > 0
		redirect to('/person1/%d' % id) unless params[:address].strip.size > 0
		ok, _ = PDB.call('kyc_ok_person', @eid, id)
		redirect to('/') unless ok
		ok, _ = PDB.call('update_person', id, {
			name: params[:name].strip,
			address: params[:address].strip,
			company: params[:company].strip,
			country: params[:country].strip,
			city: params[:city].strip,
			state: params[:state].strip}.to_json)
		if ok
			redirect to('/person2/%d' % id)
		else
			redirect to('/person1/%d' % id)
		end
	end

	post %r{\A/person/([1-9][0-9]{0,5})/url.json\Z} do |id|
		if url = geturl(params[:url])
			ok, res = PDB.call('add_url', id, url)
			res.to_json
		end
	end

	post %r{\A/url/([1-9][0-9]{0,6})/delete.json\Z} do |id|
		ok, res = PDB.call('delete_url', id)
		res.to_json
	end

	post %r{\A/url/([1-9][0-9]{0,6}).json\Z} do |id|
		ok, res = PDB.call('update_url', id, {main: params[:star]}.to_json)
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

	get '/aikeys' do
		ok, @atkeys = PDB.call('attribute_keys')
		ok, @inkeys = PDB.call('interest_keys')
		@pagetitle = 'attribute and interest keys'
		erb :aikeys
	end

	post %r{\A/interest/([a-z-]+)/delete\Z} do |interest|
		PDB.call('delete_interest_key', interest)
		redirect '/aikeys'
	end

	post %r{\A/interest/([a-z-]+)/update\Z} do |interest|
		PDB.call('update_interest_key', interest, params[:description])
		redirect '/aikeys'
	end

	post '/interest' do
		interest = params[:interest].strip.downcase
		id = params[:person_id]
		if interest.size > 0
			PDB.call('add_interest_key', interest)
			PDB.call('person_add_interest', id, interest) if id
		end
		if id
			redirect to('/person3/%d' % id)
		else
			redirect '/aikeys'
		end
	end

	post %r{\A/update3/([1-9][0-9]{0,5})\Z} do |id|
		ok, _ = PDB.call('kyc_ok_person', @eid, id)
		redirect to('/') unless ok
		ok, _ = PDB.call('kyc_done_person', id)
		# go to next!  (save a trip to home page)
		ok, js = PDB.call('kyc_next_person', @eid)
		redirect to('/person1/%d' % js[:person_id])
	end

	get %r{\A/person1/([1-9][0-9]{0,5})\Z} do |id|
		ok, @person = PDB.call('kyc_get_person', @eid, id)
		halt(404) unless ok
		@pagetitle = 'person %d = %s' % [id, @person[:name]]
		erb :person1
	end

	get %r{\A/person2/([1-9][0-9]{0,5})\Z} do |id|
		ok, @person = PDB.call('kyc_get_person', @eid, id)
		halt(404) unless ok
		if @person[:emails]
			@eurls = @person[:emails].map {|e| e[:urls]}.flatten.uniq.sort
		end
		@pagetitle = 'person %d = %s' % [id, @person[:name]]
		erb :person2
	end

	get %r{\A/person3/([1-9][0-9]{0,5})\Z} do |id|
		ok, @person = PDB.call('kyc_get_person', @eid, id)
		halt(404) unless ok
		@inkeys = PDB.call('interest_keys')[1].map {|x| x[:inkey]}
		allbodies = @person[:emails].map {|e| e[:body]}.join(' ').downcase
		@foundkeys = @inkeys.select {|w| allbodies.include? w}
		@pagetitle = 'person %d = %s' % [id, @person[:name]]
		erb :person3
	end

end
