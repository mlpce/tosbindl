-- Unittest for gemdos.Dcreate
gemdos.Cconws("Test gemdos.Dcreate\r\n")

local ec, msg = gemdos.Dcreate("TESTDIR")
assert(ec == 0, msg)

ec, msg = gemdos.Dcreate("TESTDIR")
assert(ec < 0, msg)

ec, msg = gemdos.Ddelete("TESTDIR")
assert(ec == 0, msg)

-- Completed
gemdos.Cconws("Test gemdos.Dcreate completed\r\n")
