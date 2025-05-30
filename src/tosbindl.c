#include "lua.h"
#include "lauxlib.h"

#include "tosbindl.h"

#define TOSBINDL_MAJOR_VERSION 0
#define TOSBINDL_MINOR_VERSION 1
#define TOSBINDL_MICRO_VERSION 2

/* Error messages */
const char *const TOSBINDL_ErrMess[TOSBINDL_EM_Max] = {
  "Read only",
  "Write only",
  "Invalid file",
  "Invalid memory",
  "Invalid array value",
  "Invalid value"
};

/* Metamethod names */
const char *const TOSBINDL_MMF_Names[TOSBINDL_MMFN_Max] = {
  "__gc",
  "__close",
  "__tostring",
  "__index",
  "__newindex",
  "__pairs"
};

/* Error function when attempting to alter readonly table */
static int ROErrorFn(lua_State *L) {
  luaL_error(L, TOSBINDL_ErrMess[TOSBINDL_EM_ReadOnly], 2);
  return 0;
}

/* See luaB_next in lua core */
static int ROProxyPairsNext(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_settop(L, 2);
  if (lua_next(L, 1))
    return 2;

  lua_pushnil(L);
  return 1;
}

/* Function for proxy __pairs closure. Upvalue is the table to be iterated */
static int ROProxyPairs(lua_State *L) {
  /* Next function */
  lua_pushcfunction(L, ROProxyPairsNext);
  /* Upvalue is the target table for the iteration. */
  lua_pushvalue(L, lua_upvalueindex(1));
  /* Iterate from initial index so over all values */
  lua_pushnil(L);
  return 3;
}

/* Wrap a table on the stack with a readonly proxy */
void TOSBINDL_ROProxy(lua_State *L) {
  /* Check table has been passed on the stack */
  luaL_checktype(L, -1, LUA_TTABLE);
  /* Stack: target */

  /* Push a new table which will be the proxy */
  lua_newtable(L);
  /* Stack: target, proxy */

  /* Push a new table which will be the proxy's metatable */
  lua_newtable(L);
  /* Stack: target, proxy, metatable */

  /* Rotate target table to top of stack */
  lua_rotate(L, -3, 2);
  /* Stack: proxy, metatable, target */

  /* Copy the target table */
  lua_pushvalue(L, -1);
  /* Stack: proxy, metatable, target, target */

  /* Push pairs with passed table as upvalue (pops target) */
  lua_pushcclosure(L, ROProxyPairs, 1);
  /* Stack: proxy, metatable, target, closure */

  /* Metatable __pairs set to pushed c closure (pops closure) */
  lua_setfield(L, -3, TOSBINDL_MMF_Names[TOSBINDL_MMFN_pairs]);
  /* Stack: proxy, metatable, target */

  /* Metatable __index set to target table (pops target)*/
  lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_index]);
  /* Stack: proxy, metatable */

  /* Push error function for __newindex */
  lua_pushcfunction(L, ROErrorFn);
  /* Stack: proxy, metatable, function */

  /* Metatable __newindex set to pushed c function (pops function) */
  lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_newindex]); 
  /* Stack: proxy, metatable */

  /* Set Proxy's metatable to be the Metatable (pops metatable)*/
  lua_setmetatable(L, -2);
  /* Stack: proxy */
}

static int l_version(lua_State *L) {
  lua_pushinteger(L, TOSBINDL_MAJOR_VERSION);
  lua_pushinteger(L, TOSBINDL_MINOR_VERSION);
  lua_pushinteger(L, TOSBINDL_MICRO_VERSION);
  return 3;
}

static const struct luaL_Reg tosbindl[] = {
  {"version", l_version},
  {NULL, NULL}
};

void TOSBINDL_setints(lua_State *L, int numints, const TOSBINDL_RegInt *l) {
  while (numints--) {
    lua_pushinteger(L, l->value);
    lua_setfield(L, -2, l++->name);
  }
}

void TOSBINDL_setints_fn(lua_State *L, int numints, const int *l,
    const char *(*fn)(long)) {
  while (numints--) {
    lua_pushinteger(L, *l);
    lua_setfield(L, -2, (*fn)(*l++));
  }
}

int luaopen_tosbindl(lua_State *L) {
  luaL_newlib(L, tosbindl);
  return 1;
}
