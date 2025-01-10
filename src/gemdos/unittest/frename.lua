-- Unittest for gemdos.Frename
gemdos.Cconws("Test gemdos.Frename\r\n")

-- Create test file
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)

-- Rename it
local ec, msg = gemdos.Frename("TESTFILE", "TESTFIL2")
assert(ec == 0, msg)

local ec, msg = fud:close()
assert(ec == 0, msg)

local ec, msg = gemdos.Fdelete("TESTFIL2")
assert(ec == 0, msg)

-- Create test directory
local ec, msg = gemdos.Dcreate("TESTDIR")
assert(ec == 0, msg)

-- Rename it
local ec, msg = gemdos.Frename("TESTDIR", "TESTDIR2")
assert(ec == 0, msg)

-- Delete it
local ec, msg = gemdos.Ddelete("TESTDIR2")
assert(ec == 0, msg)

gemdos.Cconws("Test gemdos.Frename completed\r\n")
