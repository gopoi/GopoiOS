--[[ POSIG/0.0.1
  Name: ocfs
  FullName: OpenComputers Filesystem Driver
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-26
  Arch: opencomputers
]]--

local ocfs = {
  devType = "filesystem", -- the LL for opencomputers
  devClass = "fs",  -- Class for udev
  partType = "ocfs", -- part type for vfs
  devices = {},
}
ocfs.__index = ocfs
local ocfsdev = {
  isOpened = false,
  handle = nil,
}
ocfsdev.__index = ocfsdev
local ocfsdrv = {
  dev = nil,
}
ocfsdrv.__index = ocfsdrv
local ocfsfile = {
  dev = nil,
  fd = nil,
}
ocfsfile.__index = ocfsfile

-------------------------------------------------------------------------------
-- ocfs Device Helpers
local function isCompatible(device)
  return component.type(device) == ocfs.devType
end

local function listDrives()
  local drives = {}
  for a in component.list(ocfs.devType) do
    if isCompatible(a) then
      --local name = component.invoke(a, "getLabel") or ocfs.vfsType
      table.insert(drives, a)-- {handle = a, label = name})
    end
  end
  return drives
end
-- ocfs Device Helpers
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocfs Device file actions : This part drive file itself (/dev/fs/fs1)
function ocfsdev:close()
  self.isOpened = false
end

function ocfsdev:write()
  error("This device doesn't support writing", 2)
end

function ocfsdev:read()
  return ocfs.partType
end

function ocfsdev:seek()
  error("This device doesn't support writing", 2)
end

function ocfsdev:ioctl(action, ...)
  if self.isOpened == true then
    return component.invoke(self.handle, action, ...)
  else
    error("Device not opened")
  end
end

function ocfsdev:isopen()
  return self.isOpened();
end

function ocfsdev:open()
  if self.isOpened == true then
    return nil
  else
    self.isOpened = true
    return self
  end
end
-- ocfs Device file actions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocfs file actions
function ocfsfile:close()
  self.dev:ioctl("close", self.fd)
  self.dev = nil
end

function ocfsfile:seek(whence, offset)
  return self.dev:ioctl("seek", self.fd, whence, offset)
end

function ocfsfile:write(value)
  return self.dev:ioctl("write", self.fd, value)
end

function ocfsfile:read(count)
  return self.dev:ioctl("read", self.fd, count)
end

function ocfsfile:opened()
  return not (self.dev == nil)
end

function ocfsfile:ioctl()
  return nil
end
-- ocfs file actions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocfs Driver actions
function ocfsdrv:openFile(path, options)
  local fh = setmetatable({__gc = ocfsfile.close}, ocfsfile)
  fh.fd = self.dev:ioctl("open", path, options)
  fh.dev = self.dev
  return fh
end

-- Disk space related methods
function ocfsdrv:getUsedSpace()
  return self.dev:ioctl("spaceUsed")
end

function ocfsdrv:getCapacity()
  return self.dev:ioctl("spaceTotal")
end

function ocfsdrv:getFreeSpace()
  return self:getCapacity() - self:getUsedSpace()
end

-- Filesystem general methods
function ocfsdrv:getLabel()
  return self.dev:ioctl("getLabel")
end

function ocfsdrv:setLabel(label)
  return self.dev:ioctl("setLabel", label)
end

function ocfsdrv:isReadOnly()
  return self.dev:ioctl("isReadOnly")
end

function ocfsdrv:exists(path)
  return self.dev:ioctl("exists", path)
end

function ocfsdrv:isDirectory(path)
  return self.dev:ioctl("isDirectory", path)
end

function ocfsdrv:lastModified(path)
  return self.dev:ioctl("lastModified", path)
end

function ocfsdrv:move(source, target)
  return self.dev:ioctl("rename", source, target)
end

function ocfsdrv:remove(path)
  return self.dev:ioctl("remove", path)
end

function ocfsdrv:size(path)
  return self.dev:ioctl("size", path)
end

function ocfsdrv:makeDirectory(path)
  return self.dev:ioctl("makeDirectory", path)
end

function ocfsdrv:removeDirectory()
  local success = false
  if self:isDirectory(path) then
    success = self.dev:ioctl("remove", path)
  end
  return success
end

function ocfsdrv:listDirectory(path)
  return self.dev:ioctl("list", path)
end
-- ocfs Driver actions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocfs Module actions
function ocfs.new(dev)
  local fs = setmetatable({}, ocfsdrv)
  assert(dev:read() == ocfs.partType, "Wrong part type!")
  fs.dev = dev --should be opened
  return fs
end

function ocfs.probe()
  local drives = listDrives()
  local devices = {}
  for _, drive in ipairs(drives) do
    if ocfs.devices[drive] then
      devices[drive] = ocfs.devices[drive]
    else
      local dev = setmetatable({__gc = ocfsdev.close}, ocfsdev)
      dev.opened = false
      dev.handle = drive
      devices[drive] = dev
    end
  end 
  ocfs.devices = devices
  return devices
end

function ocfs.insmod(posig)
  local vfs = require("vfs")
  --local udev = require("udev")
  if udev then
    udev.attach(ocfs.devClass, ocfs)
  end
  if vfs then
    vfs.attach(ocfs.partType, ocfs)
  end
  return ocfs
end
-- ocfs Module actions
-------------------------------------------------------------------------------
return ocfs