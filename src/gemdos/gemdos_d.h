#ifndef GEMDOS_D_HEADER_INCLUDED
#define GEMDOS_D_HEADER_INCLUDED

struct lua_State;
int l_Dgetdrv(lua_State *L);
int l_Dsetdrv(lua_State *L);
int l_Dfree(lua_State *L);
int l_Dcreate(lua_State *L);
int l_Ddelete(lua_State *L);
int l_Dsetpath(lua_State *L);
int l_Dgetpath(lua_State *L);

#endif
