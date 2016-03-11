local weekNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
local monthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
local realTime = false --give the program a chance to check if the time is real before ending up with 01/01/1970

local function initTime()
	local timer = os.startTimer(5)
	local timeRequest = http.request("http://lunadb.ddns.net/time.php")
	local event, url, data
	repeat 
		event, url, data = coroutine.yield()
	until (event == "timer" and url == timer) or event == "http_success" or event == "http_failure"
	
	if event == "http_failiure" then
		log.i("No connection to server, using local time")
		return 0 --if we cant get the real time just use 0
	end
	
	if event == "timer" then
		log.i("request timed out, using local time")
		return 0 --if we cant get the real time just use 0
	end 
	
	local returnedTime = data.readLine()
	returnedTime = tonumber(returnedTime)
	
	isRealTime = true
	
	return returnedTime - math.floor(os.clock()) --for this to properly return the teme at boot we must take away the system up time
end

local timeAtBoot = initTime() --cache the time at boot so we dont nee to access the webserver everytime we need to check the time

function time()
	return timeAtBoot + math.floor(os.clock())
end

function timef(s, t)
	t = t or time()
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
	local weekday = ((mathUtils.div(t, 86400) - 4 ) % 7) + 1
	
	while tmpDays >= 365 do
		year = year + 1
		tmpDays = tmpDays - (isLeap(year) and 366 or 365)
	end
	
	monthsInDays = isLeap(year) and {-1,30,59,90,120,151,181,212,243,273,304,334} or {0,31,59,90,120,151,181,212,243,273,304,334}
	
	while month > 1 and tmpDays <= monthsInDays[month] do
		month = month - 1
	end
	
	day = tmpDays - monthsInDays[month]

	s=s:gsub("\00", " ") --this is all i could think of to escape %%4
	s=s:gsub("(%%%%)", "\00")
	s=s:gsub("%%c", "%%x, %%X")
	s=s:gsub("%%x", "%%d/%%m/%%Y")
	s=s:gsub("%%X", "%%I:%%M:%%S %%p")
	s=s:gsub("%%Y", tostring(year))
	s=s:gsub("%%y", tostring(year):sub(3))
	s=s:gsub("%%B", tostring(monthNames[month]))
	s=s:gsub("%%b", tostring(monthNames[month]):sub(1,3))
	s=s:gsub("%%w", tostring(weekday))
	s=s:gsub("%%A", tostring(weekNames[weekday]))
	s=s:gsub("%%a", tostring(weekNames[weekday]):sub(1,3))
	s=s:gsub("%%d", string.format("%02d", day))
	s=s:gsub("%%H", string.format("%02d", hours))
	s=s:gsub("%%I", string.format("%02d", hours % 12))
	s=s:gsub("%%M", string.format("%02d", minutes))
	s=s:gsub("%%m", string.format("%02d", month))
	s=s:gsub("%%S", string.format("%02d", seconds))
	s=s:gsub("%%p", hours <= 12 and "AM" or "PM")
	s=s:gsub("\00", "%%")
	
	return s 
end

function isRealTime()
	return realTime
end