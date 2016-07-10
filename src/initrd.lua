--[[ POSIG/0.0.1
  Name: Initrd
  FullName: gopoiOS kernel bootstrapper for OpenComputers
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-25
  Arch: opencomputers
]]--

local initrd = {
  fsDriverName = "ocFs",
  fsDriverPath = "/lib/modules/drivers/oc/fs.ko.lua",
  vfsModulePath = "/lib/modules/vfs.ko.lua",
  schedPath = "/lib/modules/scheduler.ko.lua",
  vfsName = "vfs",
}

function initrd.tryLoad(address, filePath)
  local handle, reason = component.invoke(address, "open", filePath)
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
  kernel.modules.insmod(initrd.tryLoad(root.handle,
                                          initrd.vfsModulePath),
                                          initrd.vfsName)
                                        
  kernel.modules.insmod(initrd.tryLoad(root.handle,
                                        initrd.fsDriverPath),
                                        initrd.fsDriverName)
  kernel.ipc.sendk("vfs", "initrd", "mount", table.pack("/", root))
  initrd.tryLoad = nil
end


function initrd.boot(kernel)
  local _, _, pack = kernel.ipc.sendk("vfs", "initrd", "readFile", table.pack(initrd.schedPath))
  local file = table.unpack(pack)
  kernel.modules.insmod(file)
  
  
  
  return "scheduler", "start"
end

return initrd