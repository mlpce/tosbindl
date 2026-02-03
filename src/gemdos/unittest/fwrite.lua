-- Unittest for gemdos.Fwrite
gemdos.Cconws("Test gemdos.Fwrite\r\n")

local small_block_size = 512    -- see gemdos_f.c SMALL_BLOCK_SIZE
local large_block_size = 16384  -- see gemdos_f.c LARGE_BLOCK_SIZE

local Imode = gemdos.const.Imode
local s8, u8, s16, u16, s32 =
  Imode.s8, Imode.u8, Imode.s16, Imode.u16, Imode.s32

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
ec = gemdos.Fwritet(fud, u8, table.pack(string.byte("01234567", 1, -1)))
assert(ec == 8)
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Check contents
local tbl
ec, tbl = fud:readt(u8, 8)
assert(ec == 8 and tbl.n == 8 and string.char(table.unpack(tbl)) == "01234567")
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Create the same file so truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- positive values are positions from the start of the table
-- negative values are positions from the end of the table
tbl = table.pack(string.byte("retro computing is cool", 1, -1))
assert(fud:writet(u8, tbl, -4, -1) == 4)  -- 'cool'
assert(fud:writet(u8, tbl, -5, -5) == 1)  -- ' '
assert(fud:writet(u8, tbl, 7, -9) == 9)   -- 'computing'
assert(fud:writet(u8, tbl, 16, 19) == 4) -- ' is '
assert(fud:writet(u8, tbl, 1, 5) == 5)   -- 'retro'
fud:writet(u8, table.pack(string.byte(' Atari ', 1, -1)))
fud:writet(u8, { string.byte("S") }, -1, -1)
fud:writet(u8, { string.byte("T") }, 1, 1)
fud:close()

-- Writing value not in range 0 to 255 must fail
local ok = pcall(function() fud:writet(u8, {-1}) end)
assert(not ok)
ok = pcall(function() fud:writet(u8, {256}) end)
assert(not ok)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0, fud)

-- Read 100 bytes - only 32 are obtained
ec, new = fud:readt(u8, 100)
assert(ec == 32 and new.n == 32 and
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

fud:writet(u8, tbl)
fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(u8, small_block_size + 1)
assert(ec == small_block_size + 1 and tbl.n == ec)
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
str = mud:reads(0, 16)
assert(#str == 16)
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

local u8 = gemdos.const.Imode.u8
for i = 0, 63 do
  mud:poke(u8, i, i)
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
ec = gemdos.Fwritei(fud, u8, string.byte("0"))
-- One byte written
assert(ec == 1)

-- Write a value using self
ec = fud:writei(u8, string.byte("1"))
-- One byte written
assert(ec == 1)

-- Write multple values
ec = fud:writei(u8, string.byte("2"), string.byte("3"), string.byte("4"))
-- Three bytes written
assert(ec == 3)

-- Writing an integer value out of range of a byte must fail
ok = pcall(function() fud:writei(u8, -1) end)
assert(not ok)
ok = pcall(function() fud:writei(u8, 256) end)
assert(not ok)

-- Close the file
fud:close()

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Read a value
local val
ec, val = gemdos.Freadi(fud, u8)
-- One byte read
assert(ec == 1)
assert(val == string.byte("0"))

-- Read a value using self
ec, val = fud:readi(u8)
-- One byte read
assert(ec == 1)
assert(val == string.byte("1"))

-- Read multiple values
local a, b, c, d
ec, a, b, c, d = fud:readi(u8, 4) -- Ask for 4, only 3 are available
assert(ec == 3)
assert(a == string.byte("2"))
assert(b == string.byte("3"))
assert(c == string.byte("4"))
assert(d == nil)

-- No more data produces zero values
ec, val = fud:readi(u8)
assert(ec == 0)
assert(val == nil)

-- Close the file
fud:close()

---------------------------------------------------------------------
-- Test writing a value into a file with imodes ---------------------
---------------------------------------------------------------------

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- signed 8 bit max value
assert(fud:writei(s8, 127) == 1)
ok = pcall(function() fud:writei(s8, 128) end)
assert(not ok)
-- signed 8 bit min value
assert(fud:writei(s8, -128) == 1)
ok = pcall(function() fud:writei(s8, -129) end)
assert(not ok)
-- unsigned 8 bit max value
assert(fud:writei(u8, 255) == 1)
ok = pcall(function() fud:writei(u8, 256) end)
assert(not ok)
-- unsigned 8 bit min value
assert(fud:writei(u8, 0) == 1)
ok = pcall(function() fud:writei(u8, -1) end)
assert(not ok)
-- signed 16 bit max value
assert(fud:writei(s16, 32767) == 2)
ok = pcall(function() fud:writei(s16, 32768) end)
assert(not ok)
-- signed 16 bit min value
assert(fud:writei(s16, -32768) == 2)
ok = pcall(function() fud:writei(s16, -32769) end)
assert(not ok)
-- unsigned 16 bit max value
assert(fud:writei(u16, 65535) == 2)
ok = pcall(function() fud:writei(u16, 65536) end)
assert(not ok)
-- unsigned 16 bit min value
assert(fud:writei(u16, 0) == 2)
ok = pcall(function() fud:writei(u16, -1) end)
assert(not ok)
-- signed 32 bit max value
assert(fud:writei(s32, 2147483647) == 4)
-- signed 32 bit min value
assert(fud:writei(s32, -2147483648) == 4)

-- Close the file
fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
-- signed 8 bit max value
ec, val = fud:readi(s8)
assert(ec == 1 and val == 127)
-- signed 8 bit min value
ec, val = fud:readi(s8)
assert(ec == 1 and val == -128)
-- unsigned 8 bit max value
ec, val = fud:readi(u8)
assert(ec == 1 and val == 255)
-- unsigned 8 bit min value
ec, val = fud:readi(u8)
assert(ec == 1 and val == 0)
-- signed 16 bit max value
ec, val = fud:readi(s16)
assert(ec == 2 and val == 32767)
-- signed 16 bit min value
ec, val = fud:readi(s16)
assert(ec == 2 and val == -32768)
-- unsigned 16 bit max value
ec, val = fud:readi(u16)
assert(ec == 2 and val == 65535)
-- unsigned 16 bit min value
ec, val = fud:readi(u16)
assert(ec == 2 and val == 0)
-- signed 32 bit max value
ec, val = fud:readi(s32)
assert(ec == 4 and val == 2147483647)
-- signed 32 bit min value
ec, val = fud:readi(s32)
assert(ec == 4 and val == -2147483648)

-- Close the file
fud:close()

-- Multiple values
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

assert(fud:writei(s8, -1, -2, -3, -4) == 4)
assert(fud:writei(u8, 1, 2, 3, 4) == 4)
assert(fud:writei(s16, -1, -2, -3, -4) == 8)
assert(fud:writei(u16, 1, 2, 3, 4) == 8)
assert(fud:writei(s32, -1, 2, -3, 4) == 16)
assert(fud:writei(s16, 0) == 2) -- 2 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, a, b, c, d = fud:readi(s8, 4)
assert(ec == 4 and a == -1 and b == -2 and c == -3 and d == -4)
ec, a, b, c, d = fud:readi(u8, 4)
assert(ec == 4 and a == 1 and b == 2 and c == 3 and d == 4)
ec, a, b, c, d = fud:readi(s16, 4)
assert(ec == 8 and a == -1 and b == -2 and c == -3 and d == -4)
ec, a, b, c, d = fud:readi(u16, 4)
assert(ec == 8 and a == 1 and b == 2 and c == 3 and d == 4)
ec, a, b, c, d = fud:readi(s32, 4)
assert(ec == 16 and a == -1 and b == 2 and c == -3 and d == 4)
ec, a = fud:readi(s32, 4) -- 2 byte read then EOF
assert(ec == 2 and a == nil) -- 2 bytes read, not enough for s32 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:writei(s32, -1) == 4)
assert(fud:writei(s8, 0) == 1) -- 1 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, a = fud:readi(s32)
assert(ec == 4 and a == -1)
ec, a = fud:readi(s32) -- 1 byte read then EOF
assert(ec == 1 and a == nil) -- 1 byte read, not enough for s32 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:writei(s32, -1) == 4)
assert(fud:writei(s8, 0, 1, 2) == 3) -- 3 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, a = fud:readi(s32)
assert(ec == 4 and a == -1)
ec, a = fud:readi(s32) -- 3 byte read then EOF
assert(ec == 3 and a == nil) -- 3 byte read, not enough for s32 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:writei(s32, -1) == 4)
assert(fud:writei(s8, 0) == 1) -- 1 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, a = fud:readi(s32)
assert(ec == 4 and a == -1)
ec, a = fud:readi(s16) -- 1 byte read then EOF
assert(ec == 1 and a == nil) -- 1 byte read, not enough for s16 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:writei(s32, -1) == 4)
assert(fud:writei(u8, 0) == 1) -- 1 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, a = fud:readi(s32)
assert(ec == 4 and a == -1)
ec, a = fud:readi(u16) -- 1 byte read then EOF
assert(ec == 1 and a == nil) -- 1 byte read, not enough for u16 value

fud:close()

---------------------------------------------------------------------
-- Test writing a table into a file with imodes ---------------------
---------------------------------------------------------------------

tbl = {}

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- signed 8 bit max value
tbl[1] = 127
assert(fud:writet(s8, tbl) == 1)
tbl[1] = 128
ok = pcall(function() fud:writei(s8, tbl) end)
assert(not ok)
-- signed 8 bit min value
tbl[1] = -128
assert(fud:writet(s8, tbl) == 1)
tbl[1] = -129
ok = pcall(function() fud:writei(s8, tbl) end)
assert(not ok)
-- unsigned 8 bit max value
tbl[1] = 255
assert(fud:writet(u8, tbl) == 1)
tbl[1] = 256
ok = pcall(function() fud:writei(u8, tbl) end)
assert(not ok)
-- unsigned 8 bit min value
tbl[1] = 0
assert(fud:writet(u8, tbl) == 1)
tbl[1] = -1
ok = pcall(function() fud:writet(u8, tbl) end)
assert(not ok)
-- signed 16 bit max value
tbl[1] = 32767
assert(fud:writet(s16, tbl) == 2)
tbl[1] = 32768
ok = pcall(function() fud:writet(s16, tbl) end)
assert(not ok)
-- signed 16 bit min value
tbl[1] = -32768
assert(fud:writet(s16, tbl) == 2)
tbl[1] = -32769
ok = pcall(function() fud:writet(s16, tbl) end)
assert(not ok)
-- unsigned 16 bit max value
tbl[1] = 65535
assert(fud:writet(u16, tbl) == 2)
tbl[1] = 65536
ok = pcall(function() fud:writet(u16, tbl) end)
assert(not ok)
-- unsigned 16 bit min value
tbl[1] = 0
assert(fud:writet(u16, tbl) == 2)
tbl[1] = -1
ok = pcall(function() fud:writet(u16, tbl) end)
assert(not ok)
-- signed 32 bit max value
tbl[1] = 2147483647
assert(fud:writet(s32, tbl) == 4)
-- signed 32 bit min value
tbl[1] = -2147483648
assert(fud:writet(s32, tbl) == 4)

-- Close the file
fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
-- signed 8 bit max value
ec, tbl = fud:readt(s8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == 127)
-- signed 8 bit min value
ec, tbl = fud:readt(s8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == -128)
-- unsigned 8 bit max value
ec, tbl = fud:readt(u8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == 255)
-- unsigned 8 bit min value
ec, tbl = fud:readt(u8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == 0)
-- signed 16 bit max value
ec, tbl = fud:readt(s16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == 32767)
-- signed 16 bit min value
ec, tbl = fud:readt(s16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == -32768)
-- unsigned 16 bit max value
ec, tbl = fud:readt(u16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == 65535)
-- unsigned 16 bit min value
ec, tbl = fud:readt(u16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == 0)
-- signed 32 bit max value
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == 2147483647)
-- signed 32 bit min value
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == -2147483648)

-- Close the file
fud:close()

-- Multiple values
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

tbl = { -1, -2, -3, -4 }
assert(fud:writet(s8, tbl) == 4)
tbl = { 1, 2, 3, 4}
assert(fud:writet(u8, tbl) == 4)
tbl = { -1, -2, -3, -4}
assert(fud:writet(s16, tbl) == 8)
tbl = { 1, 2, 3, 4 }
assert(fud:writet(u16, tbl) == 8)
tbl = { -1, 2, -3, 4 }
assert(fud:writet(s32, tbl) == 16)
tbl = { 0 }
assert(fud:writet(s16, tbl) == 2) -- 2 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(s8, 4)
assert(ec == 4 and tbl.n == 4 and tbl[1] == -1 and tbl[2] == -2 and
  tbl[3] == -3 and tbl[4] == -4)
ec, tbl = fud:readt(u8, 4)
assert(ec == 4 and tbl.n == 4 and tbl[1] == 1 and tbl[2] == 2 and
  tbl[3] == 3 and tbl[4] == 4)
ec, tbl = fud:readt(s16, 4)
assert(ec == 8 and tbl.n == 4 and tbl[1] == -1 and tbl[2] == -2 and
  tbl[3] == -3 and tbl[4] == -4)
ec, tbl = fud:readt(u16, 4)
assert(ec == 8 and tbl.n == 4 and tbl[1] == 1 and tbl[2] == 2 and
  tbl[3] == 3 and tbl[4] == 4)
ec, tbl = fud:readt(s32, 4)
assert(ec == 16 and tbl.n == 4 and tbl[1] == -1 and tbl[2] == 2 and
  tbl[3] == -3 and tbl[4] == 4)
ec, tbl = fud:readt(s32, 4) -- 2 byte read then EOF
assert(ec == 2 and tbl.n == 0 and #tbl == 0 ) -- 2 bytes read, not enough for s32 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
tbl = {}
tbl[1] = -1
assert(fud:writet(s32, tbl) == 4)
tbl[1] = 0
assert(fud:writet(s8, tbl) == 1) -- 1 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == -1)
ec, tbl = fud:readt(s32, 1) -- 1 byte read then EOF
assert(ec == 1 and tbl.n == 0 and #tbl == 0) -- 1 byte read, not enough for s32 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
tbl[1] = -1
assert(fud:writet(s32, tbl) == 4)
tbl[1] = 0
tbl[2] = 1
tbl[3] = 2
assert(fud:writet(s8, tbl) == 3) -- 3 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == -1)
ec, tbl = fud:readt(s32, 1) -- 3 byte read then EOF
assert(ec == 3 and tbl.n == 0 and #tbl == 0) -- 3 byte read, not enough for s32 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
tbl = { -1 }
assert(fud:writet(s32, tbl) == 4)
tbl[1] = 0
assert(fud:writet(s8, tbl) == 1) -- 1 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == -1)
ec, tbl = fud:readt(s16, 1) -- 1 byte read then EOF
assert(ec == 1 and tbl.n == 0 and #tbl == 0) -- 1 byte read, not enough for s16 value

fud:close()

ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
tbl[1] = -1
assert(fud:writet(s32, tbl) == 4)
tbl[1] = 0
assert(fud:writet(u8, tbl) == 1) -- 1 byte tail

fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == -1)
ec, tbl = fud:readt(u16, 1) -- 1 byte read then EOF
assert(ec == 1 and tbl.n == 0 and #tbl == 0) -- 1 byte read, not enough for u16 value

fud:close()

-- Some mid table positions with imode
tbl = { -128, 127, 0, 255, -32768, 32767, 0, 65535, -2147483648, 2147483647, 42 }
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:writet(s8, tbl, 1, 1) == 1)
assert(fud:writet(s8, tbl, 2, 2) == 1)
assert(fud:writet(u8, tbl, 3, 3) == 1)
assert(fud:writet(u8, tbl, 4, 4) == 1)
assert(fud:writet(s16, tbl, 5, 5) == 2)
assert(fud:writet(s16, tbl, 6, 6) == 2)
assert(fud:writet(u16, tbl, 7, 7) == 2)
assert(fud:writet(u16, tbl, 8, 8) == 2)
assert(fud:writet(s32, tbl, 9, 9) == 4)
assert(fud:writet(s32, tbl, 10, 10) == 4)
assert(fud:writet(s8, tbl, 11, 11) == 1)
fud:close()

ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)
assert(ec == 0)
ec, tbl = fud:readt(s8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == -128)
ec, tbl = fud:readt(s8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == 127)
ec, tbl = fud:readt(u8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == 0)
ec, tbl = fud:readt(u8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == 255)
ec, tbl = fud:readt(s16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == -32768)
ec, tbl = fud:readt(s16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == 32767)
ec, tbl = fud:readt(u16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == 0)
ec, tbl = fud:readt(u16, 1)
assert(ec == 2 and tbl.n == 1 and tbl[1] == 65535)
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == -2147483648)
ec, tbl = fud:readt(s32, 1)
assert(ec == 4 and tbl.n == 1 and tbl[1] == 2147483647)
ec, tbl = fud:readt(s8, 1)
assert(ec == 1 and tbl.n == 1 and tbl[1] == 42)

fud:close()

---------------------------------------------------------------------
-- readt with output table passed as parameter
---------------------------------------------------------------------

-- Size rotator for imodes
local imode_sz_r <const> = {
  [s8] = 0,
  [u8] = 0,
  [s16] = 1,
  [u16] = 1,
  [s32] = 2
}

local output_tbl = {}
for _,test in ipairs(
    { {s8, { -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16 } },
      {u8, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 } },
      {s16, { -101, -102, -103, -104, -105, -106, -107, -108 } },
      {u16, { 101, 102, 103, 104, 105, 106, 107, 108 } },
      {s32, { 201, 202, 203, 204 } } } ) do
  local imode = test[1]
  local write_table = test[2]

  ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
  assert(ec == 0)

  ec = fud:writet(imode, write_table)
  assert(ec == #write_table << imode_sz_r[imode])

  local abs_pos = gemdos.Fseek(fud, 0, gemdos.const.Fseek.seek_set)
  assert(abs_pos == 0)

  local read_tbl
  ec, read_tbl = fud:readt(imode, #write_table, output_tbl)
  fud:close()

  assert(ec == #write_table << imode_sz_r[imode])
  assert(read_tbl == output_tbl)
  assert(read_tbl.n == #write_table)

  assert(#read_tbl == 16)
  for k,v in ipairs(write_table) do
    assert(v == read_tbl[k])
  end
end

gemdos.Cconws("Test gemdos.Fwrite completed\r\n")
