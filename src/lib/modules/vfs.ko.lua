--[[ POSIG/0.0.1
  Name: vfs
  FullName: gopoiOS virtual filesystem module
  Package: net.gopoi.gopoios
  Author: Shan B.
  Credit: OpenComputers openOS Filesystem
  Date: 2015-04-26
  Arch: Portable
]]--


local vfs = {}
vfs.__index = vfs


-------------------------------------------------------------------------------
-- vfs local methods
function vfs.segments(path)
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

function vfs.canonical(path)
  local result = table.concat(vfs.segments(path), "/")
  if locale.sub(path, 1, 1) == "/" then
    return "/" .. result
  else
    return result
  end
end

local function getNode(self, path)
  local node = self.rootNode
  local parts = vfs.segments(path)
  local restPath = ""
  local index = 0
  if #parts > 0 then
    for _, v in pairs(parts) do
      if node.child[v] then
        node = node.child[v]
      else
        restPath = restPath .. "/" .. v
      end
    end 
  end
  return node, restPath
end

local function getHandleNode(self, path)
  local node = self.rootNode
  local parts = vfs.segments(path)
  local restPath = ""
  local index = 0
  if #parts > 0 then
    for _, v in pairs(parts) do
      if node.child[v] and node.child[v].handle then
        node = node.child[v]
        restPath = ""
      else
        restPath = restPath .. "/" .. v
      end
    end 
  end
  return node, restPath
end

local function createNode(self, path)
  local node, restPath = getNearestNode(self, path)
  local parts = vfs.segments(restPath)
  if #parts > 0 then
    for _, v in pairs(parts) do
      node.child[v] = {
        child = {},
        parent = node,
        handle = nil,
        }
      node = node.child[v]
    end
  end
  return node
end

local function listNodes(node, ret)
  if ret == nil then
    ret = {}
  end
  table.insert(ret, node)
  --for _, v in pairs(node.child) do
  --  listNodes(v, ret)
  --end
  return ret
end
-------------------------------------------------------------------------------
-- vfs mounting methods
function vfs:mount(mountpoint, mountpointDriver)
  assert(type(mountpoint) == "string", "Bad argument #1: string expected")
  assert(type(mountpointDriver) == "table", "Bad argument #2: table expected")
  local node, pathRest = getNode(self, mountpoint)
  
  if pathRest == "" then
    assert(not node.handle, "Mountpoint exists!")
    node.handle = mountpointDriver
  else
    assert(node.handle, "Error while trying to find mountpoint!")
    assert(node.handle:exists(restPath), "Path doesn't exists!")
    node = createNode(self, mountpoint)
    node.handle = mountpointDriver
  end
end

function vfs:umount(mountpoint)
  
end

function vfs:mounts()
  nodes = listNodes(self.rootNode)
  local handles = {}
  for _, v in pairs(nodes) do
    if v.handle then
      handles[v.handle:getLabel()] = v.handle
    end
  end
  return handles
end

-------------------------------------------------------------------------------
-- IO/file namespaces lua override


function vfs:open(path, options)
  assert(type(path) == "string", "Bad argument #1: string expected")
  assert(type(options) == "string", "Bad argument #2: string expected")
  local node, pathRest = getHandleNode(self, path)
  assert(node.handle:exists(pathRest), "Error, file not found!")
  return node.handle:open(pathRest, options)
end

-------------------------------------------------------------------------------
-- vfs initialisation methods
function vfs.init(rootMountpoint, rootMountpointDriver)
  local self = setmetatable({
    mountpoints = {},
    rootNode = {
      child = {},
      handle = nil,
      },
    }, vfs)
  self.rootNode.parent = self.rootNode
  self:mount(rootMountpoint, rootMountpointDriver)
  return self
end

return vfs