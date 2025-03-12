#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_c.h"

/*
  Cconin. Wait for a keyboard character.
  Returns:
    1) integer: ASCII
    2) integer: Scan code
    3) integer: Shift key bits (requires conterm)
*/
int l_Cconin(lua_State *L) {
  const unsigned long in = Cconin();
  lua_pushinteger(L, in & 0xFF); /* ASCII */
  lua_pushinteger(L, (in >> 16) & 0xFF); /* Scan code*/
  lua_pushinteger(L, (in >> 24) & 0xF); /* Shift (requires conterm) */
  return 3;
}

/*
  Cconout. Send character to console
  Inputs:
    1) integer: character to output
*/
int l_Cconout(lua_State *L) {
  Cconout(luaL_checkinteger(L, 1) & 0xFF);
  return 0;
}

/*
  Cauxin. Wait for character from RS232
  Returns:
    1) integer: character received
*/
int l_Cauxin(lua_State *L) {
  lua_pushinteger(L, Cauxin() & 0xFF);
  return 1;  
}

/*
  Cauxout. Send a character to RS232
  Inputs:
    1) integer: character to send
*/
int l_Cauxout(lua_State *L) {
  Cauxout(luaL_checkinteger(L, 1) & 0xFF);
  return 0;
}

/*
  Cprnout. Sends a character to parallel port
  Inputs:
    1) integer: character to send
  Returns:
    1) integer: status code
*/
int l_Cprnout(lua_State *L) {
  lua_pushinteger(L, Cprnout(luaL_checkinteger(L, 1) & 0xFF));
  return 1;
}

/*
  Crawio. Raw I/O to Gemdos handle 0 or 1
  Inputs:
    1) integer: character
    Use A) 255 perform input
    Use B) < 255 Perform output
  Returns:
    Use A)
    1) integer: ASCII
    2) integer: Scan code
    3) integer: Shift key bits (requires conterm)
*/
int l_Crawio(lua_State *L) {
  const lua_Integer ch = luaL_checkinteger(L, 1) & 0xFF;
  const unsigned long in = Crawio(ch);
  if (ch == 0xFF) {
    lua_pushinteger(L, in & 0xFF); /* ASCII */
    lua_pushinteger(L, (in >> 16) & 0xFF); /* Scan code*/
    lua_pushinteger(L, (in >> 24) & 0xF); /* Shift (requires conterm) */
    return 3;
  }

  return 0;
}

/*
  Crawcin. Raw input Gemdos handle 0
  Returns:
    1) integer: ASCII
    2) integer: Scan code
    3) integer: Shift key bits (requires conterm)
*/
int l_Crawcin(lua_State *L) {
  const unsigned long in = Crawcin();
  lua_pushinteger(L, in & 0xFF); /* ASCII */
  lua_pushinteger(L, (in >> 16) & 0xFF); /* Scan code*/
  lua_pushinteger(L, (in >> 24) & 0xF); /* Shift (requires conterm) */
  return 3;
}

/*
  Cnecin. Wait for a keyboard character without echo.
  Returns:
    1) integer: ASCII
    2) integer: Scan code
    3) integer: Shift key bits (requires conterm)
*/
int l_Cnecin(lua_State *L) {
  const unsigned long in = Cnecin();
  lua_pushinteger(L, in & 0xFF); /* ASCII */
  lua_pushinteger(L, (in >> 16) & 0xFF); /* Scan code*/
  lua_pushinteger(L, (in >> 24) & 0xF); /* Shift (requires conterm) */
  return 3;
}

/*
  Cconws. Write string to screen
  Inputs:
    1) string: the string to write
*/
int l_Cconws(lua_State *L) {
  (void) Cconws(luaL_checkstring(L, 1));
  return 0;
}

/*
  Cconrs. Read a string from the keyboard.
  Inputs:
    1) integer: the maximum number of chars to read (up to 255)
  Returns:
    1) string: the string that was input
*/
int l_Cconrs(lua_State *L) {
  const lua_Integer num_ch = luaL_checkinteger(L, 1);
  char buffer[257];

  /* Check argument, number of characters to read */
  luaL_argcheck(L, num_ch >= 0 && num_ch <= 255, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  buffer[0] = (char) num_ch;
  buffer[1] = '\0';

  Cconrs(buffer);
  lua_pushlstring(L, &buffer[2], (unsigned char) buffer[1]);
  return 1;
}

/*
  Cconis. keyboard input status.
  Returns:
    1) boolean: true if a character is waiting
*/
int l_Cconis(lua_State *L) {
  lua_pushboolean(L, Cconis());
  return 1;
}

/*
  Cconos. screen output status.
  Returns:
    1) boolean: true if ready to accept a character
*/
int l_Cconos(lua_State *L) {
  lua_pushboolean(L, Cconos());
  return 1;
}

/*
  Cprnos. printer output status.
  Returns:
    1) boolean: true if printer is ready to accept a character
*/
int l_Cprnos(lua_State *L) {
  lua_pushboolean(L, Cprnos());
  return 1;
}

/*
  Cauxis. RS232 input status
  Returns:
    1) boolean: true if a character is waiting
*/
int l_Cauxis(lua_State *L) {
  lua_pushboolean(L, Cauxis());
  return 1;
}

/*
  Cauxos: RS232 output status
  Returns:
    1) boolean: true if a character can be output
*/
int l_Cauxos(lua_State *L) {
  lua_pushboolean(L, Cauxos());
  return 1;
}
