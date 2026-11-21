-- Teal declarations for require("flb.ui.cupertino"). Require
-- "flb.ui.cupertino.prelude" to declare its globals. Keep the widget list in step
-- with the Dart registry and the Lua module (test/catalog_test.dart).
local type UI = require("flb.ui")

local record cupertino
  -- One segment: Lua tables have no order, so segments are a list.
  record Segment
    value: string | number
    child: UI.Node
  end
  record CupertinoColorsType
    activeBlue: integer
    activeGreen: integer
    activeOrange: integer
    white: integer
    black: integer
    transparent: integer
    lightBackgroundGray: integer
    extraLightBackgroundGray: integer
    darkBackgroundGray: integer
    inactiveGray: integer
    destructiveRed: integer
    systemBlue: integer
    systemGreen: integer
    systemMint: integer
    systemIndigo: integer
    systemOrange: integer
    systemPink: integer
    systemBrown: integer
    systemPurple: integer
    systemRed: integer
    systemTeal: integer
    systemCyan: integer
    systemYellow: integer
    systemGrey: integer
    systemGrey2: integer
    systemGrey3: integer
    systemGrey4: integer
    systemGrey5: integer
    systemGrey6: integer
    label: integer
    secondaryLabel: integer
    tertiaryLabel: integer
    quaternaryLabel: integer
    systemFill: integer
    secondarySystemFill: integer
    tertiarySystemFill: integer
    quaternarySystemFill: integer
    placeholderText: integer
    systemBackground: integer
    secondarySystemBackground: integer
    tertiarySystemBackground: integer
    systemGroupedBackground: integer
    secondarySystemGroupedBackground: integer
    tertiarySystemGroupedBackground: integer
    separator: integer
    opaqueSeparator: integer
    link: integer
  end

  record CupertinoActivityIndicatorArgs
    key: any
    radius: number
    animating: boolean
    color: UI.Color
  end
  record CupertinoButtonArgs
    key: any
    onPressed: function()
    onLongPress: function()
    color: UI.Color
    foregroundColor: UI.Color
    padding: UI.EdgeInsets
    borderRadius: UI.BorderRadius
    child: UI.Node
  end
  record CupertinoButtonfilledArgs
    key: any
    onPressed: function()
    onLongPress: function()
    padding: UI.EdgeInsets
    borderRadius: UI.BorderRadius
    child: UI.Node
  end
  record CupertinoListSectionArgs
    key: any
    header: UI.Node
    footer: UI.Node
    children: {UI.Node}
  end
  record CupertinoListSectioninsetGroupedArgs
    key: any
    header: UI.Node
    footer: UI.Node
    children: {UI.Node}
  end
  record CupertinoListTileArgs
    key: any
    title: UI.Node
    subtitle: UI.Node
    additionalInfo: UI.Node
    leading: UI.Node
    trailing: UI.Node
    backgroundColor: UI.Color
    onTap: function()
  end
  record CupertinoNavigationBarArgs
    key: any
    middle: UI.Node
    leading: UI.Node
    trailing: UI.Node
    backgroundColor: UI.Color
    previousPageTitle: string
  end
  record CupertinoPageScaffoldArgs
    key: any
    navigationBar: UI.Node
    backgroundColor: UI.Color
    child: UI.Node
  end
  record CupertinoSegmentedControlArgs
    key: any
    children: {Segment}
    groupValue: string | number
    onValueChanged: function(value: any)
  end
  record CupertinoSliderArgs
    key: any
    value: number
    min: number
    max: number
    divisions: integer
    activeColor: UI.Color
    onChanged: function(value: number)
    onChangeEnd: function(value: number)
  end
  record CupertinoSwitchArgs
    key: any
    value: boolean
    activeTrackColor: UI.Color
    thumbColor: UI.Color
    onChanged: function(value: boolean)
  end
  record CupertinoTextFieldArgs
    key: any
    text: string
    placeholder: string
    prefix: UI.Node
    suffix: UI.Node
    padding: UI.EdgeInsets
    obscureText: boolean
    maxLines: integer
    enabled: boolean
    autofocus: boolean
    onChanged: function(value: string)
    onSubmitted: function(value: string)
  end

  record CupertinoButtonConstructor
    metamethod __call: function(self, args: CupertinoButtonArgs): UI.Node
    filled: function(args: CupertinoButtonfilledArgs): UI.Node
  end
  record CupertinoListSectionConstructor
    metamethod __call: function(self, args: CupertinoListSectionArgs): UI.Node
    insetGrouped: function(args: CupertinoListSectioninsetGroupedArgs): UI.Node
  end

  -- The widgets.
  CupertinoActivityIndicator: function(args: CupertinoActivityIndicatorArgs): UI.Node
  CupertinoButton: CupertinoButtonConstructor
  CupertinoListSection: CupertinoListSectionConstructor
  CupertinoListTile: function(args: CupertinoListTileArgs): UI.Node
  CupertinoNavigationBar: function(args: CupertinoNavigationBarArgs): UI.Node
  CupertinoPageScaffold: function(args: CupertinoPageScaffoldArgs): UI.Node
  CupertinoSegmentedControl: function(args: CupertinoSegmentedControlArgs): UI.Node
  CupertinoSlider: function(args: CupertinoSliderArgs): UI.Node
  CupertinoSwitch: function(args: CupertinoSwitchArgs): UI.Node
  CupertinoTextField: function(args: CupertinoTextFieldArgs): UI.Node

  -- The values it installs as globals.
  CupertinoColors: CupertinoColorsType
end

return cupertino
