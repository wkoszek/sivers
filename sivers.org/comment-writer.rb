#!/usr/bin/env ruby
require 'pg'
require_relative 'comment-functions.rb'

DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')

dirname = File.expand_path('../../sivers_comments', __FILE__) << '/'
Dir.mkdir(dirname, 0755) unless Dir.exist?(dirname)

# first write them all
DB.exec("SELECT DISTINCT(uri) FROM sivers.comments").column_values(0).each do |uri|
	File.open(dirname + uri, 'w') do |f|
		f.puts qry(DB, uri)
	end
end

# now listen and wait
DB.exec("LISTEN comments_changed")

while true do
	DB.wait_for_notify do |event, pid, uri|
		File.open(dirname + uri, 'w') do |f|
			f.puts qry(DB, uri)
		end
	end
end


