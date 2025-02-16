#include <assert.h>
#include <limits.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h" 
#include "src/gemdos/gemdos_m.h"
#include "src/gemdos/gemdos_f.h"

#define BLOCK_SIZE 512

typedef struct File {
  short valid; /* handle is set to a Gemdos handle */
  short mode; /* File open mode RO, WO, RW */
  short handle; /* Gemdos file handle */
} File;

typedef struct Dta {
#if (defined(__GNUC__) && defined(__atarist__))
  _DTA dta; /* Disk transfer structure */
#else
  DTA dta;
#endif
} Dta;

static Dta *PushDtaUserData(lua_State *L);

/*
  Close the userdata's gemdos file handle
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_File
*/
static int FileCloseHandle(struct lua_State *L) {
  File *const fud = (File *) lua_touserdata(L, 1); /* File ud */
  if (fud->valid) {
    /* Close the gemdos file handle */
    const long result = Fclose(fud->handle);
    if (result < 0) {
      printf("FileClose: %s\n", TOSBINDL_GEMDOS_ErrMess(result));
    }
    /* userdata is no longer valid */
    fud->valid = 0;
    fud->handle = 0;
    fud->mode = 0;
  }
 
  return 0;
}

/* 
  File userdata garbage collection function __gc
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_File
*/
static int FileGC(struct lua_State *L) {
  return FileCloseHandle(L);
}

/* 
  File userdata close function __close
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_File
*/
static int FileClose(struct lua_State *L) {
  return FileCloseHandle(L);
}

/* 
  File userdata to string function __tostring
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_File
  Returns:
    1) string: string representing the userdata
*/
static int FileToString(struct lua_State *L) {
  const File *const fud = (const File *) lua_touserdata(L, 1); /* File ud */
  lua_pushfstring(L, "File: %I", (lua_Integer) fud->handle);
  return 1;
}

/*
  File userdata function "handle"
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_File
  Returns:
    1) integer: Handle of the gemdos file
*/
static int FileGetHandle(struct lua_State *L) {
  const File *const fud =
    (const File *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_File);
  lua_pushinteger(L, (lua_Integer) fud->handle);
  return 1;
}

/*
  Pushes userdata TOSBINDL_UD_T_Gemdos_File
  Returns:
    1) userdata: TOSBINDL_UD_T_Gemdos_File
*/
static File *PushFileUserData(lua_State *L) {
  /* Create userdata to hold the File structure */
  File *const fud = (File *) lua_newuserdatauv(L, sizeof(File), 0);
  /* Gemdos file handle is not yet valid */
  fud->valid = 0;
  fud->handle = 0;
  fud->mode = 0;

  /* Push new metatable for type TOSBINDL_UD_T_Gemdos_File */
  if (luaL_getmetatable(L, TOSBINDL_UD_T_Gemdos_File) != LUA_TTABLE) {
    lua_pop(L, 1); 
    luaL_newmetatable(L, TOSBINDL_UD_T_Gemdos_File);

    /* Table for __index */
    lua_createtable(L, 0, 13);
    lua_pushcfunction(L, FileGetHandle); /* Fn to push handle from File*/
    lua_setfield(L, -2, "handle");
    lua_pushcfunction(L, l_Freads); /* Fn to read file bytes into a string */
    lua_setfield(L, -2, "reads");
    lua_pushcfunction(L, l_Fwrites); /* Fn to write file bytes from a string */
    lua_setfield(L, -2, "writes");
    lua_pushcfunction(L, l_Freadt); /* Fn to read file bytes into a table */
    lua_setfield(L, -2, "readt");
    lua_pushcfunction(L, l_Fwritet); /* Fn to write file bytes from a table */
    lua_setfield(L, -2, "writet");
    lua_pushcfunction(L, l_Freadm); /* Fn to read file bytes into a memory */
    lua_setfield(L, -2, "readm");
    lua_pushcfunction(L, l_Fwritem); /* Fn to write file bytes from a memory */
    lua_setfield(L, -2, "writem");
    lua_pushcfunction(L, l_Fwritei); /* Fn to write file byte from an integer */
    lua_setfield(L, -2, "writei");
    lua_pushcfunction(L, l_Freadi); /* Fn to read file byte into an integer */
    lua_setfield(L, -2, "readi");
    lua_pushcfunction(L, l_Fseek); /* Fn to seek within the file */
    lua_setfield(L, -2, "seek");
    lua_pushcfunction(L, l_Fclose); /* Fn to close the file */
    lua_setfield(L, -2, "close");
    lua_pushcfunction(L, l_Fdatime); /* Fn to set and get file datime */
    lua_setfield(L, -2, "datime");
    lua_pushcfunction(L, l_Fforce); /* Fn to force standard handle to file */
    lua_setfield(L, -2, "force");
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_index]);

    /* Garbage collection function */
    lua_pushcfunction(L, FileGC);
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_gc]);

    /* Close function */
    lua_pushcfunction(L, FileClose);
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_close]);

    /* To string function */
    lua_pushcfunction(L, FileToString);
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_tostring]);
  }

  /* Set the metatable on the userdata */
  lua_setmetatable(L, -2);

  return fud;
}

/*
  Fcreate. Create a file.
  Inputs:
    1) string: name
    2) integer: attributes
  Returns:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
    2) userdata: on success: file
    2) string: on failure: gemdos error string
*/
int l_Fcreate(lua_State *L) {
  const char *const name = luaL_checkstring(L, 1);
  const lua_Integer attr = luaL_checkinteger(L, 2);
  File *fud;

  long result;

  /* Attribute constraints:
    Cannot use directory attribute with Fcreate.
    If Volume attribute is set no other attributes can be set. */
  luaL_argcheck(L,
    !(attr & TOSBINDL_GEMDOS_FA_DIR) && !((attr & TOSBINDL_GEMDOS_FA_VOLUME)
    && (attr ^ TOSBINDL_GEMDOS_FA_VOLUME)), 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Push the File userdata which will hold the Gemdos file handle */
  fud = PushFileUserData(L);

  /* Call Gemdos Fcreate */
  result = Fcreate(name, attr);

  /* Negative result is an error */
  if (result < 0) {
    lua_pop(L, 1); /* Fcreate failed - pop userdata */
    lua_pushinteger(L, result); /* Error code */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
    return 2;
  }

  /* Mark the userdata as valid, the mode as read/write and store the Gemdos
  file handle. */
  fud->valid = 1;
  fud->mode = TOSBINDL_GEMDOS_FO_RW;
  fud->handle = (short) result;

  lua_pushinteger(L, 0); /* Success result */
  lua_rotate(L, 3, 1); /* Rotate userdata to top */

  /* Return success result and userdata */
  return 2;
}

/*
  Fopen. Open a file.
  Inputs:
    1) string: name
    2) integer: mode 0 = readonly, 1 = writeonly, 2 = readwrite
  Returns:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
    2) userdata: on success: file
    2) string: on failure: gemdos error string
*/
int l_Fopen(lua_State *L) {
  const char *const name = luaL_checkstring(L, 1);
  const lua_Integer mode = luaL_checkinteger(L, 2);
  File *fud;

  long result;

  /* Mode constraint */
  luaL_argcheck(L, mode >= TOSBINDL_GEMDOS_FO_READ &&
    mode <= TOSBINDL_GEMDOS_FO_RW, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Push the File userdata which will hold the Gemdos file handle */
  fud = PushFileUserData(L);

  /* Call Gemdos Fopen */
  result = Fopen(name, mode);

  /* Negative result is an error */
  if (result < 0) {
    lua_pop(L, 1); /* Fopen failed - pop userdata */
    lua_pushinteger(L, result); /* Error code */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
    return 2;
  }

  /* Mark the userdata as valid, the mode used and store the Gemdos file
  handle. */
  fud->valid = 1;
  fud->mode = (short) mode;
  fud->handle = (short) result;

  lua_pushinteger(L, 0); /* Success result */
  lua_rotate(L, 3, 1); /* Rotate userdata to top */

  /* Return success result and userdata */
  return 2;
}

/*
  Freads. Read bytes from a file into a string.
  Inputs:
    1) userdata: file
    2) integer: number of bytes to read
  Returns:
    1) integer: on success:  >= 0 number of bytes read
    1) integer: on failure:  -ve gemdos error number
    2) string: on success: bytes read
    2) string: on failure: gemdos error string
  Note:
    Can return less bytes than requested if EOF reached.
    Will return 0 bytes and empty string if EOF already reached.
*/
int l_Freads(lua_State *L) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  lua_Integer count = luaL_checkinteger(L, 2); /* Num chars to read */
  lua_Integer remaining = count; /* Remaining chars to read */
  long result = 0;
  luaL_Buffer b; /* Buffer for string */
  char *str; /* Pointer to string in buffer */

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);
  /* Check that mode is not write only */
  luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_WRITE, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_WriteOnly]);
  /* Check count */
  luaL_argcheck(L, count >= 0, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Initialise the buffer */
  str = luaL_buffinitsize(L, &b, (size_t) count);

  /* While characters remain to be read */
  while (remaining) {
    /* Read up to BLOCK_SIZE characters at a time */
    const long amount = remaining > BLOCK_SIZE ? BLOCK_SIZE : remaining;
    result = Fread(fud->handle, amount, str);
    if (result > 0) {
      /* 'result' characters were read */
      remaining -= result;
      str += result;
    } else {
      /* Zero characters read (EOF) or an error occurred */
      break;
    }
  }

  /* Set count to be the amount of bytes actually read */
  count -= remaining;
  luaL_pushresultsize(&b, (size_t) count);
  /* Result */
  lua_pushinteger(L, result < 0 ? result : count);
  /* Rotate result string to top */
  lua_rotate(L, 3, 1);

  if (result < 0) {
    /* Error - pop the result string */
    lua_pop(L, 1);
    /* Push an error string instead */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result));
  }

  /* Return result and result string */
  return 2;
}

/*
  Fwrites. Writes bytes from a string into a file.
  Inputs:
    1) userdata: file
    2) string: the string containing the bytes
    3) integer: position of the first byte in the string
    4) integer: position of the last byte in the string
  Returns:
    1) integer: on success:  >= 0 number of bytes written
    1) integer: on failure:  -ve gemdos error number
    2) string: on success: empty string
    2) string: on failure: gemdos error string
*/
int l_Fwrites(lua_State *L) {
  const File *const fud = (File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  size_t str_len;
  const char *str = luaL_checklstring(L, 2, &str_len); /* String to write */
  const lua_Integer i = luaL_optinteger(L, 3, 1); /* Start */
  const lua_Integer j = luaL_optinteger(L, 4, -1); /* End */
  const lua_Integer index = i < 0 ? (lua_Integer) str_len + i : i - 1; /* Zero based */
  const lua_Integer end = j < 0 ? (lua_Integer) str_len + j + 1: j; /* One based */
  const lua_Integer count = end - index; /* Number of characters to write */
  lua_Integer remaining = count; /* Remaining characters to write */
  long result = 0;

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);
  /* Check that mode is not read only */
  luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_READ, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_ReadOnly]);
  /* Check starting index is within the string (zero based) */
  luaL_argcheck(L, index >= 0 && index < (lua_Integer) str_len, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Check ending index is within the string (one based) */
  luaL_argcheck(L, end > 0 && end <= (lua_Integer) str_len, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Zero based start index must be before one based end */
  luaL_argcheck(L, index < end, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Advance string pointer by zero based start index */
  str += index;

  /* Loop until no characters are remaining */
  while (remaining) {
    /* Write out up to BLOCK_SIZE bytes at a time */
    const long amount = remaining > BLOCK_SIZE ? BLOCK_SIZE : remaining;
    result = Fwrite(fud->handle, amount, str);
    if (result > 0) {
      /* wrote 'result' bytes, adjust remaining and advance str */
      remaining -= result;
      str += result;
    } else {
      /* Write failure */
      break;
    }
  }

  /* Result */
  lua_pushinteger(L, result < 0 ? result : count - remaining);
  /* Result string */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result < 0 ? result : 0));
  return 2;
}

/*
  Freadt. Read bytes from a file into an array table.
  Inputs:
    1) userdata: file
    2) integer: number of bytes to read
  Returns:
    1) integer: on success:  >= 0 number of bytes read
    1) integer: on failure:  -ve gemdos error number
    2) table: on success: array of integers holding bytes read
    2) string: on failure: gemdos error string
  Note:
    Can return less bytes than requested if EOF reached.
    Will return 0 bytes and empty table if EOF already reached.
*/
int l_Freadt(lua_State *L) {
  const File *const fud = (File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  const lua_Integer count = luaL_checkinteger(L, 2); /* Num bytes to read */
  lua_Integer remaining = count; /* Remaining bytes to read */
  long result = 0;
  long key_base = 1; /* Base key for table */
  unsigned char *buff; /* Pointer to temporary buffer */

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);
  /* Check that mode is not write only */
  luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_WRITE, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_WriteOnly]);
  /* Check count */
  luaL_argcheck(L, count >= 0, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Create table to hold the array */
  lua_createtable(L, count < INT_MAX ? (int) count : INT_MAX, 0);
  /* Userdata for temporary space */
  buff = lua_newuserdatauv(L, BLOCK_SIZE, 0);

  /* Loop while bytes are remaining to be read */
  while (remaining) {
    /* Amount to read up to BLOCK_SIZE */
    const long amount = remaining > BLOCK_SIZE ? BLOCK_SIZE : remaining;
    /* Read into the temporary buffer */
    result = Fread(fud->handle, amount, buff);
    if (result > 0) {
      /* At least one byte was read */
      short i;
      for (i = 0; i < result; ++i) {
        /* Push the byte as an integer */
        lua_pushinteger(L, buff[i]);
        /* Set the integer in the table */
        lua_rawseti(L, -3, i + key_base);
      }
      /* Adjust remaining bytes and the key base */
      remaining -= result;
      key_base += result;
    } else {
      /* Zero bytes read (EOF) or failure */
      break;
    }
  }

  lua_pop(L, 1); /* Pop temporary buffer */
  /* Push result */
  lua_pushinteger(L, result < 0 ? result : count - remaining);
  /* Rotate array table to top */
  lua_rotate(L, 3, 1);

  if (result < 0) {
    /* An error occurred - pop the result table */
    lua_pop(L, 1);
    /* And push an error message instead */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result));
  }

  /* Return result and array table */
  return 2;
}

/*
  Fwritet. Writes bytes from an array table into a file.
  Inputs:
    1) userdata: file
    2) table: the table containing the bytes as integers
    3) integer: position of the first value to write
    4) integer: position of the last value to write
  Returns:
    1) integer: on success:  >= 0 number of bytes written
    1) integer: on failure:  -ve gemdos error number
    2) string: gemdos error string
*/
int l_Fwritet(lua_State *L) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  const lua_Integer tbl_len =
    (luaL_checktype(L, 2, LUA_TTABLE), luaL_len(L, 2)); /* length of table */
  const lua_Integer i = luaL_optinteger(L, 3, 1); /* Start */
  const lua_Integer j = luaL_optinteger(L, 4, -1); /* End */
  const lua_Integer start = i < 0 ? tbl_len + i + 1 : i; /* One based start */
  const lua_Integer end = j < 0 ? tbl_len + j + 1 : j; /* One based end */
  const lua_Integer count = end - start + 1; /* Number of bytes to write */
  /* Userdata for temporary space */
  unsigned char *buff = lua_newuserdatauv(L, BLOCK_SIZE, 0);
  lua_Integer remaining = count; /* Remaining bytes to write */
  long result = 0;
  long key_base = start; /* Table key base */

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);
  /* Check that mode is not read only */
  luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_READ, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_ReadOnly]);
  /* Check the start is within the array */
  luaL_argcheck(L, start > 0 && start <= tbl_len, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Check that the end is in the array */
  luaL_argcheck(L, end > 0 && end <= tbl_len, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Check the start is not after the end */
  luaL_argcheck(L, start <= end, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Loop while bytes are remaining to write */
  while (remaining) {
    /* Write at most BLOCK_SIZE bytes at at a time */
    const long amount = remaining > BLOCK_SIZE ? BLOCK_SIZE : remaining;
    short i;
    for (i = 0; i < amount; ++i) {
      /* Get the integer from the table */
      lua_Integer integer = 0;
      lua_rawgeti(L, 2, i + key_base);
      /* Check the value is an integer and within byte range */
      luaL_argcheck(L, lua_isinteger(L, -1) &&
        (integer = lua_tointeger(L, -1)) >= 0 && integer <= 255, 2,
        TOSBINDL_ErrMess[TOSBINDL_EM_InvalidArrayValue]);

      /* Store in temporary buffer */
      buff[i] = (unsigned char) integer;
      /* Pop the integer */
      lua_pop(L, 1);
    }

    /* Write the temporary buffer to the file */
    result = Fwrite(fud->handle, amount, buff);
    if (result > 0) {
      /* At least one byte was written */
      remaining -= result;
      key_base += result;
    } else {
      /* Zero bytes written (EOF) or an error occurred */
      break;
    }
  }

  lua_pop(L, 1); /* Pop temporary buffer */

  /* Push the result */
  lua_pushinteger(L, result < 0 ? result : count - remaining);
  /* Push the result string */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result < 0 ? result : 0));

  return 2;
}

/*
  Fwritei. Writes an integer value representing a byte into a file
  Inputs:
    1) userdata: file
    2) integer: the value to write
  Returns:
    1) integer: on success:  >= 0 number of bytes written
    1) integer: on failure:  -ve gemdos error number
    2) string: gemdos error string
*/
int l_Fwritei(lua_State *L) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  const lua_Integer value_integer =
    luaL_checkinteger(L, 2); /* Check value is an integer */
  const unsigned char value_uchar =
    (const unsigned char) value_integer;   /* The byte to write */
  long result;

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);
  /* Check that mode is not read only */
  luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_READ, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_ReadOnly]);
  /* Check the integer is in range of a byte */
  luaL_argcheck(L, value_integer >= 0 && value_integer <= 255, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Write the byte */
  result = Fwrite(fud->handle, 1, &value_uchar);

  /* Result (-ve error, 0 EOF, 1 byte written) */
  lua_pushinteger(L, result);
  /* Error message */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result < 0 ? result : 0));

  return 2;
}

/*
  Freadi. Reads a value from a file
  Inputs:
    1) userdata: file
  Returns:
    1) integer: on success:  >= 0 number of bytes read (zero or one)
    1) integer: on failure:  -ve gemdos error number
    2) integer: on success: value holding byte read
    2) string: on failure: gemdos error string
  Note:
    Will return 0 bytes and value zero if EOF already reached.
*/
int l_Freadi(lua_State *L) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  unsigned char value; /* Holds the byte read */
  long result;

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);
  /* Check that mode is not write only */
  luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_WRITE, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_WriteOnly]);

  /* Read the byte */
  result = Fread(fud->handle, 1, &value);

  /* Result (-ve error, 0 EOF, 1 byte read) */
  lua_pushinteger(L, result);
  if (result < 0)
    /* An error occurred */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result));
  else {
    /* Success - push the byte read or zero if EOF */
    lua_pushinteger(L, result ? value : 0);
  }

  return 2;
}

static int MemoryIO(lua_State *L, short read) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  const Memory *const mud = (const Memory *) luaL_checkudata(L, 2,
    TOSBINDL_UD_T_Gemdos_Memory); /* Memory ud */
  const lua_Integer offset = luaL_checkinteger(L, 3); /* Memory offset */
  const lua_Integer count = luaL_checkinteger(L, 4); /* Number of bytes */
  lua_Integer remaining = count; /* Remaining bytes to I/O */
  long result = 0;
  unsigned char *ptr;

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);

  /* According to read flag, check the file userdata mode is compatible */
  if (read) {
    /* Check that mode is not write only */
    luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_WRITE, 1,
      TOSBINDL_ErrMess[TOSBINDL_EM_WriteOnly]);
  } else {
    /* Check that mode is not read only */
    luaL_argcheck(L, fud->mode != TOSBINDL_GEMDOS_FO_READ, 1,
      TOSBINDL_ErrMess[TOSBINDL_EM_ReadOnly]);
  }

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr && mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  /* Check offset */
  luaL_argcheck(L, offset >= 0, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Check offset and count is contained in the memory area */
  luaL_argcheck(L, count >= 0 && offset + count <= mud->size, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Pointer to memory offset */
  ptr = mud->ptr + offset;
  /* Loop while bytes remain to be I/O */
  while (remaining) {
    /* I/O up to BLOCK_SIZE bytes at a time */
    const long amount = remaining > BLOCK_SIZE ? BLOCK_SIZE : remaining;
    /* Read or write the data */
    result = read ?
      Fread(fud->handle, amount, ptr) : Fwrite(fud->handle, amount, ptr);
    if (result > 0) {
      /* At least a byte was I/O */
      remaining -= result;
      ptr += result;
    } else {
      /* Zero bytes I/O (EOF) or an error occurred */
      break;
    }
  }

  /* Push either error code or amount of bytes actually I/O */
  lua_pushinteger(L, result < 0 ? result : count - remaining);
  /* Push result string */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result < 0 ? result : 0));

  return 2;
}

/*
  Freadm. Read bytes from a file into memory
  Inputs:
    1) userdata: file
    2) userdata: memory
    3) integer: offset into memory area
    4) integer: number of bytes to read
  Returns:
    1) integer: on success:  >= 0 number of bytes read
    1) integer: on failure:  -ve gemdos error number
    2) string: gemdos error string
  Note:
    Can read less bytes than requested if EOF reached.
    Will read 0 bytes if EOF already reached.
*/
int l_Freadm(lua_State *L) {
  /* Perform read I/O */
  return MemoryIO(L, 1);
}

/*
  Fwritem. Write bytes from memory into file
  Inputs:
    1) userdata: file
    2) userdata: memory
    3) integer: offset into memory area
    4) integer: number of bytes to write
  Returns:
    1) integer: on success:  >= 0 number of bytes written
    1) integer: on failure:  -ve gemdos error number
    2) string: gemdos error string
*/
int l_Fwritem(lua_State *L) {
  /* Perform write I/O */
  return MemoryIO(L, 0);
}

/*
  Fseek. Seek position within a file.
  Inputs:
    1) userdata: file
    2) integer: relative position
    3) integer: seekmode relative to: 0 = beginning, 1 = current pos, 2 = end
  Returns:
    1) integer: on success:  >= 0 new absolute offset from start of file
    1) integer: on failure:  -ve gemdos error number
    2) string: gemdos error string
*/
int l_Fseek(lua_State *L) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  const lua_Integer rel_pos = luaL_checkinteger(L, 2); /* Rel. +ve or -ve */
  const lua_Integer seek_mode = luaL_checkinteger(L, 3); /* Rel. to */
  long result;

  /* Check file */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);
  /* Check seek mode */
  luaL_argcheck(L, seek_mode >= 0 && seek_mode <= 2, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Seek within the file */
  result = Fseek(rel_pos, fud->handle, seek_mode);

  /* Push -ve error code or absolute position relative to start */
  lua_pushinteger(L, result);
  /* Error string */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result < 0 ? result : 0));

  return 2;
}

/*
  Fdelete. Deletes a file
  Inputs:
    1) string: the name of the file to delete
  Returns:
    1) integer: gemdos error code
    2) string: gemdos error string
*/
int l_Fdelete(lua_State *L) {
  const char *const name = luaL_checkstring(L, 1);
  const long result = Fdelete(name);

  lua_pushinteger(L, result); /* Error code */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
  return 2;
}

/*
  Fclose. Closes a file
  Inputs:
    1) userdata: the file to close
  Returns:
    1) integer: gemdos error code
    2) string: gemdos error string
*/
int l_Fclose(lua_State *L) {
  File *const fud =
    (File *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_File); /* File ud */
  long result;

  /* Check pointer */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);

  /* Close the handle */
  result = Fclose(fud->handle);

  /* Mark userdata as no longer valid */
  fud->valid = 0;
  fud->handle = 0;
  fud->mode = 0;

  lua_pushinteger(L, result); /* Error code */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
  return 2;
}

/*
  Frename. Renames a file
  Inputs:
    1) string: the old name
    2) string: the new name
  Returns:
    1) integer: gemdos error code
    2) string: gemdos error string
*/
int l_Frename(lua_State *L) {
  const char *const old_name = luaL_checkstring(L, 1);
  const char *const new_name = luaL_checkstring(L, 2);

  /* Rename the file */
#if defined(__VBCC__)
  const long result = Frename(old_name, new_name);
#elif (defined(ATARI) && defined(LATTICE)) || \
    (defined(__GNUC__) && defined(__atarist__))
  const long result = Frename(0, old_name, new_name);
#else
  #error How to Frename on this compiler?
#endif

  lua_pushinteger(L, result); /* Error code */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
  return 2;
}

/*
  Fattrib. Get and set file attributes.
  Inputs:
    1) string: the name
    2) integer: flag 0 = get attributes 1 = set attributes
    3) integer: the attributes to set
  Returns:
    1) integer: flags or negtive gemdos error code
    2) string: gemdos error string
*/
int l_Fattrib(lua_State *L) {
  const char *const fname = luaL_checkstring(L, 1);
  const lua_Integer flag = luaL_checkinteger(L, 2); /* Get or set */
  const lua_Integer attr = luaL_optinteger(L, 3, 0); /* Attributes for set */
  long result;

  /* Check flag, it can be 0 or 1 */
  luaL_argcheck(L, !(flag & ~1), 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Attribute constraints: Cannot set directory or volume attribute. */
  luaL_argcheck(L,
    !(attr & ~(TOSBINDL_GEMDOS_FA_READONLY |
      TOSBINDL_GEMDOS_FA_HIDDEN |
      TOSBINDL_GEMDOS_FA_SYSTEM |
      TOSBINDL_GEMDOS_FA_ARCHIVE)),
    3, TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Get or set the attributes */
  result = Fattrib(fname, flag, attr);

  /* Error code or attributes */
  lua_pushinteger(L, result);
  /* Error string */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result < 0 ? result : 0));
  return 2;
}

/*
  Fdatime. Set or get file timestamp
  Inputs:
    1) userdata: file
    2) optional integer: year
    3) optional integer: month
    4) optional integer: day
    5) optional integer: hours
    6) optional integer: minutes
    7) optional integer: seconds
    Use A) When file and integers are passed, set the timestamp
    Use B) When only file is passed, get the timestamp
  Outputs:
    Use A)
    1) integer: gemdos error code
    2) string: gemdos error string
    Use B)
    1) integer: on success: >= 1980 year
    1) integer: on failure: -ve gemdos error number
    2) integer: on success: month
    2) string: on failure: gemdos error string
    3) integer: on success: day
    4) integer: on success: hours
    5) integer: on success: minutes
    6) integer: on success: seconds
*/
int l_Fdatime(lua_State *L) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  const lua_Integer year = luaL_optinteger(L, 2, 0); /* Year value or 0 */
  const short flag = year != 0; /* If year non-zero then setting datime */
#if (defined(__GNUC__) && defined(__atarist__))
  _DATETIME dt;
#else
  DATETIME dt;
#endif
  long result;

  if (flag) {
    /* Setting the datime */
    /* Obtain integer arguments */
    const lua_Integer month = luaL_optinteger(L, 3, 0);
    const lua_Integer day = luaL_optinteger(L, 4, 0);
    const lua_Integer hours = luaL_optinteger(L, 5, 0);
    const lua_Integer minutes = luaL_optinteger(L, 6, 0);
    const lua_Integer seconds = luaL_optinteger(L, 7, 0);

    /* Check arguments and set up DATETIME */
    int days_in_month;
    luaL_argcheck(L, year >= 1980 && year <= 2099, 2,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    luaL_argcheck(L, month >= 1 && month <= 12, 3,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    days_in_month = (month == 2 && !(year & 3)) ?
      29 : TOSBINDL_GEMDOS_DaysInMonth[month];
    luaL_argcheck(L, day >= 1 && day <= days_in_month, 4,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    luaL_argcheck(L, hours >= 0 && hours <= 23, 5,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    luaL_argcheck(L, minutes >= 0 && minutes <= 59, 6,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    luaL_argcheck(L, seconds >= 0 && seconds <= 59, 7,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

    dt.hour = (unsigned) hours & 0x1F;
    dt.minute = (unsigned) minutes & 0x3F;
    dt.second = ((unsigned) seconds >> 1) & 0x1F;
    dt.year = ((unsigned) year - 1980u) & 0x7F;
    dt.month = (unsigned) month & 0xF;
    dt.day = (unsigned) day & 0x1F;
  }

  /* Set or get the datime */
#if defined(__VBCC__)
  result = Fdatime(&dt, fud->handle, flag);
#elif (defined(ATARI) && defined(LATTICE)) || \
    (defined(__GNUC__) && defined(__atarist__))
  result = Fdatime((short *) &dt, fud->handle, flag);
#else
  #error How to Fdatime on this compiler?
#endif

  if (flag || result < 0) {
    /* If setting or an error occurred push the error code and error string */
    lua_pushinteger(L, result); /* Error code */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
    return 2;
  }

  /* Push the success result and the datime as integers */
  lua_pushinteger(L, result);
  lua_pushinteger(L, dt.year + 1980);
  lua_pushinteger(L, dt.month);
  lua_pushinteger(L, dt.day);
  lua_pushinteger(L, dt.hour);
  lua_pushinteger(L, dt.minute);
  lua_pushinteger(L, dt.second << 1);
  return 7;
}

/*
  Fdup. Duplicate standard file handle
  Inputs:
    1) integer: standard file handle (0 to 3)
  Returns:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
    2) userdata: on success: file
    2) string: on failure: gemdos error string
*/
int l_Fdup(lua_State *L) {
  const lua_Integer handle = luaL_checkinteger(L, 1); /* Std file handle */
  File *fud;
  long result;

  /* Check the standard file handle is in range */
  luaL_argcheck(L, handle >= TOSBINDL_GEMDOS_SH_CONIN &&
    handle <= TOSBINDL_GEMDOS_SH_PRN, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Push a file userdata to hold the duplicated handle */
  fud = PushFileUserData(L);

  /* Duplicate the handle */
  result = Fdup(handle);
  /* Negative result means the dup failed */
  if (result < 0) {
    lua_pop(L, 1); /* Fdup failed - pop userdata */
    lua_pushinteger(L, result); /* Error code */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
    return 2;
  }

  /* Duplication success. Set userdata values. */
  fud->valid = 1;
  if (handle == TOSBINDL_GEMDOS_SH_CONIN)
    fud->mode = TOSBINDL_GEMDOS_FO_READ; /* Input therefore read only */
  else if (handle == TOSBINDL_GEMDOS_SH_CONOUT)
    fud->mode = TOSBINDL_GEMDOS_FO_WRITE; /* Output therefore write only */
  else
    fud->mode = TOSBINDL_GEMDOS_FO_RW; /* I/O therefore read/write */

  /* Store the Gemdos handle in the userdata */
  fud->handle = (short) result;

  lua_pushinteger(L, 0); /* Push success result */
  lua_rotate(L, 2, 1); /* Rotate file userdata to top */

  /* Return success result and userdata */
  return 2;
}

/*
  Fforce. Force standard file handle to file handle
  Inputs:
    1) userdata: file
    2) integer: standard file handle (0 to 3)
  Returns:
    1) integer: gemdos error code
    2) string: gemdos error string
*/
int l_Fforce(lua_State *L) {
  const File *const fud = (const File *) luaL_checkudata(L, 1,
    TOSBINDL_UD_T_Gemdos_File); /* File ud */
  const lua_Integer handle = luaL_checkinteger(L, 2); /* Std file handle */
  long result;

  /* Check file userdata */
  luaL_argcheck(L, fud && fud->valid, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidFile]);

  /* Check the standard file handle is in range */
  luaL_argcheck(L, handle >= TOSBINDL_GEMDOS_SH_CONIN &&
    handle <= TOSBINDL_GEMDOS_SH_PRN, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Force the standard handle to file handle */
  result = Fforce(handle, fud->handle);

  lua_pushinteger(L, result); /* Error code */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */

  /* Return error code and error string */
  return 2;
}

/* Pushes the name from the DTA */
static int DtaName(lua_State *L) {
  const Dta *const dud =
    (const Dta *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Dta);
  const char *name;

#if (defined(__GNUC__) && defined(__atarist__))
  name = dud->dta.dta_name;
#else
  name = dud->dta.d_fname;
#endif

  lua_pushstring(L, name); /* Name */
  return 1;
}

/* Pushes the length from the DTA */
static int DtaLength(lua_State *L) {
  const Dta *const dud =
    (const Dta *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Dta);
  lua_Integer length;

#if (defined(__GNUC__) && defined(__atarist__))
  length = dud->dta.dta_size;
#else
  length = dud->dta.d_length;
#endif

  lua_pushinteger(L, length); /* Length */
  return 1;
}

/* Pushes the attribute from the DTA */
static int DtaAttr(lua_State *L) {
  const Dta *const dud =
    (const Dta *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Dta);
  lua_Integer attribute;

#if (defined(__GNUC__) && defined(__atarist__))
  attribute = dud->dta.dta_attribute; /* Attributes */
#else
  attribute = dud->dta.d_attrib; /* Attributes */
#endif

  lua_pushinteger(L, attribute); /* Attributes */
  return 1;
}

/* Pushes a string representation of the DTA for tostring */
static int DtaToString(lua_State *L) {
  const Dta *const dud = (const Dta *) lua_touserdata(L, 1); /* DTA ud */
  const char *name;

#if (defined(__GNUC__) && defined(__atarist__))
  name = dud->dta.dta_name; /* Name */
#else
  name = dud->dta.d_fname; /* Name */
#endif

  lua_pushfstring(L, "Dta: %s", name);
  return 1;
}

/* Pushes the datime from the DTA as integers */
static int DtaDatime(lua_State *L) {
  const Dta *const dud =
    (const Dta *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Dta);
#if (defined(__GNUC__) && defined(__atarist__))
  const _DATETIME *dt = (const _DATETIME *)&dud->dta.dta_time; /* datime */
#else
  const DATETIME *dt = (const DATETIME *)&dud->dta.d_time; /* datime */
#endif

  lua_pushinteger(L, dt->year + 1980);
  lua_pushinteger(L, dt->month);
  lua_pushinteger(L, dt->day);
  lua_pushinteger(L, dt->hour);
  lua_pushinteger(L, dt->minute);
  lua_pushinteger(L, dt->second << 1);
  return 6;
}

/* Copies the DTA userdata */
static int DtaCopydta(lua_State *L) {
  const Dta *const dud =
    (const Dta *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Dta);
  Dta *const new_dud = PushDtaUserData(L);
  memcpy(new_dud, dud, sizeof(Dta));
  return 1;
}

/*
  Pushes userdata TOSBINDL_UD_T_Gemdos_Dta
  Returns:
    1) userdata: TOSBINDL_UD_T_Gemdos_Dta
*/
static Dta *PushDtaUserData(lua_State *L) {
  /* DTA userdata */
  Dta *dud = lua_newuserdatauv(L, sizeof(Dta), 0);

#if (defined(__GNUC__) && defined(__atarist__))
  dud->dta.dta_name[0] = '\0';
#else
  dud->dta.d_fname[0] = '\0';
#endif

  /* Push metatable for type TOSBINDL_UD_T_Gemdos_Dta */
  if (luaL_getmetatable(L, TOSBINDL_UD_T_Gemdos_Dta) != LUA_TTABLE) {
    lua_pop(L, 1); 
    luaL_newmetatable(L, TOSBINDL_UD_T_Gemdos_Dta);

    /* Table for __index */
    lua_createtable(L, 0, 5);
    lua_pushcfunction(L, DtaName); /* Fn to push name from DTA */
    lua_setfield(L, -2, "name");
    lua_pushcfunction(L, DtaLength); /* Fn to push length from DTA */
    lua_setfield(L, -2, "length");
    lua_pushcfunction(L, DtaAttr); /* Fn to push attributes from DTA */
    lua_setfield(L, -2, "attr");
    lua_pushcfunction(L, DtaDatime); /* Fn to push datime from DTA */
    lua_setfield(L, -2, "datime");
    lua_pushcfunction(L, DtaCopydta); /* Fn to copy DTA userdata */
    lua_setfield(L, -2, "copydta");
    lua_pushcfunction(L, l_Fsnext); /* Fn to search next extry */
    lua_setfield(L, -2, "snext");
    /* Set __index on metatable */
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_index]);

    lua_pushcfunction(L, DtaToString); /* To string function */
    /* Set __tostring on metatable */
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_tostring]);
  }

  /* Set the metatable on the userdata */
  lua_setmetatable(L, -2);

  return dud;
}

/*
  Fsfirst. Search first entry in a directory
  Inputs:
    1) string: name
    2) integer: attributes
  Returns:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
    2) userdata: on success: dta
    2) string: on failure: gemdos error string
*/
int l_Fsfirst(lua_State *L) {
  const char *const name = luaL_checkstring(L, 1); /* Name to search */
  const lua_Integer attr = luaL_checkinteger(L, 2); /* Attribute to search */
  Dta *dud; /* Pointer to DTA userdata */
  void *original_dta; /* Pointer to the original DTA */
  long result;

  /* Check attributes are valid */
  luaL_argcheck(L,
    !(attr &
    ~(TOSBINDL_GEMDOS_FA_READONLY |
      TOSBINDL_GEMDOS_FA_HIDDEN |
      TOSBINDL_GEMDOS_FA_SYSTEM |
      TOSBINDL_GEMDOS_FA_VOLUME |
      TOSBINDL_GEMDOS_FA_DIR |
      TOSBINDL_GEMDOS_FA_ARCHIVE)),
    2, TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Push DTA userdata */
  dud = PushDtaUserData(L);

  /* Get original dta */
  original_dta = Fgetdta();

  /* Set dta to the userdata */
  Fsetdta(&dud->dta);

  /* Search first entry */
  result = Fsfirst(name, attr);

  /* Restore original dta */
  Fsetdta(original_dta);

  /* Negative result is an error */
  if (result < 0) {
    lua_pop(L, 1); /* Discard DTA userdata */

    /* Push error result and error string */
    lua_pushinteger(L, result); /* Error code */
    lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */
    return 2;
  }

  lua_pushinteger(L, 0); /* Success result */
  lua_rotate(L, 3, 1); /* Rotate DTA userdata to top */

  /* Return result and DTA userdata */
  return 2;
}

/*
  Fsnext. Search next entry in a directory
  Inputs:
    1) userdata: dta
  Returns:
    1) integer: gemdos error code
    2) string: gemdos error string
*/
int l_Fsnext(lua_State *L) {
  Dta *const dud =
    (Dta *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Dta); /* DTA ud */
  void *original_dta = Fgetdta(); /* Get original dta */
  long result;

  /* Set dta to the userdata */
  Fsetdta(&dud->dta);

  /* Search for the next entry */
  result = Fsnext();

  /* Restore original dta */
  Fsetdta(original_dta);

  /* Push the error code and error string */
  lua_pushinteger(L, result); /* Error code */
  lua_pushstring(L, TOSBINDL_GEMDOS_ErrMess(result)); /* Error string */

  /* Return error code and error string */
  return 2;
}
