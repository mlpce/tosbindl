-- Test gemdos.Cprnos
gemdos.Cconws("Test gemdos.Cprnos\r\n")

-- Make sure a character can be written when starting
local available = gemdos.Cprnos()
assert(available == true, "No room for character")

-- Instructions
gemdos.Cconws("Waiting for no room for character\r\n")
gemdos.Cconws("Press a key to abort\r\n")

-- Loop until output buffer is full or a key is pressed to abort
local status
repeat
status = gemdos.Cprnos()
gemdos.Cprnout(48)
until status == false or gemdos.Cconis()

-- Check output buffer was full
assert(status == false, "The test was aborted\r\n")

-- Completed
gemdos.Cconws("Test gemdos.Cprnos completed\r\n")
