---Globaly overides various functions to prevent non root calling functions such as shutdown

local oldfs = fs
local oldGetfenv = getfenv
local _has8BitCharacters = fs.exists("rom/apis/settings")

local oldSetComputerLabel = os.setComputerLabel
local oldShutdown = os.shutdown
local oldReboot = os.reboot
local oldTermWrite = term.write
local oldTermBlit = term.blit

function os.setComputerLabel(label)
	errorUtils.expect(label, "string", false, 2)
	
	if kernel.isSU() then
		oldSetComputerLabel(label)
	end
end


function os.shutdown()
	if kernel.isSU() then
        oldShutdown()
	else
        kernel.killProcess(kernel.getRunning())
    end
end


function os.reboot()
	if kernel.isSU() then
        oldReboot()
	else
        kernel.killProcess(kernel.getRunning())
    end
end

function http.timedRequest(url, timeout, post, headers)
	local timeRequest = http.request(url, post, headers)
	local timer = os.startTimer(timeout)

		
	while true do
		local event, _url, data = coroutine.yield()
	
		if event == "http_success" and url == _url then
			os.cancelTimer(timer)
			return data
		elseif event == "timer" and _url == timer then
			return nil, "Timed out"
		elseif event == "http_failure" then
			os.cancelTimer(timer)
			return nil, data
		end
	end
	
end

function term.has8BitCharacters()
	--anything >= 192 errors
	return _has8BitCharacters
end


if not _has8BitCharacters then

	function term.write(str)
		if type(str) == "string" then
			for n = 1, #str do
				local b = string.byte(str, n)
				
				if b >= 192 then
					str =str:gsub(string.char(b), "?")
				end
			end
		end
		
		oldTermWrite(str)
	end


	function term.blit(str, textColour, backgroundColour)
		if type(str) == "string" then
			for n = 1, #str do
				local b = string.byte(str, n)
				
				if b >= 192 then
					str =str:gsub(string.char(b), "?")
				end
			end
		end
		
		oldTermBlit(str, textColour, backgroundColour)
	end
end


