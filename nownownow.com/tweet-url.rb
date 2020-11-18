#!/usr/bin/env ruby
require 'pstore'
require 'pg'
require 'twitter'

# only run on the live machine: not test
exit unless 'sivers.org' == %x{hostname}.strip

db = PG::Connection.new(dbname: 'd50b', user: 'd50b')

# log file is used to make sure that random tweeting doesn't repeat
# someone recently tweeted
logfile = '/tmp/nowtweets.pstore'
ps = PStore.new(logfile)
unless File.exist?(logfile)
	ps.transaction do
		ps[:log] = []
		ps[:log] << {id: 155, url: 'http://sivers.org/now', when: '2015-11-01 18:56:57 -0800'}
	end
end

# get array of ids that have been tweeted
ids_tweeted =	ps.transaction(true) do
	ps[:log].map {|x| x[:id]}
end

# turn into a string to tell query not these
notstring = ids_tweeted.join(',')

# get a random now.url whose person has a twitter URL
qry = "SELECT u.id, long,
	regexp_replace(p.url, 'http.*twitter.com/', '') AS twitter
	FROM now.urls u INNER JOIN peeps.urls p
		ON (u.person_id=p.person_id AND p.url LIKE '%twitter.com/%')
	WHERE u.id NOT IN (#{notstring})
	AND long IS NOT NULL ORDER BY RANDOM() LIMIT 1"
res = db.exec(qry)
raise 'none left' unless res.ntuples == 1
id = res[0]['id'].to_i
url = res[0]['long']
twitter = res[0]['twitter']

# configs to connect to Twitter client
ck = db.exec("SELECT v FROM core.configs WHERE k='twitter.nownownow.ck'")[0]['v']
cs = db.exec("SELECT v FROM core.configs WHERE k='twitter.nownownow.cs'")[0]['v']
at = db.exec("SELECT v FROM core.configs WHERE k='twitter.nownownow.at'")[0]['v']
as = db.exec("SELECT v FROM core.configs WHERE k='twitter.nownownow.as'")[0]['v']
tw = Twitter::REST::Client.new do |config|
	config.consumer_key = ck
	config.consumer_secret = cs
	config.access_token = at
	config.access_token_secret = as
end

# open up log to prepare to log it
ps.transaction do
	# make the tweet text
	tweet = 'Now: %s by @%s' % [url, twitter]
	# show it
	puts tweet
	# tweet it!
	tw.update tweet
	# log it
	ps[:log] << {id: id, url: url, when: Time.now()}
end

