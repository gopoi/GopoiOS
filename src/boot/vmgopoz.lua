--[[ NON-POSIG
  gopoiOS kernel
  Author: Shan B.
  Date: 2015-04-25
]]--


-- Startup shits
local kernel = {}
kernel.vfsModulePath = "/lib/modules/vfs.ko.lua"
kernel.vfsName = "vfs"

local success, result 

local function kernelPanic(...)
  local text = ""
  for _, v in pairs(table.pack(...)) do
    text = text .. v .. "\n"
  end
  error("\n-------- Catastrophic Derp occured! --------\nKernel Trace: " .. text .. "-------- End Trace --------\n")
end

local function assertKernel(condition, ...)
  if condition == true then
    kernelPanic(...)
  end
end

-- Parse arguments
kernel.bootargs = table.pack(...)[1] -- single table as arg for now

-- Get Fs driver
local fsLambda = kernel.bootargs.fsDriver
if not fsLambda then
  kernelPanic("Missing kernel boot arg: fsDriver")
end
success, result = pcall(fsLambda)
if not success then
  kernelPanic("Error while loading fsDriver: " .. tostring(result))
end 
fsLambda = nil
kernel.bootstrapDriver = result
kernel.rootMountpoint = result.init(kernel.bootargs.root)

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
if not success then
  kernelPanic("Error while loading:" .. kernel.vfsName .. " :" .. tostring(result)) 
end
kernel.vfs = result()
--kernelPanic("dfgdfg")
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