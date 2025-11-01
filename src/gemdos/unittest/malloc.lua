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
local mud = gemdos.Malloc(1024*1024*1024)
assert(mud == gemdos.const.Error.ENSMEM)

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
local ec
ec, mud = gemdos.Malloc(32)
assert(ec > 0)
assert(mud:address() ~= 0)
assert(mud:size() == 32)

---------------------------------------------------------------------
-- Poke and peek ----------------------------------------------------
---------------------------------------------------------------------

-- Test poke and peek. Mud offsets start from zero.
assert(mud:poke(0, 40) == 1, "Poke failed")
assert(mud:peek(0) == 40, "Peek failed")
assert(mud:poke(0, 42) == 1, "Poke failed")
assert(mud:peek(0) == 42, "Peek failed")
-- Multivalue poke
assert(mud:poke(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
  18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32) == 32,
  "Poke failed")
ok = pcall(function() mud:poke(-1, 0) end) -- Negative offset must fail
assert(not ok)
ok = pcall(function() mud:poke(31, 1, 2) end) -- Poke beyond end must fail
assert(not ok)
ok = pcall(function() mud:poke(32, 2) end) -- Poke beyond end must fail
assert(not ok)
-- Multivalue peek
local t1 = table.pack(mud:peek(0, 16))
assert(#t1 == 16)
table.move(table.pack(mud:peek(16, 16)),1,16,17,t1)
assert(#t1 == 32)
for k,v in ipairs(t1) do
  assert(k == v)
end

-- Max number of peek values is 16 so 17 must fail
-- See TOSBINDL_GEMDOS_MAX_MULTIVAL
ok = pcall(function() mud:peek(0, 17) end)
assert(not ok)

-- Set memory from offset 0 to value '69', for the whole size
mud:set(0, 69, mud:size())

-- Each byte must now be 69
for i=0, mud:size() - 1 do
  assert(mud:peek(i) == 69)
end

-- Poke ASCII for 'A' to offset 2
-- Poke ASCII for 'B' to offset 3
mud:poke(2, 65)
mud:poke(3, 66)

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
num_bytes, tbl = mud:readt(0)
assert(num_bytes == mud:size() and type(tbl) == "table")

-- Check all values are correct
for i=1,#tbl do
  assert(tbl[i] == 69)
end

-- Poke some changes
mud:poke(2, 65)
mud:poke(3, 66)

-- Read four bytes from offset two
num_bytes, tbl = mud:readt(2, 4)
assert(num_bytes == 4)

-- Check the table values. The tables use one based indices.
assert(tbl[1] == 65 and tbl[2] == 66)
assert(string.char(table.unpack(tbl)) == "ABEE")

---------------------------------------------------------------------
-- Test writing a table into the memory -----------------------------
---------------------------------------------------------------------

-- mud:writet takes four parameters, the first two parameters are the
-- memory offset and the table to write and are required. Memory
-- offsets are still zero based. Parameters three and four are
-- optional and if present specify the start table position and the
-- end table position (one based indices).
num_bytes = mud:writet(16, {79, 114, 97, 110, 103, 101, 115})
assert(num_bytes == 7)

num_bytes, tbl = mud:readt(0)
assert(num_bytes == 32)
assert(string.char(table.unpack(tbl)) == "EEABEEEEEEEEEEEEOrangesEEEEEEEEE")

---------------------------------------------------------------------
-- Test writing a table out of bounds of the memory -----------------
---------------------------------------------------------------------

-- Writing before the beginning
num_bytes, old = mud:readt(0)
ok = pcall(function() mud:writet(-1, {1, 2}) end)
num_bytes, new = mud:readt(0)
assert(not ok and table.concat(old) == table.concat(new))

-- Writing beyond the end
num_bytes, old = mud:readt(0)
ok = pcall(function() mud:writet(31, {1, 2}) end)
num_bytes, new = mud:readt(0)
assert(not ok and table.concat(old) == table.concat(new))

---------------------------------------------------------------------
-- Test writing a table into memory with table positions ------------
---------------------------------------------------------------------

-- positive values are positions from the start of the table
-- negative values are positions from the end of the table
tbl = table.pack(string.byte("retro computing is cool", 1, -1))
assert(mud:writet(0, tbl, -4, -1) == 4)  -- 'cool'
assert(mud:writet(4, tbl, -5, -5) == 1)  -- ' '
assert(mud:writet(5, tbl, 7, -9) == 9)   -- 'computing'
assert(mud:writet(14, tbl, 16, 19) == 4) -- ' is '
assert(mud:writet(18, tbl, 1, 5) == 5)   -- 'retro'
mud:writet(23, table.pack(string.byte(' Atari ST', 1, -1)))
num_bytes, new = mud:readt(0)
assert(string.char(table.unpack(new)) == "cool computing is retro Atari ST")

---------------------------------------------------------------------
-- Test table positions that are out of bounds for the source table
---------------------------------------------------------------------

tbl = table.pack(string.byte("word", 1, -1))
ok = pcall(function() mud:writet(0, tbl, 0, -1) end)
assert(not ok)
ok = pcall(function() mud:writet(0, tbl, 4, 5) end)
assert(not ok)
ok = pcall(function() mud:writet(0, tbl, 3, 2) end)
assert(not ok)
ok = pcall(function() mud:writet(0, tbl, -5, -1) end)
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

assert(mud:peek(0) == 1)
for i=0,15 do
  assert(mud:peek(i) == 1)
end
for i=16,29 do
  assert(mud:peek(i) == 2)
end
assert(mud:peek(30) == 3)
assert(mud:peek(31) == 4)

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

mud:poke(0, 42)
num_bytes = mud16:copym(15, mud, 0, 1)
assert(num_bytes == 1)

assert(mud16:peek(15) == 42)

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
