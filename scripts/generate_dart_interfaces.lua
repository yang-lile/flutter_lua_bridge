#!/usr/bin/env lua
-- generate_dart_interfaces.lua - 基于contents.html生成Dart接口

local INPUT_DIR = "src/lua/doc"
local OUTPUT_DIR = "lib/src/interfaces"

-- 工具函数
local function trim(s) return s:match("^%s*(.-)%s*$") end
local function read_file(p)
    local f = io.open(p, "r")
    if not f then return nil end
    local c = f:read("*all")
    f:close()
    return c
end
local function write_file(p, c)
    local f = io.open(p, "w")
    f:write(c)
    f:close()
    print("Generated: " .. p)
end

-- 提取返回类型（从函数签名中提取返回值类型）
local function extract_return_type(sig)
    if not sig then return "int" end
    -- 匹配函数名（lua_或luaL_开头）之前的所有内容
    local ret = sig:match("^(.-)luaL?_%w+")
    if not ret or trim(ret) == "" then
        -- 如果前面没有空格，匹配开头到函数名
        ret = sig:match("^([%w_%s%*]+)luaL?_%w+")
    end
    if not ret then return "int" end
    return trim(ret:gsub("const%s+", ""))
end

-- C类型转Dart类型
local function to_dart_type(t)
    if not t then return "int" end
    t = trim(t:gsub("const%s+", ""))
    if t:find("lua_CFunction") or t:find("lua_Alloc") or 
       t:find("lua_Hook") or t:find("lua_Reader") or
       t:find("lua_Writer") or t:find("lua_KFunction") then
        return "ffi.Pointer<ffi.NativeFunction>"
    end
    if t:find("lua_State") then
        return "ffi.Pointer<ffi.Void>"
    end
    if t:find("%*") then
        return "ffi.Pointer<ffi.Void>"
    end
    if t:find("lua_Number") then return "double" end
    if t:find("void") then return "void" end
    if t:find("lua_Integer") or t:find("int") or t:find("size_t") or t:find("ptrdiff") then
        return "int"
    end
    return "int"
end

-- 解析参数
local function parse_params(sig)
    local params = {}
    local pstr = sig:match("%((.-)%)%s*;?$")
    if not pstr or pstr == "void" then return params end
    for part in pstr:gmatch("([^,]+)") do
        part = trim(part)
        local name = part:match("(%w+)%s*$")
        if name and name ~= "L" then
            local typ = trim(part:sub(1, #part - #name))
            table.insert(params, {name=name, dart_type=to_dart_type(typ)})
        end
    end
    return params
end

-- 驼峰命名转换
local function to_camel_case(s, prefix)
    s = s:gsub("^" .. prefix .. "_", "")
    local r, first = {}, true
    for p in s:gmatch("[^_]+") do
        table.insert(r, first and p or (p:gsub("^%l", string.upper)))
        first = false
    end
    return table.concat(r)
end

-- 从manual.html获取函数详细信息
local function get_func_info(html, anchor, func_name)
    -- 找到函数在HTML中的位置
    local anchor_escaped = anchor:gsub("%-", "%%-")
    local start_pos = html:find('<a name="' .. anchor_escaped .. '"')
    if not start_pos then return nil end
    
    -- 提取函数块（从anchor开始到下一个<hr>或< h3 >）
    local chunk = html:sub(start_pos, start_pos + 3000)
    
    -- 提取栈效果
    local stack = chunk:match('<span class="apii">%[(.-)%]</span>')
    if stack then
        stack = trim(stack:gsub("&ndash;", "-"))
        -- 替换 <em> 标签
        stack = stack:gsub("<em>e</em>", "e")
        stack = stack:gsub("<em>v</em>", "v")
        stack = stack:gsub("<em>m</em>", "m")
    end
    
    -- 提取代码
    local code = chunk:match('<pre>(.-)</pre>')
    if code then
        code = code:gsub("&nbsp;", " "):gsub("<.->", "")
        code = trim(code)
    end
    
    -- 验证函数名
    if not code or not code:find(func_name) then
        return nil
    end
    
    -- 提取描述（在</pre>后的第一个<p>和<hr>或<h3>之间）
    local desc = nil
    local pre_end_pos = chunk:find('</pre>')
    if pre_end_pos then
        -- 在</pre>之后查找内容
        local after_pre = chunk:sub(pre_end_pos + 6)  -- +6 是 </pre> 的长度
        -- 查找 <p> 开始
        local p_start = after_pre:find('<p>')
        if p_start then
            -- 提取 <p> 之后到 <hr> 或 <h3 或下一个 <pre> 之前的内容
            local content = after_pre:sub(p_start + 3)
            -- 找到结束标记
            local end_pos = content:find('<hr>') or content:find('<h3') or content:find('<pre>') or content:find('<p>')
            if end_pos then
                desc = content:sub(1, end_pos - 1)
            else
                desc = content
            end
            
            -- 清理描述
            if desc then
                desc = desc:gsub("<.->", "")  -- 移除HTML标签
                desc = desc:gsub("&sect;", "§")
                desc = desc:gsub("&ndash;", "-")
                desc = desc:gsub("&mdash;", "--")
                desc = desc:gsub("&ldquo;", '"')
                desc = desc:gsub("&rdquo;", '"')
                desc = desc:gsub("&lsquo;", "'")
                desc = desc:gsub("&rsquo;", "'")
                desc = desc:gsub("&lt;", "<")
                desc = desc:gsub("&gt;", ">")
                desc = desc:gsub("&amp;", "&")
                desc = desc:gsub("%s+", " ")
                desc = trim(desc)
            end
        end
    end
    
    return code, stack, desc
end

-- 主程序
print("Generating Dart interfaces...")
os.execute("mkdir -p " .. OUTPUT_DIR)

local contents = read_file(INPUT_DIR .. "/contents.html")
local manual = read_file(INPUT_DIR .. "/manual.html")

if not contents or not manual then
    error("Cannot read HTML files")
end

-- 生成types.dart
write_file(OUTPUT_DIR.."/types.dart", [[// AUTO GENERATED FILE by scripts/generate_dart_interfaces.lua
export '../gen/flutter_lua_bridge.g.dart' show
    lua_State, lua_Integer, lua_Number, lua_CFunction, lua_KContext,
    lua_KFunction, lua_Alloc, lua_Hook, lua_Reader, lua_Writer,
    lua_WarnFunction, lua_Debug;
]] )

-- 生成constants.dart
write_file(OUTPUT_DIR.."/constants.dart", [[// AUTO GENERATED FILE by scripts/generate_dart_interfaces.lua
abstract final class LuaType {
  static const int none=-1, nil=0, boolean=1, lightUserdata=2, number=3,
    string=4, table=5, function=6, userdata=7, thread=8;
}
abstract final class LuaStatus {
  static const int ok=0, yield=1, errRun=2, errSyntax=3, errMem=4,
    errGcMM=5, errErr=6;
}
abstract final class LuaGC {
  static const int stop=0, restart=1, collect=2, count=3, countB=4,
    step=5, setPause=6, setStepMul=7;
}
abstract final class LuaOp {
  static const int eq=0, lt=1, le=2, add=0, sub=1, mul=2, div=3,
    idiv=4, mod=5, pow=6, unm=7, band=8, bor=9, bxor=10, shl=11,
    shr=12, bnot=13;
}
]] )

-- 从contents.html解析函数列表
local function parse_func_list(pattern)
    local seen = {}
    local funcs = {}
    for anchor in contents:gmatch(pattern) do
        local func_name = anchor:match("(luaL?_%w+)$")
        if func_name and not seen[func_name] then
            seen[func_name] = true
            table.insert(funcs, {name=func_name, anchor=anchor})
        end
    end
    return funcs
end

-- 生成接口文件
local function generate_interface(class_name, funcs, prefix, is_aux)
    local lines = {
        "// AUTO GENERATED FILE by scripts/generate_dart_interfaces.lua",
        "// " .. class_name,
        "",
        "import 'dart:ffi' as ffi;",
        "import 'types.dart';",
        "",
        "abstract interface class " .. class_name .. " {",
        "  ffi.Pointer<lua_State> get state;",
        ""
    }
    
    local count = 0
    for _, f in ipairs(funcs) do
        local sig, stack, desc = get_func_info(manual, f.anchor, f.name)
        if sig and sig:find("%(") then
            count = count + 1
            -- 文档注释：描述
            if desc and desc ~= "" then
                table.insert(lines, "  /// " .. desc)
                table.insert(lines, "  ///")
            end
            -- 栈效果
            if stack then
                table.insert(lines, "  /// Stack: `[" .. stack .. "]`")
            end
            -- C签名
            table.insert(lines, "  ///")
            local sig_oneline = sig:gsub("\n%s+", " ")
            table.insert(lines, "  /// C: `" .. sig_oneline .. "`")
            
            -- 方法签名
            local params = parse_params(sig)
            local method = to_camel_case(f.name, prefix)
            local ret = to_dart_type(extract_return_type(sig))
            
            local ps = {}
            for _, p in ipairs(params) do
                local n = p.name
                -- Convert to lowerCamelCase for Dart style
                if n:match("^[A-Z]") then
                    n = n:sub(1,1):lower() .. n:sub(2)
                end
                if n == "from" or n == "to" or n == "type" then n = n .. "_" end
                table.insert(ps, p.dart_type .. " " .. n)
            end
            
            table.insert(lines, "  " .. ret .. " " .. method .. "(" .. table.concat(ps, ", ") .. ");")
            table.insert(lines, "")
        end
    end
    
    table.insert(lines, "}")
    print("  " .. class_name .. ": " .. count .. " functions")
    return table.concat(lines, "\n")
end

-- C API函数 (排除类型定义)
local c_funcs = parse_func_list('HREF="manual%.html#(lua_[%w_]+)"')
local c_filtered = {}
for _, f in ipairs(c_funcs) do
    -- 排除typedef类型
    if f.name ~= "lua_State" and f.name ~= "lua_Integer" and
       f.name ~= "lua_Number" and f.name ~= "lua_CFunction" and
       f.name ~= "lua_Debug" and f.name ~= "lua_Alloc" and
       f.name ~= "lua_KFunction" and f.name ~= "lua_KContext" and
       f.name ~= "lua_Hook" and f.name ~= "lua_Reader" and
       f.name ~= "lua_Writer" and f.name ~= "lua_WarnFunction" and
       f.name ~= "lua_Unsigned" then
        table.insert(c_filtered, f)
    end
end
table.sort(c_filtered, function(a,b) return a.name < b.name end)
write_file(OUTPUT_DIR.."/c_api.dart", generate_interface("LuaCAPI", c_filtered, "lua", false))

-- Auxiliary函数
local aux_funcs = parse_func_list('HREF="manual%.html#(luaL_[%w_]+)"')
local aux_filtered = {}
for _, f in ipairs(aux_funcs) do
    -- 排除类型定义
    if f.name ~= "luaL_Buffer" then
        table.insert(aux_filtered, f)
    end
end
table.sort(aux_filtered, function(a,b) return a.name < b.name end)
write_file(OUTPUT_DIR.."/aux_lib.dart", generate_interface("LuaAuxLib", aux_filtered, "luaL", true))

-- index.dart
write_file(OUTPUT_DIR.."/index.dart", [[// AUTO GENERATED FILE by scripts/generate_dart_interfaces.lua
library;
export 'dart:ffi' show Pointer, DynamicLibrary;
export 'types.dart';
export 'constants.dart';
export 'c_api.dart';
export 'aux_lib.dart';
]] )

print("\nDone!")
