# write an updated index.html

require_relative 'init.rb'

@profiles_with_image = []
@profiles_without_image = []
@urls_with_image = []
@urls_without_image = []

res = DB.exec("SELECT p.public_id, p.name, u.short, u.long,
	s1.statvalue AS gravatar,
	s2.statvalue AS subtitle
	FROM now.urls u
	JOIN peeps.people p ON u.person_id=p.id
	LEFT JOIN peeps.stats s1 ON (u.person_id=s1.person_id AND s1.statkey='gravatar')
	LEFT JOIN peeps.stats s2 ON (u.person_id=s2.person_id AND s2.statkey='now-liner')
	WHERE u.long IS NOT NULL
	ORDER BY u.id")
@total = res.ntuples

res.each do |r|
	if r['short'].size > 25
		r['short'] = r['short'][0..25] + '…'
	end
	url = {name: r['name'], short: r['short'], long: r['long']}
	if File.exist?(ROOTDIR + 'site/p/' + r['public_id'])
		url.merge!(public_id: r['public_id'], subtitle: r['subtitle'])
		if String(r['gravatar']).size > 0
			@profiles_with_image << url.merge(gravatar: r['gravatar'])
		else
			@profiles_without_image << url
		end
	elsif String(r['gravatar']).size > 0
		@urls_with_image << url.merge(gravatar: r['gravatar'])
	else
		@urls_without_image << url
	end
end

# yeah, there's certainly a better way to do this
@js1 = File.read(ROOTDIR + 'templates/shuffle.js').gsub('shuffle', 'shuffle1')
@js2 = File.read(ROOTDIR + 'templates/shuffle.js').gsub('shuffle', 'shuffle2')
@js3 = File.read(ROOTDIR + 'templates/shuffle.js').gsub('shuffle', 'shuffle3')
@js4 = File.read(ROOTDIR + 'templates/shuffle.js').gsub('shuffle', 'shuffle4')

File.open('site/index.html', 'w') do |f|
	f.puts ERB.new(File.read(ROOTDIR + 'templates/index.erb'), nil, '>').result
end

File.open('site/rss.xml', 'w') do |f|
	f.puts ERB.new(File.read(ROOTDIR + 'templates/rss.erb'), nil, '>').result
end

