// AUTO GENERATED FILE by scripts/generate_dart_interfaces.lua
// LuaAuxLib

import 'dart:ffi' as ffi;
import 'types.dart';

abstract interface class LuaAuxLib {
  ffi.Pointer<lua_State> get state;

  /// Adds the byte c to the buffer B (see luaL_Buffer).
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `void luaL_addchar (luaL_Buffer *B, char c);`
  void addchar(ffi.Pointer<ffi.Void> b, int c);

  /// Adds a copy of the string s to the buffer B (see luaL_Buffer), replacing any occurrence of the string p with the string r.
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `const void luaL_addgsub (luaL_Buffer *B, const char *s, const char *p, const char *r);`
  void addgsub(ffi.Pointer<ffi.Void> b, ffi.Pointer<ffi.Void> s, ffi.Pointer<ffi.Void> p, ffi.Pointer<ffi.Void> r);

  /// Adds the string pointed to by s with length l to the buffer B (see luaL_Buffer). The string can contain embedded zeros.
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `void luaL_addlstring (luaL_Buffer *B, const char *s, size_t l);`
  void addlstring(ffi.Pointer<ffi.Void> b, ffi.Pointer<ffi.Void> s, int l);

  /// Adds to the buffer B a string of length n previously copied to the buffer area (see luaL_prepbuffer).
  ///
  /// Stack: `[-?, +?, -]`
  ///
  /// C: `void luaL_addsize (luaL_Buffer *B, size_t n);`
  void addsize(ffi.Pointer<ffi.Void> b, int n);

  /// Adds the zero-terminated string pointed to by s to the buffer B (see luaL_Buffer).
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `void luaL_addstring (luaL_Buffer *B, const char *s);`
  void addstring(ffi.Pointer<ffi.Void> b, ffi.Pointer<ffi.Void> s);

  /// Adds the value on the top of the stack to the buffer B (see luaL_Buffer). Pops the value. This is the only function on string buffers that can (and must) be called with an extra element on the stack, which is the value to be added to the buffer.
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `void luaL_addvalue (luaL_Buffer *B);`
  void addvalue(ffi.Pointer<ffi.Void> b);

  /// A standard allocator function for Lua (see lua_Alloc), built on top of the C functions realloc and free.
  ///
  /// Stack: `[-0, +0, m]`
  ///
  /// C: `void *luaL_alloc (void *ud, void *ptr, size_t osize, size_t nsize);`
  ffi.Pointer<ffi.Void> alloc(ffi.Pointer<ffi.Void> ud, ffi.Pointer<ffi.Void> ptr, int osize, int nsize);

  /// Checks whether cond is true. If it is not, raises an error with a standard message (see luaL_argerror).
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void luaL_argcheck (lua_State *L, int cond, int arg, const char *extramsg);`
  void argcheck(int cond, int arg, ffi.Pointer<ffi.Void> extramsg);

  /// Raises an error reporting a problem with argument arg of the C&nbsp;function that called it, using a standard message that includes extramsg as a comment: bad argument #arg to 'funcname' (extramsg) This function never returns.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `int luaL_argerror (lua_State *L, int arg, const char *extramsg);`
  int argerror(int arg, ffi.Pointer<ffi.Void> extramsg);

  /// Checks whether cond is true. If it is not, raises an error about the type of the argument arg with a standard message (see luaL_typeerror).
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void luaL_argexpected (lua_State *L, int cond, int arg, const char *tname);`
  void argexpected(int cond, int arg, ffi.Pointer<ffi.Void> tname);

  /// Returns the address of the current content of buffer B (see luaL_Buffer). Note that any addition to the buffer may invalidate this address.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `char *luaL_buffaddr (luaL_Buffer *B);`
  ffi.Pointer<ffi.Void> buffaddr(ffi.Pointer<ffi.Void> b);

  /// Initializes a buffer B (see luaL_Buffer). This function does not allocate any space; the buffer must be declared as a variable.
  ///
  /// Stack: `[-0, +?, -]`
  ///
  /// C: `void luaL_buffinit (lua_State *L, luaL_Buffer *B);`
  void buffinit(ffi.Pointer<ffi.Void> b);

  /// Equivalent to the sequence luaL_buffinit, luaL_prepbuffsize.
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `char *luaL_buffinitsize (lua_State *L, luaL_Buffer *B, size_t sz);`
  ffi.Pointer<ffi.Void> buffinitsize(ffi.Pointer<ffi.Void> b, int sz);

  /// Returns the length of the current content of buffer B (see luaL_Buffer).
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `size_t luaL_bufflen (luaL_Buffer *B);`
  int bufflen(ffi.Pointer<ffi.Void> b);

  /// Removes n bytes from the buffer B (see luaL_Buffer). The buffer must have at least that many bytes.
  ///
  /// Stack: `[-?, +?, -]`
  ///
  /// C: `void luaL_buffsub (luaL_Buffer *B, int n);`
  void buffsub(ffi.Pointer<ffi.Void> b, int n);

  /// Calls a metamethod. If the object at index obj has a metatable and this metatable has a field e, this function calls this field passing the object as its only argument. In this case this function returns true and pushes onto the stack the value returned by the call. If there is no metatable or no metamethod, this function returns false without pushing any value on the stack.
  ///
  /// Stack: `[-0, +(0|1), e]`
  ///
  /// C: `int luaL_callmeta (lua_State *L, int obj, const char *e);`
  int callmeta(int obj, ffi.Pointer<ffi.Void> e);

  /// Checks whether the function has an argument of any type (including nil) at position arg.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void luaL_checkany (lua_State *L, int arg);`
  void checkany(int arg);

  /// Checks whether the function argument arg is an integer (or can be converted to an integer) and returns this integer.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `lua_Integer luaL_checkinteger (lua_State *L, int arg);`
  int checkinteger(int arg);

  /// Checks whether the function argument arg is a string and returns this string; if l is not NULL fills its referent with the string's length. This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `const char *luaL_checklstring (lua_State *L, int arg, size_t *l);`
  ffi.Pointer<ffi.Void> checklstring(int arg, ffi.Pointer<ffi.Void> l);

  /// Checks whether the function argument arg is a number and returns this number converted to a lua_Number.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `lua_Number luaL_checknumber (lua_State *L, int arg);`
  double checknumber(int arg);

  /// Checks whether the function argument arg is a string and searches for this string in the array lst (which must be NULL-terminated). Returns the index in the array where the string was found. Raises an error if the argument is not a string or if the string cannot be found. If def is not NULL, the function uses def as a default value when there is no argument arg or when this argument is nil. This is a useful function for mapping strings to C&nbsp;enums. (The usual convention in Lua libraries is to use strings instead of numbers to select options.)
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `int luaL_checkoption (lua_State *L, int arg, const char *def, const char *const lst[]);`
  int checkoption(int arg, ffi.Pointer<ffi.Void> def);

  /// Grows the stack size to top + sz elements, raising an error if the stack cannot grow to that size. msg is an additional text to go into the error message (or NULL for no additional text).
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void luaL_checkstack (lua_State *L, int sz, const char *msg);`
  void checkstack(int sz, ffi.Pointer<ffi.Void> msg);

  /// Checks whether the function argument arg is a string and returns this string. This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `const char *luaL_checkstring (lua_State *L, int arg);`
  ffi.Pointer<ffi.Void> checkstring(int arg);

  /// Checks whether the function argument arg has type t. See lua_type for the encoding of types for t.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void luaL_checktype (lua_State *L, int arg, int t);`
  void checktype(int arg, int t);

  /// Checks whether the function argument arg is a userdata of the type tname (see luaL_newmetatable) and returns the userdata's memory-block address (see lua_touserdata).
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void *luaL_checkudata (lua_State *L, int arg, const char *tname);`
  ffi.Pointer<ffi.Void> checkudata(int arg, ffi.Pointer<ffi.Void> tname);

  /// Checks whether the code making the call and the Lua library being called are using the same version of Lua and the same numeric types.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `void luaL_checkversion (lua_State *L);`
  void checkversion();

  /// Loads and runs the given file. It is defined as the following macro: (luaL_loadfile(L, filename) || lua_pcall(L, 0, LUA_MULTRET, 0)) It returns&nbsp;0 (LUA_OK) if there are no errors, or 1 in case of errors. (Except for out-of-memory errors, which are raised.)
  ///
  /// Stack: `[-0, +?, m]`
  ///
  /// C: `int luaL_dofile (lua_State *L, const char *filename);`
  int dofile(ffi.Pointer<ffi.Void> filename);

  /// Loads and runs the given string. It is defined as the following macro: (luaL_loadstring(L, str) || lua_pcall(L, 0, LUA_MULTRET, 0)) It returns&nbsp;0 (LUA_OK) if there are no errors, or 1 in case of errors.
  ///
  /// Stack: `[-0, +?, -]`
  ///
  /// C: `int luaL_dostring (lua_State *L, const char *str);`
  int dostring(ffi.Pointer<ffi.Void> str);

  /// Raises an error. The error message format is given by fmt plus any extra arguments, following the same rules of lua_pushfstring. It also adds at the beginning of the message the file name and the line number where the error occurred, if this information is available. This function never returns, but it is an idiom to use it in C&nbsp;functions as return luaL_error(args).
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `int luaL_error (lua_State *L, const char *fmt, ...);`
  int error(ffi.Pointer<ffi.Void> fmt);

  /// This function produces the return values for process-related functions in the standard library (os.execute and io.close).
  ///
  /// Stack: `[-0, +3, m]`
  ///
  /// C: `int luaL_execresult (lua_State *L, int stat);`
  int execresult(int stat);

  /// This function produces the return values for file-related functions in the standard library (io.open, os.rename, file:seek, etc.).
  ///
  /// Stack: `[-0, +(1|3), m]`
  ///
  /// C: `int luaL_fileresult (lua_State *L, int stat, const char *fname);`
  int fileresult(int stat, ffi.Pointer<ffi.Void> fname);

  /// Pushes onto the stack the field e from the metatable of the object at index obj and returns the type of the pushed value. If the object does not have a metatable, or if the metatable does not have this field, pushes nothing and returns LUA_TNIL.
  ///
  /// Stack: `[-0, +(0|1), m]`
  ///
  /// C: `int luaL_getmetafield (lua_State *L, int obj, const char *e);`
  int getmetafield(int obj, ffi.Pointer<ffi.Void> e);

  /// Pushes onto the stack the metatable associated with the name tname in the registry (see luaL_newmetatable), or nil if there is no metatable associated with that name. Returns the type of the pushed value.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `int luaL_getmetatable (lua_State *L, const char *tname);`
  int getmetatable(ffi.Pointer<ffi.Void> tname);

  /// Ensures that the value t[fname], where t is the value at index idx, is a table, and pushes that table onto the stack. Returns true if it finds a previous table there and false if it creates a new table.
  ///
  /// Stack: `[-0, +1, e]`
  ///
  /// C: `int luaL_getsubtable (lua_State *L, int idx, const char *fname);`
  int getsubtable(int idx, ffi.Pointer<ffi.Void> fname);

  /// Creates a copy of string s, replacing any occurrence of the string p with the string r. Pushes the resulting string on the stack and returns it.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `const char *luaL_gsub (lua_State *L, const char *s, const char *p, const char *r);`
  ffi.Pointer<ffi.Void> gsub(ffi.Pointer<ffi.Void> s, ffi.Pointer<ffi.Void> p, ffi.Pointer<ffi.Void> r);

  /// Returns the "length" of the value at the given index as a number; it is equivalent to the '#' operator in Lua (see §3.4.7). Raises an error if the result of the operation is not an integer. (This case can only happen through metamethods.)
  ///
  /// Stack: `[-0, +0, e]`
  ///
  /// C: `lua_Integer luaL_len (lua_State *L, int index);`
  int len(int index);

  /// Equivalent to luaL_loadbufferx with mode equal to NULL.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int luaL_loadbuffer (lua_State *L, const char *buff, size_t sz, const char *name);`
  int loadbuffer(ffi.Pointer<ffi.Void> buff, int sz, ffi.Pointer<ffi.Void> name);

  /// Loads a buffer as a Lua chunk. This function uses lua_load to load the chunk in the buffer pointed to by buff with size sz. This function returns the same results as lua_load. name is the chunk name, used for debug information and error messages. The string mode works as in the function lua_load. In particular, this function supports mode 'B' for fixed buffers.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int luaL_loadbufferx (lua_State *L, const char *buff, size_t sz, const char *name, const char *mode);`
  int loadbufferx(ffi.Pointer<ffi.Void> buff, int sz, ffi.Pointer<ffi.Void> name, ffi.Pointer<ffi.Void> mode);

  /// Equivalent to luaL_loadfilex with mode equal to NULL.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `int luaL_loadfile (lua_State *L, const char *filename);`
  int loadfile(ffi.Pointer<ffi.Void> filename);

  /// Loads a file as a Lua chunk. This function uses lua_load to load the chunk in the file named filename. If filename is NULL, then it loads from the standard input. The first line in the file is ignored if it starts with a #. The string mode works as in the function lua_load. This function returns the same results as lua_load, or LUA_ERRFILE for file-related errors. As lua_load, this function only loads the chunk; it does not run it.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `int luaL_loadfilex (lua_State *L, const char *filename, const char *mode);`
  int loadfilex(ffi.Pointer<ffi.Void> filename, ffi.Pointer<ffi.Void> mode);

  /// Loads a string as a Lua chunk. This function uses lua_load to load the chunk in the zero-terminated string s. This function returns the same results as lua_load. Also as lua_load, this function only loads the chunk; it does not run it.
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `int luaL_loadstring (lua_State *L, const char *s);`
  int loadstring(ffi.Pointer<ffi.Void> s);

  /// Returns a value with a weak attempt for randomness. The parameter L can be NULL if there is no Lua state available.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `unsigned int luaL_makeseed (lua_State *L);`
  int makeseed();

  /// Creates a new table and registers there the functions in the list l. It is implemented as the following macro: (luaL_newlibtable(L,l), luaL_setfuncs(L,l,0)) The array l must be the actual array, not a pointer to it.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `void luaL_newlib (lua_State *L, const luaL_Reg l[]);`
  void newlib();

  /// Creates a new table with a size optimized to store all entries in the array l (but does not actually store them). It is intended to be used in conjunction with luaL_setfuncs (see luaL_newlib). It is implemented as a macro. The array l must be the actual array, not a pointer to it.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `void luaL_newlibtable (lua_State *L, const luaL_Reg l[]);`
  void newlibtable();

  /// If the registry already has the key tname, returns 0. Otherwise, creates a new table to be used as a metatable for userdata, adds to this new table the pair __name = tname, adds to the registry the pair [tname] = new table, and returns 1. In both cases, the function pushes onto the stack the final value associated with tname in the registry.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `int luaL_newmetatable (lua_State *L, const char *tname);`
  int newmetatable(ffi.Pointer<ffi.Void> tname);

  /// Creates a new Lua state. It calls lua_newstate with luaL_alloc as the allocator function and the result of luaL_makeseed(NULL) as the seed, and then sets a warning function and a panic function (see §4.4) that print messages to the standard error output. Returns the new state, or NULL if there is a memory allocation error.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `lua_State *luaL_newstate (void);`
  ffi.Pointer<ffi.Void> newstate();

  /// Opens all standard Lua libraries into the given state.
  ///
  /// Stack: `[-0, +0, e]`
  ///
  /// C: `void luaL_openlibs (lua_State *L);`
  void openlibs();

  /// Opens (loads) and preloads selected standard libraries into the state L. (To preload means to add the library loader into the table package.preload, so that the library can be required later by the program. Keep in mind that require itself is provided by the package library. If a program does not load that library, it will be unable to require anything.) The integer load selects which libraries to load; the integer preload selects which to preload, among those not loaded. Both are masks formed by a bitwise OR of the following constants: LUA_GLIBK : the basic library. LUA_LOADLIBK : the package library. LUA_COLIBK : the coroutine library. LUA_STRLIBK : the string library. LUA_UTF8LIBK : the UTF-8 library. LUA_TABLIBK : the table library. LUA_MATHLIBK : the mathematical library. LUA_IOLIBK : the I/O library. LUA_OSLIBK : the operating system library. LUA_DBLIBK : the debug library. 6.2 - Basic Functions The basic library provides core functions to Lua. If you do not include this library in your application, you should check carefully whether you need to provide implementations for some of its facilities.
  ///
  /// Stack: `[-0, +0, e]`
  ///
  /// C: `void luaL_openselectedlibs (lua_State *L, int load, int preload);`
  void openselectedlibs(int load, int preload);

  /// This macro is defined as follows: (lua_isnoneornil(L,(arg)) ? (dflt) : func(L,(arg))) In words, if the argument arg is nil or absent, the macro results in the default dflt. Otherwise, it results in the result of calling func with the state L and the argument index arg as arguments. Note that it evaluates the expression dflt only if needed.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `T luaL_opt (L, func, arg, dflt);`
  int opt(int func, int arg, int dflt);

  /// If the function argument arg is an integer (or it is convertible to an integer), returns this integer. If this argument is absent or is nil, returns d. Otherwise, raises an error.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `lua_Integer luaL_optinteger (lua_State *L, int arg, lua_Integer d);`
  int optinteger(int arg, int d);

  /// If the function argument arg is a string, returns this string. If this argument is absent or is nil, returns d. Otherwise, raises an error. If l is not NULL, fills its referent with the result's length. If the result is NULL (only possible when returning d and d == NULL), its length is considered zero. This function uses lua_tolstring to get its result, so all conversions and caveats of that function apply here.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `const char *luaL_optlstring (lua_State *L, int arg, const char *d, size_t *l);`
  ffi.Pointer<ffi.Void> optlstring(int arg, ffi.Pointer<ffi.Void> d, ffi.Pointer<ffi.Void> l);

  /// If the function argument arg is a number, returns this number as a lua_Number. If this argument is absent or is nil, returns d. Otherwise, raises an error.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `lua_Number luaL_optnumber (lua_State *L, int arg, lua_Number d);`
  double optnumber(int arg, double d);

  /// If the function argument arg is a string, returns this string. If this argument is absent or is nil, returns d. Otherwise, raises an error.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `const char *luaL_optstring (lua_State *L, int arg, const char *d);`
  ffi.Pointer<ffi.Void> optstring(int arg, ffi.Pointer<ffi.Void> d);

  /// Equivalent to luaL_prepbuffsize with the predefined size LUAL_BUFFERSIZE.
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `char *luaL_prepbuffer (luaL_Buffer *B);`
  ffi.Pointer<ffi.Void> prepbuffer(ffi.Pointer<ffi.Void> b);

  /// Returns an address to a space of size sz where you can copy a string to be added to buffer B (see luaL_Buffer). After copying the string into this space you must call luaL_addsize with the size of the string to actually add it to the buffer.
  ///
  /// Stack: `[-?, +?, m]`
  ///
  /// C: `char *luaL_prepbuffsize (luaL_Buffer *B, size_t sz);`
  ffi.Pointer<ffi.Void> prepbuffsize(ffi.Pointer<ffi.Void> b, int sz);

  /// Pushes the fail value onto the stack (see §6).
  ///
  /// Stack: `[-0, +1, -]`
  ///
  /// C: `void luaL_pushfail (lua_State *L);`
  void pushfail();

  /// Finishes the use of buffer B leaving the final string on the top of the stack.
  ///
  /// Stack: `[-?, +1, m]`
  ///
  /// C: `void luaL_pushresult (luaL_Buffer *B);`
  void pushresult(ffi.Pointer<ffi.Void> b);

  /// Equivalent to the sequence luaL_addsize, luaL_pushresult.
  ///
  /// Stack: `[-?, +1, m]`
  ///
  /// C: `void luaL_pushresultsize (luaL_Buffer *B, size_t sz);`
  void pushresultsize(ffi.Pointer<ffi.Void> b, int sz);

  /// Creates and returns a reference, in the table at index t, for the object on the top of the stack (and pops the object). The reference system uses the integer keys of the table. A reference is a unique integer key; luaL_ref ensures the uniqueness of the keys it returns. The entry 1 is reserved for internal use. Before the first use of luaL_ref, the integer keys of the table should form a proper sequence (no holes), and the value at entry 1 should be false: nil if the sequence is empty, false otherwise. You should not manually set integer keys in the table after the first use of luaL_ref. You can retrieve an object referred by the reference r by calling lua_rawgeti(L,t,r) or lua_geti(L,t,r). The function luaL_unref frees a reference. If the object on the top of the stack is nil, luaL_ref returns the constant LUA_REFNIL. The constant LUA_NOREF is guaranteed to be different from any reference returned by luaL_ref.
  ///
  /// Stack: `[-1, +0, m]`
  ///
  /// C: `int luaL_ref (lua_State *L, int t);`
  int ref(int t);

  /// If package.loaded[modname] is not true, calls the function openf with the string modname as an argument and sets the call result to package.loaded[modname], as if that function has been called through require. If glb is true, also stores the module into the global variable modname. Leaves a copy of the module on the stack.
  ///
  /// Stack: `[-0, +1, e]`
  ///
  /// C: `void luaL_requiref (lua_State *L, const char *modname, lua_CFunction openf, int glb);`
  void requiref(ffi.Pointer<ffi.Void> modname, ffi.Pointer<ffi.NativeFunction> openf, int glb);

  /// Registers all functions in the array l (see luaL_Reg) into the table on the top of the stack (below optional upvalues, see next). When nup is not zero, all functions are created with nup upvalues, initialized with copies of the nup values previously pushed on the stack on top of the library table. These values are popped from the stack after the registration. A function with a NULL value represents a placeholder, which is filled with false.
  ///
  /// Stack: `[-nup, +0, m]`
  ///
  /// C: `void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup);`
  void setfuncs(ffi.Pointer<ffi.Void> l, int nup);

  /// Sets the metatable of the object on the top of the stack as the metatable associated with name tname in the registry (see luaL_newmetatable).
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void luaL_setmetatable (lua_State *L, const char *tname);`
  void setmetatable(ffi.Pointer<ffi.Void> tname);

  /// This function works like luaL_checkudata, except that, when the test fails, it returns NULL instead of raising an error.
  ///
  /// Stack: `[-0, +0, m]`
  ///
  /// C: `void *luaL_testudata (lua_State *L, int arg, const char *tname);`
  ffi.Pointer<ffi.Void> testudata(int arg, ffi.Pointer<ffi.Void> tname);

  /// Converts any Lua value at the given index to a C&nbsp;string in a reasonable format. The resulting string is pushed onto the stack and also returned by the function (see §4.1.3). If len is not NULL, the function also sets *len with the string length. If the value has a metatable with a __tostring field, then luaL_tolstring calls the corresponding metamethod with the value as argument, and uses the result of the call as its result.
  ///
  /// Stack: `[-0, +1, e]`
  ///
  /// C: `const char *luaL_tolstring (lua_State *L, int idx, size_t *len);`
  ffi.Pointer<ffi.Void> tolstring(int idx, ffi.Pointer<ffi.Void> len);

  /// Creates and pushes a traceback of the stack L1. If msg is not NULL, it is appended at the beginning of the traceback. The level parameter tells at which level to start the traceback.
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `void luaL_traceback (lua_State *L, lua_State *L1, const char *msg, int level);`
  void traceback(ffi.Pointer<ffi.Void> l1, ffi.Pointer<ffi.Void> msg, int level);

  /// Raises a type error for the argument arg of the C&nbsp;function that called it, using a standard message; tname is a "name" for the expected type. This function never returns.
  ///
  /// Stack: `[-0, +0, v]`
  ///
  /// C: `int luaL_typeerror (lua_State *L, int arg, const char *tname);`
  int typeerror(int arg, ffi.Pointer<ffi.Void> tname);

  /// Returns the name of the type of the value at the given index.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `const char *luaL_typename (lua_State *L, int index);`
  ffi.Pointer<ffi.Void> typename(int index);

  /// Releases a reference (see luaL_ref). The integer ref must be either LUA_NOREF, LUA_REFNIL, or a reference previously returned by luaL_ref and not already released. If ref is either LUA_NOREF or LUA_REFNIL this function does nothing. Otherwise, the entry is removed from the table, so that the referred object can be collected and the reference ref can be used again by luaL_ref.
  ///
  /// Stack: `[-0, +0, -]`
  ///
  /// C: `void luaL_unref (lua_State *L, int t, int ref);`
  void unref(int t, int ref);

  /// Pushes onto the stack a string identifying the current position of the control at level lvl in the call stack. Typically this string has the following format:
  ///
  /// Stack: `[-0, +1, m]`
  ///
  /// C: `void luaL_where (lua_State *L, int lvl);`
  void where(int lvl);

}