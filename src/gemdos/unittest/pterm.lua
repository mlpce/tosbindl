-- Test gemdos.Pterm
gemdos.Cconws("Test gemdos.Pterm\r\n")

local err, msg = gemdos.Pexec0("\\lua.ttp", { "-e gemdos.Pterm(42)" } )
assert(err == 42, msg)

gemdos.Cconws("Test gemdos.Pterm completed\r\n")
