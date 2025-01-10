-- Unittest for gemdos.Fwrite
gemdos.Cconws("Test gemdos.Fwrite\r\n")

---------------------------------------------------------------------
-- Test writing strings into a file ---------------------------------
---------------------------------------------------------------------

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)

-- Write string
local msg
ec, msg = gemdos.Fwrites(fud, "01234567")
assert(ec == 8, msg)
ec, msg = gemdos.Fclose(fud)
assert(ec == 0, msg)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Check contents
local new
ec, new = fud:reads(8)
assert(ec == 8 and new == "01234567", new)
ec, msg = gemdos.Fclose(fud)
assert(ec == 0, msg)

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)

-- positive values are positions from the start of the string
-- negative values are positions from the end of the string
local str = "retro computing is cool"
assert(fud:writes(str, -4, -1) == 4)  -- 'cool'
assert(fud:writes(str, -5, -5) == 1)  -- ' '
assert(fud:writes(str, 7, -9) == 9)   -- 'computing'
assert(fud:writes(str, 16, 19) == 4) -- ' is '
assert(fud:writes(str, 1, 5) == 5)   -- 'retro'
fud:writes(' Atari ')
fud:writes('S', -1, -1)
fud:writes('T', 1, 1)
fud:close()

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Read 100 bytes - only 32 are obtained
ec, new = fud:reads(100)
assert(ec == 32 and new == "cool computing is retro Atari ST", new)
fud:close()

---------------------------------------------------------------------
-- Test writing tables into a file ----------------------------------
---------------------------------------------------------------------

-- Create a new file named TESTFILE
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)

-- Write table
ec, msg =
  gemdos.Fwritet(fud, table.pack(string.byte("01234567", 1, -1)))
assert(ec == 8, msg)
ec, msg = gemdos.Fclose(fud)
assert(ec == 0, msg)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Check contents
local tbl
ec, tbl = fud:readt(8)
assert(ec == 8 and string.char(table.unpack(tbl)) == "01234567", tbl)
ec, msg = gemdos.Fclose(fud)
assert(ec == 0, msg)

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)

-- positive values are positions from the start of the table
-- negative values are positions from the end of the table
tbl = table.pack(string.byte("retro computing is cool", 1, -1))
assert(fud:writet(tbl, -4, -1) == 4)  -- 'cool'
assert(fud:writet(tbl, -5, -5) == 1)  -- ' '
assert(fud:writet(tbl, 7, -9) == 9)   -- 'computing'
assert(fud:writet(tbl, 16, 19) == 4) -- ' is '
assert(fud:writet(tbl, 1, 5) == 5)   -- 'retro'
fud:writet(table.pack(string.byte(' Atari ', 1, -1)))
fud:writet({ string.byte("S") }, -1, -1)
fud:writet({ string.byte("T") }, 1, 1)
fud:close()

-- Writing value not in range 0 to 255 must fail
local ok
ok, msg = pcall(function() fud:writet({-1}) end)
assert(not ok)
ok, msg = pcall(function() fud:writet({256}) end)
assert(not ok)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Read 100 bytes - only 32 are obtained
ec, new = fud:readt(100)
assert(ec == 32 and
  string.char(table.unpack(new)) == "cool computing is retro Atari ST", new)
fud:close()

---------------------------------------------------------------------
-- Test writing memory into a file ----------------------------------
---------------------------------------------------------------------

local mud
ec, mud = gemdos.Malloc(16)
assert(ec == 16, mud)
assert(mud:address() ~= 0)
assert(mud:size() == 16)

-- Write a string into the memory
ec, msg = mud:writes(0, "0123456789ABCDEF")
assert(ec == 16, msg)

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)

-- Write the last 8 bytes then the first 8 bytes to the file
ec, msg = fud:writem(mud, 8, 8)
assert(ec == 8, msg)
ec, msg = fud:writem(mud, 0, 8)
assert(ec == 8, msg)

-- Offset negative must fail
ok, msg = pcall(function() fud:writem(mud, -1, 1) end)
assert(not ok)

-- Offset or run beyond end must fail
ok, msg = pcall(function() fud:writem(mud, 16, 1) end)
assert(not ok)
ok, msg = pcall(function() fud:writem(mud, 15, 2) end)
assert(not ok)

-- close the file
fud:close()

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- read from file into memory
mud:set(0, 0, mud:size())
ec = fud:readm(mud, 0, 16)
assert(ec == 16)

-- read from memory into string
ec, str = mud:reads(0, 16)
assert(ec == 16, str)
assert(str == "89ABCDEF01234567")

---------------------------------------------------------------------
-- Test writing a value into a file ---------------------------------
---------------------------------------------------------------------
-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)

-- Write a value
ec, msg = gemdos.Fwritei(fud, string.byte("0"))
-- One byte written
assert(ec == 1, msg)

-- Write a value using self
ec, msg = fud:writei(string.byte("1"))
-- One byte written
assert(ec == 1, msg)

-- Writing an integer value out of range of a byte must fail
ok, msg = pcall(function() fud:writei(-1) end)
assert(not ok)
ok, msg = pcall(function() fud:writei(256) end)
assert(not ok)

-- Close the file
fud:close()

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Read a value
local val
ec, val = gemdos.Freadi(fud)
-- One byte read
assert(ec == 1, val)
assert(val == string.byte("0"))

-- Read a value using self
ec, val = fud:readi()
-- One byte read
assert(ec == 1, val)
assert(val == string.byte("1"))

gemdos.Cconws("Test gemdos.Fwrite completed\r\n")
