require_relative 'init.rb'
require 'curb'
require 'digest/md5'

def hash(url)
	res = Curl::Easy.perform(url) do |c|
		c.ssl_verify_peer = false
		c.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
	end
	Digest::MD5.hexdigest(res.body)
end

res = DB.exec("SELECT id, long, hash FROM now.urls WHERE id > 506 ORDER BY id")
res.each do |r|
	print "%d\t%s\t%s\t" % [r['id'], r['hash'], r['long']]
	md5 = hash(r['long'])
	if md5 == r['hash']
		puts "SAME"
	else
		puts "NEW"
		DB.exec_params("UPDATE now.urls SET hash=$1, updated_at=NOW() WHERE id=$2", [md5, r['id']])
	end
end
