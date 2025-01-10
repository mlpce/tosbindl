-- Unittest for gemdos.Mshrink
gemdos.Cconws("Test gemdos.Mshrink\r\n")

---------------------------------------------------------------------
-- Check allocated memory can be shrunk -----------------------------
---------------------------------------------------------------------
local ec, mud = gemdos.Malloc(32)
assert(ec == 32, mud)
assert(mud:size() == 32)

-- Set the memory to 69
mud:set(0, 69)

-- Shrink it to 16 bytes
local msg
ec, msg = gemdos.Mshrink(mud, 16)
assert(ec == 16, msg)
assert(mud:size() == 16)

-- Read the memory, it must still contain 69
local num_bytes, str = mud:reads(0)
assert(num_bytes == 16 and str == "EEEEEEEEEEEEEEEE")

-- Try enlarge the memory, this must fail
ec, msg = gemdos.Mshrink(mud, 32)
assert(ec == gemdos.const.Error.EGSBF, msg)

-- The memory must still contain 69
local str2
num_bytes, str2 = mud:reads(0)
assert(num_bytes == 16 and str2 == "EEEEEEEEEEEEEEEE")

---------------------------------------------------------------------
-- Check memory can be shrunk through self --------------------------
---------------------------------------------------------------------
ec, msg = mud:shrink(8)
assert(ec == 8, msg)
assert(mud:size() == 8)

gemdos.Cconws("Test gemdos.Mshrink completed\r\n")
