-- Unittest for gemdos.Ddelete
gemdos.Cconws("Test gemdos.Ddelete\r\n")

local ec = gemdos.Dcreate("TESTDIR")
assert(ec == 0)

ec = gemdos.Ddelete("TESTDIR")
assert(ec == 0)

ec = gemdos.Ddelete("TESTDIR")
assert(ec < 0)

-- Completed
gemdos.Cconws("Test gemdos.Ddelete completed\r\n")
