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

-- Create output file
local ec, fud <close> = gemdos.Fcreate("conoutfc.txt", gemdos.const.Fattrib.none)
gemdos.Cconws("fud handle " .. fud:handle() .. "\r\n")
assert(ec == 0)

-- Force conout to the file and call fn
local result, err = force_standard_handle.ForcedFilenameCall(gemdos.const.Fdup.conout,
  "conoutfc.txt", fn)
assert(result, err)

-- Check contents of the file
local read_ec, read_str = fud:reads(100)
assert(read_ec == #redirect_str)
assert(read_str == redirect_str)
fud:close()

-- Completed
gemdos.Cconws("Test gemdos.Cconws completed\r\n");
