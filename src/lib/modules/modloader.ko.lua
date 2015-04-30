--[[ POSIG/0.0.1
  Name: modloader
  FullName: Module loader for gopoiOS
  Package: net.gopoi.gopoios
  Version: 0.0.1
  Author: Shan B.
  Date: 2015-04-25
  Arch: Portable
]]--

local loader = {

}



-------------------------------------------------------------------------------
-- vfs initialisation methods
function loader.init()
  local self = setmetatable({}, loader)
  return self
end

return loader