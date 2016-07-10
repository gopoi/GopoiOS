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
sched.__index = sched




















-------------------------------------------------------------------------------
-- sched initialisation methods
function sched.init()
  local self = setmetatable({
    }, sched)
  return self
end

-------------------------------------------------------------------------------
-- sched IPC methods
local actions = {

}

local function ipc(sched, kernel) 
  local src, pack, action
  while (true) do
    src, action, pack = kernel.ipc.send(src, act, pack)
    --arg = actions[action](sched, table.unpack(pack))
  end
end


-------------------------------------------------------------------------------
-- sched Module functions

function sched.insmod(kernel, posig)
  local co = coroutine.create(ipc)
  local handle = sched.init()
  local success, val = coroutine.resume(co, handle, kernel)
  assert(success, val)
  kernel.ipc.add(posig.name, co)
  return handle
end

return sched