-- Unittest for gemdos.Dfree
gemdos.Cconws("Test gemdos.Dfree\r\n")

-- Pass zero for current drive
local fc, tc, ss, cs = gemdos.Dfree(0)
assert(fc <= tc)
assert(ss == 512)
assert(cs == 2)

-- This time using default drive
local fc2, tc2, ss2, cs2 = gemdos.Dfree(gemdos.Dgetdrv() + 1)
assert(fc == fc2 and tc == tc2 and ss == ss2 and cs == cs2)

-- Completed
gemdos.Cconws("Test gemdos.Dfree completed\r\n")
