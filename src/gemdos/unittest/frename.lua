-- Unittest for gemdos.Frename
gemdos.Cconws("Test gemdos.Frename\r\n")

-- Create test file
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- Rename it
local ec = gemdos.Frename("TESTFILE", "TESTFIL2")
assert(ec == 0)

local ec = fud:close()
assert(ec == 0)

local ec = gemdos.Fdelete("TESTFIL2")
assert(ec == 0)

-- Create test directory
local ec = gemdos.Dcreate("TESTDIR")
assert(ec == 0)

-- Rename it
local ec = gemdos.Frename("TESTDIR", "TESTDIR2")
assert(ec == 0)

-- Delete it
local ec = gemdos.Ddelete("TESTDIR2")
assert(ec == 0)

gemdos.Cconws("Test gemdos.Frename completed\r\n")
