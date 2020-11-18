LIVETEST = 'test'
LOG = 'muckm'
require_relative 'bureau'
MDB = getdb('muckwork', LIVETEST)

class MuckManagerWeb < Bureau

	configure do
		set :views, '/var/www/htdocs/50web/views/muck-manager'
	end

	before do
		if authorize!
			ok, @manager = MDB.call('get_manager', @auth_id)
		end
	end

	get '/' do
		#TODO get projects: unstarted, unquoted, unfinished
		#TODO get tasks: unstarted, unquoted, unfinished
		@pagetitle = 'Muckwork Manager'
		erb :home
	end

end
