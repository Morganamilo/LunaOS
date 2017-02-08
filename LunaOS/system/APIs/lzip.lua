function zip(path)
	local files = fs.listAllSubFiles(path, 1)
	local dirs = fs.listAllSubDirs(path, 1)
	local manifest = {files = {}, dirs = {}}

	for k, file in pairs(files) do
		local fullFile = fs.combine(path, file)

		local f = fs.open(fullFile, "r")

		if not f then
			error("Can not open file: " .. fullFile)
		end

		local data = f.readAll()
		f.close()
		manifest.files[file] = data
	end

	for k, dir in ipairs(dirs) do
		manifest.dirs[k] = dir
	end

	return jsonUtils.encode(manifest)
end

function zipToFile(path, savePath)
	local data = zip(path)

	local file = fs.open(savePath, "w")

	if not file then
		error("Can not open file: " .. file)
	end

	file.write(data)
	file.close()
end

function unZip(path)
	local f = fs.open(path, "r")

	if not f then
		error("Can not open file: " .. path)
	end

	local data = f.readAll()
	f.close()
	return jsonUtils.decode(data)
end

function unZipToDir(path, savePath)
	local data = unZip(path)

	local files = data.files
	local dirs = data.dirs

	for k, dir in pairs(dirs) do
		local fullPath = fs.combine(savePath, dir)
		fs.makeDir(fullPath)
	end

	for file, contents in pairs(files) do
		local fullPath = fs.combine(savePath, file)

		local file = fs.open(fullPath, "w")

		if not file then
			error("Can not open file: " .. fullPath)
		end

		file.write(contents)
		file.close()
	end
end
