---Provides some math related function that are missing from the math libary.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module mathUtils

---Checks whether a number is an integer.
--@param x A number.
--@return true if the number is an integer.
--@raise type missmatch error - if x is not a number
--@usage local isInt = mathUtils.isInt(4.3)
function isInt(x)
	errorUtils.expect(x, "number", true)
	return x == math.floor(x)
end

---Rounds a number to the nearest integer.
--@param x A number.
--@return The nearest integer to x.
--@raise type missmatch error - if x is not a number
--@usage local x = mathUtils.isInt(5.5)
function round(x)
	errorUtils.expect(x, "number", true)
	return math.floor(x + 0.5)
end

---Preforms integer divison on x by y.
--@param x The Dividend.
--@param y The Divisor.
--@return  The result of x divided by y truncated towards 0.
--@raise type missmatch error - if x or y is not a number
--@usage local a = mathUtils.div(5, 2)
function div(x, y)
	errorUtils.expect(x, "number", true)
	errorUtils.expect(y, "number", true)
	return math.floor(x / y)
end

---Times the time it takes for a function to complete.
--@param func The function to time.
--@param trials The number of times to call the function.
--@return The time difference between before the function is called and after the function has been called n times.
--@raise type missmatch error - if func is not a function
function time(func, trials)
	errorUtils.expect(func, "function", true)
	
	local time = os.clock()
	
	for n = 1, trials or 1 do
		func()
	end
	
	return os.clock() - time
end

---Returns The sign of x.
--@param x The number to sign.
--@return 1 if x is > 0 else -1
--@raise type missmatch error - if x is not a number
--@usage local sign = mathUtils.sign(43)
function sign(x)
	errorUtils.expect(x, "number", true)
	return x >= 0 and 1 or -1
end