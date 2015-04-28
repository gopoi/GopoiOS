--[[ NON-POSIG
  gopoiOS kernel
  Author: Shan B.
  Date: 2015-04-25
]]--


-- Startup shits
local kernel = {}
kernel.filesystemFilePath = "/lib/modules/vfs.ko.lua"
kernel.filesystemName = "vfs"

local success, result 

-- Basic kernel functions
local baseError = error
function error(errmsg)
  baseError("-------- Catastrophic derp Error -------- \r\n" .. tostring(errmsg))
end 


-- Parse arguments
kernel.bootargs = table.pack(...)[1] -- single table as arg for now

-- Get Fs driver
local fsLambda = kernel.bootargs.fsDriver
if not fsLambda then
  error("Missing kernel boot arg: fsDriver")
end
success, result = pcall(fsLambda)
if not success then
  error("Error while loading fsDriver: " .. tostring(result))
end 
fsLambda = nil
kernel.bootstrapDriver = result
kernel.rootMountpoint = result.init(kernel.bootargs.root)

-- vfs bootstrap
function vfsBootstrap(filePath, fileName)
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
success, result = pcall(vfsBootstrap(kernel.filesystemFilePath, kernel.filesystemName ))
if not success then
  error("Error while loading:" .. kernel.filesystemName .. " :" .. tostring(result)) 
end
kernel.filesystem = result()
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