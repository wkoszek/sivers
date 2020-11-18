#!/usr/bin/env ruby
## USAGE apidoc.rb
## READS api.sql
## CREATES api.data

copying = false

File.open('api.data', 'w') do |f|
	File.readlines('api.sql').each do |line|
		line.strip!
		copying = true if line == '--Route{'
		if copying
			f.puts line[2..-1]
		end
		copying = false if line == '--}'
	end
end

puts "see api.data"
