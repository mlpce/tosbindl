-- Unittest for gemdos.Tgettime
gemdos.Cconws("Test gemdos.Tgettime\r\n")

local h, m, s = gemdos.Tgettime()
assert(h >= 0 and h <= 23)
assert(m >= 0 and m <= 59)
assert(s >= 0 and s <= 59)

gemdos.Cconws("Test gemdos.Tgettime completed\r\n")
