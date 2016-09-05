local function swap(tbl, i, j, k)
	tbl[i], tbl[j] = tbl[j], tbl[i]
end

function indexOf(tbl, value)
	errorUtils.expect(tbl, "table", true)
	
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
end

function binarySearch(tbl,searchFor)
	return binarySearchInternal(tbl, searchFor, 1, #tbl)
end

function binarySearchInternal(tbl, searchFor, low, high) 
	local mid = math.floor(high + low / 2)
	local value = tbl[mid]
	
	if  low > high then
		return nil
	elseif value < searchFor then
		return binarySearchInternal(tbl, searchFor, mid + 1, high)
	elseif value > searchFor then
		return binarySearchInternal(tbl, searchFor, low, mid - 1)
	else
		return mid
	end
end

function range(tbl, start, finish)
	errorUtils.expect(tbl, "table", true)
	errorUtils.expect(start, "number", false)
	errorUtils.expect(finish, "number", false)
	
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

 function deepCopy(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end

  local no
  if type(o) == 'table' then
    no = {}
    seen[o] = no

    for k, v in next, o, nil do
      no[deepCopy(k, seen)] = deepCopy(v, seen)
    end
    setmetatable(no, deepCopy(getmetatable(o), seen))
  else -- number, string, boolean, etc
    no = o
  end
  return no
end

function lowestIndex(tbl)
	errorUtils.expect(tbl, "table", true)
	
	local lowest
	
	for k in pairs(tbl) do 
		if not lowest or k < lowest then
			lowest = k
		end
	end
	
	return lowest
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

function removeValue(tbl, value)
	for i = 1, table.getn(tbl) do
		if value == tbl[i] then table.remove(tbl, i) end
	end
end

function printTable(tbl)
	for k,v in pairs(tbl) do
		print(k, v )
	end
end

local function quickSort(tbl, comparator, low, high)
	if low >= high then return end
	
	local i = low - 1
	local j = high
	local lowEqual = i
	local highEqual = j
	
	local pivot = tbl[high]
	
	while true do
		repeat
			i = i + 1
		until comparator(tbl[i], pivot) >= 0
		
		repeat
			j = j- 1
			if j == low then break end
		until comparator(tbl[j], pivot) <= 0
	
		if i >= j then break end
		swap(tbl, i, j)
		
		if comparator(tbl[i], pivot) == 0 then
			lowEqual = lowEqual + 1
			swap(tbl, i, lowEqual)
		end
		
		if comparator(tbl[j], pivot) == 0 then
			highEqual = highEqual - 1
			swap(tbl, j, highEqual)
		end
	end
	
	swap(tbl, i, high)
	j = i - 1; i = i + 1;
	
	for n = low, lowEqual - 1 do
		swap(tbl, n, j)
		j = j - 1
	end
	
	for n = high - 1, highEqual + 1, -1 do
		swap(tbl, n, i)
		i = i + 1
	end
	
	quickSort(tbl, comparator, low, j)
	quickSort(tbl, comparator, i, high)
end

function sort(tbl, comparator)
	quickSort(tbl, comparator, 1, #tbl)
end