-- a little library for making SQLite3 usage a bit simpler
-- USAGE:
--
-- DBNAME = 'lat.db'
-- local db = require('dbhelp')
-- db.justDo("INSERT INTO lat(name, price) VALUES (?, ?)", "kid's toy", 123)
-- local id = db.newId()
-- local concepts = db.getOne("SELECT * FROM concepts WHERE id=?", id)
-- local tags = db.getMany("SELECT * FROM tags ORDER BY id")

local DBHelp = {}
DBHelp.sqlite3 = require('lsqlite3')
DBHelp.db = DBHelp.sqlite3.open(DBNAME)

-- bind arguments to the "?"s in the SQL string
DBHelp.prep = function(sql, ...)
	local stmt = DBHelp.db:prepare(sql)
	for i, v in ipairs{...} do
		stmt:bind(i, v)
	end
	return stmt
end

-- run a query and return nothing
DBHelp.justDo = function(sql, ...)
	local stmt = DBHelp.prep(sql, ...)
	stmt:step()
	stmt:finalize()
end

-- if justDo was an INSERT, this returns the new id integer (0 if none)
DBHelp.newId = function()
	return DBHelp.db:last_insert_rowid()
end

-- run a query and return just one table with named indexes (nil if none)
DBHelp.getOne = function(sql, ...)
	local stmt = DBHelp.prep(sql, ...)
	local res
	if stmt:step() ~= DBHelp.sqlite3.DONE then
		res = stmt:get_named_values()
	end
	stmt:finalize()
	return res
end

-- run a query and return an array of tables with named indexes
DBHelp.getMany = function(sql, ...)
	local stmt = DBHelp.prep(sql, ...)
	local res = {}
	local row = 1
	while stmt:step() ~= DBHelp.sqlite3.DONE do
		res[row] = stmt:get_named_values()
		row = row + 1
	end
	stmt:finalize()
	return res
end

return DBHelp
