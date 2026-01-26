-- Unittest for gemdos.Fread
gemdos.Cconws("Test gemdos.Fread\r\n")

local Imode = gemdos.const.Imode
local s8, u8, s16, u16, s32 =
  Imode.s8, Imode.u8, Imode.s16, Imode.u16, Imode.s32

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Write string
local num = gemdos.Fwrites(fud, "0123456789A")
assert(num == 11)

-- Close the file
ec = gemdos.Fclose(fud)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)

-- Read string
local str
ec, str = gemdos.Freads(fud, 2)
assert(ec == 2 and str == "01")

-- Read table
local tbl
ec, tbl = gemdos.Freadt(fud, u8, 2)
assert(ec == 2 and string.char(table.unpack(tbl)) == "23")

-- Read memory
local mud
ec, mud = gemdos.Malloc(2)
assert(ec == 2)
ec = gemdos.Freadm(fud, mud, 0, 2)
assert(ec == 2)
assert(mud:peek(u8, 0) == string.byte("4") and mud:peek(u8, 1) == string.byte("5"))

-- Read value
local val
ec, val = gemdos.Freadi(fud, u8, 1)
assert(ec == 1)
assert(val == string.byte("6"))

-- Read string using self
ec, str = fud:reads(1)
assert(ec == 1)
assert(str == "7")

-- Read table using self
ec, tbl = fud:readt(u8, 1)
assert(ec == 1)
assert(tbl[1] == string.byte("8"))

-- Read memory using self
ec = fud:readm(mud, 0, 1)
assert(ec == 1)
assert(mud:peek(u8, 0) == string.byte("9"))

-- Reading zero values using self
ec, val = fud:readi(s8, 0)
assert(ec == 0, val == nil)
ec, val = fud:readi(u8, 0)
assert(ec == 0, val == nil)
ec, val = fud:readi(s16, 0)
assert(ec == 0, val == nil)
ec, val = fud:readi(u16, 0)
assert(ec == 0, val == nil)
ec, val = fud:readi(s32, 0)
assert(ec == 0, val == nil)

-- Read value using self
ec, val = fud:readi(u8, 1)
assert(ec == 1 and val == string.byte("A"))

-- End of file now reached. Any further reads produce zero bytes
assert(fud:reads(1) == 0)
assert(fud:readt(u8, 1) == 0)
assert(fud:readm(mud, 0, 1) == 0)
assert(fud:readi(u8, 1) == 0)

-- Seek back to beginning
assert(gemdos.Fseek(fud, 0, gemdos.const.Fseek.seek_set) == 0)
-- Max number of readi values is 16 so 17 must fail
-- See TOSBINDL_GEMDOS_MAX_MULTIVAL
local ok = pcall(function() fud:readi(u8, 17) end)
assert(not ok)
local v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12
-- Attempt to read 16 values, only 11 will be produced
ec, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12 = fud:readi(u8, 16)
assert(ec == 11)
assert(v1 == string.byte("0"))
assert(v2 == string.byte("1"))
assert(v3 == string.byte("2"))
assert(v4 == string.byte("3"))
assert(v5 == string.byte("4"))
assert(v6 == string.byte("5"))
assert(v7 == string.byte("6"))
assert(v8 == string.byte("7"))
assert(v9 == string.byte("8"))
assert(v10 == string.byte("9"))
assert(v11 == string.byte("A"))
assert(v12 == nil)

-- Close the file
ec = gemdos.Fclose(fud)
assert(ec)

gemdos.Cconws("Test gemdos.Fread completed\r\n")
