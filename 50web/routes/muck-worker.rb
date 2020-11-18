LIVETEST = 'test'
LOG = 'muckw'
require_relative 'bureau'
MDB = getdb('muckwork', LIVETEST)

class MuckWorkerWeb < Bureau

	configure do
		set :views, '/var/www/htdocs/50web/views/muck-worker'
	end

	before do
		if authorize!
			ok, @worker = MDB.call('get_worker', @auth_id)
			@worker_id = @auth_id
		end
	end

	get '/' do
		@pagetitle = 'Muckwork'
		@grouped_tasks = {}
		ok, res = MDB.call('worker_get_tasks', @worker_id)
		res.each do |t|
			@grouped_tasks[t[:status]] ||= []
			@grouped_tasks[t[:status]] << t
		end
		# only show available tasks if they have no started/approved tasks
		@available = false
		if [] == (%w(started approved) & @grouped_tasks.keys)
			ok, @available = MDB.call('next_available_tasks')
		end
		erb :home
	end

	get '/account' do
		@pagetitle = @worker[:name] + ' ACCOUNT'
		ok, @locations = PDB.call('all_countries')
		db2 = getdb_noschema(LIVETEST)
		ok, @currencies = db2.call('core.all_currencies')
		erb :account
	end

	post '/account' do
		filtered = params.reject {|k,v| k == :person_id}
		MDB.call('update_worker', @worker_id, filtered.to_json)
		redirect to('/account?msg=updated')
	end

	post '/password' do
		PDB.call('set_password', @person_id, params[:password])
		redirect to('/account?msg=newpass')
	end

	post %r{\A/claim/([1-9][0-9]{0,6})\Z} do |task_id|
		ok, res = MDB.call('claim_task', task_id, @worker_id)
		if ok
			redirect to("/task/#{task_id}")
		else
			redirect to('/?msg=claimfail')
		end
	end

	get %r{\A/task/([1-9][0-9]{0,6})\Z} do |task_id|
		ok, res = MDB.call('worker_owns_task', @worker_id, task_id)
		halt(400) unless ok
		ok, @task = MDB.call('get_task', task_id)
		halt(404) unless ok
		@pagetitle = "TASK %d : %s" % [task_id, @task[:title]]
		erb :task
	end

	post %r{\A/unclaim/([1-9][0-9]{0,6})\Z} do |task_id|
		ok, res = MDB.call('worker_owns_task', @worker_id, task_id)
		halt(400) unless ok
		ok, res = MDB.call('unclaim_task', task_id)
		if ok
			redirect to('/')
		else
			redirect to("/task/#{task_id}?msg=unclaimfail")
		end
	end

	post %r{\A/start/([1-9][0-9]{0,6})\Z} do |task_id|
		ok, res = MDB.call('worker_owns_task', @worker_id, task_id)
		halt(400) unless ok
		ok, res = MDB.call('start_task', task_id)
		if ok
			redirect to("/task/#{task_id}")
		else
			redirect to("/task/#{task_id}?msg=startfail")
		end
	end

	post %r{\A/finish/([1-9][0-9]{0,6})\Z} do |task_id|
		ok, res = MDB.call('worker_owns_task', @worker_id, task_id)
		halt(400) unless ok
		ok, res = MDB.call('finish_task', task_id)
		if ok
			redirect to('/')
		else
			redirect to("/task/#{task_id}?msg=finishfail")
		end
	end

	post %r{\A/task/([1-9][0-9]{0,6})/notes\Z} do |task_id|
		ok, res = MDB.call('worker_owns_task', @worker_id, task_id)
		halt(400) unless ok
		ok, res = MDB.call('worker_task_note', @worker_id, task_id, params[:note])
		redirect to("/task/#{task_id}")
	end

end

