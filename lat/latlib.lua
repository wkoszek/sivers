DBNAME = 'lat.db'

local Lat = {}
Lat.db = require('dbhelp')

Lat.getConcepts = function()
	return Lat.db.getMany("SELECT * FROM concepts ORDER BY id")
end

Lat.getConcept = function(id)
	local res = Lat.db.getOne("SELECT * FROM concepts WHERE id=?", id)
	res.tags = Lat.db.getMany("SELECT tags.tag FROM concepts_tags" ..
		" LEFT JOIN tags ON concepts_tags.tag_id=tags.id" ..
		" WHERE concepts_tags.concept_id=?", id)
	res.urls = Lat.db.getMany("SELECT urls.* FROM concepts_urls" ..
		" LEFT JOIN urls ON concepts_urls.url_id=urls.id" ..
		" WHERE concepts_urls.concept_id=?", id)
	return res
end

Lat.createConcept = function(title, concept)
	Lat.db.justDo("INSERT INTO concepts(title, concept) VALUES(?, ?)", title, concept)
	local id = Lat.db.newId()
	return Lat.getConcept(id)
end

Lat.updateConcept = function(id, title, concept)
	Lat.db.justDo("UPDATE concepts SET" ..
		" title=trim(title || ' ' || ?)," ..
		" concept=trim(concept || char(10) || ?, char(10))" ..
		" WHERE id=?", title, concept, id)
end

Lat.deleteConcept = function(id)
	Lat.db.justDo("DELETE FROM concepts WHERE id=?", id)
end

Lat.tagConcept = function(id, tag)
	local tagId
	local t = Lat.db.getOne("SELECT id FROM tags WHERE tag=?", tag)
	if t then
		tagId = t.id
	else
		Lat.db.justDo("INSERT INTO tags(tag) VALUES(?)", tag)
		tagId = Lat.db.newId()
	end
	Lat.db.justDo("INSERT INTO concepts_tags(concept_id, tag_id) VALUES(?, ?)", id, tagId)
end

Lat.untagConcept = function(id, tagId)
	Lat.db.justDo("DELETE FROM concepts_tags WHERE concept_id=? AND tag_id=?", id, tagId)
end

Lat.getUrl = function(id)
	return Lat.db.getOne("SELECT * FROM urls WHERE id=?", id)
end

Lat.addUrl = function(conceptId, url, notes)
	Lat.db.justDo("INSERT INTO urls(url, notes) VALUES(?, ?)", url, notes)
	local urlId = Lat.db.newId()
	Lat.db.justDo("INSERT INTO concepts_urls(concept_id, url_id) VALUES(?, ?)", conceptId, urlId)
end

Lat.updateUrl = function(id, url, notes)
	Lat.db.justDo("UPDATE urls SET url=?, notes=? WHERE id=?", url, notes, id)
end

Lat.deleteUrl = function(id)
	Lat.db.justDo("DELETE FROM urls WHERE id=?", id)
end

Lat.tags = function()
	return Lat.db.getMany("SELECT * FROM tags ORDER BY RANDOM()")
end

Lat.conceptsTagged = function(tag)
	return Lat.db.getMany("SELECT concepts.* FROM concepts, concepts_tags, tags" ..
		" WHERE concepts_tags.concept_id=concepts.id" ..
		" AND concepts_tags.tag_id=tags.id" ..
		" AND tags.tag=?" ..
		" ORDER BY concepts.id", tag)
end

Lat.untaggedConcepts = function()
	return Lat.db.getMany("SELECT concepts.* FROM concepts" ..
		" LEFT JOIN concepts_tags ON concepts.id=concepts_tags.concept_id" ..
		" WHERE concepts_tags.tag_id IS NULL")
end

Lat.getPairings = function()
	return Lat.db.getMany("SELECT p.id, p.created_at," ..
		" c1.title AS concept1, c2.title AS concept2 FROM pairings p" ..
		" INNER JOIN concepts c1 ON p.concept1_id=c1.id" ..
		" INNER JOIN concepts c2 ON p.concept2_id=c2.id ORDER BY p.id")
end

Lat.getPairing = function(id)
	local res = Lat.db.getOne("SELECT * FROM pairings WHERE id=?", id)
	res.concept1 = Lat.getConcept(res.concept1_id)
	res.concept2 = Lat.getConcept(res.concept2_id)
	return res
end

Lat.createPairing = function()
	local p = Lat.db.getOne("SELECT c1.id id1, c2.id id2" ..
		" FROM concepts c1 CROSS JOIN concepts c2" ..
		" LEFT JOIN pairings p1 ON (id1=p1.concept1_id AND id2=p1.concept2_id)" ..
		" LEFT JOIN pairings p2 ON (id1=p2.concept2_id AND id2=p2.concept1_id)" ..
		" WHERE id1 != id2 AND p1.id IS NULL AND p2.id IS NULL" ..
		" ORDER BY RANDOM() LIMIT 1")
	if not p then return false end
	Lat.db.justDo("INSERT INTO pairings(concept1_id, concept2_id) VALUES (?, ?)", p.id1, p.id2)
	return Lat.getPairing(Lat.db.newId())
end

Lat.updatePairing = function(id, thoughts)
	Lat.db.justDo("UPDATE pairings" ..
		" SET thoughts=trim(coalesce(thoughts, '') || char(10) || ?, char(10))" ..
		" WHERE id=?", thoughts, id)
	return Lat.getPairing(id)
end

Lat.deletePairing = function(id)
	Lat.db.justDo("DELETE FROM pairings WHERE id=?", id)
end

Lat.tagPairing = function(id, tag)
	local p = Lat.db.getOne("SELECT concept1_id, concept2_id FROM pairings WHERE id=?", id)
	Lat.tagConcept(p.concept1_id, tag)
	Lat.tagConcept(p.concept2_id, tag)
	return Lat.getPairing(id)
end

return Lat

