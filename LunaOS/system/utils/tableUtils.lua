function isIn(tbl, value)
	errorUtils.expect(tbl, "table", true)
	
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
	
	return false
end

function range(tbl, start, finish)
	errorUtils.expect(tbl, "table", true)
	errorUtils.expect(start, "number", true)
	errorUtils.expect(finish, "number", true)
	
	local tempTbl = {}
	start = start or 1
	finish = finish or #tbl

	for i = start, finish do
		tempTbl[#tempTbl + 1] = tbl[i]
	end
	
	return tempTbl
end

function getEmptyIndex(tbl)
	errorUtils.expect(tbl, "table", true)
	
	for i = 1, table.getn(tbl) + 1 do
		if not tbl[i] then return i end
	end
end

function removeEmptyIndexes(tbl) --removes empty slots in tables by changing the keys
	local tempTable = {}
	
	for _, v in pairs(tbl) do
		if v then tempTable[#tempTable + 1] = v end
	end
	
	return tempTable
end

function copy(tbl)
	errorUtils.expect(tbl, "table", true)
	
	if type(tbl) ~= 'table' then return tbl end
	local tempTbl = {}

	for k, v in pairs(tbl) do 
		tempTbl[k] = v
	end
	
	return tempTbl
end

-- local function deepCopyInternal(obj, seen)
  -- --Handle non-tables and previously-seen tables.
  -- if type(obj) ~= 'table' then return obj end
  -- if seen and seen[obj] then return seen[obj] end

  -- --New table; mark it as seen and copy recursively.
  -- local s = seen or {}
  -- local res = setmetatable({}, getmetatable(obj))
  -- s[obj] = res
  
 
 -- for k, v in pairs(obj) do 
	-- res[deepCopyInternal(k, s)] = deepCopyInternal(v, s)
 -- end
 
  -- return res
-- end

function deepCopyInternal(obj, seen)
	--Handle non-tables and previously-seen tables.
	if type(obj) ~= 'table' then return obj end
	if seen[obj] then return seen[obj] end
	
	local mt = getmetatable(obj)
	local mtRes = deepCopyInternal(mt, seen)
	local res = setmetatable({}, mtRes)
	
	if mt then seen[mt] = mtRes end
	seen[obj] = res

	for k, v in pairs(obj) do 
		res[deepCopyInternal(k, seen)] = deepCopyInternal(v, seen)
	end
	
	return res
end

function deepCopy(tbl)
	return deepCopyInternal(tbl, {})
end



function lowestIndex(tbl)
	errorUtils.expect(tbl, "table", true)
	
	local lowest
	
	for k in pairs(tbl) do 
		if not lowest or k < lowest then
			lowest = k
		end
	end
	
	return k
end

function combine(tbl1, tbl2)
	errorUtils.expect(tbl1, "table", true)
	errorUtils.expect(tbl2, "table", true)
	
	local tempTbl = {}
	
	for _,v in pairs(tbl1) do
		tempTbl[#tempTbl + 1] = v
	end
	
	for _,v in pairs(tbl2) do
		tempTbl[#tempTbl + 1] = v
	end
	
	return tempTbl
end

