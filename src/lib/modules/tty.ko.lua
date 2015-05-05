--[[ POSIG/0.0.1
  Name: tty
  FullName: gopoiOS tty driver
  Package: net.gopoi.gopoios
  Author: Shan B.
  Date: 2015-04-26
  Arch: Portable
]]--

local tty = {}
tty.__index = tty







-- vfs initialisation methods
function tty.init(device)
  local self = setmetatable({
    }, tty)

  return self
end


return tty