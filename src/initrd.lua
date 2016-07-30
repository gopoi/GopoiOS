--[[ POSIG/0.0.1
  Name: Initrd
  FullName: gopoiOS kernel bootstrapper for OpenComputers
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-25
  Arch: opencomputers
]]--

local initrd = {
  fsD = "ocfs",
  vfs = "vfs",
  modulesPath = {
    "/lib/modules/",
    "/lib/modules/drv/oc/",
      },
}

function initrd.tryLoad(address, filePath)
  local handle, reason = component.invoke(address, "open", filePath .. ".ko.lua")
  assert(handle, reason)
  local buffer = ""
  repeat
    local data, reason = component.invoke(address, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  component.invoke(address, "close", handle)
  return buffer
end

function initrd.bootstrap(kernel)
  local root = kernel.base.root
  local mp = initrd.modulesPath
  kernel.utils.setSetting("modulesPath", initrd.modulesPath)
  -- VFS
  kernel.modules.insmod(initrd.tryLoad(root.handle,
                                       mp[1] .. initrd.vfs))
  -- FS Driver         
  kernel.modules.insmod(initrd.tryLoad(root.handle,
                                       mp[2] .. initrd.fsD))
  -- Mount root
  local ocfs = require("ocfs")
  local vfs = require("vfs")
  local devs = ocfs.probe()
  local dev = devs[root.handle]
  vfs.mount("/", "ocfs", dev:open())
  require("logpanic")
  -- Setup udev
  local udev = require("udev")
  vfs.mount("/dev", "fakefs", udev)
  udev.attach(ocfs.devClass, ocfs)
  udev.refresh()
  
 
  local file = vfs.openFile("/test.txt", "r") 
  
  error(file:read(2))
  
  error(drv)
  error("OK")
  return true
end

function initrd.boot()
  require("scheduler")
  require("fakefs")
  require("udev")
  
  error(computer.freeMemory())
  return "scheduler", "start", table.pack()
end

return initrd