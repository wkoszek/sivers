#!/usr/bin/env ruby
require 'pstore'
require 'pg'
require 'twitter'

# only run on the live machine: not test
exit unless 'sivers.org' == %x{hostname}.strip

db = PG::Connection.new(dbname: 'd50b', user: 'd50b')

logfile = '/tmp/nowprofiles.pstore'
ps = PStore.new(logfile)

unless File.exist?(logfile)
	ps.transaction do
		ps[:log] = []
	end
end

def get_url(db)
	res = db.exec("SELECT p.id, p.public_id, p.name,
		regexp_replace(u.url, 'http.*twitter.com/', '') AS twitter FROM peeps.stats s
		JOIN now.urls n ON s.person_id=n.person_id
		JOIN peeps.people p ON s.person_id=p.id
		LEFT JOIN peeps.urls u ON (s.person_id=u.person_id AND u.url LIKE '%twitter.com/%')
		WHERE p.city IS NOT NULL AND p.country IS NOT NULL AND 5 =
			(SELECT COUNT(*) FROM peeps.stats WHERE person_id=p.id AND statkey IN
				('now-title', 'now-liner', 'now-why', 'now-thought', 'now-red')
			AND LENGTH(statvalue) > 1)
		ORDER BY RANDOM() LIMIT 1")
	[res[0]['id'].to_i, res[0]['public_id'], res[0]['name'], res[0]['twitter']]
end

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
	# get a URL until I find one not in recent log
	begin
		id, public_id, name, twitter = get_url(db)
	end while (ps[:log].map {|x| x[:id]}.include? id)
	# make the tweet text
	tweet = '%s profile: http://nownownow.com/p/%s' % [name, public_id]
	if String(twitter).size > 0
		tweet << ' @%s' % twitter
	end
	# tweet it!
	tw.update tweet
	# log it
	ps[:log] << {id: id, profile: public_id, when: Time.now()}
end

