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

-- Completed
gemdos.Cconws("Test gemdos.Cconin completed\r\n")
