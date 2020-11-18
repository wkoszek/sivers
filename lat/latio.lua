lat = require('latlib')
local LatIO = {}

-- cli functions for displaying
LatIO.show = {
	concept = function(c)
		if not c then
			io.write("« no concept »\n")
		else
			io.write(c.id, "\t", c.created_at, "\t", c.title, "\n", c.concept, "\n")
		end
		io.flush()
	end,
	conceptFull = function(c)
		if not c then
			io.write("« no concept »\n")
		else
			print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
			io.write(c.id, "\t", c.created_at, "\t", c.title, "\n", c.concept, "\n")
			print("URLs:")
			for i, x in pairs(c.urls) do
				print(x.id, x.notes)
				print(x.url)
			end
			print("tags:")
			for i, x in pairs(c.tags) do
				io.write(x.tag, "\t")
			end
			io.write("\n")
		end
		io.flush()
	end,
	concepts = function(cc)
		for i, c in pairs(cc) do
			LatIO.show.concept(c)
		end
	end,
	tags = function(tt)
		for i, t in pairs(tt) do
			io.write(t.tag, "\t")
		end
		io.write("\n")
		io.flush()
	end,
	pairing = function(p)
		if not p then 
			io.write("« no pairing »\n")
		else
			io.write(string.format("%d\t%s\t%s\t%s\n",
				p.id, p.created_at, p.concept1, p.concept2))
		end
		io.flush()
	end,
	pairingFull = function(p)
		if not p then 
			io.write("« no pairing »\n")
		else
			print(p.id, p.created_at)
			print "CONCEPT 1:"
			LatIO.show.conceptFull(p.concept1)
			print "CONCEPT 2:"
			LatIO.show.conceptFull(p.concept2)
			print("====================================")
			print "THOUGHTS:"
			print(p.thoughts)
		end
		io.flush()
	end,
	pairings = function(pp)
		for i, p in pairs(pp) do
			LatIO.show.pairing(p)
		end
	end,
	menu = function()
		for k, v in pairs(LatIO.menu) do
			print(k, v.desc)
		end
	end
}

-- "doid" = function that loads using id before next two args
-- "show" = send result of func to this function
LatIO.menu = {
	m = {
		desc = "menu",
		show = "menu"
	},
	l = {
		desc = "list concepts",
		func = lat.getConcepts,
		show = "concepts"
	},
	g = {
		desc = "get concept",
		func = lat.getConcept,
		args = {"id"},
		show = "conceptFull"
	},
	a = {
		desc = "add concept",
		func = lat.createConcept,
		args = {"title", "concept"},
		show = "concept"
	},
	A = {
		desc = "delete concept",
		func = lat.deleteConcept,
		args = {"id"}
	},
	u = {
		desc = "update concept",
		func = lat.updateConcept,
		args = {"id", "title", "concept"},
		doid = lat.getConcept,
		show = "conceptFull"
	},
	t = {
		desc = "tag concept",
		func = lat.tagConcept,
		args = {"id", "tag"},
		doid = lat.getConcept,
		show = "conceptFull"
	},
	T = {
		desc = "untag concept",
		func = lat.untagConcept,
		args = {"id", "tagId"},
		doid = lat.getConcept,
		show = "conceptFull"
	},
	r = {
		desc = "add url",
		func = lat.addUrl,
		args = {"id", "url", "notes"},
		doid = lat.getConcept,  -- TODO: show conceptFull after?
	},
	R = {
		desc = "delete url",
		func = lat.deleteUrl,
		args = {"id"},  -- TODO: show conceptFull after?
	},
	h = {
		desc = "update url",
		func = lat.updateUrl,
		args = {"id", "url", "notes"},
		doid = lat.getUrl,  -- TODO: show conceptFull after?
	},
	s = {
		desc = "tags",
		func = lat.tags,
		show = "tags"
	},
	c = {
		desc = "concepts tagged",
		func = lat.conceptsTagged,
		args = {"tag"},
		show = "concepts"
	},
	C = {
		desc = "untagged concepts",
		func = lat.untaggedConcepts,
		show = "concepts"
	},
	E = {
		desc = "get pairings",
		func = lat.getPairings,
		show = "pairings"
	},
	e = {
		desc = "get pairing",
		func = lat.getPairing,
		args = {"id"},
		show = "pairingFull"
	},
	p = {
		desc = "create pairing",
		func = lat.createPairing,
		show = "pairingFull"
	},
	U = {
		desc = "update pairing",
		func = lat.updatePairing,
		args = {"id", "thoughts"},
		doid = lat.getPairing,
		show = "pairingFull"
	},
	P = {
		desc = "delete pairing",
		func = lat.deletePairing,
		args = {"id"}
	},
	G = {
		desc = "tag pairing",
		func = lat.tagPairing,
		args = {"id", "tag"},
		doid = lat.getPairing,
		show = "pairingFull"
	}
}

return LatIO
