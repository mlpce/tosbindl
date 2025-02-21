#include "lua.h"
#include "lauxlib.h"

#include "src/tosbindl.h"
#include "src/gemdos/gemdosi.h"
#include "src/gemdos/gemdos_d.h"

/*
  Dgetdrv. Get the default drive.
  Returns:
    1) integer: the default drive (A:=0, B:=1, C:=2, ...)
*/
int l_Dgetdrv(lua_State *L) {
  const short default_drive = Dgetdrv();

  /* Return the default drive */
  lua_pushinteger(L, default_drive);
  return 1;
}

/*
  Dsetdrv. Set the default drive and obtain available drives.
  Inputs:
    1) integer: the drive to set as default (A:=0, B:=1, C:=2, ...)
  Returns:
    1) integer: bits indicating available drives  (1:=A, 2:=B, 4:=C, ...)
*/
int l_Dsetdrv(lua_State *L) {
  const lua_Integer drive = luaL_checkinteger(L, 1);
  long result;

  /* Check argument, A:=0, B:=1, ... */
  luaL_argcheck(L, drive >= 0 && drive <= 15, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  result = Dsetdrv(drive);

  /* Return an integer with bits set to indicate available drives */
  lua_pushinteger(L, result);
  return 1;
}

/*
  Dfree. Obtain the disk free information.
  Inputs:
    1) integer: 0 current drive, otherwise A:=1, B:=2, C:=3, ...
  Returns:
    1) integer: on success: number of free clusters
    1) integer: on failure: -ve gemdos error number
    2) integer: on success: total number of clusters
    3) integer: on success: sector size in bytes
    4) integer: on success: cluster size in sectors    
*/
int l_Dfree(lua_State *L) {
  const lua_Integer drive = luaL_checkinteger(L, 1);
  long result;
  lua_Integer number_free_clusters;
  lua_Integer total_number_of_clusters;
  lua_Integer sector_size_in_bytes;
  lua_Integer cluster_size_in_sectors;

#if defined(__VBCC__)
  DISKINFO disk_info;
#elif (defined(ATARI) && defined(LATTICE))
  struct DISKINFO disk_info;
#elif (defined(__GNUC__) && defined(__atarist__))
  _DISKINFO disk_info;
#else
  #error What type for DISKINFO for this compiler?
#endif

  /* Check argument, 0 is current drive, A:=1, B:=2, ... */
  luaL_argcheck(L, drive >= 0 && drive <= 16, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

#if defined(__VBCC__)
  result = Dfree(&disk_info, drive);
  number_free_clusters = disk_info.b_free;
  total_number_of_clusters = disk_info.b_total;
  sector_size_in_bytes = disk_info.b_secsize;
  cluster_size_in_sectors = disk_info.b_clsize;
#elif (defined(ATARI) && defined(LATTICE))
  result = Dfree(&disk_info.free, drive);
  number_free_clusters = disk_info.free;
  total_number_of_clusters = disk_info.cpd;
  sector_size_in_bytes = disk_info.bps;
  cluster_size_in_sectors = disk_info.spc;
#elif (defined(__GNUC__) && defined(__atarist__))
  result = Dfree(&disk_info.b_free, drive);
  number_free_clusters = disk_info.b_free;
  total_number_of_clusters = disk_info.b_total;
  sector_size_in_bytes = disk_info.b_secsiz;
  cluster_size_in_sectors = disk_info.b_clsiz;
#else
  #error How to call Dfree for this compiler?
#endif

  if (result < 0) {
    /* Return result */
    lua_pushinteger(L, result);
    return 1;
  }

  lua_pushinteger(L, number_free_clusters);
  lua_pushinteger(L, total_number_of_clusters);
  lua_pushinteger(L, sector_size_in_bytes);
  lua_pushinteger(L, cluster_size_in_sectors);
  return 4;
}

/*
  Dcreate. Create a directory.
  Inputs:
    1) string: the path of the directory
  Returns:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
*/
int l_Dcreate(lua_State *L) {
  const char *const path = luaL_checkstring(L, 1);
  const long result = Dcreate(path);

  /* Return result */
  lua_pushinteger(L, result);
  return 1;
}

/*
  Ddelete. Delete a directory.
  Inputs:
    1) string: the path of the directory
  Returns:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
*/
int l_Ddelete(lua_State *L) {
  const char *const path = luaL_checkstring(L, 1);
  const long result = Ddelete(path);

  /* Return result */
  lua_pushinteger(L, result);
  return 1;
}

/*
  Dsetpath. Set the drive's default path.
  Inputs:
    string: the path of the directory
  Returns:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
*/
int l_Dsetpath(lua_State *L) {
  const char *const path = luaL_checkstring(L, 1);
  const long result = Dsetpath(path);

  /* Return result */
  lua_pushinteger(L, result);
  return 1;
}

/*
  Dgetpath. Get the drive's default path.
  Inputs:
    integer: the drive to check (0=current, A:=1, B:=2, C:=3, ...)
  Outputs:
    1) integer: on success: 0
    1) integer: on failure: -ve gemdos error number
    2) string: on success: path
*/
int l_Dgetpath(lua_State *L) {
  /* drive 0 is current drive, A:=1, B:=2, C:=3, ... */
  /* The numbering is different to Dgetdrv. */
  const lua_Integer drive = luaL_checkinteger(L, 1);
  const size_t max_path_size = 1024; /* Should be enough? */
  char *path;
  long result;

  /* Check argument. 0 is current drive, A is 1, ... */
  luaL_argcheck(L, drive >= 0 && drive <= 16, 1,
    TOSBINDL_ErrMess[TOSBINDL_EM_InvalidValue]);

  /* Userdata for temporary space */
  path = lua_newuserdatauv(L, max_path_size, 0);
  path[0] = '\0';

  result = Dgetpath(path, drive);

  /* Push results */
  lua_pushinteger(L, result);
  if (result)
    lua_pushnil(L);
  else
    lua_pushstring(L, path);

  /* Remove temporary user data */
  lua_remove(L, 2);

  return 2;
}
