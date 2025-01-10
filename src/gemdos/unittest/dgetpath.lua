-- Unittest for gemdos.Dgetpath
gemdos.Cconws("Test gemdos.Dgetpath\r\n")

-- Create test directory
local ec, msg = gemdos.Dcreate("TESTDIR")
assert(ec == 0, msg)

-- Set the path to the test directory
ec, msg = gemdos.Dsetpath("TESTDIR")
assert(ec == 0, msg)

-- Get the path
local path
ec, path = gemdos.Dgetpath(0)
assert(ec == 0)

-- Check the end of the path
assert(string.sub(path, -8, -1) == "\\TESTDIR")

-- Go back to the containing directory
ec, msg = gemdos.Dsetpath("..")
gemdos.Ddelete("TESTDIR")

-- Delete the test directory
ec, msg = gemdos.Ddelete("TESTDIR")

-- Completed
gemdos.Cconws("Test gemdos.Dgetpath completed\r\n")
