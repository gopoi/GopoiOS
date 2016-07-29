--[[ POSIG/0.0.1
  Name: vmgopoi
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
    runlevel = 0,
    arch = nil,
    locale = nil,
    initrd = nil,
    binmode = nil,
    posig = nil,
  },
  bare = {
    load = load,
    require = require,
  },
  posig = {
    utils = {},
  },
  asserting = {},
  logging = {
    logs = {},
  },
  utils = {},
  exec = {},
  ipc = {
    coroutines = {},
  },
  settings = {},
}

kernel.modules.loaded.kernel = {
  handle = kernel,
  posig = kernel.base.posig
}

local assertedTables = {}
-- Kernel Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Assertion features
function kernel.asserting.getStack()
  if (debug and debug.traceback) then
    return debug.traceback(nil, 3):gsub("\t", " >"):gsub("stack traceback:", "")
  else
    return "debug not available"
  end
end

function kernel.asserting.recusiveFormatTable(info, level)
  local str = ""
  local tab = ""
  for i=0, level - 2, 1 do
    tab = tab .. "| "
  end
  tab = tab .. "|"
  for i, v in pairs(info) do
    str = str .. tab .. "->" .. tostring(i) .. " : " .. tostring(v) .. "\n"
    if (type(v) == "table" and (next(v) ~= nil) and assertedTables[i] == nil) then
      assertedTables[i] = v
      str = str .. kernel.asserting.recusiveFormatTable(v, level + 1)  .. tab .. "\n"
    end
  end
  return str 
end

function kernel.asserting.panic(catch, ...)
  local info = table.pack(...)
  local msg = catch and catch.msg or "Undefined"
  local stack = catch and catch.stack or "Undefined"
  if (type(msg) == "table") then
    table.insert(info, 1, msg)
  end
  assertedTables = {}
  error("\n-------------- Catastrophic Derp occurred! --------------\n" ..
        "A fatal error occurred in the kernel and broke everything.\n" ..
        "Error message: " .. tostring((msg)) .. "\n" ..
        "Stack traceback: " .. tostring(stack) .. "\n" ..
        "Additional information:" ..
        "\n" .. tostring(kernel.asserting.recusiveFormatTable(info, 1)) ..
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
-- Kernel POSIG utilities
function kernel.posig.utils.getHeader(data)
  local start = string.find(data, "POSIG")
  local stop = string.find(data, "%]", start)
  return string.sub(data, start - 1, stop)
end

function kernel.posig.utils.formatHeader(header)
  local expressions = {}
  -- split and remove \n\r and whitespaces
  for part in header:gmatch("[^\n]+") do
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
  header = nil
  local isPosig, ver = kernel.posig.utils.checkHeader(expressions)
  assert(isPosig, "No POSIG header found.", 2)
  table.remove(expressions, 1)
  local info = kernel.posig.utils.getInfo(expressions)
  info.posigVersion = ver
  return info
end

function kernel.posig.isCompatible(info)
  return (info.arch and (info.arch == "portable" or info.arch == kernel.base.arch))
end
-- Kernel POSIG utilities
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Utils utilities
function kernel.utils.uptime() -- This function must be ovverided by a module
  return 0
end

function kernel.utils.setRunLevel(runlevel)
  assert(runlevel >= 0 and runlevel <= 6, "invalid runlevel!")
  kernel.base.runlevel = runlevel
end

function kernel.utils.setSetting(key, val)
  kernel.settings[key] = val
end

function kernel.utils.getSetting(key)
  return kernel.settings[key]
end
-- Kernel Utils features
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Load utilities
function kernel.exec.load(data, env)
  local posig = kernel.posig.parseHeader(data)
  assert(kernel.posig.isCompatible(posig), "Architecture not compatible: " .. 
                                            tostring(posig.arch), 0)
  local ctor, err = kernel.bare.load(data, "=" .. posig.name, 
                                     kernel.base.binmode, env)
  assert(ctor, err)
  return ctor, posig
end

function kernel.exec.exec(data, env)
  local ctor, posig = kernel.exec.load(data, env)
  return ctor(), posig
end

load = function(data, env)
  return kernel.exec.load(data, env)
end

require = function(name)
  if kernel.modules.isLoaded(name) then
    return kernel.modules.get(name)
  else
    return nil
  end
end
-- Kernel Load features
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
-- Kernel Modules utilities
function kernel.modules.insmod(fileData)
  local img, posig = kernel.exec.exec(fileData)
  assert(kernel.modules.loaded[posig.name] == nil, "Module " .. posig.name .. 
                                                    " already exists.", 2)
  assert(img, "Error while running module " .. posig.name, 2)
  assert(img.insmod, "No insmod found in module " .. posig.name, 2)
  local mod = {
    handle = img.insmod(posig),
    posig = posig,
  }
  kernel.modules.loaded[posig.name] = mod
  return mod
end

function kernel.modules.isLoaded(name)
  return (type(kernel.modules.loaded[name]) == "table")
end

function kernel.modules.get(name)
  assert(kernel.modules.loaded[name], "Module not found")
  return kernel.modules.loaded[name].handle
end

function kernel.modules.getPosig(name)
  assert(kernel.modules.loaded[name], "Module not found")
  return kernel.modules.loaded[name].posig
end

function kernel.modules.rmmod(name)
end
-- Kernel Modules utilities
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel IPC functions
function kernel.ipc.exists(name)
  return (kernel.ipc.coroutines[name])
end

function kernel.ipc.add(name, handle)
  assert(not kernel.ipc.exists(name), "Coroutine name already taken.")
  assert(handle, "Handle is nil.")
  assert(type(handle) == "function" or type(handle) == "thread", 
        "Handle must be a thread or a function.")
  if (type(handle) == "function") then
    handle = coroutine.create(handle)
  end
  kernel.ipc.coroutines[name] = handle
end

function kernel.ipc.remove()
  assert(kernel.ipc.exists(name), "Coroutine not found.")
  kernel.ipc.coroutines[name] = nil
end

function kernel.ipc.send(dest, action,  args)
  return coroutine.yield(dest, action, args)
end

function kernel.ipc.sendk(dest, src, action, arg)
  local success
  success, dest, action, arg = coroutine.resume(kernel.ipc.coroutines[dest], 
                                                src, action, arg)
  assert(success, dest)
  return dest, action, arg
end
-- Kernel IPC utilities
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Kernel Main functions
function kernel.base.boot(...)
  local bootargs = ...
  assert(bootargs, "No bootargs found, Halting!", 0)
  assert(bootargs.initrd, "No initrd file found, Halting!", 0)
  assert(bootargs.arch, "No arch found, Halting!", 0)
  assert(bootargs.root, "No root found, Halting!", 0)
  assert(bootargs.posig, "No posig susbystem found, Halting!", 0)
  kernel.base.arch = bootargs.arch
  kernel.base.initrd = kernel.exec.exec(bootargs.initrd)
  kernel.base.root = bootargs.root
  kernel.base.posig = kernel.posig.parseHeader(bootargs.posig)
  kernel.base.binmode = bootargs.binmode
  bootargs.posig = nil
  bootargs.initrd = nil
  bootargs.root = nil
  bootargs.arch = nil
  bootargs = nil
  local success = kernel.base.initrd.bootstrap(kernel)
  if not success then
    error("Could not bootstrap the kernel, Halting!")
  end
  kernel.utils.setRunLevel(1)
end

function kernel.base.run()
  local ret = table.pack(kernel.base.initrd.boot())
  kernel.base.initrd = nil 
  local exists = kernel.ipc.exists
  local _assert = assert
  local _res = coroutine.resume
  local coroutines = kernel.ipc.coroutines
  local dest, src, action, packet, newDest, success 
  dest = ret[1]
  action = ret[2]
  pack = ret[3]
  src = "kernel"
  assert(dest and type(dest) == "string", "No first Coroutine, Halting!")
  while (dest ~= "kernel") do 
    _assert(exists(dest), "Bad destination: " .. dest)
    success, newDest, action, pack = _res(coroutines[dest], src, action, pack)
    assert(success, newDest)
    src = dest
    dest = newDest
  end
  --TODO: better shutdown
end
-- Kernel Main functions
-------------------------------------------------------------------------------

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
