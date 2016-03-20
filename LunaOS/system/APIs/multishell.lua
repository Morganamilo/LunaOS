function getCurrent()
	return kernel.getRunning()
end

function getCount()
	return kernel.getProcessCount()
end

function launch(env, path, ...)
	kernel.runFile(path, nil, nil, nil, unpack(arg))
end

function setFocus(PID)
	kernel.gotoPID(PID)
end

function setTitle(PID)

end

function getTitle(PID)
	return kernel.getProcess(PID).title
end

function getFocus()
	kernel.getRunning()
end