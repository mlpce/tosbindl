-- Unittest for gemdos.Tsetdate
gemdos.Cconws("Test gemdos.Tsetdate\r\n")

---------------------------------------------------------------------
-- Set some valid dates ---------------------------------------------
---------------------------------------------------------------------

-- Get the current date
local orig_y, orig_m, orig_d = gemdos.Tgetdate()

-- Set the earliest date
local ec, msg = gemdos.Tsetdate(1980, 1, 1)
assert(ec == 0, msg)

-- Get the date and compare
local y, m, d = gemdos.Tgetdate()
assert(y == 1980 and m == 1 and d == 1)

-- Set the (almost) latest date
ec, msg = gemdos.Tsetdate(2099, 12, 30)
assert(ec == 0, msg)

-- Get the date and compare
y, m, d = gemdos.Tgetdate()
assert(y == 2099 and m == 12 and d == 30)

-- Set the original date back again
ec, msg = gemdos.Tsetdate(orig_y, orig_m, orig_d)
assert(ec == 0, msg)

---------------------------------------------------------------------
-- Set some invalid dates -------------------------------------------
---------------------------------------------------------------------

-- Some invalid dates to set
local ok
ok, msg = pcall(function() gemdos.Tsetdate(2100, 1, 1) end)
assert(not ok)
ok, msg = pcall(function() gemdos.Tsetdate(1979, 12, 31) end)
assert(not ok)
ok, msg = pcall(function() gemdos.Tsetdate(2024, 11, 32) end)
assert(not ok)
ok, msg = pcall(function() gemdos.Tsetdate(2024, 11, 0) end)
assert(not ok)
ok, msg = pcall(function() gemdos.Tsetdate(2024, 13, 1) end)
assert(not ok)
ok, msg = pcall(function() gemdos.Tsetdate(2024, 0, 1) end)
assert(not ok)

gemdos.Cconws("Test gemdos.Tsetdate completed\r\n")
