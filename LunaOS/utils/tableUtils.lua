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

function getEmptyIndex(tbl)
	i = 1
	
	while tbl[i] do --we set the PID of the process to the lowest avalible PID
		i = i + 1
	end
	
	return i
end

function optimize(tbl) --removes emty slots it tabeles by reducing indexes
	local tempTbl = {}
	local size = 0
	local i = 1
	
	for k, v in pairs(tbl) do
		if type(k) == 'number' then size = size + 1 end
	end
	
	while true do
		if tbl[i] then
			tempTbl[#tempTbl + 1] = tbl[i]
			size = size - 1
		end
		
		if size == 0 then break end
		i = i + 1
	end
	
	return tempTbl
end