-- Unittest for gemdos.Malloc
gemdos.Cconws("Test gemdos.Malloc\r\n")

---------------------------------------------------------------------
-- Test obtaining largest block of free memory ----------------------
---------------------------------------------------------------------
local largest_free_block = gemdos.Malloc(-1)
assert(largest_free_block >= 0)

---------------------------------------------------------------------
-- Test allocating too much memory ----------------------------------
---------------------------------------------------------------------
local ec, mud = gemdos.Malloc(1024*1024*1024)
assert(ec == gemdos.const.Error.ENSMEM and mud == nil)

---------------------------------------------------------------------
-- Test parameter errors --------------------------------------------
---------------------------------------------------------------------
-- Test bad parameter
local ok = pcall(function() gemdos.Malloc(-10) end)
assert(not ok)

-- Number of bytes must be an integer
ok = pcall(function() gemdos.Malloc(1.2) end)
assert(not ok)

---------------------------------------------------------------------
-- Allocate 32 bytes ------------------------------------------------
---------------------------------------------------------------------
ec, mud = gemdos.Malloc(32)
assert(ec > 0)
assert(mud:address() ~= 0)
assert(mud:size() == 32)

---------------------------------------------------------------------
-- Poke and peek ----------------------------------------------------
---------------------------------------------------------------------

-- Test poke and peek. Mud offsets start from zero.
local Imode = gemdos.const.Imode
local s8, u8, s16, u16, s32 =
  Imode.s8, Imode.u8, Imode.s16, Imode.u16, Imode.s32
assert(mud:poke(u8, 0, 40) == 1, "Poke failed")
assert(mud:peek(u8, 0) == 40, "Peek failed")
assert(mud:poke(u8, 0, 42) == 1, "Poke failed")
assert(mud:peek(u8, 0) == 42, "Peek failed")
-- Multivalue poke
assert(mud:poke(u8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
  18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32) == 32,
  "Poke failed")
ok = pcall(function() mud:poke(u8, -1, 0) end) -- Negative offset must fail
assert(not ok)
ok = pcall(function() mud:poke(u8, 31, 1, 2) end) -- Poke beyond end must fail
assert(not ok)
ok = pcall(function() mud:poke(u8, 32, 2) end) -- Poke beyond end must fail
assert(not ok)
-- Multivalue peek
local t1 = table.pack(mud:peek(u8, 0, 16))
assert(#t1 == 16)
table.move(table.pack(mud:peek(u8, 16, 16)), 1, 16, 17, t1)
assert(#t1 == 32)
for k,v in ipairs(t1) do
  assert(k == v)
end

-- Max number of peek values is 16 so 17 must fail
-- See TOSBINDL_GEMDOS_MAX_MULTIVAL
ok = pcall(function() mud:peek(u8, 0, 17) end)
assert(not ok)

-- Set memory from offset 0 to value '69', for the whole size
mud:set(0, 69, mud:size())

-- Each byte must now be 69
for i=0, mud:size() - 1 do
  assert(mud:peek(u8, i) == 69)
end

-- Poke ASCII for 'A' to offset 2
-- Poke ASCII for 'B' to offset 3
mud:poke(u8, 2, 65)
mud:poke(u8, 3, 66)

---------------------------------------------------------------------
-- Test reading the memory into a string ----------------------------
---------------------------------------------------------------------

-- Second parameter is number of bytes to read, if it is missing
-- will read the whole memory.
local num_bytes, str = mud:reads(0)
assert(num_bytes == mud:size() and type(str) == "string")
assert(str == "EEABEEEEEEEEEEEEEEEEEEEEEEEEEEEE")

-- Read four bytes from offset two
num_bytes, str = mud:reads(2, 4)
assert(num_bytes == 4 and str == "ABEE")

-- Read zero bytes
num_bytes, str = mud:reads(2, 0);
assert(num_bytes == 0 and str == "")

-- Read from offset 2 to end
num_bytes, str = mud:reads(2);
assert(num_bytes == 30 and str == "ABEEEEEEEEEEEEEEEEEEEEEEEEEEEE")

---------------------------------------------------------------------
-- Test writing a string into the memory ----------------------------
---------------------------------------------------------------------

-- mud:writes takes four parameters, the first two parameters are the
-- memory offset and the string to write and are required. Parameters
-- three and four are optional and if present specify the start
-- character position and the end character position (one based
-- positions).
num_bytes = mud:writes(16, "Oranges")
assert(num_bytes == 7)
num_bytes, str = mud:reads(0)
assert(str == "EEABEEEEEEEEEEEEOrangesEEEEEEEEE")

---------------------------------------------------------------------
-- Test writing a string out of bounds of the memory ----------------
---------------------------------------------------------------------

-- Writing before the beginning
local old
num_bytes, old = mud:reads(0)
ok = pcall(function() mud:writes(-1, "No") end)
local new
num_bytes, new = mud:reads(0)
assert(not ok and old == new)

-- Writing beyond the end
num_bytes, old = mud:reads(0)
ok = pcall(function() mud:writes(31, "No") end)
num_bytes, new = mud:reads(0)
assert(not ok and old == new)

---------------------------------------------------------------------
-- Test writing a string into memory with string positions ----------
---------------------------------------------------------------------

-- positive values are positions from the start of the string
-- negative values are positions from the end of the string
str = "retro computing is cool"
assert(mud:writes(0, str, -4, -1) == 4)  -- 'cool'
assert(mud:writes(4, str, -5, -5) == 1)  -- ' '
assert(mud:writes(5, str, 7, -9) == 9)   -- 'computing'
assert(mud:writes(14, str, 16, 19) == 4) -- ' is '
assert(mud:writes(18, str, 1, 5) == 5)   -- 'retro'
assert(mud:writes(23, ' Atari ') == 7)   -- ' Atari '
assert(mud:writes(30, 'S', -1, -1) == 1) -- 'S'
assert(mud:writes(31, 'T', 1, 1) == 1)   -- 'T'
num_bytes, new = mud:reads(0)
assert(new == "cool computing is retro Atari ST")

---------------------------------------------------------------------
-- Test string positions that are out of bounds for the source string
---------------------------------------------------------------------

str = "word"
-- character start before start of the string
ok = pcall(function() mud:writes(0, str, 0, -1) end)
assert(not ok)
-- character end after end of string
ok = pcall(function() mud:writes(0, str, 4, 5) end)
assert(not ok)
-- character start after character end
ok = pcall(function() mud:writes(0, str, 3, 2) end)
assert(not ok)
-- character start before the start of the string
ok = pcall(function() mud:writes(0, str, -5, -1) end)
assert(not ok)

---------------------------------------------------------------------
-- Test reading the memory into a table -----------------------------
---------------------------------------------------------------------

-- Fill memory with 69
mud:set(0, 69, mud:size())

-- Read memory into a table. Second parameter is number of bytes to
-- read, if it is missing will read the whole memory.
local tbl
num_bytes, tbl = mud:readt(u8, 0)
assert(num_bytes == mud:size() and type(tbl) == "table")

-- Check all values are correct
for i=1,#tbl do
  assert(tbl[i] == 69)
end

-- Poke some changes
mud:poke(u8, 2, 65)
mud:poke(u8, 3, 66)

-- Read four bytes from offset two
num_bytes, tbl = mud:readt(u8, 2, 4)
assert(num_bytes == 4)

-- Check the table values. The tables use one based indices.
assert(tbl[1] == 65 and tbl[2] == 66)
assert(string.char(table.unpack(tbl)) == "ABEE")

---------------------------------------------------------------------
-- Test writing a table into the memory -----------------------------
---------------------------------------------------------------------

-- mud:writet takes five parameters, the first three parameters are
-- the Imode, memory offset and the table to write and are required.
-- Memory offsets are still zero based. Parameters four and five are
-- optional and if present specify the start table position and the
-- end table position (one based indices).
num_bytes = mud:writet(u8, 16, {79, 114, 97, 110, 103, 101, 115})
assert(num_bytes == 7)

num_bytes, tbl = mud:readt(u8, 0)
assert(num_bytes == 32)
assert(string.char(table.unpack(tbl)) == "EEABEEEEEEEEEEEEOrangesEEEEEEEEE")

---------------------------------------------------------------------
-- Test writing a table out of bounds of the memory -----------------
---------------------------------------------------------------------

-- Writing before the beginning
num_bytes, old = mud:readt(u8, 0)
ok = pcall(function() mud:writet(u8, -1, {1, 2}) end)
num_bytes, new = mud:readt(u8, 0)
assert(not ok and table.concat(old) == table.concat(new))

-- Writing beyond the end
num_bytes, old = mud:readt(u8, 0)
ok = pcall(function() mud:writet(u8, 31, {1, 2}) end)
num_bytes, new = mud:readt(u8, 0)
assert(not ok and table.concat(old) == table.concat(new))

---------------------------------------------------------------------
-- Test writing a table into memory with table positions ------------
---------------------------------------------------------------------

-- positive values are positions from the start of the table
-- negative values are positions from the end of the table
tbl = table.pack(string.byte("retro computing is cool", 1, -1))
assert(mud:writet(u8, 0, tbl, -4, -1) == 4)  -- 'cool'
assert(mud:writet(u8, 4, tbl, -5, -5) == 1)  -- ' '
assert(mud:writet(u8, 5, tbl, 7, -9) == 9)   -- 'computing'
assert(mud:writet(u8, 14, tbl, 16, 19) == 4) -- ' is '
assert(mud:writet(u8, 18, tbl, 1, 5) == 5)   -- 'retro'
mud:writet(u8, 23, table.pack(string.byte(' Atari ST', 1, -1)))
num_bytes, new = mud:readt(u8, 0)
assert(string.char(table.unpack(new)) == "cool computing is retro Atari ST")

---------------------------------------------------------------------
-- Test table positions that are out of bounds for the source table
---------------------------------------------------------------------

tbl = table.pack(string.byte("word", 1, -1))
ok = pcall(function() mud:writet(u8, 0, tbl, 0, -1) end)
assert(not ok)
ok = pcall(function() mud:writet(u8, 0, tbl, 4, 5) end)
assert(not ok)
ok = pcall(function() mud:writet(u8, 0, tbl, 3, 2) end)
assert(not ok)
ok = pcall(function() mud:writet(u8, 0, tbl, -5, -1) end)
assert(not ok)

---------------------------------------------------------------------
-- Some memory sets -------------------------------------------------
---------------------------------------------------------------------

-- Set whole of memory to 1. When third parameter is missing the
-- memory will be set from the offset to the end.
num_bytes = mud:set(0, 1)
assert(num_bytes == 32)

-- Set upper half of memory to 2
num_bytes = mud:set(16, 2)
assert(num_bytes == 16)

-- Set offset 30 to 3.
num_bytes = mud:set(30, 3, 1)
assert(num_bytes == 1)

-- Set offset 31 to 4.
num_bytes = mud:set(31, 4, 1)
assert(num_bytes == 1)

assert(mud:peek(u8, 0) == 1)
for i=0,15 do
  assert(mud:peek(u8, i) == 1)
end
for i=16,29 do
  assert(mud:peek(u8, i) == 2)
end
assert(mud:peek(u8, 30) == 3)
assert(mud:peek(u8, 31) == 4)

---------------------------------------------------------------------
-- Some memory sets out of bounds -----------------------------------
---------------------------------------------------------------------
ok = pcall(function() mud:set(32, 1) end)
assert(not ok)
ok = pcall(function() mud:set(32, 1, 0) end)
assert(not ok)
ok = pcall(function() mud:set(-1, 1) end)
assert(not ok)
ok = pcall(function() mud:set(-1, 1, 0) end)
assert(not ok)
ok = pcall(function() mud:set(0, 1, -1) end)
assert(not ok)

---------------------------------------------------------------------
-- Copy memory to memory --------------------------------------------
---------------------------------------------------------------------

-- Allocate a 16 byte memory and set the values to 69
local mud16
ec, mud16 = gemdos.Malloc(16)
num_bytes = mud16:set(0, 69)
assert(num_bytes == 16)

-- Copy to first half of mud
num_bytes = mud:copym(0, mud16, 0, mud16:size())
assert(num_bytes == 16)

-- Copy to second half of mud
num_bytes = mud:copym(16, mud16, 0, mud16:size())
assert(num_bytes == 16)

num_bytes, str = mud:reads(0)
assert(str == "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE")

mud:poke(u8, 0, 42)
num_bytes = mud16:copym(15, mud, 0, 1)
assert(num_bytes == 1)

assert(mud16:peek(u8, 15) == 42)

---------------------------------------------------------------------
-- Check copying memory out of bounds -------------------------------
---------------------------------------------------------------------

ok = pcall(function() mud16:copym(0, mud, 0, mud:size()) end)
assert(not ok)
ok = pcall(function() mud16:copym(0, mud, 0, -1) end)
assert(not ok)
ok = pcall(function() mud16:copym(15, mud, 0, 2) end)
assert(not ok)

---------------------------------------------------------------------
-- Copy within memory -----------------------------------------------
---------------------------------------------------------------------
mud:writes(0, "Copy within memories with copym.")
num_bytes = mud:copym(5, mud, 12, mud:size() - 12)
assert(num_bytes == 20)

num_bytes, str = mud:reads(0)
assert(num_bytes == 32 and str == "Copy memories with copym. copym.")

---------------------------------------------------------------------
-- Test imodes with poke and peek -----------------------------------
---------------------------------------------------------------------
-- signed 8 bit max value
assert(mud:poke(s8, 0, 127) == 1)
assert(mud:peek(s8, 0) == 127)
ok = pcall(function() mud:poke(s8, 0, 128) end)
assert(not ok)
-- signed 8 bit min value
assert(mud:poke(s8, 0, -128) == 1)
assert(mud:peek(s8, 0) == -128)
ok = pcall(function() mud:poke(s8, 0, -129) end)
assert(not ok)

-- unsigned 8 bit max value
assert(mud:poke(u8, 0, 255) == 1)
assert(mud:peek(u8, 0) == 255)
ok = pcall(function() mud:poke(u8, 0, 256) end)
assert(not ok)
-- unsigned 8 bit min value
assert(mud:poke(u8, 0, 0) == 1)
assert(mud:peek(u8, 0) == 0)
ok = pcall(function() mud:poke(u8, 0, -1) end)
assert(not ok)

-- signed 16 bit max value
assert(mud:poke(s16, 0, 32767) == 2)
assert(mud:peek(s16, 0) == 32767)
ok = pcall(function() mud:poke(s16, 0, 32768) end)
assert(not ok)
-- signed 16 bit min value
assert(mud:poke(s16, 0, -32768) == 2)
assert(mud:peek(s16, 0) == -32768)
ok = pcall(function() mud:poke(s16, 0, -32769) end)
assert(not ok)

-- unsigned 16 bit max value
assert(mud:poke(u16, 0, 65535) == 2)
assert(mud:peek(u16, 0) == 65535)
ok = pcall(function() mud:poke(u16, 0, 65536) end)
assert(not ok)
-- unsigned 16 bit min value
assert(mud:poke(u16, 0, 0) == 2)
assert(mud:peek(u16, 0) == 0)
ok = pcall(function() mud:poke(u16, 0, -1) end)
assert(not ok)

-- signed 32 bit max value
assert(mud:poke(s32, 0, 2147483647) == 4)
assert(mud:peek(s32, 0) == 2147483647)
-- signed 32 bit min value
assert(mud:poke(s32, 0, -2147483648) == 4)
assert(mud:peek(s32, 0) == -2147483648)

-- Multiple signed 16 bit values on the stack
local t = {}
for v = 32767,32760,-1 do
  t[#t + 1] = v
end

mud:poke(s16, 0, table.unpack(t))
local r = table.pack(mud:peek(s16, 0, 8))
for i=1,#t do
  assert(t[i] == r[i])
end

-- Multiple unsigned 16 bit values on the stack
t = {}
for v = 65535,65528,-1 do
  t[#t + 1] = v
end
mud:poke(u16, 0, table.unpack(t))
r = table.pack(mud:peek(u16, 0, 8))
for i=1,#t do
  assert(t[i] == r[i])
end

-- multiple signed 32 bit values on the stack
t = {}
for v = 2147483647, 2147483644, -1 do
  t[#t + 1] = v
end

mud:poke(s32, 0, table.unpack(t))
r = table.pack(mud:peek(s32, 0, 4))
for i=1,#t do
  assert(t[i] == r[i])
end

-- odd offsets for signed 16 bit values must fail
ok = pcall(function() mud:poke(s16, 1, 0) end)
assert(not ok)
ok = pcall(function() mud:peek(s16, 1) end)
assert(not ok)

-- odd offsets for unsigned 16 bit values must fail
ok = pcall(function() mud:poke(u16, 1, 0) end)
assert(not ok)
ok = pcall(function() mud:peek(u16, 1) end)
assert(not ok)

-- odd offsets for signed 32 bit values must fail
ok = pcall(function() mud:poke(s32, 1, 0) end)
assert(not ok)
ok = pcall(function() mud:peek(s32, 1) end)
assert(not ok)

-- Offset checks (assuming s16 native endian is bigendian)
mud:set(0, 0)
assert(mud:poke(s16, 14, 32767) == 2)
assert(mud:peek(s16, 14) == 32767)
for k = 1, 13 do
  assert(mud:peek(u8, k) == 0)
end
assert(mud:peek(u8, 14) == 0x7f)
assert(mud:peek(u8, 15) == 0xff)

-- Offset checks (assuming u16 native endian is bigendian)
mud:set(0, 0)
assert(mud:poke(u16, 14, 32768) == 2)
assert(mud:peek(u16, 14) == 32768)
for k = 1, 13 do
  assert(mud:peek(u8, k) == 0)
end
assert(mud:peek(u8, 14) == 0x80)
assert(mud:peek(u8, 15) == 0x00)

-- Offset checks (assuming s32 native endian is bigendian)
mud:set(0, 0)
assert(mud:poke(s32, 12, 2147483647) == 4)
assert(mud:peek(s32, 12) == 2147483647)
for k = 1, 11 do
  assert(mud:peek(u8, k) == 0)
end
assert(mud:peek(u8, 12) == 0x7f)
assert(mud:peek(u8, 13) == 0xff)
assert(mud:peek(u8, 14) == 0xff)
assert(mud:peek(u8, 15) == 0xff)

-- Writing and reading beyond the end must fail (s16)
assert(mud:poke(s16, 30, 42) == 2)
ok = pcall(function() mud:poke(s16, 30, 1, 2) end)
assert(not ok)
assert(mud:peek(s16, 30) == 42)
ok = pcall(function() mud:peek(s16, 30, 2) end)
assert(not ok)

-- Writing and reading beyond the end must fail (u16)
assert(mud:poke(u16, 30, 43) == 2)
ok = pcall(function() mud:poke(u16, 30, 1, 2) end)
assert(not ok)
assert(mud:peek(u16, 30) == 43)
ok = pcall(function() mud:peek(u16, 30, 2) end)
assert(not ok)

-- Writing and reading beyond the end must fail (s32)
assert(mud:poke(s32, 28, 44) == 4)
ok = pcall(function() mud:poke(s32, 28, 1, 2) end)
assert(not ok)
assert(mud:peek(s32, 28) == 44)
ok = pcall(function() mud:peek(s32, 28, 2) end)
assert(not ok)

---------------------------------------------------------------------
-- Test imodes with writet and readt --------------------------------
---------------------------------------------------------------------
--- Writing and reading s16
mud:set(0, 0)
t = {}
for v=1,16 do
  t[v] = v
end
assert(mud:writet(s16, 0, t) == 32)
local num, t2 = mud:readt(s16, 0)
assert(num == 32)
for k=1,16 do
  assert(t2[k] == t[k])
end

-- Writing and reading u16
t = {}
for v=1,16 do
  t[v] = v
end
assert(mud:writet(u16, 0, t) == 32)
num, t2 = mud:readt(u16, 0)
assert(num == 32)
for k=1,16 do
  assert(t2[k] == t[k])
end

-- Writing and reading s32
t = {}
for v=1,8 do
  t[v] = v
end
assert(mud:writet(s32, 0, t) == 32)
num, t2 = mud:readt(s32, 0)
assert(num == 32)
for k=1,8 do
  assert(t2[k] == t[k])
end

-- signed 8 bit max value
t = { 127 }
assert(mud:writet(s8, 0, t) == 1)
num, t2 = mud:readt(s8, 0, 1)
assert(num == 1 and t2[1] == t[1])
t[1] = 128
ok = pcall(function() mud:writet(s8, 0, t) end)
assert(not ok)

-- signed 8 bit min value
t = { -128 }
assert(mud:writet(s8, 0, t) == 1)
num, t2 = mud:readt(s8, 0, 1)
assert(num == 1 and t2[1] == t[1])
t[1] = -129
ok = pcall(function() mud:writet(s8, 0, t) end)
assert(not ok)

-- unsigned 8 bit max value
t = { 255 }
assert(mud:writet(u8, 0, t) == 1)
num, t2 = mud:readt(u8, 0, 1)
assert(num == 1 and t2[1] == t[1])
t[1] = 256
ok = pcall(function() mud:writet(u8, 0, t) end)
assert(not ok)

-- unsigned 8 bit min value
t = { 0 }
assert(mud:writet(u8, 0, t) == 1)
num, t2 = mud:readt(u8, 0, 1)
assert(num == 1 and t2[1] == t[1])
t[1] = -1
ok = pcall(function() mud:writet(u8, 0, t) end)
assert(not ok)

-- signed 16 bit max value
t = { 32767 }
assert(mud:writet(s16, 0, t) == 2)
num, t2 = mud:readt(s16, 0, 1)
assert(num == 2 and t2[1] == t[1])
t[1] = 32768
ok = pcall(function() mud:writet(s16, 0, t) end)
assert(not ok)

-- signed 16 bit min value
t = { -32768 }
assert(mud:writet(s16, 0, t) == 2)
num, t2 = mud:readt(s16, 0, 1)
assert(num == 2 and t2[1] == t[1])
t[1] = -32769
ok = pcall(function() mud:writet(s16, 0, t) end)
assert(not ok)

-- unsigned 16 bit max value
t = { 65535 }
assert(mud:writet(u16, 0, t) == 2)
num, t2 = mud:readt(u16, 0, 1)
assert(num == 2 and t2[1] == t[1])
t[1] = 65536
ok = pcall(function() mud:writet(u16, 0, t) end)
assert(not ok)

-- unsigned 16 bit min value
t = { 0 }
assert(mud:writet(u16, 0, t) == 2)
num, t2 = mud:readt(u16, 0, 1)
assert(num == 2 and t2[1] == t[1])
t[1] = -1
ok = pcall(function() mud:writet(u16, 0, t) end)
assert(not ok)

-- signed 32 bit max value
t = { 2147483647 }
assert(mud:writet(s32, 0, t) == 4)
num, t2 = mud:readt(s32, 0, 1)
assert(num == 4 and t2[1] == t[1])

-- signed 32 bit min value
t = { -2147483648 }
assert(mud:writet(s32, 0, t) == 4)
num, t2 = mud:readt(s32, 0, 1)
assert(num == 4 and t2[1] == t[1])

-- odd offsets for signed 16 bit values must fail
t = { 0 }
ok = pcall(function() mud:writet(s16, 1, t) end)
assert(not ok)
ok = pcall(function() mud:readt(s16, 1) end)
assert(not ok)

-- odd offsets for unsigned 16 bit values must fail
ok = pcall(function() mud:writet(u16, 1, t) end)
assert(not ok)
ok = pcall(function() mud:readt(u16, 1) end)
assert(not ok)

-- odd offsets for signed 32 bit values must fail
ok = pcall(function() mud:writet(s32, 1, 0) end)
assert(not ok)
ok = pcall(function() mud:readt(s32, 1) end)
assert(not ok)

-- Offset checks (assuming s16 native endian is bigendian)
mud:set(0, 0)
t = { 32767 }
assert(mud:writet(s16, 14, t) == 2)
ec, t2 = mud:readt(s16, 14, 1)
assert(ec == 2 and t2[1] == t[1])
for k = 1, 13 do
  assert(mud:peek(u8, k) == 0)
end
assert(mud:peek(u8, 14) == 0x7f)
assert(mud:peek(u8, 15) == 0xff)

-- Offset checks (assuming u16 native endian is bigendian)
mud:set(0, 0)
t = { 32768 }
assert(mud:writet(u16, 14, t) == 2)
ec, t2 = mud:readt(u16, 14, 1)
assert(ec == 2 and t2[1] == t[1])
for k = 1, 13 do
  assert(mud:peek(u8, k) == 0)
end
assert(mud:peek(u8, 14) == 0x80)
assert(mud:peek(u8, 15) == 0x00)

-- Offset checks (assuming s32 native endian is bigendian)
mud:set(0, 0)
t = { 2147483647 }
assert(mud:writet(s32, 12, t) == 4)
ec, t2 = mud:readt(s32, 12, 1)
assert(ec == 4 and t2[1] == t[1])
for k = 1, 11 do
  assert(mud:peek(u8, k) == 0)
end
assert(mud:peek(u8, 12) == 0x7f)
assert(mud:peek(u8, 13) == 0xff)
assert(mud:peek(u8, 14) == 0xff)
assert(mud:peek(u8, 15) == 0xff)

-- Writing and reading beyond the end must fail (s16)
mud:set(0, 0)
t = { 42, 43 }
assert(mud:writet(s16, 30, t, 1, 1) == 2)
ok = pcall(function() mud:writet(s16, 30, t, 1) end)
assert(not ok)
ec, t2 = mud:readt(s16, 30, 1)
assert(ec == 2 and t2[1] == t[1])
ok = pcall(function() mud:readt(s16, 30, 2) end)
assert(not ok)

-- Writing and reading beyond the end must fail (u16)
t = { 44, 45 }
assert(mud:writet(u16, 30, t, 1, 1) == 2)
ok = pcall(function() mud:writet(u16, 30, t, 1) end)
assert(not ok)
ec, t2 = mud:readt(u16, 30, 1)
assert(ec == 2 and t2[1] == t[1])
ok = pcall(function() mud:readt(u16, 30, 2) end)
assert(not ok)

-- Writing and reading beyond the end must fail (s32)
t = { 46, 47 }
assert(mud:writet(s32, 28, t, 1, 1) == 4)
ok = pcall(function() mud:writet(s32, 28, t, 1) end)
assert(not ok)
ec, t2 = mud:readt(s32, 28, 1)
assert(ec == 4 and t2[1] == t[1])
ok = pcall(function() mud:readt(s32, 28, 2) end)
assert(not ok)

---------------------------------------------------------------------
-- imode with odd memory sizes and poke/peek ------------------------
---------------------------------------------------------------------
mud:free()
-- Allocate 15 byte mud
ec, mud = gemdos.Malloc(15)
assert(ec > 0)
assert(mud:address() ~= 0)
assert(mud:size() == 15)
mud:set(0, 0)

-- Poking seven values for imode s16 must succeed
t = { 1, 2, 3, 4, 5, 6, 7 }
assert(mud:poke(s16, 0, table.unpack(t)) == 14)
-- Poking eight values for imode s16 must fail
ok = pcall(function() mud:poke(s16, 0, 0, table.unpack(t)) end)
assert(not ok)
-- Peeking seven values for imode s16 must succeed
t2 = table.pack(mud:peek(s16, 0, 7))
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Peeking eight values for imode s16 must fail
ok = pcall(function() mud:peek(s16, 0, 8) end)
assert(not ok)

-- Also check with a non-zero offset
-- Poking six values for imode s16 with offset 2 must succeed
t = { 1, 2, 3, 4, 5, 6 }
assert(mud:poke(s16, 2, table.unpack(t)) == 12)
-- Poking seven values at offset 2 for imode s16 must fail
ok = pcall(function() mud:poke(s16, 2, 0, table.unpack(t)) end)
assert(not ok)
-- Peeking six values for imode s16 with offset 2 must succeed
t2 = table.pack(mud:peek(s16, 2, 6))
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Peeking seven values at offset 2 for imode s16 must fail
ok = pcall(function() mud:peek(s16, 2, 7) end)
assert(not ok)

-- Poking seven values for imode u16 must succeed
t = { 1, 2, 3, 4, 5, 6, 7 }
assert(mud:poke(u16, 0, table.unpack(t)) == 14)
-- Poking eight values for imode u16 must fail
ok = pcall(function() mud:poke(u16, 0, 0, table.unpack(t)) end)
assert(not ok)
-- Peeking seven values for imode u16 must succeed
t2 = table.pack(mud:peek(u16, 0, 7))
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Peeking eight values for imode u16 must fail
ok = pcall(function() mud:peek(u16, 0, 8) end)
assert(not ok)

-- Also check with a non-zero offset
-- Poking six values for imode u16 with offset 2 must succeed
t = { 1, 2, 3, 4, 5, 6 }
assert(mud:poke(u16, 2, table.unpack(t)) == 12)
-- Poking seven values at offset 2 for imode u16 must fail
ok = pcall(function() mud:poke(u16, 2, 0, table.unpack(t)) end)
assert(not ok)
-- Peeking six values for imode u16 with offset 2 must succeed
t2 = table.pack(mud:peek(u16, 2, 6))
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Peeking seven values at offset 2 for imode u16 must fail
ok = pcall(function() mud:peek(u16, 2, 7) end)
assert(not ok)

-- Poking three values for imode s32 must succeed
t = { 1, 2, 3 }
assert(mud:poke(s32, 0, table.unpack(t)) == 12)
-- Poking four values for imode s32 must fail
ok = pcall(function() mud:poke(s32, 0, 0, table.unpack(t)) end)
assert(not ok)
-- Peeking three values for imode s32 must succeed
t2 = table.pack(mud:peek(s32, 0, 3))
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Peeking four values for imode s32 must fail
ok = pcall(function() mud:peek(s32, 0, 4) end)
assert(not ok)

-- Also check with a non-zero offset
-- Poking two values for imode s32 with offset 4 must succeed
t = { 1, 2 }
assert(mud:poke(s32, 4, table.unpack(t)) == 8)
-- Poking three values at offset 4 for imode s32 must fail
ok = pcall(function() mud:poke(s32, 4, 0, table.unpack(t)) end)
assert(not ok)
-- Peeking two values for imode s32 with offset 4 must succeed
t2 = table.pack(mud:peek(s32, 4, 2))
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Peeking three values at offset 4 for imode s32 must fail
ok = pcall(function() mud:peek(s32, 4, 3) end)
assert(not ok)

---------------------------------------------------------------------
-- imode with odd memory sizes and writet/readt ---------------------
---------------------------------------------------------------------

-- Writing seven values for imode s16 must succeed
t = { 1, 2, 3, 4, 5, 6, 7 }
assert(mud:writet(s16, 0, t) == 14)
-- Writing eight values for imode s16 must fail
t2 = table.move(t, 1, #t, 1, {})
table.insert(t2, 8)
ok = pcall(function() mud:writet(s16, 0, t2) end)
assert(not ok)
-- Reading seven values for imode s16 must succeed
num, t2 = mud:readt(s16, 0, 7)
assert(num == 14)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Without num values, must only read complete values
num, t2 = mud:readt(s16, 0)
assert(num == 14)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Reading eight values for imode s16 must fail
ok = pcall(function() mud:readt(s16, 0, 8) end)
assert(not ok)

-- Also check with a non-zero offset
-- Writing six values for imode s16 with offset 2 must succeed
t = { 1, 2, 3, 4, 5, 6 }
assert(mud:writet(s16, 2, t) == 12)
-- Writing seven values at offset 2 for imode s16 must fail
t2 = table.move(t, 1, #t, 1, {})
table.insert(t2, 7)
ok = pcall(function() mud:writet(s16, 2, t2) end)
assert(not ok)
-- Reading six values for imode s16 with offset 2 must succeed
num, t2 = mud:readt(s16, 2, 6)
assert(num == 12)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Without num values, must only read complete values
num, t2 = mud:readt(s16, 2)
assert(num == 12)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Reading seven values for imode s16 with offset 2 must fail
ok = pcall(function() mud:readt(s16, 2, 7) end)
assert(not ok)

-- Writing seven values for imode u16 must succeed
t = { 1, 2, 3, 4, 5, 6, 7 }
assert(mud:writet(u16, 0, t) == 14)
-- Writing eight values for imode u16 must fail
t2 = table.move(t, 1, #t, 1, {})
table.insert(t2, 8)
ok = pcall(function() mud:writet(u16, 0, t2) end)
assert(not ok)
-- Reading seven values for imode u16 must succeed
num, t2 = mud:readt(u16, 0, 7)
assert(num == 14)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Without num values, must only read complete values
num, t2 = mud:readt(u16, 0)
assert(num == 14)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Reading eight values for imode u16 must fail
ok = pcall(function() mud:readt(u16, 0, 8) end)
assert(not ok)

-- Also check with a non-zero offset
-- Writing six values for imode u16 with offset 2 must succeed
t = { 1, 2, 3, 4, 5, 6 }
assert(mud:writet(u16, 2, t) == 12)
-- Writing seven values at offset 2 for imode u16 must fail
t2 = table.move(t, 1, #t, 1, {})
table.insert(t2, 7)
ok = pcall(function() mud:writet(u16, 2, t2) end)
assert(not ok)
-- Reading six values for imode u16 with offset 2 must succeed
num, t2 = mud:readt(u16, 2, 6)
assert(num == 12)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Without num values, must only read complete values
num, t2 = mud:readt(u16, 2)
assert(num == 12)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Reading seven values for imode s16 with offset 2 must fail
ok = pcall(function() mud:readt(u16, 2, 7) end)
assert(not ok)

-- Writing three values for imode s32 must succeed
t = { 1, 2, 3 }
assert(mud:writet(s32, 0, t) == 12)
-- Writing four values for imode s32 must fail
t2 = table.move(t, 1, #t, 1, {})
table.insert(t2, 4)
ok = pcall(function() mud:writet(s32, 0, t2) end)
assert(not ok)
-- Reading three values for imode s32 must succeed
num, t2 = mud:readt(s32, 0, 3)
assert(num == 12)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Without num values, must only read complete values
num, t2 = mud:readt(s32, 0)
assert(num == 12)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Reading four values for imode s32 must fail
ok = pcall(function() mud:readt(s32, 0, 4) end)
assert(not ok)

-- Also check with a non-zero offset
-- Writing two values for imode s32 with offset 4 must succeed
t = { 1, 2 }
assert(mud:writet(s32, 4, t) == 8)
-- Writing three values at offset 4 for imode s32 must fail
t2 = table.move(t, 1, #t, 1, {})
table.insert(t2, 3)
ok = pcall(function() mud:writet(s32, 4, t2) end)
assert(not ok)
-- Reading two values for imode s32 with offset 4 must succeed
num, t2 = mud:readt(s32, 4, 2)
assert(num == 8)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Without num values, must only read complete values
num, t2 = mud:readt(s32, 4)
assert(num == 8)
for k,v in ipairs(t2) do
  assert(v == t[k])
end
-- Reading three values for imode s32 with offset 4 must fail
ok = pcall(function() mud:readt(s32, 4, 3) end)
assert(not ok)

---------------------------------------------------------------------
-- Compare memory ---------------------------------------------------
---------------------------------------------------------------------

-- Comparing a memory with itself must match
local muda
ec, muda = gemdos.Malloc(16)
num_bytes = muda:set(0, 69)
assert(num_bytes == 16)
assert(muda:comparem(0, muda, 0, muda:size()) == 0)

-- Comparing a memory with an identical memory must match
local mudb
ec, mudb = gemdos.Malloc(16)
num_bytes = mudb:set(0,69)
assert(num_bytes == 16)
assert(muda:comparem(0, mudb, 0, muda:size()) == 0)

-- Comparing different memories, must not match
num_bytes = muda:set(0,0)
assert(num_bytes == 16)
num_bytes = mudb:set(0,1)
assert(num_bytes == 16)
assert(muda:comparem(0, mudb, 0, muda:size()) ~= 0)

-- Comparing portions
muda:set(0, 1, muda:size()/2)
muda:set(muda:size()/2, 2, muda:size()/2)
mudb:copym(0, muda, 0, mudb:size())

assert(muda:comparem(0, mudb, 0, muda:size()) == 0)
assert(muda:comparem(0, mudb, muda:size()/2, muda:size()/2) ~= 0)
assert(muda:comparem(muda:size()/2, mudb, 0, muda:size()/2) ~= 0)
assert(muda:comparem(0, mudb, 0, muda:size()/2) == 0)
assert(muda:comparem(muda:size()/2, mudb, muda:size()/2, muda:size()/2) == 0)

---------------------------------------------------------------------
-- Check comparing memory out of bounds -----------------------------
---------------------------------------------------------------------

ok = pcall(function() muda:comparem(0, mudb, 0, muda:size() + 1) end)
assert(not ok)
ok = pcall(function() muda:comparem(0, mudb, 0, -1) end)
assert(not ok)
ok = pcall(function() muda:comparem(15, mudb, 0, 2) end)
assert(not ok)

muda:free()
mudb:free()

gemdos.Cconws("Test gemdos.Malloc completed\r\n")
