-- Unittest for gemdos.Ddelete
gemdos.Cconws("Test gemdos.Ddelete\r\n")

local ec, msg = gemdos.Dcreate("TESTDIR")
assert(ec == 0, msg)

ec, msg = gemdos.Ddelete("TESTDIR")
assert(ec == 0, msg)

ec, msg = gemdos.Ddelete("TESTDIR")
assert(ec < 0, msg)

-- Completed
gemdos.Cconws("Test gemdos.Ddelete completed\r\n")
