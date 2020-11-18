#!/usr/bin/env lua

local latio = require('latio')

-- keep at it until Ctrl-C
while true do

	-- which menu choice?
	io.write("choice? ")
	io.flush()
	local menuChoice = io.read()
	local choice = latio.menu[menuChoice]
	if not choice then print("bye!") break end
	print(string.upper(choice.desc))

	-- prompt for arguments required
	local args = {}
	if choice.args then
		local i = 1
		for n, arg in pairs(choice.args) do
			io.write(arg, ": ")
			io.flush()
			args[i] = io.read()
			i = i + 1
		end
	end

	-- perform the main function of this choice
	-- (note turning table of args[#] into separate elements)
	local res
	if choice.func then
		res = choice.func(table.unpack(args))
	end

	-- show anything?
	if choice.show then
		latio.show[choice.show](res)
	end

end
