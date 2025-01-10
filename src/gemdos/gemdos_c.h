#ifndef GEMDOS_C_HEADER_INCLUDED
#define GEMDOS_C_HEADER_INCLUDED

struct lua_State;
int l_Cconin(lua_State *L);
int l_Cconout(lua_State *L);
int l_Cauxin(lua_State *L);
int l_Cauxout(lua_State *L);
int l_Cprnout(lua_State *L);
int l_Crawio(lua_State *L);
int l_Crawcin(lua_State *L);
int l_Cnecin(lua_State *L);
int l_Cconws(lua_State *L);
int l_Cconrs(lua_State *L);
int l_Cconis(lua_State *L);
int l_Cconos(lua_State *L);
int l_Cprnos(lua_State *L);
int l_Cauxis(lua_State *L);
int l_Cauxos(lua_State *L);

#endif
