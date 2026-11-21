-- Must fail the Teal check: `colour` is not a Container argument.
-- expect: unknown field colour
require("flb.ui.prelude")
return Container { colour = 0xFF000000 }
