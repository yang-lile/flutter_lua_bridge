-- Must fail the Teal check: a segment needs `child`, not `label`.
-- expect: unknown field label
require("flb.ui.cupertino.prelude")
return CupertinoSegmentedControl { children = { { value = "a", label = Text { "A" } } } }
