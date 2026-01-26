#include <assert.h>
#include <string.h>
#include <limits.h>

#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_m.h"

/*
  Mark the memory userdata as invalid.
*/
static void InvalidateMemoryUserData(Memory *mud) {
  mud->ptr = NULL;
  mud->size = 0;
}

/*
  Free memory
  Inputs:
    1) userdata: TOSBINDL_UD_T_Gemdos_Memory
*/
static int MemoryFree(lua_State *L) {
  Memory *const mud = (Memory *) lua_touserdata(L, 1); /* Memory userdata */
  if (mud && mud->ptr) {
    /* Free the Gemdos memory */
    const long result = Mfree(mud->ptr);
    if (result < 0) {
      (void) Cconws("MemoryFree: ");
      (void) Cconws(TOSBINDL_GEMDOS_ErrMess(result));
      (void) Cconws("\r\n");
    }

    /* userdata is no longer valid */
    InvalidateMemoryUserData(mud);
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
  Writes values from an array table into a memory.
  Inputs:
    1) userdata: memory
    2) integer: imode controlling Lua integer conversion
    3) integer: destination offset into the memory
    4) table: the table containing the values as integers
    5) optional integer: position of the first value to write
    6) optional integer: position of the last value to write
  Returns:
    1) integer: number of bytes written into the memory
*/
static int MemoryWritet(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer imode = luaL_checkinteger(L, 2); /* Integer mode */
  const lua_Integer offset = luaL_checkinteger(L, 3); /* Offset into memory */
  const lua_Integer tbl_len =
    (luaL_checktype(L, 4, LUA_TTABLE), luaL_len(L, 4)); /* Length of table */
  const lua_Integer i = luaL_optinteger(L, 5, 1); /* Start */
  const lua_Integer j = luaL_optinteger(L, 6, -1); /* End */
  const lua_Integer start_key = i < 0 ? tbl_len + i + 1 : i; /* One based */
  const lua_Integer end_key = j < 0 ? tbl_len + j + 1 : j; /* One based end */
  const lua_Integer count = end_key - start_key + 1; /* Number of values */
  lua_Integer num_bytes; /* Number of bytes written */
  lua_Integer key;
  unsigned char *dest; /* Destination write pointer */

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  /* Check integer mode */
  luaL_argcheck(L, imode >= TOSBINDL_GEMDOS_IMODE_S8 &&
    imode <= TOSBINDL_GEMDOS_IMODE_S32, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Offset must not be negative, must be within the memory size
  and must be aligned according to imode */
  luaL_argcheck(L,
    offset >= 0 && offset < mud->size &&
    IMODE_OFFSET_CHECK_ALIGNED(imode, offset),
    3, TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Table start key must be in the array */
  luaL_argcheck(L, start_key > 0 && start_key <= tbl_len, 5,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Table end key must be in the array */
  luaL_argcheck(L, end_key > 0 && end_key <= tbl_len, 6,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Start key must not be after the end key */
  luaL_argcheck(L, start_key <= end_key, 5,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Number of bytes to be written */
  num_bytes = IMODE_NVAL_TO_SIZE(imode, count);

  /* Check write fits into memory */
  luaL_argcheck(L,
    offset + num_bytes <= mud->size,
    3, TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Destination write pointer starts at memory plus offset */
  dest = mud->ptr + offset;
  /* Loop through each key */
  for (key = start_key; key <= end_key; ++key) {
    /* Get the value for the table key */
    int isnum;
    lua_Integer integer;
    lua_rawgeti(L, 4, key);
    /* The value must be an integer or convertable to an integer
    and be within imode value range */
    integer = lua_tointegerx(L, -1, &isnum);
    luaL_argcheck(L, isnum &&
      integer >= IMODE_VALUE_MIN(imode) &&
      integer <= IMODE_VALUE_MAX(imode), 4,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidArrayValue]);

    /* Copy the value to the destination */
    IMODE_WRITE_VALUE_MEM(imode, integer, dest)

    /* Pop the value */
    lua_pop(L, 1);
  }

  /* Number of bytes written */
  lua_pushinteger(L, num_bytes);
  return 1;
}

/*
  Memory userdata function "readt".
  Read values from a memory into an array table.
  Inputs:
    1) userdata: memory
    2) integer: imode controlling Lua integer conversion
    3) integer: offset
    4) optional integer: number of values to read (offset to end if missing)
  Returns:
    1) integer: number of bytes read
    2) table: an array of integers holding values read
*/
static int MemoryReadt(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer imode = luaL_checkinteger(L, 2); /* Integer mode */
  const lua_Integer offset = luaL_checkinteger(L, 3); /* Offset into memory */
  lua_Integer count; /* Number of values read */
  lua_Integer num_bytes; /* Number of bytes read */
  const unsigned char *src; /* Source read pointer */
  lua_Integer key;

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  /* Check integer mode */
  luaL_argcheck(L, imode >= TOSBINDL_GEMDOS_IMODE_S8 &&
    imode <= TOSBINDL_GEMDOS_IMODE_S32, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Offset must not be negative, must be within the memory size
  and must be aligned according to imode */
  luaL_argcheck(L,
    offset >= 0 && offset < mud->size &&
    IMODE_OFFSET_CHECK_ALIGNED(imode, offset), 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Number of values to read */
  count = luaL_optinteger(L, 4,
    IMODE_SIZE_TO_NVAL(imode, mud->size - offset));
  /* Number of bytes read */
  num_bytes = IMODE_NVAL_TO_SIZE(imode, count);

  /* Count must not be negative and check read is within the memory */
  luaL_argcheck(L,
    count >= 0 && offset + num_bytes <= mud->size, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Push number of bytes read */
  lua_pushinteger(L, num_bytes);
  /* Push table to hold the array */
  lua_createtable(L, count < INT_MAX ? (int) count : INT_MAX, 0);

  /* Source read pointer starts at memory plus offset */
  src = mud->ptr + offset;

  /* Loop key through the count */
  for (key = 1; key <= count; ++key) {
    /* Read the value and push as an integer */
    lua_Integer integer_value = 0;
    IMODE_READ_VALUE_MEM(imode, src, &integer_value)
    lua_pushinteger(L, integer_value);

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
  Reads bytes from a memory into a string, optionally ending early when an
  arbitary termination byte is encountered.
  Inputs:
    1) userdata: memory
    2) integer: offset
    3) optional integer: number of bytes to read (offset to end if missing)
    4) optional integer: early termination byte (e.g. 0 for c string memory)
  Returns:
    1) integer: number of bytes read
    2) string: bytes read
*/
static int MemoryReads(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer offset = luaL_checkinteger(L, 2); /* Memory offset */
  const int arg_4_type = lua_type(L, 4); /* Early termination argument */
  const unsigned char *src_ptr; /* Source pointer */
  lua_Integer count; /* Number of bytes read */
  luaL_Buffer b; /* Buffer for string */
  char *str; /* Pointer to string within buffer */

  /* Check arguments */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  luaL_argcheck(L, offset >= 0 && offset < mud->size, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  src_ptr = mud->ptr + offset;

  /* Read count */
  count = luaL_optinteger(L, 3, mud->size - offset);
  luaL_argcheck(L, count >= 0 && offset + count <= mud->size, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check for read early termination byte if specified */
  if (arg_4_type != LUA_TNIL &&
      arg_4_type != LUA_TNONE) {
    const lua_Integer term = luaL_checkinteger(L, 4);
    const unsigned char *check_ptr = src_ptr;
    const unsigned char *end_ptr = check_ptr + count; 
    unsigned char tc;

    luaL_argcheck(L, term >= -128 && term <= 255, 4,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    tc = (unsigned char) term;

    /* Scan for early termination byte */
    while (check_ptr < end_ptr) {
      if (*check_ptr == tc) {
        /* Change count to end before the termination byte */
        count = check_ptr - src_ptr;
        break;
      }
      ++check_ptr;
    }
  }

  /* Number of bytes read */
  lua_pushinteger(L, count);
  /* Copy bytes into string buffer */
  str = luaL_buffinitsize(L, &b, (size_t) count);
  memcpy(str, src_ptr, (size_t) count);

  /* Push string */
  luaL_pushresultsize(&b, (size_t) count);

  return 2;
}

/*
  Memory userdata function "poke"
  Poke one or more values from integers into a memory.
  Inputs:
    1) userdata: memory
    2) integer: imode controlling Lua integer conversion
    3) integer: offset
    4) integer: the first value
    5) ..., n
  Returns:
    1) integer: the number of bytes written
*/
int MemoryPoke(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer imode = luaL_checkinteger(L, 2); /* Integer mode */
  const lua_Integer offset = luaL_checkinteger(L, 3); /* Memory offset */
  /* One or more integers to poke */
  const int top_index = (luaL_checkinteger(L, 4), lua_gettop(L));
  int index = 3;
  const int num_poked = top_index - index;
  lua_Integer num_bytes; /* Number of bytes written */
  unsigned char *dest; /* Destination pointer within memory */

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  /* Check integer mode */
  luaL_argcheck(L, imode >= TOSBINDL_GEMDOS_IMODE_S8 &&
    imode <= TOSBINDL_GEMDOS_IMODE_S32, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Number of bytes to be written */
  num_bytes = IMODE_NVAL_TO_SIZE(imode, num_poked);

  /* Check offset. */
  luaL_argcheck(L,
    offset >= 0 && offset + num_bytes <= mud->size &&
    IMODE_OFFSET_CHECK_ALIGNED(imode, offset),
    3, TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  dest = mud->ptr + offset;

  while (++index <= top_index) {
    const lua_Integer value = luaL_checkinteger(L, index); /* Value */ 
    luaL_argcheck(L,
      value >= IMODE_VALUE_MIN(imode) && value <= IMODE_VALUE_MAX(imode),
      index, TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
    IMODE_WRITE_VALUE_MEM(imode, value, dest)
  }

  /* Push number of bytes written */
  lua_pushinteger(L, num_bytes);

  /* Return number of bytes written */
  return 1;
}

/*
  Memory userdata function "peek".
  Peek zero or more values from a memory.
  Inputs:
    1) userdata: memory
    2) integer: imode controlling Lua integer conversion
    3) integer: offset
    4) integer: number of values to peek (default 1 maximum 16 minimum 0)
  Returns:
    X) integers: the values peeked
*/
int MemoryPeek(lua_State *L) {
  const Memory *const mud =
    (const Memory *) luaL_checkudata(L, 1, TOSBINDL_UD_T_Gemdos_Memory);
  const lua_Integer imode = luaL_checkinteger(L, 2); /* Integer mode */
  const lua_Integer offset = luaL_checkinteger(L, 3); /* Memory offset */
  const lua_Integer num_values = luaL_optinteger(L, 4, 1); /* Num values */
  int remaining = (int) num_values;
  const unsigned char *ptr;

  /* Check memory */
  luaL_argcheck(L, mud && mud->ptr, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidMemory]);
  /* Check integer mode */
  luaL_argcheck(L, imode >= TOSBINDL_GEMDOS_IMODE_S8 &&
    imode <= TOSBINDL_GEMDOS_IMODE_S32, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
  /* Check offset. */
  luaL_argcheck(L,
    offset >= 0 && offset < mud->size &&
    IMODE_OFFSET_CHECK_ALIGNED(imode, offset), 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check num values */
  luaL_argcheck(L, num_values >= 0 &&
    num_values <= TOSBINDL_GEMDOS_MAX_MULTIVAL &&
    offset + IMODE_NVAL_TO_SIZE(imode, num_values) <= mud->size, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  ptr = mud->ptr + offset;

  /* Push the integer(s) from the memory */
  luaL_checkstack(L, (int) num_values, "not enough stack");
  while (remaining--) {
    lua_Integer integer_value = 0;
    IMODE_READ_VALUE_MEM(imode, ptr, &integer_value)
    lua_pushinteger(L, integer_value);
  }

  return (int) num_values;
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
  /* userdata is not yet valid */
  InvalidateMemoryUserData(mud);

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

    static const luaL_Reg meta_funcs[] = {
      {"__gc", MemoryGC},
      {"__close", MemoryClose},
      {"__tostring", MemoryToString},
      {NULL, NULL}
    };

    lua_pop(L, 1); 
    luaL_newmetatable(L, TOSBINDL_UD_T_Gemdos_Memory);

    /* Table for __index */
    luaL_newlib(L, funcs);
    lua_setfield(L, -2, "__index");

    /* Meta functions */
    luaL_setfuncs(L, meta_funcs, 0);
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
  InvalidateMemoryUserData(mud);

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
