local bin = lunaOS.getProp("binPath")
local packagePath = lunaOS.getProp("packagePath")
local systemPackagePath = lunaOS.getProp("systemPackagePath")


shell.setPath('.' .. ":" .. bin .. ":" .. systemPackagePath .. ":" .. packagePath .. shell.path():sub(2))

-- Setup completion functions
local function completeMultipleChoice( sText, tOptions, bAddSpaces )
    local tResults = {}
    for n=1,#tOptions do
        local sOption = tOptions[n]
        if #sOption + (bAddSpaces and 1 or 0) > #sText and string.sub( sOption, 1, #sText ) == sText then
            local sResult = string.sub( sOption, #sText + 1 )
            if bAddSpaces then
                table.insert( tResults, sResult .. " " )
            else
                table.insert( tResults, sResult )
            end
        end
    end

    return tResults
end

local tRedstoneSides = redstone.getSides()
local function completeSide( sText, bAddSpaces )
    return completeMultipleChoice( sText, tRedstoneSides, bAddSpaces )
end

local function completeFile( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), true, false )
    end
end

local function completeDir( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), false, true )
    end
end

local function completeEither( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), true, true )
    end
end

local function completeEitherN(max)
	local function completeEN(shell, index, text, previousText)
		if not max or index <= max then
			local results =  fs.complete( text, shell.dir(), true, true )

			for n = 1, #results do
				local result = results[n]

				if result:sub(-1) ~= "/" then
					results[n] = result .. " "
				end
			end

			return results
		end
	end

	return completeEN
end

local function completeProgram( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return shell.completeProgram( sText )
    end
end

shell.setCompletionFunction( "LunaOS/system/bin/cat", completeEitherN())
shell.setCompletionFunction( "LunaOS/system/bin/run", completeFile)
shell.setCompletionFunction( "LunaOS/system/bin/script", completeFile)
shell.setCompletionFunction( "LunaOS/system/bin/script", completeFile)
shell.setCompletionFunction( "LunaOS/system/bin/script", completeEither)
