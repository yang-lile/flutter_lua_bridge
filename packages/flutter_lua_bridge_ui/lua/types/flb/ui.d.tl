-- Teal declarations for require("flb.ui"), the Lua module that LuaView of
-- flutter_lua_bridge_ui loads. Add this directory to include_dir in
-- tlconfig.lua.
local record ui
  -- A widget node, a component output or a component reference.
  type Node = {string: any}
  -- Widget arguments by name; functions are event handlers and `key` is the
  -- widget key. Lua code can also pass children and a Text's string as
  -- positional entries, which Teal's table types cannot express: in Teal
  -- write `children = {...}`, `child = ...` and `text = ...`.
  type Args = {string: any}
  type Props = {string: any}
  type Constructor = function(args?: Args): Node
  type Render = function(props: Props): Node
  type Component = function(props?: Props): Node

  record AppSpec
    -- The initial store, mirrored to the Dart LuaStore.
    store: {any: any}
    -- Functions the host calls with LuaViewController.call(name, args).
    methods: {string: function(store: any, args: any): any}
    view: function(store: any, props: Props): Node
  end

  record App
    render: function(props?: Props): {string: any}
    update: function(props?: Props): {string: any}
    dispatch: function(id: integer, args?: {string: any}): {string: any}
    call: function(name: string, args?: any): {string: any}
    set: function(path: {any}, value: any): {string: any}
    snapshot: function(): {any: any}
  end

  node: function(name: string, args?: Args): Node
  library: function(prefix: string, names: {string}): {string: Constructor}
  component: function(setup: function(props: Props): Render): Component
  state: function<T>(initial?: T): T
  raw: function<T>(value: T): T
  pairs: function<K, V>(t: {K: V}): (function(): (K, V))
  app: function(spec: AppSpec): App

  -- The core library: package:flutter/widgets.dart.
  core: {string: Constructor}
  Align: Constructor
  AspectRatio: Constructor
  Center: Constructor
  ClipRRect: Constructor
  ColoredBox: Constructor
  Column: Constructor
  Container: Constructor
  DecoratedBox: Constructor
  DefaultTextStyle: Constructor
  Expanded: Constructor
  Flexible: Constructor
  GestureDetector: Constructor
  Icon: Constructor
  Image: Constructor
  ListView: Constructor
  Opacity: Constructor
  Padding: Constructor
  Positioned: Constructor
  Row: Constructor
  SafeArea: Constructor
  SingleChildScrollView: Constructor
  SizedBox: Constructor
  Spacer: Constructor
  Stack: Constructor
  Text: Constructor
  Wrap: Constructor
end
return ui
