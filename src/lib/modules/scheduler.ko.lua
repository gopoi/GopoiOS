--[[ POSIG/0.0.1
  Name: scheduler
  FullName: gopoiOS kernel
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: portable
]]--

local sched = {}
local process = {}
sched.__index = sched
process.__index = process

function process:sched(...)
  
  local t = self.threads[self.current]
  
  
end

function process:createThread(fc)
  local t = coroutine.create(fc)
  table.insert(self.threads, t)
end

function sched:createProcess(filePath)
  local _, _, pack = self.ipc.send("vfs", "readFile", table.pack(filePath))
  local file = table.unpack(pack)
  local img, posig = self.utils.load(file)
  local pro = setmetatable({
      threads = {},
      current = 1,
      }, process)
  pro.img = img
  pro.posig = posig
  assert(type(img.main) == "function", "No entry point, main not found.")
  pro:createThread(img.main)
  assert(type(pro.threads.main) == "thread", "Error while creating process.")
  table.insert(self.processList, pro)
end
  
function sched:schedule()
  
  
end

function sched:start()
  assert(self.processList, "No process!")
  assert(#self.processList > 0, "No process!")
  return sched:schedule()
end

-------------------------------------------------------------------------------
-- sched initialisation methods
function sched.init(kernel)

  --local iso = require("isolation")
  local self = setmetatable({
      ipc = kernel.ipc,
      base = kernel.base,
      processList = {},
      current = 1,
      iso = iso,
    }, sched)
  return self
end

-------------------------------------------------------------------------------
-- sched IPC methods
local actions = {
  createProcess = sched.createProcess,
  start = sched.start
}

local function ipc(sched, kernel) 
  local src, pack, action, dest
  while (true) do
    src, action, pack = kernel.ipc.send(dest, action, pack)
    dest, action, pack = actions[action](sched, table.unpack(pack))
    dest = dest or src
  end
end

-------------------------------------------------------------------------------
-- sched Module functions
function sched.insmod(posig)
  local kernel = require("kernel")
  local co = coroutine.create(ipc)
  local handle = sched.init(kernel)
  local success, val = coroutine.resume(co, handle, kernel)
  assert(success, val)
  kernel.ipc.add(posig.name, co)
  return handle
end

return sched