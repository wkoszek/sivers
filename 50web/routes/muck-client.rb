require 'sinatra/base'
require 'tilt/erb'
require 'getdb'
require 'stripe'

class MuckClientWeb < Sinatra::Base

	log = File.new('/tmp/MuckClientWeb.log', 'a+')
	log.sync = true

	configure do
		enable :logging
		set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
		set :views, Proc.new { File.join(root, 'views/muck-client') }
	end

	def protected!
		redirect to('/login') unless @client_id
	end

	def has_cookie?
		# TODO: new cookie
	end

	def login(res)
		expires = Time.now + (60 * 60 * 24 * 30)
		# TODO: new cookie
	end

	def logout
		expires = Time.at(0)
		# TODO: new cookie
	end

	def sorry(msg)
		redirect to('/sorry?for=' + msg)
	end

	def thanks(msg)
		redirect to('/thanks?for=' + msg)
	end

	before do
		@api = 'MuckworkClient'
		@livetest = 'test'
		env['rack.errors'] = log
		@client_id = @person_id = @client = false
		if has_cookie?
			@db = getdb('muckwork', @livetest)
			ok, res = @db.call('auth_client') # TODO: new cookie
			sorry 'cookie' unless ok
			@client_id = res[:client_id]
			@person_id = res[:person_id]
			ok, @client = @db.call('get_client', @client_id)
			sorry 'client' unless ok
		end
	end

	helpers do
		def h(text)
			Rack::Utils.escape_html(text)
		end
	end

##### ROUTES THAT DON'T NEED AUTH COOKIE

	get '/login' do
		redirect to('/') if @client
		@pagetitle = 'Muckwork client login'
		erb :login
	end

	# route to receive login form: sorry or logs in with cookie. sends home.
	post '/login' do
		redirect to('/') if @client
		sorry 'bademail' unless (/\A\S+@\S+\.\S+\Z/ === params[:email])
		sorry 'badlogin' unless String(params[:password]).size > 3
		db = getdb('peeps', @livetest)
		ok, res = db.call('auth_api', params[:email], params[:password], @api)
		sorry 'badlogin' unless ok
		login(res)
		redirect to('/')
	end

	get '/logout' do
		logout
		redirect to('/login')
	end

	# when they signup, create a person in the database, but not muckwork.client yet
	# (create_client happens in the /newpass post below)
	post '/signup' do
		redirect to('/') if @client
		sorry 'badname' unless String(params[:name]).size > 1
		sorry 'bademail' unless (/\A\S+@\S+\.\S+\Z/ === params[:email])
		db = getdb('peeps', @livetest)
		ok, person = db.call('create_person', params[:name], params[:email])  # TODO: stats
		sorry 'badcreate' unless ok
		ok, _ = db.call('make_newpass', person[:id])
		sorry 'badcreate' unless ok
		ok, _ = db.call('send_person_formletter', person[:id], 7, 'muckwork')
		thanks 'signup'
	end

	get '/thanks' do
		@pagetitle = 'Thank you!'
		@msg = case params[:for] 
		when 'signup'
			'Thank you for signing up.</p>
			<p>Please check your email for an email from <strong>muckwork@muckwork.com</strong></p>
			<p>Subject: “<strong>Muckwork signup</strong>”</p>
			<p>Click the link in there to make a password.'
		else
			'You’re so cool.'
		end
		erb :generic
	end

	get '/sorry' do
		@pagetitle = 'Sorry!'
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
			'That email address or password wasn’t right.</p>
			<p>Please <a href="/login">try again</a>.'
		when 'badname'
			'Did you forget your name? Please go back and tell me your name.'
		when 'badcreate'
			'That new info seems wrong, because the database wouldn’t accept it.
			</p><p>Please go back, look closely, and try again.'
		when 'badupdate'
			'That updated info seems wrong, because the database wouldn’t accept it.
			</p><p>Please go back, look closely, and try again.'
		when 'api'
			'Strange. MuckworkClient API key is wrong.</p>
			<p>Please <a href="/logout">log in again</a>.'
		when 'api'
			'Strange. Muckwork client is not found.</p>
			<p>Please <a href="/logout">log in again</a>.'
		else
			'I’m sure it’s my fault.'
		end
		erb :generic
	end

	#	receive password reset link & show form to make new password
	get %r{\A/newpass/([1-9][0-9]{0,5})/([0-9a-zA-Z]{8})\Z} do |id, newpass|
		redirect to('/') if @client
		db = getdb('peeps', @livetest)
		ok, @person = db.call('get_person_newpass', id, newpass)
		sorry 'badid' unless ok
		@post2 = '/newpass/%d/%s' % [id, newpass]
		@pagetitle = 'make a password'
		erb :newpass
	end

	# route to receive post of new password. logs in with cookie. sends home.
	post %r{\A/newpass/([1-9][0-9]{0,5})/([0-9a-zA-Z]{8})\Z} do |id, newpass|
		redirect to('/') if @client
		db = getdb('peeps', @livetest)
		ok, _ = db.call('get_person_newpass', id, newpass)
		sorry 'badid' unless ok
		sorry 'badpass' unless String(params[:setpass]).length > 3
		ok, _ = db.call('set_password', id, params[:setpass])
		sorry 'badpass' unless ok
		mw = getdb('muckwork', @livetest)
		ok, res = mw.call('create_client', id)  # TODO: stat
		sorry 'badcreate' unless ok
		login(res)
		redirect to('/')
	end

##### ROUTES THAT NEED AUTH COOKIE

	get '/' do
		protected!
		ok, @projects = @db.call('client_get_projects', @client_id)
		@pagetitle = @client[:name] + ' HOME'
		erb :home
	end

	get '/account' do
		protected!
		db2 = getdb_noschema(@livetest)
		@pagetitle = @client[:name] + ' ACCOUNT'
		@msg = params[:msg]
		ok, @locations = db2.call('peeps.all_countries')
		ok, @currencies = db2.call('core.all_currencies')
		erb :account
	end

	post '/account' do
		protected!
		filtered = params.reject {|k,v| k == :person_id}
		@db.call('update_client', @client_id, filtered)
		redirect to('/account?msg=updated')
	end

	post '/password' do
		protected!
		db2 = getdb_noschema(@livetest)
		db2.call('peeps.set_password', @person_id, params[:password])
		redirect to('/account?msg=newpass')
	end

	get '/balance' do
		protected!
		@pagetitle = 'balance'
		ok, @payments = @db.call('client_payments', @client_id)
		@stripe_pub = get_config('stripe_test_public')
		erb :balance
	end

	post '/balance' do
		protected!
		token = params[:stripeToken]
		Stripe.api_key = get_config('stripe_test_secret')
		begin
			charge = Stripe::Charge.create(
				amount: 2000,
				currency: 'usd',
				source: token,
				description: 'Muckwork $20'
			)
			@db.call('add_client_payment', @client_id, 'USD', 20, charge.to_json)
			redirect to('/balance')
		rescue Stripe::CardError => e
			File.open('/tmp/error-' + token, 'w') {|f| f.puts Marshal.dump(e) }
			redirect to('/balance?error=%s' % token)
		end
	end

	post '/projects' do
		protected!
		ok, p = @db.('create_project', @client_id, params[:title], params[:description])
		if ok
			redirect to('/project/%d' % p[:id])
		else
			redirect to('/')
		end
	end

	get %r{\A/project/([1-9][0-9]{0,6})\Z} do |id|
		protected!
		ok, res = @db.call('client_owns_project', @client_id, id)
		halt(400) unless ok
		ok, @project = @db.call('get_project', id)
		halt(404) unless ok
		@pagetitle = @project[:title]
		erb :project
	end

	get %r{\A/project/([1-9][0-9]{0,6})/task/([1-9][0-9]{0,6})\Z} do |project_id, task_id|
		protected!
		ok, res = @db.call('client_owns_project', @client_id, project_id)
		halt(400) unless ok
		ok, @task = @db.call('get_project_task', project_id, task_id)
		halt(404) unless ok
		@pagetitle = @task[:title]
		erb :task
	end

	post %r{\A/project/([1-9][0-9]{0,6})\Z} do |id|
		protected!
		ok, res = @db.call('client_owns_project', @client_id, id)
		halt(400) unless ok
		ok, res = @db.call('update_project', id, params[:title], params[:description])
		redirect to('/project/%d' % id)
	end

	post %r{\A/project/([1-9][0-9]{0,6})/approve\Z} do |id|
		protected!
		ok, res = @db.call('client_owns_project', @client_id, id)
		halt(400) unless ok
		@db.call('approve_quote', id)
		redirect to('/project/%d' % id)
	end

	post %r{\A/project/([1-9][0-9]{0,6})/refuse\Z} do |id|
		protected!
		ok, res = @db.call('client_owns_project', @client_id, id)
		halt(400) unless ok
		redirect to('/project/%d' % id) unless String(params[:reason]).length > 0
		@db.call('refuse_quote', id, params[:reason])
		redirect to('/project/%d' % id)
	end

	post %r{\A/project/([1-9][0-9]{0,6})/notes\Z} do |id|
		protected!
		ok, res = @db.call('client_owns_project', @client_id, id)
		halt(400) unless ok
		ok, res = @db.call('client_project_note', @client_id, id, params[:note])
		redirect to('/project/%d' % id)
	end

	post %r{\A/project/([1-9][0-9]{0,6})/task/([1-9][0-9]{0,6})/notes\Z} do |project_id, task_id|
		protected!
		ok, res = @db.call('client_owns_project', @client_id, project_id)
		halt(400) unless ok
		ok, res = @db.call('client_task_note', @client_id, task_id, params[:note])
		redirect to('/project/%d/task/%d' % [project_id, task_id])
	end

	get %r{\A/worker/([1-9][0-9]{0,6})\Z} do |id|
		protected!
		ok, @worker = @db.call('get_worker', id)
		halt(404) unless ok
		@pagetitle = @worker[:name]
		erb :worker
	end

	get %r{\A/manager/([1-9][0-9]{0,6})\Z} do |id|
		protected!
		ok, @manager = @db.call('get_manager', id)
		halt(404) unless ok
		@pagetitle = @manager[:name]
		erb :manager
	end
end

