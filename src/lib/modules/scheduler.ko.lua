--[[ POSIG/0.0.1
	 Name: scheduler
	 FullName: Scheduler for all the processes that needs to run
	 Package: net.gopoi.gopoios
	 Version: 0.0.1
	 Author: Simon Bastien-Filiatrault
	 Dependencies: vmgopoz = 0.0.1	 
	 Arch: Portable
]]--

local kernelAssert = kernelAssert
local kernelPanic = kernalPanic
local coroutine = coroutine
local sandbox = require("isolation.ko")



--List of all processes
local processes = {}

--Definition of process object
local process = {}
process.__index = process






------------------------------------------------------------
--Working on process
function process:resume() --it has been scheduled

result, data = coroutine.resume(self.coroutine)

end

function process:exit()

end



function process:new(parent, file, priority)
	self = setmetatable({}, self)
	self.priority = priority
	--?
	processes[#processes + 1] = self
	--/?
	self.couroutine = couroutine.create(kernel.loadFile(file, sandbox))
	
end

------------------------------------------------------------

local function schedule()

end



return process, processes, schedule