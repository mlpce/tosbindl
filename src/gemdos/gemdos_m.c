#include <assert.h>
#include <string.h>
#include <limits.h>

#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_m.h"

/*
  Free memory
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
*/
static int MemoryFree(lua_State *L) {
  Memory *const mud = (Memory *) lua_touserdata(L, 1); /* Memory userdata */
  void *memory = mud->ptr;
  if (memory) {
    /* Free the Gemdos memory */
    const long result = Mfree(memory);
    if (result < 0) {
      (void) Cconws("MemoryFree: ");
      (void) Cconws(TOSBINDL_GEMDOS_ErrMess(result));
      (void) Cconws("\r\n");
    }
    mud->ptr = NULL;
    mud->size = 0;
  }
 
  return 0;
}

/* 
  Memory userdata garbage collection function __gc
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
*/
static int MemoryGC(lua_State *L) {
  return MemoryFree(L);
}

/* 
  Memory userdata close function __close
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
*/
static int MemoryClose(lua_State *L) {
  return MemoryFree(L);
}

/* 
  Memory userdata to string function __tostring
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
  Returns:
    1) string: string representing the userdata
*/
static int MemoryToString(lua_State *L) {
  const Memory *const mud =
    (const Memory *) lua_touserdata(L, 1); /* Memory userdata */
  lua_pushfstring(L, "p: %p s: %I", mud->ptr, (lua_Integer) mud->size);
  return 1;
}

/*
  Memory userdata function "address"
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
  Returns:
    1) integer: Address of allocated memory
*/
static int MemoryGetAddress(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  lua_pushinteger(L, (lua_Integer) mud->ptr);
  return 1;
}

/*
  Memory userdata function "size"
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
  Returns:
    1) integer: Size of memory in bytes
*/
static int MemoryGetSize(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  lua_pushinteger(L, (lua_Integer) mud->size);
  return 1;
}

/*
  Memory userdata function "writet"
  Writes bytes from an array table into a memory.
  Inputs:
    1) userdata: memory
    2) integer: destination offset into the memory
    3) table: the table containing the bytes as integers
    4) optional integer: position of the first value to write
    5) optional integer: position of the last value to write
  Returns:
    1) integer: number of bytes written into the memory
*/
static int MemoryWritet(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Offset into memory */
  const lua_Integer tbl_len =
    (luaL_checktype(L, 3, LUA_TTABLE), luaL_len(L, 3)); /* Length of table */
  const lua_Integer i = luaL_optinteger(L, 4, 1); /* Start */
  const lua_Integer j = luaL_optinteger(L, 5, -1); /* End */
  const lua_Integer start_key = i < 0 ? tbl_len + i + 1 : i; /* One based */
  const lua_Integer end_key = j < 0 ? tbl_len + j + 1 : j; /* One based end */
  const lua_Integer count = end_key - start_key + 1; /* Number of bytes */
  lua_Integer key;
  unsigned char *dest; /* Destination write pointer */

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  /* Offset must not be negative and offset must be within the memory size */
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Table start key must be in the array */
  luaL_argcheck(L, start_key > 0 && start_key <= tbl_len, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Table end key must be in the array */
  luaL_argcheck(L, end_key > 0 && end_key <= tbl_len, 5,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Start key must not be after the end key */
  luaL_argcheck(L, start_key <= end_key, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check write fits into memory */
  luaL_argcheck(L, offset + count <= mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Destination write pointer starts at memory plus offset */
  dest = mud->ptr + offset;
  /* Loop through each key */
  for (key = start_key; key <= end_key; ++key) {
    /* Get the value for the table key */
    lua_Integer integer = 0;
    lua_rawgeti(L, 3, key);
    /* The value must be an integer and be within byte range */
    luaL_argcheck(L, lua_isinteger(L, -1) &&
      (integer = lua_tointeger(L, -1)) >= 0 && integer <= 255, 3,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidArrayValue]);

    /* Copy the byte to the destination */
    *dest++ = (unsigned char) integer;
    /* Pop the value */
    lua_pop(L, 1);
  }

  lua_pushinteger(L, count); /* Number of bytes written */
  return 1;
}

/*
  Memory userdata function "readt".
  Read bytes from a memory into an array table.
  Inputs:
    1) userdata: memory
    2) integer: offset
    3) optional integer: number of bytes to read (offset to end if missing)
  Returns:
    1) integer: number of bytes read
    2) table: on array of integers holding bytes read
*/
static int MemoryReadt(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Offset into memory */
  lua_Integer count; /* Number of bytes read */
  const unsigned char *src; /* Source read pointer */
  lua_Integer key;

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  /* Offset must not be negative and must fit within the memory size */
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Number of bytes to read */
  count = luaL_optinteger(L, 3, mud->size - offset);
  /* Count must not be negative and check read is within the memory */
  luaL_argcheck(L, count >= 0 && offset + count <= mud->size, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Push number of bytes read */
  lua_pushinteger(L, count);
  /* Push table to hold the array */
  lua_createtable(L, count < INT_MAX ? (int) count : INT_MAX, 0);

  /* Source read pointer starts at memory plus offset */
  src = mud->ptr + offset;

  /* Loop key through the count */
  for (key = 1; key <= count; ++key) {
    /* Read the byte and push as an integer */
    lua_pushinteger(L, *src++);
    /* Set the value for the table key */
    lua_rawseti(L, -2, key);
  }

  return 2;
}

/*
  Memory userdata function "writes".
  Writes bytes from a string into a memory.
  Inputs:
    1) userdata: memory
    2) integer: offset
    3) string: the string containing the bytes
    4) integer: position of the first byte in the string
    5) integer: position of the last byte in the string
  Returns:
    1) integer: the number of bytes written
*/
static int MemoryWrites(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Offset into memory */
  size_t str_len; /* String length */
  const char *const str = luaL_checklstring(L, 3, &str_len); /* String */
  const lua_Integer i = luaL_optinteger(L, 4, 1); /* One based start */
  const lua_Integer j = luaL_optinteger(L, 5, -1); /* One based end */
  const lua_Integer zero_based_index = i < 0 ?
    (lua_Integer) str_len + i : i - 1;
  const lua_Integer one_based_end_index = j < 0 ?
    (lua_Integer) str_len + j + 1: j;
  const lua_Integer count = one_based_end_index - zero_based_index;

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check string */
  luaL_argcheck(L, zero_based_index >= 0 &&
    zero_based_index < (lua_Integer) str_len, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  luaL_argcheck(L, one_based_end_index > 0 &&
    one_based_end_index <= (lua_Integer) str_len,
    5, TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  luaL_argcheck(L, zero_based_index < one_based_end_index, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check write fits into memory */
  luaL_argcheck(L, offset + count <= mud->size, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Copy from string into memory */
  memcpy(mud->ptr + offset, str + zero_based_index, (size_t) count);
  /* Number of bytes copied */
  lua_pushinteger(L, count);

  return 1;
}

/*
  Memory userdata function reads.
  Reads bytes from a memory into a string.
  Inputs:
    1) userdata: memory
    2) integer: offset
    3) optional integer: number of bytes to read (offset to end if missing)
  Returns:
    1) integer: number of bytes read
    2) string: bytes read
*/
static int MemoryReads(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Memory offset */
  lua_Integer count; /* Number of bytes read */
  luaL_Buffer b; /* Buffer for string */
  char *str; /* Pointer to string within buffer */

  /* Check arguments */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  count = luaL_optinteger(L, 3, mud->size - offset);
  luaL_argcheck(L, count >= 0 && offset + count <= mud->size, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Number of bytes read */
  lua_pushinteger(L, count);
  /* Copy bytes into string buffer */
  str = luaL_buffinitsize(L, &b, (size_t) count);
  memcpy(str, mud->ptr + offset, (size_t) count);

  /* Push string */
  luaL_pushresultsize(&b, (size_t) count);

  return 2;
}

/*
  Memory userdata function "poke"
  Writes byte from integer into a memory.
  Inputs:
    1) userdata: memory
    2) integer: offset
    3) integer: the byte
  Returns:
    1) integer: the old byte value
*/
static int MemoryPoke(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Memory offset */
  const lua_Integer i = luaL_checkinteger(L, 3); /* Value to poke */
  unsigned char *dest; /* Destination pointer within memory */

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  luaL_argcheck(L, i >= 0 && i <= 255, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  dest = mud->ptr + offset;

  /* Push old value */
  lua_pushinteger(L, *dest);

  /* Set new value */
  *dest = (unsigned char) i;

  /* Return old value */
  return 1;
}

/*
  Memory userdata function "peek".
  Reads a byte from memory into an integer.
  Inputs:
    1) userdata: memory
    2) integer: offset
  Returns:
    1) integer: the byte value
*/
static int MemoryPeek(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Memory offset */

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Push byte as an integer value */
  lua_pushinteger(L, *(mud->ptr + offset));

  return 1;
}

static int MemoryOp(lua_State *L, short copy) {
  const Memory *const dst_mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer dst_offset = luaL_checkinteger(L, 2); /* Memory offset */
  const Memory *const src_mud = (const Memory *) luaL_checkudata(L, 3,
    TOSBINDL_UD_T_Gemdos_Memory); /* Source memory userdata */
  const lua_Integer src_offset = luaL_checkinteger(L, 4); /* Source offset */
  const lua_Integer length = luaL_checkinteger(L, 5); /* Data length */
  lua_Integer result;

  /* Check destination */
  luaL_argcheck(L, dst_mud && dst_mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]); 
  luaL_argcheck(L, dst_offset >= 0 && dst_offset < dst_mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check source */
  luaL_argcheck(L, src_mud && src_mud->ptr, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]); 
  luaL_argcheck(L, src_offset >= 0 && src_offset < src_mud->size, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check length */
  luaL_argcheck(L, length >= 0 &&
    dst_offset + length <= dst_mud->size &&
    src_offset + length <= src_mud->size, 5,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  if (copy) {
    /* Copy data between same or different memories */
    memmove(dst_mud->ptr + dst_offset, src_mud->ptr + src_offset,
      (size_t) length);
    result = length;
  } else {
    /* Compare data between same or different memories */
    result = memcmp(dst_mud->ptr + dst_offset, src_mud->ptr + src_offset,
      (size_t) length);
  }

  /* Return number of bytes copied or result of memcmp */
  lua_pushinteger(L, result);
  return 1;
}

/*
  Memory userdata function "copym".
  Copies data between two memories.
  Inputs:
    1) userdata: destination memory
    2) integer: destination offset
    3) userdata: source memory
    4) integer: source offset
    5) integer: length of data
  Returns:
    1) integer: number of bytes copied
*/
static int MemoryCopym(lua_State *L) {
  return MemoryOp(L, 1);
}

/*
  Memory userdata function "comparem".
  Compares data between two memories.
  Inputs:
    1) userdata: memory
    2) integer: offset
    3) userdata: other memory
    4) integer: other offset
    5) integer: length of data
  Returns:
    1) integer: memcmp result
*/
static int MemoryComparem(lua_State *L) {
  return MemoryOp(L, 0);
}

/*
  Memory userdata function "set".
  Sets memory to a byte value.
  Inputs:
    1) userdata: destination memory
    2) integer: destination offset
    3) integer: byte value
    4) optional integer: number of bytes to set (default offset to end)
  Returns:
    1) integer: number of bytes set
*/
static int MemorySet(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Memory offset */
  const lua_Integer i = luaL_checkinteger(L, 3); /* Value to set */
  lua_Integer length; /* Length of data to set */

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check value is in range of byte */
  luaL_argcheck(L, i >= 0 && i <= 255, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check offset and length */
  length = luaL_optinteger(L, 4, mud->size - offset);
  luaL_argcheck(L, length >= 0 && offset + length <= mud->size, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Set the memory data */
  memset(mud->ptr + offset, (int) i, (size_t) length);

  /* Return number of bytes set */
  lua_pushinteger(L, length);
  return 1;
}

/*
  Malloc. Allocate memory
  Inputs:
    integer: either -1 or greater than 0
    Use A) 1) -1 obtains the size of largest block of free memory
    Use B) 1) >0 allocates memory
  Returns:
    Use A) 1) integer: when obtaining the size of largest block of free memory
    Use B) 1) integer: on success: number of bytes allocated
    Use B) 1) integer: on failure: gemdos error code
    Use B) 2) userdata: on success: memory
*/
int l_Malloc(lua_State *L) {
  const lua_Integer amount = luaL_checkinteger(L, 1);
  Memory *mud;

  /* -1 to get size of the largest block of free memory,
  otherwise the number of bytes to allocate */
  luaL_argcheck(L, amount == -1 || amount > 0, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  if (amount == -1) {
    /* Return integer : the largest block of free memory */
    lua_pushinteger(L, (lua_Integer) Malloc(amount));
    return 1;
  }

  /* Create userdata to hold the Memory */
  mud = lua_newuserdatauv(L, sizeof(Memory), 0);
  mud->ptr = NULL;
  mud->size = 0;

  /* Push metatable for type TOSBINDL_UD_T_Gemdos_Memory */
  if (luaL_getmetatable(L, TOSBINDL_UD_T_Gemdos_Memory) != LUA_TTABLE) {
    static const luaL_Reg funcs[] = {
      {"address", MemoryGetAddress},
      {"size", MemoryGetSize},
      {"writet", MemoryWritet},
      {"readt", MemoryReadt},
      {"writes", MemoryWrites},
      {"reads", MemoryReads},
      {"poke", MemoryPoke},
      {"peek", MemoryPeek},
      {"comparem", MemoryComparem},
      {"copym", MemoryCopym},
      {"set", MemorySet},
      {"free", l_Mfree},
      {"shrink", l_Mshrink},
      {NULL, NULL}
    };

    lua_pop(L, 1); 
    luaL_newmetatable(L, TOSBINDL_UD_T_Gemdos_Memory);

    /* Table for __index */
    luaL_newlib(L, funcs);
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_index]);

    /* Garbage collection function */
    lua_pushcfunction(L, MemoryGC);
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_gc]);

    /* Close function */
    lua_pushcfunction(L, MemoryClose);
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_close]);

    /* To string function */
    lua_pushcfunction(L, MemoryToString);
    lua_setfield(L, -2, TOSBINDL_MMF_Names[TOSBINDL_MMFN_tostring]);
  }

  /* Set the metatable on the userdata */
  lua_setmetatable(L, -2);

  /* Allocate the memory and store ptr and size in userdata */
  mud->ptr = (unsigned char *) Malloc(amount);

  if (!mud->ptr) {
    lua_pop(L, 1); /* Malloc failed - pop user data */
    lua_pushinteger(L, TOSBINDL_GEMDOS_ERROR_ENSMEM);
    return 1;
  }

  mud->size = amount;
  lua_pushinteger(L, amount); /* Number of bytes allocated */
  lua_rotate(L, 2, 1); /* Rotate userdata to top */

  /* Return number of bytes allocated and userdata */
  return 2;
}

/*
  Mfree. Free memory.
  Input:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
  Returns:
    1) integer: zero on success or -ve gemdos error number
*/
int l_Mfree(lua_State *L) {
  Memory *const mud =
    (Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  long result;

  /* Check pointer */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);

  /* Free the memory */
  result = Mfree(mud->ptr); 
  mud->ptr = NULL;
  mud->size = 0;

  lua_pushinteger(L, result); /* Error code */

  /* Return error code */
  return 1;
}

/*
  Mshrink. Shrink memory.
  Input:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
    2) integer: number of bytes to keep allocated
  Returns:
    1) integer: number of bytes kept on success or -ve gemdos error number
*/
int l_Mshrink(lua_State *L) {
  Memory *const mud =
    (Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer size = luaL_checkinteger(L, 2);
  long result;

  /* Check pointer */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);

  /* Shrink */
  result = Mshrink(mud->ptr, size);
  if (!result)
    mud->size = size;

  lua_pushinteger(L, result < 0 ? result : size); /* Error code or new size */

  /* Return error code or size */
  return 1;
}
