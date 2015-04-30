--[[ POSIG/0.0.1
  Name: vmgopoz
  FullName: gopoiOS kernel
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: Portable
]]--


-- Startup shits
_ENV.kernel = {
  vfsModulePath = "/lib/modules/vfs.ko.lua",
  vfsName = "vfs"
}
local kernel = _ENV.kernel
local success, result 

function kernelPanic(...)
  local text = ""
  for _, v in pairs(table.pack(...)) do
    text = text .. tostring(v) .. "\n"
  end
  error("\n-------- Catastrophic Derp occured! --------\nKernel Trace: " .. text .. "-------- End Trace --------\n", 2)
end

function kernelAssert(condition, ...)
  if not condition then
    kernelPanic(...)
  end
end

-- Parse arguments
kernel.bootargs = table.pack(...)[1] -- single table as arg for now


-- Load some shits
kernel.locale = kernel.bootargs.locale

-- Get Fs driver
local fsLambda = kernel.bootargs.fsDriver
kernelAssert(fsLambda, "Missing kernel boot arg: fsDriver")
success, result = pcall(fsLambda)
kernelAssert(success, "Error while loading fsDriver: " .. tostring(result))
kernel.bootstrapDriver = result
kernel.rootMountpoint = result.init(kernel.bootargs.root)
fsLambda = nil

-- vfs bootstrap
local function vfsBootstrap(filePath, fileName)
  local handle, reason = kernel.rootMountpoint:open(filePath)
  if not handle then
    return nil, reason
  end
  local buffer = ""
  repeat
    local data, reason = handle:read(math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  handle:close()
  return load(buffer, "=" .. fileName)
end

-- Load Filesystem module with the Fs driver
success, result = pcall(vfsBootstrap, kernel.vfsModulePath, kernel.vfsName)
kernelAssert(success, "Error while loading:" .. kernel.vfsName .. " :" .. tostring(result)) 
--kernel.rootMountpoint:close()
--kernel.rootMountpoint = nil

kernel.vfs = result().init("/", kernel.rootMountpoint)

--local testFile = kernel.vfs:open("/lib/tempSharedLibrary.so.lua", "r")

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