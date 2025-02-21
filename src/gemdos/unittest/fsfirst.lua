-- Unittest for gemdos.Fsfirst
gemdos.Cconws("Test gemdos.Fsfirst\r\n")

-- make a directory
local ec = gemdos.Dcreate("TESTDIR")
assert(ec == 0)

-- Find the directory just created
local dta
ec, dta = gemdos.Fsfirst("TESTDIR", gemdos.const.Fattrib.dir);

-- Check name, attribytes and length
assert(ec == 0)
assert(dta:name() == "TESTDIR")
assert(dta:attr() & gemdos.const.Fattrib.dir)
assert(type(dta:length()) == "number")
-- Get the directory's timestamp
local year, month, day, hours, minutes, seconds = dta:datime()

-- Check the timestamp values are within range
assert(year >= 1980 and year <= 2099)
assert(month >= 1 and month <= 12)
assert(day >= 1 and day <= 31)
assert(hours >= 0 and hours <= 23)
assert(minutes >= 0 and minutes <= 59)
assert(seconds >= 0 and seconds <= 59)

-- In the test directory create a file with each attribute type apart from
-- dir and volume.
for k,v in pairs(gemdos.const.Fattrib) do
  if (k ~= "dir" and k ~= "volume") then
    -- Create test file with attribute
    local fud
    ec, fud = gemdos.Fcreate("TESTDIR\\TESTFILE", v)
    assert(ec == 0)
    fud:close()

    -- Find the test file just created
    ec, dta = gemdos.Fsfirst("TESTDIR\\TESTFILE", v);
    assert(ec == 0)
    assert(dta:name() == "TESTFILE")
    assert(dta:attr() & v)
    assert(dta:length() == 0)

    -- If the attribute is read only then deleting must fail
    if k == "readonly" then
      ec = gemdos.Fdelete("TESTDIR\\TESTFILE")
      assert(ec == gemdos.const.Error.EACCDN)

      -- remove the readonly attribute so it can be deleted later
      local flags = gemdos.Fattrib("TESTDIR\\TESTFILE", 1, 0);
      assert(flags == 0)
    end

    -- No more files in this directory
    ec = dta:snext()
    assert(ec == gemdos.const.Error.ENMFIL)

    -- Delete the test file
    ec = gemdos.Fdelete("TESTDIR\\TESTFILE")
    assert(ec == 0)
  end
end

-- Delete the test directory
ec = gemdos.Ddelete("TESTDIR")
assert(ec == 0)

gemdos.Cconws("Test gemdos.Fsfirst completed\r\n")
