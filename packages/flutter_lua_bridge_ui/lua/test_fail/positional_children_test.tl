-- Must fail the Teal check: Column takes no positional arguments.
-- expect: expected UI.ColumnArgs
require("flb.ui.prelude")
return Column { Text { "a" } }
