-- Unittest for gemdos.Dgetpath
gemdos.Cconws("Test gemdos.Dgetpath\r\n")

-- Create test directory
local ec = gemdos.Dcreate("TESTDIR")
assert(ec == 0)

-- Set the path to the test directory
ec = gemdos.Dsetpath("TESTDIR")
assert(ec == 0)

-- Get the path
local path
ec, path = gemdos.Dgetpath(0)
assert(ec == 0)

-- Check the end of the path
assert(string.sub(path, -8, -1) == "\\TESTDIR")

-- Go back to the containing directory
ec = gemdos.Dsetpath("..")
assert(ec == 0)

-- Delete the test directory
ec = gemdos.Ddelete("TESTDIR")
assert(ec == 0)

-- Completed
gemdos.Cconws("Test gemdos.Dgetpath completed\r\n")
