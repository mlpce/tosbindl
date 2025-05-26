local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cconout
gemdos.Cconws("Test gemdos.Cconout\r\n")

-- The message to output
local str = "hello"

-- Instructions
gemdos.Cconws("Observe the message \"" .. str .. "\"\r\n")

-- Output the string using Cconout
for i=1,#str do
  gemdos.Cconout(str:byte(i))
end

gemdos.Cconws("\r\n")

-- The message to send
local redirect_str = "goodbye"

-- Instructions
gemdos.Cconws("Observe the message \"" .. redirect_str .. "\" in \"conoutfc.txt\"\r\n")

-- Test redirection of conout to output file
local fn = function()
  -- Send the message
  for i=1,#redirect_str do
    gemdos.Cconout(redirect_str:byte(i))
  end
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
gemdos.Cconws("\r\nTest gemdos.Cconout completed\r\n")
