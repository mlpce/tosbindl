-- Unittest for gemdos.Fdelete
gemdos.Cconws("Test gemdos.Fdelete\r\n")

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Close the file
ec = gemdos.Fclose(fud)
assert(ec == 0)

-- Delete it
ec = gemdos.Fdelete("TESTFILE")
assert(ec == 0)

-- Deleting it again must fail
ec = gemdos.Fdelete("TESTFILE")
assert(ec == gemdos.const.Error.EFILNF)

gemdos.Cconws("Test gemdos.Fdelete completed\r\n")
