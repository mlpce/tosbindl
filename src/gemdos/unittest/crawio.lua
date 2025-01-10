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

-- Completed
gemdos.Cconws("Test gemdos.Crawio completed\r\n")
