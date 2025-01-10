#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_t.h"

/*
  Tgetdate. Get the date.
  Returns:
    1) integer: year
    2) integer: month
    3) integer: day
*/
int l_Tgetdate(lua_State *L) {
  const unsigned short date = (unsigned short) Tgetdate();
  const unsigned short year = (unsigned short) (1980 + ((date >> 9) & 0x7f));
  const unsigned short month = (date >> 5) & 0xf;
  const unsigned short day = date & 0x1f;

  /* Return year month and day as integers */
  lua_pushinteger(L, year);
  lua_pushinteger(L, month);
  lua_pushinteger(L, day);
  return 3;
}

/*
  Tsetdate. Set the date.
  Inputs:
    1) integer: year
    2) integer: month
    3) integer: day
  Returns:
    1) integer: zero on success or -ve gemdos error number
    2) string: gemdos error string
*/
int l_Tsetdate(lua_State *L) {
  const lua_Integer year = luaL_checkinteger(L, 1);
  const lua_Integer month = luaL_checkinteger(L, 2);
  const lua_Integer day = luaL_checkinteger(L, 3);
  const unsigned short date =
    (unsigned short) (day | (month << 5) | ((year - 1980) << 9));
  int days_in_month;
  long result;

  /* Check arguments */
  luaL_argcheck(L, year >= 1980 && year <= 2099, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidYear]);
  luaL_argcheck(L, month >= 1 && month <= 12, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMonth]);
  days_in_month = (month == 2 && !(year & 3)) ?
    29 : TOSBINDL_GEMDOS_DaysInMonth[month];
  luaL_argcheck(L, day >= 1 && day <= days_in_month, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidDay]);

  result = Tsetdate(date);

  lua_pushinteger(L, result); /* Error code */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */

  /* Return error code and error string */
  return 2;
}

/*
  Tgettime. Get the time.
  Returns:
    1) integer: hours
    2) integer: minutes
    3) integer: seconds
*/
int l_Tgettime(lua_State *L) {
  const unsigned short time = (unsigned short) Tgettime();
  const unsigned short hours = (time >> 11) & 0x1f;
  const unsigned short minutes = (time >> 5) & 0x3f;
  const unsigned short seconds = (unsigned short) ((time & 0x1f) << 1);

  /* Return hours minutes and seconds as integers */
  lua_pushinteger(L, hours);
  lua_pushinteger(L, minutes);
  lua_pushinteger(L, seconds);
  return 3;
}

/*
  Tsettime. Set the time.
  Inputs:
    1) integer: hours
    2) integer: minutes
    3) integer: seconds
  Returns:
    1) integer: zero on success or -ve gemdos error number
    2) string: gemdos error string
*/
int l_Tsettime(lua_State *L) {
  const lua_Integer hours = luaL_checkinteger(L, 1);
  const lua_Integer minutes = luaL_checkinteger(L, 2);
  const lua_Integer seconds = luaL_checkinteger(L, 3);
  const unsigned short time =
    (unsigned short) ((seconds >> 1) | (minutes << 5) | (hours << 11));
  long result;

  /* Check arguments */
  luaL_argcheck(L, hours >= 0 && hours <= 23, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidHours]);
  luaL_argcheck(L, minutes >= 0 && minutes <= 59, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMinutes]);
  luaL_argcheck(L, seconds >= 0 && seconds <= 59, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidSeconds]);

  result = Tsettime(time);

  /* Return result and gemdos error string */
  lua_pushinteger(L, result);
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result));
  return 2;
}
