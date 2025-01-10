#ifndef TOSBINDL_HEADER_INCLUDED
#define TOSBINDL_HEADER_INCLUDED

/* Error messages */
enum {
  TOSBINDL_EM_ReadOnly,
  TOSBINDL_EM_WriteOnly,
  TOSBINDL_EM_InvalidFile,
  TOSBINDL_EM_InvalidMemory,
  TOSBINDL_EM_InvalidHandle,
  TOSBINDL_EM_NotInString,
  TOSBINDL_EM_NotInArray,
  TOSBINDL_EM_NotInMemory,
  TOSBINDL_EM_UnexpectedArrayValue,
  TOSBINDL_EM_StartAfterEnd,
  TOSBINDL_EM_BadOpenMode,
  TOSBINDL_EM_BadAttr,
  TOSBINDL_EM_BadSeekMode,
  TOSBINDL_EM_BadFlag,
  TOSBINDL_EM_NegativeValue,
  TOSBINDL_EM_InvalidValue,
  TOSBINDL_EM_InvalidDrive,
  TOSBINDL_EM_InvalidYear,
  TOSBINDL_EM_InvalidMonth,
  TOSBINDL_EM_InvalidDay,
  TOSBINDL_EM_InvalidHours,
  TOSBINDL_EM_InvalidMinutes,
  TOSBINDL_EM_InvalidSeconds,
  TOSBINDL_EM_Max
};

extern const char *const TOSBINDL_ErrMess[TOSBINDL_EM_Max];

enum {
  TOSBINDL_MMFN_gc,
  TOSBINDL_MMFN_close,
  TOSBINDL_MMFN_tostring,
  TOSBINDL_MMFN_index,
  TOSBINDL_MMFN_newindex,
  TOSBINDL_MMFN_pairs,
  TOSBINDL_MMFN_Max
};

/* Metamethod names */
extern const char *const TOSBINDL_MMF_Names[TOSBINDL_MMFN_Max];

/* Wrap a table passed on the stack with a read-only proxy */
void TOSBINDL_ROProxy(lua_State *L);

#endif
