local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cauxout
gemdos.Cconws("Test gemdos.Cauxout\r\n")

local fn = function()
  -- The message to send
  local str = "hello"

  -- Instructions
  gemdos.Cconws("Observe the message \"" .. str .. "\" on the remote\r\n")

  -- Send the message to the remote
  for i=1,#str do
    gemdos.Cauxout(str:byte(i))
  end
end

local result, err = force_standard_handle.ForcedFilenameCall(gemdos.const.Fdup.aux,
  "aux:", fn)
assert(result, err)

-- Completed
gemdos.Cconws("Test gemdos.Cauxout completed\r\n")
