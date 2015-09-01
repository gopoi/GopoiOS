--[[ POSIG/0.0.1
  Name: vmgopoz
  FullName: gopoiOS kernel
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: Portable
  Dependencies: vfs.ko, scheduler.ko
]]--

--[[ Kernel Defenitions ]]--
_ENV.kernel = {
  modules = {
    loaded = {}
    },
  arch = nil,
  posig = {},
  utils = {},
  report = {},
  vfs = nil,
  initrd = nil,
}
local kernel = _ENV.kernel
local success, result 

-------------------------------------------------------------------------------
-- Kernel Utilities features
local function kernelPanic(errorType, errorMsg, ...)

  -- Additionnal information parse
  local text = ""
  for _, v in pairs(table.pack(...)) do
    text = text .. tostring(v) .. "\n"
    if type(v) == "table" then
      for key, val in pairs(v) do
        text = text .. "   " .. tostring(key) .. "  : " .. tostring(val) .. "\n"
      end
    end 
  end
  
  -- error Msg parse
  errorMsg = errorMsg:gsub("\r", "")
  errorMsg = errorMsg:gsub("\n", "\n  ")
  errorMsg = errorMsg:gsub("\001", "\n  ")
  errorMsg = errorMsg:gsub("\002", "\n")
  
  error("-------------- Catastrophic Derp occurred! --------------\n" ..
        "A fatal error occurred in the kernel and broke everything\n" ..
        "Error type: " .. tostring(errorType) .. "\n" ..
        "Error message: \n\n" .. tostring((errorMsg)) .. "\n" ..
        "Additional information:" ..
        "\n" .. text ..
        "----------------------- End Trace -----------------------\n", 0)
end


function kernel.utils.assertFormat(message, assertStack)
  return "\001" .. tostring(message) .. "\002" .. tostring(assertStack or "")
end

function kernel.utils.tcall(func, message, ...)
	local result = table.pack(pcall(func, ...))
  if not result[1] then
    error(kernel.utils.assertFormat(message, result[2]), 2)
  end
  table.remove(result, 1)
  return table.unpack(result)
end

-------------------------------------------------------------------------------
-- Posig subsystem

function kernel.posig.getHeader(data)
  local start = string.find(data, "POSIG")
  local stop = string.find(data, "%]", start)
  return string.sub(data, start - 1, stop)
end

function kernel.posig.getInfo(posigHeader)
  local expressions = {}
  local info = {}
  for part in posigHeader:gmatch("[^\n]+") do
    part = part:gsub("\r", "")
    part = part:gsub(" ", "")
    table.insert(expressions, part)
  end
  local pos, ver = expressions[1]:match("([^/]+)/([^/]+)")
  assert(pos == "POSIG", kernel.utils.assertFormat("No POSIG header found"))
  info.posigVersion = ver
  table.remove(expressions, 1)
  for _, part in pairs(expressions) do
    local k, v = part:match("([^:]+):([^:]+)")
    if k and v then
      info[tostring(k)] = tostring(v)
    end 
  end
  return info
end

function kernel.posig.isCompatible(posigInfo)
  return (posigInfo.Arch and (posigInfo.Arch:lower() == "portable" or posigInfo.Arch:lower() == kernel.arch))
end

-------------------------------------------------------------------------------
-- Modules management


function kernel.modules.mount(mod)
  --assert(kernel.modules.loaded[mod.name], "Module already loaded")
  kernel.modules.loaded[mod.name] = mod
end

function kernel.modules.umount(mod)
  local out = {}
end



function kernel.readFile(path)
  local handle, reason = kernel.vfs:open(path, "r")
  assert(handle, reason)
  local buffer = ""
  repeat
    local data, reason = handle:read(math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  handle:close()
  return buffer
end

function kernel.loadString(data, name, env)
  local posig = kernel.posig.getHeader(data)
  assert(kernel.posig.isCompatible(kernel.posig.getInfo(posig)), kernel.utils.assertFormat("Architecture not compatible"))
  local returnVal, returnError = load(data, "=" .. name)
  assert(returnVal, kernel.utils.assertFormat(returnError))
  return returnVal, posig
end

function kernel.loadFile(path, env)
  local data = kernel.readFile(path)
  return kernel.loadString(data, path, env)
end


function runKernel(...)
--------------------------------------------------------------------
-- Pre boot (bootstrap)

-- Parse arguments
local bootargs = table.pack(...)[1] -- single table as arg for now
assert(bootargs.initrd, kernel.utils.assertFormat("No initrd file found!, Halting"))
assert(bootargs.locale, kernel.utils.assertFormat("No locale found!, Halting"))
kernel.locale = bootargs.locale

-- Parse Initrd POSIG and set kernel arch
kernel.initrdPOSIG = kernel.posig.getInfo(kernel.posig.getHeader(bootargs.initrd))
kernel.arch = kernel.initrdPOSIG.Arch:lower()
assert(kernel.arch, kernel.utils.assertFormat("No Arch found!, Halting"))

-- Load the initrd 
kernel.initrd = kernel.utils.tcall(kernel.loadString, "Error while trying to load the initrd file", bootargs.initrd, bootargs.initrdName)
kernel.initrd = kernel.utils.tcall(kernel.initrd, "Error while trying to running the initrd file")
bootargs.initrd = nil

-- Run the first initrd step to bootstrap vfs with a rootmountpoint
kernel.utils.tcall(kernel.initrd.bootstrap, "Error while running the initrd bootstrap", kernel, bootargs)


--------------------------------------------------------------------
-- Boot sequence

-- Run the initrd boot
kernel.utils.tcall(kernel.initrd.boot, "Error while running the initrd boot")


















local testFile = kernel.readFile("/lib/tempSharedLibrary.so.lua")
local header = kernel.posig.getHeader(testFile)
local info = kernel.posig.getInfo(header)

local derp = kernel.posig.isCompatible(info)
--kernel.report.panic("DERP", kernel.posig.isCompatible(info), info)
--kernel.report.panic("Arch", kernel.arch)


--local testFile = kernel.vfs:open("/lib/tempSharedLibrary.so.lua", "r")
--kernelAssert(success, result)
--kernelPanic("DER")
--kernelPanic(testFile:read(10))

--local drives = kernel.bootstrapDriver.listConnectedDevices()
--local mess = ""
--for k, v in pairs(drives) do
--  mess = mess .. k .. " : " .. v.label.."\n"
--end
--kernelPanic(mess)
--kernelPanic(kernel.bootstrapDriver.findDrive("tmpfs"))
--local newPart = kernel.bootstrapDriver.init(kernel.bootstrapDriver.findDrive("raid"))
--local device = kernel.vfs.drivers.filesystem.findDrive("raid")
kernel.vfs:mount("/mnt/test", "filesystem", kernel.vfs:findDrive("filesystem", "raid"))




--local mounts = kernel.vfs:mounts()
--local mess = ""
--for k, v in pairs(mounts) do
--  mess = mess .. k .. " : " .. tostring(v.path) .. " : " .. tostring(v.device) .. "\n"
--end
--kernelPanic(mess)
--local myPath = "/mnt/test/derp/derp.txt"
local myFile = kernel.vfs:open("/mnt/test/derp/derp.txt", "r")

error(myFile:read(10))


-- Create virtual filesystem




-- Attach Fs driver



-- Mount rootfs on 



-- Load and attach required kernel modules



-- Mount system filesystems



-- Sandbox everything



-- execute rc file



-- Start scheduling



-- Scheduling and shits



-- Shutdown 
end

local success, result = pcall(runKernel, ...)
if not success then
  kernelPanic("Kernel internal error", result)
end