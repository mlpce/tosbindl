-- Unittest for gemdos.Fsnext
gemdos.Cconws("Test gemdos.Fsnext\r\n")

-- make a directory
local ec = gemdos.Dcreate("TESTDIR")
assert(ec == 0, msg)

-- Create two files with each attribute in the new directory
for count = 1,2 do
  for k,v in pairs(gemdos.const.Fattrib) do
    if (k ~= "dir" and k ~= "volume") then
      -- Create test file with attribute
      local fud
      ec, fud = gemdos.Fcreate("TESTDIR\\" .. v .. "_" .. count, v)
      assert(ec == 0)
      fud:close()
    end
  end
end

-- Check Fsnext can find the next file with the attribute
for k,v in pairs(gemdos.const.Fattrib) do
  if (k ~= "dir" and k ~= "volume") then
    local dta
    ec, dta = gemdos.Fsfirst("TESTDIR\\" .. v .. "_*", v)
    assert(ec == 0)
    assert(dta:attr() & v)

    if v == gemdos.const.Fattrib.readonly then
      -- remove the readonly attribute so it can be deleted later
      local flags = gemdos.Fattrib("TESTDIR\\" .. dta:name(), 1, 0)
      assert(flags == 0)
    end

    -- Get the next one
    ec = gemdos.Fsnext(dta)
    assert(ec == 0)
    assert(dta:attr() & v)

    if v == gemdos.const.Fattrib.readonly then
      -- remove the readonly attribute so it can be deleted later
      local flags = gemdos.Fattrib("TESTDIR\\" .. dta:name(), 1, 0)
      assert(flags == 0)
    end

    -- There isn't another one
    ec = gemdos.Fsnext(dta)
    assert(ec == gemdos.const.Error.ENMFIL)
  end
end

-- Now delete the files that were created in TESTDIR
local dta
ec, dta = gemdos.Fsfirst("TESTDIR\\*",
  gemdos.const.Fattrib.readonly |
  gemdos.const.Fattrib.hidden |
  gemdos.const.Fattrib.system |
  gemdos.const.Fattrib.archive)
assert(ec == 0)

while ec == 0 do
  ec = gemdos.Fdelete("TESTDIR\\" .. dta:name())
  assert(ec == 0)
  ec = dta:snext()
end
assert(ec == gemdos.const.Error.ENMFIL)

-- Create two subdirectory in TESTDIR
ec = gemdos.Dcreate("TESTDIR\\one")
assert(ec == 0)
ec = gemdos.Dcreate("TESTDIR\\two")
assert(ec == 0)

-- Check search finds both directories
-- It will also find '.' and '..' so check for those too
local found = { }
local found_count = 0
-- one
ec, dta = gemdos.Fsfirst("TESTDIR\\*", gemdos.const.Fattrib.dir)
assert(ec == 0, dta)
while ec == 0 do
  assert(dta:attr() & gemdos.const.Fattrib.dir)
  found[dta:name()] = true
  found_count = found_count + 1
  ec = dta:snext()
end
assert(ec == gemdos.const.Error.ENMFIL)

assert(found_count == 4)
assert(found["."])
assert(found[".."])
assert(found["ONE"])
assert(found["TWO"])

-- Now delete the directories that were created in TESTDIR
ec = gemdos.Ddelete("TESTDIR\\ONE")
assert(ec == 0)
ec = gemdos.Ddelete("TESTDIR\\TWO")
assert(ec == 0)

-- Finally delete TESTDIR
ec = gemdos.Ddelete("TESTDIR")
assert(ec == 0)

gemdos.Cconws("Test gemdos.Fsnext completed\r\n")
