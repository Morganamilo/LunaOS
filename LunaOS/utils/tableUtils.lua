function isInTable(tbl, element)
	for _, v in pairs(tbl) do if v == element then return end end
end

function range(tbl, start, finish)
	local tempTbl = {}

	for i = start, finish do
		tempTbl[#tempTbl + 1] = tbl[i]
	end
	
	return tempTbl
end