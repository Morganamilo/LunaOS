local weekNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
local monthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
local realTime = false --give the program a chance to check if the time is real before ending up with 01/01/1970
local timeAtBoot
local offset

local function initTime()
	if not fs.exists("/LunaOS/data/system/timezone") then
		local file = fs.open("/LunaOS/data/system/timezone", "w")
		file.write("Europe/London")
		file.close()
	end
	
	local file = fs.open("/LunaOS/data/system/timezone", "r")
	local timezone = file.readLine()
	file.close()

	local request, err = http.timedRequest("http://lunadb.ddns.net/time.php?timezone=" .. textutils.urlEncode(timezone), 2)
	
	if not request then
		log.i("No connection to server, using local time")
		return 0, 0 --if we cant get the real time just use 0
	end
	
	--ensure we get a valid json response
	local success, response = pcall(jsonUtils.decode, request.readLine())

	if not success then
		return 0, 0 --if we cant get the real time just use 0
	end
	
	local returnedTime = tonumber(response[1])
	local offset = tonumber(response[2])
	
	if not returnedTime then
		log.i("invalid response, using local time")
		return 0, 0
	end
	
	realTime = true
	
	return returnedTime - math.floor(os.clock()), offset --for this to properly return the time at boot we must take away the system up time
end

function time()
	return timeAtBoot + math.floor(os.clock())
end

function timef(s, t)
	t = t or time() + offset
	s = s or "%c"

	errorUtils.assert(type(s) == "string", "Error: string expected got " .. type(s), 2)
	errorUtils.assert(type(t) == "number", "Error: number expected got " .. type(t), 2)
	errorUtils.assert(t >= 0 and mathUtils.isInt(t), "Error: time must be a positive integer", 2)
		
	local function isLeap(year)
		return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
	end
	
	local year = 1970
	local tmpDays = mathUtils.div(t, 86400) + 1
	local month = 12
	local monthsInDays
	local day
	
	local seconds = t % 60 
	local minutes = mathUtils.div(t, 60) % 60
	local hours = mathUtils.div(t, 60*60) % 24
	local weekday = ((mathUtils.div(t, 86400) - 3 ) % 7) + 1
	
	while tmpDays >= 365 do
		year = year + 1
		tmpDays = tmpDays - (isLeap(year) and 366 or 365)
	end
	
	monthsInDays = isLeap(year) and {-1,30,59,90,120,151,181,212,243,273,304,334} or {0,31,59,90,120,151,181,212,243,273,304,334}
	
	while month > 1 and tmpDays <= monthsInDays[month] do
		month = month - 1
	end
	
	day = tmpDays - monthsInDays[month]

	s=s:gsub("\00", " ") --this is all i could think of to escape %%
	s=s:gsub("(%%%%)", "\00")
	
	local characterClasses = {
		Y =  tostring(year),
		y =  tostring(year):sub(3),
		B = monthNames[month],
		b = monthNames[month]:sub(1,3),
		w = tostring(weekday),
		A = weekNames[weekday],
		a = weekNames[weekday]:sub(1,3),
		d = string.format("%02d", day),
		H = string.format("%02d", hours),
		I = string.format("%02d", hours % 12),
		M = string.format("%02d", minutes),
		m = string.format("%02d", month),
		S = string.format("%02d", seconds),
		p = (hours <= 12 and "AM" or "PM")
	}
	
	characterClasses.X = characterClasses.I .. ":" .. characterClasses.M .. ":" .. characterClasses.p
	characterClasses.x = characterClasses.d .. "/" .. characterClasses.m .. "/" .. characterClasses.y
	characterClasses.c = characterClasses.x .. ", " .. characterClasses.X
	
	for class, result in pairs(characterClasses) do
		s = s:gsub('%%' .. class, result)
	end
	
	s=s:gsub("\00", "%%")
	
	return s 
end

function isRealTime()
	return realTime
end

function getOffset()
	return offset
end

timeAtBoot, offset = initTime() --cache the time at boot so we dont nee to access the webserver everytime we need to check the time
