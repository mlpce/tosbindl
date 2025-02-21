-- Unittest for gemdos.Dsetpath
gemdos.Cconws("Test gemdos.Dsetpath\r\n")

-- Create test directory
local ec = gemdos.Dcreate("TESTDIR")
assert(ec == 0)

-- Set the path to the test directory
ec = gemdos.Dsetpath("TESTDIR")
assert(ec == 0)

-- Go to the directory above the test directory
ec = gemdos.Dsetpath("..")
assert(ec == 0)

-- Delete the test directory
ec = gemdos.Ddelete("TESTDIR")
assert(ec == 0)

-- Completed
gemdos.Cconws("Test gemdos.Dsetpath completed\r\n")
