--[[ POSIG/0.0.1
  Name: Initrd
  FullName: gopoiOS kernel bootstrapper for OpenComputers
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-25
  Arch: opencomputers
  Dependencies: vmgopoz.ko, vfs.ko; net.gopoi.gopoios : test.ko, derp.kp; info.sbernard.corelib
  SoftDependencies: systemd.ko, libuser.ko; localdomain.localhost : udev.ko; net.gopoi.gopoios
]]--

local initrd = {
  fsDriverName = "ocFs",
  fsDriverPath = "/lib/modules/drivers/oc/fs.ko.lua",
  vfsModulePath = "/lib/modules/vfs.ko.lua",
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
  --return initrd.kernel.base.load(buffer, fileName)
  return buffer
end

function initrd.bootstrap(kernel)
  local root = kernel.base.root
  --initrd.kernel = kernel
  --Fs driver
  --[[initrd.fsDriverLoader = initrd.tryLoad(computer.getBootAddress(), 
                                          initrd.fsDriverFilePath, 
                                          initrd.fsDriverName)
  initrd.fsDriver = initrd.fsDriverLoader()
  initrd.fsDriverLoader = nil]]

  -- Load Filesystem module with the Fs driver
  --[[kernel.modules.insmod( initrd.tryLoad(computer.getBootAddress(),
                                        initrd.fsDriverPath),
                                        initrd.fsDriverName)]]
                                        
  --local test = initrd.tryload(computer.getBootAddress(), initrd.vfsModulePath)
 -- initrd.kernel.modules.insmod( test,
   --                                     initrd.vfsName)
  kernel.modules.insmod(initrd.tryLoad(root.handle,
                                          initrd.vfsModulePath),
                                          initrd.vfsName)
                                        
  kernel.modules.insmod(initrd.tryLoad(root.handle,
                                        initrd.fsDriverPath),
                                        initrd.fsDriverName)
  --error(computer.freeMemory())
  --error(kernel.modules.loaded.vfs.handle.drivers)
  kernel.ipc.sendk("vfs", "initrd", "mount", table.pack("/", root))
  initrd.tryLoad = nil
end


function initrd.boot()



end

return initrd