#ifndef TOSBINDL_HEADER_INCLUDED
#define TOSBINDL_HEADER_INCLUDED

/* Error messages */
enum {
  TOSBINDL_EM_ReadOnly,
  TOSBINDL_EM_WriteOnly,
  TOSBINDL_EM_InvalidFile,
  TOSBINDL_EM_InvalidMemory,
  TOSBINDL_EM_InvalidArrayValue,
  TOSBINDL_EM_InvalidValue,
  TOSBINDL_EM_Max
};

extern const char *const TOSBINDL_ErrMess[TOSBINDL_EM_Max];

/* Wrap a table passed on the stack with a read-only proxy */
void TOSBINDL_ROProxy(lua_State *L);

/* Used for setting tables with string keys and integers from int values */
typedef struct TOSBINDL_RegInt {
  const char *name;
  int value;
} TOSBINDL_RegInt;

#define TOSBINDL_newinttable(L,l) \
  (lua_createtable(L, 0, sizeof(l)/sizeof((l)[0])), \
  TOSBINDL_setints(L, sizeof(l)/sizeof((l)[0]), l))

/* Registers all integers in the array l into the table on the top of the
stack with each key set to the name in the array. */
void TOSBINDL_setints(lua_State *L, int numints, const TOSBINDL_RegInt *l);

#define TOSBINDL_newinttable_fn(L,l,f) \
  (lua_createtable(L, 0, sizeof(l)/sizeof((l)[0])), \
  TOSBINDL_setints_fn(L, sizeof(l)/sizeof((l)[0]), l, f))

/* Registers all integers in the array l into the table on the top of the
stack with each key set to a string which is a function of the value. */
void TOSBINDL_setints_fn(lua_State *L, int numints,
  const int *l, const char *(*fn)(long));

#define TOSBINDL_LIBNAME "tosbindl"
LUAMOD_API int (luaopen_tosbindl)(lua_State *L);

#endif
