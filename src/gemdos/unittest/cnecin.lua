-- Unittest for gemdos.Cnecin
gemdos.Cconws("Test gemdos.Cnecin\r\n")

-- Set conterm to produce shift key states
gemdos.SuperPoke("conterm", gemdos.SuperPeek("conterm") | 8)

-- Instruction
gemdos.Cconws("Press a\r\n");

-- Get the input
local ascii,scan_code,shift = gemdos.Cnecin()

-- Check result
assert(ascii == 97, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 0, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press ctrl + a\r\n");

-- Get the input
ascii,scan_code,shift = gemdos.Cnecin()

-- Check result
assert(ascii == 1, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 4, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press left shift + a\r\n");

-- Get the input
ascii,scan_code,shift = gemdos.Cnecin()

-- Check result
assert(ascii == 65, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 2, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press right shift + a\r\n");

-- Get the input
ascii,scan_code,shift = gemdos.Cnecin()

-- Check result
assert(ascii == 65, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 1, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Instruction
gemdos.Cconws("Press alt + a\r\n");

-- Check result
ascii,scan_code,shift = gemdos.Cnecin()
assert(ascii == 0, "Wrong ascii code: " .. ascii)
assert(scan_code == 30, "Wrong scan code: " .. scan_code)
assert(shift == 8, "Wrong shift: " .. shift)
gemdos.Cconws("\r\n");

-- Completed
gemdos.Cconws("Test gemdos.Cnecin completed\r\n")
