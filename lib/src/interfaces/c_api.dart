// AUTO GENERATED FILE by scripts/generate_dart_interfaces.lua
// LuaCAPI

import 'dart:ffi' as ffi;
import 'types.dart';

abstract interface class LuaCAPI {
  ffi.Pointer<lua_State> get state;

  /// Converts the acceptable index idx into an equivalent absolute index (that is, one that does not depend on the stack size).
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_absindex (lua_State *L, int idx);`
  int absindex(int idx);

  /// Performs an arithmetic or bitwise operation over the two values (or one, in the case of negations) at the top of the stack, with the value on the top being the second operand, pops these values, and pushes the result of the operation. The function follows the semantics of the corresponding Lua operator (that is, it may call metamethods). The value of op must be one of the following constants: LUA_OPADD: performs addition (+) LUA_OPSUB: performs subtraction (-) LUA_OPMUL: performs multiplication (*) LUA_OPDIV: performs float division (/) LUA_OPIDIV: performs floor division (//) LUA_OPMOD: performs modulo (%) LUA_OPPOW: performs exponentiation (^) LUA_OPUNM: performs mathematical negation (unary -) LUA_OPBNOT: performs bitwise NOT (~) LUA_OPBAND: performs bitwise AND (&) LUA_OPBOR: performs bitwise OR (|) LUA_OPBXOR: performs bitwise exclusive OR (~) LUA_OPSHL: performs left shift (<<) LUA_OPSHR: performs right shift (>>)
  ///
  /// Stack: `[-(2|1), +1, e]`
  ///
  /// C: `void lua_arith (lua_State *L, int op);`
  void arith(int op);

  /// Sets a new panic function and returns the old one (see §4.4).
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_CFunction lua_atpanic (lua_State *L, lua_CFunction panicf);`
  ffi.Pointer<ffi.NativeFunction> atpanic(ffi.Pointer<ffi.NativeFunction> panicf);

  /// Calls a function. Like regular Lua calls, lua_call respects the __call metamethod. So, here the word "function" means any callable value. To do a call you must use the following protocol: first, the function to be called is pushed onto the stack; then, the arguments to the call are pushed in direct order; that is, the first argument is pushed first. Finally you call lua_call; nargs is the number of arguments that you pushed onto the stack. When the function returns, all arguments and the function value are popped and the call results are pushed onto the stack. The number of results is adjusted to nresults, unless nresults is LUA_MULTRET, which makes all results from the function to be pushed. In the first case, an explicit number of results, the caller must ensure that the stack has space for the returned values. In the second case, all results, Lua takes care that the returned values fit into the stack space, but it does not ensure any extra space in the stack. The function results are pushed onto the stack in direct order (the first result is pushed first), so that after the call the last result is on the top of the stack. The maximum value for nresults is 250. Any error while calling and running the function is propagated upwards (with a longjmp). The following example shows how the host program can do the equivalent to this Lua code: a = f("how", t.x, 14) Here it is in&nbsp;C: lua_getglobal(L, "f"); /* function to be called */ lua_pushliteral(L, "how"); /* 1st argument */ lua_getglobal(L, "t"); /* table to be indexed */ lua_getfield(L, -1, "x"); /* push result of t.x (2nd arg) */ lua_remove(L, -2); /* remove 't' from the stack */ lua_pushinteger(L, 14); /* 3rd argument */ lua_call(L, 3, 1); /* call 'f' with 3 arguments and 1 result */ lua_setglobal(L, "a"); /* set global 'a' */ Note that the code above is balanced: at its end, the stack is back to its original configuration. This is considered good programming practice.
  ///
  /// Stack: `[-(nargs+1), +nresults, e]`
  ///
  /// C: `void lua_call (lua_State *L, int nargs, int nresults);`
  void call(int nargs, int nresults);

  /// This function behaves exactly like lua_call, but allows the called function to yield (see §4.5).
  ///
  /// Stack: `[-(nargs + 1), +nresults, e]`
  ///
  /// C: `void lua_callk (lua_State *L, int nargs, int nresults, lua_KContext ctx, lua_KFunction k);`
  void callk(int nargs, int nresults, int ctx, ffi.Pointer<ffi.NativeFunction> k);

  /// Ensures that the stack has space for at least n extra elements, that is, that you can safely push up to n values into it. It returns false if it cannot fulfill the request, either because it would cause the stack to be greater than a fixed maximum size (typically at least several thousand elements) or because it cannot allocate memory for the extra space. This function never shrinks the stack; if the stack already has space for the extra elements, it is left unchanged.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_checkstack (lua_State *L, int n);`
  int checkstack(int n);

  /// Close all active to-be-closed variables in the main thread, release all objects in the given Lua state (calling the corresponding garbage-collection metamethods, if any), and frees all dynamic memory used by this state. On several platforms, you may not need to call this function, because all resources are naturally released when the host program ends. On the other hand, long-running programs that create multiple states, such as daemons or web servers, will probably need to close states as soon as they are not needed.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_close (lua_State *L);`
  void close();

  /// Close the to-be-closed slot at the given index and set its value to nil. The index must be the last index previously marked to be closed (see lua_toclose) that is still active (that is, not closed yet). A __close metamethod cannot yield when called through this function.
  ///
  /// Stack: `[-0, +0, e]`
  ///
  /// C: `void lua_closeslot (lua_State *L, int index);`
  void closeslot(int index);

  /// Resets a thread, cleaning its call stack and closing all pending to-be-closed variables. The parameter from represents the coroutine that is resetting L. If there is no such coroutine, this parameter can be NULL. Unless L is equal to from, the call returns a status code: LUA_OK for no errors in the thread (either the original error that stopped the thread or errors in closing methods), or an error status otherwise. In case of error, the error object is put on the top of the stack. If L is equal to from, it corresponds to a thread closing itself. In that case, the call does not return; instead, the resume that (re)started the thread returns. The thread must be running inside a resume.
  ///
  /// Stack: `[-0, +?, -]`
  ///
  /// C: `int lua_closethread (lua_State *L, lua_State *from);`
  int closethread(ffi.Pointer<ffi.Void> from_);

  /// Compares two Lua values. Returns 1 if the value at index index1 satisfies op when compared with the value at index index2, following the semantics of the corresponding Lua operator (that is, it may call metamethods). Otherwise returns&nbsp;0. Also returns&nbsp;0 if any of the indices is not valid. The value of op must be one of the following constants: LUA_OPEQ: compares for equality (==) LUA_OPLT: compares for less than (<) LUA_OPLE: compares for less or equal (<=)
  ///
  /// Stack: `[-0, +0, e]`
  ///
  /// C: `int lua_compare (lua_State *L, int index1, int index2, int op);`
  int compare(int index1, int index2, int op);

  /// Concatenates the n values at the top of the stack, pops them, and leaves the result on the top. If n&nbsp;is&nbsp;1, the result is the single value on the stack (that is, the function does nothing); if n is 0, the result is the empty string. Concatenation is performed following the usual semantics of Lua (see §3.4.6).
  ///
  /// Stack: `[-n, +1, e]`
  ///
  /// C: `void lua_concat (lua_State *L, int n);`
  void concat(int n);

  /// Copies the element at index fromidx into the valid index toidx, replacing the value at that position. Values at other positions are not affected.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_copy (lua_State *L, int fromidx, int toidx);`
  void copy(int fromidx, int toidx);

  /// Creates a new empty table and pushes it onto the stack. Parameter nseq is a hint for how many elements the table will have as a sequence; parameter nrec is a hint for how many other elements the table will have. Lua may use these hints to preallocate memory for the new table. This preallocation may help performance when you know in advance how many elements the table will have. Otherwise you should use the function lua_newtable.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `void lua_createtable (lua_State *L, int nseq, int nrec);`
  void createtable(int nseq, int nrec);

  /// Dumps a function as a binary chunk. Receives a Lua function on the top of the stack and produces a binary chunk that, if loaded again, results in a function equivalent to the one dumped. As it produces parts of the chunk, lua_dump calls function writer (see lua_Writer) with the given data to write them. The function lua_dump fully preserves the Lua stack through the calls to the writer function, except that it may push some values for internal use before the first call, and it restores the stack size to its original size after the last call. If strip is true, the binary representation may not include all debug information about the function, to save space. The value returned is the error code returned by the last call to the writer; 0&nbsp;means no errors.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_dump (lua_State *L, lua_Writer writer, void *data, int strip);`
  int dump(ffi.Pointer<ffi.NativeFunction> writer, ffi.Pointer<ffi.Void> data, int strip);

  /// Raises a Lua error, using the value on the top of the stack as the error object. This function does a long jump, and therefore never returns (see luaL_error).
  ///
  /// Stack: `[-1, +0, v]`
  ///
  /// C: `int lua_error (lua_State *L);`
  int error();

  /// Controls the garbage collector. This function performs several tasks, according to the value of the parameter what. For options that need extra arguments, they are listed after the option. LUA_GCCOLLECT: Performs a full garbage-collection cycle. LUA_GCSTOP: Stops the garbage collector. LUA_GCRESTART: Restarts the garbage collector. LUA_GCCOUNT: Returns the current amount of memory (in Kbytes) in use by Lua. LUA_GCCOUNTB: Returns the remainder of dividing the current amount of bytes of memory in use by Lua by 1024. LUA_GCSTEP (size_t n): Performs a step of garbage collection. LUA_GCISRUNNING: Returns a boolean that tells whether the collector is running (i.e., not stopped). LUA_GCINC: Changes the collector to incremental mode. Returns the previous mode (LUA_GCGEN or LUA_GCINC). LUA_GCGEN: Changes the collector to generational mode. Returns the previous mode (LUA_GCGEN or LUA_GCINC). LUA_GCPARAM (int param, int val): Changes and/or returns the value of a parameter of the collector. If val is -1, the call only returns the current value. The argument param must have one of the following values: LUA_GCPMINORMUL: The minor multiplier. LUA_GCPMAJORMINOR: The major-minor multiplier. LUA_GCPMINORMAJOR: The minor-major multiplier. LUA_GCPPAUSE: The garbage-collector pause. LUA_GCPSTEPMUL: The step multiplier. LUA_GCPSTEPSIZE: The step size. For more details about these options, see collectgarbage. This function should not be called by a finalizer.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_gc (lua_State *L, int what, ...);`
  int gc(int what);

  /// Returns the memory-allocator function of a given state. If ud is not NULL, Lua stores in *ud the opaque pointer given when the memory-allocator function was set.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Alloc lua_getallocf (lua_State *L, void **ud);`
  ffi.Pointer<ffi.NativeFunction> getallocf(ffi.Pointer<ffi.Void> ud);

  /// Returns a pointer to a raw memory area associated with the given Lua state. The application can use this area for any purpose; Lua does not use it for anything. Each new thread has this area initialized with a copy of the area of the main thread. By default, this area has the size of a pointer to void, but you can recompile Lua with a different size for this area. (See LUA_EXTRASPACE in luaconf.h.)
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void *lua_getextraspace (lua_State *L);`
  ffi.Pointer<ffi.Void> getextraspace();

  /// Pushes onto the stack the value t[k], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see §2.4). Returns the type of the pushed value.
  ///
  /// Stack: `[-0, +1, e]`
  ///
  /// C: `int lua_getfield (lua_State *L, int index, const char *k);`
  int getfield(int index, ffi.Pointer<ffi.Void> k);

  /// Pushes onto the stack the value of the global name. Returns the type of that value.
  ///
  /// Stack: `[-0, +1, e]`
  ///
  /// C: `int lua_getglobal (lua_State *L, const char *name);`
  int getglobal(ffi.Pointer<ffi.Void> name);

  /// Returns the current hook function.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Hook lua_gethook (lua_State *L);`
  ffi.Pointer<ffi.NativeFunction> gethook();

  /// Returns the current hook count.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_gethookcount (lua_State *L);`
  int gethookcount();

  /// Returns the current hook mask.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_gethookmask (lua_State *L);`
  int gethookmask();

  /// Pushes onto the stack the value t[i], where t is the value at the given index. As in Lua, this function may trigger a metamethod for the "index" event (see §2.4). Returns the type of the pushed value.
  ///
  /// Stack: `[-0, +1, e]`
  ///
  /// C: `int lua_geti (lua_State *L, int index, lua_Integer i);`
  int geti(int index, int i);

  /// Gets information about a specific function or function invocation. To get information about a function invocation, the parameter ar must be a valid activation record that was filled by a previous call to lua_getstack or given as argument to a hook (see lua_Hook). To get information about a function, you push it onto the stack and start the what string with the character '>'. (In that case, lua_getinfo pops the function from the top of the stack.) For instance, to know in which line a function f was defined, you can write the following code: lua_Debug ar; lua_getglobal(L, "f"); /* get global 'f' */ lua_getinfo(L, ">S", &ar); printf("%d\n", ar.linedefined); Each character in the string what selects some fields of the structure ar to be filled or a value to be pushed on the stack. (These characters are also documented in the declaration of the structure lua_Debug, between parentheses in the comments following each field.) 'f': pushes onto the stack the function that is running at the given level; 'l': fills in the field currentline; 'n': fills in the fields name and namewhat; 'r': fills in the fields ftransfer and ntransfer; 'S': fills in the fields source, short_src, linedefined, lastlinedefined, and what; 't': fills in the fields istailcall and extraargs; 'u': fills in the fields nups, nparams, and isvararg; 'L': pushes onto the stack a table whose indices are the lines on the function with some associated code, that is, the lines where you can put a break point. (Lines with no code include empty lines and comments.) If this option is given together with option 'f', its table is pushed after the function. This is the only option that can raise a memory error. This function returns 0 to signal an invalid option in what; even then the valid options are handled correctly.
  ///
  /// Stack: `[-(0|1), +(0|1|2), m]`
  ///
  /// C: `int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);`
  int getinfo(ffi.Pointer<ffi.Void> what, ffi.Pointer<ffi.Void> ar);

  /// Pushes onto the stack the n-th user value associated with the full userdata at the given index and returns the type of the pushed value. If the userdata does not have that value, pushes nil and returns LUA_TNONE.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int lua_getiuservalue (lua_State *L, int index, int n);`
  int getiuservalue(int index, int n);

  /// Gets information about a local variable or a temporary value of a given activation record or a given function. In the first case, the parameter ar must be a valid activation record that was filled by a previous call to lua_getstack or given as argument to a hook (see lua_Hook). The index n selects which local variable to inspect; see debug.getlocal for details about variable indices and names. lua_getlocal pushes the variable's value onto the stack and returns its name. In the second case, ar must be NULL and the function to be inspected must be on the top of the stack. In this case, only parameters of Lua functions are visible (as there is no information about what variables are active) and no values are pushed onto the stack. Returns NULL (and pushes nothing) when the index is greater than the number of active local variables.
  ///
  /// Stack: `[-0, +(0|1), -]`
  ///
  /// C: `const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);`
  ffi.Pointer<ffi.Void> getlocal(ffi.Pointer<ffi.Void> ar, int n);

  /// If the value at the given index has a metatable, the function pushes that metatable onto the stack and returns&nbsp;1. Otherwise, the function returns&nbsp;0 and pushes nothing on the stack.
  ///
  /// Stack: `[-0, +(0|1), -]`
  ///
  /// C: `int lua_getmetatable (lua_State *L, int index);`
  int getmetatable(int index);

  /// Gets information about the interpreter runtime stack. This function fills parts of a lua_Debug structure with an identification of the activation record of the function executing at a given level. Level&nbsp;0 is the current running function, whereas level n+1 is the function that has called level n (except for tail calls, which do not count in the stack). When called with a level greater than the stack depth, lua_getstack returns 0; otherwise it returns 1.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_getstack (lua_State *L, int level, lua_Debug *ar);`
  int getstack(int level, ffi.Pointer<ffi.Void> ar);

  /// Pushes onto the stack the value t[k], where t is the value at the given index and k is the value on the top of the stack. This function pops the key from the stack, pushing the resulting value in its place. As in Lua, this function may trigger a metamethod for the "index" event (see §2.4). Returns the type of the pushed value.
  ///
  /// Stack: `[-1, +1, e]`
  ///
  /// C: `int lua_gettable (lua_State *L, int index);`
  int gettable(int index);

  /// Returns the index of the top element in the stack. Because indices start at&nbsp;1, this result is equal to the number of elements in the stack; in particular, 0&nbsp;means an empty stack.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_gettop (lua_State *L);`
  int gettop();

  /// Gets information about the n-th upvalue of the closure at index funcindex. It pushes the upvalue's value onto the stack and returns its name. Returns NULL (and pushes nothing) when the index n is greater than the number of upvalues. See debug.getupvalue for more information about upvalues.
  ///
  /// Stack: `[-0, +(0|1), -]`
  ///
  /// C: `const char *lua_getupvalue (lua_State *L, int funcindex, int n);`
  ffi.Pointer<ffi.Void> getupvalue(int funcindex, int n);

  /// Moves the top element into the given valid index, shifting up the elements above this index to open space. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
  ///
  /// Stack: `[-1, +1, -]`
  ///
  /// C: `void lua_insert (lua_State *L, int index);`
  void insert(int index);

  /// Returns 1 if the value at the given index is a boolean, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isboolean (lua_State *L, int index);`
  int isboolean(int index);

  /// Returns 1 if the value at the given index is a C&nbsp;function, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_iscfunction (lua_State *L, int index);`
  int iscfunction(int index);

  /// Returns 1 if the value at the given index is a function (either C or Lua), and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isfunction (lua_State *L, int index);`
  int isfunction(int index);

  /// Returns 1 if the value at the given index is an integer (that is, the value is a number and is represented as an integer), and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isinteger (lua_State *L, int index);`
  int isinteger(int index);

  /// Returns 1 if the value at the given index is a light userdata, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_islightuserdata (lua_State *L, int index);`
  int islightuserdata(int index);

  /// Returns 1 if the value at the given index is nil, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isnil (lua_State *L, int index);`
  int isnil(int index);

  /// Returns 1 if the given index is not valid, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isnone (lua_State *L, int index);`
  int isnone(int index);

  /// Returns 1 if the given index is not valid or if the value at this index is nil, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isnoneornil (lua_State *L, int index);`
  int isnoneornil(int index);

  /// Returns 1 if the value at the given index is a number or a string convertible to a number, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isnumber (lua_State *L, int index);`
  int isnumber(int index);

  /// Returns 1 if the value at the given index is a string or a number (which is always convertible to a string), and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isstring (lua_State *L, int index);`
  int isstring(int index);

  /// Returns 1 if the value at the given index is a table, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_istable (lua_State *L, int index);`
  int istable(int index);

  /// Returns 1 if the value at the given index is a thread, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isthread (lua_State *L, int index);`
  int isthread(int index);

  /// Returns 1 if the value at the given index is a userdata (either full or light), and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isuserdata (lua_State *L, int index);`
  int isuserdata(int index);

  /// Returns 1 if the given coroutine can yield, and 0&nbsp;otherwise.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_isyieldable (lua_State *L);`
  int isyieldable();

  /// Returns the length of the value at the given index. It is equivalent to the '#' operator in Lua (see §3.4.7) and may trigger a metamethod for the "length" event (see §2.4). The result is pushed on the stack.
  ///
  /// Stack: `[-0, +1, e]`
  ///
  /// C: `void lua_len (lua_State *L, int index);`
  void len(int index);

  /// Loads a Lua chunk without running it. If there are no errors, lua_load pushes the compiled chunk as a Lua function on top of the stack. Otherwise, it pushes an error message. The lua_load function uses a user-supplied reader function to read the chunk (see lua_Reader). The data argument is an opaque value passed to the reader function. The chunkname argument gives a name to the chunk, which is used for error messages and in debug information (see §4.7). lua_load automatically detects whether the chunk is text or binary and loads it accordingly (see program luac). The string mode works as in function load, with the addition that a NULL value is equivalent to the string "bt". Moreover, it may have a 'B' instead of a 'b', meaning a fixed buffer with the binary dump. A fixed buffer means that the address returned by the reader function will contain the chunk until everything created by the chunk has been collected; therefore, Lua can avoid copying to internal structures some parts of the chunk. (In general, a fixed buffer would keep its contents until the end of the program, for instance with the chunk in ROM.) Moreover, for a fixed buffer, the reader function should return the entire chunk in the first read. (As an example, luaL_loadbufferx does that, which means that you can use it to load fixed buffers.) The function lua_load fully preserves the Lua stack through the calls to the reader function, except that it may push some values for internal use before the first call, and it restores the stack size to its original size plus one (for the pushed result) after the last call. lua_load can return LUA_OK, LUA_ERRSYNTAX, or LUA_ERRMEM. The function may also return other values corresponding to errors raised by the read function (see §4.4.1). If the resulting function has upvalues, its first upvalue is set to the value of the global environment stored at index LUA_RIDX_GLOBALS in the registry (see §4.3). When loading main chunks, this upvalue will be the _ENV variable (see §2.2). Other upvalues are initialized with nil.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int lua_load (lua_State *L, lua_Reader reader, void *data, const char *chunkname, const char *mode);`
  int load(ffi.Pointer<ffi.NativeFunction> reader, ffi.Pointer<ffi.Void> data, ffi.Pointer<ffi.Void> chunkname, ffi.Pointer<ffi.Void> mode);

  /// Creates a new independent state and returns its main thread. Returns NULL if it cannot create the state (due to lack of memory). The argument f is the allocator function; Lua will do all memory allocation for this state through this function (see lua_Alloc). The second argument, ud, is an opaque pointer that Lua passes to the allocator in every call. The third argument, seed, is a seed for the hashing of strings.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_State *lua_newstate (lua_Alloc f, void *ud, unsigned int seed);`
  ffi.Pointer<ffi.Void> newstate(ffi.Pointer<ffi.NativeFunction> f, ffi.Pointer<ffi.Void> ud, int seed);

  /// Creates a new empty table and pushes it onto the stack. It is equivalent to lua_createtable(L,0,0).
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `void lua_newtable (lua_State *L);`
  void newtable();

  /// Creates a new thread, pushes it on the stack, and returns a pointer to a lua_State that represents this new thread. The new thread returned by this function shares with the original thread its global environment, but has an independent execution stack. Threads are subject to garbage collection, like any Lua object.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `lua_State *lua_newthread (lua_State *L);`
  ffi.Pointer<ffi.Void> newthread();

  /// This function creates and pushes on the stack a new full userdata, with nuvalue associated Lua values, called user values, plus an associated block of raw memory with size bytes. (The user values can be set and read with the functions lua_setiuservalue and lua_getiuservalue.) The function returns the address of the block of memory. Lua ensures that this address is valid as long as the corresponding userdata is alive (see §2.5). Moreover, if the userdata is marked for finalization (see §2.5.3), its address is valid at least until the call to its finalizer.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `void *lua_newuserdatauv (lua_State *L, size_t size, int nuvalue);`
  ffi.Pointer<ffi.Void> newuserdatauv(int size, int nuvalue);

  /// Pops a key from the stack, and pushes a key-value pair from the table at the given index, the "next" pair after the given key. If there are no more elements in the table, then lua_next returns&nbsp;0 and pushes nothing. A typical table traversal looks like this: /* table is in the stack at index 't' */ lua_pushnil(L); /* first key */ while (lua_next(L, t) != 0) { /* uses 'key' (at index -2) and 'value' (at index -1) */ printf("%s - %s\n", lua_typename(L, lua_type(L, -2)), lua_typename(L, lua_type(L, -1))); /* removes 'value'; keeps 'key' for next iteration */ lua_pop(L, 1); } While traversing a table, avoid calling lua_tolstring directly on a key, unless you know that the key is actually a string. Recall that lua_tolstring may change the value at the given index; this confuses the next call to lua_next. This function may raise an error if the given key is neither nil nor present in the table. See function next for the caveats of modifying the table during its traversal.
  ///
  /// Stack: `[-1, +(2|0), v]`
  ///
  /// C: `int lua_next (lua_State *L, int index);`
  int next(int index);

  /// Converts the number at acceptable index idx to a string and puts the result in buff. The buffer must have a size of at least LUA_N2SBUFFSZ bytes. The conversion follows a non-specified format (see §3.4.3). The function returns the number of bytes written to the buffer (including the final zero), or zero if the value at idx is not a number.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `unsigned lua_numbertocstring (lua_State *L, int idx, char *buff);`
  int numbertocstring(int idx, ffi.Pointer<ffi.Void> buff);

  /// Tries to convert a Lua float to a Lua integer; the float n must have an integral value. If that value is within the range of Lua integers, it is converted to an integer and assigned to *p. The macro results in a boolean indicating whether the conversion was successful. (Note that this range test can be tricky to do correctly without this macro, due to rounding.) This macro may evaluate its arguments more than once.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_numbertointeger (lua_Number n, lua_Integer *p);`
  int numbertointeger(double n, ffi.Pointer<ffi.Void> p);

  /// Calls a function (or a callable object) in protected mode. Both nargs and nresults have the same meaning as in lua_call. If there are no errors during the call, lua_pcall behaves exactly like lua_call. However, if there is any error, lua_pcall catches it, pushes a single value on the stack (the error object), and returns an error code. Like lua_call, lua_pcall always removes the function and its arguments from the stack. If msgh is 0, then the error object returned on the stack is exactly the original error object. Otherwise, msgh is the stack index of a message handler. (This index cannot be a pseudo-index.) In case of runtime errors, this handler will be called with the error object and its return value will be the object returned on the stack by lua_pcall. Typically, the message handler is used to add more debug information to the error object, such as a stack traceback. Such information cannot be gathered after the return of lua_pcall, since by then the stack has unwound. The lua_pcall function returns one of the following status codes: LUA_OK, LUA_ERRRUN, LUA_ERRMEM, or LUA_ERRERR.
  ///
  /// Stack: `[-(nargs + 1), +(nresults|1), -]`
  ///
  /// C: `int lua_pcall (lua_State *L, int nargs, int nresults, int msgh);`
  int pcall(int nargs, int nresults, int msgh);

  /// This function behaves exactly like lua_pcall, except that it allows the called function to yield (see §4.5).
  ///
  /// Stack: `[-(nargs + 1), +(nresults|1), -]`
  ///
  /// C: `int lua_pcallk (lua_State *L, int nargs, int nresults, int msgh, lua_KContext ctx, lua_KFunction k);`
  int pcallk(int nargs, int nresults, int msgh, int ctx, ffi.Pointer<ffi.NativeFunction> k);

  /// Pops n elements from the stack. It is implemented as a macro over lua_settop.
  ///
  /// Stack: `[-n, +0, e]`
  ///
  /// C: `void lua_pop (lua_State *L, int n);`
  void pop(int n);

  /// Pushes a boolean value with value b onto the stack.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushboolean (lua_State *L, int b);`
  void pushboolean(int b);

  /// Pushes a new C&nbsp;closure onto the stack. This function receives a pointer to a C&nbsp;function and pushes onto the stack a Lua value of type function that, when called, invokes the corresponding C&nbsp;function. The parameter n tells how many upvalues this function will have (see §4.2). Any function to be callable by Lua must follow the correct protocol to receive its parameters and return its results (see lua_CFunction). When a C&nbsp;function is created, it is possible to associate some values with it, the so called upvalues; these upvalues are then accessible to the function whenever it is called. This association is called a C&nbsp;closure (see §4.2). To create a C&nbsp;closure, first the initial values for its upvalues must be pushed onto the stack. (When there are multiple upvalues, the first value is pushed first.) Then lua_pushcclosure is called to create and push the C&nbsp;function onto the stack, with the argument n telling how many values will be associated with the function. lua_pushcclosure also pops these values from the stack. The maximum value for n is 255. When n is zero, this function creates a light C&nbsp;function, which is just a pointer to the C&nbsp;function. In that case, it never raises a memory error.
  ///
  /// Stack: `[-n, +1, m]`
  ///
  /// C: `void lua_pushcclosure (lua_State *L, lua_CFunction fn, int n);`
  void pushcclosure(ffi.Pointer<ffi.NativeFunction> fn, int n);

  /// Pushes a C&nbsp;function onto the stack. This function is equivalent to lua_pushcclosure with no upvalues.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushcfunction (lua_State *L, lua_CFunction f);`
  void pushcfunction(ffi.Pointer<ffi.NativeFunction> f);

  /// Creates an external string, that is, a string that uses memory not managed by Lua. The pointer s points to the external buffer holding the string content, and len is the length of the string. The string should have a zero at its end, that is, the condition s[len] == '\0' should hold. As with any string in Lua, the length must fit in a Lua integer. If falloc is different from NULL, that function will be called by Lua when the external buffer is no longer needed. The contents of the buffer should not change before this call. The function will be called with the given ud, the string s as the block, the length plus one (to account for the ending zero) as the old size, and 0 as the new size. Even when using an external buffer, Lua still has to allocate a header for the string. In case of a memory-allocation error, Lua will call falloc before raising the error. The function returns a pointer to the string (that is, s).
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `const char *lua_pushexternalstring (lua_State *L, const char *s, size_t len, lua_Alloc falloc, void *ud);`
  ffi.Pointer<ffi.Void> pushexternalstring(ffi.Pointer<ffi.Void> s, int len, ffi.Pointer<ffi.NativeFunction> falloc, ffi.Pointer<ffi.Void> ud);

  /// Pushes onto the stack a formatted string and returns a pointer to this string (see §4.1.3). The result is a copy of fmt with each conversion specifier replaced by a string representation of its respective extra argument. A conversion specifier (and its corresponding extra argument) can be '%%' (inserts the character '%'), '%s' (inserts a zero-terminated string, with no size restrictions), '%f' (inserts a lua_Number), '%I' (inserts a lua_Integer), '%p' (inserts a void pointer), '%d' (inserts an int), '%c' (inserts an int as a one-byte character), and '%U' (inserts an unsigned long as a UTF-8 byte sequence). Every occurrence of '%' in the string fmt must form a valid conversion specifier. Besides memory allocation errors, this function may raise an error if the resulting string is too large.
  ///
  /// Stack: `[-0, +1, v]`
  ///
  /// C: `const char *lua_pushfstring (lua_State *L, const char *fmt, ...);`
  ffi.Pointer<ffi.Void> pushfstring(ffi.Pointer<ffi.Void> fmt);

  /// Pushes the global environment onto the stack.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushglobaltable (lua_State *L);`
  void pushglobaltable();

  /// Pushes an integer with value n onto the stack.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushinteger (lua_State *L, lua_Integer n);`
  void pushinteger(int n);

  /// Pushes a light userdata onto the stack. Userdata represent C&nbsp;values in Lua. A light userdata represents a pointer, a void*. It is a value (like a number): you do not create it, it has no individual metatable, and it is not collected (as it was never created). A light userdata is equal to "any" light userdata with the same C&nbsp;address.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushlightuserdata (lua_State *L, void *p);`
  void pushlightuserdata(ffi.Pointer<ffi.Void> p);

  /// This macro is equivalent to lua_pushstring, but should be used only when s is a literal string. (Lua may optimize this case.)
  ///
  /// Stack: `[-0, +1, v]`
  ///
  /// C: `const char *lua_pushliteral (lua_State *L, const char *s);`
  ffi.Pointer<ffi.Void> pushliteral(ffi.Pointer<ffi.Void> s);

  /// Pushes the string pointed to by s with size len onto the stack. Lua will make or reuse an internal copy of the given string, so the memory at s can be freed or reused immediately after the function returns. The string can contain any binary data, including embedded zeros. Returns a pointer to the internal copy of the string (see §4.1.3). Besides memory allocation errors, this function may raise an error if the string is too large.
  ///
  /// Stack: `[-0, +1, v]`
  ///
  /// C: `const char *lua_pushlstring (lua_State *L, const char *s, size_t len);`
  ffi.Pointer<ffi.Void> pushlstring(ffi.Pointer<ffi.Void> s, int len);

  /// Pushes a nil value onto the stack.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushnil (lua_State *L);`
  void pushnil();

  /// Pushes a float with value n onto the stack.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushnumber (lua_State *L, lua_Number n);`
  void pushnumber(double n);

  /// Pushes the zero-terminated string pointed to by s onto the stack. Lua will make or reuse an internal copy of the given string, so the memory at s can be freed or reused immediately after the function returns. Returns a pointer to the internal copy of the string (see §4.1.3). If s is NULL, pushes nil and returns NULL.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `const char *lua_pushstring (lua_State *L, const char *s);`
  ffi.Pointer<ffi.Void> pushstring(ffi.Pointer<ffi.Void> s);

  /// Pushes the thread represented by L onto the stack. Returns 1 if this thread is the main thread of its state.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int lua_pushthread (lua_State *L);`
  int pushthread();

  /// Pushes a copy of the element at the given index onto the stack.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void lua_pushvalue (lua_State *L, int index);`
  void pushvalue(int index);

  /// Equivalent to lua_pushfstring, except that it receives a va_list instead of a variable number of arguments, and it does not raise errors. Instead, in case of errors it pushes the error message and returns NULL.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `const char *lua_pushvfstring (lua_State *L, const char *fmt, va_list argp);`
  ffi.Pointer<ffi.Void> pushvfstring(ffi.Pointer<ffi.Void> fmt, int argp);

  /// Returns 1 if the two values in indices index1 and index2 are primitively equal (that is, equal without calling the __eq metamethod). Otherwise returns&nbsp;0. Also returns&nbsp;0 if any of the indices are not valid.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_rawequal (lua_State *L, int index1, int index2);`
  int rawequal(int index1, int index2);

  /// Similar to lua_gettable, but does a raw access (i.e., without metamethods). The value at index must be a table.
  ///
  /// Stack: `[-1, +1, -]`
  ///
  /// C: `int lua_rawget (lua_State *L, int index);`
  int rawget(int index);

  /// Pushes onto the stack the value t[n], where t is the table at the given index. The access is raw, that is, it does not use the __index metavalue. Returns the type of the pushed value.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int lua_rawgeti (lua_State *L, int index, lua_Integer n);`
  int rawgeti(int index, int n);

  /// Pushes onto the stack the value t[k], where t is the table at the given index and k is the pointer p represented as a light userdata. The access is raw; that is, it does not use the __index metavalue. Returns the type of the pushed value.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int lua_rawgetp (lua_State *L, int index, const void *p);`
  int rawgetp(int index, ffi.Pointer<ffi.Void> p);

  /// Returns the raw "length" of the value at the given index: for strings, this is the string length; for tables, this is the result of the length operator ('#') with no metamethods; for userdata, this is the size of the block of memory allocated for the userdata. For other values, this call returns&nbsp;0.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Unsigned lua_rawlen (lua_State *L, int index);`
  int rawlen(int index);

  /// Similar to lua_settable, but does a raw assignment (i.e., without metamethods). The value at index must be a table.
  ///
  /// Stack: `[-2, +0, m]`
  ///
  /// C: `void lua_rawset (lua_State *L, int index);`
  void rawset(int index);

  /// Does the equivalent of t[i] = v, where t is the table at the given index and v is the value on the top of the stack. This function pops the value from the stack. The assignment is raw, that is, it does not use the __newindex metavalue.
  ///
  /// Stack: `[-1, +0, m]`
  ///
  /// C: `void lua_rawseti (lua_State *L, int index, lua_Integer i);`
  void rawseti(int index, int i);

  /// Does the equivalent of t[p] = v, where t is the table at the given index, p is encoded as a light userdata, and v is the value on the top of the stack. This function pops the value from the stack. The assignment is raw, that is, it does not use the __newindex metavalue.
  ///
  /// Stack: `[-1, +0, m]`
  ///
  /// C: `void lua_rawsetp (lua_State *L, int index, const void *p);`
  void rawsetp(int index, ffi.Pointer<ffi.Void> p);

  /// Sets the C&nbsp;function f as the new value of global name. It is defined as a macro: #define lua_register(L,n,f) \ (lua_pushcfunction(L, f), lua_setglobal(L, n))
  ///
  /// Stack: `[-0, +0, e]`
  ///
  /// C: `void lua_register (lua_State *L, const char *name, lua_CFunction f);`
  void register(ffi.Pointer<ffi.Void> name, ffi.Pointer<ffi.NativeFunction> f);

  /// Removes the element at the given valid index, shifting down the elements above this index to fill the gap. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
  ///
  /// Stack: `[-1, +0, -]`
  ///
  /// C: `void lua_remove (lua_State *L, int index);`
  void remove(int index);

  /// Moves the top element into the given valid index without shifting any element (therefore replacing the value at that given index), and then pops the top element.
  ///
  /// Stack: `[-1, +0, -]`
  ///
  /// C: `void lua_replace (lua_State *L, int index);`
  void replace(int index);

  /// Starts and resumes a coroutine in the given thread L. To start a coroutine, you push the main function plus any arguments onto the empty stack of the thread. then you call lua_resume, with nargs being the number of arguments. The function returns when the coroutine suspends, finishes its execution, or raises an unprotected error. When it returns without errors, *nresults is updated and the top of the stack contains the *nresults values passed to lua_yield or returned by the body function. lua_resume returns LUA_YIELD if the coroutine yields, LUA_OK if the coroutine finishes its execution without errors, or an error code in case of errors (see §4.4.1). In case of errors, the error object is pushed on the top of the stack. (In that case, nresults is not updated, as its value would have to be 1 for the sole error object.) To resume a suspended coroutine, you remove the *nresults yielded values from its stack, push the values to be passed as results from yield, and then call lua_resume. The parameter from represents the coroutine that is resuming L. If there is no such coroutine, this parameter can be NULL.
  ///
  /// Stack: `[-?, +?, -]`
  ///
  /// C: `int lua_resume (lua_State *L, lua_State *from, int nargs, int *nresults);`
  int resume(ffi.Pointer<ffi.Void> from_, int nargs, ffi.Pointer<ffi.Void> nresults);

  /// Rotates the stack elements between the valid index idx and the top of the stack. The elements are rotated n positions in the direction of the top, for a positive n, or -n positions in the direction of the bottom, for a negative n. The absolute value of n must not be greater than the size of the slice being rotated. This function cannot be called with a pseudo-index, because a pseudo-index is not an actual stack position.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_rotate (lua_State *L, int idx, int n);`
  void rotate(int idx, int n);

  /// Changes the allocator function of a given state to f with user data ud.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);`
  void setallocf(ffi.Pointer<ffi.NativeFunction> f, ffi.Pointer<ffi.Void> ud);

  /// Does the equivalent to t[k] = v, where t is the value at the given index and v is the value on the top of the stack. This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see §2.4).
  ///
  /// Stack: `[-1, +0, e]`
  ///
  /// C: `void lua_setfield (lua_State *L, int index, const char *k);`
  void setfield(int index, ffi.Pointer<ffi.Void> k);

  /// Pops a value from the stack and sets it as the new value of global name.
  ///
  /// Stack: `[-1, +0, e]`
  ///
  /// C: `void lua_setglobal (lua_State *L, const char *name);`
  void setglobal(ffi.Pointer<ffi.Void> name);

  /// Sets the debugging hook function. Argument f is the hook function. mask specifies on which events the hook will be called: it is formed by a bitwise OR of the constants LUA_MASKCALL, LUA_MASKRET, LUA_MASKLINE, and LUA_MASKCOUNT. The count argument is only meaningful when the mask includes LUA_MASKCOUNT. For each event, the hook is called as explained below: The call hook: is called when the interpreter calls a function. The hook is called just after Lua enters the new function. The return hook: is called when the interpreter returns from a function. The hook is called just before Lua leaves the function. The line hook: is called when the interpreter is about to start the execution of a new line of code, or when it jumps back in the code (even to the same line). This event only happens while Lua is executing a Lua function. The count hook: is called after the interpreter executes every count instructions. This event only happens while Lua is executing a Lua function. Hooks are disabled by setting mask to zero.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_sethook (lua_State *L, lua_Hook f, int mask, int count);`
  void sethook(ffi.Pointer<ffi.NativeFunction> f, int mask, int count);

  /// Does the equivalent to t[n] = v, where t is the value at the given index and v is the value on the top of the stack. This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see §2.4).
  ///
  /// Stack: `[-1, +0, e]`
  ///
  /// C: `void lua_seti (lua_State *L, int index, lua_Integer n);`
  void seti(int index, int n);

  /// Pops a value from the stack and sets it as the new n-th user value associated to the full userdata at the given index. Returns 0 if the userdata does not have that value.
  ///
  /// Stack: `[-1, +0, -]`
  ///
  /// C: `int lua_setiuservalue (lua_State *L, int index, int n);`
  int setiuservalue(int index, int n);

  /// Sets the value of a local variable of a given activation record. It assigns the value on the top of the stack to the variable and returns its name. It also pops the value from the stack. Returns NULL (and pops nothing) when the index is greater than the number of active local variables. Parameters ar and n are as in the function lua_getlocal.
  ///
  /// Stack: `[-(0|1), +0, -]`
  ///
  /// C: `const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);`
  ffi.Pointer<ffi.Void> setlocal(ffi.Pointer<ffi.Void> ar, int n);

  /// Pops a table or nil from the stack and sets that value as the new metatable for the value at the given index. (nil means no metatable.) (For historical reasons, this function returns an int, which now is always 1.)
  ///
  /// Stack: `[-1, +0, -]`
  ///
  /// C: `int lua_setmetatable (lua_State *L, int index);`
  int setmetatable(int index);

  /// Does the equivalent to t[k] = v, where t is the value at the given index, v is the value on the top of the stack, and k is the value just below the top. This function pops both the key and the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see §2.4).
  ///
  /// Stack: `[-2, +0, e]`
  ///
  /// C: `void lua_settable (lua_State *L, int index);`
  void settable(int index);

  /// Receives any acceptable stack index, or&nbsp;0, and sets the stack top to this index. If the new top is greater than the old one, then the new elements are filled with nil. If index is&nbsp;0, then all stack elements are removed. This function can run arbitrary code when removing an index marked as to-be-closed from the stack.
  ///
  /// Stack: `[-?, +?, e]`
  ///
  /// C: `void lua_settop (lua_State *L, int index);`
  void settop(int index);

  /// Sets the value of a closure's upvalue. It assigns the value on the top of the stack to the upvalue and returns its name. It also pops the value from the stack. Returns NULL (and pops nothing) when the index n is greater than the number of upvalues. Parameters funcindex and n are as in the function lua_getupvalue.
  ///
  /// Stack: `[-(0|1), +0, -]`
  ///
  /// C: `const char *lua_setupvalue (lua_State *L, int funcindex, int n);`
  ffi.Pointer<ffi.Void> setupvalue(int funcindex, int n);

  /// Sets the warning function to be used by Lua to emit warnings (see lua_WarnFunction). The ud parameter sets the value ud passed to the warning function.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_setwarnf (lua_State *L, lua_WarnFunction f, void *ud);`
  void setwarnf(int f, ffi.Pointer<ffi.Void> ud);

  /// Returns the status of the thread L. The status can be LUA_OK for a normal thread, an error code if the thread finished the execution of a lua_resume with an error, or LUA_YIELD if the thread is suspended. You can call functions only in threads with status LUA_OK. You can resume threads with status LUA_OK (to start a new coroutine) or LUA_YIELD (to resume a coroutine).
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_status (lua_State *L);`
  int status();

  /// Converts the zero-terminated string s to a number, pushes that number into the stack, and returns the total size of the string, that is, its length plus one. The conversion can result in an integer or a float, according to the lexical conventions of Lua (see §3.1). The string may have leading and trailing whitespaces and a sign. If the string is not a valid numeral, returns 0 and pushes nothing. (Note that the result can be used as a boolean, true if the conversion succeeds.)
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `size_t lua_stringtonumber (lua_State *L, const char *s);`
  int stringtonumber(ffi.Pointer<ffi.Void> s);

  /// Converts the Lua value at the given index to a C&nbsp;boolean value (0&nbsp;or&nbsp;1). Like all tests in Lua, lua_toboolean returns true for any Lua value different from false and nil; otherwise it returns false. (If you want to accept only actual boolean values, use lua_isboolean to test the value's type.)
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_toboolean (lua_State *L, int index);`
  int toboolean(int index);

  /// Converts a value at the given index to a C&nbsp;function. That value must be a C&nbsp;function; otherwise, returns NULL.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_CFunction lua_tocfunction (lua_State *L, int index);`
  ffi.Pointer<ffi.NativeFunction> tocfunction(int index);

  /// Marks the given index in the stack as a to-be-closed slot (see §3.3.8). Like a to-be-closed variable in Lua, the value at that slot in the stack will be closed when it goes out of scope. Here, in the context of a C function, to go out of scope means that the running function returns to Lua, or there is an error, or the slot is removed from the stack through lua_settop or lua_pop, or there is a call to lua_closeslot. A slot marked as to-be-closed should not be removed from the stack by any other function in the API except lua_settop or lua_pop, unless previously deactivated by lua_closeslot. This function raises an error if the value at the given slot neither has a __close metamethod nor is a false value. This function should not be called for an index that is equal to or below an active to-be-closed slot. Note that, both in case of errors and of a regular return, by the time the __close metamethod runs, the C&nbsp;stack was already unwound, so that any automatic C&nbsp;variable declared in the calling function (e.g., a buffer) will be out of scope.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void lua_toclose (lua_State *L, int index);`
  void toclose(int index);

  /// Equivalent to lua_tointegerx with isnum equal to NULL.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Integer lua_tointeger (lua_State *L, int index);`
  int tointeger(int index);

  /// Converts the Lua value at the given index to the signed integral type lua_Integer. The Lua value must be an integer, or a number or string convertible to an integer (see §3.4.3); otherwise, lua_tointegerx returns&nbsp;0. If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Integer lua_tointegerx (lua_State *L, int index, int *isnum);`
  int tointegerx(int index, ffi.Pointer<ffi.Void> isnum);

  /// Converts the Lua value at the given index to a C&nbsp;string. The Lua value must be a string or a number; otherwise, the function returns NULL. If the value is a number, then lua_tolstring also changes the actual value in the stack to a string. (This change confuses lua_next when lua_tolstring is applied to keys during a table traversal.) If len is not NULL, the function sets *len with the string length. The returned C&nbsp;string always has a zero ('\0') after its last character, but can contain other zeros in its body. The pointer returned by lua_tolstring may be invalidated by the garbage collector if the corresponding Lua value is removed from the stack (see §4.1.3). This function can raise memory errors only when converting a number to a string (as then it may create a new string).
  ///
  /// Stack: `[-0, +0, m]`
  ///
  /// C: `const char *lua_tolstring (lua_State *L, int index, size_t *len);`
  ffi.Pointer<ffi.Void> tolstring(int index, ffi.Pointer<ffi.Void> len);

  /// Equivalent to lua_tonumberx with isnum equal to NULL.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Number lua_tonumber (lua_State *L, int index);`
  double tonumber(int index);

  /// Converts the Lua value at the given index to the C&nbsp;type lua_Number (see lua_Number). The Lua value must be a number or a string convertible to a number (see §3.4.3); otherwise, lua_tonumberx returns&nbsp;0. If isnum is not NULL, its referent is assigned a boolean value that indicates whether the operation succeeded.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Number lua_tonumberx (lua_State *L, int index, int *isnum);`
  double tonumberx(int index, ffi.Pointer<ffi.Void> isnum);

  /// Converts the value at the given index to a generic C&nbsp;pointer (void*). The value can be a userdata, a table, a thread, a string, or a function; otherwise, lua_topointer returns NULL. Different objects will give different pointers. There is no way to convert the pointer back to its original value. Typically this function is used only for hashing and debug information.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `const void *lua_topointer (lua_State *L, int index);`
  ffi.Pointer<ffi.Void> topointer(int index);

  /// Equivalent to lua_tolstring with len equal to NULL.
  ///
  /// Stack: `[-0, +0, m]`
  ///
  /// C: `const char *lua_tostring (lua_State *L, int index);`
  ffi.Pointer<ffi.Void> tostring(int index);

  /// Converts the value at the given index to a Lua thread (represented as lua_State*). This value must be a thread; otherwise, the function returns NULL.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_State *lua_tothread (lua_State *L, int index);`
  ffi.Pointer<ffi.Void> tothread(int index);

  /// If the value at the given index is a full userdata, returns its memory-block address. If the value is a light userdata, returns its value (a pointer). Otherwise, returns NULL.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void *lua_touserdata (lua_State *L, int index);`
  ffi.Pointer<ffi.Void> touserdata(int index);

  /// Returns the type of the value in the given valid index, or LUA_TNONE for a non-valid but acceptable index. The types returned by lua_type are coded by the following constants defined in lua.h: LUA_TNIL, LUA_TNUMBER, LUA_TBOOLEAN, LUA_TSTRING, LUA_TTABLE, LUA_TFUNCTION, LUA_TUSERDATA, LUA_TTHREAD, and LUA_TLIGHTUSERDATA.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_type (lua_State *L, int index);`
  int type(int index);

  /// Returns the name of the type encoded by the value tp, which must be one the values returned by lua_type.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `const char *lua_typename (lua_State *L, int tp);`
  ffi.Pointer<ffi.Void> typename(int tp);

  /// Returns a unique identifier for the upvalue numbered n from the closure at index funcindex. These unique identifiers allow a program to check whether different closures share upvalues. Lua closures that share an upvalue (that is, that access a same external local variable) will return identical ids for those upvalue indices. Parameters funcindex and n are as in the function lua_getupvalue, but n cannot be greater than the number of upvalues.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void *lua_upvalueid (lua_State *L, int funcindex, int n);`
  ffi.Pointer<ffi.Void> upvalueid(int funcindex, int n);

  /// Returns the pseudo-index that represents the i-th upvalue of the running function (see §4.2). i must be in the range [1,256].
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `int lua_upvalueindex (int i);`
  int upvalueindex(int i);

  /// Make the n1-th upvalue of the Lua closure at index funcindex1 refer to the n2-th upvalue of the Lua closure at index funcindex2. 5 - The Auxiliary Library The auxiliary library provides several convenient functions to interface C with Lua. While the basic API provides the primitive functions for all interactions between C and Lua, the auxiliary library provides higher-level functions for some common tasks. All functions and types from the auxiliary library are defined in the header file lauxlib.h and have a prefix luaL_. All functions in the auxiliary library are built on top of the basic API, and so they provide nothing that cannot be done with that API. Nevertheless, the use of the auxiliary library ensures more consistency to your code. Several functions in the auxiliary library use internally some extra stack slots. When a function in the auxiliary library uses less than five slots, it does not check the stack size; it simply assumes that there are enough slots. Several functions in the auxiliary library are used to check C&nbsp;function arguments. Because the error message is formatted for arguments (e.g., "bad argument #1"), you should not use these functions for other stack values. Functions called luaL_check* always raise an error if the check is not satisfied. 5.1 - Functions and Types Here we list all functions and types from the auxiliary library in alphabetical order.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_upvaluejoin (lua_State *L, int funcindex1, int n1, int funcindex2, int n2);`
  void upvaluejoin(int funcindex1, int n1, int funcindex2, int n2);

  /// Returns the version number of this core.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_Number lua_version (lua_State *L);`
  double version();

  /// Emits a warning with the given message. A message in a call with tocont true should be continued in another call to this function. See warn for more details about warnings.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void lua_warning (lua_State *L, const char *msg, int tocont);`
  void warning(ffi.Pointer<ffi.Void> msg, int tocont);

  /// Exchange values between different threads of the same state. This function pops n values from the stack from, and pushes them onto the stack to.
  ///
  /// Stack: `[-?, +?, -]`
  ///
  /// C: `void lua_xmove (lua_State *from, lua_State *to, int n);`
  void xmove(ffi.Pointer<ffi.Void> from_, ffi.Pointer<ffi.Void> to_, int n);

  /// This function is equivalent to lua_yieldk, but it has no continuation (see §4.5). Therefore, when the thread resumes, it continues the function that called the function calling lua_yield. To avoid surprises, this function should be called only in a tail call.
  ///
  /// Stack: `[-?, +?, v]`
  ///
  /// C: `int lua_yield (lua_State *L, int nresults);`
  int yield(int nresults);

  /// Yields a coroutine (thread). When a C&nbsp;function calls lua_yieldk, the running coroutine suspends its execution, and the call to lua_resume that started this coroutine returns. The parameter nresults is the number of values from the stack that will be passed as results to lua_resume. When the coroutine is resumed again, Lua calls the given continuation function k to continue the execution of the C&nbsp;function that yielded (see §4.5). This continuation function receives the same stack from the previous function, with the n results removed and replaced by the arguments passed to lua_resume. Moreover, the continuation function receives the value ctx that was passed to lua_yieldk. Usually, this function does not return; when the coroutine eventually resumes, it continues executing the continuation function. However, there is one special case, which is when this function is called from inside a line or a count hook (see §4.7). In that case, lua_yieldk should be called with no continuation (probably in the form of lua_yield) and no results, and the hook should return immediately after the call. Lua will yield and, when the coroutine resumes again, it will continue the normal execution of the (Lua) function that triggered the hook. This function can raise an error if it is called from a thread with a pending C call with no continuation function (what is called a C-call boundary), or it is called from a thread that is not running inside a resume (typically the main thread). 4.7 - The Debug Interface Lua has no built-in debugging facilities. Instead, it offers a special interface by means of functions and hooks. This interface allows the construction of different kinds of debuggers, profilers, and other tools that need "inside information" from the interpreter.
  ///
  /// Stack: `[-?, +?, v]`
  ///
  /// C: `int lua_yieldk (lua_State *L, int nresults, lua_KContext ctx, lua_KFunction k);`
  int yieldk(int nresults, int ctx, ffi.Pointer<ffi.NativeFunction> k);

}