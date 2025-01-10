-- Unittest for gemdos.Dsetpath
gemdos.Cconws("Test gemdos.Dsetpath\r\n")

-- Create test directory
local ec, msg = gemdos.Dcreate("TESTDIR")
assert(ec == 0, msg)

-- Set the path to the test directory
ec, msg = gemdos.Dsetpath("TESTDIR")
assert(ec == 0, msg)

-- Go to the directory above the test directory
ec, msg = gemdos.Dsetpath("..")
assert(ec == 0, msg)

-- Delete the test directory
ec, msg = gemdos.Ddelete("TESTDIR")
assert(ec == 0, msg)

-- Completed
gemdos.Cconws("Test gemdos.Dsetpath completed\r\n")
