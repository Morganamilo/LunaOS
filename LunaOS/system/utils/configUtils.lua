---Allows for easy editing of config files stored in json format.
--Json files mat be easily created, read and edited.
--@author Morganamilo
--@copyright Morganamilo 2016
--@module configUtils


---Creates a configEditor object that can be used to manipulate json files.
--@param path The path to the json file.
--@param readable wether or not the json file should be saved in human readable format.
--@return A configEditor object.
--@usage local editor = configUtils.configEditor(path, false)
function configEditor(path, readable)
	errorUtils.expect(path, "string", true)
	errorUtils.assert(fs.hasReadPerm(path), "Can not open " .. path, 2)

	local self = {}
	local data = {}
	
	--if the file already exits read it and store the data in a table
	if fs.isFile(path) then
		local success
		local file = fs.open(path, 'r')
		success, data = pcall(jsonUtils.decodeFile, path)
		file.close()
		
		errorUtils.assert(success, "Error: invalid json file", 2)
	end

	---Gets a value from the config file. 
	--@param k The key of the valie.
	--@return The value from the config file with key k.
	--@usage local value = config.get(4)
	function self.get(k)
		return data[k]
	end
	
	--if we dont have write permission then dont unclude the write functions
	if not fs.hasWritePerm(path) then return self end
	
	---Sets a value in the config file.
	--@param k the key to write at
	--@param v the value to write to the config file
	--@usage config.set(4, "9")
	function self.set(k, v)
		k = k or table.getn(data) + 1
		data[k] = v
	end

	---Saves changes and writes them back to the files
	--@usage config.save()
	function self.save()
		local file = fs.open(path, 'w')
		file.write(jsonUtils.encode(data, readable))
		file.close()
	end
	
	return self
end