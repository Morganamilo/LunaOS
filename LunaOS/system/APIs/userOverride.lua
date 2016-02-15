--overrides certain APIs that so that non root processes cant access them

function os.shutdown()
	kernel.killProcess(kernel.getRunning())
end

os.retstart = os.shutdown