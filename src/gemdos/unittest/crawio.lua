local force_standard_handle = require("fcestdhd")

-- Unittest for gemdos.Crawcio
gemdos.Cconws("Test gemdos.Crawio\r\n")

-- Set conterm to produce shift key states
gemdos.SuperPoke("conterm", gemdos.SuperPeek("conterm") | 8)

-- The message to output
local str = "hello"

-- Instructions
gemdos.Cconws("Observe the message \"" .. str .. "\"\r\n")

for i=1,#str do
    gemdos.Crawio(str:byte(i))
end

-- Instruction
gemdos.Cconws("\r\nPress a\r\n")

-- Get the input
local ascii,scan_code,shift
repeat
  ascii, scan_code, shift = gemdos.Crawio(255)
until ascii ~= 0

-- Check result
assert(ascii == 97, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 0, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press ctrl + a\r\n");

-- Get the input
repeat
  ascii, scan_code, shift = gemdos.Crawio(255)
until ascii ~= 0

-- Check result
assert(ascii == 1, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 4, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press left shift + a\r\n");

-- Get the input
repeat
  ascii, scan_code, shift = gemdos.Crawio(255)
until ascii ~= 0

-- Check result
assert(ascii == 65, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 2, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press right shift + a\r\n");

-- Get the input
repeat
  ascii, scan_code, shift = gemdos.Crawio(255)
until ascii ~= 0

-- Check result
assert(ascii == 65, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 1, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press alt + a\r\n");

-- Get the input
repeat
  ascii, scan_code, shift = gemdos.Crawio(255)
until scan_code ~= 0

-- Check result
assert(ascii == 0, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 8, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- TODO(mlpce): The tests for redirection with Crawio are disabled
if false then
  -- Check with a file forced to conin.
  gemdos.Cconws("Check file forced to conin\r\n")

  local input_fn = function()
    local ascii, scancode, shift = gemdos.Crawio(255)
    assert(ascii == 48)
    assert(scancode == 0)
    assert(shift == 0)

    ascii, scancode, shift = gemdos.Crawio(255)
    assert(ascii == 49)
    assert(scancode == 0)
    assert(shift == 0)

    ascii, scancode, shift = gemdos.Crawio(255)
    assert(ascii == 50)
    assert(scancode == 0)
    assert(shift == 0)
  end

  -- Write 012 to coninfce.txt
  local ec, fud_in <close> = gemdos.Fcreate("coninfce.txt", gemdos.const.Fattrib.none)
  gemdos.Cconws("fud_in handle " .. fud_in:handle() .. "\r\n")
  assert(ec == 0)

  ec = fud_in:writes("012")
  assert(ec == 3)

  ec = fud_in:close()
  assert(ec == 0)

  -- Force coninfce.txt to conin and call fn
  local result, err = force_standard_handle.ForcedFilenameCall(gemdos.const.Fdup.conin,
    "coninfce.txt", input_fn)
  assert(result, err)

  -- Delete coninfce.txt
  gemdos.Fdelete("coninfce.txt")

  -- Check with a file forced to conout. It does not work.
  gemdos.Cconws("Check file forced to conout\r\n")

  local output_fn = function()
    gemdos.Crawio(48)
    gemdos.Crawio(49)
    gemdos.Crawio(50)
  end

  -- Write 012 to coninfce.txt
  local ec, fud_out <close> = gemdos.Fcreate("conoutfc.txt", gemdos.const.Fattrib.none)
  gemdos.Cconws("fud_out handle " .. fud_out:handle() .. "\r\n")
  assert(ec == 0)

  -- Force coninfce.txt to conin and call fn
  local result, err = force_standard_handle.ForcedFilenameCall(gemdos.const.Fdup.conout,
    "conoutfc.txt", output_fn)
  assert(result, err)

  -- Check contents of the file
  local read_ec, read_str = fud_out:reads(100)
  assert(read_ec == 3)
  assert(read_str == "012")

  ec = fud_out:close()
  assert(ec == 0)

  -- Delete conoutfc.txt
  gemdos.Fdelete("conoutfc.txt")
end

-- Completed
gemdos.Cconws("Test gemdos.Crawio completed\r\n")
