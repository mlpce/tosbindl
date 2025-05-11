local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cauxin
gemdos.Cconws("Test gemdos.Cauxin\r\n")

-- Instructions
gemdos.Cconws("Send the letter a from the remote\r\n")

local fn = function()
  -- Read the character from serial port
  local c = gemdos.Cauxin()
  -- Was the letter a received?
  assert(c == 97, "Wrong ASCII code: " .. c .. " expected 97")
end

-- Force aux: to aux, as some runtime libraries use Gemdos handle 2 for stderr
local result, err = force_standard_handle.ForcedFilenameCall(gemdos.const.Fdup.aux,
  "aux:", fn)
assert(result, err)

-- Completed
gemdos.Cconws("Test gemdos.Cauxin completed\r\n")
