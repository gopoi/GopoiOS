--[[ POSIG/0.0.1
  Name: filesystem
  FullName: OpenComputers Filesystem Driver
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-26
  Arch: OpenOS
]]--


local ocFs = {}
local fileBase = {}
ocFs.__index = ocFs
fileBase.__index = fileBase
-------------------------------------------------------------------------------
-- Disk space related methods
function ocFs:getUsedSpace()
  return self.invoker(self.device, "spaceUsed")
end

function ocFs:getCapacity()
  return self.invoker(self.device, "spaceTotal")
end

function ocFs:getFreeSpace()
  return self:getCapacity() - self:getUsedSpace()
end
-------------------------------------------------------------------------------
-- Filesystem general methods
function ocFs:getLabel()
  return self.invoker(self.device, "getLabel")
end

function ocFs:setLabel(label)
  return self.invoker(self.device, "setLabel", label)
end

function ocFs:isReadOnly()
  return self.invoker(self.device, "isReadOnly")
end

-------------------------------------------------------------------------------
-- File/Folder related methods
function ocFs:exists(path)
  return self.invoker(self.device, "exists", path)
end

function ocFs:isDirectory(path)
  return self.invoker(self.device, "isDirectory", path)
end

function ocFs:lastModified(path)
  return self.invoker(self.device, "lastModified", path)
end

function ocFs:move(source, target)
  return self.invoker(self.device, "rename", source, target)
end

function ocFs:remove(path)
  return self.invoker(self.device, "remove", path)
end

function ocFs:size(path)
  return self.invoker(self.device, "size", path)
end

function ocFs:makeDirectory(path)
  return self.invoker(self.device, "makeDirectory", path)
end

function ocFs:removeDirectory()
  local success = false
  if self:isDirectory(path) then
    success = self.invoker(self.device, "remove", path)
  end
  return success
end

function ocFs:listDirectory(path)
  return self.invoker(self.device, "list", path)
end

-------------------------------------------------------------------------------
-- Symlinks related methods
function ocFs:canLink()
  return false
end

function ocFs:isLink()
  return false
end

function ocFs:makeLink()
  return false
end

function ocFs:removeLink()
  return false
end

function ocFs:listLink()
  return nil
end

-------------------------------------------------------------------------------
-- File handle related methods
function fileBase:close()
  self.invoker(self.device, "close", self.handle)
end

function fileBase:seek(whence, offset)
  return self.invoker(self.device, "seek", self.handle, whence, offset)
end

function fileBase:write(value)
  return self.invoker(self.device, "write", self.handle, value)
end

function fileBase:read(count)
  return self.invoker(self.device, "read", self.handle, count)
end

function ocFs:open(path, mode)
  local newFile = setmetatable({}, fileBase)
  newFile.handle = self.invoker(self.device, "open", path, mode or "r")
  newFile.device = self.device
  newFile.invoker = self.invoker
  return newFile
end

-------------------------------------------------------------------------------
-- Driver related methods
function ocFs:detach()

end

function ocFs.isCompatible(device, invoker)
  return true
end

function ocFs.init(device, invoker)
  if not invoker then
    invoker = component.invoke
  end
  local self = setmetatable({}, ocFs)
  kernelAssert(ocFs.isCompatible(device, invoker), "Device is not compatible with this driver.")
  self.device = device
  self.invoker = invoker
  return self
end

-------------------------------------------------------------------------------
-- Returns the driver
return ocFs