-- Test gemdos.Cconis
gemdos.Cconws("Test gemdos.Cconis\r\n")

-- Make sure a character is not available when starting
local available = gemdos.Cconis()
assert(available == false, "Character already available")

-- Instructions
gemdos.Cconws("Press a key\r\n")

-- Loop until a character is ready
local status
repeat
status = gemdos.Cconis()
until status == true

-- Check that a character is ready
assert(status == true, "A character was not ready\r\n")

-- Completed
gemdos.Cconws("Test gemdos.Cconis completed\r\n")
