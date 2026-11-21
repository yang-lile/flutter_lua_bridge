-- Teal declarations for require("flb.ui.material"). Require
-- "flb.ui.material.prelude" to declare its globals. Keep the widget list in step
-- with the Dart registry and the Lua module (test/catalog_test.dart).
local type UI = require("flb.ui")

local record material
  enum InputBorderTypeName
    "outline" "underline" "none"
  end
  record InputBorderValue
    type: InputBorderTypeName
    borderRadius: UI.BorderRadius
  end
  record InputDecorationValue
    labelText: string
    hintText: string
    helperText: string
    errorText: string
    prefixIcon: UI.Node
    suffixIcon: UI.Node
    filled: boolean
    fillColor: UI.Color
    border: InputBorderValue
  end
  enum TextInputTypeName
    "text" "multiline" "number" "phone" "datetime" "emailAddress" "url" "visiblePassword" "name"
  end
  record TextInputTypeType
    text: TextInputTypeName
    multiline: TextInputTypeName
    number: TextInputTypeName
    phone: TextInputTypeName
    datetime: TextInputTypeName
    emailAddress: TextInputTypeName
    url: TextInputTypeName
    visiblePassword: TextInputTypeName
    name: TextInputTypeName
  end
  record InputBorderType
    none: InputBorderValue
  end
  record OutlineInputBorderArgs
    borderRadius: UI.BorderRadius
  end
  record ColorsType
    transparent: integer
    black: integer
    black87: integer
    black54: integer
    black45: integer
    black38: integer
    black26: integer
    black12: integer
    white: integer
    white70: integer
    white60: integer
    white54: integer
    white38: integer
    white30: integer
    white24: integer
    white12: integer
    white10: integer
    red: UI.ColorSwatch
    redAccent: UI.ColorSwatch
    pink: UI.ColorSwatch
    pinkAccent: UI.ColorSwatch
    purple: UI.ColorSwatch
    purpleAccent: UI.ColorSwatch
    deepPurple: UI.ColorSwatch
    deepPurpleAccent: UI.ColorSwatch
    indigo: UI.ColorSwatch
    indigoAccent: UI.ColorSwatch
    blue: UI.ColorSwatch
    blueAccent: UI.ColorSwatch
    lightBlue: UI.ColorSwatch
    lightBlueAccent: UI.ColorSwatch
    cyan: UI.ColorSwatch
    cyanAccent: UI.ColorSwatch
    teal: UI.ColorSwatch
    tealAccent: UI.ColorSwatch
    green: UI.ColorSwatch
    greenAccent: UI.ColorSwatch
    lightGreen: UI.ColorSwatch
    lightGreenAccent: UI.ColorSwatch
    lime: UI.ColorSwatch
    limeAccent: UI.ColorSwatch
    yellow: UI.ColorSwatch
    yellowAccent: UI.ColorSwatch
    amber: UI.ColorSwatch
    amberAccent: UI.ColorSwatch
    orange: UI.ColorSwatch
    orangeAccent: UI.ColorSwatch
    deepOrange: UI.ColorSwatch
    deepOrangeAccent: UI.ColorSwatch
    brown: UI.ColorSwatch
    grey: UI.ColorSwatch
    blueGrey: UI.ColorSwatch
  end

  record AppBarArgs
    key: any
    title: UI.Node
    leading: UI.Node
    actions: {UI.Node}
    backgroundColor: UI.Color
    foregroundColor: UI.Color
    centerTitle: boolean
    elevation: number
  end
  record CardArgs
    key: any
    color: UI.Color
    elevation: number
    margin: UI.EdgeInsets
    child: UI.Node
  end
  record CheckboxArgs
    key: any
    value: boolean
    tristate: boolean
    onChanged: function(value: boolean)
  end
  record ChipArgs
    key: any
    label: UI.Node
    avatar: UI.Node
    backgroundColor: UI.Color
    onDeleted: function()
  end
  record CircularProgressIndicatorArgs
    key: any
    value: number
    color: UI.Color
    backgroundColor: UI.Color
    strokeWidth: number
  end
  record DividerArgs
    key: any
    height: number
    thickness: number
    indent: number
    endIndent: number
    color: UI.Color
  end
  record ElevatedButtonArgs
    key: any
    onPressed: function()
    onLongPress: function()
    child: UI.Node
  end
  record ElevatedButtoniconArgs
    key: any
    onPressed: function()
    onLongPress: function()
    icon: UI.Node
    label: UI.Node
  end
  record FilledButtonArgs
    key: any
    onPressed: function()
    onLongPress: function()
    child: UI.Node
  end
  record FilledButtoniconArgs
    key: any
    onPressed: function()
    onLongPress: function()
    icon: UI.Node
    label: UI.Node
  end
  record FilledButtontonalArgs
    key: any
    onPressed: function()
    onLongPress: function()
    child: UI.Node
  end
  record FloatingActionButtonArgs
    key: any
    onPressed: function()
    tooltip: string
    backgroundColor: UI.Color
    foregroundColor: UI.Color
    mini: boolean
    child: UI.Node
  end
  record FloatingActionButtonextendedArgs
    key: any
    onPressed: function()
    tooltip: string
    backgroundColor: UI.Color
    foregroundColor: UI.Color
    icon: UI.Node
    label: UI.Node
  end
  record IconButtonArgs
    key: any
    icon: UI.Node
    onPressed: function()
    tooltip: string
    color: UI.Color
    iconSize: number
  end
  record IconButtonfilledArgs
    key: any
    icon: UI.Node
    onPressed: function()
    tooltip: string
    color: UI.Color
    iconSize: number
  end
  record InkWellArgs
    key: any
    onTap: function()
    onLongPress: function()
    borderRadius: UI.BorderRadius
    child: UI.Node
  end
  record LinearProgressIndicatorArgs
    key: any
    value: number
    color: UI.Color
    backgroundColor: UI.Color
    minHeight: number
  end
  record ListTileArgs
    key: any
    leading: UI.Node
    title: UI.Node
    subtitle: UI.Node
    trailing: UI.Node
    onTap: function()
    onLongPress: function()
    dense: boolean
    selected: boolean
    enabled: boolean
  end
  record MaterialArgs
    key: any
    color: UI.Color
    elevation: number
    borderRadius: UI.BorderRadius
    child: UI.Node
  end
  record OutlinedButtonArgs
    key: any
    onPressed: function()
    onLongPress: function()
    child: UI.Node
  end
  record OutlinedButtoniconArgs
    key: any
    onPressed: function()
    onLongPress: function()
    icon: UI.Node
    label: UI.Node
  end
  record ScaffoldArgs
    key: any
    appBar: UI.Node
    body: UI.Node
    floatingActionButton: UI.Node
    bottomNavigationBar: UI.Node
    backgroundColor: UI.Color
  end
  record SliderArgs
    key: any
    value: number
    min: number
    max: number
    divisions: integer
    label: string
    onChanged: function(value: number)
    onChangeEnd: function(value: number)
  end
  record SwitchArgs
    key: any
    value: boolean
    onChanged: function(value: boolean)
  end
  record TextButtonArgs
    key: any
    onPressed: function()
    onLongPress: function()
    child: UI.Node
  end
  record TextButtoniconArgs
    key: any
    onPressed: function()
    onLongPress: function()
    icon: UI.Node
    label: UI.Node
  end
  record TextFieldArgs
    key: any
    text: string
    decoration: InputDecorationValue
    obscureText: boolean
    maxLines: integer
    enabled: boolean
    autofocus: boolean
    keyboardType: TextInputTypeName
    onChanged: function(value: string)
    onSubmitted: function(value: string)
  end

  record ElevatedButtonConstructor
    metamethod __call: function(self, args: ElevatedButtonArgs): UI.Node
    icon: function(args: ElevatedButtoniconArgs): UI.Node
  end
  record FilledButtonConstructor
    metamethod __call: function(self, args: FilledButtonArgs): UI.Node
    icon: function(args: FilledButtoniconArgs): UI.Node
    tonal: function(args: FilledButtontonalArgs): UI.Node
  end
  record FloatingActionButtonConstructor
    metamethod __call: function(self, args: FloatingActionButtonArgs): UI.Node
    extended: function(args: FloatingActionButtonextendedArgs): UI.Node
  end
  record IconButtonConstructor
    metamethod __call: function(self, args: IconButtonArgs): UI.Node
    filled: function(args: IconButtonfilledArgs): UI.Node
  end
  record OutlinedButtonConstructor
    metamethod __call: function(self, args: OutlinedButtonArgs): UI.Node
    icon: function(args: OutlinedButtoniconArgs): UI.Node
  end
  record TextButtonConstructor
    metamethod __call: function(self, args: TextButtonArgs): UI.Node
    icon: function(args: TextButtoniconArgs): UI.Node
  end

  -- The widgets.
  AppBar: function(args: AppBarArgs): UI.Node
  Card: function(args: CardArgs): UI.Node
  Checkbox: function(args: CheckboxArgs): UI.Node
  Chip: function(args: ChipArgs): UI.Node
  CircularProgressIndicator: function(args: CircularProgressIndicatorArgs): UI.Node
  Divider: function(args: DividerArgs): UI.Node
  ElevatedButton: ElevatedButtonConstructor
  FilledButton: FilledButtonConstructor
  FloatingActionButton: FloatingActionButtonConstructor
  IconButton: IconButtonConstructor
  InkWell: function(args: InkWellArgs): UI.Node
  LinearProgressIndicator: function(args: LinearProgressIndicatorArgs): UI.Node
  ListTile: function(args: ListTileArgs): UI.Node
  Material: function(args: MaterialArgs): UI.Node
  OutlinedButton: OutlinedButtonConstructor
  Scaffold: function(args: ScaffoldArgs): UI.Node
  Slider: function(args: SliderArgs): UI.Node
  Switch: function(args: SwitchArgs): UI.Node
  TextButton: TextButtonConstructor
  TextField: function(args: TextFieldArgs): UI.Node

  -- The values it installs as globals.
  Colors: ColorsType
  InputDecoration: function(args: InputDecorationValue): InputDecorationValue
  OutlineInputBorder: function(args?: OutlineInputBorderArgs): InputBorderValue
  UnderlineInputBorder: function(): InputBorderValue
  InputBorder: InputBorderType
  TextInputType: TextInputTypeType
end

return material
