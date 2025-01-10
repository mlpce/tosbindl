-- Unittest for gemdos.Fsnext
gemdos.Cconws("Test gemdos.Fsnext\r\n")

-- make a directory
local ec, msg = gemdos.Dcreate("TESTDIR")
assert(ec, msg)

-- Create two files with each attribute in the new directory
for count = 1,2 do
  for k,v in pairs(gemdos.const.Fattrib) do
    if (k ~= "dir" and k ~= "volume") then
      -- Create test file with attribute
      local fud
      ec, fud = gemdos.Fcreate("TESTDIR\\" .. v .. "_" .. count, v)
      assert(ec == 0, fud)
      fud:close()
    end
  end
end

-- Check Fsnext can find the next file with the attribute
for k,v in pairs(gemdos.const.Fattrib) do
  if (k ~= "dir" and k ~= "volume") then
    local dta
    ec, dta = gemdos.Fsfirst("TESTDIR\\" .. v .. "_*", v)
    assert(ec == 0, dta)
    assert(dta:attr() & v)

    -- Get the next one
    ec, msg = gemdos.Fsnext(dta)
    assert(ec == 0, msg)
    assert(dta:attr() & v)

    -- There isn't another one
    ec, msg = gemdos.Fsnext(dta)
    assert(ec == gemdos.const.Error.ENMFIL, msg)
  end
end

-- Now delete the files that were created in TESTDIR
local dta
ec, dta = gemdos.Fsfirst("TESTDIR\\*",
  gemdos.const.Fattrib.readonly |
  gemdos.const.Fattrib.hidden |
  gemdos.const.Fattrib.system |
  gemdos.const.Fattrib.archive)
assert(ec == 0, dta)

repeat
  ec, msg = gemdos.Fdelete("TESTDIR\\" .. dta:name())
  ec, msg = dta:snext()
until ec < 0
assert(ec == gemdos.const.Error.ENMFIL, msg)

-- Create two subdirectory in TESTDIR
ec, msg = gemdos.Dcreate("TESTDIR\\one")
ec, msg = gemdos.Dcreate("TESTDIR\\two")

-- Check search finds both directories

-- one
ec, dta = gemdos.Fsfirst("TESTDIR\\*", gemdos.const.Fattrib.dir)
assert(ec == 0, dta)
assert(dta:attr() & gemdos.const.Fattrib.dir)

-- two
ec, msg = gemdos.Fsnext(dta)
assert(ec == 0, msg)
assert(dta:attr() & gemdos.const.Fattrib.dir)

-- No more
ec, msg = gemdos.Fsnext(dta)
assert(ec == gemdos.const.Error.ENMFIL, msg)

-- Now delete the directories that were created in TESTDIR
local ec, dta = gemdos.Fsfirst("TESTDIR\\*", gemdos.const.Fattrib.dir)
assert(ec == 0, dta)

repeat
  ec, msg = gemdos.Ddelete("TESTDIR\\" .. dta:name())
  ec, msg = gemdos.Fsnext(dta)
until ec < 0
assert(ec == gemdos.const.Error.ENMFIL, msg)

-- Finally delete TESTDIR
ec, msg = gemdos.Ddelete("TESTDIR")
assert(ec == 0, msg)

gemdos.Cconws("Test gemdos.Fsnext completed\r\n")
