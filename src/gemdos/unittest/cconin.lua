local force_standard_handle = require("fcestdhd")

-- Test gemdos.Cconin
gemdos.Cconws("Test gemdos.Cconin\r\n")

-- Set conterm to produce shift key states
gemdos.SuperPoke("conterm", gemdos.SuperPeek("conterm") | 8)

-- Instruction
gemdos.Cconws("Press a\r\n");

-- Get the input
local ascii,scan_code,shift = gemdos.Cconin()

-- Check result
assert(ascii == 97, "Wrong ascii code: " .. ascii .. " expected 97")
assert(scan_code == 30, "Wrong scan code: " .. scan_code .. " expected 30")
assert(shift == 0, "Wrong shift: " .. shift .. " expected 0")
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press ctrl + a\r\n");

-- Get the input
ascii,scan_code,shift = gemdos.Cconin()

-- Check result
assert(ascii == 1, "Wrong ascii code: " .. ascii .. " expected 1")
assert(scan_code == 30, "Wrong scan code: " .. scan_code .. " expected 30")
assert(shift == 4, "Wrong shift: " .. shift .. " expected 4")
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press left shift + a\r\n");

-- Get the input
ascii,scan_code,shift = gemdos.Cconin()

-- Check result
assert(ascii == 65, "Wrong ascii code: " .. ascii .. " expected 65")
assert(scan_code == 30, "Wrong scan code: " .. scan_code .. " expected 30")
assert(shift == 2, "Wrong shift: " .. shift .. " expected 2")
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press right shift + a\r\n");

-- Get the input
ascii,scan_code,shift = gemdos.Cconin()

-- Check result
assert(ascii == 65, "Wrong ascii code: " .. ascii .. " expected 65")
assert(scan_code == 30, "Wrong scan code: " .. scan_code .. " expected 30")
assert(shift == 1, "Wrong shift: " .. shift .. " expected 1")
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press alt + a\r\n");

-- Get the input
ascii,scan_code,shift = gemdos.Cconin()

-- Check result
assert(ascii == 0, "Wrong ascii code: " .. ascii .. " expected 0")
assert(scan_code == 30, "Wrong scan code: " .. scan_code .. " expected 30")
assert(shift == 8, "Wrong shift: " .. shift .. " expected 8")
gemdos.Cconws("\r\n");

-- Check with a file forced to conin
gemdos.Cconws("Check file forced to conin\r\n")

local fn = function()
  local ascii, scancode, shift = gemdos.Cconin()

  -- First character read must be '0'
  assert(ascii == 48, "Wrong ASCII code: " .. ascii .. " expected 48")

  -- scancode and shift must be zero
  assert(scancode == 0)
  assert(shift == 0)

  ascii, scancode, shift = gemdos.Cconin()

  -- Second character read must be '0'
  assert(ascii == 49, "Wrong ASCII code: " .. ascii .. " expected 49")

  -- scancode and shift must be zero
  assert(scancode == 0)
  assert(shift == 0)

  ascii, scancode, shift = gemdos.Cconin()

  -- Third character read must be '0'
  assert(ascii == 50, "Wrong ASCII code: " .. ascii .. " expected 50")

  -- scancode and shift must be zero
  assert(scancode == 0)
  assert(shift == 0)
end

-- Write 012 to coninfce.txt
local ec, fud <close> = gemdos.Fcreate("coninfce.txt", gemdos.const.Fattrib.none)
assert(ec == 0)

ec = fud:writes("012")
assert(ec == 3)

ec = fud:close()
assert(ec == 0)

-- Force coninfce.txt to conin and call fn
local result, err = force_standard_handle.ForcedFilenameCall(gemdos.const.Fdup.conin,
  "coninfce.txt", fn)
assert(result, err)

-- Delete coninfce.txt
gemdos.Fdelete("coninfce.txt")

-- Completed
gemdos.Cconws("Test gemdos.Cconin completed\r\n")
