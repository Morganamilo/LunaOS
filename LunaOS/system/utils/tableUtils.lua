function isIn(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
	
	return false
end

function range(tbl, start, finish)
	local tempTbl = {}
	start = start or 1
	finish = finish or #tbl

	for i = start, finish do
		tempTbl[#tempTbl + 1] = tbl[i]
	end
	
	return tempTbl
end

function getEmptyIndex(tbl)
	for i = 1, table.getn(tbl) + 1 do
		if not tbl[i] then return i end
	end
end

function optimize(tbl) --removes empty slots in tables by changing the keys
	local size = table.getn(tbl)
	local i = 1
	local tempTable = {}
	
	for _, v in pairs(tbl) do
		if v then tempTable[#tempTable + 1] = v end
	end
	
	return tempTable
end

function copy(tbl)
	local tempTbl = {}

	for k, v in pairs(tbl) do 
		tempTbl[k] = v
	end
	
	return tempTbl
end

function deepCopy(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen an copy recursively.
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
 
 for k, v in pairs(obj) do 
	res[deepCopy(k, s)] = deepCopy(v, s)
 end
  return res
end

function lowestIndex(tbl)
	local lowest
	
	for k, _ in pairs(tbl) do 
		if not lowest or k < lowest then
			lowest = k
		end
	end
	
	return k
end