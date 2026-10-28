#!/usr/bin/env lua
-- 生成 Dart FFI 接口的 Lua 脚本
-- 从 Lua 文档中解析 C API 并生成 Dart 绑定代码

local function read_file(filepath)
    local f = io.open(filepath, "r")
    if not f then
        error("无法打开文件: " .. filepath)
    end
    local content = f:read("*all")
    f:close()
    return content
end

local function write_file(filepath, content)
    local f = io.open(filepath, "w")
    if not f then
        error("无法创建文件: " .. filepath)
    end
    f:write(content)
    f:close()
end

local function ensure_dir(dir)
    os.execute("mkdir -p " .. dir)
end

-- 从 contents.html 解析 C API 列表
local function parse_contents_html(content)
    local apis = {}
    local types = {}
    local constants = {}
    
    -- 匹配 C API 链接
    for href, name in content:gmatch('<A HREF="manual%.html#([^"]+)">([^<]+)</A>') do
        local api_info = {
            name = name,
            href = href,
            category = "function"
        }
        
        -- 判断类型
        if name:match("^lua_") then
            if name:match("^lua_") and not name:match("^lua_[a-z]+") then
                -- 可能是类型定义（如 lua_State, lua_Integer）
                api_info.category = "type"
                table.insert(types, api_info)
            else
                table.insert(apis, api_info)
            end
        elseif name:match("^luaL_") then
            api_info.category = "aux"
            table.insert(apis, api_info)
        elseif name:match("^LUA_") then
            api_info.category = "constant"
            table.insert(constants, api_info)
        end
    end
    
    return apis, types, constants
end

-- 从 manual.html 解析 API 详细信息
local function parse_manual_html(content, api_name)
    local api_info = {
        name = api_name,
        signature = nil,
        apii = nil,
        description = {},
        is_typedef = false,
        is_macro = false
    }
    
    -- 查找 API 定义位置
    local pattern = '<a name="' .. api_name:gsub("%-", "%%-") .. '"[^>]*>'
    local start_pos = content:find(pattern)
    
    if not start_pos then
        return nil
    end
    
    -- 从该位置开始提取信息
    local section = content:sub(start_pos, start_pos + 5000)
    
    -- 提取 apii (stack 信息)
    api_info.apii = section:match('<span class="apii">([^<]+)</span>')
    
    -- 提取函数签名（支持多行）
    -- 匹配 <pre>...</pre> 之间的内容，可能跨多行
    local sig_start, sig_end = section:find('<pre>')
    if sig_start then
        -- 找到对应的 </pre>
        local pre_end = section:find('</pre>', sig_end + 1)
        if pre_end then
            local sig = section:sub(sig_end + 1, pre_end - 1)
            -- 替换换行和多余空白
            sig = sig:gsub("\n%s+", " ")  -- 将换行及缩进替换为空格
            sig = sig:gsub("&ndash;", "-"):gsub("<", "<"):gsub(">", ">"):gsub("&", "&")
            api_info.signature = sig:gsub("^%s*(.-)%s*$", "%1")
            
            -- 检查是否是 typedef
            if api_info.signature:match("^typedef") then
                api_info.is_typedef = true
            end
        end
    end
    
    -- 提取描述（从第一个 <p> 到下一个 <hr> 之间的所有内容）
    local desc_parts = {}
    local desc_start = section:find('</pre>')
    if desc_start then
        local desc_section = section:sub(desc_start)
        -- 找到下一个 <hr> 作为结束位置
        local hr_pos = desc_section:find('<hr>')
        if hr_pos then
            desc_section = desc_section:sub(1, hr_pos - 1)
        end
        -- 提取所有 <p> 标签内容
        -- 模式：匹配 <p> 开始到下一个 <p 或 </p> 或字符串结束
        local i = 1
        while true do
            local s, e, matched
            -- 首先尝试匹配到下一个 <p 或 </p>
            s, e, matched = desc_section:find('<p>(.-)</?p>', i)
            if s then
                i = e + 1
            else
                -- 尝试匹配到字符串结束
                s, e = desc_section:find('<p>(.+)$', i)
                if s then
                    matched = desc_section:sub(s + 3)  -- 跳过 '<p>'
                    i = #desc_section + 1
                else
                    break
                end
            end
            if matched then
                -- 移除 HTML 标签
                local cleaned = matched:gsub('<[^>]+>', '')
                -- 转换 HTML 实体
                cleaned = cleaned:gsub("&ndash;", "-"):gsub("<", "<"):gsub(">", ">"):gsub("&", "&")
                cleaned = cleaned:gsub("&nbsp;", " ")
                -- 清理空白
                cleaned = cleaned:gsub("^%s*(.-)%s*$", "%1")
                -- 压缩多行空格和换行
                cleaned = cleaned:gsub("%s+", " ")
                if #cleaned > 0 then
                    table.insert(desc_parts, cleaned)
                end
            end
        end
    end
    api_info.description = desc_parts
    
    return api_info
end

-- C 类型到 Dart 类型的映射
-- 使用 Dart 原生类型与 ffigen 生成的绑定保持一致
local c_to_dart_types = {
    -- 基本类型
    ["void"] = "void",
    ["int"] = "int",
    ["unsigned int"] = "int",
    ["long"] = "int",
    ["unsigned long"] = "int",
    ["size_t"] = "int",
    ["char"] = "int",
    ["unsigned char"] = "int",
    ["short"] = "int",
    ["unsigned short"] = "int",
    ["float"] = "double",
    ["double"] = "double",
    ["lua_Number"] = "double",
    ["lua_Integer"] = "int",
    ["lua_Unsigned"] = "int",
    ["lua_KContext"] = "int",
    ["ptrdiff_t"] = "int",
    
    -- FFI 原生类型
    ["DynamicLibrary"] = "ffi.DynamicLibrary",
    -- IntPtr 在 Dart FFI 中使用 int 表示地址
    ["IntPtr"] = "int",
    
    -- 指针类型
    ["void*"] = "ffi.Pointer<ffi.Void>",
    ["void**"] = "ffi.Pointer<ffi.Pointer<ffi.Void>>",
    ["const void*"] = "ffi.Pointer<ffi.Void>",
    ["char*"] = "ffi.Pointer<ffi.Char>",
    ["const char*"] = "ffi.Pointer<ffi.Char>",
    ["unsigned char*"] = "ffi.Pointer<ffi.UnsignedChar>",
    ["const char* const*"] = "ffi.Pointer<ffi.Pointer<ffi.Char>>",
    ["const char* const lst[]"] = "ffi.Pointer<ffi.Pointer<ffi.Char>>",
    ["const char*const lst[]"] = "ffi.Pointer<ffi.Pointer<ffi.Char>>",
    ["int*"] = "ffi.Pointer<ffi.Int>",
    ["size_t*"] = "ffi.Pointer<ffi.Size>",
    ["lua_Number*"] = "ffi.Pointer<ffi.Double>",
    ["lua_Integer*"] = "ffi.Pointer<lua_Integer>",
    ["lua_State*"] = "ffi.Pointer<lua_State>",
    ["lua_Debug*"] = "ffi.Pointer<lua_Debug>",
    ["lua_Alloc"] = "lua_Alloc",
    ["lua_CFunction"] = "lua_CFunction",
    ["lua_Hook"] = "lua_Hook",
    ["lua_KFunction"] = "lua_KFunction",
    ["lua_Reader"] = "lua_Reader",
    ["lua_Writer"] = "lua_Writer",
    ["lua_WarnFunction"] = "lua_WarnFunction",
    ["luaL_Buffer*"] = "ffi.Pointer<flb.luaL_Buffer>",
    ["luaL_Reg*"] = "ffi.Pointer<flb.luaL_Reg>",
    ["FILE*"] = "ffi.Pointer<FILE>",
    ["va_list"] = "ffi.Pointer<va_list$1>",
}

-- 解析 C 函数签名
local function parse_c_signature(sig)
    if not sig then return nil end
    
    -- 移除 typedef 前缀
    sig = sig:gsub("^typedef%s+", "")
    
    -- 匹配函数签名: return_type func_name(params)
    local pattern = "^(.-)%s*([%a_][%w_]*)%s*%((.*)%);?$"
    local ret_type, func_name, params = sig:match(pattern)
    
    if not ret_type then
        -- 可能是函数指针 typedef
        local ptr_pattern = "^%(%s*[*]%s*([%a_][%w_]*)%s*%)%s*%((.*)%)$"
        func_name, params = sig:match(ptr_pattern)
        if func_name then
            -- 函数指针，从签名开头获取返回类型
            ret_type = sig:match("^(.-)%s*%(")
            ret_type = ret_type:gsub("[%(%)]", "")
        end
    end
    
    if not ret_type or not func_name then
        return nil
    end
    
    -- 清理返回类型
    ret_type = ret_type:gsub("^%s*(.-)%s*$", "%1")
    
    return {
        return_type = ret_type,
        name = func_name,
        params = params
    }
end

-- 解析参数列表
local function parse_params(params_str)
    if not params_str or params_str == "" or params_str == "void" then
        return {}
    end
    
    local params = {}
    local depth = 0
    local current = ""
    
    for i = 1, #params_str do
        local char = params_str:sub(i, i)
        if char == "(" or char == "<" then
            depth = depth + 1
            current = current .. char
        elseif char == ")" or char == ">" then
            depth = depth - 1
            current = current .. char
        elseif char == "," and depth == 0 then
            local trimmed = (current:gsub("^%s*(.-)%s*$", "%1"))
            table.insert(params, trimmed)
            current = ""
        else
            current = current .. char
        end
    end
    
    local trimmed = (current:gsub("^%s*(.-)%s*$", "%1"))
    if trimmed ~= "" then
        table.insert(params, trimmed)
    end
    
    return params
end

-- 将 C 参数转换为 Dart 参数
local function c_param_to_dart(param)
    -- 处理带默认值或变长参数的省略
    if param:match("^%.%.%.$") then
        return nil  -- 变长参数在 FFI 中需要特殊处理
    end
    
    -- 检查是否是数组类型（如 const char *const lst[]）
    local array_pattern = "(.-)%s*([%a_][%w_]*)%s*%[%]$"
    local type_part, name = param:match(array_pattern)
    if type_part then
        -- 数组类型，移除 [] 后查找类型
        type_part = type_part:gsub("^%s*(.-)%s*$", "%1")
        -- 对于字符串数组，使用 Pointer<Pointer<Char>>
        if type_part:match("const char") or type_part:match("char") then
            return {
                dart_type = "ffi.Pointer<ffi.Pointer<ffi.Char>>",
                name = name
            }
        end
        -- 其他数组类型
        return {
            dart_type = "ffi.Pointer<ffi.Void>",
            name = name
        }
    end
    
    -- 提取参数名和类型（处理指针类型如 lua_State* L 或 void** ud）
    -- 先尝试匹配多级指针类型: 类型名** 参数名（可能有空格）
    local multi_ptr_pattern = "([%a_][%w_]*)%s*(%*+)%s*([%a_][%w_]*)$"
    local base_type, stars, var_name = param:match(multi_ptr_pattern)
    
    if base_type and stars then
        -- 是指针类型（可能多级）
        type_part = base_type .. stars
        name = var_name
    else
        -- 非指针类型，使用普通模式
        local param_pattern = "(.-)%s+([%a_][%w_]*)$"
        type_part, name = param:match(param_pattern)
    end
    
    if not type_part then
        -- 可能是函数指针参数
        if param:find("%(") then
            -- 简化处理：函数指针参数
            local func_name = param:match("%(%s*[*]%s*([%a_][%w_]*)%s*%)%s*%(")
            return {
                dart_type = "ffi.Pointer<ffi.NativeFunction>",
                name = func_name or "callback"
            }
        end
        type_part = param
        name = "arg"
    end
    
    type_part = type_part:gsub("^%s*(.-)%s*$", "%1")
    
    -- 查找 Dart 类型
    local dart_type = c_to_dart_types[type_part]
    if not dart_type then
        -- 尝试匹配指针类型
        if type_part:find("[*]") then
            dart_type = "ffi.Pointer<ffi.Void>"
        else
            dart_type = "int"  -- 默认类型
        end
    end
    
    return {
        dart_type = dart_type,
        name = name
    }
end

-- 生成 Dart FFI 函数绑定
local function generate_dart_binding(api_info)
    if not api_info.signature then
        return nil
    end
    
    -- 特殊处理 luaL_opt 宏定义
    if api_info.name == "luaL_opt" then
        local lines = {}
        table.insert(lines, "  /// " .. api_info.name)
        table.insert(lines, "  ///")
        if api_info.apii then
            table.insert(lines, "  /// Stack: " .. api_info.apii:gsub("^%s*(.-)%s*$", "%1"))
            table.insert(lines, "  ///")
        end
        if #api_info.description > 0 then
            for _, desc in ipairs(api_info.description) do
                desc = desc:gsub("\n", " ")
                table.insert(lines, "  /// " .. desc)
            end
        end
        -- luaL_opt 是泛型宏，在 Dart 中简化为返回 int
        table.insert(lines, "  int luaL_opt(ffi.Pointer<lua_State> L, int func, int arg, int dflt);")
        return table.concat(lines, "\n")
    end
    
    local parsed = parse_c_signature(api_info.signature)
    if not parsed then
        return nil
    end
    
    local lines = {}
    
    -- 添加文档注释
    table.insert(lines, "  /// " .. api_info.name)
    table.insert(lines, "  ///")
    if api_info.apii then
        table.insert(lines, "  /// Stack: " .. api_info.apii:gsub("^%s*(.-)%s*$", "%1"))
        table.insert(lines, "  ///")
    end
    if #api_info.description > 0 then
        for _, desc in ipairs(api_info.description) do
            desc = desc:gsub("\n", " ")
            table.insert(lines, "  /// " .. desc)
        end
    end
    
    -- 解析参数
    local params = parse_params(parsed.params)
    local dart_params = {}
    local native_params = {}
    
    for _, param in ipairs(params) do
        local dart_param = c_param_to_dart(param)
        if dart_param then
            table.insert(dart_params, dart_param.dart_type .. " " .. dart_param.name)
            table.insert(native_params, dart_param.dart_type)
        end
    end
    
    -- 获取返回类型
    local ret_type = c_to_dart_types[parsed.return_type] or "int"
    
    -- 生成函数签名
    local func_sig = "  " .. ret_type .. " " .. api_info.name .. "("
    if #dart_params > 0 then
        func_sig = func_sig .. table.concat(dart_params, ", ")
    end
    func_sig = func_sig .. ")"
    
    table.insert(lines, func_sig .. ";")
    
    return table.concat(lines, "\n")
end

-- 生成 Dart 类型定义
local function generate_dart_typedef(api_info)
    if not api_info.signature then
        return nil
    end
    
    local sig = api_info.signature
    
    -- 处理 typedef struct
    if sig:match("^typedef%s+struct") then
        return "  /// Struct: " .. api_info.name .. "\n  // Struct definition requires manual implementation"
    end
    
    -- 处理函数指针 typedef
    local func_ptr = sig:match("^typedef%s+(.-)%s*%(%s*[*]%s*" .. api_info.name .. "%s*%)%s*%((.-)%)%s*;")
    if func_ptr then
        local ret_type = c_to_dart_types[func_ptr:gsub("^%s*(.-)%s*$", "%1")] or "int"
        local params = parse_params(sig:match("%((.-)%)%s*;"))
        local dart_params = {}
        
        for _, param in ipairs(params) do
            local dart_param = c_param_to_dart(param)
            if dart_param then
                table.insert(dart_params, dart_param.dart_type)
            end
        end
        
        local typedef_line = "  typedef " .. api_info.name .. "_Func = " .. ret_type .. " Function("
        if #dart_params > 0 then
            typedef_line = typedef_line .. table.concat(dart_params, ", ")
        end
        typedef_line = typedef_line .. ");"
        
        return "  /// Function type: " .. api_info.name .. "\n" .. typedef_line
    end
    
    return nil
end

-- 生成完整的 Dart 文件
local function generate_dart_file(apis_info, types_info, constants_info, filename)
    local lines = {}
    
    -- 文件头
    table.insert(lines, "// Auto-generated from Lua C API documentation")
    table.insert(lines, "// Generated by: lua_api/scripts/generate_dart_interfaces.lua")
    table.insert(lines, "// DO NOT EDIT MANUALLY")
    table.insert(lines, "")
    table.insert(lines, "import 'dart:ffi' as ffi;")
    table.insert(lines, "import 'flutter_lua_bridge.g.dart' as flb;")
    table.insert(lines, "")
    
    -- 类型别名 - 直接使用 FFI 中的类型
    table.insert(lines, "// Type aliases from FFI bindings")
    table.insert(lines, "typedef lua_State = flb.lua_State;")
    table.insert(lines, "typedef lua_Debug = flb.lua_Debug;")
    table.insert(lines, "typedef lua_CFunction = flb.lua_CFunction;")
    table.insert(lines, "typedef lua_KFunction = flb.lua_KFunction;")
    table.insert(lines, "typedef lua_Alloc = flb.lua_Alloc;")
    table.insert(lines, "typedef lua_Hook = flb.lua_Hook;")
    table.insert(lines, "typedef lua_Reader = flb.lua_Reader;")
    table.insert(lines, "typedef lua_Writer = flb.lua_Writer;")
    table.insert(lines, "typedef lua_WarnFunction = flb.lua_WarnFunction;")
    table.insert(lines, "typedef lua_Integer = flb.lua_Integer;")
    table.insert(lines, "typedef FILE = flb.FILE;")
    table.insert(lines, [[typedef va_list$1 = flb.va_list$1;]])
    table.insert(lines, "")
    
    -- 常量定义部分
    if #constants_info > 0 then
        table.insert(lines, "// ============================================")
        table.insert(lines, "// Constants")
        table.insert(lines, "// ============================================")
        table.insert(lines, "")
        
        for _, api_info in ipairs(constants_info) do
            if api_info.signature then
                local const_val = api_info.signature:match("#define%s+" .. api_info.name .. "%s+(.-)$")
                if const_val then
                    table.insert(lines, "  /// " .. api_info.name)
                    table.insert(lines, "  static const int " .. api_info.name .. " = " .. const_val .. ";")
                    table.insert(lines, "")
                end
            end
        end
    end
    
    -- 函数绑定部分
    table.insert(lines, "// ============================================")
    table.insert(lines, "// C API Bindings")
    table.insert(lines, "// ============================================")
    table.insert(lines, "")
    table.insert(lines, "abstract class LuaCApi {")
    table.insert(lines, "  /// Lookup function for dynamic library")
    table.insert(lines, "  static late final ffi.DynamicLibrary _dylib;")
    table.insert(lines, "")
    table.insert(lines, "  /// Initialize with dynamic library")
    table.insert(lines, "  static void initialize(ffi.DynamicLibrary dylib) {")
    table.insert(lines, "    _dylib = dylib;")
    table.insert(lines, "  }")
    table.insert(lines, "")
    
    -- 分组输出函数
    local current_group = nil
    for _, api_info in ipairs(apis_info) do
        -- 按前缀分组
        local prefix = api_info.name:match("^(lua[a-zA-Z]*_)")
        if prefix and prefix ~= current_group then
            current_group = prefix
            table.insert(lines, "")
            table.insert(lines, "  // --- " .. current_group .. " functions ---")
        end
        
        local binding = generate_dart_binding(api_info)
        if binding then
            table.insert(lines, binding)
            table.insert(lines, "")
        end
    end
    
    table.insert(lines, "}")
    table.insert(lines, "")
    
    return table.concat(lines, "\n")
end

-- 生成 auxiliary library Dart 文件
local function generate_aux_dart_file(apis_info, filename)
    local lines = {}
    
    -- 文件头
    table.insert(lines, "// Auto-generated from Lua Auxiliary Library documentation")
    table.insert(lines, "// Generated by: lua_api/scripts/generate_dart_interfaces.lua")
    table.insert(lines, "// DO NOT EDIT MANUALLY")
    table.insert(lines, "")
    table.insert(lines, "import 'dart:ffi' as ffi;")
    table.insert(lines, "import 'flutter_lua_bridge.g.dart' as flb;")
    table.insert(lines, "import 'lua_c_api.dart';")
    table.insert(lines, "")
    table.insert(lines, "// ============================================")
    table.insert(lines, "// Auxiliary Library Bindings")
    table.insert(lines, "// ============================================")
    table.insert(lines, "")
    table.insert(lines, "abstract class LuaAuxApi {")
    table.insert(lines, "  /// Lookup function for dynamic library")
    table.insert(lines, "  static late final ffi.DynamicLibrary _dylib;")
    table.insert(lines, "")
    table.insert(lines, "  /// Initialize with dynamic library")
    table.insert(lines, "  static void initialize(ffi.DynamicLibrary dylib) {")
    table.insert(lines, "    _dylib = dylib;")
    table.insert(lines, "  }")
    table.insert(lines, "")
    
    -- 分组输出函数
    local current_group = nil
    for _, api_info in ipairs(apis_info) do
        local prefix = api_info.name:match("^(luaL_[a-z]+)")
        if prefix and prefix ~= current_group then
            current_group = prefix
            table.insert(lines, "")
            table.insert(lines, "  // --- " .. current_group .. " functions ---")
        end
        
        local binding = generate_dart_binding(api_info)
        if binding then
            table.insert(lines, binding)
            table.insert(lines, "")
        end
    end
    
    table.insert(lines, "}")
    table.insert(lines, "")
    
    return table.concat(lines, "\n")
end

-- 主函数
local function main()
    print("Lua C API Dart Interface Generator")
    print("===================================")
    
    -- 读取文件（从项目根目录运行）
    local contents_path = "lua_src/doc/contents.html"
    local manual_path = "lua_src/doc/manual.html"
    local output_dir = "flutter_lua_bridge/lib/src/gen"
    
    print("\nReading " .. contents_path .. "...")
    local contents = read_file(contents_path)
    
    print("Reading " .. manual_path .. "...")
    local manual = read_file(manual_path)
    
    -- 解析 API 列表
    print("\nParsing C API list...")
    local apis, types, constants = parse_contents_html(contents)
    
    print(string.format("Found %d functions, %d types, %d constants", #apis, #types, #constants))
    
    -- 分离 C API 和 auxiliary library
    local capi_list = {}
    local aux_list = {}
    
    for _, api in ipairs(apis) do
        if api.category == "aux" or api.name:match("^luaL_") then
            table.insert(aux_list, api)
        else
            table.insert(capi_list, api)
        end
    end
    
    print(string.format("  - C API functions: %d", #capi_list))
    print(string.format("  - Auxiliary functions: %d", #aux_list))
    
    -- 解析详细信息
    print("\nParsing detailed API information...")
    
    local capi_info_list = {}
    for i, api in ipairs(capi_list) do
        local info = parse_manual_html(manual, api.href)
        if info then
            table.insert(capi_info_list, info)
        end
        if i % 20 == 0 then
            print(string.format("  Progress: %d/%d", i, #capi_list))
        end
    end
    
    local aux_info_list = {}
    for i, api in ipairs(aux_list) do
        local info = parse_manual_html(manual, api.href)
        if info then
            table.insert(aux_info_list, info)
        end
    end
    
    local types_info_list = {}
    for _, api in ipairs(types) do
        local info = parse_manual_html(manual, api.href)
        if info then
            table.insert(types_info_list, info)
        end
    end
    
    local constants_info_list = {}
    for _, api in ipairs(constants) do
        local info = parse_manual_html(manual, api.href)
        if info then
            table.insert(constants_info_list, info)
        end
    end
    
    print(string.format("Parsed %d C API, %d auxiliary, %d types, %d constants", 
        #capi_info_list, #aux_info_list, #types_info_list, #constants_info_list))
    
    -- 确保输出目录存在
    ensure_dir(output_dir)
    
    -- 生成 Dart 文件
    print("\nGenerating Dart files...")
    
    local capi_dart = generate_dart_file(capi_info_list, types_info_list, constants_info_list, "lua_c_api")
    local capi_path = output_dir .. "/lua_c_api.dart"
    write_file(capi_path, capi_dart)
    print("  Generated: " .. capi_path)
    
    if #aux_info_list > 0 then
        local aux_dart = generate_aux_dart_file(aux_info_list, "lua_aux_api")
        local aux_path = output_dir .. "/lua_aux_api.dart"
        write_file(aux_path, aux_dart)
        print("  Generated: " .. aux_path)
    end
    
    print("\nDone!")
    print("===================================")
end

-- 运行主函数
main()
