-- bootstrap.lua
--
-- Lua 侧的入口设置。Flutter 宿主会把 assets/lua 目录加进 package.path，
-- 这里只需要处理相对路径和可选的 vendor 目录。

local function script_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    return src:sub(2):match("^(.*)[/\\][^/\\]*$") or "."
  end
  return "."
end

local root = script_dir()

package.path = table.concat({
  root .. "/?.lua",
  root .. "/?/init.lua",
  root .. "/vendor/?.lua",
  root .. "/vendor/?/init.lua",
  package.path,
}, ";")

return { root = root }