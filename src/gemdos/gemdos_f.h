#ifndef GEMDOS_F_HEADER_INCLUDED
#define GEMDOS_F_HEADER_INCLUDED

struct lua_State;
int l_Fcreate(lua_State *L);
int l_Fopen(lua_State *L);
int l_Fclose(lua_State *L);
int l_Freads(lua_State *L);
int l_Fwrites(lua_State *L);
int l_Freadt(lua_State *L);
int l_Fwritet(lua_State *L);
int l_Freadm(lua_State *L);
int l_Fwritem(lua_State *L);
int l_Fwritei(lua_State *L);
int l_Freadi(lua_State *L);
int l_Fseek(lua_State *L);
int l_Fdelete(lua_State *L);
int l_Fseek(lua_State *L);
int l_Fattrib(lua_State *L);
int l_Fdup(lua_State *L);
int l_Fforce(lua_State *L);
int l_Frename(lua_State *L);
int l_Fdatime(lua_State *L);
int l_Fsfirst(lua_State *L);
int l_Fsnext(lua_State *L);

#endif
