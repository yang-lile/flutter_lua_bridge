-- Globals that ui.install() defines (LuaView installs them before running a
-- script). Teal code requires "flb.ui.prelude" to see these declarations.
local type UI = require("flb.ui")

global ui: UI
global App: function<S>(spec: UI.AppSpec<S>): UI.App
global Align: function(args: UI.AlignArgs): UI.Node
global AspectRatio: function(args: UI.AspectRatioArgs): UI.Node
global Center: function(args: UI.CenterArgs): UI.Node
global ClipRRect: function(args: UI.ClipRRectArgs): UI.Node
global ColoredBox: function(args: UI.ColoredBoxArgs): UI.Node
global Column: function(args: UI.ColumnArgs): UI.Node
global Container: function(args: UI.ContainerArgs): UI.Node
global DecoratedBox: function(args: UI.DecoratedBoxArgs): UI.Node
global DefaultTextStyle: function(args: UI.DefaultTextStyleArgs): UI.Node
global Expanded: function(args: UI.ExpandedArgs): UI.Node
global Flexible: function(args: UI.FlexibleArgs): UI.Node
global GestureDetector: function(args: UI.GestureDetectorArgs): UI.Node
global Icon: function(args: UI.IconArgs): UI.Node
global Image: UI.ImageConstructor
global ListView: UI.ListViewConstructor
global Opacity: function(args: UI.OpacityArgs): UI.Node
global Padding: function(args: UI.PaddingArgs): UI.Node
global Positioned: function(args: UI.PositionedArgs): UI.Node
global Row: function(args: UI.RowArgs): UI.Node
global SafeArea: function(args: UI.SafeAreaArgs): UI.Node
global SingleChildScrollView: function(args: UI.SingleChildScrollViewArgs): UI.Node
global SizedBox: UI.SizedBoxConstructor
global Spacer: function(args: UI.SpacerArgs): UI.Node
global Stack: function(args: UI.StackArgs): UI.Node
global Text: function(args: UI.TextArgs): UI.Node
global Wrap: function(args: UI.WrapArgs): UI.Node

global Navigator: UI.NavigatorType

global Color: UI.ColorType
global EdgeInsets: UI.EdgeInsetsType
global Radius: UI.RadiusType
global BorderRadius: UI.BorderRadiusType
global Offset: UI.OffsetType
global Alignment: UI.AlignmentType
global Border: UI.BorderType
global BoxShadow: function(args: UI.BoxShadow): UI.BoxShadow
global BoxDecoration: function(args: UI.BoxDecoration): UI.BoxDecoration
global TextStyle: function(args: UI.TextStyle): UI.TextStyle
global LinearGradient: function(args: UI.LinearGradient): UI.LinearGradient
global Duration: function(args: UI.DurationParts): number
global NetworkImage: function(url: string): UI.ImageProvider
global AssetImage: function(name: string): UI.ImageProvider
-- Icon names; the host registers the icon data for each name.
global Icons: {string: string}
global Axis: UI.AxisType
global BoxFit: UI.BoxFitType
global BoxShape: UI.BoxShapeType
global CrossAxisAlignment: UI.CrossAxisAlignmentType
global FlexFit: UI.FlexFitType
global FontStyle: UI.FontStyleType
global FontWeight: UI.FontWeightType
global HitTestBehavior: UI.HitTestBehaviorType
global MainAxisAlignment: UI.MainAxisAlignmentType
global MainAxisSize: UI.MainAxisSizeType
global StackFit: UI.StackFitType
global TextAlign: UI.TextAlignType
global TextDecoration: UI.TextDecorationType
global TextOverflow: UI.TextOverflowType
global WrapAlignment: UI.WrapAlignmentType
global WrapCrossAlignment: UI.WrapCrossAlignmentType

return ui
