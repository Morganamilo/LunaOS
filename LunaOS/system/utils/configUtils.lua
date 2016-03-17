function configEditor(path, readable)
	errorUtils.expect(path, "string", true)
	errorUtils.assert(fs.hasReadPerm(path), 2)

	local self = {}
	local data = {}
	
	if fs.isFile(path) then
		local success
		local file = fs.open(path, 'r')
		success, data = pcall(jsonUtils.decodeFile, path)
		file.close()
		
		errorUtils.assert(success, "Error: invalid json file", 2)
	end

	function self.get(k)
		return data[k]
	end
	
	if not fs.hasWritePerm(path) then return self end
	
	function self.set(k, v)
		k = k or table.getn(data) + 1
		data[k] = v
	end

	function self.save()
		local file = fs.open(path, 'w')
		file.write(jsonUtils.encode(data, readable))
		file.close()
	end
	
	return self
end