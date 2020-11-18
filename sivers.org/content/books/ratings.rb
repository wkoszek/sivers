#!/usr/bin/env ruby
# script to bump up/down the rating for ALL books

# this regexp gets the integer from the ratings line in the text file
reg = %r{RATING: ([0-9]+)}

# go through all book notes files
Dir['20*'].each do |filename|

	# get all lines of the file, to use for re-writing at end
	all_lines = File.readlines(filename)

	# RATING is always on the 3rd line, then use that regexp to match
	m = reg.match(all_lines[2])

	# subtract 1 from ratings, but don't go below 0
	new_rating = [0, m[1].to_i - 1].max

	# replace old with new rating
	all_lines[2] = "RATING: #{new_rating}\n"
	
	# write the new file
	File.open(filename, 'w') {|f| f.puts all_lines.join('') }
end
