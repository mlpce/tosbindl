-- Unittest for gemdos.Fwrite
gemdos.Cconws("Test gemdos.Fwrite\r\n")

local small_block_size = 512    -- see gemdos_f.c SMALL_BLOCK_SIZE
local large_block_size = 16384  -- see gemdos_f.c LARGE_BLOCK_SIZE

---------------------------------------------------------------------
-- Test writing strings into a file ---------------------------------
---------------------------------------------------------------------

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Write string
ec = gemdos.Fwrites(fud, "01234567")
assert(ec == 8)
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Check contents
local new
ec, new = fud:reads(8)
assert(ec == 8 and new == "01234567")
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
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
assert(ec == 0)

-- Read 100 bytes - only 32 are obtained
ec, new = fud:reads(100)
assert(ec == 32 and new == "cool computing is retro Atari ST")
fud:close()

---------------------------------------------------------------------
-- Test writing and reading a longer string -------------------------
---------------------------------------------------------------------

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
-- Write a long string
str = string.rep("01234567", 1 + large_block_size / 8)
local count = fud:writes(str)
assert(count == large_block_size + 8)
fud:close()

-- Read it back
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
local new_count
new_count, new = fud:reads(count)
assert(new_count == count)
-- Check match
assert(new == str)
fud:close()
new = nil
str = nil

---------------------------------------------------------------------
-- Test writing tables into a file ----------------------------------
---------------------------------------------------------------------

-- Create a new file named TESTFILE
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Write table
ec = gemdos.Fwritet(fud, table.pack(string.byte("01234567", 1, -1)))
assert(ec == 8)
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Check contents
local tbl
ec, tbl = fud:readt(8)
assert(ec == 8 and string.char(table.unpack(tbl)) == "01234567")
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
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
local ok = pcall(function() fud:writet({-1}) end)
assert(not ok)
ok = pcall(function() fud:writet({256}) end)
assert(not ok)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Read 100 bytes - only 32 are obtained
ec, new = fud:readt(100)
assert(ec == 32 and
  string.char(table.unpack(new)) == "cool computing is retro Atari ST")
fud:close()

---------------------------------------------------------------------
-- Test writing and reading a longer table --------------------------
---------------------------------------------------------------------

-- Write and read small_block_size + 1 bytes. This is just over
-- SMALL_BLOCK_SIZE in gemdos_f.c.

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

tbl = {}
for i = 0,small_block_size - 1 do
  tbl[#tbl + 1] = i % 8
end
tbl[#tbl + 1] = 66

fud:writet(tbl)
fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(small_block_size + 1)
assert(ec == small_block_size + 1)
fud:close()
for i = 0,small_block_size - 1 do
  assert(tbl[i + 1] == i % 8)
end
assert(tbl[small_block_size + 1] == 66)
tbl = nil

---------------------------------------------------------------------
-- Test writing memory into a file ----------------------------------
---------------------------------------------------------------------

local mud
ec, mud = gemdos.Malloc(16)
assert(ec == 16)
assert(mud:address() ~= 0)
assert(mud:size() == 16)

-- Write a string into the memory
ec = mud:writes(0, "0123456789ABCDEF")
assert(ec == 16)

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- Write the last 8 bytes then the first 8 bytes to the file
ec = fud:writem(mud, 8, 8)
assert(ec == 8)
ec = fud:writem(mud, 0, 8)
assert(ec == 8)

-- Offset negative must fail
ok = pcall(function() fud:writem(mud, -1, 1) end)
assert(not ok)

-- Offset or run beyond end must fail
ok = pcall(function() fud:writem(mud, 16, 1) end)
assert(not ok)
ok = pcall(function() fud:writem(mud, 15, 2) end)
assert(not ok)

-- close the file
fud:close()

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- read from file into memory
mud:set(0, 0, mud:size())
ec = fud:readm(mud, 0, 16)
assert(ec == 16)

-- read from memory into string
ec, str = mud:reads(0, 16)
assert(ec == 16)
assert(str == "89ABCDEF01234567")

-- Close the file
ec = gemdos.Fclose(fud)
assert(ec == 0)

---------------------------------------------------------------------
-- Test writing and reading a longer memory -------------------------
---------------------------------------------------------------------

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
local large_mem_size = 64 + large_block_size * 2
ec, mud = gemdos.Malloc(large_mem_size)
assert(ec == large_mem_size)

for i = 0, 63 do
  mud:poke(i,i)
end

local src_offset = 0
for i = 1, 2 * large_block_size / 64 do
  local dst_offset = src_offset + 64
  mud:copym(dst_offset, mud, src_offset, 64)
  src_offset = dst_offset
end

count = fud:writem(mud, 0, mud:size())
assert(count == large_mem_size)
fud:close()

-- Read it back
local mud2
ec, mud2 = gemdos.Malloc(large_mem_size)
assert(ec == large_mem_size)

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)
count = fud:readm(mud2, 0, mud2:size())
assert(count == large_mem_size)
fud:close()

-- Compare both memories
assert(mud:comparem(0, mud2, 0, mud:size()) == 0)

mud:free()
mud2:free()

---------------------------------------------------------------------
-- Test writing a value into a file ---------------------------------
---------------------------------------------------------------------
-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- Write a value
ec = gemdos.Fwritei(fud, string.byte("0"))
-- One byte written
assert(ec == 1)

-- Write a value using self
ec = fud:writei(string.byte("1"))
-- One byte written
assert(ec == 1)

-- Writing an integer value out of range of a byte must fail
ok = pcall(function() fud:writei(-1) end)
assert(not ok)
ok = pcall(function() fud:writei(256) end)
assert(not ok)

-- Close the file
fud:close()

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Read a value
local val
ec, val = gemdos.Freadi(fud)
-- One byte read
assert(ec == 1)
assert(val == string.byte("0"))

-- Read a value using self
ec, val = fud:readi()
-- One byte read
assert(ec == 1)
assert(val == string.byte("1"))

-- Close the file
fud:close()

gemdos.Cconws("Test gemdos.Fwrite completed\r\n")
