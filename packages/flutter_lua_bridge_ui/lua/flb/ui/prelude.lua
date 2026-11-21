-- require("flb.ui.prelude") makes the widgets and value types of flb.ui
-- globals (LuaView does this before running a script) and returns flb.ui.
-- Teal code requires it to see the global declarations of prelude.d.tl.
local ui = require("flb.ui")
ui.install()
return ui
