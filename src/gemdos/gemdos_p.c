#include <string.h>

#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_p.h"

/*
  Pterm0. Terminate with result code zero.
*/
int l_Pterm0(lua_State *L) {
  Pterm0();
  return 0;
}

/*
  Pterm. Terminate with result code.
  Inputs:
    1) integer: Return status code
*/
int l_Pterm(lua_State *L) {
  const lua_Integer ret = luaL_checkinteger(L, 1);

  /* Check argument */
  luaL_argcheck(L, ret >= SHRT_MIN && ret <= SHRT_MAX, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  Pterm((short) ret);
  return 0;
}

static void PushGemdosEnvString(lua_State *L) {
  /* Get the GEMDOS environment pointer */
  const char *const *gemdos_envp = TOSBINDL_GEMDOS_EnvP(L);
  luaL_Buffer b; /* Buffer for '\0' delimited concatenated arguments  */

  /* Convert gemdos environment to single '\0' delimited string */
  luaL_buffinit(L, &b);
  while( *gemdos_envp != NULL ) {
    /* Add str to buffer including the '\0' delimiter */
    size_t str_len = strlen(*gemdos_envp) + 1;
    luaL_addlstring(&b, *gemdos_envp, str_len);
    ++gemdos_envp;
  }
 
  /* Push string containing gemdos env delimited by '\0' on stack */
  luaL_pushresult(&b);
}

static void PushArgsString(lua_State *L, int tbl_idx) {
  /* End key for argument table */
  const lua_Integer tbl_len =
    (luaL_checktype(L, tbl_idx, LUA_TTABLE), luaL_len(L, tbl_idx));
  luaL_Buffer b; /* Buffer for '\0' delimited concatenated arguments  */
  size_t total_len = 0; /* Total length of the final string */
  char *dst_ptr;
  lua_Integer key;

  /* Work out total length of '\0' delimited args */
  for (key = 1; key <= tbl_len; ++key) {
    /* Get the string value for the table key */
    const char *str = NULL;
    size_t str_len;

    /* Push the string value for the key */
    lua_rawgeti(L, tbl_idx, key);
    /* Get the string pointer. Empty arguments are not supported. */
    luaL_argcheck(L, lua_isstring(L, -1) &&
      (str = lua_tolstring(L, -1, &str_len)) && str_len, tbl_idx,
      TOSBINDL_ErrMess[TOSBINDL_EM_UnexpectedArrayValue]);
    lua_pop(L, 1);

    ++str_len;  /* Plus one for '\0' delimiter */
    total_len += str_len;
  }

  /* Initialise the buffer with the total length */
  dst_ptr = luaL_buffinitsize(L, &b, (size_t) total_len);

  /* Copy the data */
  for (key = 1; key <= tbl_len; ++key) {
    size_t data_len;
    const char *src_str;

    /* Push the string value for the key */
    lua_rawgeti(L, tbl_idx, key);
    /* Get the string pointer */
    src_str = lua_tolstring(L, -1, &data_len);
    memcpy(dst_ptr, src_str, ++data_len);
    lua_pop(L, 1);
    dst_ptr += data_len;
  }

  /* Push string containing args delimited by '\0' on stack */
  luaL_pushresultsize(&b, total_len);
}

/*
  Pexec0. Execute a program using Pexec mode zero.
  Inputs:
    1) string: Path of the program's executable.
    2) table: Array of arguments to pass to the child
  Returns:
    1) integer: Return code from child
    2) string: GEMDOS error message
*/
int l_Pexec0(lua_State *L) {
  char tail[128];
  char *tail_dest_ptr;
  const char *args_ptr;
  const char *args_end_ptr;
  size_t args_len;
  const char *argv_ptr = "ARGV=";
  long result;
  size_t child_path_len;

  /* Path to child process */
  const char *child_path = luaL_checklstring(L, 1, &child_path_len);

  /* Push '\0' delimited gemdos environment as a string. */
  PushGemdosEnvString(L);

  /* Push ARGV= and '\0' terminator */
  lua_pushlstring(L, argv_ptr, strlen(argv_ptr) + 1);

  /* Push child name and '\0' terminator */
  lua_pushlstring(L, child_path, child_path_len + 1);

  /* Push '\0' delimited arguments as a string. */
  PushArgsString(L, 2);

  /* Push a '\0' finisher as a string. */
  lua_pushlstring(L, "", 1);

  /* Setup the tail from the pushed Args string */
  args_ptr = lua_tolstring(L, -2, &args_len);
  args_end_ptr = args_ptr +
    (args_len <= 125 ? args_len : 125);

  /* Copy arguments into tail - maximum of 125 chars */
  tail_dest_ptr = &tail[1];
  while (args_ptr < args_end_ptr) {
    *tail_dest_ptr++ = (char) (*args_ptr ? *args_ptr : ' ');
    ++args_ptr;
  }

  /* Terminate the tail */
  *tail_dest_ptr = '\0';

  /* Length of tail: Special value 127 means using ARGV */
  tail[0] = 127;

  /* Concatenate the five strings on the stack, popping them
  and pushing the concatenated string. */
  lua_concat(L, 5);

  /* Call Pexec. Environment is at top of stack. */
  result = Pexec(0, child_path, tail, lua_tostring(L, -1));

  /* Pop the concatenated string */
  lua_pop(L, 1);

  lua_pushinteger(L, result); /* Error code  */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
  return 2;
}
