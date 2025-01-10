-- Unittest for gemdos.Fcreate
gemdos.Cconws("Test gemdos.Fcreate\r\n")

-- Create a new file named TESTFILE
-- See also fattrib.lua for attribute testing
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)

-- Write data
gemdos.Fwrites(fud, "orange")

-- Close it
local msg
ec, msg = gemdos.Fclose(fud)
assert(ec == 0, msg)

-- Create the file again - this will truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)

-- TODO CHECK: Fcreate makes write only file handle?

-- Will read zero bytes due to truncation
local num_bytes, str = gemdos.Freads(fud, 6);
assert(num_bytes == 0, str)

-- Create with directory attribute set must fail
local ok
ok, msg = pcall(function() gemdos.Fcreate("TESTFILE",
  gemdos.const.Fattrib.dir) end)
assert(not ok)

-- If volume attribute is set no other attribute must be set
ok, msg = pcall(function() gemdos.Fcreate("TESTFILE",
  gemdos.const.Fattrib.volume | gemdos.const.Fattrib.archive) end)
assert(not ok)

gemdos.Cconws("Test gemdos.Fcreate completed\r\n")
