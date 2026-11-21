-- Must fail the Teal check: Colors has no member "purpel".
-- expect: purpel
require("flb.ui.material.prelude")
return Card { color = Colors.purpel }
