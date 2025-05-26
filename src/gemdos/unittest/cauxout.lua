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

-- Force aux: to aux, as some runtime libraries use Gemdos handle 2 for stderr
local result, err = force_standard_handle.ForcedFileCall(
  gemdos.const.Fdup.aux,
  function()
    return gemdos.Fopen("aux:", gemdos.const.Fopen.writeonly)
  end,
  fn)
assert(result, err)

-- Completed
gemdos.Cconws("Test gemdos.Cauxout completed\r\n")
