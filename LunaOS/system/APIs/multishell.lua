function multishell.getCurrent()
	return kernel.getRunning()
end

function multishell.getCount()
	return kernel.getProcessCount()
end

function multishell.launch(env, path, ...)
	return kernel.runFile(path, nil, nil, nil, unpack(arg))
end

function multishell.setFocus(PID)
	if kernel.getProcess(PID) then
		kernel.gotoPID(PID)
		return true
	else
		return false
	end
end

function multishell.setTitle(PID)

end

function multishell.getTitle(PID)
	return kernel.getProcess(PID).title
end

function multishell.getFocus()
	kernel.getRunning()
end