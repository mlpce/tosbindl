-- Unittest for gemdos.Fdatime
gemdos.Cconws("Test gemdos.Fdatime\r\n")

-- Create test file
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)

-- Set the date and time
ec = gemdos.Fdatime(fud, 2000, 6, 20, 18, 20, 12)
assert(ec == 0)

-- Get the date and time
local year, month, day, hours, minutes, seconds
ec, year, month, day, hours, minutes, seconds = gemdos.Fdatime(fud)
assert(ec == 0, year)
assert(year == 2000 and month == 6 and day == 20 and
  hours == 18 and minutes == 20 and seconds == 12)

-- Close the file handle
ec = gemdos.Fclose(fud)
assert(ec == 0)

gemdos.Cconws("Test gemdos.Fdatime completed\r\n")
