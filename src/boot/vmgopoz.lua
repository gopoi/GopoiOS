--[[ POSIG/0.0.1
  Name: vmgopoz
  FullName: gopoiOS kernel
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: Portable
]]--

--[[ Kernel Defenitions ]]--
_ENV.kernel = {
  modules = {
    fs = {}
    },
  arch = nil,
  posig = {},
  vfs = nil,
  initrd = nil,
}
local kernel = _ENV.kernel
local success, result 

local function kernelPanic(errorType, errorMsg, ...)
  local text = ""
  for _, v in pairs(table.pack(...)) do
    text = text .. tostring(v) .. "\n"
    if type(v) == "table" then
      for key, val in pairs(v) do
        text = text .. "   " .. tostring(key) .. "  : " .. tostring(val) .. "\n"
      end
    end 
  end
  error("-------------- Catastrophic Derp occurred! --------------\n" ..
        "A fatal error occurred in the kernel and broke everything\n" ..
        "Error type: " .. tostring(errorType) .. "\n" ..
        "Error message: " .. tostring(errorMsg) .. "\n" ..
        "Additional information:" ..
        "\n" .. text ..
        "----------------------- End Trace -----------------------\n", 0)
end

local function kernelAssert(condition, ...)
  if not condition then
    kernelPanic("Assertion failed", ...)
  end
end

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
  assert(pos == "POSIG")
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

function kernel.modules.load(mod)

end

function kernel.modules.mount(mod)

end

function kernel.modules.umount(mod)

end

function kernel.modules.list()
  
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
  return load(data, "=" .. name, "t", env) --need to be able to load with env for isolation, text mode to be sure
end

function kernel.loadFile(path, env)
  return kernel.loadString(kernel.loadFile(path), path, env) --recursive function without exit option!
end


-- Parse arguments
local bootargs = table.pack(...)[1] -- single table as arg for now
kernelAssert(bootargs.initrd, "No initrd file found!, Halting", bootargs)
kernelAssert(bootargs.locale, "No locale found!, Halting", bootargs)
kernel.locale = bootargs.locale
success, result = pcall(bootargs.initrd)
kernelAssert(success, "Error while trying to load the initrd file", result)
kernel.initrd = result
-- Run the first initrd step to bootstrap vfs with a rootmountpoint
success, result = pcall(kernel.initrd.bootstrap, kernel, bootargs)
kernelAssert(success, result)












-- Get Fs driver
--local fsLambda = kernel.bootargs.fsDriver
--kernelAssert(fsLambda, "Missing kernel boot arg: fsDriver")
--success, result = pcall(fsLambda)
--kernelAssert(success, "Error while loading fsDriver: " .. tostring(result))
--kernel.bootstrapDriver = result
--kernel.rootMountpoint = result.init(kernel.bootargs.root)
--fsLambda = nil






-- Load Filesystem module with the Fs driver
--success, result = pcall(tryLoad, kernel.vfsModulePath, kernel.vfsName)
--kernelAssert(success, "Error while loading:" .. kernel.vfsName .. " :" .. tostring(result)) 
--kernel.vfs = result().init("/", kernel.rootMountpoint)

-- Load the loader to finish the bootstrap process
--success, result = pcall(tryLoad, kernel.loaderModulePath, kernel.loaderName)
--kernelAssert(success, "Error while loading:" .. kernel.loaderName .. " :" .. tostring(result)) 
--kernel.loader = result().init()
---- End Bootstrap process ----
--tryLoad = nil










--kernel.rootMountpoint:close()
--kernel.rootMountpoint = nil



--function durr()
--  error("ASDASDASD")
--end

--success, result = pcall(durr)

local testFile = kernel.readFile("/lib/tempSharedLibrary.so.lua")
local header = kernel.posig.getHeader(testFile)
local info = kernel.posig.getInfo(header)

local derp = kernel.posig.isCompatible(info)
--kernelPanic("DERP", kernel.posig.isCompatible(info), info)



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
--kernel.vfs:mount("/mnt/test", newPart )




--local mounts = kernel.vfs:mounts()
--local mess = ""
--for k, v in pairs(mounts) do
--  mess = mess .. k .. " : " .. tostring(v.path) .. " : " .. tostring(v.device) .. "\n"
--end
--kernelPanic(mess)
--local myPath = "/mnt/test/derp/derp.txt"
--local myFile = kernel.vfs:open("/mnt/test/derp/derp.txt", "r")

--kernelPanic(myFile:read(10))


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