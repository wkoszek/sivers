require 'sinatra/base'
require 'tilt/erb'
require 'getdb'
PDB = getdb('peeps', LIVETEST)

# COMMON THINGS MY WEB APPS NEED.  Mostly authentication.
# Why "Bureau"?  Because it's uncommon, and falls early alphabetically
class Bureau < Sinatra::Base

	log = File.new("/tmp/#{LOG}.log", 'a+')
	log.sync = true

	# Great feature that looks for templates in multiple directories,
	# the one passed in by top route, and then add 'views/bureau'
	# Layout is in top, then ingredients like login.erb are in views/bureau/
	def find_template(viewpath, name, engine, &block)
		super(viewpath, name, engine, &block)
		super('/var/www/htdocs/50web/views/bureau', name, engine, &block)
	end

	configure do
		set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
		enable :logging
	end

	helpers do
		def h(text)
			Rack::Utils.escape_html(text)
		end

		def showmoney(money)
			'$%0.2f %s' % [money[:amount], money[:currency]]
		end

		# This is the database table that needs to have the auth'd person_id in it.
		# Meaning: after the person is authenticated with a password or cookie, so we
		# know they are person_id 12345, now we need to make sure that person_id is
		# also found in this database table, or else they can't continue.
		# Instead of each top-level route having to pass in the name of its secondary
		# auth table, just getting it by hostname, here.
		def auth_table
			case request.host
			when 'kyc.sivers.org', 'kyc.dev'
				'peeps.emailers'
			when 'inbox.sivers.org', 'inbox.dev'
				'peeps.emailers'
			when 'data.sivers.org', 'sivdata.dev'
				nil # no secondary table
			when 'data.woodegg.com', 'woodegg.dev'
				'woodegg.customers'
			when 'words.sivers.org', 'words.dev'
				'words.translators'
			when 'c.muckwork.com', 'muckc.dev'
				'muckwork.clients'
			when 'w.muckwork.com', 'muckw.dev'
				'muckwork.workers'
			when 'm.muckwork.com', 'muckm.dev'
				'muckwork.managers'
			else
				raise "bad host in auth_table: #{request.host}"
			end
		end

		def auth_bypass?
			nocookie = %w(/login /getpass /newpass /thanks /sorry)
			# using start_with? because /newpass/1234/aBcDeFgH doesn't need auth
			nocookie.find {|p| request.path.start_with? p}
		end

		# Use the browser cookie to authenticate both person and secondary table
		def authorized?
			return false unless /[a-zA-Z0-9]{32}/ === request.cookies['ok']
			ok, @person = PDB.call('get_person_cookie', request.cookies['ok'])
			return false unless ok
			if auth_table 
				ok, res = PDB.call('person_in_table', @person[:id], auth_table)
				return false unless ok
				@auth_id = res[:id]
			else  # no auth_table means person auth is all we need
				@auth_id = @person[:id]
			end
		end

		# returns false or true so can be used by top level routes in an "if"
		# so "if authorize!" then @person and @auth_id are set
		def authorize!
			return false if auth_bypass?
			redirect to('/login') unless authorized?
			# now @person and @auth_id should be set
			return true
		end

		def setcookie(val)
			response.set_cookie('ok', value: val, path: '/',
				expires: Time.now + (60 * 60 * 24 * 365), secure: true, httponly: true)
		end

		def killcookie
			response.set_cookie('ok', value: '', path: '/',
				expires: Time.now - (60 * 60 * 24), secure: true, httponly: true)
		end

		def login(person_id)
			ok, res = PDB.call('cookie_from_id', person_id, request.host)
			return false unless ok
			setcookie(res[:cookie])
		end

		# Use email + password to authenticate both person and secondary table
		# Then set cookie if all OK
		def password_auth(email, password)
			ok, @person = PDB.call('get_person_password', email, password)
			return false unless ok
			if auth_table
				ok, res = PDB.call('person_in_table', @person[:id], auth_table)
				return false unless ok
			end
			unless login(@person[:id]) == false
				redirect to('/')  # TODO : is this right?
			end
		end

		def sorry(msg)
			redirect to('/sorry?for=' + msg)
		end

		def thanks(msg)
			redirect to('/thanks?for=' + msg)
		end
	end

	get '/login' do
		redirect to('/') if authorized?
		@pagetitle = 'log in'
		erb :login
	end

	post '/login' do
		redirect to('/') if authorized?
		sorry 'bademail' unless (/\A\S+@\S+\.\S+\Z/ === params[:email])
		sorry 'badlogin' unless String(params[:password]).size > 3
		if password_auth(params[:email], params[:password])
			redirect to('/')
		else
			sorry 'badlogin'
		end
	end

	get '/logout' do
		killcookie
		redirect to('/login')
	end

	get '/getpass' do
		redirect to('/') if authorized?
		@pagetitle = 'get a new password'
		erb :getpass
	end

	# route to receive post of that ^ form, verify, send formletter, or sorry
	post '/getpass' do
		redirect to('/') if authorized?
		sorry 'bademail' unless (/\A\S+@\S+\.\S+\Z/ === params[:email])
		ok, _ = PDB.call('reset_email', 1, params[:email]) # TODO: domain name in formletter
		sorry 'unknown' unless ok
		thanks 'getpass'
	end

	# /thanks?for= pages
	get '/thanks' do
		@header = @pagetitle = 'Thank you!'
		@msg = case params[:for] 
		when 'getpass'
			'Please go check for an email from derek@sivers.org</p>
			<p>Subject is “your password reset link”'
		else
			'You’re so cool.'
		end
		erb :generic
	end

	# /sorry?for= pages
	get '/sorry' do
		@header = @pagetitle = 'Sorry!'
		@msg = case params[:for] 
		when 'bademail'
			'There was a typo in your email address.</p><p>Please try again.'
		when 'unknown'
			'That email address is not in my system.</p><p>Do you have another?'
		when 'badid'
			'That link is expired. Maybe try to <a href="/login">log in</a>?'
		when 'badpass'
			'Not sure why, but my system didn’t accept that password. Try another?'
		when 'badlogin'
			'That email address or password wasn’t right.
			</p><p>Please <a href="/login">try again</a>.'
		when 'badupdate'
			'That updated info seems wrong, because the database wouldn’t accept it.
			</p><p>Please go back, look closely, and try again.'
		when 'notfound'
			'Something was not found. Email derek@sivers.org to let me know.'
		else
			'I’m sure it’s my fault.'
		end
		erb :generic
	end

	#	receive password reset link & show form to make new password
	get %r{\A/newpass/([1-9][0-9]{0,5})/([0-9a-zA-Z]{8})\Z} do |id, newpass|
		redirect to('/') if authorized?
		ok, @person = PDB.call('get_person_newpass', id, newpass)
		sorry 'badid' unless ok
		@post2 = '/newpass/%d/%s' % [id, newpass]
		@pagetitle = 'make a password'
		erb :newpass
	end

	# route to receive post of new password. logs in with cookie. sends home.
	post %r{\A/newpass/([1-9][0-9]{0,5})/([0-9a-zA-Z]{8})\Z} do |id, newpass|
		redirect to('/') if authorized?
		unless String(params[:setpass]).length > 3
			redirect to('/newpass/%d/%s' % [id, newpass])
		end
		ok, _ = PDB.call('get_person_newpass', id, newpass)
		sorry 'badid' unless ok
		ok, _ = PDB.call('set_password', id, params[:setpass])
		sorry 'badpass' unless ok
		login(id)
		redirect to('/')
	end

end
