-- Unittest for gemdos.utility
gemdos.Cconws("Test gemdos.utility\r\n")

local env_table = gemdos.utility.getenv()
local env_path = gemdos.utility.getenv("PATH")
assert(env_path == env_table.PATH)

local ec, mud <close> = gemdos.utility.allocm(8)
assert(ec == 8)
local mud2 = gemdos.utility.wrapm(mud:address(), mud:size())

mud:set(0, 48)
assert(mud2:reads(0) == "00000000")

mud2:set(0,49)
assert(mud:reads(0) == "11111111")

-- Odd address cannot be wrapped
local ok = pcall(
  function() gemdos.utility.wrapm(mud:address() + 1, mud:size() - 1) end)
assert(not ok)

-- libc allocated memory cannot be shrunk
ok = pcall(function() mud:shrink(2) end)
assert(not ok)

-- Wrapped memory cannot be shrunk
ok = pcall(function() mud2:shrink(2) end)
assert(not ok)

-- Test allocation failure with allocm
local mud3
ec, mud3 = gemdos.utility.allocm(1024*1024*512)
assert(ec == gemdos.const.Error.ENSMEM and mud3 == nil)

gemdos.Cconws("Test gemdos.utility completed\r\n")
