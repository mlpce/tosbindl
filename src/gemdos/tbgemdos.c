#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <limits.h>

#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"

#include "src/gemdos/tbgemdos.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_c.h"
#include "src/gemdos/gemdos_d.h"
#include "src/gemdos/gemdos_f.h"
#include "src/gemdos/gemdos_m.h"
#include "src/gemdos/gemdos_p.h"
#include "src/gemdos/gemdos_s.h"
#include "src/gemdos/gemdos_t.h"

/* GEMDOS binding version */
#define TBGEMDOS_MAJOR_VERSION 1
#define TBGEMDOS_MINOR_VERSION 0
#define TBGEMDOS_MICRO_VERSION 0

static const struct luaL_Reg gemdos[] = {
  {"Sversion", l_Sversion},
  {"SuperPeek", l_SuperPeek},
  {"SuperPoke", l_SuperPoke},
  {"Pterm0", l_Pterm0},
  {"Pterm", l_Pterm},
  {"Pexec0", l_Pexec0},
  {"Malloc", l_Malloc},
  {"Mfree", l_Mfree},
  {"Mshrink", l_Mshrink},
  {"Tgetdate", l_Tgetdate},
  {"Tsetdate", l_Tsetdate},
  {"Tgettime", l_Tgettime},
  {"Tsettime", l_Tsettime},
  {"Dgetdrv", l_Dgetdrv},
  {"Dsetdrv", l_Dsetdrv},
  {"Dfree", l_Dfree},
  {"Dcreate", l_Dcreate},
  {"Ddelete", l_Ddelete},
  {"Dsetpath", l_Dsetpath},
  {"Dgetpath", l_Dgetpath},
  {"Cconin", l_Cconin},
  {"Cconout", l_Cconout},
  {"Cauxin", l_Cauxin},
  {"Cauxout", l_Cauxout},
  {"Cprnout", l_Cprnout},
  {"Crawio", l_Crawio},
  {"Crawcin", l_Crawcin},
  {"Cnecin", l_Cnecin},
  {"Cconws", l_Cconws},
  {"Cconrs", l_Cconrs},
  {"Cconis", l_Cconis},
  {"Cconos", l_Cconos},
  {"Cprnos", l_Cprnos},
  {"Cauxis", l_Cauxis},
  {"Cauxos", l_Cauxos},
  {"Fcreate", l_Fcreate},
  {"Fopen", l_Fopen},
  {"Freads", l_Freads},
  {"Fwrites", l_Fwrites},
  {"Freadt", l_Freadt},
  {"Fwritet", l_Fwritet},
  {"Freadm", l_Freadm},
  {"Fwritem", l_Fwritem},
  {"Fwritei", l_Fwritei},
  {"Freadi", l_Freadi},
  {"Fseek", l_Fseek},
  {"Fdelete", l_Fdelete},
  {"Fclose", l_Fclose},
  {"Frename", l_Frename},
  {"Fattrib", l_Fattrib},
  {"Fdatime", l_Fdatime},
  {"Fdup", l_Fdup},
  {"Fforce", l_Fforce},
  {"Fsfirst", l_Fsfirst},
  {"Fsnext", l_Fsnext},
  {NULL, NULL}
};

/*
  GetEnvStr. Obtains an environment variable string.
  Returns:
    1) string: on success: obtained environment variable string
    1) nil: on failure: the environment variable was not found
*/
static int GetEnvStr(lua_State *L, const char *env_var,
    size_t env_var_len, const char *const *gemdos_envp) {
  while (*gemdos_envp) {
    const char *const gemdos_env_var = *gemdos_envp;
    if (strncmp(gemdos_env_var, env_var, env_var_len) == 0 &&
        gemdos_env_var[env_var_len] == '=') {
      lua_pushstring(L, &gemdos_env_var[env_var_len + 1]);
      break;
    }
    ++gemdos_envp;
  }

  if (*gemdos_envp == NULL)
    luaL_pushfail(L);

  return 1;
}

/*
  GetEnvTbl. Obtains all environment variables into a table.
  Returns:
    1) table: GEMDOS environment
*/
static int GetEnvTbl(lua_State *L, const char *const *gemdos_envp) {
  lua_newtable(L);

  while (*gemdos_envp) {
    const char *const gemdos_env_var = *gemdos_envp;
    const char *ptr = gemdos_env_var;
    while (*ptr && *ptr != '=')
      ++ptr;

    if (*ptr == '=') {
      const size_t key_len = (size_t) (ptr - gemdos_env_var);
      if (key_len) {
        lua_pushlstring(L, gemdos_env_var, key_len);  /* key */
        lua_pushstring(L, ptr + 1);  /* value */
        lua_settable(L, -3);
      }
    }
    ++gemdos_envp;
  }

  return 1;
}

/*
  GetEnv
  Inputs:
    Use A) 1) string: name of env var to get
    Use B) 1) nil: get GEMDOS environment into a table
  Returns:
    Use A) 1) string: on success: env var
    Use A) 1) nil: on failure: the env var was not found
    Use B) 1) table: the GEMDOS environment as a table
*/
static int GetEnv(lua_State *L) {
  size_t env_var_len;
  const char *env_var = luaL_optlstring(L, 1, NULL, &env_var_len);
  const char *const *gemdos_envp = TOSBINDL_GEMDOS_EnvP(L);
  if (env_var)
    return GetEnvStr(L, env_var, env_var_len, gemdos_envp);

  return GetEnvTbl(L, gemdos_envp);
}

static void lstop(lua_State *L, lua_Debug *ar) {
  (void)ar;  /* unused arg. */
  lua_sethook(L, NULL, 0, 0);  /* reset hook */
  luaL_error(L, "Escape");
}

/*
  Esc. Read a key press if available and raise an error if the key pressed
  is the escape key.
  Inputs:
    None
  Returns:
    None
*/
static int Esc(lua_State *L) {  
  /* Check for escape key press */
  if (Cconis() && (Cnecin() & 0xFF) == '\033') {
    const int flag =
      LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT;
    lua_sethook(L, lstop, flag, 1);
  }

  return 0;
}

/*
  Version. Obtain the binding version.
  Inputs:
    None
  Returns:
    1) integer: major version
    2) integer: minor version
    3) integer: micro version
*/
static int Version(lua_State *L) {
  lua_pushinteger(L, TBGEMDOS_MAJOR_VERSION);
  lua_pushinteger(L, TBGEMDOS_MINOR_VERSION);
  lua_pushinteger(L, TBGEMDOS_MICRO_VERSION);
  return 3;
}

int luaopen_gemdos(lua_State *L) {
  /* gemdos.const.Fattrib table keys and values */
  static const TOSBINDL_RegInt attrib_ints[] = {
    {"none", 0},
    {"readonly", TOSBINDL_GEMDOS_FA_READONLY},
    {"hidden", TOSBINDL_GEMDOS_FA_HIDDEN},
    {"system", TOSBINDL_GEMDOS_FA_SYSTEM},
    {"volume", TOSBINDL_GEMDOS_FA_VOLUME},
    {"dir", TOSBINDL_GEMDOS_FA_DIR},
    {"archive", TOSBINDL_GEMDOS_FA_ARCHIVE}
  };

  /* gemdos.const.Fseek table keys and values */
  static const TOSBINDL_RegInt seek_ints[] = {
    {"seek_set", SEEK_SET},
    {"seek_cur", SEEK_CUR},
    {"seek_end", SEEK_END}
  };

  /* gemdos.const.Fopen table keys and values */
  static const TOSBINDL_RegInt open_ints[] = {
    {"readonly", TOSBINDL_GEMDOS_FO_READ},
    {"writeonly", TOSBINDL_GEMDOS_FO_WRITE},
    {"readwrite", TOSBINDL_GEMDOS_FO_RW}
  };

  /* gemdos.const.Fdup table keys and values */
  static const TOSBINDL_RegInt fdup_ints[] = {
    {"conin", TOSBINDL_GEMDOS_SH_CONIN},
    {"conout", TOSBINDL_GEMDOS_SH_CONOUT},
    {"aux", TOSBINDL_GEMDOS_SH_AUX},
    {"prn", TOSBINDL_GEMDOS_SH_PRN}
  };

  /* gemdos.const.Error table values */
  static const int error_ints[] = {
    0,
    TOSBINDL_GEMDOS_ERROR_EINVFN,
    TOSBINDL_GEMDOS_ERROR_EFILNF,
    TOSBINDL_GEMDOS_ERROR_EPTHNF,
    TOSBINDL_GEMDOS_ERROR_ENHNDL,
    TOSBINDL_GEMDOS_ERROR_EACCDN,
    TOSBINDL_GEMDOS_ERROR_EIHNDL,
    TOSBINDL_GEMDOS_ERROR_ENSMEM,
    TOSBINDL_GEMDOS_ERROR_EIMBA,
    TOSBINDL_GEMDOS_ERROR_EDRIVE,
    TOSBINDL_GEMDOS_ERROR_ENMFIL,
    TOSBINDL_GEMDOS_ERROR_ERANGE,
    TOSBINDL_GEMDOS_ERROR_EINTRN,
    TOSBINDL_GEMDOS_ERROR_EPLFMT,
    TOSBINDL_GEMDOS_ERROR_EGSBF
  };

  /* gemdos.utility table keys and functions */
  static const luaL_Reg util_funcs[] = {
    {"getenv", GetEnv},
    {"esc", Esc},
    {"version", Version},
    {NULL, NULL}
  };

  /* Gemdos table */
  luaL_newlib(L, gemdos);

  /* Table to hold Constant tables */
  lua_newtable(L);

  /* Attribute constants */
  TOSBINDL_newinttable(L, attrib_ints);
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fattrib in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fattrib");

  /* Seek mode constants */
  TOSBINDL_newinttable(L, seek_ints);
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fseek in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fseek");

  /* Open mode constants */
  TOSBINDL_newinttable(L, open_ints);
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fopen in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fopen");

  /* Fdup standard handles */
  TOSBINDL_newinttable(L, fdup_ints);
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fdup in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fdup");

  /* Errors */
  TOSBINDL_newinttable_fn(L, error_ints, TOSBINDL_GEMDOS_ErrMess);
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Error in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Error");

  /* Make the Constant table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name const in Gemdos table to have Constant table as
  value */
  lua_setfield(L, -2, "const");

  /* Table to hold utility functions */
  luaL_newlib(L, util_funcs);
  /* Set field with name utility in Gemdos table to have Utility table as
  value */
  lua_setfield(L, -2, "utility");

  /* Return the Gemdos table */
  return 1;
}
