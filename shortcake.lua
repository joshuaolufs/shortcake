-- Load Config and Libraries
os.loadAPI("./sc_files/config")
os.loadAPI("./sc_files/t")

-- Set Regular Expression Strings
local expressionUnit = "%[(.-)%]"
local loopUnit = "[%(%)]+%d+"
local singleLoop = "([x<>^vfudcaby#])(%d+)"
local multiLoop = "(%([x<>^vfudcabsryp',igkn0-9#]-%))(%d+)"
local jitterLeft = "<>"
local jitterRight = "><"
local longTurnLeft = "<<<"
local longTurnRight = ">>>"
local moveSet = "[x^v]"
local commandSet = "[x<>^vfudcabsrypk#%s]"

-- Version
local version = 1.1

-------------------------------------------------
-- Helper Functions
-------------------------------------------------

function clear()
	term.clear()
	term.setCursorPos(1,1)
end

-------------------------------------------------
-- Argument Handling
-------------------------------------------------

-- Load Argument List
local args = { ... }

-- Validate Args / Print Usage
if #args < 1 then
	clear()
	print("You must specify a function.")
	print("Usage: shortcake <function> [params]")
	print("Functions: about delete get help new run save uninstall update")
	return
end

-------------------------------------------------
-- Compilation Functions
-------------------------------------------------

-- Substitute Parameter References
function subParamValues(codeIn, variablesIn)
	if config.printStatus then print("- Replacing Parameter References") end
	if #args > 2 then -- if there are arguments to process then continue
		for i=3, #args do -- for each arg do ...
			local temp = string.sub(variablesIn, i-2, i-2) -- get the reference character for this argument
			codeIn = string.gsub(codeIn, temp, args[i]) -- replace all instances of that character with the current argument
			if config.printStatus then print("  - Replacing " .. temp .. " with " .. args[i]) end
		end
	end
	return codeIn
end

-- Evaluate Expressions
function evalExpressions(codeIn)
	if config.printStatus then print("- Evaluating Expressions") end
	for ex in string.gmatch(codeIn, expressionUnit) do
		-- evaluate the result of the current expression
		local eval, err = loadstring("return " .. ex)
		local resultOut = ""
		local result = eval()
		
		-- convert the output to an integer
		if type(result) == "number" then 
			resultOut = math.floor(result + 0.5) -- round any numerical result
			resultOut = math.max(0, resultOut) -- limit the result to non-negative numbers
			resultOut = tostring(resultOut) -- convert the result for insertion into the program string
		elseif type(result) == "boolean" then
			if result == true then
				resultOut = "1" -- true = 1
			else
				resultOut = "0" -- false = 0
			end
		end
		
		-- now replace the expression with the result
		local start, stop = string.find(codeIn, "[" .. ex .. "]", 1, true)
		local before = string.sub(codeIn , 1, start-1)
		local after = string.sub(codeIn, stop+1)
		codeIn =  before .. resultOut .. after
		if config.printStatus then print("  - " .. ex .. " = " .. resultOut) end
	end
	return codeIn
end

-- Unwind Loops (Repeat Statements)
function unwindLoops(codeIn)
	if config.printStatus then print("- Unwinding Loops") end
	-- if there are no numbers then there are no loops so pass the code through
	if string.find(codeIn, "%d") == nil then return codeIn end

	-- fist pass, expand all multi-loops
	while string.find(codeIn, loopUnit) ~= nil do
		codeIn = string.gsub(codeIn, multiLoop, function(s1, s2) 
			if tonumber(s2) > 0 then
				-- repeat the string the desired number of times
				local tempResult = string.rep(string.sub(s1,2,-2), tonumber(s2),' ')

				-- get n1 counts
				local temp, totalCount = string.gsub(tempResult, "n", "")
				local temp1, repCount = string.gsub(s1, "n1", "")
				local count = totalCount + 1

				-- step through, replacing n1's with progressively smaller ints, starting with count
				tempResult = string.gsub(tempResult, "n1", function()
					count = count - 1
					return tostring(math.ceil(count/repCount))
				end)

				-- optionally we could start at 0 and go up

				-- replace all n# in remaining string with n[#-1]
				tempResult = string.gsub(tempResult, "n([0-9]+)", function(num)
					return "n" .. tostring(tonumber(num)-1)
				end)

				-- return the result
				return tempResult
			else
				return ""
			end
		end)
	end
	if config.printStatus then print("  - Pass 1 Complete") end

	-- second pass, expand all single command loops
	codeIn = string.gsub(codeIn, singleLoop, function(s1, s2) 
		if tonumber(s2) > 0 then 
			return string.rep(s1, tonumber(s2),' ') 
		else 
			return "" 
		end 
	end)
	if config.printStatus then print("  - Pass 2 Complete") end
	
	return codeIn
end

-- Process any static flags
function processFlags(codeIn)
	if config.printStatus then print("- Processing Flags") end
	local output = ""
	for i=1, string.len(codeIn) do
		local current = string.sub(codeIn, i, i) -- get the current command
		local nextCommand = ""
		if i < string.len(codeIn) then nextCommand = string.sub(codeIn, i+1, i+1) end -- get the next command if one exists
		
		-- process the 'i' flag
		if current == "i" then
			config.hFlipBitOn = not config.hFlipBitOn
		elseif current == "<" and config.hFlipBitOn then output = output .. ">"
		elseif current == ">" and config.hFlipBitOn then output = output .. "<"
		-- process the 'g' flag
		elseif current == "g" then
			config.vFlipBitOn = not config.vFlipBitOn
		elseif current == "^" and config.vFlipBitOn then output = output .. "v"
		elseif current == "v" and config.vFlipBitOn then output = output .. "^"
		-- process the include up and down flags
		elseif current == "'" then config.includeUp = not config.includeUp
		elseif current == "," then config.includeDown = not config.includeDown
		elseif current == 'x' then
			local temp = "x"
			if config.includeUp then temp = temp .. "u" end
			if config.includeDown then temp = temp .. "d" end
			output = output .. temp
		else
			output = output .. current
		end
	end
	if config.printStatus then print("  - All Flags Processed") end
	return output
end

function cleanCode(codeIn)
	if config.printStatus then print("- Optimizing Code") end
	codeIn = string.gsub(codeIn, jitterLeft, "")
	codeIn = string.gsub(codeIn, jitterRight, "")
	codeIn = string.gsub(codeIn, longTurnLeft, ">")
	codeIn = string.gsub(codeIn, longTurnRight, "<")
	return codeIn
end

function validateCode(rawIn, compiledIn)
	local unquoted = string.sub(compiledIn, 2, -2)
	local badString = string.gsub(unquoted, commandSet, ".") or ""
	local length = string.len(string.gsub(unquoted, commandSet, ""))
	
	-- delete the error file to remove clutter
	fs.delete("sc_errors")

	if length > 0 then
		local file = fs.open("sc_errors", "w")
		if not file then 
			print("Failed to save errors to file.")
			return 
		end

		file.writeLine('Raw Code: ' .. string.len(rawIn))
		file.writeLine(rawIn)
		file.writeLine('')
		file.writeLine('Compiled Code: ' .. string.len(compiledIn))
		file.writeLine(compiledIn)
		file.writeLine('')
		file.writeLine('Bad Code: ' .. length)
		file.writeLine(badString)
		
		file.close()

		term.clear()
		term.setCursorPos(1,1)
		print("Code failed to validate")
		print("See error file 'sc_errors' for details")
		
		return false
	end
	return true
end

-------------------------------------------------
-- Execution Functions
-------------------------------------------------

-- Run the Program
function doit(codeIn)
	-- initialize turtle state
	turtle.select(1)

	-- loop over the string interpreting the commands
	for i=1, string.len(codeIn) do
		-- get the next command
		local current = string.sub(codeIn, i, i)	
		-- execute the next command
		if current == "x" then t.forward()
		elseif current == "^" then t.up()
		elseif current == "v" then t.down()
		elseif current == "<" then t.left()
		elseif current == ">" then t.right()
		elseif current == "f" then t.dig()
		elseif current == "u" then t.digUp()
		elseif current == "d" then t.digDown()
		elseif current == "c" then t.placeForward()
		elseif current == "a" then t.placeUp()
		elseif current == "b" then t.placeDown()
		elseif current == "p" then t.dropDown()
		elseif current == "y" then t.cycleSlot()
		elseif current == "s" then t.suck()
		elseif current == "r" then t.refuel()
		elseif current == 'k' then t.keepOne = not t.keepOne
		elseif current == '#' then turtle.craft(1)
		end
	end
end

-- Compile and Run the Program
function mainProgram(code)
	local raw = code
	clear()
	print("Raw Code: " .. raw)

	-- Compile Code
	code = subParamValues(code, config.variables)
	code = evalExpressions(code)
	code = unwindLoops(code)
	code = processFlags(code)
	code = cleanCode(code)

	-- Check validity of compiled code
	if not validateCode(raw, code) then return end
	
	-- Analyze code
	local programLength = string.len(code)
	if programLength > 100 then
		print("Compiled: " .. programLength .. " commands")
	else
		print("Compiled: " .. code)
	end
	local temp, programFuelUsage = string.gsub(code, moveSet, "")
	local currentFuel = turtle.getFuelLevel()
	print("Fuel required: " .. programFuelUsage .. " out of " .. currentFuel)
	if programFuelUsage > currentFuel then
		print("Not enough fuel, add more and try again")
		return
	end

	-- Run Code
	print("Running...")
	doit(code)
	print("Finished!")
	return
end


-------------------------------------------------
-- Shortcake Usage Functions
-------------------------------------------------

-- Save the program
-- <program_name> <program_code>
if args[1] == "save" then
	clear()
	if #args < 3 then
		print("Usage: shortcake save <program_name> <program_code>")
		return
	end
	local name = args[2]
	local program = args[3]

	local saveFile = fs.open(name, "w")
	if not saveFile then 
		print("Save Failed")
		return 
	end
	
	saveFile.writeLine('-- "' .. program .. '"')
	saveFile.writeLine("-- Move: x ^ v < >")
	saveFile.writeLine("-- Break: [f]orward, [u]p, [d]own")
	saveFile.writeLine("-- Place: [c]enter, [a]bove, [b]elow")
	saveFile.writeLine("-- Other: [s]uck, [r]efuel, c[y]cle, dro[p]")
	saveFile.writeLine("-- Craft: #")
	saveFile.writeLine("")
	saveFile.writeLine("-- Don't alter code below this line, it is required to make your shortcake code run.")
	saveFile.writeLine("local args = { ... }")
	saveFile.writeLine("executeString = 'shortcake run " .. name .. "'")
	saveFile.writeLine("for i=1,#args do")
	saveFile.writeLine("	executeString = executeString .. ' ' .. args[i]")
	saveFile.writeLine("end")
	saveFile.writeLine("shell.run(executeString)")
	saveFile.writeLine("return")

	saveFile.close()

	local file = fs.open("sc_files/dependents", "a")
	if not file then 
		print("Failed to update dependents")
		return 
	end
	file.writeLine(name)
	file.close()

	print("Program saved as: " .. name)
	return

-- Run the program
-- <program_name> [params]
elseif args[1] == "run" then
	if #args < 2 then
		print("Usage: shortcake run <program_name> [params]")
		return
	end
	local saveFileName = args[2]
	local saveFile = fs.open(saveFileName, "r")
	if not saveFile then 
		print("Couldn't run program")
		return 
	end
	local program = string.sub(saveFile.readLine(), 4)
	print("Running: " .. program)
	mainProgram(program)
	saveFile.close()
	return

-- Update the files
elseif args[1] == "update" then
	local channel = args[2] or config.channel
	clear()
	print("Updating from " .. channel .. " channel")
	print("")
	if (channel == "stable") then
		shell.run("pastebin run AyRdWn84") -- update from the stable channel
	elseif (channel == "dev") then
		shell.run("pastebin run zP17pfXi") -- update from the development channel
	else
		print(channel .. " is not a valid channel")
	end
	return

-- Uninstall
elseif args[1] == "uninstall" then
	clear()
	print("Uninstalling Shortcake ... ")
	print("")

	if fs.exists("sc_files/dependents") then
		print("Deleting shortcake programs.")
		local file = fs.open("sc_files/dependents", "r")
		if not file then 
			print("Failed to uninstall. Dependents error.")
			return 
		end
		local line = file.readLine()
		local contents = {}
		while line do
			table.insert(contents, line)
			line = file.readLine()
		end
		file.close()

		for key,value in pairs(contents) do
			if value ~= "" then fs.delete(value) end
		end
	end

	print("Deleting core files.")
	fs.delete("shortcake")
	fs.delete("sc_files")
	fs.delete("sc_errors")

	print("")
	print("Uninstall complete")
	return

-- About
elseif args[1] == "about" then
	clear()
	print("About Shortcake")
	print("")
	print("Author: metamilo")
	print("Version: " .. version)
	return

-- Delete
elseif args[1] == "delete" then
	clear()
	if #args < 2 then
		print("Usage: shortcake delete <program_name>")
		return
	end
	local name = args[2]

	-- delete the file
	fs.delete(name)

	-- read the file and remove the deleted file from the list
	local file = fs.open("sc_files/dependents", "r")
	if not file then 
		print("Failed to update dependents")
		return 
	end

	local line = file.readLine()
	local contents = {}
	while line do
		if line ~= name then
			table.insert(contents, line)
		end
		line = file.readLine()
	end
	file.close()

	-- save the list back to the file
	file = fs.open("sc_files/dependents", "w")
	if not file then 
		print("Failed to update dependents")
		return 
	end
	for key,value in pairs(contents) do
		file.writeLine(value)
	end
	file.close()

	print("Program " .. name .. " deleted successfully")
	return

-- Help
elseif args[1] == "help" then
	clear()
	if #args < 2 then
		print("Usage: shortcake help <topic>")
		print("Topics: about delete get new run save uninstall update")
		print("")
		return
	end
	if args[2] == "about" then
		print("Help -> About")
		print("Params: none")
		print("Displays some basic information about Shortcake")
	elseif args[2] == "delete" then
		print("Help -> Delete")
		print("Params: <program_name>")
		print("Deletes a shortcake program, and removes it from the dependents list.")
	elseif args[2] == "get" then
		print("Help -> Get")
		print("Params: <program_name>")
		print("Extracts an example program from the config file into a shortcake program")
	elseif args[2] == "new" then
		print("Help -> New")
		print("Params: <program_name>")
		print("Creates a new blank shortcake program with the given name")
	elseif args[2] == "run" then
		print("Help -> Run")
		print("Params: <program_name> [program_params]")
		print("Runs the given shortcake program with the given parameters")
	elseif args[2] == "save" then
		print("Help -> Save")
		print("Params: <program_name> <program_code>")
		print("Creates a shortcake program with the given name and code")
	elseif args[2] == "uninstall" then
		print("Help -> Uninstall")
		print("Params: none")
		print("Deletes all shortcake files, including your shortcake programs")
	elseif args[2] == "update" then
		print("Help -> Update")
		print("Params: [channel]")
		print("Redownloads the core shortcake files, leaving your programs intact")
		print("If [channel] is set it updates from the specified channel, otherwise it uses the channel set in the config file")
	else
		print("Sorry, I can't help you with that")
	end
	return

-- New program
elseif args[1] == "new" then
	clear()
	if #args < 2 then
		print("Usage: shortcake new <program_name>")
		return
	end

	local name = args[2]
	local saveFile = fs.open(name, "w")
	if not saveFile then 
		print("Failed to create program")
		return 
	end

	saveFile.writeLine('-- ""')
	saveFile.writeLine("-- Move: x ^ v < >")
	saveFile.writeLine("-- Break: [f]orward, [u]p, [d]own")
	saveFile.writeLine("-- Place: [c]enter, [a]bove, [b]elow")
	saveFile.writeLine("-- Other: [s]uck, [r]efuel, c[y]cle, dro[p]")
	saveFile.writeLine("-- Craft: #")
	saveFile.writeLine("")
	saveFile.writeLine("-- Don't alter code below this line, it is required to make your shortcake code run.")
	saveFile.writeLine("local args = { ... }")
	saveFile.writeLine("executeString = 'shortcake run " .. name .. "'")
	saveFile.writeLine("for i=1,#args do")
	saveFile.writeLine("	executeString = executeString .. ' ' .. args[i]")
	saveFile.writeLine("end")
	saveFile.writeLine("shell.run(executeString)")
	saveFile.writeLine("return")

	saveFile.close()

	local file = fs.open("sc_files/dependents", "a")
	if not file then 
		print("Failed to update dependents")
		return 
	end
	file.writeLine(name)
	file.close()

	print("New program created: " .. name)
	return

-- Get an example program
elseif args[1] == "get" then
	clear()
	if #args < 2 then
		print("Usage: shortcake get <program name>")
		print("Available Programs:")
		local resultString = ""
		for key,value in pairs(config.programs) do
			resultString = resultString .. " " .. key
		end
		print(resultString)
		return
	end
	local program_name = args[2]
	if config.programs[program_name] ~= nil then
		shell.run("shortcake", "save", program_name, config.programs[program_name])
	else
		print("No such program: " .. program_name)
	end
	return
else
	print(args[1] .. " is not a shortcake function.")
	shell.run("shortcake help")
end