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
  GetEnvStr
  Inputs:
    1) string: name of env var to get
  Returns:
    1) string: on success: env var
    1) nil: on failure: the env var was not found
*/
static int GetEnvStr(lua_State *L, const char *env_var,
    size_t env_var_len, const char *const *gemdos_envp) {
  while (*gemdos_envp) {
    const char *const gemdos_env_var = *gemdos_envp;
    if (memcmp(gemdos_env_var, env_var, env_var_len) == 0 &&
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
  GetEnvTble
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

int luaopen_gemdos(lua_State *L) {
  luaL_newlib(L, gemdos);

  /* Table to hold Constant tables */
  lua_newtable(L);

  /* Attribute constants */
  lua_createtable(L, 0, 7);
  lua_pushinteger(L, 0);
  lua_setfield(L, -2, "none");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FA_READONLY);
  lua_setfield(L, -2, "readonly");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FA_HIDDEN);
  lua_setfield(L, -2, "hidden");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FA_SYSTEM);
  lua_setfield(L, -2, "system");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FA_VOLUME);
  lua_setfield(L, -2, "volume");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FA_DIR);
  lua_setfield(L, -2, "dir");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FA_ARCHIVE);
  lua_setfield(L, -2, "archive");
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fattrib in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fattrib");

  /* Seek mode constants */
  lua_createtable(L, 0, 3);
  lua_pushinteger(L, SEEK_SET);
  lua_setfield(L, -2, "seek_set");
  lua_pushinteger(L, SEEK_CUR);
  lua_setfield(L, -2, "seek_cur");
  lua_pushinteger(L, SEEK_END);
  lua_setfield(L, -2, "seek_end");
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fseek in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fseek");

  /* Open mode constants */
  lua_createtable(L, 0, 3);
  lua_pushinteger(L, TOSBINDL_GEMDOS_FO_READ);
  lua_setfield(L, -2, "readonly");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FO_WRITE);
  lua_setfield(L, -2, "writeonly");
  lua_pushinteger(L, TOSBINDL_GEMDOS_FO_RW);
  lua_setfield(L, -2, "readwrite");
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fopen in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fopen");

  /* Fdup standard handles */
  lua_createtable(L, 0, 4);
  lua_pushinteger(L, TOSBINDL_GEMDOS_SH_CONIN);
  lua_setfield(L, -2, "conin");
  lua_pushinteger(L, TOSBINDL_GEMDOS_SH_CONOUT);
  lua_setfield(L, -2, "conout");
  lua_pushinteger(L, TOSBINDL_GEMDOS_SH_AUX);
  lua_setfield(L, -2, "aux");
  lua_pushinteger(L, TOSBINDL_GEMDOS_SH_PRN);
  lua_setfield(L, -2, "prn");
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Fdup in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Fdup");

  /* Errors */
  lua_createtable(L, 0, 15);
  lua_pushinteger(L, 0);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(0));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EINVFN);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EINVFN));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EFILNF);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EFILNF));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EPTHNF);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EPTHNF));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_ENHNDL);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_ENHNDL));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EACCDN);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EACCDN));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EIHNDL);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EIHNDL));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_ENSMEM);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_ENSMEM));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EIMBA);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EIMBA));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EDRIVE);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EDRIVE));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_ENMFIL);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_ENMFIL));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_ERANGE);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_ERANGE));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EINTRN);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EINTRN));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EPLFMT);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EPLFMT));
  lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_EGSBF);
  lua_setfield(L, -2, TOSBINDL_GEMDOS_ErrMess(TOSBINDL_GEMDOS_ERROR_EGSBF));

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
  lua_newtable(L);

  lua_pushcfunction(L, GetEnv); /* Fn to get environment variable or table */
  lua_setfield(L, -2, "getenv");
  lua_pushcfunction(L, Esc); /* Fn to raise an error if escape key pressed */
  lua_setfield(L, -2, "esc");

  /* Set field with name utility in Gemdos table to have Utility table as
  value */
  lua_setfield(L, -2, "utility");

  /* Return the Gemdos table */
  return 1;
}
