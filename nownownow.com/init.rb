require 'erb'
require 'pg'

DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')
ROOTDIR = '/var/www/htdocs/nownownow.com/'

def h(str)
	ERB::Util.html_escape(str)
end

def autolink(str)
	str.gsub(/(http\S*)/, '<a href="\1">\1</a>')
end

