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

    if v == gemdos.const.Fattrib.readonly then
      -- remove the readonly attribute so it can be deleted later
      local flags
      flags, msg = gemdos.Fattrib("TESTDIR\\" .. dta:name(), 1, 0)
      assert(flags == 0, msg)
    end

    -- Get the next one
    ec, msg = gemdos.Fsnext(dta)
    assert(ec == 0, msg)
    assert(dta:attr() & v)

    if v == gemdos.const.Fattrib.readonly then
      -- remove the readonly attribute so it can be deleted later
      local flags
      flags, msg = gemdos.Fattrib("TESTDIR\\" .. dta:name(), 1, 0)
      assert(flags == 0, msg)
    end

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

while ec == 0 do
  ec, msg = gemdos.Fdelete("TESTDIR\\" .. dta:name())
  assert(ec == 0, msg)
  ec, msg = dta:snext()
end
assert(ec == gemdos.const.Error.ENMFIL, msg)

-- Create two subdirectory in TESTDIR
ec, msg = gemdos.Dcreate("TESTDIR\\one")
ec, msg = gemdos.Dcreate("TESTDIR\\two")

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
  ec, msg = dta:snext()
end
assert(ec == gemdos.const.Error.ENMFIL, msg)

assert(found_count == 4)
assert(found["."])
assert(found[".."])
assert(found["ONE"])
assert(found["TWO"])

-- Now delete the directories that were created in TESTDIR
ec, msg = gemdos.Ddelete("TESTDIR\\ONE")
ec, msg = gemdos.Ddelete("TESTDIR\\TWO")

-- Finally delete TESTDIR
ec, msg = gemdos.Ddelete("TESTDIR")
assert(ec == 0, msg)

gemdos.Cconws("Test gemdos.Fsnext completed\r\n")
