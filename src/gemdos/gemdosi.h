#ifndef GEMDOSI_HEADER_INCLUDED
#define GEMDOSI_HEADER_INCLUDED

#if (defined(__GNUC__) && defined(__atarist__))
#include <osbind.h>
#include <mint/ostruct.h>
#else
#include <tos.h>
#endif

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
const char **TOSBINDL_GEMDOS_EnvP(lua_State *L);

#endif
