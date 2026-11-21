-- Must fail the Teal check: Switch.onChanged receives a boolean.
-- expect: onChanged
require("flb.ui.material.prelude")
return Switch { value = true, onChanged = function(value: string) print(value) end }
