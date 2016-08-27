local properties = jsonUtils.decodeFile("/LunaOS/system/properties.json")

function getProp(prop)
	return properties[prop]
end

local function generateSalt()
	local salt = ""
 
	for n = 1,64 do
		salt = salt .. math.random(0,9)
	end
	
	return salt
end

function setPassword(password)
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	
	local dataPath = packageHandler.getPackageDataPath("keygaurd")
	local passwordPath = fs.combine(dataPath, "hash")
	local saltPath = fs.combine(dataPath, "salt")

	if #password == 0 then
		local passwordFile = fs.open(passwordPath, "w")
		passwordFile.close()
	
		local saltFile = fs.open(saltPath, "w")
		saltFile.close()
		
		return
	end
	
	local salt = generateSalt()
	local hash = sha256.hash(salt .. password)

	local passwordFile = fs.open(passwordPath, "w")
	passwordFile.write(hash)
	passwordFile.close()

	local saltFile = fs.open(saltPath, "w")
	saltFile.write(salt)
	saltFile.close()
end