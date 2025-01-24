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
local orig_ec, orig_dta = gemdos.Fsfirst("A:\\*.*", gemdos.const.Fattrib.volume);
assert(orig_ec == 0 or orig_ec == gemdos.const.Error.EFILNF, orig_dta)

-- Create new volume label
ec, fud = gemdos.Fcreate("A:\\TESTVOLU", gemdos.const.Fattrib.volume)
fud:close()

-- Find the volume label
local test_dta
ec, test_dta = gemdos.Fsfirst("A:\\*.*", gemdos.const.Fattrib.volume);
assert(ec == 0, test_dta)
assert(test_dta:name() == "TESTVOLU")

-- Restore the original volume label if there was one
if orig_ec == 0 then
  ec, fud = gemdos.Fcreate("A:\\" .. orig_dta:name(),
    gemdos.const.Fattrib.volume)
  assert(ec == 0, fud)
  fud:close()

  -- Check the volume label matches the original volume label
  ec, test_dta = gemdos.Fsfirst("A:\\*.*", gemdos.const.Fattrib.volume);
  assert(ec == 0, test_dta)
  assert(test_dta:name() == orig_dta:name())
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
