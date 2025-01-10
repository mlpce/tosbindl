-- Test gemdos.Fforce
gemdos.Cconws("Test gemdos.Fforce\r\n")

-- Create output file
local ec, file_fud = gemdos.Fcreate("REDIRECT", gemdos.const.Fattrib.none)
assert(ec == 0, file_fud)
assert(file_fud:handle() >= 6)

-- Duplicate conout
local duplicate_conout_fud
ec, duplicate_conout_fud = gemdos.Fdup(gemdos.const.Fdup.conout)
assert(ec == 0, duplicate_conout_fud)

-- Force conout to file
local msg
ec, msg = gemdos.Fforce(file_fud, gemdos.const.Fdup.conout)
assert(ec, msg)

-- Pexec0 some output
ec, msg = gemdos.Pexec0("lua.ttp", { "-e print(\"HELLO\")" } )
assert(ec, msg)

-- Restore conout
ec, msg = gemdos.Fforce(duplicate_conout_fud, gemdos.const.Fdup.conout)
assert(ec, msg)

-- Close duplicate
ec, msg = gemdos.Fclose(duplicate_conout_fud)
assert(ec, msg)

-- Close output file
ec, msg = gemdos.Fclose(file_fud)
assert(ec, msg)

-- Open the output for checking
local check_fud
ec, check_fud = gemdos.Fopen("REDIRECT", gemdos.const.Fopen.readonly)

-- Read string
local str
ec, str = gemdos.Freads(check_fud, 100)
assert(ec == 7 and str == "HELLO\r\n", str)

-- Close
ec, msg = gemdos.Fclose(check_fud)
assert(ec == 0, msg)

gemdos.Cconws("Test gemdos.Fforce completed\r\n")
