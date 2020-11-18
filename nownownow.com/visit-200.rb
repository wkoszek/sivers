require_relative 'init.rb'
require 'curb'

def get(url)
	Curl::Easy.perform(url) do |c|
		c.ssl_verify_peer = false
		c.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
	end
end

urls = DB.exec("SELECT id, long FROM now.urls ORDER BY id")
urls.each do |u|
	print "%d " % u['id']
	res = get(u['long'])
	unless res.status.start_with? '200'
		if(m = /\slocation:\s+(\S+)/i.match(res.head))
			new_url = m[1]
			new_res = get(new_url)
			if new_res.status.start_with? '200'
				puts "\n%s\nupdating to\n%s" % [u['long'], new_url] 
				DB.exec_params("UPDATE now.urls SET long=$1 WHERE id=$2", [new_url, u['id']])
				puts "\n"
			else
				puts "\n%s\nBAD LOCATION\n%s\n%s" % [u['long'], new_url, new_res.head]
				puts "\n"
			end
		else
			puts u['long']
			puts res.head
		end
	end
end
