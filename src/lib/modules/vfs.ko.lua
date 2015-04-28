--[[ POSIG/PORTABLE
  Title: gopoiOS virtual filesystem module
  Author: Shan B.
  Credit: OpenComputers openOS Filesystem
  Date: 2015-04-26
]]--


local vfs = {}
vfs.__index = vfs

-------------------------------------------------------------------------------
-- vfs local methods
local function segments(path)
  path = path:gsub("\\", "/")
  repeat local n; path, n = path:gsub("//", "/") until n == 0
  local parts = {}
  for part in path:gmatch("[^/]+") do
    table.insert(parts, part)
  end
  local i = 1
  while i <= #parts do
    if parts[i] == "." then
      table.remove(parts, i)
    elseif parts[i] == ".." then
      table.remove(parts, i)
      i = i - 1
      if i > 0 then
        table.remove(parts, i)
      else
        i = 1
      end
    else
      i = i + 1
    end
  end
  return parts
end

local function addMountpoint()


end

-------------------------------------------------------------------------------
-- vfs driver methods
function vfs:attachDriver()

end

function vfs:detachDriver()

end

-------------------------------------------------------------------------------
-- vfs mounting methods
function vfs:mount()

end

function vfs:umount()

end

function vfs:probe()

end



-------------------------------------------------------------------------------
-- IO/file namespaces lua override






function vfs:open()

end

-------------------------------------------------------------------------------
-- vfs initialisation methods
function vfs.init(rootMountpoint, rootMountpointDriver)
  local self = setmetatable({}, vfs)
  self.mountpoints = {}
  return self
end

return vfs