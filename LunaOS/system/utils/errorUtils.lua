function assert(v, message, code)
	if code > 0 then code = code + 1 end
	if not v then error(message, code) end
	return value
end