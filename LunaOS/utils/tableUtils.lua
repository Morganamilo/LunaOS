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
	for i = 1, table.getn(tbl) do
		if not tbl[i] then return i end
	end
	
	return table.getn(tbl) + 1
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

function isInTable(tbl, element)
	for k, v in pairs(tbl) do
		if v == element then return k end
	end
	
	return false
end