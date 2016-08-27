local dataPath = "/LunaOS/data/system/password"
local saltPath = fs.combine(dataPath, "salt")
local passwordPath = fs.combine(dataPath, "hash")

local function generateSalt()
	local salt = ""
 
	for n = 1,64 do
		salt = salt .. math.random(0,9)
	end
	
	return salt
end

local function makeFiles()
	fs.open(saltPath, "w").close()
	fs.open(passwordPath, "w").close()
end

local function getSalt()
	local file = fs.open(saltPath, "r")
	local data = file.readAll()
	file.close()
	
	return data
end

local function getPassword()
	local file = fs.open(passwordPath, "r")
	local data = file.readAll()
	file.close()
	
	return data
end

function isPassword(password)
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	
	if not (fs.exists(saltPath) and fs.exists(passwordPath)) then
		makeFiles()
	end
	
	local salt = getSalt()
	local hashedPassword = getPassword()
	local hash = sha256.hash(salt .. password)
	
	return hash == hashedPassword
end


function setPassword(password)
	errorUtils.assert(kernel.isSU(), "Error: permission denied", 2)
	
	local salt = generateSalt()
	local hash = sha256.hash(salt .. password)

	local passwordFile = fs.open(passwordPath, "w")
	passwordFile.write(hash)
	passwordFile.close()

	local saltFile = fs.open(saltPath, "w")
	saltFile.write(salt)
	saltFile.close()
end