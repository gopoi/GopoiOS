--[[ POSIG/0.0.1
  Name: GopoiLoader
  FullName: gopoiOS kernel bootstrapper for OpenComputers
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-25
  Arch: OpenOS
]]--
local bootloader = {
  version = "0.0.1",
  kernelName = "vmgopoz",
  kernelFilePath = "/boot/vmgopoz.lua",
  initrdName = "initrd",
  initrdFilePath = "/initrd.lua",
  kernelArgs = {
    arch = "oc",
    root = computer.getBootAddress(),
    locale = unicode,
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

local reason
if (bootloader.initrdFilePath and initrdFilePath ~= "") then
  bootloader.initrd, reason = bootloader.tryLoad(computer.getBootAddress(), bootloader.initrdFilePath, bootloader.initrdName)
  if not bootloader.initrd then
    error("Cannot load initrd:" .. bootloader.initrdFilePath .. " :" .. tostring(reason))
  end
end

---- Load kernel
bootloader.kernel, reason = bootloader.tryLoad(computer.getBootAddress(), bootloader.kernelFilePath, bootloader.kernelName)
if not bootloader.kernel then
  error("Cannot load Kernel:" .. bootloader.kernelFilePath .. " :" .. tostring(reason))
end

---- Boot kernel
bootloader.kernelArgs.fsDriver = bootloader.fsDriver
bootloader.kernelArgs.initrd = bootloader.initrd
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

