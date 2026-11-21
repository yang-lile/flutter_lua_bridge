-- require("flb.ui.cupertino.prelude") makes the core and Cupertino widgets
-- globals (LuaView does this before running a script) and returns flb.ui.
-- Teal code requires it to see the declarations of prelude.d.tl.
local ui = require("flb.ui.prelude")
ui.install((require("flb.ui.cupertino")))
return ui
