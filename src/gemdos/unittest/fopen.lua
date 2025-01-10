-- Unittest for gemdos.Fopen
gemdos.Cconws("Test gemdos.Fopen\r\n")

-- Create the test file
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)

-- Close the test file
local msg
ec, msg = gemdos.Fclose(fud)
assert(ec, msg)

---------------------------------------------------------------------
-- Test writing to file opened readonly -----------------------------
---------------------------------------------------------------------

-- Open the test file, readonly
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Write to readonly file must fail
local ok
ok, msg = pcall(function() gemdos.Fwrites(fud, "01234567") end)
assert(not ok)

-- Close it
ec, msg = gemdos.Fclose(fud)

---------------------------------------------------------------------
-- Test reading from file opened writeonly --------------------------
---------------------------------------------------------------------

-- Open the test file, writeonly
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.writeonly)
assert(ec == 0, fud)

-- Read from writeonly file must fail
ok, msg = pcall(function() gemdos.Freads(fud, 8) end)
assert(not ok)

-- Close it
ec, msg = gemdos.Fclose(fud)

---------------------------------------------------------------------
-- Test writing to file opened writeonly ----------------------------
---------------------------------------------------------------------

-- Open the test file, writeonly
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.writeonly)
assert(ec == 0, fud)

-- Write to writeonly file
local num
num, msg = gemdos.Fwrites(fud, "01234567")
assert(num == 8, msg)

-- Close it
ec, msg = gemdos.Fclose(fud)

---------------------------------------------------------------------
-- Test reading from file opened readonly ---------------------------
---------------------------------------------------------------------

-- Open the test file, readonly
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Read from readonly file
local str
num, str = gemdos.Freads(fud, 100)
assert(num == 8, str)
assert(str == "01234567")

-- Close it
ec, msg = gemdos.Fclose(fud)

---------------------------------------------------------------------
-- Test writing and reading from a file opened readwrite ------------
---------------------------------------------------------------------

-- Open the test file, readwrite
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readwrite)
assert(ec == 0, fud)

-- Write to file
ec, msg = gemdos.Fwrites(fud, "ABCDEFGH")
assert(ec == 8, msg)

local off
off, msg = gemdos.Fseek(fud, 2, gemdos.const.Fseek.seek_set)
assert(off == 2, msg)

-- Read from file
num, str = gemdos.Freads(fud, 3)
assert(num == 3)
assert(str == "CDE")

-- Close it
ec, msg = gemdos.Fclose(fud)

gemdos.Cconws("Test gemdos.Fopen completed\r\n")
