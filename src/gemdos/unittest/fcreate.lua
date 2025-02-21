-- Unittest for gemdos.Fcreate
gemdos.Cconws("Test gemdos.Fcreate\r\n")

-- Create a new file named TESTFILE
-- See also fattrib.lua for attribute testing
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Write data
gemdos.Fwrites(fud, "orange")

-- Close it
ec = gemdos.Fclose(fud)
assert(ec == 0, msg)

-- Create the file again - this will truncate
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- TODO CHECK: Should Fcreate make RO, R/W or WO file handle?

-- Will read zero bytes due to truncation
local num_bytes, str = gemdos.Freads(fud, 6);
assert(num_bytes == 0 and str == "")

-- Close the file
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Create with directory attribute set must fail
local ok = pcall(function() gemdos.Fcreate("TESTFILE",
  gemdos.const.Fattrib.dir) end)
assert(not ok)

-- If volume attribute is set no other attribute must be set
ok = pcall(function() gemdos.Fcreate("TESTFILE",
  gemdos.const.Fattrib.volume | gemdos.const.Fattrib.archive) end)
assert(not ok)

gemdos.Cconws("Test gemdos.Fcreate completed\r\n")
