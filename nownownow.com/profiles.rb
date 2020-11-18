# make profile pages

require_relative 'init.rb'

template = File.read(ROOTDIR + 'templates/profile.erb')
@shuffle = File.read(ROOTDIR + 'templates/shuffle.js')

# get everyone with profile and gravatar, used for further browsing in each
@profiles = DB.exec("SELECT p.public_id, p.name, u.short, u.long,
	s1.statvalue AS gravatar, 
	s2.statvalue AS subtitle
	FROM now.urls u
	JOIN peeps.people p ON u.person_id=p.id
	JOIN peeps.stats s1 ON (u.person_id=s1.person_id AND s1.statkey='gravatar')
	JOIN peeps.stats s2 ON (u.person_id=s2.person_id AND s2.statkey='now-liner')
	WHERE city IS NOT NULL
	AND country IS NOT NULL
	AND 6 = (
		SELECT COUNT(*) FROM peeps.stats
		WHERE person_id=p.id
		AND statkey IN
		('gravatar', 'now-title', 'now-liner', 'now-why', 'now-thought', 'now-red')
		AND LENGTH(statvalue) > 1)
	ORDER BY u.id")

# everyone who's answered all profile questions, and has a location
res = DB.exec("SELECT id FROM peeps.people p
	WHERE city IS NOT NULL
	AND country IS NOT NULL
	AND 5 = (
		SELECT COUNT(*) FROM peeps.stats
		WHERE person_id=p.id
		AND statkey IN
		('now-title', 'now-liner', 'now-why', 'now-thought', 'now-red')
		AND LENGTH(statvalue) > 1)
	ORDER BY id")
res.map{|r| r['id']}.each do |person_id|
	puts person_id

	# get person info
	res = DB.exec("SELECT p.public_id, p.name, p.city, p.state, c.name AS country
		FROM peeps.people p
		JOIN peeps.countries c ON p.country=c.code
		WHERE id=#{person_id}")
	@person = res[0]

	# get profile answers
	res = DB.exec("SELECT statkey, statvalue FROM peeps.stats
		WHERE person_id=#{person_id}
		AND statkey LIKE 'now-%'")
	@profile = {}
	res.each do |r|
		# save in hash skipping the "now-" part of key: liner, red, thought, title, why
		@profile[r['statkey'][4..-1]] = r['statvalue']
	end

	# get Gravatar or false
	res = DB.exec("SELECT statvalue FROM peeps.stats
		WHERE person_id=#{person_id}
		AND statkey='gravatar'")
	if res.ntuples < 1
		@image = false
	else
		@image = 'http://www.gravatar.com/avatar/' + res[0]['statvalue']
	end
	
	# get other urls
	res = DB.exec("SELECT url FROM peeps.urls
		WHERE person_id=#{person_id}
		AND url NOT LIKE '%www.cdbaby.com%'
		ORDER BY main DESC NULLS LAST, id")
	@urls = res.map{|r| r['url']}

	# get now.urls  (usually 1-to-1 but sometimes a person has more than 1)
	@nows = DB.exec("SELECT short, long FROM now.urls WHERE person_id=#{person_id}")

	# merge into template, saving as public_id
	File.open(ROOTDIR + 'site/p/' + @person['public_id'], 'w') do |f|
		f.puts ERB.new(template, nil, '-').result
	end
end

