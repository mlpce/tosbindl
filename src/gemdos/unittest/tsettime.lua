-- Unittest for gemdos.Tsettime
gemdos.Cconws("Test gemdos.Tsettime\r\n")

---------------------------------------------------------------------
-- Set some valid times ---------------------------------------------
---------------------------------------------------------------------

-- Get the current time
local orig_h, orig_m, orig_s = gemdos.Tgettime()

-- Set the earliest time
local ec = gemdos.Tsettime(0, 0, 0)
assert(ec == 0)

-- Get the time and compare
local h, m, s = gemdos.Tgettime()
assert(h == 0)
assert(m == 0)
assert(s >= 0)

-- Set the (almost) latest time
ec = gemdos.Tsettime(23, 59, 50)
assert(ec == 0)

-- Get the time and compare
h, m, s = gemdos.Tgettime()
assert(h == 23, h)
assert(m == 59, m)
assert(s >= 50, s)

-- Set the original time back again
ec = gemdos.Tsettime(orig_h, orig_m, orig_s)
assert(ec == 0)

---------------------------------------------------------------------
-- Set some invalid time --------------------------------------------
---------------------------------------------------------------------

-- Some invalid time to set
local ok
ok = pcall(function() gemdos.Tsettime(24, 1, 1) end)
assert(not ok)
ok = pcall(function() gemdos.Tsettime(23, 60, 1) end)
assert(not ok)
ok = pcall(function() gemdos.Tsettime(23, 59, 60) end)
assert(not ok)
ok = pcall(function() gemdos.Tsettime(-1, 0, 0) end)
assert(not ok)
ok = pcall(function() gemdos.Tsettime(0, -1, 0) end)
assert(not ok)
ok = pcall(function() gemdos.Tsettime(0, 0, -1) end)
assert(not ok)

gemdos.Cconws("Test gemdos.Tsettime completed\r\n")
