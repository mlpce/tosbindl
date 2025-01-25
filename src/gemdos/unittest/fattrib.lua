-- Unittest for gemdos.Fattrib
gemdos.Cconws("Test gemdos.Fattrib\r\n")

-- Note: these tests expect writable floppy disc to be inserted in drive A:

-- Create a new file named TESTFILE
-- No attributes set
local ec, fud = gemdos.Fcreate("A:\\TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0, fud)
assert(fud:handle() >= 6)
local msg
ec, msg = fud:close()
assert(ec == 0, msg)

-- Archive bit set on newly created file
local attrib
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.archive, msg)

---------------------------------------------------------------------
-- Readonly attribute -----------------------------------------------
---------------------------------------------------------------------

-- Set attribute readonly
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.readonly)
assert(attrib == gemdos.const.Fattrib.readonly, msg)

-- Check attribute readonly is set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.readonly, msg)

-- Remove attribute readonly
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.none)
assert(attrib == gemdos.const.Fattrib.none, msg)

-- Check no attributes set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.none, msg)

---------------------------------------------------------------------
-- Hidden attribute -------------------------------------------------
---------------------------------------------------------------------

-- Set attribute hidden
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.hidden)
assert(attrib == gemdos.const.Fattrib.hidden, msg)

-- Check attribute hidden is set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.hidden, msg)

-- Remove attribute hidden
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.none)
assert(attrib == gemdos.const.Fattrib.none, msg)

-- Check no attributes set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.none, msg)

---------------------------------------------------------------------
-- System attribute -------------------------------------------------
---------------------------------------------------------------------

-- Set attribute system
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.system)
assert(attrib == gemdos.const.Fattrib.system, msg)

-- Check attribute system is set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.system, msg)

-- Remove attribute system
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.none)
assert(attrib == gemdos.const.Fattrib.none, msg)

-- Check no attributes set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.none, msg)

---------------------------------------------------------------------
-- Volume attribute -------------------------------------------------
---------------------------------------------------------------------

-- See rainbow tos release notes regarding volume label.
-- Test here expects rainbow tos behaviour

-- Setting volume attribute with Fattrib must fail
local ok
ok, msg = pcall(function() gemdos.Fattrib("A:\\TESTFILE", 1,
  gemdos.const.Fattrib.volume) end),
assert(not ok)

-- Find the existing volume file if there is one (there can be only one)
local dta
ec, dta = gemdos.Fsfirst("A:\\*.*", gemdos.const.Fattrib.volume);
assert(ec == 0 or ec == gemdos.const.Error.EFILNF, dta)
local orig_volume_name
if ec == 0 then
  orig_volume_name = dta:name()

  -- There must not be a next one
  ec, msg = gemdos.Fsnext(dta)
  assert(ec == gemdos.const.Error.ENMFIL, msg)
end

-- Create new volume label
ec, fud = gemdos.Fcreate("A:\\TESTVOLU", gemdos.const.Fattrib.volume)
fud:close()

-- Find the volume label
ec, dta = gemdos.Fsfirst("A:\\*.*", gemdos.const.Fattrib.volume);
assert(ec == 0, dta)
assert(dta:name() == "TESTVOLU")

-- There must not be a next one
ec, msg = gemdos.Fsnext(dta)
assert(ec == gemdos.const.Error.ENMFIL, msg)

-- Restore the original volume label if there was one
if orig_volume_name then
  ec, fud = gemdos.Fcreate("A:\\" .. orig_volume_name,
    gemdos.const.Fattrib.volume)
  assert(ec == 0, fud)
  fud:close()

  -- Check the volume label matches the original volume label
  ec, dta = gemdos.Fsfirst("A:\\*.*", gemdos.const.Fattrib.volume);
  assert(ec == 0, dta)
  assert(dta:name() == orig_volume_name)

  -- There must not be a next one
  ec, msg = gemdos.Fsnext(dta)
  assert(ec == gemdos.const.Error.ENMFIL, msg)
end

---------------------------------------------------------------------
-- Dir attribute ----------------------------------------------------
---------------------------------------------------------------------

-- Setting directory attribute with Fattrib must fail
ok, msg = pcall(function() gemdos.Fattrib("A:\\TESTFILE", 1,
  gemdos.const.Fattrib.dir) end),
assert(not ok)

---------------------------------------------------------------------
-- Archive attribute ------------------------------------------------
---------------------------------------------------------------------

-- Set attribute archive
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.archive)
assert(attrib == gemdos.const.Fattrib.archive, msg)

-- Check attribute archive is set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.archive, msg)

-- Remove attribute archive
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 1, gemdos.const.Fattrib.none)
assert(attrib == gemdos.const.Fattrib.none, msg)

-- Check no attributes set
attrib, msg = gemdos.Fattrib("A:\\TESTFILE", 0, 0);
assert(attrib == gemdos.const.Fattrib.none, msg)

-- Completed
gemdos.Cconws("Test gemdos.Fattrib completed\r\n")
