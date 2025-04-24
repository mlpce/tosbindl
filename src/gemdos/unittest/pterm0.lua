-- Test gemdos.Pterm0
gemdos.Cconws("Test gemdos.Pterm0\r\n")

local err = gemdos.Pexec0("lua.ttp", { "-e gemdos.Pterm0()" } )
assert(err == 0)

gemdos.Cconws("Test gemdos.Pterm0 completed\r\n")
