-- Version 3.0.0 is broken: its first render fails, so RemoteLuaView marks
-- it bad and falls back to the last good version.
return App {
  view = function()
    error("v3 的 view 有 bug")
  end,
}
