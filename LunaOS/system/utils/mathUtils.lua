function isInt(x)
	errorUtils.expect(x, "number", true)
	return x == math.floor(x)
end

function round(x)
	errorUtils.expect(x, "number", true)
	return math.floor(x + 0.5)
end

function div(x, y)
	errorUtils.expect(x, "number", true)
	return math.floor(x / y)
end

function time(func, trials)
	errorUtils.expect(func, "function", true)
	
	local time = os.clock()
	
	for n = 1, trials or 1 do
		func()
	end
	
	return os.clock() - time
end

function sign(x)
	return x >= 0 and 1 or -1
end