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

function geEmptyIndex(tbl)
	i = 1
	
	while tbl[i] do --we set the PID of the process to the lowest avalible PID
		i = i + 1
	end
	
	return i
end

function optimize(tbl) --removes emty slots it tabeles by reducing indexes
	local tempTbl = {}
	
	for _, v it pairs(tbl) do
		tempTbl[#tempTbl + 1] = v
	end
	
	return tempTbl
end