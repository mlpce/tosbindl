-- Unittest for gemdos.Fclose
gemdos.Cconws("Test gemdos.Fclose\r\n")

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Close it
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Closing it again must fail
local ok = pcall(function() gemdos.Fclose(fud) end)
assert(not ok)

-- Create the file again
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- This time close it with self
ec = fud:close()
assert(ec == 0)

-- Closing it again must fail
ok = pcall(function() fud:close() end)
assert(not ok)

gemdos.Cconws("Test gemdos.Fclose completed\r\n")
