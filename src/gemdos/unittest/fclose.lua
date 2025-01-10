-- Unittest for gemdos.Fclose
gemdos.Cconws("Test gemdos.Fclose\r\n")

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)

-- Close it
local msg
ec, msg = gemdos.Fclose(fud)
assert(ec == 0, msg)

-- Closing it again must fail
local ok
ok, msg = pcall(function() gemdos.Fclose(fud) end)
assert(not ok)

-- Create the file again
ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)

-- This time close it with self
ec, msg = fud:close()
assert(ec == 0, msg)

-- Closing it again must fail
ok, msg = pcall(function() fud:close() end)
assert(not ok)

gemdos.Cconws("Test gemdos.Fclose completed\r\n")
