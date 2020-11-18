# toc.rb = Table of Contents for books
# The values are URIs from sivers.org
# For example, itunes = sivers.org/itunes

AYW = %w(ayw1 ayw2 ayw3 ayw4 ayw5 ayw6 hitswitch hellyeah changeplan nofund startnow multiply formalities blc exclude2 noads more-than-one noplan the-mob grade caremore dontneed punish real unclear cdbe cdbf casual nq double being itunes mistake delegate ayw7 trustbut abdicate done trust ayw8)

MusicBook = [
	{"Before we begin" => %w(
		mym1
	)},
	{"It’s just people" => %w(
		people1
		syk
		mosquito
		persistence
		hych
		gpers
		favors
		smgf
	)},
	{"It’s just a game" => %w(
		solicited
		destdir
		get-specific
		compass
		extremex
		no-oracle
		details
		flipstick
		decaying
		gofilt
	)},
	{"Think of everything from their point of view." => %w(
		wdtrw
		reach
		dass
		wwoy
		barking
	)},
	{"Marketing is a creative extension of your art." => %w(
		bizriff
		tvtest
		wmore
		senses
		restr
		capt
	)},
	{"Have the confidence to target." => %w(
		wysl
		exclude
		vodka
		no-bullseye
		purplecow
		trshr
		prgrk
		1pct
	)},
	{"All the world’s a stage. What character are you?" => %w(
		actors
		rounded
		evers
		consx
		contrarian
		candles
		mystery
	)},
	{"Prove yourself before asking for help" => %w(
		success-first
		testm
		up2you
		no9to5
		gbp
		1090
		diy
	)},
	{"People : one to many" => %w(
		hundreds
		dbq
		dbt
		ppweek
		hs
		kit1
		kit2
		conferences
		rayko
	)},
	{"Words carry your music farther and faster" => %w(
		wordsm
		shrtd
		dym
		ncorp
		hillbf
		whycare
		not2say
		nomu
		notalk
	)},
	{"Money is neutral proof that you’re being valuable" => %w(
		nolimit
		pigs-sharks
		sustainable
		buyable
		livecd
		quantity
		lines
		ppay
		no-reward
	)},
	{"Get people involved." => %w(
		fanwork
		inclev
		phoaud
		insidr
	)},
	{"Tools and skills" => %w(
		netskill
		promobox
		intrweb
	)},
	{"Before you leave" => %w(
		oyh
		drain
	)},
	{"Extra" => %w(
		songwriters-only
		label-list
		session-musician
		berklee
		sakamoto
	)}
]
MusicBookTOC = MusicBook.map {|x| x.values}.flatten
