local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cconws
gemdos.Cconws("Test gemdos.Cconws\r\n");

-- The message to send
local redirect_str = "hello"

-- Instructions
gemdos.Cconws("Observe the message \"" .. redirect_str .. "\" in \"conoutfc.txt\"\r\n")

-- Test redirection of conout to output file
local fn = function()
  -- Send the message
  gemdos.Cconws(redirect_str)
end

-- Force conout to the file and call fn
local result, err = force_standard_handle.ForcedFileCall(
  gemdos.const.Fdup.conout,
  function()
    return gemdos.Fcreate("conoutfc.txt", gemdos.const.Fattrib.none)
  end,
  fn)
assert(result, err)

-- Open output file
local ec, fud <close> = gemdos.Fopen("conoutfc.txt",
  gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Check contents of the file
local read_ec, read_str = fud:reads(100)
assert(read_ec == #redirect_str)
assert(read_str == redirect_str)
fud:close()

-- Delete conoutfc.txt
gemdos.Fdelete("conoutfc.txt")

-- Completed
gemdos.Cconws("Test gemdos.Cconws completed\r\n");
