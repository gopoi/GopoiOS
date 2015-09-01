--[[ POSIG/0.0.1
	 Name: scheduler
	 FullName: Scheduler for all the processTable that needs to run
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
<<<<<<< Updated upstream




--processTable
local processTable = {}
processTable.

=======



--processTable
local processTable = {}
processTable.
>>>>>>> Stashed changes

--Definition of process object
local process = {}
process.__index = process
process.posig = {}





------------------------------------------------------------
--Working on process
function process:resume() --it has been scheduled will return result and data for dispatch

result, data = coroutine.resume(self.coroutine)
return result, data
end
<<<<<<< Updated upstream

function process:exit()

>>>>>>> Stashed changes
=======

function process:exit()

>>>>>>> Stashed changes
end



<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
function process:new(parent, file, priority, posig)
	self = setmetatable({}, self)
	self.priority = priority
	self.posig = posig
	processTable[#processTable + 1] = self
	self.couroutine = couroutine.create(kernel.loadFile(file, sandbox))
	
end

------------------------------------------------------------

local function schedule()

end



return process, processTable, schedule