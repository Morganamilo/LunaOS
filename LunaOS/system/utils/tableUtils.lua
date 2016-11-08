---The tableUtils API provides function to manipulate tables.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module tableUtils


---Swaps two elements in a table.
--@param tbl The table.
--@param i The first element.
--@param j The seconds element
--@usage tableUtils.swap(tbl, 1, 2)
local function swap(tbl, i, j)
	tbl[i], tbl[j] = tbl[j], tbl[i]
end

---Searches through a table and finds the first key with the given value.
--@param tbl The table to search.
--@param value The value to seach for.
--@return the key of the value if the value exists. nil otherwise.
--@raise type error - if tbl is not a value
--@usage local k = tableUtils.indexOf(tbl, 9)
function indexOf(tbl, value)
	errorUtils.expect(tbl, "table", true)
	
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
end

---Searches through a table and finds the first key with the Given Value.
--The table must be sorted in accending order.
--If multiple keys have the same value there is no defined behaviour for wich key is returned.
--@param tbl The table to seach.
--@param searchFor The value to search for.
--@param low The key to search from.
--@param high The ket to search to.
--@return the key of the value if the value exists. nil otherwise.
--@usage local k = binarySearchInternal(tbl, 9)
local function binarySearchInternal(tbl, searchFor, low, high)
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

---Public call for binarySearchInternal, acts the same but ommits the low and high variables.
--@param tbl The table to seach.
--@param searchFor The value to search for.
--@return the key of the value if the value exists. nil otherwise.
--@usage local k = tableUtils.binarySearch(tbl, 9)
--@see binarySearchInternal
function binarySearch(tbl,searchFor)
	return binarySearchInternal(tbl, searchFor, 1, #tbl)
end

---Copies part of a table to a new table starting with the key 1.
--@param tbl The table to copy.
--@param start The point to start copying from.
--@param finish The point to copy upto.
--@return A copy of the table containint the elements from tbl[start] to tbl[finish].
--@raise type error - if tbl is not a table<br>
--raise type error - if start is not a number<br>
--raise type error - if finish is not a number
--@usage local newTbl = tableUtils.range(tbl, 4, 8)
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

---Gets the lowest positive index where tnl[n-1] ~= nil and tbl[n] = nil.
--@param tbl A table.
--@return The lowest positive index where tnl[n-1] ~= nil and tbl[n] = nil.
--@raise type error - if tbl is not a table
--@usage local i = tableUtils.getEmptyIndex(tbl)
function getEmptyIndex(tbl)
	errorUtils.expect(tbl, "table", true)
	
	return #tbl + 1
end

---Copies values from tbl, starting at index 1 and ignores nil values.
--@param tbl A table.
--@return A new tables with the similar to tbl but with nil values removed.
--@raise type error - if tbl is not a table
--@usage local newTbl = tableUtils.removeEmptyIndexes(tbl)
function removeEmptyIndexes(tbl)
    errorUtils.expect(tbl, "table", true)
	local tempTable = {}

	for _, v in pairs(tbl) do
		if v then tempTable[#tempTable + 1] = v end
	end
	
	return tempTable
end

---Copies a table non recursively.
--If a non table is passed then the value is returned.
--@param tbl The table to copy.
--@return A copy of the table (tables withing the table are not copied).
--@raise type error - if tbl is not a table
--@usage tblCopy = tableUtils.copy(tbl)
function copy(tbl)
	errorUtils.expect(tbl, "table", true)
	
	if type(tbl) ~= 'table' then return tbl end
	local tempTbl = {}

	for k, v in pairs(tbl) do 
		tempTbl[k] = v
	end
	
	return tempTbl
end

--Copies a table recursively, including all sub tables and meta tables.
--@param value The table to copy.
--@param seen A table of seen values.
--@return A coppy of value including sub tables and meta tables.
--@usge tblCopy = tableUtils.copy(tbl)
function deepCopy(value, seen)
  seen = seen or {}
  if value == nil then return nil end
  if seen[value] then return seen[value] end

  local copy
  if type(value) == 'table' then
    copy = {}
    seen[value] = copy

    for k, v in next, value, nil do
      copy[deepCopy(k, seen)] = deepCopy(v, seen)
    end
    setmetatable(copy, deepCopy(getmetatable(value), seen))
  else -- number, string, boolean, etc
    copy = value
  end
  return copy
end

---Gets the lowest numberical key from a table.
--@param tbl A table.
--@return The lowest numberical key from a table.
function lowestIndex(tbl)
	errorUtils.expect(tbl, "table", true)
	
	local lowest
	
	for k in ipairs(tbl) do
		if not lowest or k < lowest then
			lowest = k
		end
	end
	
	return lowest
end

---Combine two tables together into a new table.
--The first table will be given keys 1 to n and the second will be given kets n + 1 to n + m
--@param tbl1 A table.
--@param tbl2 Another table.
--@return A combination of both tables.
--@raise type error - if tbl1 or tbl2 is not a table
--@usage local tbl3 = tableUtils.combine(tbl1, tbl2)
function combine(tbl1, tbl2)
	errorUtils.expect(tbl1, "table", true)
	errorUtils.expect(tbl2, "table", true)
	
	local tempTbl = {}
	
	for _,v in ipairs(tbl1) do
		tempTbl[#tempTbl + 1] = v
	end
	
	for _,v in ipairs(tbl2) do
		tempTbl[#tempTbl + 1] = v
	end
	
	return tempTbl
end

---Removes every instance of a value from a table.
--@param tbl The table.
--@param value The value to remove.
--@usage tableUtils.removeValue(tbl, 4)
function removeValue(tbl, value)
	for i = 1, table.getn(tbl) do
		if value == tbl[i] then table.remove(tbl, i) end
	end
end

---Prints a tanle out in as key pairs.
--@param tbl The table to print.
--@usage tableUtils.printTable(tbl)
function printTable(tbl)
	for k,v in pairs(tbl) do
		print(k, v)
	end
end
