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
  --assert(kernel.posig.isCompatible(kernel.posig.getInfo(kernel.posig.getHeader(buffer))), )
  --return load(buffer, "=" .. fileName)
end

function initrd.bootstrap(kernel, bootargs)
  local result
  local success
  
  --success, result = pcall(initrd.tryLoad, computer.getBootAddress(), initrd.fsDriverFilePath, initrd.fsDriverName)
  --assert(success, "Cannot load fsDriver:" .. initrd.fsDriverFilePath .. " :" .. tostring(result))
  --initrd.fsDriver = result
  initrd.fsDriver = kernel.utils.tcall(initrd.tryLoad, "Cannot load fsDriver: " 
                                       .. initrd.fsDriverFilePath, 
                                       computer.getBootAddress(), 
                                       initrd.fsDriverFilePath, 
                                       initrd.fsDriverName)
  -- Get Fs driver
  --success, result = pcall(initrd.fsDriver)
  --assert(success, "Error while loading fsDriver: " .. tostring(result))
  --initrd.bootstrapDriver = result
  initrd.bootstrapDriver = kernel.utils.tcall(initrd.fsDriver, 
                                              "Error while loading fsDriver")
  

  -- Load Filesystem module with the Fs driver
  success, result = pcall(initrd.tryLoad, computer.getBootAddress(), initrd.vfsModulePath, initrd.vfsName)
  assert(success, "Error while loading:" .. initrd.vfsName .. " :" .. tostring(result)) 
  kernel.vfs = result().init("/", initrd.bootstrapDriver, computer.getBootAddress())
end


return initrd