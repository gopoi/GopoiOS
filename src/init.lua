--[[ NON-POSIG/NON-PORTABLE
  gopoiOS kernel bootstrapper for OpenComputers
  Non portable
  Author: Shan B.
  Date: 2015-04-25
]]--
local bootloader = {}
bootloader.version = "0.0.1"
bootloader.kernelName = "vmgopoz"
bootloader.kernelFilePath = "/boot/vmgopoz.lua"
bootloader.fsDriverName = "ocFs"
bootloader.fsDriverFilePath = "/lib/modules/arch/fs/ocFs.ko.lua"
bootloader.kernelArgs = {
  arch = "oc",
  root = computer.getBootAddress(),
  locale = unicode,
  }
bootloader.invokeHandle = component.invoke


-- Map base components for the bootstrapping process
function bootloader.invoke(address, method, ...) -- From OpenComputers Lua BIOS
  local result = table.pack(pcall(bootloader.invokeHandle, address, method, ...))
  if not result[1] then
    return nil, result[2]
  else
    return table.unpack(result, 2, result.n)
  end
end

function bootloader.tryLoad(address, filePath, fileName)
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
  return load(buffer, "=" .. fileName)
end

---- Locate and map Gpu and screen
local screen = component.list("screen")()
local gpu = component.list("gpu")()
local gpuEnabled = false
local w, h
if gpu and screen then
  bootloader.invoke(gpu, "bind", screen)
  w, h = bootloader.invoke(gpu, "getResolution")
  bootloader.invoke(gpu, "setResolution", w, h)
  bootloader.invoke(gpu, "setBackground", 0x000000)
  bootloader.invoke(gpu, "setForeground", 0xFFFFFF)
  bootloader.invoke(gpu, "fill", 1, 1, w, h, " ")
  gpuEnabled = true
end

---- Locate and load kernel Fs driver 
local reason
if (bootloader.fsDriverFilePath and fsDriverFilePath ~= "") then
  bootloader.fsDriver, reason = bootloader.tryLoad(computer.getBootAddress(), bootloader.fsDriverFilePath, bootloader.fsDriverName)
  if not bootloader.fsDriver then
    error("Cannot load fsDriver:" .. bootloader.fsDriverFilePath .. " :" .. tostring(reason))
  end
end


---- Load kernel
bootloader.kernel, reason = bootloader.tryLoad(computer.getBootAddress(), bootloader.kernelFilePath, bootloader.kernelName)
if not bootloader.kernel then
  error("Cannot load Kernel:" .. bootloader.kernelFilePath .. " :" .. tostring(reason))
end

---- Boot kernel
bootloader.kernelArgs.fsDriver = bootloader.fsDriver
success, reason = pcall(bootloader.kernel, bootloader.kernelArgs) -- pass a table as an arg for now

if not success then
  if gpuEnabled then
    bootloader.invoke(gpu, "setBackground", 0x000A91)
    bootloader.invoke(gpu, "fill", 1, 1, w, h, " ")
    local i = 1
    reason = reason .. "\n"
    local text = reason:gmatch("(.-)\n")
    for line in text do
      bootloader.invoke(gpu, "set", 1, i, line)
      i = i + 1
    end
    if i == 1 then
      bootloader.invoke(gpu, "set", 1, 1, reason)
    end
  end
    error(reason)
end
computer.beep(2000, 1)
computer.beep(1000, 1)

