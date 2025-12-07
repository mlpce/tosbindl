#include "lua.h"
#include "lauxlib.h"

#include "src/gemdos/gemdosi.h"

/* Rotate for converting between byte size and number of imode integers */
const unsigned char TOSBINDL_GEMDOS_imode_sz_r[TOSBINDL_GEMDOS_IMODE_NUM] = {
  0, 0, 1, 1, 2
};

/* Minimum value of an imode integer */
const long TOSBINDL_GEMDOS_imode_min_val[TOSBINDL_GEMDOS_IMODE_NUM] = {
  -128L, 0L, -32768L, 0L, -2147483647L - 1
};

/* Maximum value of an imode integer */
const long TOSBINDL_GEMDOS_imode_max_val[TOSBINDL_GEMDOS_IMODE_NUM] = {
  127L, 255L, 32767L, 65535L, 2147483647L
};

/* Map a GEMDOS negative error value to a string. */
typedef struct ErrorEntry {
  short err;
  const char *str;
} ErrorEntry;

/* Array of error entries */
static const ErrorEntry GemdosError[] = {
  {0, "OK"},
  {TOSBINDL_GEMDOS_ERROR_EINVFN, "EINVFN"},
  {TOSBINDL_GEMDOS_ERROR_EFILNF, "EFILNF"},
  {TOSBINDL_GEMDOS_ERROR_EPTHNF, "EPTHNF"},
  {TOSBINDL_GEMDOS_ERROR_ENHNDL, "ENHNDL"},
  {TOSBINDL_GEMDOS_ERROR_EACCDN, "EACCDN"},
  {TOSBINDL_GEMDOS_ERROR_EIHNDL, "EIHNDL"},
  {TOSBINDL_GEMDOS_ERROR_ENSMEM, "ENSMEM"},
  {TOSBINDL_GEMDOS_ERROR_EIMBA, "EIMBA"},
  {TOSBINDL_GEMDOS_ERROR_EDRIVE, "EDRIVE"},
  {TOSBINDL_GEMDOS_ERROR_ENMFIL, "ENMFIL"},
  {TOSBINDL_GEMDOS_ERROR_ERANGE, "ERANGE"},
  {TOSBINDL_GEMDOS_ERROR_EINTRN, "EINTRN"},
  {TOSBINDL_GEMDOS_ERROR_EPLFMT, "EPLFMT"},
  {TOSBINDL_GEMDOS_ERROR_EGSBF, "EGSBF"}
};

/* Convert a GEMDOS error code to a string */
const char *TOSBINDL_GEMDOS_ErrMess(long err) {
  const char *str = "Error";
  const ErrorEntry *entry =
    GemdosError + sizeof(GemdosError)/sizeof(GemdosError[0]);
  while (--entry >= GemdosError) {
    if (err == entry->err) {
      str = entry->str;
      break;
    }
  }

  return str;
}

/* Userdata type names */
const char *const TOSBINDL_UD_T_Gemdos_File = "gemdos.file";
const char *const TOSBINDL_UD_T_Gemdos_Memory = "gemdos.memory";
const char *const TOSBINDL_UD_T_Gemdos_Dta = "gemdos.dta";

/* Days in month (non leap year)*/
const unsigned char TOSBINDL_GEMDOS_DaysInMonth[13] = {
  0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

const char *const *TOSBINDL_GEMDOS_EnvP(lua_State *L) {
  /* Registry key for gemdos environment pointer */
  const char *const gemdos_envp_reg_key = "gemdos.envp";
  const char *const *gemdos_envp;

  /* Get the gemdos environment pointer from the registry */
  lua_getfield(L, LUA_REGISTRYINDEX, gemdos_envp_reg_key);
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "%s missing", gemdos_envp_reg_key);
  }
  gemdos_envp = (const char *const *)lua_touserdata (L, -1);
  if (!gemdos_envp) {
    luaL_error(L, "%s invalid", gemdos_envp_reg_key);
  }

  /* Pop the light user data */
  lua_pop(L, 1);

  return gemdos_envp;
}
