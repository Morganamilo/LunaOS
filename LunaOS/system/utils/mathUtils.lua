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

function time(func)
	errorUtils.expect(x, "function", true)
	
	local time = os.clock()
	func()
	return os.clock() - time
end