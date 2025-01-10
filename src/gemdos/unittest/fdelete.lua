-- Unittest for gemdos.Fdelete
gemdos.Cconws("Test gemdos.Fdelete\r\n")

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)

-- Delete it
local msg
ec, msg = gemdos.Fdelete("TESTFILE")
assert(ec == 0, msg)

-- Deleting it again must fail
ec, msg = gemdos.Fdelete("TESTFILE")
assert(ec == gemdos.const.Error.EFILNF, msg)

gemdos.Cconws("Test gemdos.Fdelete completed\r\n")
