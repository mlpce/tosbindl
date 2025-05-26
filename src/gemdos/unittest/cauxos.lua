local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cauxos
gemdos.Cconws("Test gemdos.Cauxos\r\n")

local fn = function()
  -- Make sure a character can be written when starting
  local available = gemdos.Cauxos()
  assert(available == true, "No room for character")

  -- Instructions
  -- Run this test with serial port set to 8N1 300 so buffer will fill
  gemdos.Cconws("This test requires serial set to 8N1 300\r\n")
  gemdos.Cconws("Press a key to abort\r\n")

  -- Loop until output buffer is full or a key is pressed to abort
  local status
  repeat
    gemdos.Cauxout(48)
    gemdos.Cauxout(13)
    gemdos.Cauxout(10)
    gemdos.Cauxout(49)
    gemdos.Cauxout(13)
    gemdos.Cauxout(10)
    status = gemdos.Cauxos()
  until status == false or gemdos.Cconis()

  -- Check output buffer was full
  assert(status == false, "The test was aborted\r\n")
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
gemdos.Cconws("Test gemdos.Cauxos completed\r\n")
