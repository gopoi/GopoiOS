--[[ POSIG/0.0.1
  Name: GopoiLoader
  FullName: gopoiOS kernel bootstrapper for OpenComputers on default BIOS
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-25
  Arch: opencomputers
]]--

local bootloader = {
  version = "0.0.1",
  kernelName = "vmgopoi",
  kernelFilePath = "/boot/vmgopoi.lua",
  initrdFilePath = "/initrd.lua",
  kernelArgs = {
    root = {
      handle = computer.getBootAddress(),
      type = "filesystem",
    },
    initrd = nil,
    locale = unicode,
    arch = "opencomputers",
    binmode = "t"
  },
  invokeHandle = component.invoke
}

-- Map base components for the bootstrapping process
function bootloader.invoke(address, method, ...) -- From OpenComputers Lua BIOS
  local result = table.pack(pcall(bootloader.invokeHandle, address, method, ...))
  if not result[1] then
    return nil, result[2]
  else
    return table.unpack(result, 2, result.n)
  end
end

function bootloader.tryLoad(address, filePath)
  local handle, reason = bootloader.invoke(address, "open", filePath)
  if not handle then
    return nil, reason
  end
  local buffer = ""
  repeat
    local data, reason = bootloader.invoke(address, "read", handle, math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  bootloader.invoke(address, "close", handle)
  return buffer
end


---- Load initrd
local reason
if (bootloader.initrdFilePath and initrdFilePath ~= "") then
  bootloader.initrd, reason = bootloader.tryLoad(computer.getBootAddress(), bootloader.initrdFilePath)
  if not bootloader.initrd then
    error("Cannot load initrd:" .. bootloader.initrdFilePath .. " :" .. tostring(reason))
  end
end


---- Load kernel
bootloader.kernel, reason = bootloader.tryLoad(computer.getBootAddress(), bootloader.kernelFilePath, bootloader.kernelName)
if not bootloader.kernel then
  error("Cannot load Kernel:" .. bootloader.kernelFilePath .. " :" .. tostring(reason))
end
bootloader.kernelArgs.posig = bootloader.kernel
bootloader.kernel = load(bootloader.kernel, "=" .. bootloader.kernelName)

---- Cleanup some shits
bootloader.tryLoad = nil
---- Boot kernel
bootloader.kernelArgs.initrd = bootloader.initrd
success, reason = pcall(bootloader.kernel, bootloader.kernelArgs) -- pass a table as an arg for now

if not success then
    error(reason, 0)
end
computer.beep(2000, 1)
computer.beep(1000, 1)

