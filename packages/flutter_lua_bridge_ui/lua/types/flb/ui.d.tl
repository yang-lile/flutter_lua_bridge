-- Teal declarations for require("flb.ui"), the Lua module of
-- flutter_lua_bridge_ui. Require "flb.ui.prelude" to declare its globals.
-- Keep the widget list in step with coreLibrary() and CORE in flb/ui.lua
-- (test/catalog_test.dart checks the names).
local record ui
  -- A widget node, a component output or a component reference.
  type Node = {string: any}
  type Props = {string: any}
  type Render = function(props: Props): Node
  type Component = function(props?: Props): Node
  -- function(context, index) with a zero-based index; context is nil.
  type IndexedBuilder = function(context: any, index: integer): Node

  ------------------------------------------------------------ values
  -- A swatch (Colors.red of flb.ui.material) is its primary color with
  -- shades: Colors.red.shade100 or Colors.red[100].
  record ColorSwatch is {integer}
    value: integer
    shade50: integer
    shade100: integer
    shade200: integer
    shade300: integer
    shade400: integer
    shade500: integer
    shade600: integer
    shade700: integer
    shade800: integer
    shade900: integer
  end
  -- 0xAARRGGBB, "#RGB", "#RRGGBB", "#AARRGGBB" or a swatch.
  type Color = integer | string | ColorSwatch
  record EdgeInsetsValue
    all: number
    horizontal: number
    vertical: number
    left: number
    top: number
    right: number
    bottom: number
  end
  type EdgeInsets = number | EdgeInsetsValue
  record BorderRadiusValue
    topLeft: number
    topRight: number
    bottomLeft: number
    bottomRight: number
  end
  type BorderRadius = number | BorderRadiusValue
  enum AlignmentName
    "topLeft" "topCenter" "topRight" "centerLeft" "center" "centerRight" "bottomLeft" "bottomCenter" "bottomRight"
  end
  record AlignmentXY
    x: number
    y: number
  end
  type Alignment = AlignmentName | AlignmentXY
  record Offset
    dx: number
    dy: number
  end
  enum AxisName
    "horizontal" "vertical"
  end
  enum BoxFitName
    "fill" "contain" "cover" "fitWidth" "fitHeight" "none" "scaleDown"
  end
  enum BoxShapeName
    "rectangle" "circle"
  end
  enum CrossAxisAlignmentName
    "start" "end" "center" "stretch" "baseline"
  end
  enum FlexFitName
    "tight" "loose"
  end
  enum FontStyleName
    "normal" "italic"
  end
  enum FontWeightName
    "normal" "bold" "w100" "w200" "w300" "w400" "w500" "w600" "w700" "w800" "w900"
  end
  enum HitTestBehaviorName
    "deferToChild" "opaque" "translucent"
  end
  enum MainAxisAlignmentName
    "start" "end" "center" "spaceBetween" "spaceAround" "spaceEvenly"
  end
  enum MainAxisSizeName
    "min" "max"
  end
  enum StackFitName
    "loose" "expand" "passthrough"
  end
  enum TextAlignName
    "left" "right" "center" "justify" "start" "end"
  end
  enum TextDecorationName
    "none" "underline" "overline" "lineThrough"
  end
  enum TextOverflowName
    "clip" "fade" "ellipsis" "visible"
  end
  enum WrapAlignmentName
    "start" "end" "center" "spaceBetween" "spaceAround" "spaceEvenly"
  end
  enum WrapCrossAlignmentName
    "start" "end" "center"
  end
  record BorderSide
    color: Color
    width: number
  end
  record BoxShadow
    color: Color
    blurRadius: number
    spreadRadius: number
    offset: Offset
  end
  record LinearGradient
    colors: {Color}
    stops: {number}
    begin: Alignment
    ["end"]: Alignment
  end
  record BoxDecoration
    color: Color
    borderRadius: BorderRadius
    border: BorderSide
    gradient: LinearGradient
    boxShadow: {BoxShadow}
    shape: BoxShapeName
  end
  record TextStyle
    color: Color
    backgroundColor: Color
    fontSize: number
    fontWeight: FontWeightName
    fontStyle: FontStyleName
    fontFamily: string
    letterSpacing: number
    height: number
    decoration: TextDecorationName
  end
  record ImageProvider
    network: string
    asset: string
  end
  record DurationParts
    days: number
    hours: number
    minutes: number
    seconds: number
    milliseconds: number
    microseconds: number
  end

  -- The value constructors and enums that ui.install() makes global.
  record ColorType
    metamethod __call: function(self, argb: integer): integer
    fromARGB: function(a: integer, r: integer, g: integer, b: integer): integer
    fromRGBO: function(r: integer, g: integer, b: integer, opacity: number): integer
  end
  record EdgeInsetsType
    zero: EdgeInsets
    all: function(value: number): EdgeInsets
    symmetric: function(args: EdgeInsetsValue): EdgeInsets
    only: function(args: EdgeInsetsValue): EdgeInsets
    fromLTRB: function(left: number, top: number, right: number, bottom: number): EdgeInsets
  end
  record RadiusType
    zero: number
    circular: function(radius: number): number
  end
  record BorderRadiusType
    zero: BorderRadius
    circular: function(radius: number): BorderRadius
    all: function(radius: number): BorderRadius
    only: function(args: BorderRadiusValue): BorderRadius
  end
  record OffsetType
    metamethod __call: function(self, dx: number, dy: number): Offset
    zero: Offset
  end
  record AlignmentType
    metamethod __call: function(self, x: number, y: number): AlignmentXY
    topLeft: AlignmentName
    topCenter: AlignmentName
    topRight: AlignmentName
    centerLeft: AlignmentName
    center: AlignmentName
    centerRight: AlignmentName
    bottomLeft: AlignmentName
    bottomCenter: AlignmentName
    bottomRight: AlignmentName
  end
  record BorderType
    all: function(args: BorderSide): BorderSide
  end
  record AxisType
    horizontal: AxisName
    vertical: AxisName
  end
  record BoxFitType
    fill: BoxFitName
    contain: BoxFitName
    cover: BoxFitName
    fitWidth: BoxFitName
    fitHeight: BoxFitName
    none: BoxFitName
    scaleDown: BoxFitName
  end
  record BoxShapeType
    rectangle: BoxShapeName
    circle: BoxShapeName
  end
  record CrossAxisAlignmentType
    start: CrossAxisAlignmentName
    ["end"]: CrossAxisAlignmentName
    end_: CrossAxisAlignmentName
    center: CrossAxisAlignmentName
    stretch: CrossAxisAlignmentName
    baseline: CrossAxisAlignmentName
  end
  record FlexFitType
    tight: FlexFitName
    loose: FlexFitName
  end
  record FontStyleType
    normal: FontStyleName
    italic: FontStyleName
  end
  record FontWeightType
    normal: FontWeightName
    bold: FontWeightName
    w100: FontWeightName
    w200: FontWeightName
    w300: FontWeightName
    w400: FontWeightName
    w500: FontWeightName
    w600: FontWeightName
    w700: FontWeightName
    w800: FontWeightName
    w900: FontWeightName
  end
  record HitTestBehaviorType
    deferToChild: HitTestBehaviorName
    opaque: HitTestBehaviorName
    translucent: HitTestBehaviorName
  end
  record MainAxisAlignmentType
    start: MainAxisAlignmentName
    ["end"]: MainAxisAlignmentName
    end_: MainAxisAlignmentName
    center: MainAxisAlignmentName
    spaceBetween: MainAxisAlignmentName
    spaceAround: MainAxisAlignmentName
    spaceEvenly: MainAxisAlignmentName
  end
  record MainAxisSizeType
    min: MainAxisSizeName
    max: MainAxisSizeName
  end
  record StackFitType
    loose: StackFitName
    expand: StackFitName
    passthrough: StackFitName
  end
  record TextAlignType
    left: TextAlignName
    right: TextAlignName
    center: TextAlignName
    justify: TextAlignName
    start: TextAlignName
    ["end"]: TextAlignName
    end_: TextAlignName
  end
  record TextDecorationType
    none: TextDecorationName
    underline: TextDecorationName
    overline: TextDecorationName
    lineThrough: TextDecorationName
  end
  record TextOverflowType
    clip: TextOverflowName
    fade: TextOverflowName
    ellipsis: TextOverflowName
    visible: TextOverflowName
  end
  record WrapAlignmentType
    start: WrapAlignmentName
    ["end"]: WrapAlignmentName
    end_: WrapAlignmentName
    center: WrapAlignmentName
    spaceBetween: WrapAlignmentName
    spaceAround: WrapAlignmentName
    spaceEvenly: WrapAlignmentName
  end
  record WrapCrossAlignmentType
    start: WrapCrossAlignmentName
    ["end"]: WrapCrossAlignmentName
    end_: WrapCrossAlignmentName
    center: WrapCrossAlignmentName
  end

  ------------------------------------------------------------ widgets
  -- Arguments of each widget, named as in Flutter. Array entries are the
  -- Flutter positional parameters (Text { "hi" }); `key` is the widget key.
  record AlignArgs
    key: any
    alignment: Alignment
    widthFactor: number
    heightFactor: number
    child: Node
  end
  record AspectRatioArgs
    key: any
    aspectRatio: number
    child: Node
  end
  record CenterArgs
    key: any
    widthFactor: number
    heightFactor: number
    child: Node
  end
  record ClipRRectArgs
    key: any
    borderRadius: BorderRadius
    child: Node
  end
  record ColoredBoxArgs
    key: any
    color: Color
    child: Node
  end
  record ColumnArgs
    key: any
    mainAxisAlignment: MainAxisAlignmentName
    crossAxisAlignment: CrossAxisAlignmentName
    mainAxisSize: MainAxisSizeName
    spacing: number
    children: {Node}
  end
  record ContainerArgs
    key: any
    alignment: Alignment
    padding: EdgeInsets
    margin: EdgeInsets
    color: Color
    decoration: BoxDecoration
    width: number
    height: number
    child: Node
  end
  record DecoratedBoxArgs
    key: any
    decoration: BoxDecoration
    child: Node
  end
  record DefaultTextStyleArgs
    key: any
    style: TextStyle
    textAlign: TextAlignName
    maxLines: integer
    child: Node
  end
  record ExpandedArgs
    key: any
    flex: integer
    child: Node
  end
  record FlexibleArgs
    key: any
    flex: integer
    fit: FlexFitName
    child: Node
  end
  record GestureDetectorArgs
    key: any
    onTap: function()
    onDoubleTap: function()
    onLongPress: function()
    behavior: HitTestBehaviorName
    child: Node
  end
  record IconArgs is {string}
    key: any
    icon: string
    size: number
    color: Color
    semanticLabel: string
  end
  record ImageArgs
    key: any
    image: ImageProvider
    width: number
    height: number
    fit: BoxFitName
    semanticLabel: string
  end
  record ImageassetArgs is {string}
    key: any
    name: string
    width: number
    height: number
    fit: BoxFitName
    semanticLabel: string
  end
  record ImagenetworkArgs is {string}
    key: any
    src: string
    width: number
    height: number
    fit: BoxFitName
    semanticLabel: string
  end
  record ListViewArgs
    key: any
    scrollDirection: AxisName
    reverse: boolean
    shrinkWrap: boolean
    padding: EdgeInsets
    itemExtent: number
    children: {Node}
  end
  record ListViewbuilderArgs
    key: any
    scrollDirection: AxisName
    reverse: boolean
    shrinkWrap: boolean
    padding: EdgeInsets
    itemExtent: number
    itemCount: integer
    itemBuilder: IndexedBuilder
  end
  record ListViewseparatedArgs
    key: any
    scrollDirection: AxisName
    reverse: boolean
    shrinkWrap: boolean
    padding: EdgeInsets
    itemCount: integer
    itemBuilder: IndexedBuilder
    separatorBuilder: IndexedBuilder
  end
  record OpacityArgs
    key: any
    opacity: number
    child: Node
  end
  record PaddingArgs
    key: any
    padding: EdgeInsets
    child: Node
  end
  record PositionedArgs
    key: any
    left: number
    top: number
    right: number
    bottom: number
    width: number
    height: number
    child: Node
  end
  record RowArgs
    key: any
    mainAxisAlignment: MainAxisAlignmentName
    crossAxisAlignment: CrossAxisAlignmentName
    mainAxisSize: MainAxisSizeName
    spacing: number
    children: {Node}
  end
  record SafeAreaArgs
    key: any
    left: boolean
    top: boolean
    right: boolean
    bottom: boolean
    child: Node
  end
  record SingleChildScrollViewArgs
    key: any
    scrollDirection: AxisName
    reverse: boolean
    padding: EdgeInsets
    child: Node
  end
  record SizedBoxArgs
    key: any
    width: number
    height: number
    child: Node
  end
  record SizedBoxexpandArgs
    key: any
    child: Node
  end
  record SizedBoxshrinkArgs
    key: any
    child: Node
  end
  record SpacerArgs
    key: any
    flex: integer
  end
  record StackArgs
    key: any
    alignment: Alignment
    fit: StackFitName
    children: {Node}
  end
  record TextArgs is {string}
    key: any
    data: string
    style: TextStyle
    textAlign: TextAlignName
    maxLines: integer
    softWrap: boolean
    overflow: TextOverflowName
  end
  record WrapArgs
    key: any
    direction: AxisName
    spacing: number
    runSpacing: number
    alignment: WrapAlignmentName
    crossAxisAlignment: WrapCrossAlignmentName
    children: {Node}
  end

  record ImageConstructor
    metamethod __call: function(self, args: ImageArgs): Node
    asset: function(args: ImageassetArgs): Node
    network: function(args: ImagenetworkArgs): Node
  end
  record ListViewConstructor
    metamethod __call: function(self, args: ListViewArgs): Node
    builder: function(args: ListViewbuilderArgs): Node
    separated: function(args: ListViewseparatedArgs): Node
  end
  record SizedBoxConstructor
    metamethod __call: function(self, args: SizedBoxArgs): Node
    expand: function(args: SizedBoxexpandArgs): Node
    shrink: function(args: SizedBoxshrinkArgs): Node
  end

  -- Named arguments of Navigator.pushNamed.
  record NavigatorPushArgs
    arguments: any
  end
  record NavigatorReplaceArgs
    arguments: any
    result: any
  end
  -- The static Navigator methods without the BuildContext. pushNamed and
  -- maybePop wait for their Future inside event handlers and methods.
  record NavigatorType
    pushNamed: function(routeName: string, args?: NavigatorPushArgs): any
    pushReplacementNamed: function(routeName: string, args?: NavigatorReplaceArgs): any
    pop: function(result?: any)
    maybePop: function(result?: any): boolean
    canPop: function(): boolean
  end

  -- S is the type of the store, usually a record of the script.
  record AppSpec<S>
    -- The initial store, mirrored to the Dart LuaStore.
    store: S
    -- Functions the host calls with LuaViewController.call(name, args).
    methods: {string: function(store: S, args: any): any}
    view: function(store: S, props: Props): Node
  end

  record App
    render: function(props?: Props): {string: any}
    update: function(props?: Props): {string: any}
    dispatch: function(id: integer, args?: {any}, n?: integer): {string: any}
    resume: function(token: integer, ok: boolean, value: any): {string: any}
    build: function(id: integer, args?: {any}, n?: integer): {string: any}
    release: function(id: string): {string: any}
    call: function(name: string, args?: any): {string: any}
    set: function(path: {any}, value: any): {string: any}
    snapshot: function(): {any: any}
  end

  node: function(name: string, args?: {any: any}, positional?: {string}): Node
  widget: function(name: string, positional?: {string}): function(args?: {any: any}): Node
  library: function(prefix: string, names: {string}, positional?: {string: {string}}): {string: function(args?: {any: any}): Node}
  component: function(setup: function(props: Props): Render): Component
  -- Calls host function "library.Name" registered in Dart; waits for a
  -- Future inside event handlers and methods.
  invoke: function(name: string, ...: any): any
  functions: function(prefix: string, names: {string}): {string: any}
  set_host: function(host: function(name: string, n: integer, ...: any): {string: any})
  state: function<T>(initial?: T): T
  raw: function<T>(value: T): T
  pairs: function<K, V>(t: {K: V}): (function(): (K, V))
  enum: function(type_name: string, names: {string}): {string: string}
  instances: function(store: any): integer
  app: function<S>(spec: AppSpec<S>): App
  install: function(exports?: {string: any}, env?: {string: any}): {string: any}
  exports: {string: any}
  values: {string: any}

  -- The core library: package:flutter/widgets.dart.
  record Core
    Align: function(args: AlignArgs): Node
    AspectRatio: function(args: AspectRatioArgs): Node
    Center: function(args: CenterArgs): Node
    ClipRRect: function(args: ClipRRectArgs): Node
    ColoredBox: function(args: ColoredBoxArgs): Node
    Column: function(args: ColumnArgs): Node
    Container: function(args: ContainerArgs): Node
    DecoratedBox: function(args: DecoratedBoxArgs): Node
    DefaultTextStyle: function(args: DefaultTextStyleArgs): Node
    Expanded: function(args: ExpandedArgs): Node
    Flexible: function(args: FlexibleArgs): Node
    GestureDetector: function(args: GestureDetectorArgs): Node
    Icon: function(args: IconArgs): Node
    Image: ImageConstructor
    ListView: ListViewConstructor
    Opacity: function(args: OpacityArgs): Node
    Padding: function(args: PaddingArgs): Node
    Positioned: function(args: PositionedArgs): Node
    Row: function(args: RowArgs): Node
    SafeArea: function(args: SafeAreaArgs): Node
    SingleChildScrollView: function(args: SingleChildScrollViewArgs): Node
    SizedBox: SizedBoxConstructor
    Spacer: function(args: SpacerArgs): Node
    Stack: function(args: StackArgs): Node
    Text: function(args: TextArgs): Node
    Wrap: function(args: WrapArgs): Node
  end
  core: Core
  record CoreFunctions
    Navigator: NavigatorType
  end
  core_functions: CoreFunctions
end
return ui
