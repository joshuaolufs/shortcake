-- Variable Declarations --
x, y, z, v = 0, 0, 0, 0
totalBroken, totalTraveled = 0, 0
NORTH = 0 -- positive y direction
WEST = 3 -- negative x direction
EAST = 1 -- positive x direction
SOUTH = 2 -- negative y direction
rawCode = ""

-- Detection Functions --
function getBlockName(dir)
	if dir == "down" and turtle.detectDown() then
		local success, data = turtle.inspectDown()
		if success then
			return data.name
		end
	elseif dir == "up" and turtle.detectUp() then
		local success, data = turtle.inspectUp()
		if success then
			return data.name
		end
	else 
		turtle.detect()
		local success, data = turtle.inspect()
		if success then
			return data.name
		end
	end
	return nil
end

function isBlockInList(blockList, dir)
	blockName = getBlockName(dir)
	success = false
	if blockName ~= nil then
		for i=1, #blockList do
			if string.find(blockName, blockList[i]) ~= nil then
				success = true
			end
		end
	end
	return success
end

-- Basic Digging Functions --
function dig()
	while turtle.detect() do
		local success = turtle.dig()
		while not success do
			sleep(config.UPDATE_PAUSE)
			success = turtle.dig()
		end
		totalBroken = totalBroken + 1
		sleep(config.GRAVITY_PAUSE)
	end
end

function digUp()
	while turtle.detectUp() do
		local success = turtle.digUp()
		while not success do
			sleep(config.UPDATE_PAUSE)
			success = turtle.digUp()
		end
		totalBroken = totalBroken + 1
		sleep(config.GRAVITY_PAUSE)
	end
end

function digDown()
	if isBlockInList(config.softAbort, "down") then return true end
	while turtle.detectDown() do
		local success = turtle.digDown()
		while not success do
			sleep(config.UPDATE_PAUSE)
			success = turtle.digDown()
		end
		totalBroken = totalBroken + 1
		sleep(config.UPDATE_PAUSE)
	end
	return true
end

-- Turning Functions --
function left()
	local success = turtle.turnLeft()
	while not success do
		success = turtle.turnLeft()
	end
	v = math.fmod((v+3), 4)
end

function right()
	local success = turtle.turnRight()
	while not success do
		success = turtle.turnRight()
	end
	v = math.fmod((v+1), 4)
end

function turnTo(newDir)
	newDir = newDir + 4
	local oldDir = v + 4
	local diff = (newDir - oldDir)%4
	if diff == 1 then
		right()
	elseif diff == 3 then
		left()
	elseif diff == 2 then
		left()
		left()
	end
end

-- Movement Functions --
function forward()
	local success = turtle.forward()
	local attempts = 1
	while not success do
		dig()
		if config.agressive then turtle.attack() end
		if turtleNeedFuel ~= 0 then
			if turtle.getFuelLevel() < 1 and attempts == config.TIMEOUT then
				print("Out of fuel, feed me Seymour!")
				local event, p1 = os.pullEvent("turtle_inventory")
				refuel()
			end
		end
		if attempts < config.TIMEOUT then
			sleep(config.GRAVITY_PAUSE)
		elseif attempts == config.TIMEOUT then
			print("Can't move forward, the way is shut!")
			sleep(config.USER_PAUSE)
		else
			sleep(config.USER_PAUSE)
		end
		attempts = attempts + 1
		success = turtle.forward()
	end
	if v == NORTH then
		y = y+1
	elseif v == EAST then
		x = x+1
	elseif v == SOUTH then
		y = y-1
	elseif v == WEST then
		x = x-1
	end
	totalTraveled = totalTraveled + 1
end

function up()
	local success = turtle.up()
	local attempts = 1
	while not success do
		digUp()
		if config.agressive then turtle.attackUp() end
		if turtleNeedFuel ~= 0 then
			if turtle.getFuelLevel() < 1 and attempts == config.TIMEOUT then
				print("Out of fuel, feed me Seymour!")
				local event, p1 = os.pullEvent("turtle_inventory")
				refuel()
			end
		end
		if attempts < config.TIMEOUT then
            sleep(config.GRAVITY_PAUSE)
        elseif attempts == config.TIMEOUT then
            print("Can't move up, the way is shut!")
            sleep(config.USER_PAUSE)
        else
            sleep(config.USER_PAUSE)
        end
        attempts = attempts + 1
		success = turtle.up()
	end
	z = z+1
	totalTraveled = totalTraveled + 1
end

function down()
	if isBlockInList(config.softAbort, "down") then return true end
	local success = turtle.down()
	local attempts = 1
	while not success do
		digDown()
		if config.agressive then turtle.attackDown() end
		if turtleNeedFuel ~= 0 then
			if turtle.getFuelLevel() < 1 and attempts == config.TIMEOUT then
				print("Out of fuel, feed me Seymour!")
				local event, p1 = os.pullEvent("turtle_inventory")
				refuel()
			end
		end
		if attempts < config.TIMEOUT then
			sleep(config.GRAVITY_PAUSE)
		elseif attempts == config.TIMEOUT then
			print("Can't move down, the way is shut!")
			sleep(config.USER_PAUSE)
		else
			sleep(config.USER_PAUSE)
		end
		attempts = attempts + 1
		success = turtle.down()
	end
	z = z-1
	totalTraveled = totalTraveled + 1
end

-- Placement Functions
function placeUp(keep)
	if turtle.getItemCount() > 0 then
		digUp()
		if keep then
			if turtle.getItemCount() > 1 then
				turtle.placeUp()
			end
		else
			turtle.placeUp()
		end
	end
end

function placeDown(keep)
	if turtle.getItemCount() > 0 then
		digDown()
		if keep then
			if turtle.getItemCount() > 1 then
				turtle.placeDown()
			end
		else
			turtle.placeDown()
		end
	end
end

function placeForward(keep)
	if turtle.getItemCount() > 0 then
		dig()
		if keep then
			if turtle.getItemCount() > 1 then
				turtle.place()
			end
		else
			turtle.place()
		end
	end
end

-- Dropping Functions
function smartDrop(keep)
	if turtle.getItemCount() == 0 then return end
	if string.find(getBlockName("forward") or "", "[Cc]hest") ~= nil then
		if keep then
			turtle.drop(turtle.getItemCount()-1)
		else
			turtle.drop()
		end
	elseif string.find(getBlockName("up") or "", "[Cc]hest") ~= nil then
		if keep then
			turtle.dropUp(turtle.getItemCount()-1)
		else
			turtle.dropUp()
		end
	elseif string.find(getBlockName("down") or "", "[Cc]hest") ~= nil then
		if keep then
			turtle.dropDown(turtle.getItemCount()-1)
		else
			turtle.dropDown()
		end
	else
		if keep then
			turtle.drop(turtle.getItemCount()-1)
		else
			turtle.drop()
		end
	end
end

function cycleSlot()
	if turtle.getSelectedSlot() < 16 then
		turtle.select(turtle.getSelectedSlot()+1)
	else
		turtle.select(1)
	end
end

function suck()
	turtle.suck()
	turtle.suckUp()
	turtle.suckDown()
end

function refuel(keep)
	if turtle.getItemCount() > 0 then
		if keep then
			turtle.refuel(turtle.getItemCount()-1)
		else
			turtle.refuel()
		end
	end
end