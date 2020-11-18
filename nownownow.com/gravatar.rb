require_relative 'init.rb'
require 'digest/md5'
require 'net/http'

# https://secure.gravatar.com/site/implement/images/

# get Gravatars for those who don't have one on file yet

def update_gravatar
	res = DB.exec("SELECT id, email FROM peeps.people
		WHERE id IN (SELECT person_id FROM now.urls)
		AND id NOT IN (SELECT person_id FROM peeps.stats WHERE statkey='gravatar')
		ORDER BY id")
	res.each do |r|
		id = r['id']
		email = r['email']
		hash = Digest::MD5.hexdigest(email)
		print "%d\t%s\t%s\t" % [id, hash, email]
		url = 'http://www.gravatar.com/avatar/%s?d=404' % hash
		res = Net::HTTP.get_response(URI(url))
		if res.code == '200'
			DB.exec_params("INSERT INTO peeps.stats(person_id, statkey, statvalue)
				VALUES ($1, 'gravatar', $2)", [id, hash])
			puts "YEP!"
		elsif res.code == '404'
			puts "NOPE!"
		else
			puts "WTF?!?"
		end
	end
end

if __FILE__ == $0
	update_gravatar
end

