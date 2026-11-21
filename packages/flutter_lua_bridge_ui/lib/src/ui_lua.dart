/// The `flb.ui` Lua module that [LuaView] loads into its runtime.
///
/// It builds node tables for the Dart side:
///
/// * `{t = "core.Column", a = {...}, k = key}` is a widget node;
/// * a Lua function in the arguments becomes `{["$h"] = id}`;
/// * `{c = id, n = node}` is the output of component instance `id`, and
///   `{["$c"] = id}` an instance whose output Dart already has.
///
/// After the first render, Lua only sends the components whose reactive
/// state or props changed (`patches`), the instances it unmounted
/// (`removed`) and the writes to the store (`changes`).
const String uiLuaModule = 'flb.ui';

/// The source of [uiLuaModule].
const String uiLuaSource = r'''
-- flb.ui: builds Flutter widget trees for flutter_lua_bridge_ui.
local M = {}

local HANDLER = "$h"
local REF = "$c"
local ITERATE = {} -- dependency key for the length and the set of keys

-- The component instances being rendered, innermost last.
local stack = {}

local function rendering(what)
  local inst = stack[#stack]
  if inst == nil then
    error(what .. " can only be used while a view is rendering", 3)
  end
  return inst
end

---------------------------------------------------------------- reactivity

local raw_of = setmetatable({}, { __mode = "k" })   -- proxy -> table
local proxy_of = setmetatable({}, { __mode = "k" }) -- table -> proxy

local function track(deps, key)
  local inst = stack[#stack]
  if inst == nil then return end
  local set = deps[key]
  if set == nil then
    set = {}
    deps[key] = set
  end
  if not set[inst] then
    set[inst] = true
    inst.subs[set] = true
  end
end

local function trigger(deps, key)
  local set = deps[key]
  if set == nil then return end
  for inst in pairs(set) do inst.app.dirty[inst] = true end
end

local function child_path(path, key)
  local p = {}
  for i = 1, #path do p[i] = path[i] end
  p[#p + 1] = key
  return p
end

local reactive

local function wrap(value, app, path, key)
  if type(value) ~= "table" or getmetatable(value) ~= nil then return value end
  return reactive(value, app, path and child_path(path, key))
end

-- A proxy that records which component reads which key and re-renders
-- the readers when the key changes. `app` and `path` are set for the store,
-- whose writes are reported to Dart.
function reactive(t, app, path)
  local existing = proxy_of[t]
  if existing then return existing end
  local deps = {}
  local proxy = {}
  local meta = {}
  meta.__index = function(_, key)
    track(deps, key)
    return wrap(t[key], app, path, key)
  end
  meta.__newindex = function(_, key, value)
    value = raw_of[value] or value
    local old = t[key]
    if old == value then return end
    t[key] = value
    trigger(deps, key)
    if old == nil or value == nil then trigger(deps, ITERATE) end
    if app and not app.silent then
      app.changes[#app.changes + 1] = { path = child_path(path, key), value = value }
    end
  end
  meta.__len = function()
    track(deps, ITERATE)
    return #t
  end
  meta.__pairs = function()
    track(deps, ITERATE)
    return function(_, key)
      local k, v = next(t, key)
      return k, wrap(v, app, path, k)
    end, proxy, nil
  end
  setmetatable(proxy, meta)
  raw_of[proxy] = t
  proxy_of[t] = proxy
  return proxy
end

-- Reactive local state for a component; create it in the setup function.
function M.state(initial)
  return reactive(initial or {})
end

-- The plain table behind a reactive proxy (or the value itself).
function M.raw(value)
  return raw_of[value] or value
end

-- pairs() that works on proxies in every Lua release.
function M.pairs(t)
  local mt = getmetatable(t)
  if mt and mt.__pairs then return mt.__pairs(t) end
  return next, t, nil
end

---------------------------------------------------------------- nodes

local function register(inst, fn)
  local app = inst.app
  local id = app.next_id
  app.next_id = id + 1
  app.handlers[id] = fn
  inst.handlers[id] = true
  return { [HANDLER] = id }
end

-- Creates the node of widget `name` ("library.Widget"; no library means core).
-- Positional entries of `args` are children: they become `children`, and a
-- single one also `child`; a string first entry of a Text is its text.
-- Functions become event handlers and `key` becomes the widget key.
function M.node(name, args)
  if type(name) ~= "string" then
    error("widget name must be a string, got " .. type(name), 2)
  end
  local node = { t = name }
  if args == nil then return node end
  if type(args) ~= "table" then
    error(name .. ": arguments must be a table, got " .. type(args), 2)
  end
  local count = #args
  if count > 0 then
    if count == 1 and type(args[1]) == "string" and args.text == nil then
      args.text = args[1]
      args[1] = nil
    else
      local children = {}
      for i = 1, count do
        children[i] = args[i]
        args[i] = nil
      end
      if args.children == nil then args.children = children end
      if count == 1 and args.child == nil then args.child = children[1] end
    end
  end
  local key = args.key
  if key ~= nil then
    node.k = key
    args.key = nil
  end
  for field, value in pairs(args) do
    local kind = type(value)
    if kind == "function" then
      args[field] = register(rendering("event handlers"), value)
    elseif kind == "table" and raw_of[value] then
      args[field] = raw_of[value]
    end
  end
  node.a = args
  return node
end

-- A table of constructors for the widgets `names` of library `prefix`:
-- `local m = ui.library("material", {"ElevatedButton"})`.
function M.library(prefix, names)
  local lib = {}
  for _, short in ipairs(names) do
    local full = prefix .. "." .. short
    lib[short] = function(args) return M.node(full, args) end
  end
  return lib
end

---------------------------------------------------------------- components

local function unsubscribe(inst)
  for set in pairs(inst.subs) do set[inst] = nil end
  inst.subs = {}
  local handlers = inst.app.handlers
  for id in pairs(inst.handlers) do handlers[id] = nil end
  inst.handlers = {}
end

local function unmount(inst)
  local app = inst.app
  for _, child in pairs(inst.children) do unmount(child) end
  unsubscribe(inst)
  app.instances[inst.id] = nil
  app.dirty[inst] = nil
  app.removed[#app.removed + 1] = inst.id
end

local function render_instance(inst, props)
  unsubscribe(inst)
  local previous = inst.children
  inst.children = {}
  inst.count = 0
  inst.props = props
  inst.app.dirty[inst] = nil
  stack[#stack + 1] = inst
  local node = inst.render(props)
  stack[#stack] = nil
  if type(node) ~= "table" then
    error("component " .. inst.id .. " must return a widget node", 0)
  end
  for id, child in pairs(previous) do
    if inst.children[id] == nil then unmount(child) end
  end
  return node
end

local function same_props(a, b)
  for k, v in pairs(a) do
    if b[k] ~= v then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

local function use(def, props)
  local parent = rendering("components")
  props = props or {}
  local key = props.key
  props.key = nil
  parent.count = parent.count + 1
  local id = parent.id .. "/" .. (key ~= nil and tostring(key) or ("#" .. parent.count))
  if parent.children[id] then
    error("two components have the key " .. tostring(key), 3)
  end
  local app = parent.app
  local inst = app.instances[id]
  if inst and inst.def ~= def then
    unmount(inst)
    inst = nil
  end
  if inst == nil then
    inst = {
      id = id, app = app, def = def, depth = parent.depth + 1,
      subs = {}, handlers = {}, children = {}, count = 0,
    }
    app.instances[id] = inst
    stack[#stack + 1] = inst
    local render = def.setup(props)
    stack[#stack] = nil
    if type(render) ~= "function" then
      error("component setup must return its render function", 3)
    end
    inst.render = render
  elseif not app.dirty[inst] and same_props(inst.props, props) then
    parent.children[id] = inst
    return { [REF] = id }
  end
  parent.children[id] = inst
  return { c = id, n = render_instance(inst, props) }
end

-- Defines a component. `setup(props)` runs once per instance and returns
-- `render(props)`, which returns a widget node. The instance renders again
-- when reactive state it read changes or its props change (compared field
-- by field); otherwise Dart keeps its widgets. Call the result with the
-- props table; `key` in props identifies the instance among its siblings.
function M.component(setup)
  if type(setup) ~= "function" then
    error("ui.component expects a setup function", 2)
  end
  local def = { setup = setup }
  return function(props) return use(def, props) end
end

---------------------------------------------------------------- apps

local function flush(app)
  local patches = {}
  for _ = 1, 100 do
    if next(app.dirty) == nil then break end
    local list = {}
    for inst in pairs(app.dirty) do list[#list + 1] = inst end
    table.sort(list, function(a, b) return a.depth < b.depth end)
    for _, inst in ipairs(list) do
      if app.dirty[inst] and app.instances[inst.id] == inst then
        patches[#patches + 1] = { id = inst.id, tree = render_instance(inst, inst.props) }
      end
      app.dirty[inst] = nil
    end
  end
  if next(app.dirty) ~= nil then
    error("the view keeps changing state while rendering", 0)
  end
  local result = { patches = patches, removed = app.removed, changes = app.changes }
  app.removed = {}
  app.changes = {}
  return result
end

-- Creates an app. `spec.view(store, props)` returns the root node;
-- `spec.store` is the initial store, whose changes are mirrored to the
-- Dart LuaStore; `spec.methods` are functions the host can call as
-- `method(store, args)`.
function M.app(spec)
  if type(spec) ~= "table" or type(spec.view) ~= "function" then
    error("ui.app expects a table with a view function", 2)
  end
  local view = spec.view
  local methods = spec.methods or {}
  local raw_store = spec.store or {}
  local app = {
    next_id = 1, handlers = {}, instances = {}, dirty = {},
    removed = {}, changes = {}, silent = false,
  }
  local store = reactive(raw_store, app, {})
  app.store = store
  local api = {}

  local function new_root()
    local root = {
      id = "root", app = app, depth = 0,
      subs = {}, handlers = {}, children = {}, count = 0,
      render = function(props) return view(store, props) end,
    }
    app.instances.root = root
    app.root = root
    return root
  end

  -- Renders everything; returns { root = node, removed = , changes = }.
  function api.render(props)
    stack = {}
    if app.root then unmount(app.root) end
    app.dirty = {}
    local root = new_root()
    local node = render_instance(root, props or {})
    local result = { root = { c = "root", n = node }, removed = app.removed, changes = app.changes }
    app.removed = {}
    app.changes = {}
    return result
  end

  -- Renders the root again with new props and returns the patches.
  function api.update(props)
    stack = {}
    app.root.props = props or {}
    app.dirty[app.root] = true
    return flush(app)
  end

  -- Runs event handler `id`; returns the patches.
  function api.dispatch(id, args)
    stack = {}
    local fn = app.handlers[id]
    if fn ~= nil then fn(args or {}) end
    return flush(app)
  end

  -- Runs `methods[name](store, args)`; returns the patches and `value`.
  function api.call(name, args)
    stack = {}
    local fn = methods[name]
    if type(fn) ~= "function" then
      error("the app has no method " .. tostring(name), 2)
    end
    local value = fn(store, args)
    local result = flush(app)
    result.value = raw_of[value] or value
    return result
  end

  -- Writes `value` at `path` of the store for the host; returns the patches.
  function api.set(path, value)
    stack = {}
    app.silent = true
    local ok, err = pcall(function()
      local t = store
      for i = 1, #path - 1 do
        if t[path[i]] == nil then t[path[i]] = {} end
        t = t[path[i]]
      end
      t[path[#path]] = value
    end)
    app.silent = false
    if not ok then error(err, 0) end
    return flush(app)
  end

  -- The store as plain data.
  function api.snapshot()
    return raw_store
  end

  return api
end

-- Constructors for the core library (package:flutter/widgets.dart).
M.core = M.library("core", {
  "Align", "AspectRatio", "Center", "ClipRRect", "ColoredBox", "Column",
  "Container", "DecoratedBox", "DefaultTextStyle", "Expanded", "Flexible",
  "GestureDetector", "Icon", "Image", "ListView", "Opacity", "Padding",
  "Positioned", "Row", "SafeArea", "SingleChildScrollView", "SizedBox",
  "Spacer", "Stack", "Text", "Wrap",
})
for short, ctor in pairs(M.core) do M[short] = ctor end

return M
''';
