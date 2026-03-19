# Lua 5.5 C API 参考

自动生成的 API 文档，包含堆栈影响信息。

格式说明：`[-弹出数, +压入数, 错误标志]`

- **弹出数**: 函数从堆栈弹出的元素数量（负数表示弹出，如 `-n`）
- **压入数**: 函数向堆栈压入的元素数量（正数表示压入，如 `+n`）
- **错误标志**: `e`=可能抛出错误, `m`=可能触发内存错误, `v`=可能触发任意错误, `-`=无错误
- **堆栈净变化**: 压入数 - 弹出数

---

## C API 函数 (共 124 个)

| 函数 | 签名 | 堆栈影响 | 错误 | 净变化 | 描述 |
|------|------|----------|------|--------|------|
| `lua_absindex` | `int lua_absindex (lua_State *L, int idx);` | [0, +0] | - | 0 | Converts the acceptable index idx into an equivalent absolute index (that is,... |
| `lua_arith` | `void lua_arith (lua_State *L, int op);` | [(2|1), +1] | e | +1 -(2|1) | Performs an arithmetic or bitwise operation over the two values (or one, in t... |
| `lua_atpanic` | `lua_CFunction lua_atpanic (lua_State *L, lua_CFunction panicf);` | [0, +0] | - | 0 | Sets a new panic function and returns the old one (see &sect;4.4). |
| `lua_call` | `void lua_call (lua_State *L, int nargs, int nresults);` | [(nargs+1), +nresults] | e | +nresults -(nargs+1) | Calls a function. Like regular Lua calls, lua_call respects the __call metame... |
| `lua_callk` | `void lua_callk (lua_State *L, int nargs, int nresults, lua_KContext ctx, lua_KFunction k);` | [(nargs + 1), +nresults] | e | +nresults -(nargs + 1) | This function behaves exactly like lua_call, but allows the called function t... |
| `lua_checkstack` | `int lua_checkstack (lua_State *L, int n);` | [0, +0] | - | 0 | Ensures that the stack has space for at least n extra elements, that is, that... |
| `lua_close` | `void lua_close (lua_State *L);` | [0, +0] | - | 0 | Close all active to-be-closed variables in the main thread, release all objec... |
| `lua_closeslot` | `void lua_closeslot (lua_State *L, int index);` | [0, +0] | e | 0 | Close the to-be-closed slot at the given index and set its value to nil. The ... |
| `lua_closethread` | `int lua_closethread (lua_State *L, lua_State *from);` | [0, +?] | - | ? | Resets a thread, cleaning its call stack and closing all pending to-be-closed... |
| `lua_compare` | `int lua_compare (lua_State *L, int index1, int index2, int op);` | [0, +0] | e | 0 | Compares two Lua values. Returns 1 if the value at index index1 satisfies op ... |
| `lua_concat` | `void lua_concat (lua_State *L, int n);` | [n, +1] | e | +1 -n | Concatenates the n values at the top of the stack, pops them, and leaves the ... |
| `lua_copy` | `void lua_copy (lua_State *L, int fromidx, int toidx);` | [0, +0] | - | 0 | Copies the element at index fromidx into the valid index toidx, replacing the... |
| `lua_createtable` | `void lua_createtable (lua_State *L, int nseq, int nrec);` | [0, +1] | m | +1 | Creates a new empty table and pushes it onto the stack. Parameter nseq is a h... |
| `lua_dump` | `int lua_dump (lua_State *L, lua_Writer writer, void *data, int strip);` | [0, +0] | - | 0 | Dumps a function as a binary chunk. Receives a Lua function on the top of the... |
| `lua_error` | `int lua_error (lua_State *L);` | [1, +0] | v | -1 | Raises a Lua error, using the value on the top of the stack as the error obje... |
| `lua_gc` | `int lua_gc (lua_State *L, int what, ...);` | [0, +0] | - | 0 | Controls the garbage collector. > This function performs several tasks, accor... |
| `lua_getallocf` | `lua_Alloc lua_getallocf (lua_State *L, void **ud);` | [0, +0] | - | 0 | Returns the memory-allocator function of a given state. If ud is not NULL, Lu... |
| `lua_getextraspace` | `void *lua_getextraspace (lua_State *L);` | [0, +0] | - | 0 | Returns a pointer to a raw memory area associated with the given Lua state. T... |
| `lua_getfield` | `int lua_getfield (lua_State *L, int index, const char *k);` | [0, +1] | e | +1 | Pushes onto the stack the value t[k], where t is the value at the given index... |
| `lua_getglobal` | `int lua_getglobal (lua_State *L, const char *name);` | [0, +1] | e | +1 | Pushes onto the stack the value of the global name. Returns the type of that ... |
| `lua_gethook` | `lua_Hook lua_gethook (lua_State *L);` | [0, +0] | - | 0 | Returns the current hook function. |
| `lua_gethookcount` | `int lua_gethookcount (lua_State *L);` | [0, +0] | - | 0 | Returns the current hook count. |
| `lua_gethookmask` | `int lua_gethookmask (lua_State *L);` | [0, +0] | - | 0 | Returns the current hook mask. |
| `lua_geti` | `int lua_geti (lua_State *L, int index, lua_Integer i);` | [0, +1] | e | +1 | Pushes onto the stack the value t[i], where t is the value at the given index... |
| `lua_getinfo` | `int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);` | [(0|1), +(0|1|2)] | m | +(0|1|2) -(0|1) | Gets information about a specific function or function invocation. > To get i... |
| `lua_getiuservalue` | `int lua_getiuservalue (lua_State *L, int index, int n);` | [0, +1] | - | +1 | Pushes onto the stack the n-th user value associated with the full userdata a... |
| `lua_getlocal` | `const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);` | [0, +(0|1)] | - | +(0|1) -0 | Gets information about a local variable or a temporary value of a given activ... |
| `lua_getmetatable` | `int lua_getmetatable (lua_State *L, int index);` | [0, +(0|1)] | - | +(0|1) -0 | If the value at the given index has a metatable, the function pushes that met... |
| `lua_getstack` | `int lua_getstack (lua_State *L, int level, lua_Debug *ar);` | [0, +0] | - | 0 | Gets information about the interpreter runtime stack. > This function fills p... |
| `lua_gettable` | `int lua_gettable (lua_State *L, int index);` | [1, +1] | e | 0 | Pushes onto the stack the value t[k], where t is the value at the given index... |
| `lua_gettop` | `int lua_gettop (lua_State *L);` | [0, +0] | - | 0 | Returns the index of the top element in the stack. Because indices start at 1... |
| `lua_getupvalue` | `const char *lua_getupvalue (lua_State *L, int funcindex, int n);` | [0, +(0|1)] | - | +(0|1) -0 | Gets information about the n-th upvalue of the closure at index funcindex. It... |
| `lua_insert` | `void lua_insert (lua_State *L, int index);` | [1, +1] | - | 0 | Moves the top element into the given valid index, shifting up the elements ab... |
| `lua_isboolean` | `int lua_isboolean (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a boolean, and 0 otherwise. |
| `lua_iscfunction` | `int lua_iscfunction (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a C function, and 0 otherwise. |
| `lua_isfunction` | `int lua_isfunction (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a function (either C or Lua), an... |
| `lua_isinteger` | `int lua_isinteger (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is an integer (that is, the value i... |
| `lua_islightuserdata` | `int lua_islightuserdata (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a light userdata, and 0 otherwise. |
| `lua_isnil` | `int lua_isnil (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is nil, and 0 otherwise. |
| `lua_isnone` | `int lua_isnone (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the given index is not valid, and 0 otherwise. |
| `lua_isnoneornil` | `int lua_isnoneornil (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the given index is not valid or if the value at this index is ni... |
| `lua_isnumber` | `int lua_isnumber (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a number or a string convertible... |
| `lua_isstring` | `int lua_isstring (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a string or a number (which is a... |
| `lua_istable` | `int lua_istable (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a table, and 0 otherwise. |
| `lua_isthread` | `int lua_isthread (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a thread, and 0 otherwise. |
| `lua_isuserdata` | `int lua_isuserdata (lua_State *L, int index);` | [0, +0] | - | 0 | Returns 1 if the value at the given index is a userdata (either full or light... |
| `lua_isyieldable` | `int lua_isyieldable (lua_State *L);` | [0, +0] | - | 0 | Returns 1 if the given coroutine can yield, and 0 otherwise. |
| `lua_len` | `void lua_len (lua_State *L, int index);` | [0, +1] | e | +1 | Returns the length of the value at the given index. It is equivalent to the '... |
| `lua_load` | `int lua_load (lua_State *L, lua_Reader reader, void *data, const char *chunkname, const char *mode);` | [0, +1] | - | +1 | Loads a Lua chunk without running it. If there are no errors, lua_load pushes... |
| `lua_newstate` | `lua_State *lua_newstate (lua_Alloc f, void *ud, unsigned int seed);` | [0, +0] | - | 0 | Creates a new independent state and returns its main thread. Returns NULL if ... |
| `lua_newtable` | `void lua_newtable (lua_State *L);` | [0, +1] | m | +1 | Creates a new empty table and pushes it onto the stack. It is equivalent to l... |
| `lua_newthread` | `lua_State *lua_newthread (lua_State *L);` | [0, +1] | m | +1 | Creates a new thread, pushes it on the stack, and returns a pointer to a lua_... |
| `lua_newuserdatauv` | `void *lua_newuserdatauv (lua_State *L, size_t size, int nuvalue);` | [0, +1] | m | +1 | This function creates and pushes on the stack a new full userdata, with nuval... |
| `lua_next` | `int lua_next (lua_State *L, int index);` | [1, +(2|0)] | v | +(2|0) -1 | Pops a key from the stack, and pushes a key–value pair from the table at th... |
| `lua_numbertocstring` | `unsigned lua_numbertocstring (lua_State *L, int idx, char *buff);` | [0, +0] | - | 0 | Converts the number at acceptable index idx to a string and puts the result i... |
| `lua_numbertointeger` | `unsigned lua_numbertocstring (lua_State *L, int idx, char *buff);` | [0, +0] | - | 0 | Converts the number at acceptable index idx to a string and puts the result i... |
| `lua_pcall` | `int lua_pcall (lua_State *L, int nargs, int nresults, int msgh);` | [(nargs + 1), +(nresults|1)] | - | +(nresults|1) -(nargs + 1) | Calls a function (or a callable object) in protected mode. > Both nargs and n... |
| `lua_pcallk` | `int lua_pcallk (lua_State *L, int nargs, int nresults, int msgh, lua_KContext ctx, lua_KFunction k);` | [(nargs + 1), +(nresults|1)] | - | +(nresults|1) -(nargs + 1) | This function behaves exactly like lua_pcall, except that it allows the calle... |
| `lua_pop` | `void lua_pop (lua_State *L, int n);` | [n, +0] | e | +0 -n | Pops n elements from the stack. It is implemented as a macro over lua_settop. |
| `lua_pushboolean` | `void lua_pushboolean (lua_State *L, int b);` | [0, +1] | - | +1 | Pushes a boolean value with value b onto the stack. |
| `lua_pushcclosure` | `void lua_pushcclosure (lua_State *L, lua_CFunction fn, int n);` | [n, +1] | m | +1 -n | Pushes a new C closure onto the stack. This function receives a pointer to a ... |
| `lua_pushcfunction` | `void lua_pushcfunction (lua_State *L, lua_CFunction f);` | [0, +1] | - | +1 | Pushes a C function onto the stack. This function is equivalent to lua_pushcc... |
| `lua_pushexternalstring` | `const char *lua_pushexternalstring (lua_State *L, const char *s, size_t len, lua_Alloc falloc, void *ud);` | [0, +1] | m | +1 | Creates an external string, that is, a string that uses memory not managed by... |
| `lua_pushfstring` | `const char *lua_pushfstring (lua_State *L, const char *fmt, ...);` | [0, +1] | v | +1 | Pushes onto the stack a formatted string and returns a pointer to this string... |
| `lua_pushglobaltable` | `void lua_pushglobaltable (lua_State *L);` | [0, +1] | - | +1 | Pushes the global environment onto the stack. |
| `lua_pushinteger` | `void lua_pushinteger (lua_State *L, lua_Integer n);` | [0, +1] | - | +1 | Pushes an integer with value n onto the stack. |
| `lua_pushlightuserdata` | `void lua_pushlightuserdata (lua_State *L, void *p);` | [0, +1] | - | +1 | Pushes a light userdata onto the stack. > Userdata represent C values in Lua.... |
| `lua_pushliteral` | `const char *lua_pushliteral (lua_State *L, const char *s);` | [0, +1] | v | +1 | This macro is equivalent to lua_pushstring, but should be used only when s is... |
| `lua_pushlstring` | `const char *lua_pushlstring (lua_State *L, const char *s, size_t len);` | [0, +1] | v | +1 | Pushes the string pointed to by s with size len onto the stack. Lua will make... |
| `lua_pushnil` | `void lua_pushnil (lua_State *L);` | [0, +1] | - | +1 | Pushes a nil value onto the stack. |
| `lua_pushnumber` | `void lua_pushnumber (lua_State *L, lua_Number n);` | [0, +1] | - | +1 | Pushes a float with value n onto the stack. |
| `lua_pushstring` | `const char *lua_pushstring (lua_State *L, const char *s);` | [0, +1] | m | +1 | Pushes the zero-terminated string pointed to by s onto the stack. Lua will ma... |
| `lua_pushthread` | `int lua_pushthread (lua_State *L);` | [0, +1] | - | +1 | Pushes the thread represented by L onto the stack. Returns 1 if this thread i... |
| `lua_pushvalue` | `void lua_pushvalue (lua_State *L, int index);` | [0, +1] | - | +1 | Pushes a copy of the element at the given index onto the stack. |
| `lua_pushvfstring` | `const char *lua_pushvfstring (lua_State *L, const char *fmt, va_list argp);` | [0, +1] | - | +1 | Equivalent to lua_pushfstring, except that it receives a va_list instead of a... |
| `lua_rawequal` | `int lua_rawequal (lua_State *L, int index1, int index2);` | [0, +0] | - | 0 | Returns 1 if the two values in indices index1 and index2 are primitively equa... |
| `lua_rawget` | `int lua_rawget (lua_State *L, int index);` | [1, +1] | - | 0 | Similar to lua_gettable, but does a raw access (i.e., without metamethods). T... |
| `lua_rawgeti` | `int lua_rawgeti (lua_State *L, int index, lua_Integer n);` | [0, +1] | - | +1 | Pushes onto the stack the value t[n], where t is the table at the given index... |
| `lua_rawgetp` | `int lua_rawgetp (lua_State *L, int index, const void *p);` | [0, +1] | - | +1 | Pushes onto the stack the value t[k], where t is the table at the given index... |
| `lua_rawlen` | `lua_Unsigned lua_rawlen (lua_State *L, int index);` | [0, +0] | - | 0 | Returns the raw "length" of the value at the given index: for strings, this i... |
| `lua_rawset` | `void lua_rawset (lua_State *L, int index);` | [2, +0] | m | -2 | Similar to lua_settable, but does a raw assignment (i.e., without metamethods... |
| `lua_rawseti` | `void lua_rawseti (lua_State *L, int index, lua_Integer i);` | [1, +0] | m | -1 | Does the equivalent of t[i] = v, where t is the table at the given index and ... |
| `lua_rawsetp` | `void lua_rawsetp (lua_State *L, int index, const void *p);` | [1, +0] | m | -1 | Does the equivalent of t[p] = v, where t is the table at the given index, p i... |
| `lua_register` | `void lua_register (lua_State *L, const char *name, lua_CFunction f);` | [0, +0] | e | 0 | Sets the C function f as the new value of global name. It is defined as a mac... |
| `lua_remove` | `void lua_remove (lua_State *L, int index);` | [1, +0] | - | -1 | Removes the element at the given valid index, shifting down the elements abov... |
| `lua_replace` | `void lua_replace (lua_State *L, int index);` | [1, +0] | - | -1 | Moves the top element into the given valid index without shifting any element... |
| `lua_resume` | `int lua_resume (lua_State *L, lua_State *from, int nargs, int *nresults);` | [?, +?] | - | ? | Starts and resumes a coroutine in the given thread L. > To start a coroutine,... |
| `lua_rotate` | `void lua_rotate (lua_State *L, int idx, int n);` | [0, +0] | - | 0 | Rotates the stack elements between the valid index idx and the top of the sta... |
| `lua_setallocf` | `void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);` | [0, +0] | - | 0 | Changes the allocator function of a given state to f with user data ud. |
| `lua_setfield` | `void lua_setfield (lua_State *L, int index, const char *k);` | [1, +0] | e | -1 | Does the equivalent to t[k] = v, where t is the value at the given index and ... |
| `lua_setglobal` | `void lua_setglobal (lua_State *L, const char *name);` | [1, +0] | e | -1 | Pops a value from the stack and sets it as the new value of global name. |
| `lua_sethook` | `void lua_sethook (lua_State *L, lua_Hook f, int mask, int count);` | [0, +0] | - | 0 | Sets the debugging hook function. > Argument f is the hook function. mask spe... |
| `lua_seti` | `void lua_seti (lua_State *L, int index, lua_Integer n);` | [1, +0] | e | -1 | Does the equivalent to t[n] = v, where t is the value at the given index and ... |
| `lua_setiuservalue` | `int lua_setiuservalue (lua_State *L, int index, int n);` | [1, +0] | - | -1 | Pops a value from the stack and sets it as the new n-th user value associated... |
| `lua_setlocal` | `const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);` | [(0|1), +0] | - | +0 -(0|1) | Sets the value of a local variable of a given activation record. It assigns t... |
| `lua_setmetatable` | `int lua_setmetatable (lua_State *L, int index);` | [1, +0] | - | -1 | Pops a table or nil from the stack and sets that value as the new metatable f... |
| `lua_settable` | `void lua_settable (lua_State *L, int index);` | [2, +0] | e | -2 | Does the equivalent to t[k] = v, where t is the value at the given index, v i... |
| `lua_settop` | `void lua_settop (lua_State *L, int index);` | [?, +?] | e | ? | Receives any acceptable stack index, or 0, and sets the stack top to this ind... |
| `lua_setupvalue` | `const char *lua_setupvalue (lua_State *L, int funcindex, int n);` | [(0|1), +0] | - | +0 -(0|1) | Sets the value of a closure's upvalue. It assigns the value on the top of the... |
| `lua_setwarnf` | `void lua_setwarnf (lua_State *L, lua_WarnFunction f, void *ud);` | [0, +0] | - | 0 | Sets the warning function to be used by Lua to emit warnings (see lua_WarnFun... |
| `lua_status` | `int lua_status (lua_State *L);` | [0, +0] | - | 0 | Returns the status of the thread L. > The status can be LUA_OK for a normal t... |
| `lua_stringtonumber` | `size_t lua_stringtonumber (lua_State *L, const char *s);` | [0, +1] | - | +1 | Converts the zero-terminated string s to a number, pushes that number into th... |
| `lua_toboolean` | `int lua_toboolean (lua_State *L, int index);` | [0, +0] | - | 0 | Converts the Lua value at the given index to a C boolean value (0 or 1). Like... |
| `lua_tocfunction` | `lua_CFunction lua_tocfunction (lua_State *L, int index);` | [0, +0] | - | 0 | Converts a value at the given index to a C function. That value must be a C f... |
| `lua_toclose` | `void lua_toclose (lua_State *L, int index);` | [0, +0] | v | 0 | Marks the given index in the stack as a to-be-closed slot (see &sect;3.3.8). ... |
| `lua_tointeger` | `lua_Integer lua_tointeger (lua_State *L, int index);` | [0, +0] | - | 0 | Equivalent to lua_tointegerx with isnum equal to NULL. |
| `lua_tointegerx` | `lua_Integer lua_tointegerx (lua_State *L, int index, int *isnum);` | [0, +0] | - | 0 | Converts the Lua value at the given index to the signed integral type lua_Int... |
| `lua_tolstring` | `const char *lua_tolstring (lua_State *L, int index, size_t *len);` | [0, +0] | m | 0 | Converts the Lua value at the given index to a C string. The Lua value must b... |
| `lua_tonumber` | `lua_Number lua_tonumber (lua_State *L, int index);` | [0, +0] | - | 0 | Equivalent to lua_tonumberx with isnum equal to NULL. |
| `lua_tonumberx` | `lua_Number lua_tonumberx (lua_State *L, int index, int *isnum);` | [0, +0] | - | 0 | Converts the Lua value at the given index to the C type lua_Number (see lua_N... |
| `lua_topointer` | `const void *lua_topointer (lua_State *L, int index);` | [0, +0] | - | 0 | Converts the value at the given index to a generic C pointer (void*). The val... |
| `lua_tostring` | `const char *lua_tostring (lua_State *L, int index);` | [0, +0] | m | 0 | Equivalent to lua_tolstring with len equal to NULL. |
| `lua_tothread` | `lua_State *lua_tothread (lua_State *L, int index);` | [0, +0] | - | 0 | Converts the value at the given index to a Lua thread (represented as lua_Sta... |
| `lua_touserdata` | `void *lua_touserdata (lua_State *L, int index);` | [0, +0] | - | 0 | If the value at the given index is a full userdata, returns its memory-block ... |
| `lua_type` | `int lua_type (lua_State *L, int index);` | [0, +0] | - | 0 | Returns the type of the value in the given valid index, or LUA_TNONE for a no... |
| `lua_typename` | `const char *lua_typename (lua_State *L, int tp);` | [0, +0] | - | 0 | Returns the name of the type encoded by the value tp, which must be one the v... |
| `lua_upvalueid` | `void *lua_upvalueid (lua_State *L, int funcindex, int n);` | [0, +0] | - | 0 | Returns a unique identifier for the upvalue numbered n from the closure at in... |
| `lua_upvalueindex` | `int lua_upvalueindex (int i);` | [0, +0] | - | 0 | Returns the pseudo-index that represents the i-th upvalue of the running func... |
| `lua_upvaluejoin` | `void lua_upvaluejoin (lua_State *L, int funcindex1, int n1, int funcindex2, int n2);` | [0, +0] | - | 0 | Make the n1-th upvalue of the Lua closure at index funcindex1 refer to the n2... |
| `lua_version` | `lua_Number lua_version (lua_State *L);` | [0, +0] | - | 0 | Returns the version number of this core. |
| `lua_warning` | `void lua_warning (lua_State *L, const char *msg, int tocont);` | [0, +0] | - | 0 | Emits a warning with the given message. A message in a call with tocont true ... |
| `lua_xmove` | `void lua_xmove (lua_State *from, lua_State *to, int n);` | [?, +?] | - | ? | Exchange values between different threads of the same state. > This function ... |
| `lua_yield` | `int lua_yield (lua_State *L, int nresults);` | [?, +?] | v | ? | This function is equivalent to lua_yieldk, but it has no continuation (see &s... |
| `lua_yieldk` | `int lua_yieldk (lua_State *L, int nresults, lua_KContext ctx, lua_KFunction k);` | [?, +?] | v | ? | Yields a coroutine (thread). > When a C function calls lua_yieldk, the runnin... |

---

## Auxiliary Library 函数 (共 68 个)

| 函数 | 签名 | 堆栈影响 | 错误 | 净变化 | 描述 |
|------|------|----------|------|--------|------|
| `luaL_addchar` | `void luaL_addchar (luaL_Buffer *B, char c);` | [?, +?] | m | ? | Adds the byte c to the buffer B (see luaL_Buffer). |
| `luaL_addgsub` | `const void luaL_addgsub (luaL_Buffer *B, const char *s, const char *p, const char *r);` | [?, +?] | m | ? | Adds a copy of the string s to the buffer B (see luaL_Buffer), replacing any ... |
| `luaL_addlstring` | `void luaL_addlstring (luaL_Buffer *B, const char *s, size_t l);` | [?, +?] | m | ? | Adds the string pointed to by s with length l to the buffer B (see luaL_Buffe... |
| `luaL_addsize` | `void luaL_addsize (luaL_Buffer *B, size_t n);` | [?, +?] | - | ? | Adds to the buffer B a string of length n previously copied to the buffer are... |
| `luaL_addstring` | `void luaL_addstring (luaL_Buffer *B, const char *s);` | [?, +?] | m | ? | Adds the zero-terminated string pointed to by s to the buffer B (see luaL_Buf... |
| `luaL_addvalue` | `void luaL_addvalue (luaL_Buffer *B);` | [?, +?] | m | ? | Adds the value on the top of the stack to the buffer B (see luaL_Buffer). Pop... |
| `luaL_argcheck` | `void luaL_argcheck (lua_State *L, int cond, int arg, const char *extramsg);` | [0, +0] | v | 0 | Checks whether cond is true. If it is not, raises an error with a standard me... |
| `luaL_argerror` | `int luaL_argerror (lua_State *L, int arg, const char *extramsg);` | [0, +0] | v | 0 | Raises an error reporting a problem with argument arg of the C function that ... |
| `luaL_argexpected` | `void luaL_argexpected (lua_State *L, int cond, int arg, const char *tname);` | [0, +0] | v | 0 | Checks whether cond is true. If it is not, raises an error about the type of ... |
| `luaL_buffaddr` | `char *luaL_buffaddr (luaL_Buffer *B);` | [0, +0] | - | 0 | Returns the address of the current content of buffer B (see luaL_Buffer). Not... |
| `luaL_buffinit` | `void luaL_buffinit (lua_State *L, luaL_Buffer *B);` | [0, +?] | - | ? | Initializes a buffer B (see luaL_Buffer). This function does not allocate any... |
| `luaL_buffinitsize` | `char *luaL_buffinitsize (lua_State *L, luaL_Buffer *B, size_t sz);` | [?, +?] | m | ? | Equivalent to the sequence luaL_buffinit, luaL_prepbuffsize. |
| `luaL_bufflen` | `size_t luaL_bufflen (luaL_Buffer *B);` | [0, +0] | - | 0 | Returns the length of the current content of buffer B (see luaL_Buffer). |
| `luaL_buffsub` | `void luaL_buffsub (luaL_Buffer *B, int n);` | [?, +?] | - | ? | Removes n bytes from the buffer B (see luaL_Buffer). The buffer must have at ... |
| `luaL_callmeta` | `int luaL_callmeta (lua_State *L, int obj, const char *e);` | [0, +(0|1)] | e | +(0|1) -0 | Calls a metamethod. > If the object at index obj has a metatable and this met... |
| `luaL_checkany` | `void luaL_checkany (lua_State *L, int arg);` | [0, +0] | v | 0 | Checks whether the function has an argument of any type (including nil) at po... |
| `luaL_checkinteger` | `lua_Integer luaL_checkinteger (lua_State *L, int arg);` | [0, +0] | v | 0 | Checks whether the function argument arg is an integer (or can be converted t... |
| `luaL_checklstring` | `const char *luaL_checklstring (lua_State *L, int arg, size_t *l);` | [0, +0] | v | 0 | Checks whether the function argument arg is a string and returns this string;... |
| `luaL_checknumber` | `lua_Number luaL_checknumber (lua_State *L, int arg);` | [0, +0] | v | 0 | Checks whether the function argument arg is a number and returns this number ... |
| `luaL_checkoption` | `int luaL_checkoption (lua_State *L, int arg, const char *def, const char *const lst[]);` | [0, +0] | v | 0 | Checks whether the function argument arg is a string and searches for this st... |
| `luaL_checkstack` | `void luaL_checkstack (lua_State *L, int sz, const char *msg);` | [0, +0] | v | 0 | Grows the stack size to top + sz elements, raising an error if the stack cann... |
| `luaL_checkstring` | `const char *luaL_checkstring (lua_State *L, int arg);` | [0, +0] | v | 0 | Checks whether the function argument arg is a string and returns this string.... |
| `luaL_checktype` | `void luaL_checktype (lua_State *L, int arg, int t);` | [0, +0] | v | 0 | Checks whether the function argument arg has type t. See lua_type for the enc... |
| `luaL_checkudata` | `void *luaL_checkudata (lua_State *L, int arg, const char *tname);` | [0, +0] | v | 0 | Checks whether the function argument arg is a userdata of the type tname (see... |
| `luaL_checkversion` | `void luaL_checkversion (lua_State *L);` | [0, +0] | v | 0 | Checks whether the code making the call and the Lua library being called are ... |
| `luaL_dofile` | `int luaL_dofile (lua_State *L, const char *filename);` | [0, +?] | m | ? | Loads and runs the given file. It is defined as the following macro: re> (lua... |
| `luaL_dostring` | `int luaL_dostring (lua_State *L, const char *str);` | [0, +?] | - | ? | Loads and runs the given string. It is defined as the following macro: re> (l... |
| `luaL_error` | `int luaL_error (lua_State *L, const char *fmt, ...);` | [0, +0] | v | 0 | Raises an error. The error message format is given by fmt plus any extra argu... |
| `luaL_execresult` | `int luaL_execresult (lua_State *L, int stat);` | [0, +3] | m | +3 | This function produces the return values for process-related functions in the... |
| `luaL_fileresult` | `int luaL_fileresult (lua_State *L, int stat, const char *fname);` | [0, +(1|3)] | m | +(1|3) -0 | This function produces the return values for file-related functions in the st... |
| `luaL_getmetafield` | `int luaL_getmetafield (lua_State *L, int obj, const char *e);` | [0, +(0|1)] | m | +(0|1) -0 | Pushes onto the stack the field e from the metatable of the object at index o... |
| `luaL_getmetatable` | `int luaL_getmetatable (lua_State *L, const char *tname);` | [0, +1] | m | +1 | Pushes onto the stack the metatable associated with the name tname in the reg... |
| `luaL_getsubtable` | `int luaL_getsubtable (lua_State *L, int idx, const char *fname);` | [0, +1] | e | +1 | Ensures that the value t[fname], where t is the value at index idx, is a tabl... |
| `luaL_gsub` | `const char *luaL_gsub (lua_State *L, const char *s, const char *p, const char *r);` | [0, +1] | m | +1 | Creates a copy of string s, replacing any occurrence of the string p with the... |
| `luaL_len` | `lua_Integer luaL_len (lua_State *L, int index);` | [0, +0] | e | 0 | Returns the "length" of the value at the given index as a number; it is equiv... |
| `luaL_loadbuffer` | `int luaL_loadbuffer (lua_State *L, const char *buff, size_t sz, const char *name);` | [0, +1] | - | +1 | Equivalent to luaL_loadbufferx with mode equal to NULL. |
| `luaL_loadbufferx` | `int luaL_loadbufferx (lua_State *L, const char *buff, size_t sz, const char *name, const char *mode);` | [0, +1] | - | +1 | Loads a buffer as a Lua chunk. This function uses lua_load to load the chunk ... |
| `luaL_loadfile` | `int luaL_loadfile (lua_State *L, const char *filename);` | [0, +1] | m | +1 | Equivalent to luaL_loadfilex with mode equal to NULL. |
| `luaL_loadfilex` | `int luaL_loadfilex (lua_State *L, const char *filename, const char *mode);` | [0, +1] | m | +1 | Loads a file as a Lua chunk. This function uses lua_load to load the chunk in... |
| `luaL_loadstring` | `int luaL_loadstring (lua_State *L, const char *s);` | [0, +1] | - | +1 | Loads a string as a Lua chunk. This function uses lua_load to load the chunk ... |
| `luaL_makeseed` | `unsigned int luaL_makeseed (lua_State *L);` | [0, +0] | - | 0 | Returns a value with a weak attempt for randomness. The parameter L can be NU... |
| `luaL_newlib` | `void luaL_newlib (lua_State *L, const luaL_Reg l[]);` | [0, +1] | m | +1 | Creates a new table and registers there the functions in the list l. > It is ... |
| `luaL_newlibtable` | `void luaL_newlibtable (lua_State *L, const luaL_Reg l[]);` | [0, +1] | m | +1 | Creates a new table with a size optimized to store all entries in the array l... |
| `luaL_newmetatable` | `int luaL_newmetatable (lua_State *L, const char *tname);` | [0, +1] | m | +1 | If the registry already has the key tname, returns 0. Otherwise, creates a ne... |
| `luaL_newstate` | `lua_State *luaL_newstate (void);` | [0, +0] | - | 0 | Creates a new Lua state. It calls lua_newstate with luaL_alloc as the allocat... |
| `luaL_openlibs` | `void luaL_openlibs (lua_State *L);` | [0, +0] | e | 0 | Opens all standard Lua libraries into the given state. |
| `luaL_openselectedlibs` | `void luaL_openselectedlibs (lua_State *L, int load, int preload);` | [0, +0] | e | 0 | Opens (loads) and preloads selected standard libraries into the state L. (To ... |
| `luaL_opt` | `T luaL_opt (L, func, arg, dflt);` | [0, +0] | - | 0 | This macro is defined as follows: re> (lua_isnoneornil(L,(arg)) ? (dflt) : fu... |
| `luaL_optinteger` | `lua_Integer luaL_optinteger (lua_State *L, int arg, lua_Integer d);` | [0, +0] | v | 0 | If the function argument arg is an integer (or it is convertible to an intege... |
| `luaL_optlstring` | `const char *luaL_optlstring (lua_State *L, int arg, const char *d, size_t *l);` | [0, +0] | v | 0 | If the function argument arg is a string, returns this string. If this argume... |
| `luaL_optnumber` | `lua_Number luaL_optnumber (lua_State *L, int arg, lua_Number d);` | [0, +0] | v | 0 | If the function argument arg is a number, returns this number as a lua_Number... |
| `luaL_optstring` | `const char *luaL_optstring (lua_State *L, int arg, const char *d);` | [0, +0] | v | 0 | If the function argument arg is a string, returns this string. If this argume... |
| `luaL_prepbuffer` | `char *luaL_prepbuffer (luaL_Buffer *B);` | [?, +?] | m | ? | Equivalent to luaL_prepbuffsize with the predefined size LUAL_BUFFERSIZE. |
| `luaL_prepbuffsize` | `char *luaL_prepbuffsize (luaL_Buffer *B, size_t sz);` | [?, +?] | m | ? | Returns an address to a space of size sz where you can copy a string to be ad... |
| `luaL_pushfail` | `void luaL_pushfail (lua_State *L);` | [0, +1] | - | +1 | Pushes the fail value onto the stack (see &sect;6). |
| `luaL_pushresult` | `void luaL_pushresult (luaL_Buffer *B);` | [?, +1] | m | ? | Finishes the use of buffer B leaving the final string on the top of the stack. |
| `luaL_pushresultsize` | `void luaL_pushresultsize (luaL_Buffer *B, size_t sz);` | [?, +1] | m | ? | Equivalent to the sequence luaL_addsize, luaL_pushresult. |
| `luaL_ref` | `int luaL_ref (lua_State *L, int t);` | [1, +0] | m | -1 | Creates and returns a reference, in the table at index t, for the object on t... |
| `luaL_requiref` | `void luaL_requiref (lua_State *L, const char *modname, lua_CFunction openf, int glb);` | [0, +1] | e | +1 | If package.loaded[modname] is not true, calls the function openf with the str... |
| `luaL_setfuncs` | `void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup);` | [nup, +0] | m | +0 -nup | Registers all functions in the array l (see luaL_Reg) into the table on the t... |
| `luaL_setmetatable` | `void luaL_setmetatable (lua_State *L, const char *tname);` | [0, +0] | - | 0 | Sets the metatable of the object on the top of the stack as the metatable ass... |
| `luaL_testudata` | `void *luaL_testudata (lua_State *L, int arg, const char *tname);` | [0, +0] | m | 0 | This function works like luaL_checkudata, except that, when the test fails, i... |
| `luaL_tolstring` | `const char *luaL_tolstring (lua_State *L, int idx, size_t *len);` | [0, +1] | e | +1 | Converts any Lua value at the given index to a C string in a reasonable forma... |
| `luaL_traceback` | `void luaL_traceback (lua_State *L, lua_State *L1, const char *msg, int level);` | [0, +1] | m | +1 | Creates and pushes a traceback of the stack L1. If msg is not NULL, it is app... |
| `luaL_typeerror` | `int luaL_typeerror (lua_State *L, int arg, const char *tname);` | [0, +0] | v | 0 | Raises a type error for the argument arg of the C function that called it, us... |
| `luaL_typename` | `const char *luaL_typename (lua_State *L, int index);` | [0, +0] | - | 0 | Returns the name of the type of the value at the given index. |
| `luaL_unref` | `void luaL_unref (lua_State *L, int t, int ref);` | [0, +0] | - | 0 | Releases a reference (see luaL_ref). The integer ref must be either LUA_NOREF... |
| `luaL_where` | `void luaL_where (lua_State *L, int lvl);` | [0, +1] | m | +1 | Pushes onto the stack a string identifying the current position of the contro... |

---

## 按功能分类

### 堆栈操作函数

- **`lua_gettop`**: Returns the index of the top element in the stack. Because indices start at 1, this result is equal to the number of elements in the stack; in particular, 0 means an empty stack.
- **`lua_settop`**: Receives any acceptable stack index, or 0, and sets the stack top to this index. If the new top is greater than the old one, then the new elements are filled with nil. If index is 0, then all stack elements are removed. > This function can run arbitrary code when removing an index marked as to-be-closed from the stack.
- **`lua_pop`**: Pops n elements from the stack. It is implemented as a macro over lua_settop.
- **`lua_pushvalue`**: Pushes a copy of the element at the given index onto the stack.
- **`lua_remove`**: Removes the element at the given valid index, shifting down the elements above this index to fill the gap. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
- **`lua_insert`**: Moves the top element into the given valid index, shifting up the elements above this index to open space. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
- **`lua_replace`**: Moves the top element into the given valid index without shifting any element (therefore replacing the value at that given index), and then pops the top element.
- **`lua_copy`**: Copies the element at index fromidx into the valid index toidx, replacing the value at that position. Values at other positions are not affected.
- **`lua_checkstack`**: Ensures that the stack has space for at least n extra elements, that is, that you can safely push up to n values into it. It returns false if it cannot fulfill the request, either because it would cause the stack to be greater than a fixed maximum size (typically at least several thousand elements) or because it cannot allocate memory for the extra space. This function never shrinks the stack; if the stack already has space for the extra elements, it is left unchanged.
- **`lua_xmove`**: Exchange values between different threads of the same state. > This function pops n values from the stack from, and pushes them onto the stack to.
- **`lua_rotate`**: Rotates the stack elements between the valid index idx and the top of the stack. The elements are rotated n positions in the direction of the top, for a positive n, or -n positions in the direction of the bottom, for a negative n. The absolute value of n must not be greater than the size of the slice being rotated. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
- **`lua_closeslot`**: Close the to-be-closed slot at the given index and set its value to nil. The index must be the last index previously marked to be closed (see lua_toclose) that is still active (that is, not closed yet). > A __close metamethod cannot yield when called through this function.

### Push 函数（将值压入堆栈）

- **`lua_pushboolean`**: [0, +1] - Pushes a boolean value with value b onto the stack.
- **`lua_pushcclosure`**: [n, +1] - Pushes a new C closure onto the stack. This function receives a pointer to a C function and pushes onto the stack a Lua value of type function that, when called, invokes the corresponding C function. The parameter n tells how many upvalues this function will have (see &sect;4.2). > Any function to be callable by Lua must follow the correct protocol to receive its parameters and return its results (see lua_CFunction). > When a C function is created, it is possible to associate some values with...
- **`lua_pushcfunction`**: [0, +1] - Pushes a C function onto the stack. This function is equivalent to lua_pushcclosure with no upvalues.
- **`lua_pushexternalstring`**: [0, +1] - Creates an external string, that is, a string that uses memory not managed by Lua. The pointer s points to the external buffer holding the string content, and len is the length of the string. The string should have a zero at its end, that is, the condition s[len] == '\0' should hold. As with any string in Lua, the length must fit in a Lua integer. > If falloc is different from NULL, that function will be called by Lua when the external buffer is no longer needed. The contents of the buffer sh...
- **`lua_pushfstring`**: [0, +1] - Pushes onto the stack a formatted string and returns a pointer to this string (see &sect;4.1.3). The result is a copy of fmt with each conversion specifier replaced by a string representation of its respective extra argument. A conversion specifier (and its corresponding extra argument) can be '%%' (inserts the character '%'), '%s' (inserts a zero-terminated string, with no size restrictions), '%f' (inserts a lua_Number), '%I' (inserts a lua_Integer), '%p' (inserts a void pointer), '%d' (inse...
- **`lua_pushglobaltable`**: [0, +1] - Pushes the global environment onto the stack.
- **`lua_pushinteger`**: [0, +1] - Pushes an integer with value n onto the stack.
- **`lua_pushlightuserdata`**: [0, +1] - Pushes a light userdata onto the stack. > Userdata represent C values in Lua. A light userdata represents a pointer, a void*. It is a value (like a number): you do not create it, it has no individual metatable, and it is not collected (as it was never created). A light userdata is equal to "any" light userdata with the same C address.
- **`lua_pushliteral`**: [0, +1] - This macro is equivalent to lua_pushstring, but should be used only when s is a literal string. (Lua may optimize this case.)
- **`lua_pushlstring`**: [0, +1] - Pushes the string pointed to by s with size len onto the stack. Lua will make or reuse an internal copy of the given string, so the memory at s can be freed or reused immediately after the function returns. The string can contain any binary data, including embedded zeros. > Returns a pointer to the internal copy of the string (see &sect;4.1.3). > Besides memory allocation errors, this function may raise an error if the string is too large.
- **`lua_pushnil`**: [0, +1] - Pushes a nil value onto the stack.
- **`lua_pushnumber`**: [0, +1] - Pushes a float with value n onto the stack.
- **`lua_pushstring`**: [0, +1] - Pushes the zero-terminated string pointed to by s onto the stack. Lua will make or reuse an internal copy of the given string, so the memory at s can be freed or reused immediately after the function returns. > Returns a pointer to the internal copy of the string (see &sect;4.1.3). > If s is NULL, pushes nil and returns NULL.
- **`lua_pushthread`**: [0, +1] - Pushes the thread represented by L onto the stack. Returns 1 if this thread is the main thread of its state.
- **`lua_pushvalue`**: [0, +1] - Pushes a copy of the element at the given index onto the stack.
- **`lua_pushvfstring`**: [0, +1] - Equivalent to lua_pushfstring, except that it receives a va_list instead of a variable number of arguments, and it does not raise errors. Instead, in case of errors it pushes the error message and returns NULL.

### Get 函数（获取但不弹出）

- **`lua_getfield`**: [0, +1] - Pushes onto the stack the value t[k], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see &sect;2.4). > Returns the type of the pushed value.
- **`lua_getglobal`**: [0, +1] - Pushes onto the stack the value of the global name. Returns the type of that value.
- **`lua_geti`**: [0, +1] - Pushes onto the stack the value t[i], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see &sect;2.4). > Returns the type of the pushed value.
- **`lua_getlocal`**: [0, +(0|1)] - Gets information about a local variable or a temporary value of a given activation record or a given function. > In the first case, the parameter ar must be a valid activation record that was filled by a previous call to lua_getstack or given as argument to a hook (see lua_Hook). The index n selects which local variable to inspect; see debug.getlocal for details about variable indices and names. > lua_getlocal pushes the variable's value onto the stack and returns its name. > In the second ca...
- **`lua_getmetatable`**: [0, +(0|1)] - If the value at the given index has a metatable, the function pushes that metatable onto the stack and returns 1. Otherwise, the function returns 0 and pushes nothing on the stack.
- **`lua_gettable`**: [1, +1] - Pushes onto the stack the value t[k], where t is the value at the given index and k is the value on the top of the stack. > This function pops the key from the stack, pushing the resulting value in its place. As in Lua, this function may trigger a metamethod for the "index" event (see &sect;2.4). > Returns the type of the pushed value.
- **`lua_getupvalue`**: [0, +(0|1)] - Gets information about the n-th upvalue of the closure at index funcindex. It pushes the upvalue's value onto the stack and returns its name. Returns NULL (and pushes nothing) when the index n is greater than the number of upvalues. > See debug.getupvalue for more information about upvalues.

### Set 函数（设置并弹出）

- **`lua_setfield`**: [1, +0] - Does the equivalent to t[k] = v, where t is the value at the given index and v is the value on the top of the stack. > This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see &sect;2.4).
- **`lua_setglobal`**: [1, +0] - Pops a value from the stack and sets it as the new value of global name.
- **`lua_seti`**: [1, +0] - Does the equivalent to t[n] = v, where t is the value at the given index and v is the value on the top of the stack. > This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see &sect;2.4).
- **`lua_setiuservalue`**: [1, +0] - Pops a value from the stack and sets it as the new n-th user value associated to the full userdata at the given index. Returns 0 if the userdata does not have that value.
- **`lua_setlocal`**: [(0|1), +0] - Sets the value of a local variable of a given activation record. It assigns the value on the top of the stack to the variable and returns its name. It also pops the value from the stack. > Returns NULL (and pops nothing) when the index is greater than the number of active local variables. > Parameters ar and n are as in the function lua_getlocal.
- **`lua_setmetatable`**: [1, +0] - Pops a table or nil from the stack and sets that value as the new metatable for the value at the given index. (nil means no metatable.) > (For historical reasons, this function returns an int, which now is always 1.)
- **`lua_settable`**: [2, +0] - Does the equivalent to t[k] = v, where t is the value at the given index, v is the value on the top of the stack, and k is the value just below the top. > This function pops both the key and the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see &sect;2.4).
- **`lua_settop`**: [?, +?] - Receives any acceptable stack index, or 0, and sets the stack top to this index. If the new top is greater than the old one, then the new elements are filled with nil. If index is 0, then all stack elements are removed. > This function can run arbitrary code when removing an index marked as to-be-closed from the stack.
- **`lua_setupvalue`**: [(0|1), +0] - Sets the value of a closure's upvalue. It assigns the value on the top of the stack to the upvalue and returns its name. It also pops the value from the stack. > Returns NULL (and pops nothing) when the index n is greater than the number of upvalues. > Parameters funcindex and n are as in the function lua_getupvalue.

### 类型检查函数 (Is 系列)

- **`lua_isboolean`**: Returns 1 if the value at the given index is a boolean, and 0 otherwise.
- **`lua_iscfunction`**: Returns 1 if the value at the given index is a C function, and 0 otherwise.
- **`lua_isfunction`**: Returns 1 if the value at the given index is a function (either C or Lua), and 0 otherwise.
- **`lua_isinteger`**: Returns 1 if the value at the given index is an integer (that is, the value is a number and is represented as an integer), and 0 otherwise.
- **`lua_islightuserdata`**: Returns 1 if the value at the given index is a light userdata, and 0 otherwise.
- **`lua_isnil`**: Returns 1 if the value at the given index is nil, and 0 otherwise.
- **`lua_isnone`**: Returns 1 if the given index is not valid, and 0 otherwise.
- **`lua_isnoneornil`**: Returns 1 if the given index is not valid or if the value at this index is nil, and 0 otherwise.
- **`lua_isnumber`**: Returns 1 if the value at the given index is a number or a string convertible to a number, and 0 otherwise.
- **`lua_isstring`**: Returns 1 if the value at the given index is a string or a number (which is always convertible to a string), and 0 otherwise.
- **`lua_istable`**: Returns 1 if the value at the given index is a table, and 0 otherwise.
- **`lua_isthread`**: Returns 1 if the value at the given index is a thread, and 0 otherwise.
- **`lua_isuserdata`**: Returns 1 if the value at the given index is a userdata (either full or light), and 0 otherwise.
- **`lua_isyieldable`**: Returns 1 if the given coroutine can yield, and 0 otherwise.

### 类型转换函数 (To 系列)

- **`lua_toboolean`**: Converts the Lua value at the given index to a C boolean value (0 or 1). Like all tests in Lua, lua_toboolean returns true for any Lua value different from false and nil; otherwise it returns false. (If you want to accept only actual boolean values, use lua_isboolean to test the value's type.)
- **`lua_tocfunction`**: Converts a value at the given index to a C function. That value must be a C function; otherwise, returns NULL.
- **`lua_toclose`**: Marks the given index in the stack as a to-be-closed slot (see &sect;3.3.8). Like a to-be-closed variable in Lua, the value at that slot in the stack will be closed when it goes out of scope. Here, in the context of a C function, to go out of scope means that the running function returns to Lua, or there is an error, or the slot is removed from the stack through lua_settop or lua_pop, or there is a call to lua_closeslot. A slot marked as to-be-closed should not be removed from the stack by an...
- **`lua_tointeger`**: Equivalent to lua_tointegerx with isnum equal to NULL.
- **`lua_tointegerx`**: Converts the Lua value at the given index to the signed integral type lua_Integer. The Lua value must be an integer, or a number or string convertible to an integer (see &sect;3.4.3); otherwise, lua_tointegerx returns 0. > If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.
- **`lua_tolstring`**: Converts the Lua value at the given index to a C string. The Lua value must be a string or a number; otherwise, the function returns NULL. If the value is a number, then lua_tolstring also changes the actual value in the stack to a string. (This change confuses lua_next when lua_tolstring is applied to keys during a table traversal.) > If len is not NULL, the function sets *len with the string length. The returned C string always has a zero ('\0') after its last character, but can contain oth...
- **`lua_tonumber`**: Equivalent to lua_tonumberx with isnum equal to NULL.
- **`lua_tonumberx`**: Converts the Lua value at the given index to the C type lua_Number (see lua_Number). The Lua value must be a number or a string convertible to a number (see &sect;3.4.3); otherwise, lua_tonumberx returns 0. > If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.
- **`lua_topointer`**: Converts the value at the given index to a generic C pointer (void*). The value can be a userdata, a table, a thread, a string, or a function; otherwise, lua_topointer returns NULL. Different objects will give different pointers. There is no way to convert the pointer back to its original value. > Typically this function is used only for hashing and debug information.
- **`lua_tostring`**: Equivalent to lua_tolstring with len equal to NULL.
- **`lua_tothread`**: Converts the value at the given index to a Lua thread (represented as lua_State*). This value must be a thread; otherwise, the function returns NULL.
- **`lua_touserdata`**: If the value at the given index is a full userdata, returns its memory-block address. If the value is a light userdata, returns its value (a pointer). Otherwise, returns NULL.

---

## 完整 API 详细描述

### C API

#### `lua_absindex`

```c
int lua_absindex (lua_State *L, int idx);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the acceptable index idx into an equivalent absolute index (that is, one that does not depend on the stack size).

#### `lua_arith`

```c
void lua_arith (lua_State *L, int op);
```

- **堆栈弹出**: (2|1)
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Performs an arithmetic or bitwise operation over the two values (or one, in the case of negations) at the top of the stack, with the value on the top being the second operand, pops these values, and pushes the result of the operation. The function follows the semantics of the corresponding Lua operator (that is, it may call metamethods). > The value of op must be one of the following constants: l> i>LUA_OPADD: performs addition (+)li> i>LUA_OPSUB: performs subtraction (-)li> i>LUA_OPMUL: perf...

#### `lua_atpanic`

```c
lua_CFunction lua_atpanic (lua_State *L, lua_CFunction panicf);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Sets a new panic function and returns the old one (see &sect;4.4).

#### `lua_call`

```c
void lua_call (lua_State *L, int nargs, int nresults);
```

- **堆栈弹出**: (nargs+1)
- **堆栈压入**: nresults
- **错误标志**: e
- **描述**: Calls a function. Like regular Lua calls, lua_call respects the __call metamethod. So, here the word "function" means any callable value. > To do a call you must use the following protocol: first, the function to be called is pushed onto the stack; then, the arguments to the call are pushed in direct order; that is, the first argument is pushed first. Finally you call lua_call; nargs is the number of arguments that you pushed onto the stack. When the function returns, all arguments and the fu...

#### `lua_callk`

```c
void lua_callk (lua_State *L, int nargs, int nresults, lua_KContext ctx, lua_KFunction k);
```

- **堆栈弹出**: (nargs + 1)
- **堆栈压入**: nresults
- **错误标志**: e
- **描述**: This function behaves exactly like lua_call, but allows the called function to yield (see &sect;4.5).

#### `lua_checkstack`

```c
int lua_checkstack (lua_State *L, int n);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Ensures that the stack has space for at least n extra elements, that is, that you can safely push up to n values into it. It returns false if it cannot fulfill the request, either because it would cause the stack to be greater than a fixed maximum size (typically at least several thousand elements) or because it cannot allocate memory for the extra space. This function never shrinks the stack; if the stack already has space for the extra elements, it is left unchanged.

#### `lua_close`

```c
void lua_close (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Close all active to-be-closed variables in the main thread, release all objects in the given Lua state (calling the corresponding garbage-collection metamethods, if any), and frees all dynamic memory used by this state. > On several platforms, you may not need to call this function, because all resources are naturally released when the host program ends. On the other hand, long-running programs that create multiple states, such as daemons or web servers, will probably need to close states as ...

#### `lua_closeslot`

```c
void lua_closeslot (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Close the to-be-closed slot at the given index and set its value to nil. The index must be the last index previously marked to be closed (see lua_toclose) that is still active (that is, not closed yet). > A __close metamethod cannot yield when called through this function.

#### `lua_closethread`

```c
int lua_closethread (lua_State *L, lua_State *from);
```

- **堆栈弹出**: 0
- **堆栈压入**: ?
- **错误标志**: -
- **描述**: Resets a thread, cleaning its call stack and closing all pending to-be-closed variables. The parameter from represents the coroutine that is resetting L. If there is no such coroutine, this parameter can be NULL. > Unless L is equal to from, the call returns a status code: LUA_OK for no errors in the thread (either the original error that stopped the thread or errors in closing methods), or an error status otherwise. In case of error, the error object is put on the top of the stack. > If L is...

#### `lua_compare`

```c
int lua_compare (lua_State *L, int index1, int index2, int op);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Compares two Lua values. Returns 1 if the value at index index1 satisfies op when compared with the value at index index2, following the semantics of the corresponding Lua operator (that is, it may call metamethods). Otherwise returns 0. Also returns 0 if any of the indices is not valid. > The value of op must be one of the following constants: l> i>LUA_OPEQ: compares for equality (==)li> i>LUA_OPLT: compares for less than (li> i>LUA_OPLE: compares for less or equal ()li> ul>

#### `lua_concat`

```c
void lua_concat (lua_State *L, int n);
```

- **堆栈弹出**: n
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Concatenates the n values at the top of the stack, pops them, and leaves the result on the top. If n is 1, the result is the single value on the stack (that is, the function does nothing); if n is 0, the result is the empty string. Concatenation is performed following the usual semantics of Lua (see &sect;3.4.6).

#### `lua_copy`

```c
void lua_copy (lua_State *L, int fromidx, int toidx);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Copies the element at index fromidx into the valid index toidx, replacing the value at that position. Values at other positions are not affected.

#### `lua_createtable`

```c
void lua_createtable (lua_State *L, int nseq, int nrec);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates a new empty table and pushes it onto the stack. Parameter nseq is a hint for how many elements the table will have as a sequence; parameter nrec is a hint for how many other elements the table will have. Lua may use these hints to preallocate memory for the new table. This preallocation may help performance when you know in advance how many elements the table will have. Otherwise you should use the function lua_newtable.

#### `lua_dump`

```c
int lua_dump (lua_State *L, lua_Writer writer, void *data, int strip);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Dumps a function as a binary chunk. Receives a Lua function on the top of the stack and produces a binary chunk that, if loaded again, results in a function equivalent to the one dumped. As it produces parts of the chunk, lua_dump calls function writer (see lua_Writer) with the given data to write them. > The function lua_dump fully preserves the Lua stack through the calls to the writer function, except that it may push some values for internal use before the first call, and it restores the ...

#### `lua_error`

```c
int lua_error (lua_State *L);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Raises a Lua error, using the value on the top of the stack as the error object. This function does a long jump, and therefore never returns (see luaL_error).

#### `lua_gc`

```c
int lua_gc (lua_State *L, int what, ...);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Controls the garbage collector. > This function performs several tasks, according to the value of the parameter what. For options that need extra arguments, they are listed after the option. l> i>LUA_GCCOLLECT: Performs a full garbage-collection cycle. li> i>LUA_GCSTOP: Stops the garbage collector. li> i>LUA_GCRESTART: Restarts the garbage collector. li> i>LUA_GCCOUNT: Returns the current amount of memory (in Kbytes) in use by Lua. li> i>LUA_GCCOUNTB: Returns the remainder of dividing the cur...

#### `lua_getallocf`

```c
lua_Alloc lua_getallocf (lua_State *L, void **ud);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the memory-allocator function of a given state. If ud is not NULL, Lua stores in *ud the opaque pointer given when the memory-allocator function was set.

#### `lua_getextraspace`

```c
void *lua_getextraspace (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns a pointer to a raw memory area associated with the given Lua state. The application can use this area for any purpose; Lua does not use it for anything. > Each new thread has this area initialized with a copy of the area of the main thread. > By default, this area has the size of a pointer to void, but you can recompile Lua with a different size for this area. (See LUA_EXTRASPACE in luaconf.h.)

#### `lua_getfield`

```c
int lua_getfield (lua_State *L, int index, const char *k);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Pushes onto the stack the value t[k], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see &sect;2.4). > Returns the type of the pushed value.

#### `lua_getglobal`

```c
int lua_getglobal (lua_State *L, const char *name);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Pushes onto the stack the value of the global name. Returns the type of that value.

#### `lua_gethook`

```c
lua_Hook lua_gethook (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the current hook function.

#### `lua_gethookcount`

```c
int lua_gethookcount (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the current hook count.

#### `lua_gethookmask`

```c
int lua_gethookmask (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the current hook mask.

#### `lua_geti`

```c
int lua_geti (lua_State *L, int index, lua_Integer i);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Pushes onto the stack the value t[i], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see &sect;2.4). > Returns the type of the pushed value.

#### `lua_getinfo`

```c
int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
```

- **堆栈弹出**: (0|1)
- **堆栈压入**: (0|1|2)
- **错误标志**: m
- **描述**: Gets information about a specific function or function invocation. > To get information about a function invocation, the parameter ar must be a valid activation record that was filled by a previous call to lua_getstack or given as argument to a hook (see lua_Hook). > To get information about a function, you push it onto the stack and start the what string with the character '>'. (In that case, lua_getinfo pops the function from the top of the stack.) For instance, to know in which line a func...

#### `lua_getiuservalue`

```c
int lua_getiuservalue (lua_State *L, int index, int n);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes onto the stack the n-th user value associated with the full userdata at the given index and returns the type of the pushed value. > If the userdata does not have that value, pushes nil and returns LUA_TNONE.

#### `lua_getlocal`

```c
const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
```

- **堆栈弹出**: 0
- **堆栈压入**: (0|1)
- **错误标志**: -
- **描述**: Gets information about a local variable or a temporary value of a given activation record or a given function. > In the first case, the parameter ar must be a valid activation record that was filled by a previous call to lua_getstack or given as argument to a hook (see lua_Hook). The index n selects which local variable to inspect; see debug.getlocal for details about variable indices and names. > lua_getlocal pushes the variable's value onto the stack and returns its name. > In the second ca...

#### `lua_getmetatable`

```c
int lua_getmetatable (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: (0|1)
- **错误标志**: -
- **描述**: If the value at the given index has a metatable, the function pushes that metatable onto the stack and returns 1. Otherwise, the function returns 0 and pushes nothing on the stack.

#### `lua_getstack`

```c
int lua_getstack (lua_State *L, int level, lua_Debug *ar);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Gets information about the interpreter runtime stack. > This function fills parts of a lua_Debug structure with an identification of the activation record of the function executing at a given level. Level 0 is the current running function, whereas level n+1 is the function that has called level n (except for tail calls, which do not count in the stack). When called with a level greater than the stack depth, lua_getstack returns 0; otherwise it returns 1.

#### `lua_gettable`

```c
int lua_gettable (lua_State *L, int index);
```

- **堆栈弹出**: 1
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Pushes onto the stack the value t[k], where t is the value at the given index and k is the value on the top of the stack. > This function pops the key from the stack, pushing the resulting value in its place. As in Lua, this function may trigger a metamethod for the "index" event (see &sect;2.4). > Returns the type of the pushed value.

#### `lua_gettop`

```c
int lua_gettop (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the index of the top element in the stack. Because indices start at 1, this result is equal to the number of elements in the stack; in particular, 0 means an empty stack.

#### `lua_getupvalue`

```c
const char *lua_getupvalue (lua_State *L, int funcindex, int n);
```

- **堆栈弹出**: 0
- **堆栈压入**: (0|1)
- **错误标志**: -
- **描述**: Gets information about the n-th upvalue of the closure at index funcindex. It pushes the upvalue's value onto the stack and returns its name. Returns NULL (and pushes nothing) when the index n is greater than the number of upvalues. > See debug.getupvalue for more information about upvalues.

#### `lua_insert`

```c
void lua_insert (lua_State *L, int index);
```

- **堆栈弹出**: 1
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Moves the top element into the given valid index, shifting up the elements above this index to open space. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.

#### `lua_isboolean`

```c
int lua_isboolean (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a boolean, and 0 otherwise.

#### `lua_iscfunction`

```c
int lua_iscfunction (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a C function, and 0 otherwise.

#### `lua_isfunction`

```c
int lua_isfunction (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a function (either C or Lua), and 0 otherwise.

#### `lua_isinteger`

```c
int lua_isinteger (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is an integer (that is, the value is a number and is represented as an integer), and 0 otherwise.

#### `lua_islightuserdata`

```c
int lua_islightuserdata (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a light userdata, and 0 otherwise.

#### `lua_isnil`

```c
int lua_isnil (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is nil, and 0 otherwise.

#### `lua_isnone`

```c
int lua_isnone (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the given index is not valid, and 0 otherwise.

#### `lua_isnoneornil`

```c
int lua_isnoneornil (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the given index is not valid or if the value at this index is nil, and 0 otherwise.

#### `lua_isnumber`

```c
int lua_isnumber (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a number or a string convertible to a number, and 0 otherwise.

#### `lua_isstring`

```c
int lua_isstring (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a string or a number (which is always convertible to a string), and 0 otherwise.

#### `lua_istable`

```c
int lua_istable (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a table, and 0 otherwise.

#### `lua_isthread`

```c
int lua_isthread (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a thread, and 0 otherwise.

#### `lua_isuserdata`

```c
int lua_isuserdata (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the value at the given index is a userdata (either full or light), and 0 otherwise.

#### `lua_isyieldable`

```c
int lua_isyieldable (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the given coroutine can yield, and 0 otherwise.

#### `lua_len`

```c
void lua_len (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Returns the length of the value at the given index. It is equivalent to the '#' operator in Lua (see &sect;3.4.7) and may trigger a metamethod for the "length" event (see &sect;2.4). The result is pushed on the stack.

#### `lua_load`

```c
int lua_load (lua_State *L, lua_Reader reader, void *data, const char *chunkname, const char *mode);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Loads a Lua chunk without running it. If there are no errors, lua_load pushes the compiled chunk as a Lua function on top of the stack. Otherwise, it pushes an error message. > The lua_load function uses a user-supplied reader function to read the chunk (see lua_Reader). The data argument is an opaque value passed to the reader function. > The chunkname argument gives a name to the chunk, which is used for error messages and in debug information (see &sect;4.7). > lua_load automatically detec...

#### `lua_newstate`

```c
lua_State *lua_newstate (lua_Alloc f, void *ud, unsigned int seed);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Creates a new independent state and returns its main thread. Returns NULL if it cannot create the state (due to lack of memory). The argument f is the allocator function; Lua will do all memory allocation for this state through this function (see lua_Alloc). The second argument, ud, is an opaque pointer that Lua passes to the allocator in every call. The third argument, seed, is a seed for the hashing of strings.

#### `lua_newtable`

```c
void lua_newtable (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates a new empty table and pushes it onto the stack. It is equivalent to lua_createtable(L,0,0).

#### `lua_newthread`

```c
lua_State *lua_newthread (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates a new thread, pushes it on the stack, and returns a pointer to a lua_State that represents this new thread. The new thread returned by this function shares with the original thread its global environment, but has an independent execution stack. > Threads are subject to garbage collection, like any Lua object.

#### `lua_newuserdatauv`

```c
void *lua_newuserdatauv (lua_State *L, size_t size, int nuvalue);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: This function creates and pushes on the stack a new full userdata, with nuvalue associated Lua values, called user values, plus an associated block of raw memory with size bytes. (The user values can be set and read with the functions lua_setiuservalue and lua_getiuservalue.) > The function returns the address of the block of memory. Lua ensures that this address is valid as long as the corresponding userdata is alive (see &sect;2.5). Moreover, if the userdata is marked for finalization (see ...

#### `lua_next`

```c
int lua_next (lua_State *L, int index);
```

- **堆栈弹出**: 1
- **堆栈压入**: (2|0)
- **错误标志**: v
- **描述**: Pops a key from the stack, and pushes a key–value pair from the table at the given index, the "next" pair after the given key. If there are no more elements in the table, then lua_next returns 0 and pushes nothing. > A typical table traversal looks like this: re> /* table is in the stack at index 't' */ lua_pushnil(L); /* first key */ while (lua_next(L, t) != 0) { /* uses 'key' (at index -2) and 'value' (at index -1) */ printf("%s - %s\n", lua_typename(L, lua_type(L, -2)), lua_typename(L, l...

#### `lua_numbertocstring`

```c
unsigned lua_numbertocstring (lua_State *L, int idx, char *buff);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the number at acceptable index idx to a string and puts the result in buff. The buffer must have a size of at least LUA_N2SBUFFSZ bytes. The conversion follows a non-specified format (see &sect;3.4.3). The function returns the number of bytes written to the buffer (including the final zero), or zero if the value at idx is not a number.

#### `lua_numbertointeger`

```c
unsigned lua_numbertocstring (lua_State *L, int idx, char *buff);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the number at acceptable index idx to a string and puts the result in buff. The buffer must have a size of at least LUA_N2SBUFFSZ bytes. The conversion follows a non-specified format (see &sect;3.4.3). The function returns the number of bytes written to the buffer (including the final zero), or zero if the value at idx is not a number.

#### `lua_pcall`

```c
int lua_pcall (lua_State *L, int nargs, int nresults, int msgh);
```

- **堆栈弹出**: (nargs + 1)
- **堆栈压入**: (nresults|1)
- **错误标志**: -
- **描述**: Calls a function (or a callable object) in protected mode. > Both nargs and nresults have the same meaning as in lua_call. If there are no errors during the call, lua_pcall behaves exactly like lua_call. However, if there is any error, lua_pcall catches it, pushes a single value on the stack (the error object), and returns an error code. Like lua_call, lua_pcall always removes the function and its arguments from the stack. > If msgh is 0, then the error object returned on the stack is exactly...

#### `lua_pcallk`

```c
int lua_pcallk (lua_State *L, int nargs, int nresults, int msgh, lua_KContext ctx, lua_KFunction k);
```

- **堆栈弹出**: (nargs + 1)
- **堆栈压入**: (nresults|1)
- **错误标志**: -
- **描述**: This function behaves exactly like lua_pcall, except that it allows the called function to yield (see &sect;4.5).

#### `lua_pop`

```c
void lua_pop (lua_State *L, int n);
```

- **堆栈弹出**: n
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Pops n elements from the stack. It is implemented as a macro over lua_settop.

#### `lua_pushboolean`

```c
void lua_pushboolean (lua_State *L, int b);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes a boolean value with value b onto the stack.

#### `lua_pushcclosure`

```c
void lua_pushcclosure (lua_State *L, lua_CFunction fn, int n);
```

- **堆栈弹出**: n
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Pushes a new C closure onto the stack. This function receives a pointer to a C function and pushes onto the stack a Lua value of type function that, when called, invokes the corresponding C function. The parameter n tells how many upvalues this function will have (see &sect;4.2). > Any function to be callable by Lua must follow the correct protocol to receive its parameters and return its results (see lua_CFunction). > When a C function is created, it is possible to associate some values with...

#### `lua_pushcfunction`

```c
void lua_pushcfunction (lua_State *L, lua_CFunction f);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes a C function onto the stack. This function is equivalent to lua_pushcclosure with no upvalues.

#### `lua_pushexternalstring`

```c
const char *lua_pushexternalstring (lua_State *L, const char *s, size_t len, lua_Alloc falloc, void *ud);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates an external string, that is, a string that uses memory not managed by Lua. The pointer s points to the external buffer holding the string content, and len is the length of the string. The string should have a zero at its end, that is, the condition s[len] == '\0' should hold. As with any string in Lua, the length must fit in a Lua integer. > If falloc is different from NULL, that function will be called by Lua when the external buffer is no longer needed. The contents of the buffer sh...

#### `lua_pushfstring`

```c
const char *lua_pushfstring (lua_State *L, const char *fmt, ...);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: v
- **描述**: Pushes onto the stack a formatted string and returns a pointer to this string (see &sect;4.1.3). The result is a copy of fmt with each conversion specifier replaced by a string representation of its respective extra argument. A conversion specifier (and its corresponding extra argument) can be '%%' (inserts the character '%'), '%s' (inserts a zero-terminated string, with no size restrictions), '%f' (inserts a lua_Number), '%I' (inserts a lua_Integer), '%p' (inserts a void pointer), '%d' (inse...

#### `lua_pushglobaltable`

```c
void lua_pushglobaltable (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes the global environment onto the stack.

#### `lua_pushinteger`

```c
void lua_pushinteger (lua_State *L, lua_Integer n);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes an integer with value n onto the stack.

#### `lua_pushlightuserdata`

```c
void lua_pushlightuserdata (lua_State *L, void *p);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes a light userdata onto the stack. > Userdata represent C values in Lua. A light userdata represents a pointer, a void*. It is a value (like a number): you do not create it, it has no individual metatable, and it is not collected (as it was never created). A light userdata is equal to "any" light userdata with the same C address.

#### `lua_pushliteral`

```c
const char *lua_pushliteral (lua_State *L, const char *s);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: v
- **描述**: This macro is equivalent to lua_pushstring, but should be used only when s is a literal string. (Lua may optimize this case.)

#### `lua_pushlstring`

```c
const char *lua_pushlstring (lua_State *L, const char *s, size_t len);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: v
- **描述**: Pushes the string pointed to by s with size len onto the stack. Lua will make or reuse an internal copy of the given string, so the memory at s can be freed or reused immediately after the function returns. The string can contain any binary data, including embedded zeros. > Returns a pointer to the internal copy of the string (see &sect;4.1.3). > Besides memory allocation errors, this function may raise an error if the string is too large.

#### `lua_pushnil`

```c
void lua_pushnil (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes a nil value onto the stack.

#### `lua_pushnumber`

```c
void lua_pushnumber (lua_State *L, lua_Number n);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes a float with value n onto the stack.

#### `lua_pushstring`

```c
const char *lua_pushstring (lua_State *L, const char *s);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Pushes the zero-terminated string pointed to by s onto the stack. Lua will make or reuse an internal copy of the given string, so the memory at s can be freed or reused immediately after the function returns. > Returns a pointer to the internal copy of the string (see &sect;4.1.3). > If s is NULL, pushes nil and returns NULL.

#### `lua_pushthread`

```c
int lua_pushthread (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes the thread represented by L onto the stack. Returns 1 if this thread is the main thread of its state.

#### `lua_pushvalue`

```c
void lua_pushvalue (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes a copy of the element at the given index onto the stack.

#### `lua_pushvfstring`

```c
const char *lua_pushvfstring (lua_State *L, const char *fmt, va_list argp);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Equivalent to lua_pushfstring, except that it receives a va_list instead of a variable number of arguments, and it does not raise errors. Instead, in case of errors it pushes the error message and returns NULL.

#### `lua_rawequal`

```c
int lua_rawequal (lua_State *L, int index1, int index2);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns 1 if the two values in indices index1 and index2 are primitively equal (that is, equal without calling the __eq metamethod). Otherwise returns 0. Also returns 0 if any of the indices are not valid.

#### `lua_rawget`

```c
int lua_rawget (lua_State *L, int index);
```

- **堆栈弹出**: 1
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Similar to lua_gettable, but does a raw access (i.e., without metamethods). The value at index must be a table.

#### `lua_rawgeti`

```c
int lua_rawgeti (lua_State *L, int index, lua_Integer n);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes onto the stack the value t[n], where t is the table at the given index. The access is raw, that is, it does not use the __index metavalue. > Returns the type of the pushed value.

#### `lua_rawgetp`

```c
int lua_rawgetp (lua_State *L, int index, const void *p);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes onto the stack the value t[k], where t is the table at the given index and k is the pointer p represented as a light userdata. The access is raw; that is, it does not use the __index metavalue. > Returns the type of the pushed value.

#### `lua_rawlen`

```c
lua_Unsigned lua_rawlen (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the raw "length" of the value at the given index: for strings, this is the string length; for tables, this is the result of the length operator ('#') with no metamethods; for userdata, this is the size of the block of memory allocated for the userdata. For other values, this call returns 0.

#### `lua_rawset`

```c
void lua_rawset (lua_State *L, int index);
```

- **堆栈弹出**: 2
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: Similar to lua_settable, but does a raw assignment (i.e., without metamethods). The value at index must be a table.

#### `lua_rawseti`

```c
void lua_rawseti (lua_State *L, int index, lua_Integer i);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: Does the equivalent of t[i] = v, where t is the table at the given index and v is the value on the top of the stack. > This function pops the value from the stack. The assignment is raw, that is, it does not use the __newindex metavalue.

#### `lua_rawsetp`

```c
void lua_rawsetp (lua_State *L, int index, const void *p);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: Does the equivalent of t[p] = v, where t is the table at the given index, p is encoded as a light userdata, and v is the value on the top of the stack. > This function pops the value from the stack. The assignment is raw, that is, it does not use the __newindex metavalue.

#### `lua_register`

```c
void lua_register (lua_State *L, const char *name, lua_CFunction f);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Sets the C function f as the new value of global name. It is defined as a macro: re> #define lua_register(L,n,f) \ (lua_pushcfunction(L, f), lua_setglobal(L, n)) pre>

#### `lua_remove`

```c
void lua_remove (lua_State *L, int index);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Removes the element at the given valid index, shifting down the elements above this index to fill the gap. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.

#### `lua_replace`

```c
void lua_replace (lua_State *L, int index);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Moves the top element into the given valid index without shifting any element (therefore replacing the value at that given index), and then pops the top element.

#### `lua_resume`

```c
int lua_resume (lua_State *L, lua_State *from, int nargs, int *nresults);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: -
- **描述**: Starts and resumes a coroutine in the given thread L. > To start a coroutine, you push the main function plus any arguments onto the empty stack of the thread. then you call lua_resume, with nargs being the number of arguments. The function returns when the coroutine suspends, finishes its execution, or raises an unprotected error. When it returns without errors, *nresults is updated and the top of the stack contains the *nresults values passed to lua_yield or returned by the body function. l...

#### `lua_rotate`

```c
void lua_rotate (lua_State *L, int idx, int n);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Rotates the stack elements between the valid index idx and the top of the stack. The elements are rotated n positions in the direction of the top, for a positive n, or -n positions in the direction of the bottom, for a negative n. The absolute value of n must not be greater than the size of the slice being rotated. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.

#### `lua_setallocf`

```c
void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Changes the allocator function of a given state to f with user data ud.

#### `lua_setfield`

```c
void lua_setfield (lua_State *L, int index, const char *k);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Does the equivalent to t[k] = v, where t is the value at the given index and v is the value on the top of the stack. > This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see &sect;2.4).

#### `lua_setglobal`

```c
void lua_setglobal (lua_State *L, const char *name);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Pops a value from the stack and sets it as the new value of global name.

#### `lua_sethook`

```c
void lua_sethook (lua_State *L, lua_Hook f, int mask, int count);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Sets the debugging hook function. > Argument f is the hook function. mask specifies on which events the hook will be called: it is formed by a bitwise OR of the constants LUA_MASKCALL, LUA_MASKRET, LUA_MASKLINE, and LUA_MASKCOUNT. The count argument is only meaningful when the mask includes LUA_MASKCOUNT. For each event, the hook is called as explained below: l> i>The call hook: is called when the interpreter calls a function. The hook is called just after Lua enters the new function. li> i>T...

#### `lua_seti`

```c
void lua_seti (lua_State *L, int index, lua_Integer n);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Does the equivalent to t[n] = v, where t is the value at the given index and v is the value on the top of the stack. > This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see &sect;2.4).

#### `lua_setiuservalue`

```c
int lua_setiuservalue (lua_State *L, int index, int n);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Pops a value from the stack and sets it as the new n-th user value associated to the full userdata at the given index. Returns 0 if the userdata does not have that value.

#### `lua_setlocal`

```c
const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
```

- **堆栈弹出**: (0|1)
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Sets the value of a local variable of a given activation record. It assigns the value on the top of the stack to the variable and returns its name. It also pops the value from the stack. > Returns NULL (and pops nothing) when the index is greater than the number of active local variables. > Parameters ar and n are as in the function lua_getlocal.

#### `lua_setmetatable`

```c
int lua_setmetatable (lua_State *L, int index);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Pops a table or nil from the stack and sets that value as the new metatable for the value at the given index. (nil means no metatable.) > (For historical reasons, this function returns an int, which now is always 1.)

#### `lua_settable`

```c
void lua_settable (lua_State *L, int index);
```

- **堆栈弹出**: 2
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Does the equivalent to t[k] = v, where t is the value at the given index, v is the value on the top of the stack, and k is the value just below the top. > This function pops both the key and the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see &sect;2.4).

#### `lua_settop`

```c
void lua_settop (lua_State *L, int index);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: e
- **描述**: Receives any acceptable stack index, or 0, and sets the stack top to this index. If the new top is greater than the old one, then the new elements are filled with nil. If index is 0, then all stack elements are removed. > This function can run arbitrary code when removing an index marked as to-be-closed from the stack.

#### `lua_setupvalue`

```c
const char *lua_setupvalue (lua_State *L, int funcindex, int n);
```

- **堆栈弹出**: (0|1)
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Sets the value of a closure's upvalue. It assigns the value on the top of the stack to the upvalue and returns its name. It also pops the value from the stack. > Returns NULL (and pops nothing) when the index n is greater than the number of upvalues. > Parameters funcindex and n are as in the function lua_getupvalue.

#### `lua_setwarnf`

```c
void lua_setwarnf (lua_State *L, lua_WarnFunction f, void *ud);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Sets the warning function to be used by Lua to emit warnings (see lua_WarnFunction). The ud parameter sets the value ud passed to the warning function.

#### `lua_status`

```c
int lua_status (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the status of the thread L. > The status can be LUA_OK for a normal thread, an error code if the thread finished the execution of a lua_resume with an error, or LUA_YIELD if the thread is suspended. > You can call functions only in threads with status LUA_OK. You can resume threads with status LUA_OK (to start a new coroutine) or LUA_YIELD (to resume a coroutine).

#### `lua_stringtonumber`

```c
size_t lua_stringtonumber (lua_State *L, const char *s);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Converts the zero-terminated string s to a number, pushes that number into the stack, and returns the total size of the string, that is, its length plus one. The conversion can result in an integer or a float, according to the lexical conventions of Lua (see &sect;3.1). The string may have leading and trailing whitespaces and a sign. If the string is not a valid numeral, returns 0 and pushes nothing. (Note that the result can be used as a boolean, true if the conversion succeeds.)

#### `lua_toboolean`

```c
int lua_toboolean (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the Lua value at the given index to a C boolean value (0 or 1). Like all tests in Lua, lua_toboolean returns true for any Lua value different from false and nil; otherwise it returns false. (If you want to accept only actual boolean values, use lua_isboolean to test the value's type.)

#### `lua_tocfunction`

```c
lua_CFunction lua_tocfunction (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts a value at the given index to a C function. That value must be a C function; otherwise, returns NULL.

#### `lua_toclose`

```c
void lua_toclose (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Marks the given index in the stack as a to-be-closed slot (see &sect;3.3.8). Like a to-be-closed variable in Lua, the value at that slot in the stack will be closed when it goes out of scope. Here, in the context of a C function, to go out of scope means that the running function returns to Lua, or there is an error, or the slot is removed from the stack through lua_settop or lua_pop, or there is a call to lua_closeslot. A slot marked as to-be-closed should not be removed from the stack by an...

#### `lua_tointeger`

```c
lua_Integer lua_tointeger (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Equivalent to lua_tointegerx with isnum equal to NULL.

#### `lua_tointegerx`

```c
lua_Integer lua_tointegerx (lua_State *L, int index, int *isnum);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the Lua value at the given index to the signed integral type lua_Integer. The Lua value must be an integer, or a number or string convertible to an integer (see &sect;3.4.3); otherwise, lua_tointegerx returns 0. > If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.

#### `lua_tolstring`

```c
const char *lua_tolstring (lua_State *L, int index, size_t *len);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: Converts the Lua value at the given index to a C string. The Lua value must be a string or a number; otherwise, the function returns NULL. If the value is a number, then lua_tolstring also changes the actual value in the stack to a string. (This change confuses lua_next when lua_tolstring is applied to keys during a table traversal.) > If len is not NULL, the function sets *len with the string length. The returned C string always has a zero ('\0') after its last character, but can contain oth...

#### `lua_tonumber`

```c
lua_Number lua_tonumber (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Equivalent to lua_tonumberx with isnum equal to NULL.

#### `lua_tonumberx`

```c
lua_Number lua_tonumberx (lua_State *L, int index, int *isnum);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the Lua value at the given index to the C type lua_Number (see lua_Number). The Lua value must be a number or a string convertible to a number (see &sect;3.4.3); otherwise, lua_tonumberx returns 0. > If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.

#### `lua_topointer`

```c
const void *lua_topointer (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the value at the given index to a generic C pointer (void*). The value can be a userdata, a table, a thread, a string, or a function; otherwise, lua_topointer returns NULL. Different objects will give different pointers. There is no way to convert the pointer back to its original value. > Typically this function is used only for hashing and debug information.

#### `lua_tostring`

```c
const char *lua_tostring (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: Equivalent to lua_tolstring with len equal to NULL.

#### `lua_tothread`

```c
lua_State *lua_tothread (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Converts the value at the given index to a Lua thread (represented as lua_State*). This value must be a thread; otherwise, the function returns NULL.

#### `lua_touserdata`

```c
void *lua_touserdata (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: If the value at the given index is a full userdata, returns its memory-block address. If the value is a light userdata, returns its value (a pointer). Otherwise, returns NULL.

#### `lua_type`

```c
int lua_type (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the type of the value in the given valid index, or LUA_TNONE for a non-valid but acceptable index. The types returned by lua_type are coded by the following constants defined in lua.h: LUA_TNIL, LUA_TNUMBER, LUA_TBOOLEAN, LUA_TSTRING, LUA_TTABLE, LUA_TFUNCTION, LUA_TUSERDATA, LUA_TTHREAD, and LUA_TLIGHTUSERDATA.

#### `lua_typename`

```c
const char *lua_typename (lua_State *L, int tp);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the name of the type encoded by the value tp, which must be one the values returned by lua_type.

#### `lua_upvalueid`

```c
void *lua_upvalueid (lua_State *L, int funcindex, int n);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns a unique identifier for the upvalue numbered n from the closure at index funcindex. > These unique identifiers allow a program to check whether different closures share upvalues. Lua closures that share an upvalue (that is, that access a same external local variable) will return identical ids for those upvalue indices. > Parameters funcindex and n are as in the function lua_getupvalue, but n cannot be greater than the number of upvalues.

#### `lua_upvalueindex`

```c
int lua_upvalueindex (int i);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the pseudo-index that represents the i-th upvalue of the running function (see &sect;4.2). i must be in the range [1,256].

#### `lua_upvaluejoin`

```c
void lua_upvaluejoin (lua_State *L, int funcindex1, int n1, int funcindex2, int n2);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Make the n1-th upvalue of the Lua closure at index funcindex1 refer to the n2-th upvalue of the Lua closure at index funcindex2. 1>5 – The Auxiliary Libraryh1> > The auxiliary library provides several convenient functions to interface C with Lua. While the basic API provides the primitive functions for all interactions between C and Lua, the auxiliary library provides higher-level functions for some common tasks. > All functions and types from the auxiliary library are defined in the header...

#### `lua_version`

```c
lua_Number lua_version (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the version number of this core.

#### `lua_warning`

```c
void lua_warning (lua_State *L, const char *msg, int tocont);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Emits a warning with the given message. A message in a call with tocont true should be continued in another call to this function. > See warn for more details about warnings.

#### `lua_xmove`

```c
void lua_xmove (lua_State *from, lua_State *to, int n);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: -
- **描述**: Exchange values between different threads of the same state. > This function pops n values from the stack from, and pushes them onto the stack to.

#### `lua_yield`

```c
int lua_yield (lua_State *L, int nresults);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: v
- **描述**: This function is equivalent to lua_yieldk, but it has no continuation (see &sect;4.5). Therefore, when the thread resumes, it continues the function that called the function calling lua_yield. To avoid surprises, this function should be called only in a tail call.

#### `lua_yieldk`

```c
int lua_yieldk (lua_State *L, int nresults, lua_KContext ctx, lua_KFunction k);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: v
- **描述**: Yields a coroutine (thread). > When a C function calls lua_yieldk, the running coroutine suspends its execution, and the call to lua_resume that started this coroutine returns. The parameter nresults is the number of values from the stack that will be passed as results to lua_resume. > When the coroutine is resumed again, Lua calls the given continuation function k to continue the execution of the C function that yielded (see &sect;4.5). This continuation function receives the same stack from...

### Auxiliary Library

#### `luaL_addchar`

```c
void luaL_addchar (luaL_Buffer *B, char c);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Adds the byte c to the buffer B (see luaL_Buffer).

#### `luaL_addgsub`

```c
const void luaL_addgsub (luaL_Buffer *B, const char *s, const char *p, const char *r);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Adds a copy of the string s to the buffer B (see luaL_Buffer), replacing any occurrence of the string p with the string r.

#### `luaL_addlstring`

```c
void luaL_addlstring (luaL_Buffer *B, const char *s, size_t l);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Adds the string pointed to by s with length l to the buffer B (see luaL_Buffer). The string can contain embedded zeros.

#### `luaL_addsize`

```c
void luaL_addsize (luaL_Buffer *B, size_t n);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: -
- **描述**: Adds to the buffer B a string of length n previously copied to the buffer area (see luaL_prepbuffer).

#### `luaL_addstring`

```c
void luaL_addstring (luaL_Buffer *B, const char *s);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Adds the zero-terminated string pointed to by s to the buffer B (see luaL_Buffer).

#### `luaL_addvalue`

```c
void luaL_addvalue (luaL_Buffer *B);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Adds the value on the top of the stack to the buffer B (see luaL_Buffer). Pops the value. > This is the only function on string buffers that can (and must) be called with an extra element on the stack, which is the value to be added to the buffer.

#### `luaL_argcheck`

```c
void luaL_argcheck (lua_State *L, int cond, int arg, const char *extramsg);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether cond is true. If it is not, raises an error with a standard message (see luaL_argerror).

#### `luaL_argerror`

```c
int luaL_argerror (lua_State *L, int arg, const char *extramsg);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Raises an error reporting a problem with argument arg of the C function that called it, using a standard message that includes extramsg as a comment: re> bad argument #arg to 'funcname' (extramsg) pre>> This function never returns.

#### `luaL_argexpected`

```c
void luaL_argexpected (lua_State *L, int cond, int arg, const char *tname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether cond is true. If it is not, raises an error about the type of the argument arg with a standard message (see luaL_typeerror).

#### `luaL_buffaddr`

```c
char *luaL_buffaddr (luaL_Buffer *B);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the address of the current content of buffer B (see luaL_Buffer). Note that any addition to the buffer may invalidate this address.

#### `luaL_buffinit`

```c
void luaL_buffinit (lua_State *L, luaL_Buffer *B);
```

- **堆栈弹出**: 0
- **堆栈压入**: ?
- **错误标志**: -
- **描述**: Initializes a buffer B (see luaL_Buffer). This function does not allocate any space; the buffer must be declared as a variable.

#### `luaL_buffinitsize`

```c
char *luaL_buffinitsize (lua_State *L, luaL_Buffer *B, size_t sz);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Equivalent to the sequence luaL_buffinit, luaL_prepbuffsize.

#### `luaL_bufflen`

```c
size_t luaL_bufflen (luaL_Buffer *B);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the length of the current content of buffer B (see luaL_Buffer).

#### `luaL_buffsub`

```c
void luaL_buffsub (luaL_Buffer *B, int n);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: -
- **描述**: Removes n bytes from the buffer B (see luaL_Buffer). The buffer must have at least that many bytes.

#### `luaL_callmeta`

```c
int luaL_callmeta (lua_State *L, int obj, const char *e);
```

- **堆栈弹出**: 0
- **堆栈压入**: (0|1)
- **错误标志**: e
- **描述**: Calls a metamethod. > If the object at index obj has a metatable and this metatable has a field e, this function calls this field passing the object as its only argument. In this case this function returns true and pushes onto the stack the value returned by the call. If there is no metatable or no metamethod, this function returns false without pushing any value on the stack.

#### `luaL_checkany`

```c
void luaL_checkany (lua_State *L, int arg);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function has an argument of any type (including nil) at position arg.

#### `luaL_checkinteger`

```c
lua_Integer luaL_checkinteger (lua_State *L, int arg);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function argument arg is an integer (or can be converted to an integer) and returns this integer.

#### `luaL_checklstring`

```c
const char *luaL_checklstring (lua_State *L, int arg, size_t *l);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function argument arg is a string and returns this string; if l is not NULL fills its referent with the string's length. > This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.

#### `luaL_checknumber`

```c
lua_Number luaL_checknumber (lua_State *L, int arg);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function argument arg is a number and returns this number converted to a lua_Number.

#### `luaL_checkoption`

```c
int luaL_checkoption (lua_State *L, int arg, const char *def, const char *const lst[]);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function argument arg is a string and searches for this string in the array lst (which must be NULL-terminated). Returns the index in the array where the string was found. Raises an error if the argument is not a string or if the string cannot be found. > If def is not NULL, the function uses def as a default value when there is no argument arg or when this argument is nil. > This is a useful function for mapping strings to C enums. (The usual convention in Lua libraries is...

#### `luaL_checkstack`

```c
void luaL_checkstack (lua_State *L, int sz, const char *msg);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Grows the stack size to top + sz elements, raising an error if the stack cannot grow to that size. msg is an additional text to go into the error message (or NULL for no additional text).

#### `luaL_checkstring`

```c
const char *luaL_checkstring (lua_State *L, int arg);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function argument arg is a string and returns this string. > This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.

#### `luaL_checktype`

```c
void luaL_checktype (lua_State *L, int arg, int t);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function argument arg has type t. See lua_type for the encoding of types for t.

#### `luaL_checkudata`

```c
void *luaL_checkudata (lua_State *L, int arg, const char *tname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the function argument arg is a userdata of the type tname (see luaL_newmetatable) and returns the userdata's memory-block address (see lua_touserdata).

#### `luaL_checkversion`

```c
void luaL_checkversion (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Checks whether the code making the call and the Lua library being called are using the same version of Lua and the same numeric types.

#### `luaL_dofile`

```c
int luaL_dofile (lua_State *L, const char *filename);
```

- **堆栈弹出**: 0
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Loads and runs the given file. It is defined as the following macro: re> (luaL_loadfile(L, filename) || lua_pcall(L, 0, LUA_MULTRET, 0)) pre>> It returns 0 (LUA_OK) if there are no errors, or 1 in case of errors. (Except for out-of-memory errors, which are raised.)

#### `luaL_dostring`

```c
int luaL_dostring (lua_State *L, const char *str);
```

- **堆栈弹出**: 0
- **堆栈压入**: ?
- **错误标志**: -
- **描述**: Loads and runs the given string. It is defined as the following macro: re> (luaL_loadstring(L, str) || lua_pcall(L, 0, LUA_MULTRET, 0)) pre>> It returns 0 (LUA_OK) if there are no errors, or 1 in case of errors.

#### `luaL_error`

```c
int luaL_error (lua_State *L, const char *fmt, ...);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Raises an error. The error message format is given by fmt plus any extra arguments, following the same rules of lua_pushfstring. It also adds at the beginning of the message the file name and the line number where the error occurred, if this information is available. > This function never returns, but it is an idiom to use it in C functions as return luaL_error(args).

#### `luaL_execresult`

```c
int luaL_execresult (lua_State *L, int stat);
```

- **堆栈弹出**: 0
- **堆栈压入**: 3
- **错误标志**: m
- **描述**: This function produces the return values for process-related functions in the standard library (os.execute and io.close).

#### `luaL_fileresult`

```c
int luaL_fileresult (lua_State *L, int stat, const char *fname);
```

- **堆栈弹出**: 0
- **堆栈压入**: (1|3)
- **错误标志**: m
- **描述**: This function produces the return values for file-related functions in the standard library (io.open, os.rename, file:seek, etc.).

#### `luaL_getmetafield`

```c
int luaL_getmetafield (lua_State *L, int obj, const char *e);
```

- **堆栈弹出**: 0
- **堆栈压入**: (0|1)
- **错误标志**: m
- **描述**: Pushes onto the stack the field e from the metatable of the object at index obj and returns the type of the pushed value. If the object does not have a metatable, or if the metatable does not have this field, pushes nothing and returns LUA_TNIL.

#### `luaL_getmetatable`

```c
int luaL_getmetatable (lua_State *L, const char *tname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Pushes onto the stack the metatable associated with the name tname in the registry (see luaL_newmetatable), or nil if there is no metatable associated with that name. Returns the type of the pushed value.

#### `luaL_getsubtable`

```c
int luaL_getsubtable (lua_State *L, int idx, const char *fname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Ensures that the value t[fname], where t is the value at index idx, is a table, and pushes that table onto the stack. Returns true if it finds a previous table there and false if it creates a new table.

#### `luaL_gsub`

```c
const char *luaL_gsub (lua_State *L, const char *s, const char *p, const char *r);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates a copy of string s, replacing any occurrence of the string p with the string r. Pushes the resulting string on the stack and returns it.

#### `luaL_len`

```c
lua_Integer luaL_len (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Returns the "length" of the value at the given index as a number; it is equivalent to the '#' operator in Lua (see &sect;3.4.7). Raises an error if the result of the operation is not an integer. (This case can only happen through metamethods.)

#### `luaL_loadbuffer`

```c
int luaL_loadbuffer (lua_State *L, const char *buff, size_t sz, const char *name);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Equivalent to luaL_loadbufferx with mode equal to NULL.

#### `luaL_loadbufferx`

```c
int luaL_loadbufferx (lua_State *L, const char *buff, size_t sz, const char *name, const char *mode);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Loads a buffer as a Lua chunk. This function uses lua_load to load the chunk in the buffer pointed to by buff with size sz. > This function returns the same results as lua_load. name is the chunk name, used for debug information and error messages. The string mode works as in the function lua_load. In particular, this function supports mode 'B' for fixed buffers.

#### `luaL_loadfile`

```c
int luaL_loadfile (lua_State *L, const char *filename);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Equivalent to luaL_loadfilex with mode equal to NULL.

#### `luaL_loadfilex`

```c
int luaL_loadfilex (lua_State *L, const char *filename, const char *mode);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Loads a file as a Lua chunk. This function uses lua_load to load the chunk in the file named filename. If filename is NULL, then it loads from the standard input. The first line in the file is ignored if it starts with a #. > The string mode works as in the function lua_load. > This function returns the same results as lua_load, or LUA_ERRFILE for file-related errors. > As lua_load, this function only loads the chunk; it does not run it.

#### `luaL_loadstring`

```c
int luaL_loadstring (lua_State *L, const char *s);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Loads a string as a Lua chunk. This function uses lua_load to load the chunk in the zero-terminated string s. > This function returns the same results as lua_load. > Also as lua_load, this function only loads the chunk; it does not run it.

#### `luaL_makeseed`

```c
unsigned int luaL_makeseed (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns a value with a weak attempt for randomness. The parameter L can be NULL if there is no Lua state available.

#### `luaL_newlib`

```c
void luaL_newlib (lua_State *L, const luaL_Reg l[]);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates a new table and registers there the functions in the list l. > It is implemented as the following macro: re> (luaL_newlibtable(L,l), luaL_setfuncs(L,l,0)) pre>> The array l must be the actual array, not a pointer to it.

#### `luaL_newlibtable`

```c
void luaL_newlibtable (lua_State *L, const luaL_Reg l[]);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates a new table with a size optimized to store all entries in the array l (but does not actually store them). It is intended to be used in conjunction with luaL_setfuncs (see luaL_newlib). > It is implemented as a macro. The array l must be the actual array, not a pointer to it.

#### `luaL_newmetatable`

```c
int luaL_newmetatable (lua_State *L, const char *tname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: If the registry already has the key tname, returns 0. Otherwise, creates a new table to be used as a metatable for userdata, adds to this new table the pair __name = tname, adds to the registry the pair [tname] = new table, and returns 1. > In both cases, the function pushes onto the stack the final value associated with tname in the registry.

#### `luaL_newstate`

```c
lua_State *luaL_newstate (void);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Creates a new Lua state. It calls lua_newstate with luaL_alloc as the allocator function and the result of luaL_makeseed(NULL) as the seed, and then sets a warning function and a panic function (see &sect;4.4) that print messages to the standard error output. > Returns the new state, or NULL if there is a memory allocation error.

#### `luaL_openlibs`

```c
void luaL_openlibs (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Opens all standard Lua libraries into the given state.

#### `luaL_openselectedlibs`

```c
void luaL_openselectedlibs (lua_State *L, int load, int preload);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: e
- **描述**: Opens (loads) and preloads selected standard libraries into the state L. (To preload means to add the library loader into the table package.preload, so that the library can be required later by the program. Keep in mind that require itself is provided by the package library. If a program does not load that library, it will be unable to require anything.) > The integer load selects which libraries to load; the integer preload selects which to preload, among those not loaded. Both are masks for...

#### `luaL_opt`

```c
T luaL_opt (L, func, arg, dflt);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: This macro is defined as follows: re> (lua_isnoneornil(L,(arg)) ? (dflt) : func(L,(arg))) pre>> In words, if the argument arg is nil or absent, the macro results in the default dflt. Otherwise, it results in the result of calling func with the state L and the argument index arg as arguments. Note that it evaluates the expression dflt only if needed.

#### `luaL_optinteger`

```c
lua_Integer luaL_optinteger (lua_State *L, int arg, lua_Integer d);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: If the function argument arg is an integer (or it is convertible to an integer), returns this integer. If this argument is absent or is nil, returns d. Otherwise, raises an error.

#### `luaL_optlstring`

```c
const char *luaL_optlstring (lua_State *L, int arg, const char *d, size_t *l);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: If the function argument arg is a string, returns this string. If this argument is absent or is nil, returns d. Otherwise, raises an error. > If l is not NULL, fills its referent with the result's length. If the result is NULL (only possible when returning d and d == NULL), its length is considered zero. > This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.

#### `luaL_optnumber`

```c
lua_Number luaL_optnumber (lua_State *L, int arg, lua_Number d);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: If the function argument arg is a number, returns this number as a lua_Number. If this argument is absent or is nil, returns d. Otherwise, raises an error.

#### `luaL_optstring`

```c
const char *luaL_optstring (lua_State *L, int arg, const char *d);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: If the function argument arg is a string, returns this string. If this argument is absent or is nil, returns d. Otherwise, raises an error.

#### `luaL_prepbuffer`

```c
char *luaL_prepbuffer (luaL_Buffer *B);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Equivalent to luaL_prepbuffsize with the predefined size LUAL_BUFFERSIZE.

#### `luaL_prepbuffsize`

```c
char *luaL_prepbuffsize (luaL_Buffer *B, size_t sz);
```

- **堆栈弹出**: ?
- **堆栈压入**: ?
- **错误标志**: m
- **描述**: Returns an address to a space of size sz where you can copy a string to be added to buffer B (see luaL_Buffer). After copying the string into this space you must call luaL_addsize with the size of the string to actually add it to the buffer.

#### `luaL_pushfail`

```c
void luaL_pushfail (lua_State *L);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: -
- **描述**: Pushes the fail value onto the stack (see &sect;6).

#### `luaL_pushresult`

```c
void luaL_pushresult (luaL_Buffer *B);
```

- **堆栈弹出**: ?
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Finishes the use of buffer B leaving the final string on the top of the stack.

#### `luaL_pushresultsize`

```c
void luaL_pushresultsize (luaL_Buffer *B, size_t sz);
```

- **堆栈弹出**: ?
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Equivalent to the sequence luaL_addsize, luaL_pushresult.

#### `luaL_ref`

```c
int luaL_ref (lua_State *L, int t);
```

- **堆栈弹出**: 1
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: Creates and returns a reference, in the table at index t, for the object on the top of the stack (and pops the object). > The reference system uses the integer keys of the table. A reference is a unique integer key; luaL_ref ensures the uniqueness of the keys it returns. The entry 1 is reserved for internal use. Before the first use of luaL_ref, the integer keys of the table should form a proper sequence (no holes), and the value at entry 1 should be false: nil if the sequence is empty, false...

#### `luaL_requiref`

```c
void luaL_requiref (lua_State *L, const char *modname, lua_CFunction openf, int glb);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: If package.loaded[modname] is not true, calls the function openf with the string modname as an argument and sets the call result to package.loaded[modname], as if that function has been called through require. > If glb is true, also stores the module into the global variable modname. > Leaves a copy of the module on the stack.

#### `luaL_setfuncs`

```c
void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup);
```

- **堆栈弹出**: nup
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: Registers all functions in the array l (see luaL_Reg) into the table on the top of the stack (below optional upvalues, see next). > When nup is not zero, all functions are created with nup upvalues, initialized with copies of the nup values previously pushed on the stack on top of the library table. These values are popped from the stack after the registration. > A function with a NULL value represents a placeholder, which is filled with false.

#### `luaL_setmetatable`

```c
void luaL_setmetatable (lua_State *L, const char *tname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Sets the metatable of the object on the top of the stack as the metatable associated with name tname in the registry (see luaL_newmetatable).

#### `luaL_testudata`

```c
void *luaL_testudata (lua_State *L, int arg, const char *tname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: m
- **描述**: This function works like luaL_checkudata, except that, when the test fails, it returns NULL instead of raising an error.

#### `luaL_tolstring`

```c
const char *luaL_tolstring (lua_State *L, int idx, size_t *len);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: e
- **描述**: Converts any Lua value at the given index to a C string in a reasonable format. The resulting string is pushed onto the stack and also returned by the function (see &sect;4.1.3). If len is not NULL, the function also sets *len with the string length. > If the value has a metatable with a __tostring field, then luaL_tolstring calls the corresponding metamethod with the value as argument, and uses the result of the call as its result.

#### `luaL_traceback`

```c
void luaL_traceback (lua_State *L, lua_State *L1, const char *msg, int level);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Creates and pushes a traceback of the stack L1. If msg is not NULL, it is appended at the beginning of the traceback. The level parameter tells at which level to start the traceback.

#### `luaL_typeerror`

```c
int luaL_typeerror (lua_State *L, int arg, const char *tname);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: v
- **描述**: Raises a type error for the argument arg of the C function that called it, using a standard message; tname is a "name" for the expected type. This function never returns.

#### `luaL_typename`

```c
const char *luaL_typename (lua_State *L, int index);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Returns the name of the type of the value at the given index.

#### `luaL_unref`

```c
void luaL_unref (lua_State *L, int t, int ref);
```

- **堆栈弹出**: 0
- **堆栈压入**: 0
- **错误标志**: -
- **描述**: Releases a reference (see luaL_ref). The integer ref must be either LUA_NOREF, LUA_REFNIL, or a reference previously returned by luaL_ref and not already released. If ref is either LUA_NOREF or LUA_REFNIL this function does nothing. Otherwise, the entry is removed from the table, so that the referred object can be collected and the reference ref can be used again by luaL_ref.

#### `luaL_where`

```c
void luaL_where (lua_State *L, int lvl);
```

- **堆栈弹出**: 0
- **堆栈压入**: 1
- **错误标志**: m
- **描述**: Pushes onto the stack a string identifying the current position of the control at level lvl in the call stack. Typically this string has the following format: re> chunkname:currentline: pre>> Level 0 is the running function, level 1 is the function that called the running function, etc. > This function is used to build a prefix for error messages. 1>6 – The Standard Librariesh1> > The standard Lua libraries provide useful functions that are implemented in C through the C API. Some of these ...
