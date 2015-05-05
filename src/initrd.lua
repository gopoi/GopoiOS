


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
  return load(buffer, "=" .. fileName)
end

function initrd.bootstrap(kernel, bootargs)
  local result
  local success
  success, result = pcall(initrd.tryLoad, computer.getBootAddress(), initrd.fsDriverFilePath, initrd.fsDriverName)
  assert(success, "Cannot load fsDriver:" .. initrd.fsDriverFilePath .. " :" .. tostring(result))
  initrd.fsDriver = result
  
  -- Get Fs driver
  success, result = pcall(initrd.fsDriver)
  assert(success, "Error while loading fsDriver: " .. tostring(result))
  initrd.bootstrapDriver = result

  -- Load Filesystem module with the Fs driver
  success, result = pcall(initrd.tryLoad, computer.getBootAddress(), initrd.vfsModulePath, initrd.vfsName)
  assert(success, "Error while loading:" .. initrd.vfsName .. " :" .. tostring(result)) 
  kernel.vfs = result().init("/", initrd.bootstrapDriver, computer.getBootAddress())
end


return initrd