--[[ POSIG/0.0.1
  Name: vfs
  FullName: gopoiOS virtual filesystem module
  Package: net.gopoi.gopoios
  Author: Shan B.
  Credit: OpenComputers openOS Filesystem
  Date: 2015-04-26
  Arch: portable
]]--


local vfs = {}
vfs.__index = vfs

-------------------------------------------------------------------------------
-- vfs helper methods

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

-------------------------------------------------------------------------------
-- vfs local methods

local function retrievePath(node)
  local oldNode = nil
  local path = ""
  while node ~= oldNode and node.name ~= "" do
    path = "/" .. node.name .. path
    oldNode = node
    node = node.parent
  end
  if path == "" then 
    path = "/"
  end
  return path
end

local function getNode(self, path)
  local node = self.rootNode
  local parts = vfs.segments(path)
  local restPath = ""
  local hnode = node
  local hrestPath = ""
  local continue = true
  if #parts > 0 then
    for _, v in pairs(parts) do
      if node.child[v] and continue then
        node = node.child[v]
        if node.handle then
          hrestPath = ""
          hnode = node
        else
          hrestPath = hrestPath .. "/" .. v
        end
      else
        continue = false
        restPath = restPath .. "/" .. v
        hrestPath = hrestPath .. "/" .. v
      end
    end 
  end
  return node, restPath, hnode, hrestPath
end

local function createNode(self, path)
  local node, restPath = getNode(self, path)
  local parts = vfs.segments(restPath)
  if #parts > 0 then
    for _, v in pairs(parts) do
      node.child[v] = {
        child = {},
        parent = node,
        handle = nil,
        name = v,
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
  for _, v in pairs(node.child) do
    listNodes(v, ret)
  end
  return ret
end


-------------------------------------------------------------------------------
-- vfs mounting methods

function vfs:mount(mountpoint, mountpointType, device)
  assert(type(mountpoint) == "string", "Bad argument #1: string expected")
  assert(type(mountpointType) == "string", "Bad argument #2: string expected")
  assert(self.drivers[mountpointType], "Type not found: " .. mountpointType)
  local mountpointDriver = self.drivers[mountpointType].init(device)
  
  local node, pathRest = getNode(self, mountpoint)
  if pathRest == "" then
    assert(not node.handle, "Mountpoint exists!")
    node.handle = mountpointDriver
  else
    assert(node.handle, "Error while trying to find mountpoint!")
    assert(node.handle:exists(pathRest), "Path doesn't exists!")
    node = createNode(self, mountpoint)
    node.handle = mountpointDriver
  end
end

function vfs:umount(mountpoint)
  
end

function vfs:mounts()
  nodes = listNodes(self.rootNode)
  local mounts = {}
  for _, v in pairs(nodes) do
    if v.handle then
      local name = v.handle:getLabel()
      mounts[name] = {
        handle = v.handle,
        name = name,
        path = retrievePath(v),
        device = v.handle.device,
      }
    end
  end
  return mounts
end

function vfs:attach(driver)
  self.drivers[driver.partitionType] = driver
end

function vfs:listMountable()
  local out = {}
  for _, v in pairs(self.drivers) do
    local drives = v.listConnectedDevices()
    out[v.getPartitionType()] = drives
  end
  return out
end

function vfs:findDrive(driveType, label)
  assert(self.drivers[driveType], "Partition type not found")
  return self.drivers[driveType].findDrive(label)
end


-------------------------------------------------------------------------------
-- IO/file namespaces lua override

function vfs:open(path, options)
  assert(type(path) == "string", "Bad argument #1: string expected")
  assert(type(options) == "string", "Bad argument #2: string expected")
  local _, _, node, pathRest = getNode(self, path)
  --assert(false, node.name)
  assert(node.handle:exists(pathRest), "Error, file not found!")
  return node.handle:open(pathRest, options)
end


-------------------------------------------------------------------------------
-- vfs initialisation methods

function vfs.init(rootMountpoint, rootDriver, rootDevice)
  local self = setmetatable({
    drivers = {},
    rootNode = {
      child = {},
      handle = nil,
      name = "",
      },
    }, vfs)
  self:attach(rootDriver)
  self.rootNode.parent = self.rootNode
  self:mount("/", rootDriver.partitionType, rootDevice)
  return self
end

function vfs.insmod(kernel)
end

return vfs