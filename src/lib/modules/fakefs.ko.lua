--[[ POSIG/0.0.1
  Name: fakefs
  FullName: gopoiOS Fake Filesystem
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: portable
]]--

local fakefs = {
  vfsType = "fakefs", -- part type for vfs\
}
fakefs.__index = fakefs
local fakefsdrv = {
  label = "",
}
fakefsdrv.__index = fakefsdrv
-------------------------------------------------------------------------------
-- ocfs Device Helpers


-- ocfs Device Helpers
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocfs vfs Driver actions
function fakefsdrv:openFile(path, options)
  local fh = self.dev:ioctl("open", path, options)
  return fh
end

-- Disk space related methods
function fakefsdrv:getUsedSpace()
  return self.dev:ioctl("spaceUsed")
end

function fakefsdrv:getCapacity()
  return self.dev:ioctl("spaceTotal")
end

function fakefsdrv:getFreeSpace()
  return self:getCapacity() - self:getUsedSpace()
end

-- Filesystem general methods
function fakefsdrv:getLabel()
  return self.dev:ioctl("getLabel")
end

function fakefsdrv:setLabel(label)
  return self.dev:ioctl("setLabel", label)
end

function fakefsdrv:isReadOnly()
  return self.dev:ioctl("isReadOnly")
end

function fakefsdrv:exists(path)
  return self.dev:ioctl("exists", path)
end

function fakefsdrv:isDirectory(path)
  return self.dev:ioctl("isDirectory", path)
end

function fakefsdrv:lastModified(path)
  return self.dev:ioctl("lastModified", path)
end

function fakefsdrv:move(source, target)
  return self.dev:ioctl("rename", source, target)
end

function fakefsdrv:remove(path)
  return self.dev:ioctl("remove", path)
end

function fakefsdrv:size(path)
  return self.dev:ioctl("size", path)
end

function fakefsdrv:makeDirectory(path)
  return self.dev:ioctl("makeDirectory", path)
end

function fakefsdrv:removeDirectory()
  local success = false
  if self:isDirectory(path) then
    success = self.dev:ioctl("remove", path)
  end
  return success
end

function fakefsdrv:listDirectory(path)
  return self.dev:ioctl("list", path)
end
-- ocfs vfs Driver actions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocfs Driver actions


-- ocfs Driver actions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocfs Module actions
function fakefs.new(dev)
  local fs = setmetatable({}, fakefsdrv)
  fs.dev = dev
  return fs
end

function fakefs.insmod(posig)
  local vfs = require("vfs")
  if vfs then
    vfs.attach(fakefs.vfsType, fakefs)--{handle = ocfsdrv, type = ocfs.vfsType})
  end
  return fakefs
end
-- ocfs Module actions
-------------------------------------------------------------------------------
return fakefs

