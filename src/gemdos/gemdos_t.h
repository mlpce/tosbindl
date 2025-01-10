#ifndef GEMDOS_T_HEADER_INCLUDED
#define GEMDOS_T_HEADER_INCLUDED

struct lua_State;
int l_Tgetdate(lua_State *L);
int l_Tsetdate(lua_State *L);
int l_Tgettime(lua_State *L);
int l_Tsettime(lua_State *L);

#endif
