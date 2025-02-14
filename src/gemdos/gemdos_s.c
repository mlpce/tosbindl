#include <string.h>

#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_s.h"

/*
  Svesion. Get GEMDOS version number.
  Returns:
    1) integer: Major version
    2) integer: Minor version
*/
int l_Sversion(lua_State *L) {
  const unsigned short gemdos_version = (unsigned short) Sversion();
  lua_pushinteger(L, gemdos_version & 0xff);
  lua_pushinteger(L, gemdos_version >> 8);
  return 2;
}

/*
  SuperPeek. Peek a named address in supervisor mode
  Inputs:
    1) string: the named address
  Returns:
    1) integer: the value
*/
int l_SuperPeek(lua_State *L) {
  const char *value_name = luaL_checkstring(L, 1);
  const unsigned char *uchar_address = NULL;
  const unsigned long *ulong_address = NULL;
  lua_Integer value;
  void *save_ssp;

  if (strcmp(value_name, "conterm") == 0)
    uchar_address = (unsigned char *) 0x484;
  else if (strcmp(value_name, "_hz_200") == 0)
    ulong_address = (unsigned long *) 0x4ba;

  luaL_argcheck(L, uchar_address || ulong_address, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  save_ssp = (void *) Super(0); /* Switch to supervisor mode */

  if (uchar_address)
    value = *uchar_address;
  else if (ulong_address)
    value = *ulong_address;

  Super(save_ssp); /* Switch to user mode */

  lua_pushinteger(L, value);
  return 1;
}

/*
  SuperPoke. Poke a named address in supervisor mode
  Inputs:
    1) string: the named address
    2) integer: the value to write
  Returns:
    Nothing
*/
int l_SuperPoke(lua_State *L) {
  const char *value_name = luaL_checkstring(L, 1);
  const lua_Integer value = luaL_checkinteger(L, 2);
  unsigned char *uchar_address = NULL;
  void *save_ssp;

  if (strcmp(value_name, "conterm") == 0) {
    luaL_argcheck(L, !(value & ~0xf), 2,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    uchar_address = (unsigned char *) 0x484;
  }

  luaL_argcheck(L, uchar_address, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  save_ssp = (void *) Super(0); /* Switch to supervisor mode */
  *uchar_address = (unsigned char) value;
  Super(save_ssp); /* Switch to user mode */

  return 0;
}
