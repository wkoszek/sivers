P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class MuckworkAPITest < Minitest::Test
	include JDB
	
	def setup
		# EXAMPLES OF VIEWS
		@project_view_1 = {id: 1,
			title: 'Finished project',
			description: 'by Wonka for Charlie',
			created_at: '2015-07-02T00:34:56+12:00',
			quoted_at: '2015-07-03T00:34:56+12:00',
			approved_at: '2015-07-04T00:34:56+12:00',
			started_at: '2015-07-05T00:34:56+12:00',
			finished_at: '2015-07-05T03:34:56+12:00',
			progress: 'finished',
			client: {id: 1,
				name: 'Willy Wonka',
				email: 'willy@wonka.com'},
			quoted_ratetype: 'time',
			quoted_money: {currency: 'USD', amount: 50},
			final_money: {currency: 'USD', amount: 45.36}}
		@project_detail_view_1 = {id: 1,
			title: 'Finished project',
			description: 'by Wonka for Charlie',
			created_at: '2015-07-02T00:34:56+12:00',
			quoted_at: '2015-07-03T00:34:56+12:00',
			approved_at: '2015-07-04T00:34:56+12:00',
			started_at: '2015-07-05T00:34:56+12:00',
			finished_at: '2015-07-05T03:34:56+12:00',
			progress: 'finished',
			client: {id: 1,
				name: 'Willy Wonka',
				email: 'willy@wonka.com'},
			quoted_ratetype: 'time',
			quoted_money: {currency: 'USD', amount: 50},
			final_money: {currency: 'USD', amount: 45.36},
			tasks: [
				{id: 2,
				project_id: 1,
				worker_id: 1,
				sortid: 1,
				title: 'first task',
				description: 'clean hands',
				created_at: '2015-07-03T00:34:56+12:00',
				claimed_at: '2015-07-04T00:34:56+12:00',
				started_at: '2015-07-05T00:34:56+12:00',
				finished_at: '2015-07-05T00:35:56+12:00',
				progress: 'finished',
				worker: {id: 1,
					name: 'Charlie Buckets',
					email: 'charlie@bucket.org'}},
				{id: 1,
				project_id: 1,
				worker_id: 1,
				sortid: 2,
				title: 'second task',
				description: 'get bucket',
				created_at: '2015-07-03T00:34:56+12:00',
				claimed_at: '2015-07-04T00:34:56+12:00',
				started_at: '2015-07-05T00:35:56+12:00',
				finished_at: '2015-07-05T00:36:56+12:00',
				progress: 'finished',
				worker: {id: 1,
					name: 'Charlie Buckets',
					email: 'charlie@bucket.org'}},
				{id: 3,
				project_id: 1,
				worker_id: 1,
				sortid: 3,
				title: 'third task',
				description: 'clean tank',
				created_at: '2015-07-03T00:34:56+12:00',
				claimed_at: '2015-07-04T00:34:56+12:00',
				started_at: '2015-07-05T00:36:56+12:00',
				finished_at: '2015-07-05T03:34:56+12:00',
				progress: 'finished',
				worker: {id: 1,
					name: 'Charlie Buckets',
					email: 'charlie@bucket.org'}}
			],
			notes: [{id: 1,
				note: 'great job, Charlie!',
				created_at: '2015-07-07T12:34:56+12:00',
				project_id: 1,
				task_id: 1,
				manager: nil,
				client: {id: 1, name: 'Willy Wonka'},
				worker: nil},
				{id: 2,
				note: 'thank you sir',
				created_at: '2015-07-07T12:45:56+12:00',
				project_id: 1,
				task_id: 1,
				manager: nil,
				client: nil,
				worker: {id: 1, name: 'Charlie Buckets'}}]}
		@task_view_1 = {id: 1,
			project_id: 1,
			worker_id: 1,
			sortid: 2,
			title: 'second task',
			description: 'get bucket',
			created_at: '2015-07-03T00:34:56+12:00',
			claimed_at: '2015-07-04T00:34:56+12:00',
			started_at: '2015-07-05T00:35:56+12:00',
			finished_at: '2015-07-05T00:36:56+12:00',
			progress: 'finished',
			project: {id: 1,
				title: 'Finished project',
				description: 'by Wonka for Charlie'},
			worker: {id: 1,
				name: 'Charlie Buckets',
				email: 'charlie@bucket.org'},
			notes: [{id: 1,
				note: 'great job, Charlie!',
				created_at: '2015-07-07T12:34:56+12:00',
				project_id: 1,
				task_id: 1,
				manager: nil,
				client: {id: 1, name: 'Willy Wonka'},
				worker: nil},
				{id: 2,
				note: 'thank you sir',
				created_at: '2015-07-07T12:45:56+12:00',
				project_id: 1,
				task_id: 1,
				manager: nil,
				client: nil,
				worker: {id: 1, name: 'Charlie Buckets'}}]}
		super
	end

	def test_auth_client
		qry("muckwork.auth_client($1, $2)", ['derek@sivers.org', 'derek'])
		assert_equal({}, @j)
		qry("muckwork.auth_client($1, $2)", ['willy@wonka.com', 'willy'])
		assert_equal({client_id: 1, person_id: 2}, @j)
		qry("muckwork.auth_client($1, $2)", ['veruca@salt.com', 'veruca'])
		assert_equal({client_id: 2, person_id: 3}, @j)
	end

	def test_auth_worker
		qry("muckwork.auth_worker($1, $2)", ['derek@sivers.org', 'derek'])
		assert_equal({}, @j)
		qry("muckwork.auth_worker($1, $2)", ['charlie@bucket.org', 'charlie'])
		assert_equal({worker_id: 1, person_id: 4}, @j)
		qry("muckwork.auth_worker($1, $2)", ['oompa@loompa.mm', 'oompa'])
		assert_equal({worker_id: 2, person_id: 5}, @j)
	end

	def test_auth_manager
		qry("muckwork.auth_manager($1, $2)", ['derek@sivers.org', 'derek'])
		assert_equal({manager_id: 1, person_id: 1}, @j)
		qry("muckwork.auth_manager($1, $2)", ['willy@wonka.com', 'willy'])
		assert_equal({}, @j)
		qry("muckwork.auth_manager($1, $2)", ['this@that.com', 'abcde'])
		assert_equal({}, @j)
	end

	def test_client_owns_project
		qry("muckwork.client_owns_project(1, 1)")
		assert_equal({ok: true}, @j)
		qry("muckwork.client_owns_project(2, 1)")
		assert_equal({ok: false}, @j)
		qry("muckwork.client_owns_project(2, 2)")
		assert_equal({ok: true}, @j)
		qry("muckwork.client_owns_project(9, 99)")
		assert_equal({ok: false}, @j)
	end

	def test_worker_owns_task
		qry("muckwork.worker_owns_task(1, 1)")
		assert_equal({ok: true}, @j)
		qry("muckwork.worker_owns_task(2, 1)")
		assert_equal({ok: false}, @j)
		qry("muckwork.worker_owns_task(2, 4)")
		assert_equal({ok: true}, @j)
		qry("muckwork.worker_owns_task(2, 99)")
		assert_equal({ok: false}, @j)
	end

	def test_project_has_progress
		qry("muckwork.project_has_progress(4, 'quoted')")
		assert_equal({ok: true}, @j)
		qry("muckwork.project_has_progress(5, 'created')")
		assert_equal({ok: true}, @j)
		qry("muckwork.project_has_progress(1, 'poop')")
		assert_equal({ok: false}, @j)
		qry("muckwork.project_has_progress(99, 'started')")
		assert_equal({ok: false}, @j)
	end

	def test_task_has_progress
		qry("muckwork.task_has_progress(10, 'quoted')")
		assert_equal({ok: true}, @j)
		qry("muckwork.task_has_progress(9, 'approved')")
		assert_equal({ok: true}, @j)
		qry("muckwork.task_has_progress(1, 'poop')")
		assert_equal({ok: false}, @j)
		qry("muckwork.task_has_progress(99, 'started')")
		assert_equal({ok: false}, @j)
	end

	def test_get_managers
		qry("muckwork.get_managers()")
		r = [{id:1, person_id:1, name:'Derek Sivers', email:'derek@sivers.org'}]
		assert_equal r, @j
	end

	def test_get_manager
		qry("muckwork.get_manager(1)")
		r = {id:1, person_id:1, name:'Derek Sivers', email:'derek@sivers.org', address:'Derek', company:'50POP LLC', city:'Singapore', state:nil, country:'SG', phone:'+65 1234 5678'}
		assert_equal r, @j
		qry("muckwork.get_manager(99)")
		assert_equal({}, @j)
	end

	def test_get_clients
		qry("muckwork.get_clients()")
		r = [
			{:id=>2, :person_id=>3, :currency=>'GBP', :name=>'Veruca Salt', :email=>'veruca@salt.com'},
			{:id=>1, :person_id=>2, :currency=>'USD', :name=>'Willy Wonka', :email=>'willy@wonka.com'}]
		assert_equal r, @j
	end

	def test_get_client
		qry("muckwork.get_client(2)")
		r = {:id=>2, :person_id=>3, :currency=>'GBP', :name=>'Veruca Salt', :email=>'veruca@salt.com', :address=>'Veruca', :company=>'Daddy Empires Ltd', :city=>'London', :state=>'England', :country=>'GB', :phone=>'+44 9273 7231', :balance=>{currency: 'GBP', amount:100}}
		assert_equal r, @j
		qry("muckwork.get_client(99)")
		assert_equal({}, @j)
	end

	def test_create_client
		qry("muckwork.create_client(2)")
		assert_equal({client_id: 1, person_id: 2}, @j)
		qry("muckwork.create_client(8)")
		assert_equal({client_id: 3, person_id: 8}, @j)
		qry("muckwork.create_client(99)")
		assert @j[:message].include? 'violates foreign key'
	end

	def test_update_client
		up = {currency: 'EUR', name: 'Veruca Darling', country: 'BE'}
		qry("muckwork.update_client(2, $1)", [up.to_json])
		r = {:id=>2, :person_id=>3, :currency=>'EUR', :name=>'Veruca Darling', :email=>'veruca@salt.com', :address=>'Veruca', :company=>'Daddy Empires Ltd', :city=>'London', :state=>'England', :country=>'BE', :phone=>'+44 9273 7231', :balance=>{:currency=>'EUR', :amount=>136.07}}
		assert_equal r, @j
		qry("muckwork.update_client(99, $1)", [up.to_json])
		assert_equal({}, @j)
	end

	def test_get_workers
		qry("muckwork.get_workers()")
		r = [
			{id:3, person_id:7, hourly_rate:{currency:'CNY',amount:65}, name:'巩俐', email:'gong@li.cn'},
			{id:2, person_id:5, hourly_rate:{currency:'THB',amount:350}, name:'Oompa Loompa', email:'oompa@loompa.mm'},
			{id:1, person_id:4, hourly_rate:{currency:'USD',amount:15}, name:'Charlie Buckets', email:'charlie@bucket.org'}]
		assert_equal r, @j
	end

	def test_get_worker
		qry("muckwork.get_worker(2)")
		r = {:id=>2, :person_id=>5, hourly_rate:{currency:'THB',amount:350}, :name=>'Oompa Loompa', :email=>'oompa@loompa.mm', :address=>'Oompa Loompa', :company=>nil, :city=>'Hershey', :state=>'PA', :country=>'US', :phone=>nil}
		assert_equal r, @j
		qry("muckwork.get_worker(99)")
		assert_equal({}, @j)
	end

	def test_create_worker
		qry("muckwork.create_worker(8)")
		r = {:id=>4, :person_id=>8, :hourly_rate => {currency:'USD',amount:10}, :name=>'Yoko Ono', :email=>'yoko@ono.com', :address=>'Ono-San', :company=>'yoko@lennon.com', :city=>'Tokyo', :state=>nil, :country=>'JP', :phone=>nil}
		assert_equal r, @j
		qry("muckwork.create_worker(99)")
		assert @j[:message].include? 'violates foreign key'
	end

	def test_update_worker
		up = {name: 'Oompa Wow', email: 'oompa@loom.pa', company: 'cash', id: 919191}
		qry("muckwork.update_worker(2, $1)", [up.to_json])
		r = {:id=>2, :person_id=>5, :hourly_rate=>{currency:'THB',amount:350}, :name=>'Oompa Wow', :email=>'oompa@loom.pa', :address=>'Oompa Loompa', :company=>'cash', :city=>'Hershey', :state=>'PA', :country=>'US', :phone=>nil}
		assert_equal r, @j
		qry("muckwork.update_worker(99, $1)", [up.to_json])
		assert_equal({}, @j)
	end

	def test_get_projects
		qry("muckwork.get_projects()")
		assert_equal 5, @j.size
		assert_equal [5,4,3,2,1], @j.map {|p| p[:id]}
	end

	def test_client_get_projects
		qry("muckwork.client_get_projects(2)")
		assert_equal [4,2], @j.map {|p| p[:id]}
	end

	def test_get_projects_with_progress
		qry("muckwork.get_projects_with_progress('finished')")
		assert_equal 1, @j.size
		assert_equal @project_view_1, @j[0]
		qry("muckwork.get_projects_with_progress('poop')")
		assert_equal [], @j
	end

	def test_get_tasks_with_progress
		qry("muckwork.get_tasks_with_progress('started')")
		assert_equal 1, @j.size
		assert_equal 5, @j[0][:id]
		assert_equal 'started', @j[0][:progress]
		assert_equal 'Oompa Loompa', @j[0][:worker][:name]
		qry("muckwork.get_tasks_with_progress('poop')")
		assert_equal [], @j
	end

	def test_get_project
		qry("muckwork.get_project(1)")
		assert_equal @project_detail_view_1, @j
	end

	def test_create_project
		qry("muckwork.create_project(2, 'a title', 'a description')")
		assert_equal 6, @j[:id]
		assert_equal 'a title', @j[:title]
		assert_equal 'a description', @j[:description]
		assert_equal 'Veruca Salt', @j[:client][:name]
		assert_equal 'created', @j[:progress]
	end

	def test_update_project
		qry("muckwork.update_project(5, 'new title', 'new description')")
		assert_equal 'new title', @j[:title]
		assert_equal 'new description', @j[:description]
	end

	def test_quote_project
		qry("muckwork.quote_project(5, 'time', 'USD', 1000)")
		assert_equal 'quoted', @j[:progress]
		assert_equal 'time', @j[:quoted_ratetype]
		assert_equal 'USD', @j[:quoted_money][:currency]
		assert_equal 1000, @j[:quoted_money][:amount]
	end

	def test_approve_quote
		qry("muckwork.approve_quote(4)")
		assert_equal 'approved', @j[:progress]
		assert_match /^20[0-9][0-9]-/, @j[:approved_at]
	end

	def test_refuse_quote
		qry("muckwork.refuse_quote(1, 'nah')")
		assert_equal({}, @j)
		qry("muckwork.refuse_quote(9, 'nah')")
		assert_equal({}, @j)
		qry("muckwork.refuse_quote(4, 'nah')")
		assert_equal 6, @j[:id]
		assert_equal 'nah', @j[:note]
		assert_match /\A20[0-9]{2}-[0-9]{2}/, @j[:created_at]
		assert_equal 4, @j[:project_id]
		assert_equal 2, @j[:client_id]
		qry("muckwork.get_project(4)")
		assert_equal 'refused', @j[:progress]
	end

	def test_get_task
		qry("muckwork.get_task(1)")
		assert_equal @task_view_1, @j
	end

	def test_get_project_task
		qry("muckwork.get_project_task(1, 1)")
		assert_equal @task_view_1, @j
		qry("muckwork.get_project_task(2, 1)")
		assert_equal({}, @j)
	end

	def test_create_task
		qry("muckwork.create_task(5, '1 title', 'a description', NULL)")
		assert_equal 1, @j[:sortid]
		assert_equal 'Unquoted project', @j[:project][:title]
		qry("muckwork.create_task(5, '3 title', 'c description', 3)")
		assert_equal 3, @j[:sortid]
		assert_equal 'c description', @j[:description]
		qry("muckwork.create_task(5, '2 title', 'b description', 2)")
		assert_equal 2, @j[:sortid]
		qry("muckwork.create_task(5, '4 title', 'd description', NULL)")
		assert_equal 4, @j[:sortid]
	end

	def test_update_task
		qry("muckwork.update_task(12, 'nu title', 'nu description', 1)")
		assert_equal 1, @j[:sortid]
		assert_equal 'nu title', @j[:title]
		assert_equal 'nu description', @j[:description]
	end

	def test_claim_task
		qry("muckwork.claim_task(7, 1)")
		assert_equal 'Charlie Buckets', @j[:worker][:name]
		assert_equal 'approved', @j[:progress]  # 'claimed' is not a progress
		assert_match /^20[0-9][0-9]-/, @j[:claimed_at]
	end

	def test_unclaim_task
		qry("muckwork.unclaim_task(8)")
		assert_nil @j[:worker]
		assert_nil @j[:claimed_at]
		assert_equal 'approved', @j[:progress]
	end

	def test_start_task
		qry("muckwork.start_task(6)")
		assert_equal 'started', @j[:progress]
		assert_match /^20[0-9][0-9]-/, @j[:started_at]
	end

	def test_finish_task
		qry("muckwork.start_task(6)")
		qry("muckwork.finish_task(6)")
		assert_equal 'finished', @j[:progress]
		assert_match /^20[0-9][0-9]-/, @j[:finished_at]
	end

	def test_worker_get_tasks
		qry("muckwork.worker_get_tasks(1)")
		assert_equal [3, 2, 1], @j.map {|x| x[:id]}
		qry("muckwork.worker_get_tasks(99)")
		assert_equal [], @j
	end

	def test_next_available_tasks
		qry("muckwork.next_available_tasks()")
		assert_equal [7], @j.map {|x| x[:id]}
		qry("muckwork.approve_quote(4)")
		qry("muckwork.next_available_tasks()")
		assert_equal [7,12], @j.map {|x| x[:id]}
		assert_equal 'by Wonka', @j[0][:project][:description]
		qry("muckwork.claim_task(7, 1)")
		qry("muckwork.next_available_tasks()")
		assert_equal [8,12], @j.map {|x| x[:id]}
	end

	def test_manager_project_note
		qry("muckwork.manager_project_note(1, 2, 'yup')")
		assert_equal 6, @j[:id]
		assert_equal 2, @j[:project_id]
		assert_equal 1, @j[:manager_id]
		assert_equal 'yup', @j[:note]
		assert_nil @j[:task_id]
		assert_nil @j[:worker_id]
		assert_nil @j[:client_id]
	end

	def test_manager_task_note
		qry("muckwork.manager_task_note(1, 5, 'yup')")
		assert_equal 6, @j[:id]
		assert_equal 2, @j[:project_id]
		assert_equal 5, @j[:task_id]
		assert_equal 1, @j[:manager_id]
		assert_equal 'yup', @j[:note]
		assert_nil @j[:worker_id]
		assert_nil @j[:client_id]
	end

	def test_client_project_note
		qry("muckwork.client_project_note(2, 2, 'yup')")
		assert_equal 6, @j[:id]
		assert_equal 2, @j[:project_id]
		assert_equal 2, @j[:client_id]
		assert_equal 'yup', @j[:note]
		assert_nil @j[:task_id]
		assert_nil @j[:worker_id]
		assert_nil @j[:manager_id]
	end

	def test_client_task_note
		qry("muckwork.client_task_note(2, 5, 'yup')")
		assert_equal 6, @j[:id]
		assert_equal 2, @j[:project_id]
		assert_equal 5, @j[:task_id]
		assert_equal 2, @j[:client_id]
		assert_equal 'yup', @j[:note]
		assert_nil @j[:worker_id]
		assert_nil @j[:manager_id]
	end

	def test_worker_project_note
		qry("muckwork.worker_project_note(2, 2, 'yup')")
		assert_equal 6, @j[:id]
		assert_equal 2, @j[:project_id]
		assert_equal 2, @j[:worker_id]
		assert_equal 'yup', @j[:note]
		assert_nil @j[:task_id]
		assert_nil @j[:client_id]
		assert_nil @j[:manager_id]
	end

	def test_worker_task_note
		qry("muckwork.worker_task_note(2, 5, 'yup')")
		assert_equal 6, @j[:id]
		assert_equal 2, @j[:project_id]
		assert_equal 5, @j[:task_id]
		assert_equal 2, @j[:worker_id]
		assert_equal 'yup', @j[:note]
		assert_nil @j[:client_id]
		assert_nil @j[:manager_id]
	end

	def test_client_payments
		c = {id: 'someId', details: 'someDetails'}
		qry('muckwork.add_client_payment($1, $2, $3, $4)', [1, 'EUR', 12.34, c.to_json])
		assert_equal({id: 3}, @j)
		qry('muckwork.client_payments(1)')
		assert_equal 2, @j.size
		p = @j.pop
		assert_equal(c.to_json, p[:notes])
		assert_equal(12.34, p[:money][:amount])
		assert_equal('EUR', p[:money][:currency])
	end
end

