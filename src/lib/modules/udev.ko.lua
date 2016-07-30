--[[ POSIG/0.0.1
  Name: udev
  FullName: gopoiOS Kernel helpers
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: portable
]]--

local udev = {
  devProbersC = {},
  rootNode = {
    childs = {},
  },
}

local function getNode(path)
  local vfs = require("vfs")
  local node = udev.rootNode
  local parts = vfs.segments(path)
  local continue = true
  if #parts > 0 then
    for _, v in pairs(parts) do
      if node.childs[v] and continue then
        node = node.childs[v]
      else
        continue = false
      end
    end
  end
  return continue, node
end

-------------------------------------------------------------------------------
-- udev Device file actions : This part drive file itself (/dev/fs/fs1)
function udev:ioctl(action, path)
  if action == "open" then
    local success, node = getNode(path)
    if success then
      if node and node.dev then
        return node.dev
      end
    end
  elseif action == "list" then
    local success, node = getNode(path)
    if success and node and node.type == "dir" then
      local items = {}

      for _, v in pairs(node.childs) do
        table.insert(items, v.name)
      end
      return items
    end
  elseif action == "size" then
    return 0
  elseif action == "spaceUsed" then
    return 0
  elseif action == "spaceTotal" then
    return 0
  elseif action == "getLabel" then
    return "udev"
  elseif action == "isReadOnly" then
    return false
  elseif action == "exists" then
    local success, node = getNode(path)
    return success == true
  elseif action == "isDirectory" then
    local success, node = getNode(path)
    return success == true and node.type == "dir"
  end
end
-- ocfs Device file actions
-------------------------------------------------------------------------------
function udev.createNode(class, name, dev)
  if not udev.rootNode.childs[class] then
    udev.rootNode.childs[class] = {
      childs = {},
      name = class,
      type = "dir"
    }
  end
  local tempName = name
  local i = 1
  while udev.rootNode.childs[class].childs[tempName] do
    tempName = name .. tostring(i)
    i = i + 1
  end
  local newnode = {
    name = tempName,
    dev = dev,
    type = "file"
  } 
  udev.rootNode.childs[class].childs[tempName] = newnode
end

function udev.refresh()
  udev.rootNode = {
    childs = {},
  }
  for class, devProbers in pairs(udev.devProbersC) do
    for _, devProber in ipairs(devProbers) do
      local devices = devProber.probe()
      for name, device in pairs(devices) do
        udev.createNode(class, name, device)
      end
    end
  end
  
end

function udev.attach(class, devProber)
  assert(type(devProber.probe) == "function", "Driver cannot be probed!")
  if not udev.devProbersC[class] then
    udev.devProbersC[class] = {}
  end
    table.insert(udev.devProbersC[class], devProber)
end

function udev.insmod()
  local vfs = require("vfs")
  local fakefs = require("fakefs")
  return udev
end
return udev

