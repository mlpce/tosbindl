-- Test gemdos.Fforce
gemdos.Cconws("Test gemdos.Fforce\r\n")

-- TODO(mlpce): Investigate ENHNDL when looping unittest\fforce.lua
-- If this test is repeated in a loop, eventually it will fail with ENHNDL.
-- This is the case with both EmuTOS 1.3 and TOS 1.04 (in TOS 1.04 you will
-- likely need FOLDR100.PRG otherwise the system will run out of resources
-- before ENHDNL can be generated).
-- If the file_fud:handle() is printed out it can be seen that the handle
-- is increasing each time the test is run.

-- Create output file
local ec, file_fud = gemdos.Fcreate("REDIRECT", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(file_fud:handle() >= 6)
gemdos.Cconws("file_fud:handle() " .. file_fud:handle() .. "\r\n")

-- Duplicate conout
local duplicate_conout_fud
ec, duplicate_conout_fud = gemdos.Fdup(gemdos.const.Fdup.conout)
assert(ec == 0)

-- Force conout to file
ec = gemdos.Fforce(file_fud, gemdos.const.Fdup.conout)
assert(ec == 0)

-- Pexec0 some output
ec = gemdos.Pexec0("lua.ttp", { "-e print(\"HELLO\")" } )
assert(ec == 0)

-- Restore conout
ec = gemdos.Fforce(duplicate_conout_fud, gemdos.const.Fdup.conout)
assert(ec == 0)

-- Close duplicate
ec = gemdos.Fclose(duplicate_conout_fud)
assert(ec == 0)

-- NOTE(mlpce): Close output file fails with EINTRN after a Pexec0. If
-- the call to Pexec0 is removed then this close will succeed. However
-- looping the test (with the output check below disabled) will still
-- eventually fail with ENHNDL.
ec = gemdos.Fclose(file_fud)
assert(ec == gemdos.const.Error.EINTRN)

-- Open the output for checking
local check_fud
ec, check_fud = gemdos.Fopen("REDIRECT", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Read string
local str
ec, str = gemdos.Freads(check_fud, 100)
assert(ec == 7 and str == "HELLO\r\n")

-- Close
ec = gemdos.Fclose(check_fud)
assert(ec == 0)

gemdos.Cconws("Test gemdos.Fforce completed\r\n")
