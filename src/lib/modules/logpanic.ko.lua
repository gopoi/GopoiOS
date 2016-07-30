--[[ POSIG/0.0.1
  Name: logpanic
  FullName: gopoiOS Panic Logging
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: portable
]]--
local logpanic = {
  oldPanic = nil,
}

local function prvPanicHandler(msg)
  local vfs = require("vfs")
  local file = vfs.openFile("/panic.log", "w") 
  file:write(msg)
  file:close()
end

function logpanic.panicHandler(msg)
  local success, val = pcall(prvPanicHandler, msg)
  logpanic.oldPanic(msg)
end

-------------------------------------------------------------------------------
-- logpanic module methods
function logpanic.insmod(posig)
  local kernel = require("kernel")
  logpanic.oldPanic = kernel.asserting.panicHandler
  kernel.asserting.panicHandler = logpanic.panicHandler
  return logpanic
end

return logpanic