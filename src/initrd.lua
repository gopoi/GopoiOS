--[[ POSIG/0.0.1
  Name: Initrd
  FullName: gopoiOS kernel bootstrapper for OpenComputers
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-25
  Arch: OC
]]--


local initrd = {
  fsDriverName = "ocFs",
  fsDriverFilePath = "/lib/modules/drivers/oc/fs.ko.lua",
  vfsModulePath = "/lib/modules/vfs.ko.lua",
  vfsName = "vfs",
}

function initrd.tryLoad(address, filePath, fileName)
  local handle, reason = component.invoke(address, "open", filePath)
  assert(handle, reason)
  local buffer = ""
  repeat
    local data, reason = component.invoke(address, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  component.invoke(address, "close", handle)
  return kernel.loadString(buffer, fileName)
end

function initrd.bootstrap(kernel, bootargs)
  initrd.kernel = kernel
  initrd.fsDriverLoader = kernel.utils.tcall(initrd.tryLoad, "Cannot load fsDriver: " 
                                       .. initrd.fsDriverFilePath, 
                                       computer.getBootAddress(), 
                                       initrd.fsDriverFilePath, 
                                       initrd.fsDriverName)
  -- Get Fs driver
  initrd.fsDriver = kernel.utils.tcall(initrd.fsDriverLoader, 
                                              "Error while loading fsDriver")
  initrd.fsDriverLoader = nil

  -- Load Filesystem module with the Fs driver
  initrd.vfsDriverLoader = kernel.utils.tcall(initrd.tryLoad,  "Error while loading:" 
                                                             .. initrd.vfsName, 
                                                             computer.getBootAddress(), 
                                                             initrd.vfsModulePath, initrd.vfsName)
  
  kernel.vfs = initrd.vfsDriverLoader().init("/", initrd.fsDriver, computer.getBootAddress())
  initrd.vfsDriverLoader = nil
  initrd.tryLoad = nil
end


function initrd.boot()



end


return initrd