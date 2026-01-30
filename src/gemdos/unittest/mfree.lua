-- Unittest for gemdos.Mfree
gemdos.Cconws("Test gemdos.Mfree\r\n")

---------------------------------------------------------------------
-- Check allocated memory can be freed ------------------------------
---------------------------------------------------------------------

-- Allocate 32 bytes
local ec, mud = gemdos.Malloc(32)
assert(ec == 32)
assert(mud:address() ~= 0)
assert(mud:size() == 32)

mud:set(0, 69)

local str = mud:reads(0)
assert(type(str) == "string" and #str == mud:size())
assert(str == "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE")

-- Free the mud
ec = gemdos.Mfree(mud)
assert(ec == 0)

-- Freeing it again must fail
local ok = pcall(function() gemdos.Mfree(mud) end)
assert(not ok)

-- Reading from it must now fail
ok = pcall(function() mud:reads(0) end)
assert(not ok)

---------------------------------------------------------------------
-- Allocate and free half of largest free memory block in a loop ----
---------------------------------------------------------------------

-- Get largest free memory block
local lfmb = gemdos.Malloc(-1)

-- Allocate half of it then free it in a loop
for i=1,100 do
  num_bytes, mud = gemdos.Malloc(lfmb/2)
  assert(num_bytes > 0, mud)
  ec = gemdos.Mfree(mud)
  assert(ec == 0)
end

---------------------------------------------------------------------
-- Check memory can be closed ---------------------------------------
---------------------------------------------------------------------
local mud2
do
  ec, mud2 = gemdos.Malloc(32)
  assert(mud2:address() ~= 0 and mud2:size() == ec)
  local mud_to_close <close> = mud2
end
assert(mud2:address() == 0 and mud2:size() == 0)

---------------------------------------------------------------------
-- Check memory can be freed through self ---------------------------
---------------------------------------------------------------------

num_bytes, mud = gemdos.Malloc(32);

ec = mud:free()
assert(ec == 0)

gemdos.Cconws("Test gemdos.Mfree completed\r\n")
