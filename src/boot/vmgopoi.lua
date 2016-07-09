--[[ POSIG/0.0.1
  Name: vmgopoz
  FullName: gopoiOS kernel
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: portable
]]--

-------------------------------------------------------------------------------
-- Kernel Declarations
local kernel = {
  modules = {
    loaded = {},
  },
  base = {
    arch = nil,
    initrd = nil,
    locale = nil,
    --header = nil,
  },
  posig = {
    utils = {},
  },
  asserting = {},
  logging = {
    logs = {},
  },
  utils = {},
  ipc = {
    coroutines = {},
  },
}
-- Kernel Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Assertion features
function kernel.asserting.getStack()
  if (debug and debug.traceback) then
    local stack = ""
    return debug.traceback(nil, 3):gsub("\t", " >"):gsub("stack traceback:", "")
  else
    return "debug not available"
  end
end

function kernel.asserting.recusiveFormatTable(info, level)
  local str = ""
  local tab = ""
  for i=0, level do
    if (i == level) then
      tab = tab .. ">"
    elseif (i == level - 1) then
      tab = tab .. "|-"
    else
      tab = tab .. "| "
    end
  end
  for i, v in pairs(info) do
    str = str .. tab .. tostring(i) .. " : " .. tostring(v) .. "\n"
    if (type(v) == "table") then
      str = str .. kernel.asserting.recusiveFormatTable(v, level + 1)
    end
  end
  return str
end

function kernel.asserting.panic(catch, ...)
  local info = table.pack(...)
  local msg = catch and catch.msg or "Undefined"
  local stack = catch and catch.stack or "Undefined"
  if (type(msg) == "table") then
    table.insert(info, msg)
  end
  error("\n-------------- Catastrophic Derp occurred! --------------\n" ..
        "A fatal error occurred in the kernel and broke everything\n" ..
        "Error message: " .. tostring((msg)) .. "\n" ..
        "Stack traceback: " .. stack .. "\n" ..
        "Additional information:" ..
        "\n" .. kernel.asserting.recusiveFormatTable(info, 1) ..
        "----------------------- End Trace -----------------------\n", 0)
end

function kernel.asserting.catch(msg)
  local catch = {
    stack = kernel.asserting.getStack(),
    msg = msg,
    }
  return catch
end
-- Kernel Assertion features
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Utils utilities
function kernel.utils.uptime() -- This function must be ovverided by a module
  return 0
end
-- Kernel Utils features
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel LOG utilities
function kernel.logging.log(level, msg, time)
  local log = {
    level = level,
    msg = msg,
    time = time or kernel.utils.uptime(),
  }
  kernel.logging.logs:insert(log)
end

function kernel.logging.dinfo(msg, time)
  kernel.logging.log(0, msg, time)
end

function kernel.logging.dwarn(msg, time)
  kernel.logging.log(1, msg, time)
end

function kernel.logging.derr(msg, time)
  kernel.logging.log(2, msg, time)
end

function kernel.logging.dcrit(msg, time)
  kernel.logging.log(3, msg, time)
end
-- Kernel LOG features
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel POSIG utilities
function kernel.posig.utils.getHeader(data)
  local start = string.find(data, "POSIG")
  local stop = string.find(data, "%]", start)
  return string.sub(data, start - 1, stop)
end

function kernel.posig.utils.formatHeader(header)
  local expressions = {}
  -- split and remove \n\r and whitespaces
  for part in posigHeader:gmatch("[^\n]+") do
    part = part:gsub("\r", "")
    part = part:gsub(" ", "")
    table.insert(expressions, part)
  end
  return expressions
end

function kernel.posig.utils.checkHeader(expressions)
  local pos, ver = expressions[1]:match("([^/]+)/([^/]+)")
  return (pos == "POSIG"), ver
end

function kernel.posig.utils.getInfo(expressions)
  local info = {}
  -- Get all attributes and values
  for _, part in pairs(expressions) do
    local k, v = part:match("([^:]+):(.+)")
    if k and v then
      info[tostring(k):lower()] = tostring(v)
    end 
  end
  return info
end

function kernel.posig.parseHeader(data)
  local header = kernel.posig.utils.getHeader(data)
  local expressions = kernel.posig.utils.formatHeader(header)
  local isPosig, ver = kernel.posig.utils.checkHeader(expressions)
  assert(isPosig, "No POSIG header found", 2)
  table.remove(expressions, 1)
  local info = kernel.posig.utils.getInfo(expressions)
  info.posigVersion = ver
  return info
end

function kernel.posig.isCompatible(posigInfo)
  return (posigInfo.arch and (posigInfo.arch == "portable" or posigInfo.arch == kernel.arch))
end
-- Kernel POSIG utilities
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Modules utilities
function kernel.modules.probe(name)
  
  
  
end

function kernel.modules.unprobe(name)
  --[[if kernel.modules.loaded[name].unprobe then
    kernel.modules.loaded[name].unprobe()
  else
    kernel.logging.derr("Module " .. tostring(name) .. " cannot be unprobed")
  end]]
end

function kernel.modules.insmod(fileData, name)
  assert(kernel.modules.loaded[name] == nil, "Module " .. name .. " already exists", 2)
  kernel.base.load(fileData, name)
  local posig = kernel.posig.parseHeader(data)
  assert(kernel.posig.isCompatible(posig), "Architecture not compatible", 2)
  local ctor, err = load(data, "=" .. name)
  assert(ctor, err, 2)
  local mod = {
    handle = ctor(),
    posig = posig,
  }
  assert(mod.handle, "Error while running module " .. name, 2)
  assert(mod.handle.insmod, "No insmod found in module " .. name, 2)
  mod.handle.insmod()
  kernel.modules.loaded[name] = mod
end

function kernel.modules.rmmod(name)
  --[[assert(kernel.modules.name, "Module not found")
  kernel.modules.unprobe(name)
  kernel.modules.loaded[name] = nil]]
end
-- Kernel Modules utilities
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Main functions
function kernel.base.load(data, name)
  local posig = kernel.posig.parseHeader(data)
  assert(kernel.posig.isCompatible(posig), "Architecture not compatible", 0)
  local ctor, err = load(data, "=" .. name)
  assert(ctor, err)
  return ctor, posig
end

function kernel.base.boot(...)
  local bootargs = table.pack(...)[1] 
  assert(bootargs, "No bootargs found, Halting!", 0)
  assert(bootargs.initrd, "No initrd file found, Halting!", 0)
  kernel.base.initrd = kernel.base.load(bootargs.initrd, bootargs.initrdName)()
  kernel.base.initrd.bootstrap(kernel)
  kernel.base.initrd.boot(kernel)
end

function kernel.base.run()
  
  
end

-------------------------------------------------------------------------------
-- Kernel Entry point
local success, result = xpcall(kernel.base.boot, kernel.asserting.catch, ...)
if not success then
  kernel.asserting.panic(result, kernel)
end

success, result = xpcall(kernel.base.run, kernel.asserting.catch)
if not success then
  kernel.asserting.panic(result, kernel)
else
  local catch = kernel.asserting.catch("Kernel exited run mode")
  kernel.asserting.panic(catch, kernel)
end
