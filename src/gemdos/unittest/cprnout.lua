local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cprnout
gemdos.Cconws("Test gemdos.Cprnout\r\n")

-- The message to send
local str = "hello"

-- Instructions
gemdos.Cconws("Observe the message \"" .. str .. "\" on the printer\r\n")

-- Send the message to the printer
for i=1,#str do
  gemdos.Cprnout(str:byte(i))
end

-- The message to send
local redirect_str = "goodbye"

-- Test redirection of prn to output file
local fn = function()
  -- Instructions
  gemdos.Cconws("Observe the message \"" .. redirect_str .. "\" in \"prnoutfc.txt\"\r\n")

  -- Send the message
  for i=1,#redirect_str do
    gemdos.Cprnout(redirect_str:byte(i))
  end
end

-- Force prn to the file and call fn
local result, err = force_standard_handle.ForcedFileCall(
  gemdos.const.Fdup.prn,
  function()
    return gemdos.Fcreate("prnoutfc.txt", gemdos.const.Fattrib.none)
  end,
  fn)
assert(result, err)

-- Open output file
local ec, fud <close> = gemdos.Fopen("prnoutfc.txt",
  gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Check contents of the file
local read_ec, read_str = fud:reads(100)
assert(read_ec == #redirect_str)
assert(read_str == redirect_str)
fud:close()

-- Delete prnoutfc.txt
gemdos.Fdelete("prnoutfc.txt")

-- Completed
gemdos.Cconws("Test gemdos.Cprnout completed\r\n")
