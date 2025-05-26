local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cauxis
gemdos.Cconws("Test gemdos.Cauxis\r\n")

local fn = function()
  -- Make sure a character is not available when starting
  local available = gemdos.Cauxis()
  assert(available == false, "Character already available")

  -- Instructions
  gemdos.Cconws("Send the letter a from the remote\r\n")
  gemdos.Cconws("Press a key to abort\r\n")

  -- Loop until a character is received or a key is pressed to abort
  local status
  repeat
  status = gemdos.Cauxis()
  until status == true or gemdos.Cconis()

  -- Check that a character is ready
  assert(status == true, "The test was aborted\r\n")

  -- Read the character from aux
  local c = gemdos.Cauxin()

  -- Was the letter a received?
  assert(c == 97, "Wrong ASCII code: " .. c .. " expected 97")
end

-- Force aux: to aux, as some runtime libraries use Gemdos handle 2 for stderr
local result, err = force_standard_handle.ForcedFileCall(
  gemdos.const.Fdup.aux,
  function()
    return gemdos.Fopen("aux:", gemdos.const.Fopen.readonly)
  end,
  fn)
assert(result, err)

-- Completed
gemdos.Cconws("Test gemdos.Cauxis completed\r\n")
