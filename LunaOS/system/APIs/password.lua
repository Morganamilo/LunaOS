local dataPath = "/LunaOS/data/system/password"
local saltPath = fs.combine(dataPath, "salt")
local passwordPath = fs.combine(dataPath, "hash")
local permissionDenied = errorUtils.strings.permDenied

local function generateSalt()
	local salt = ""
 
	for n = 1, 64 do
		salt = salt .. string.char(math.random(33,126))
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

local function isPasswordInternal(password)
	if not (fs.exists(saltPath) and fs.exists(passwordPath)) then
		setPassword("")
	end
	
	local salt = getSalt()
	local hashedPassword = getPassword()
	local hash = sha256.hash(salt .. password)
	
	return hash == hashedPassword
end

function hasPassword()
	return not isPasswordInternal("")
end

function isPassword(password)
	errorUtils.assert(kernel.isSU(), permissionDenied, 2)
	return isPasswordInternal(password)
end

function setPassword(password)
	errorUtils.assert(kernel.isSU(), permissionDenied, 2)
	
	local salt = generateSalt()
	local hash = sha256.hash(salt .. password)

	local passwordFile = fs.open(passwordPath, "w")
	passwordFile.write(hash)
	passwordFile.close()

	local saltFile = fs.open(saltPath, "w")
	saltFile.write(salt)
	saltFile.close()
end
