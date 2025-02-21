-- Unittest for gemdos.Dcreate
gemdos.Cconws("Test gemdos.Dcreate\r\n")

local ec = gemdos.Dcreate("TESTDIR")
assert(ec == 0)

ec = gemdos.Dcreate("TESTDIR")
assert(ec < 0)

ec = gemdos.Ddelete("TESTDIR")
assert(ec == 0)

-- Completed
gemdos.Cconws("Test gemdos.Dcreate completed\r\n")
