-- Test gemdos.Sversion
gemdos.Cconws("Test gemdos.Sversion\r\n")

local major, minor = gemdos.Sversion()

assert(major == 0)
assert(minor >= 19)

gemdos.Cconws("Test gemdos.Sversion completed\r\n")
