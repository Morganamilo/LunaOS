local oldFs = fs


--list = oldFs.list

list = function(path)
	local list = oldFs.list(path)
	return list
end

exists = oldFs.exists
isDir = oldFs.isDir
isReadOnly = oldFs.isReadOnly
getName = oldFs.getName
getDrive = oldFs.getDrive
getSize = oldFs.getSize
getFreeSpace = oldFs.getFreeSpace
makeDir = oldFs.makeDir
move = oldFs.move
copy = oldFs.copy
delete = oldFs.delete
combine = oldFs.combine
open = oldFs.open
find = oldFs.find
getDir = oldFs.getDir
complete = oldFs.complete