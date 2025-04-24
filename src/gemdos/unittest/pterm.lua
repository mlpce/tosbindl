-- Test gemdos.Pterm
gemdos.Cconws("Test gemdos.Pterm\r\n")

local err = gemdos.Pexec0("lua.ttp", { "-e gemdos.Pterm(42)" } )
assert(err == 42)

gemdos.Cconws("Test gemdos.Pterm completed\r\n")
