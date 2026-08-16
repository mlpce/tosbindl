#include <string.h>
#include <stdio.h>
#include <limits.h>

#if (defined(__GNUC__) && defined(__atarist__))
#include <osbind.h>
#include <mint/ostruct.h>
#else
#include <tos.h>
#endif

#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"

#include "src/gempb/tbgempb.h"

/* GEMPB binding version */
#define TBGEMPB_MAJOR_VERSION 1
#define TBGEMPB_MINOR_VERSION 0
#define TBGEMPB_MICRO_VERSION 0

/* VDI array sizes */
#define TBGEMPB_VDI_CONTROL_MAX 15
#define TBGEMPB_VDI_INTIN_MAX 1024
#define TBGEMPB_VDI_INTOUT_MAX 512
#define TBGEMPB_VDI_PTSIN_MAX 1024
#define TBGEMPB_VDI_PTSOUT_MAX 256

/* AES array sizes */
#define TBGEMPB_AES_CONTROL_MAX 5
#define TBGEMPB_AES_GLOBAL_MAX 16
#define TBGEMPB_AES_INTIN_MAX 16
#define TBGEMPB_AES_INTOUT_MAX 16
#define TBGEMPB_AES_ADDRIN_MAX 16
#define TBGEMPB_AES_ADDROUT_MAX 16

/* Parameter block array identifiers */
typedef enum TBGEMPB_PBId {
  /* VDI arrays */
  TBGEMPB_PBID_VDI_CONTROL,
  TBGEMPB_PBID_VDI_INTIN,
  TBGEMPB_PBID_VDI_PTSIN,
  TBGEMPB_PBID_VDI_INTOUT,
  TBGEMPB_PBID_VDI_PTSOUT,

  /* AES arrays */
  TBGEMPB_PBID_AES_CONTROL,
  TBGEMPB_PBID_AES_GLOBAL,
  TBGEMPB_PBID_AES_INTIN,
  TBGEMPB_PBID_AES_INTOUT,
  TBGEMPB_PBID_AES_ADDRIN,
  TBGEMPB_PBID_AES_ADDROUT,

  TBGEMPB_PBID_NUM_IDS
} TBGEMPB_PBId;

/* VDI parameter block */
typedef struct TBGEMPB_VDI_ParamBlock {
  short *control_ptr;
  short *intin_ptr;
  short *ptsin_ptr;
  short *intout_ptr;
  short *ptsout_ptr;
} TBGEMPB_VDI_ParamBlock;

/* AES parameter block */
typedef struct TBGEMPB_AES_ParamBlock {
  short *control_ptr;
  short *global_ptr;
  short *intin_ptr;
  short *intout_ptr;
  long  *addrin_ptr;
  long  *addrout_ptr;
} TBGEMPB_AES_ParamBlock;

typedef struct TBGEMPB_PBID_Entry {
  void *array;
  size_t data_size;
} TBGEMPB_PBID_Entry;

typedef struct TBGEMPB_ParamBlock {
  /* VDI arrays */
  struct {
    short control[TBGEMPB_VDI_CONTROL_MAX];
    short intin[TBGEMPB_VDI_INTIN_MAX];
    short ptsin[TBGEMPB_VDI_PTSIN_MAX];
    short intout[TBGEMPB_VDI_INTOUT_MAX];
    short ptsout[TBGEMPB_VDI_PTSOUT_MAX];
    TBGEMPB_VDI_ParamBlock pb;
  } vdi;

  /* AES arrays */
  struct {
    short control[TBGEMPB_AES_CONTROL_MAX];
    short global[TBGEMPB_AES_GLOBAL_MAX];
    short intin[TBGEMPB_AES_INTIN_MAX];
    short intout[TBGEMPB_AES_INTOUT_MAX];
    long  addrin[TBGEMPB_AES_ADDRIN_MAX];
    long  addrout[TBGEMPB_AES_ADDROUT_MAX];
    TBGEMPB_AES_ParamBlock pb;
  } aes;

  TBGEMPB_PBID_Entry pbid_array[TBGEMPB_PBID_NUM_IDS];
} TBGEMPB_ParamBlock;

static const int array_sizes[] = {
  /* VDI array sizes */
  TBGEMPB_VDI_CONTROL_MAX,
  TBGEMPB_VDI_INTIN_MAX,
  TBGEMPB_VDI_PTSIN_MAX,
  TBGEMPB_VDI_INTOUT_MAX,
  TBGEMPB_VDI_PTSOUT_MAX,

  /* AES array sizes */
  TBGEMPB_AES_CONTROL_MAX,
  TBGEMPB_AES_GLOBAL_MAX,
  TBGEMPB_AES_INTIN_MAX,
  TBGEMPB_AES_INTOUT_MAX,
  TBGEMPB_AES_ADDRIN_MAX,
  TBGEMPB_AES_ADDROUT_MAX
};

/* Userdata type names */
const char *const TOSBINDL_UD_T_GEMPB_Data = "gempb.data";

/* 
  GEM userdata to string function __tostring
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
  Returns:
    1) string: string representing the userdata
*/
static int GEMDataToString(lua_State *L) {
  const TBGEMPB_ParamBlock *const vud =
    (const TBGEMPB_ParamBlock *) lua_touserdata(L, 1);
  lua_pushfstring(L, "TBGEMPB_ParamBlock: %p", vud);
  return 1;
}

/*
  ArraySet.
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: array id
    3) integer: write offset
    3) integer: table containing 16 or 32 bit integer values
  Returns:
    None
*/
static int ArraySet(lua_State *L) {
  TBGEMPB_ParamBlock *const vud = (TBGEMPB_ParamBlock *)
    luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const lua_Integer pbid = luaL_checkinteger(L, 2); /* Id of array */
  const lua_Integer array_offset =
    luaL_checkinteger(L, 3); /* array write offset */
  const lua_Integer tbl_len = /* Length of table */
    (luaL_checktype(L, 4, LUA_TTABLE), luaL_len(L, 4));
  const TBGEMPB_PBID_Entry *pbid_entry_ptr;
  short *short_array_ptr;
  long *long_array_ptr;
  int data_size;
  lua_Integer key;

  /* Check array identifier */
  luaL_argcheck(L,
    pbid >= TBGEMPB_PBID_VDI_CONTROL && pbid < TBGEMPB_PBID_NUM_IDS, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check array offset is valid */
  luaL_argcheck(L,
    array_offset >= 0 && array_offset < array_sizes[pbid], 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check table length */
  luaL_argcheck(L,
    tbl_len >= 0 && tbl_len <= array_sizes[pbid] - array_offset, 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Pointer to the array and data size */
  pbid_entry_ptr = &vud->pbid_array[pbid];

  short_array_ptr = (short *)pbid_entry_ptr->array + array_offset;
  long_array_ptr = (long *)pbid_entry_ptr->array + array_offset;
  data_size = (int) pbid_entry_ptr->data_size;

  for (key = 1; key <= tbl_len; ++key) {
    /* Get the value for the table key */
    int isnum;
    lua_Integer integer;
    lua_rawgeti(L, 4, key);

    /* The value must be an integer and be within numeric range. For 16 bit
    data size values between SHRTMIN and USHRT_MAX are allowed (unsigned
    values are useful for e.g. vsf_udpat, vsl_udsty and vsc_form). */
    integer = lua_tointegerx(L, -1, &isnum);
    luaL_argcheck(L, isnum &&
      (data_size == 4 || (integer >= SHRT_MIN && integer <= USHRT_MAX)), 4,
      TOSBINDL_ErrMess[TOSBINDL_EM_InvalidArrayValue]);

    /* Copy the integer to the destination */
    if (data_size == 4)
      *long_array_ptr++ = integer;
    else
      *short_array_ptr++ = (short) integer;

    lua_pop(L, 1);
  }

  return 0;
}

/*
  ArrayGet.
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: array id
    3) integer: optional read offset (default 0)
    4) integer: optional num values to read (default size - offset)
  Returns:
    1) table: the integers read
*/
static int ArrayGet(lua_State *L) {
  const TBGEMPB_ParamBlock *const vud = (const TBGEMPB_ParamBlock *)
    luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const lua_Integer pbid = luaL_checkinteger(L, 2); /* Id of array */
  const lua_Integer array_offset =
    luaL_optinteger(L, 3, 0); /* array read offset */
  lua_Integer num_values;
  const TBGEMPB_PBID_Entry *pbid_entry_ptr;
  const short *short_array_ptr;
  const long *long_array_ptr;
  int data_size;
  lua_Integer key;

  /* Check array identifier */
  luaL_argcheck(L,
    pbid >= TBGEMPB_PBID_VDI_CONTROL && pbid < TBGEMPB_PBID_NUM_IDS, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check array offset is valid */
  luaL_argcheck(L,
    array_offset >= 0 && array_offset < array_sizes[pbid], 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Num vals to read */
  num_values = luaL_optinteger(L, 4, array_sizes[pbid] - array_offset);

  /* Check values to read fit the array size */
  luaL_argcheck(L, num_values >= 0 &&
    array_offset + num_values <= array_sizes[pbid], 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Pointer to the array and data size */
  pbid_entry_ptr = &vud->pbid_array[pbid];
  short_array_ptr = (const short *)pbid_entry_ptr->array + array_offset;
  long_array_ptr = (const long *)pbid_entry_ptr->array + array_offset;
  data_size = (int) pbid_entry_ptr->data_size;

  /* Push table to hold the array */
  lua_createtable(L, (int) num_values, 0);

  /* Loop key through the count */
  for (key = 1; key <= num_values; ++key) {
    /* Push the integer from the source */
    lua_pushinteger(L,
      data_size ==  4 ? *long_array_ptr++ : *short_array_ptr++);
    /* Set the value for the table key */
    lua_rawseti(L, -2, key);
  }

  /* Return the table */
  return 1;
}

/*
  ArrayPoke. Poke one or more values to an array
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: array id
    3) integer: array offset
    4) integer: 16 or 32 bit value depending on array
    5) ..., n
  Returns:
    None
*/
static int ArrayPoke(lua_State *L) {
  TBGEMPB_ParamBlock *const vud = (TBGEMPB_ParamBlock *)
    luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const lua_Integer pbid = luaL_checkinteger(L, 2); /* Id of array */
  const lua_Integer offset = luaL_checkinteger(L, 3); /* Offset */
  /* One or more integers to poke */
  const int top_index = (luaL_checkinteger(L, 4), lua_gettop(L));
  int index = 3;
  const TBGEMPB_PBID_Entry *pbid_entry_ptr; 

  /* Check array identifier */
  luaL_argcheck(L,
    pbid >= TBGEMPB_PBID_VDI_CONTROL && pbid < TBGEMPB_PBID_NUM_IDS, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check offset */
  luaL_argcheck(L,
    offset >= 0 && offset + (top_index - index) <= array_sizes[pbid], 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Pointer to the array and data size */
  pbid_entry_ptr = &vud->pbid_array[pbid];

  if (pbid_entry_ptr->data_size == 2) {
    short *ptr = (short *) pbid_entry_ptr->array + offset;
    while (++index <= top_index) {
      /* The value must be an integer and be within numeric range. Values
      between SHRTMIN and USHRT_MAX are allowed (unsigned values are useful
      for e.g. vsf_udpat, vsl_udsty and vsc_form). */
      const lua_Integer value = luaL_checkinteger(L, index); /* Value */ 
      luaL_argcheck(L, value >= SHRT_MIN && value <= USHRT_MAX, index,
        TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);
      *ptr++ = (short) value;
    }
  } else {
    long *ptr = (long *) pbid_entry_ptr->array + offset;
    while (++index <= top_index)
      *ptr++ = (long) luaL_checkinteger(L, index); /* Value */
  }

  return 0;
}

/*
  ArrayPeek. Peek one or more values from an array
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: array id
    3) integer: array offset
    4) integer: number of values to peek (default 1)
  Returns:
    1) integer: 16 or 32 bit value depending on array
    X) ..., n
*/
static int ArrayPeek(lua_State *L) {
  const TBGEMPB_ParamBlock *const vud = (const TBGEMPB_ParamBlock *)
    luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const lua_Integer pbid = luaL_checkinteger(L, 2); /* Id of array */
  const lua_Integer offset = luaL_checkinteger(L, 3); /* Offset */
  const lua_Integer num_values = luaL_optinteger(L, 4, 1); /* Num values */
  const TBGEMPB_PBID_Entry *pbid_entry_ptr;
  int remaining = (int) num_values;

  /* Check array identifier */
  luaL_argcheck(L,
    pbid >= TBGEMPB_PBID_VDI_CONTROL && pbid < TBGEMPB_PBID_NUM_IDS, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check offset */
  luaL_argcheck(L, offset >= 0 && offset < array_sizes[pbid], 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check num values */
  luaL_argcheck(L, num_values >= 0 &&
    offset + num_values <= array_sizes[pbid], 4,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Pointer to the array and data size */
  pbid_entry_ptr = &vud->pbid_array[pbid];

  /* Push the integer(s) from the array */
  luaL_checkstack(L, (int) num_values, "not enough stack");
  if (pbid_entry_ptr->data_size == 2) {
    const short *ptr = (const short *) pbid_entry_ptr->array + offset;
    while (remaining--)
      lua_pushinteger(L, *ptr++);
  } else {
    const long *ptr = (const long *) pbid_entry_ptr->array + offset;
    while (remaining--)
      lua_pushinteger(L, *ptr++);
  }

  return (int) num_values;
}

/*
  ArraySetStr. Sets the VDI intin array to a string
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: write offset
    3) string: string to write into the intin array
  Returns:
    None
*/
int ArraySetStr(lua_State *L) {
  TBGEMPB_ParamBlock *const vud =
    (TBGEMPB_ParamBlock *) luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const lua_Integer array_offset =
    luaL_checkinteger(L, 2); /* array write offset */
  size_t str_len;
  const char *str = luaL_checklstring(L, 3, &str_len); /* String to write */
  short *short_array_ptr = vud->vdi.intin + array_offset;

  /* Check array offset is valid */
  luaL_argcheck(L,
    array_offset >= 0 && array_offset < TBGEMPB_VDI_INTIN_MAX, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check string length */
  luaL_argcheck(L,
    (lua_Integer) str_len + array_offset <= TBGEMPB_VDI_INTIN_MAX, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Copy string into short array */
  while (str_len--)
    *short_array_ptr++ = (short) ((unsigned char) *str++);

  return 0;
}

/*
  ArrayGetStr. Gets a string from the VDI intout array
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: read offset
    3) integer: maximum number of characters to read
  Returns:
    1) string: the obtained string
*/
int ArrayGetStr(lua_State *L) {
  const TBGEMPB_ParamBlock *const vud =
    (const TBGEMPB_ParamBlock *) luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const lua_Integer array_offset =
    luaL_checkinteger(L, 2); /* array read offset */
  const lua_Integer count = luaL_checkinteger(L, 3);
  const short *short_array_ptr = vud->vdi.intout + array_offset;
  int remaining = (int) count;
  luaL_Buffer b; /* Buffer for string */
  const char *start;
  char *str;
  char c;

  /* Check array offset is valid */
  luaL_argcheck(L,
    array_offset >= 0 && array_offset < TBGEMPB_VDI_INTOUT_MAX, 2,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Check string length */
  luaL_argcheck(L,
    count >= 0 && count <= TBGEMPB_VDI_INTOUT_MAX - array_offset, 3,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Initialise the buffer */
  str = luaL_buffinitsize(L, &b, (size_t) count);
  start = str;

  /* Copy string from short array into buffer */
  while (remaining-- && (c = (char) *short_array_ptr++))
    *str++ = c;

  /* Push the string */
  luaL_pushresultsize(&b, (size_t) (str - start));
  return 1;
}

#if defined(__VBCC__)
__regsused("d0/d1/a0/a1") void do_vbcc_vdi_trap(__reg("d1")long) =
  "\tmove.l\td2,-(sp)\n"
  "\tmove.l\ta2,-(sp)\n"
  "\tmoveq\t#115,d0\n"
  "\ttrap\t#2\n"
  "\tmove.l\t(sp)+,a2\n"
  "\tmove.l\t(sp)+,d2";

__regsused("d0/d1/a0/a1") void do_vbcc_aes_trap(__reg("d1")long) =
  "\tmove.l\td2,-(sp)\n"
  "\tmove.l\ta2,-(sp)\n"
  "\tmove.w\t#200,d0\n"
  "\ttrap\t#2\n"
  "\tmove.l\t(sp)+,a2\n"
  "\tmove.l\t(sp)+,d2";
#elif defined(LATTICE)
void do_lc_vdi_trap(long pb);
void do_lc_aes_trap(long pb);
#endif

/*
  VDITrap.
  Inputs:
    1) integer: handle
    2) integer: opcode
    3) optional integer: subopcode (default 0)
    4) optional integer: nintin (default 0)
    5) optional integer: nptsin (default 0)
    6) optional integer: addr1 (default 0)
    7) optional integer: addr2 (default 0)
  Returns:
    None
*/
static int VDITrap(lua_State *L, TBGEMPB_ParamBlock *gud,
    unsigned short numval, int top_index, int index) {
  /* Obtain span and therefore number of values */
  const char *const err_mess = TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue];
  const int run_end_index = index + numval;
  /* Pointer to the array */
  short *const ctrl_array = (short *) gud->vdi.control;

  lua_Integer handle;
  lua_Integer opcode;
  lua_Integer subopcode;
  lua_Integer nintin;
  lua_Integer nptsin;
  lua_Integer addr1;
  lua_Integer addr2;

  /* Must be supplied with at least handle and opcode, and no more
  that seven values. Check there are enough values on the stack. */
  luaL_argcheck(L,
    numval >= 2 && numval <= 7 && numval <= top_index - index,
    index, err_mess);

  /* VDI handle - mandatory */
  handle = luaL_checkinteger(L, ++index);

  /* Opcode - mandatory */
  opcode = luaL_checkinteger(L, ++index);

  /* Subopcode - zero if missing */
  subopcode = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;

  /* Number of intint words - zero if missing */
  nintin = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;
  luaL_argcheck(L, nintin <= TBGEMPB_VDI_INTIN_MAX, index,  err_mess);

  /* Number of ptsin words - zero if missing */
  nptsin = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;
  luaL_argcheck(L, nptsin <= TBGEMPB_VDI_PTSIN_MAX/2, index,  err_mess);

  /* addr1 - zero if missing */
  addr1 = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;

  /* addr2 - zero if missing */
  addr2 = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;

  ctrl_array[0] = (short) opcode;
  ctrl_array[1] = (short) nptsin; /* Number of points in ptsin */
  ctrl_array[2] = 0;
  ctrl_array[3] = (short) nintin; /* Number of integers in intin */
  ctrl_array[4] = 0;
  ctrl_array[5] = (short) subopcode;
  ctrl_array[6] = (short) handle;
  ctrl_array[7] = (short) (addr1 >> 16);
  ctrl_array[8] = (short) addr1;
  ctrl_array[9] = (short) (addr2 >> 16);
  ctrl_array[10] = (short) addr2;

  if (opcode > 0) { /* opcode <= 0 used by unittests to avoid trap */
#ifdef __GNUC__
    register long d1 __asm__("d1") = (long)&gud->vdi.pb;

    __asm__ __volatile__ (
      "\tmoveq	#115,%%d0\n"
      "\ttrap	#2\n"
      : /* Output: none */
      : "r"(d1) /* Input: address of VDI parameter block */
      : "d0", "d2", "a0", "a1", "a2", "memory", "cc" /* Clobbered */
    );
#elif defined (__VBCC__)
    do_vbcc_vdi_trap((long)&gud->vdi.pb);
#elif defined (LATTICE)
    do_lc_vdi_trap((long)&gud->vdi.pb);
#else
    #error How to call VDI on this compiler?
#endif
  }

  return index + 1;
}

/*
  AESTrap.
  Inputs:
    1) integer: opcode
    2) optional integer: nintin (default 0)
    3) optional integer: nintout (default 0)
    4) optional integer: naddrin (default 0)
    5) optional integer: naddrout (default 0)
  Returns:
    None
*/
static int AESTrap(lua_State *L, TBGEMPB_ParamBlock *gud,
    unsigned short numval, int top_index, int index) {
  /* Obtain span and therefore number of values */
  const char *const err_mess = TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue];
  const int run_end_index = index + numval;
  /* Pointer to the array */
  short *const ctrl_array = (short *) gud->aes.control;

  lua_Integer opcode;
  lua_Integer nintin;
  lua_Integer nintout;
  lua_Integer naddrin;
  lua_Integer naddrout;

  /* Must be supplied with at least opcode and no more than five values.
  Check there are enough values on the stack. */
  luaL_argcheck(L,
    numval >= 1 && numval <= 5 && numval <= top_index - index,
    index, err_mess);

  /* AES opcode */
  opcode = luaL_checkinteger(L, ++index);

  /* Number of intint words */
  nintin = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;
  luaL_argcheck(L, nintin <= TBGEMPB_AES_INTIN_MAX, index,  err_mess);

  /* Number of intout words */
  nintout = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;
  luaL_argcheck(L, nintout <= TBGEMPB_AES_INTOUT_MAX, index, err_mess);

  /* Number of addrin longs */
  naddrin = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;
  luaL_argcheck(L, naddrin <= TBGEMPB_AES_ADDRIN_MAX, index, err_mess);

  /* Number of addrout longs */
  naddrout = index < run_end_index ? luaL_checkinteger(L, ++index) : 0;
  luaL_argcheck(L, naddrout <= TBGEMPB_AES_ADDROUT_MAX, index, err_mess);

  ctrl_array[0] = (short) opcode;
  ctrl_array[1] = (short) nintin;
  ctrl_array[2] = (short) nintout;
  ctrl_array[3] = (short) naddrin;
  ctrl_array[4] = (short) naddrout;

  if (opcode > 0) { /* opcode <= 0 used by unittests to avoid trap */
#ifdef __GNUC__
    register long d1 __asm__("d1") = (long)&gud->aes.pb;

    __asm__ __volatile__ (
      "\tmove.w	#200,%%d0\n"
      "\ttrap	#2\n"
      : /* Output: none */
      : "r"(d1) /* Input: address of AES parameter block */
      : "d0", "d2", "a0", "a1", "a2", "memory", "cc" /* Clobbered */
    );
#elif defined (__VBCC__)
    do_vbcc_aes_trap((long)&gud->aes.pb);
#elif defined (LATTICE)
    do_lc_aes_trap((long)&gud->aes.pb);
#else
    #error How to call AES on this compiler?
#endif
  }

  return index + 1;
}

/*
  Call. This function combines parameter block array setup, GEM trap and
  the reading of parameter block results into a single API call.
  Inputs:
    First stage is writing to zero or more parameter block arrays:
      1) integer: parameter block array identifier
      2) integer: high word = array offset, low word = num integers to write
      n) integer: integers to write to parameter block array
    Second stage occurs when array identifier is vdi_control or aes_control:
      1) integer: vdi_control or aes_control
      2) integer: low word = num integers to write to control array
      n) integer: integers to write to control array
    After last control array integer is written the VDI or AES trap is called
    and the third stage is then entered.
    The third stage reads from zero or more parameter block arrays pushing the
    integers onto the stack:
      1) integer: parameter block array identifier
      2) integer: high word = array offset, low word = num integers to read
  Returns:
    The third stage reads from zero or more parameter block arrays pushing the
    integers onto the stack:
      n) integer: integers read from parameter block array(s)
*/
static int Call(lua_State *L) {
  TBGEMPB_ParamBlock *const gud = (TBGEMPB_ParamBlock *)
    luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  /* One or more integers to poke */
  const int top_index = lua_gettop(L);
  const char *const err_mess = TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue];
  const TBGEMPB_PBID_Entry *pbid_entry_ptr; 
  int index = 2;
  lua_Integer pbid;  /* Id of array */
  lua_Integer span;  /* Span combining offset and number of values */
  unsigned short offset;  /* Offset from span */
  unsigned short numval;  /* Number of values from span */

  /* Stage one: Poke arrays until TBGEMPB_PBID_VDI_CONTROL or
  TBGEMPB_PBID_AES_CONTROL */
  while (index <= top_index - 1) {
    int run_end_index;

    /* Obtain array id and check it is valid */
    pbid = luaL_checkinteger(L, index); /* Id of array */
    luaL_argcheck(L,
      pbid >= TBGEMPB_PBID_VDI_CONTROL && pbid < TBGEMPB_PBID_NUM_IDS,
      index, err_mess);

    /* CONTROL completed? */
    if (pbid == TBGEMPB_PBID_VDI_CONTROL) {
      /* Stage two: Call VDI trap */
      const unsigned short numval =
        (unsigned short) luaL_checkinteger(L, ++index);
      index = VDITrap(L, gud, numval, top_index, index);
      /* Progress to stage three */
      break;
    } else if (pbid == TBGEMPB_PBID_AES_CONTROL) {
      /* Stage two: Call AES trap */
      const unsigned short numval =
        (unsigned short) luaL_checkinteger(L, ++index);
      index = AESTrap(L, gud, numval, top_index, index);
      /* Progress to stage three */
      break;
    }

    /* Obtain span and therefore offset and number of values */
    span = luaL_checkinteger(L, ++index);
    offset = (unsigned short) (((unsigned long) span) >> 16);
    numval = (unsigned short) span;

    /* Check offset and numval */
    luaL_argcheck(L,
      offset + numval <= array_sizes[pbid] &&
      numval <= top_index - index, index, err_mess);

    /* Determine stack index of run end */
    run_end_index = index + numval;
  
    /* Pointer to the array and data size */
    pbid_entry_ptr = &gud->pbid_array[pbid];

    /* Poke the indentified array */
    if (pbid_entry_ptr->data_size == 2) {
      short *ptr = (short *) pbid_entry_ptr->array + offset;
      while (++index <= run_end_index) {
        /* The value must be an integer and be within numeric range. Values
        between SHRTMIN and USHRT_MAX are allowed (unsigned values are useful
        for e.g. vsf_udpat, vsl_udsty and vsc_form). */
        const lua_Integer value = luaL_checkinteger(L, index); /* Value */ 
        luaL_argcheck(L, value >= SHRT_MIN && value <= USHRT_MAX, index,
          err_mess);
        *ptr++ = (short) value;
      }
    } else {
      long *ptr = (long *) pbid_entry_ptr->array + offset;
      while (++index <= run_end_index) {
        const lua_Integer value = (long) luaL_checkinteger(L, index); /* Value */
        *ptr++ = (long) value; /* Value */
      }
    }
  }

  /* Stage three: Peek arrays */
  while (index <= top_index - 1) {
    /* Obtain array id and check it is valid */
    pbid = luaL_checkinteger(L, index); /* Id of array */

    /* Check array id */
    luaL_argcheck(L,
      pbid >= TBGEMPB_PBID_VDI_CONTROL && pbid < TBGEMPB_PBID_NUM_IDS, index,
      err_mess);

    /* Obtain span and therefore offset and number of values */
    span = luaL_checkinteger(L, ++index);
    offset = (unsigned short) (((unsigned long) span) >> 16);
    numval = (unsigned short) span;

    /* Check offset and numval */
    luaL_argcheck(L,
      offset + numval <= array_sizes[pbid], index, err_mess);

    /* Pointer to the array and data size */
    pbid_entry_ptr = &gud->pbid_array[pbid];

    /* Push the integer(s) from the array */
    luaL_checkstack(L, (int) numval, "not enough stack");

    if (pbid_entry_ptr->data_size == 2) {
      const short *ptr = (const short *) pbid_entry_ptr->array + offset;
      while (numval--)
        lua_pushinteger(L, *ptr++);
    } else {
      const long *ptr = (const long *) pbid_entry_ptr->array + offset;
      while (numval--)
        lua_pushinteger(L, *ptr++);
    }

    ++index;
  }

  return lua_gettop(L) - top_index;
}

/*
  VDITrap_ctrl. Sets up ctrl array and calls VDI trap
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: workstation handle
    3) integer: opcode
    4) optional integer: subopcode (default 0)
    5) optional integer: n intin (default 0)
    6) optional integer: n ptsin (default 0)
    7) optional integer: address one (default 0)
    8) optional integer: address two (default 0)
  Returns:
    None
*/
static int VDITrap_ctrl(lua_State *L) {
  TBGEMPB_ParamBlock *const gud =
    (TBGEMPB_ParamBlock *) luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const int top_idx = lua_gettop(L);
  const int num_params = top_idx - 1;
  VDITrap(L, gud, (unsigned short) num_params, top_idx, 1);
  return 0;
}

/*
  AESTrap_ctrl. Sets up ctrl array and calls AES trap
  Inputs:
    1) userdata: TOSBINDL_UD_T_GEMPB_Data
    2) integer: opcode
    3) optional integer: n intin (default 0)
    4) optional integer: n intout (default 0)
    5) optional integer: n addrin (default 0)
    6) optional integer: n addrout (default 0)
  Returns:
    None
*/
static int AESTrap_ctrl(lua_State *L) {
  TBGEMPB_ParamBlock *const gud =
    (TBGEMPB_ParamBlock *) luaL_checkudata(L, 1, TOSBINDL_UD_T_GEMPB_Data);
  const int top_idx = lua_gettop(L);
  const int num_params = top_idx - 1;
  AESTrap(L, gud, (unsigned short) num_params, top_idx, 1);
  return 0;
}

static int l_create_pb(lua_State *L) {
  /* TBGEMPB_ParamBlock userdata */
  TBGEMPB_ParamBlock *gud =
    lua_newuserdatauv(L, sizeof(TBGEMPB_ParamBlock), 0);
  memset(gud, 0, sizeof(TBGEMPB_ParamBlock));

  /* Set up VDI parameter block */
  gud->vdi.pb.control_ptr = gud->vdi.control;
  gud->vdi.pb.intin_ptr = gud->vdi.intin;
  gud->vdi.pb.ptsin_ptr = gud->vdi.ptsin;
  gud->vdi.pb.intout_ptr = gud->vdi.intout;
  gud->vdi.pb.ptsout_ptr = gud->vdi.ptsout;

  /* Set up AES parameter block */
  gud->aes.pb.control_ptr = gud->aes.control;
  gud->aes.pb.global_ptr = gud->aes.global;
  gud->aes.pb.intin_ptr = gud->aes.intin;
  gud->aes.pb.intout_ptr = gud->aes.intout;
  gud->aes.pb.addrin_ptr = gud->aes.addrin;
  gud->aes.pb.addrout_ptr = gud->aes.addrout;

  /* Set up pbid_array VDI entries */
  gud->pbid_array[TBGEMPB_PBID_VDI_CONTROL].array = gud->vdi.control;
  gud->pbid_array[TBGEMPB_PBID_VDI_CONTROL].data_size =
    sizeof gud->vdi.control[0];

  gud->pbid_array[TBGEMPB_PBID_VDI_INTIN].array = gud->vdi.intin;
  gud->pbid_array[TBGEMPB_PBID_VDI_INTIN].data_size =
    sizeof gud->vdi.intin[0];

  gud->pbid_array[TBGEMPB_PBID_VDI_PTSIN].array = gud->vdi.ptsin;
  gud->pbid_array[TBGEMPB_PBID_VDI_PTSIN].data_size =
    sizeof gud->vdi.ptsin[0];

  gud->pbid_array[TBGEMPB_PBID_VDI_INTOUT].array = gud->vdi.intout;
  gud->pbid_array[TBGEMPB_PBID_VDI_INTOUT].data_size =
    sizeof gud->vdi.intout[0];

  gud->pbid_array[TBGEMPB_PBID_VDI_PTSOUT].array = gud->vdi.ptsout;
  gud->pbid_array[TBGEMPB_PBID_VDI_PTSOUT].data_size =
    sizeof gud->vdi.ptsout[0];

  /* Set up pbid_array AES entries */
  gud->pbid_array[TBGEMPB_PBID_AES_CONTROL].array = gud->aes.control;
  gud->pbid_array[TBGEMPB_PBID_AES_CONTROL].data_size =
    sizeof gud->aes.control[0];

  gud->pbid_array[TBGEMPB_PBID_AES_GLOBAL].array = gud->aes.global;
  gud->pbid_array[TBGEMPB_PBID_AES_GLOBAL].data_size =
    sizeof gud->aes.global[0];

  gud->pbid_array[TBGEMPB_PBID_AES_INTIN].array = gud->aes.intin;
  gud->pbid_array[TBGEMPB_PBID_AES_INTIN].data_size =
    sizeof gud->aes.intin[0];

  gud->pbid_array[TBGEMPB_PBID_AES_INTOUT].array = gud->aes.intout;
  gud->pbid_array[TBGEMPB_PBID_AES_INTOUT].data_size =
    sizeof gud->aes.intout[0];

  gud->pbid_array[TBGEMPB_PBID_AES_ADDRIN].array = gud->aes.addrin;
  gud->pbid_array[TBGEMPB_PBID_AES_ADDRIN].data_size =
    sizeof gud->aes.addrin[0];

  gud->pbid_array[TBGEMPB_PBID_AES_ADDROUT].array = gud->aes.addrout;
  gud->pbid_array[TBGEMPB_PBID_AES_ADDROUT].data_size =
    sizeof gud->aes.addrout[0];

  /* Push new metatable for type TOSBINDL_UD_T_GEMPB_Data */
  if (luaL_getmetatable(L, TOSBINDL_UD_T_GEMPB_Data) != LUA_TTABLE) {
    static const luaL_Reg funcs[] = {
      {"vdi", VDITrap_ctrl},
      {"aes", AESTrap_ctrl},
      {"set", ArraySet},
      {"get", ArrayGet},
      {"poke", ArrayPoke},
      {"peek", ArrayPeek},
      {"setstr", ArraySetStr},
      {"getstr", ArrayGetStr},
      {"call", Call},
      {NULL, NULL}
    };

    static const luaL_Reg meta_funcs[] = {
      {"__tostring", GEMDataToString},
      {NULL, NULL}
    };

    lua_pop(L, 1); 
    luaL_newmetatable(L, TOSBINDL_UD_T_GEMPB_Data);

    /* Table for __index */
    luaL_newlib(L, funcs);
    lua_setfield(L, -2, "__index");

    /* Meta functions */
    luaL_setfuncs(L, meta_funcs, 0);
  }

  /* Set the metatable on the userdata */
  lua_setmetatable(L, -2);

  /* Return userdata */
  return 1;
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
  lua_pushinteger(L, TBGEMPB_MAJOR_VERSION);
  lua_pushinteger(L, TBGEMPB_MINOR_VERSION);
  lua_pushinteger(L, TBGEMPB_MICRO_VERSION);
  return 3;
}

#ifdef __VBCC__
__regsused("d0/d1/a0/a1") long do_vbcc_vq_gdos_trap(void) =
  "\tmove.l\td2,-(sp)\n"
  "\tmove.l\ta2,-(sp)\n"
  "\tmoveq\t#-2,d0\n"
  "\ttrap\t#2\n"
  "\tcmp.w #-2,d0\n"
  "\tsne d0\n"
  "\text.w d0\n"
  "\tmove.l\t(sp)+,a2\n"
  "\tmove.l\t(sp)+,d2";
#elif defined(LATTICE)
long do_lc_vq_gdos_trap(void);
#endif

/*
  vq_gdos. Query presence of GDOS.
  Inputs:
    None
  Returns:
    1) integer: non-zero if GDOS present.
*/
static int l_vq_gdos(lua_State *L) {
#ifdef __GNUC__
  register long d0 __asm__("d0");

	__asm__ __volatile__ (
		"\tmoveq	#-2,%%d0\n"
		"\ttrap	#2\n"
		"\tcmp.w	#-2,%%d0\n"
		"\tsne		%%d0\n"
		"\text.w	%%d0\n"
		: "=r"(d0) /* Output: query result */
		: /* Input: none */
		: "d1", "d2", "a0", "a1", "a2", "memory", "cc" /* Clobbered */
	);

  lua_pushinteger(L, (short) d0);
#elif defined(__VBCC__)
  lua_pushinteger(L, (short) do_vbcc_vq_gdos_trap());
#elif defined(LATTICE)
  lua_pushinteger(L, (short) do_lc_vq_gdos_trap());
#else
  #error How to call VDI on this compiler?
#endif

  return 1;
}

/*
  ScrDevId. Obtain the screen device id.
  Inputs:
    None
  Returns:
    1) integer: screen device id
*/
static int ScrDevId(lua_State *L) {
  lua_pushinteger(L, Getrez() + 2);
  return 1;
}

static const struct luaL_Reg gempb[] = {
  {"create_pb", l_create_pb},
  {NULL, NULL}
};

int luaopen_gempb(lua_State *L) {
  /* gempb.const.Pbid table keys and values */
  static const TOSBINDL_RegInt pbid_ints[] = {
    {"vdi_control", TBGEMPB_PBID_VDI_CONTROL},
    {"vdi_intin", TBGEMPB_PBID_VDI_INTIN},
    {"vdi_ptsin", TBGEMPB_PBID_VDI_PTSIN},
    {"vdi_intout", TBGEMPB_PBID_VDI_INTOUT},
    {"vdi_ptsout", TBGEMPB_PBID_VDI_PTSOUT},
    {"aes_control", TBGEMPB_PBID_AES_CONTROL},
    {"aes_global", TBGEMPB_PBID_AES_GLOBAL},
    {"aes_intin", TBGEMPB_PBID_AES_INTIN},
    {"aes_intout", TBGEMPB_PBID_AES_INTOUT},
    {"aes_addrin", TBGEMPB_PBID_AES_ADDRIN},
    {"aes_addrout", TBGEMPB_PBID_AES_ADDROUT}
  };

  static const TOSBINDL_RegInt pbsize_ints[] = {
    {"vdi_control", TBGEMPB_VDI_CONTROL_MAX},
    {"vdi_intin", TBGEMPB_VDI_INTIN_MAX},
    {"vdi_intout", TBGEMPB_VDI_INTOUT_MAX},
    {"vdi_ptsin", TBGEMPB_VDI_PTSIN_MAX},
    {"vdi_ptsout", TBGEMPB_VDI_PTSOUT_MAX},
    {"aes_control", TBGEMPB_AES_CONTROL_MAX},
    {"aes_global", TBGEMPB_AES_GLOBAL_MAX},
    {"aes_intin", TBGEMPB_AES_INTIN_MAX},
    {"aes_intout", TBGEMPB_AES_INTOUT_MAX},
    {"aes_addrin", TBGEMPB_AES_ADDRIN_MAX},
    {"aes_addrout", TBGEMPB_AES_ADDROUT_MAX}
  };

  /* gempb.utility table keys and functions */
  static const luaL_Reg util_funcs[] = {
    {"version", Version},
    {"scr_devid", ScrDevId},
    {"vq_gdos", l_vq_gdos},
    {NULL, NULL}
  };

  /* gempb table */
  luaL_newlib(L, gempb);

  /* Table to hold Constant tables */
  lua_newtable(L);

  /* Parameter block array id constants */
  TOSBINDL_newinttable(L, pbid_ints);
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Pbid in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Pbid");

  /* Parameter block array size constants */
  TOSBINDL_newinttable(L, pbsize_ints);
  /* Make the table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name Pbsize in Constant table to have Proxy table as
  value */
  lua_setfield(L, -2, "Pbsize");

  /* Make the Constant table readonly */
  TOSBINDL_ROProxy(L);

  /* Set field with name const in gempb table to have Constant table as
  value */
  lua_setfield(L, -2, "const");

  /* Table to hold utility functions */
  luaL_newlib(L, util_funcs);
  /* Set field with name utility in gembp table to have Utility table as
  value */
  lua_setfield(L, -2, "utility");

  /* Return the gempb table */
  return 1;
}
