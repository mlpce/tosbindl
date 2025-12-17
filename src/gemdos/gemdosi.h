#ifndef GEMDOSI_HEADER_INCLUDED
#define GEMDOSI_HEADER_INCLUDED

#if (defined(__GNUC__) && defined(__atarist__))
#include <osbind.h>
#include <mint/ostruct.h>
#else
#include <tos.h>
#endif

/*
  Imode integer modes. Controls conversion between Lua integers
  and File or Memory data for the following userdata:
  TOSBINDL_UD_T_Gemdos_File: used for writet/readt/writei/readi functions.
  TOSBINDL_UD_T_Gemdos_Memory: used for writet/readt/poke/peek functions.
*/
#define TOSBINDL_GEMDOS_IMODE_S8 0    /* Signed 8 bit */
#define TOSBINDL_GEMDOS_IMODE_U8 1    /* Unsigned 8 bit */
#define TOSBINDL_GEMDOS_IMODE_S16 2   /* Signed 16 bit native endian */
#define TOSBINDL_GEMDOS_IMODE_U16 3   /* Unsigned 16 bit native endian */
#define TOSBINDL_GEMDOS_IMODE_S32 4   /* Signed 32 bit native endian */
#define TOSBINDL_GEMDOS_IMODE_NUM 5   /* Total number of imodes */

/* Convert total size in bytes to number of imode integer values */
#define IMODE_SIZE_TO_NVAL(imode, sz) \
  ((sz) >> TOSBINDL_GEMDOS_imode_sz_r[(imode)])
/* Convert number of imode integer values to total size in bytes */
#define IMODE_NVAL_TO_SIZE(imode, nv) \
  (((lua_Integer)(nv)) << TOSBINDL_GEMDOS_imode_sz_r[(imode)])
/* The minimum value of an integer for an imode */
#define IMODE_VALUE_MIN(imode) \
  (TOSBINDL_GEMDOS_imode_min_val[(imode)])
/* The maximum value of an integer for an imode */
#define IMODE_VALUE_MAX(imode) \
  (TOSBINDL_GEMDOS_imode_max_val[(imode)])

extern const unsigned char TOSBINDL_GEMDOS_imode_sz_r[
  TOSBINDL_GEMDOS_IMODE_NUM];
extern const long TOSBINDL_GEMDOS_imode_min_val[
  TOSBINDL_GEMDOS_IMODE_NUM];
extern const long TOSBINDL_GEMDOS_imode_max_val[
  TOSBINDL_GEMDOS_IMODE_NUM];

/* word and long access must use an even offset */
#define IMODE_OFFSET_CHECK_ALIGNED(imode, offset) \
  ((imode) <= TOSBINDL_GEMDOS_IMODE_U8 || !((offset) & 1))

/* Writes from lua_Integer to memory using imode.
NOTE(mlpce): only supports native endian. */
#define IMODE_WRITE_VALUE_MEM(imode, integer_value, char_ptr) \
  switch (imode) { \
    case TOSBINDL_GEMDOS_IMODE_S32: \
      *(long *) (char_ptr) = (long) (integer_value); \
      (char_ptr) += sizeof(long); \
      break; \
    case TOSBINDL_GEMDOS_IMODE_U16: \
    case TOSBINDL_GEMDOS_IMODE_S16: \
      *(short *) (char_ptr) = (short) (integer_value); \
      (char_ptr) += sizeof(short); \
      break; \
    case TOSBINDL_GEMDOS_IMODE_U8: \
    case TOSBINDL_GEMDOS_IMODE_S8: \
      *(char *) (char_ptr) = (char) (integer_value); \
      (char_ptr) += sizeof(char); \
      break; \
  }

/* Reads from memory into lua_Integer using imode.
NOTE(mlpce): only supports native endian. */
#define IMODE_READ_VALUE_MEM(imode, char_ptr, integer_value) \
  switch (imode) { \
    case TOSBINDL_GEMDOS_IMODE_S32: \
      *(integer_value) = *(const signed long *) (char_ptr); \
      (char_ptr) += sizeof(signed long); \
      break; \
    case TOSBINDL_GEMDOS_IMODE_U16: \
      *(integer_value) = *(const unsigned short *) (char_ptr); \
      (char_ptr) += sizeof(unsigned short); \
      break; \
    case TOSBINDL_GEMDOS_IMODE_S16: \
      *(integer_value) = *(const signed short *) (char_ptr); \
      (char_ptr) += sizeof(signed short); \
      break; \
    case TOSBINDL_GEMDOS_IMODE_U8: \
      *(integer_value) = *(const unsigned char *) (char_ptr); \
      (char_ptr) += sizeof(unsigned char); \
      break; \
    case TOSBINDL_GEMDOS_IMODE_S8: \
      *(integer_value) = *(const signed char *) (char_ptr); \
      (char_ptr) += sizeof(signed char); \
      break; \
  }

/* Writes from lua_Integer value to file using imode.
NOTE(mlpce): only supports native endian. */
#define IMODE_WRITE_VALUE_FILE(imode, value, handle) \
  (Fwrite((handle), \
  IMODE_NVAL_TO_SIZE((imode), 1), \
  ((const char *) &(value)) + sizeof(long) - IMODE_NVAL_TO_SIZE((imode), \
  1)))

/* Reads from file to buffer using imode to determine number of bytes. */
#define IMODE_READ_BUFF_FILE(imode, handle, buffer_ptr) \
  (Fread((handle), \
  IMODE_NVAL_TO_SIZE((imode), 1), \
  (buffer_ptr)))

#define TOSBINDL_GEMDOS_SH_CONIN 0
#define TOSBINDL_GEMDOS_SH_CONOUT 1
#define TOSBINDL_GEMDOS_SH_AUX 2
#define TOSBINDL_GEMDOS_SH_PRN 3

#define TOSBINDL_GEMDOS_FA_READONLY 0x01
#define TOSBINDL_GEMDOS_FA_HIDDEN 0x02
#define TOSBINDL_GEMDOS_FA_SYSTEM 0x04
#define TOSBINDL_GEMDOS_FA_VOLUME 0x08
#define TOSBINDL_GEMDOS_FA_DIR 0x10
#define TOSBINDL_GEMDOS_FA_ARCHIVE 0x20

#define TOSBINDL_GEMDOS_FO_READ 0
#define TOSBINDL_GEMDOS_FO_WRITE 1
#define TOSBINDL_GEMDOS_FO_RW 2

#define TOSBINDL_GEMDOS_MAX_MULTIVAL 16

#if (defined(ATARI) && defined(LATTICE))
#include <dos.h>

typedef struct {
  unsigned hour : 5;
  unsigned minute : 6;
  unsigned second : 5;
  unsigned year : 7;
  unsigned month : 4;
  unsigned day : 5;
} DATETIME;
#endif

#define TOSBINDL_GEMDOS_ERROR_EINVFN -32
#define TOSBINDL_GEMDOS_ERROR_EFILNF -33
#define TOSBINDL_GEMDOS_ERROR_EPTHNF -34
#define TOSBINDL_GEMDOS_ERROR_ENHNDL -35
#define TOSBINDL_GEMDOS_ERROR_EACCDN -36
#define TOSBINDL_GEMDOS_ERROR_EIHNDL -37
#define TOSBINDL_GEMDOS_ERROR_ENSMEM -39
#define TOSBINDL_GEMDOS_ERROR_EIMBA -40
#define TOSBINDL_GEMDOS_ERROR_EDRIVE -46
#define TOSBINDL_GEMDOS_ERROR_ENMFIL -49
#define TOSBINDL_GEMDOS_ERROR_ERANGE -64
#define TOSBINDL_GEMDOS_ERROR_EINTRN -65
#define TOSBINDL_GEMDOS_ERROR_EPLFMT -66
#define TOSBINDL_GEMDOS_ERROR_EGSBF -67

/* Convert a negative gemdos error value to an error string */
const char *TOSBINDL_GEMDOS_ErrMess(long err);

/* User data types */
extern const char *const TOSBINDL_UD_T_Gemdos_File;
extern const char *const TOSBINDL_UD_T_Gemdos_Memory;
extern const char *const TOSBINDL_UD_T_Gemdos_Dta;

/* Days in month */
extern const unsigned char TOSBINDL_GEMDOS_DaysInMonth[13];

/* Gets the GEMDOS environment pointer */
const char *const *TOSBINDL_GEMDOS_EnvP(lua_State *L);

#endif
