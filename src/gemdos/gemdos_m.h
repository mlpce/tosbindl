#ifndef GEMDOS_M_HEADER_INCLUDED
#define GEMDOS_M_HEADER_INCLUDED

typedef struct Memory {
  unsigned char *ptr;
  lua_Integer size;
} Memory;

struct lua_State;
int l_Malloc(lua_State *L);
int l_Mfree(lua_State *L);
int l_Mshrink(lua_State *L);

#endif
