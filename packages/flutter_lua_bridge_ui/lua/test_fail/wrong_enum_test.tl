-- Must fail the Teal check: "centre" is not a MainAxisAlignment.
-- expect: "centre" is not a member of MainAxisAlignmentName
require("flb.ui.prelude")
return Row { mainAxisAlignment = "centre", children = {} }
