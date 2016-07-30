--[[ POSIG/0.0.1
  Name: vfs
  FullName: gopoiOS virtual filesystem module
  Package: net.gopoi.gopoios
  Author: Shan B.
  Credit: OpenComputers openOS Filesystem
  Date: 2015-04-26
  Arch: portable
]]--

local vfs = {
  drivers = {},
  rootNode = {
    child = {},
    handle = nil,
    name = "",
  },
  bare = {
    loadfile = loadfile,
    dofile = dofile,
    require = require,
  },
}
vfs.rootNode.parent = vfs.rootNode
-------------------------------------------------------------------------------
-- vfs overload methods
loadfile = function(name, env)
  local _, _, pack = vfs.readFile(name .. ".lua")
  return load(pack[1], env)
end

local function search(pathList, name, ext)
  for _, v in ipairs(pathList) do
    if vfs.fileExists(v .. name .. ext) == true then
      return v .. name .. ext
    end
  end
end

dofile = function(name, env)
  return loadfile(name, env)()
end

require = function(name)
  local kernel = vfs.bare.require("kernel")
  if kernel.modules.isLoaded(name) then
    return kernel.modules.get(name)
  else
    local path = search(kernel.utils.getSetting("modulesPath"),
                                                name, ".ko.lua")   
    if path then
      local file = vfs.readFile(path)
      return kernel.modules.insmod(file).handle
    else
      return nil
    end
  end
end
-- vfs overload methods
-------------------------------------------------------------------------------

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

--[[function vfs.canonical(path)
  local result = table.concat(vfs.segments(path), "/")
  return result
end]]

function vfs.formatPath(file)
  local segs = vfs.segments(file)
  local fileName = segs[#segs]
  table.remove(segs)
  local path = table.concat(segs, "/")
  return path, fileName
end
-- vfs helper methods
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- vfs local methods
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

local function listHNodes(node, ret)
  if ret == nil then
    ret = {}
  end
  if node.handle then
    table.insert(ret, node)
  end
  for _, v in pairs(node.child) do
    listNodes(v, ret)
  end
  return ret
end
-- vfs local methods
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- vfs mounting methods
function vfs.mount(mountpoint, mounttype, dev)
  assert(type(mountpoint) == "string", "Bad argument #1: string expected")
  assert(type(mounttype) == "string", "Bad argument #2: string expected")
  assert(type(dev) == "table", "Bad argument #3: table expected")
  assert(vfs.drivers[mounttype], "Type not found: " .. mounttype)
  local mountpointDriver = vfs.drivers[mounttype].new(dev)
  local node, pathRest = getNode(vfs, mountpoint)
  if pathRest == "" then
    assert(not node.handle, "Mountpoint exists!")
    node.handle = mountpointDriver
  else
    assert(node.handle, "Error while trying to find mountpoint!")
    --assert(node.handle:exists(pathRest), "Path doesn't exists!") --TODO: uncomment when mkdir works
    node = createNode(vfs, mountpoint)
    node.handle = mountpointDriver
  end
end

function vfs.attach(mounttype, driver)
  assert(not vfs.drivers[mounttype], "Driver already exists!")
  vfs.drivers[mounttype] = driver
end
-- vfs mounting methods
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- vfs file methods
function vfs.fileExists(path)
  assert(type(path) == "string", "Bad argument #1: string expected")
  local _, _, node, pathRest = getNode(vfs, path)
  if node.handle then
    return node.handle:exists(pathRest) and not node.handle:isDirectory(pathRest)
  end
  return false
end

function vfs.pathExists(path)
  assert(type(path) == "string", "Bad argument #1: string expected")
  local pathonly = vfs.formatPath(path)
  local _, _, node, pathRest = getNode(vfs, pathonly)
  if node.handle then
    return node.handle:exists(pathRest) and node.handle:isDirectory(pathRest)
  end
  return false
end

function vfs.openFile(path, options)
  assert(type(path) == "string", "Bad argument #1: string expected")
  assert(type(options) == "string", "Bad argument #2: string expected")
  local _, _, node, pathRest = getNode(vfs, path)
  assert(vfs.pathExists(path), "Error, path not found! " .. pathRest)
  return node.handle:openFile(pathRest, options)
end

function vfs.readFile(filePath)
  local handle, reason = vfs.openFile(filePath, "r")
  assert(handle, reason)
  local buffer = ""
  repeat
    local data, reason = handle:read(math.huge)
    buffer = buffer .. (data or "")
  until not data
  handle:close()
  return buffer
end



-- vfs file methods
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- vfs module methods
function vfs.insmod(posig)
  return vfs
end

return vfs