-- Test gemdos.Cauxos
gemdos.Cconws("Test gemdos.Cauxos\r\n")

-- Make sure a character can be written when starting
local available = gemdos.Cauxos()
assert(available == true, "No room for character")

-- Instructions
gemdos.Cconws("Instruct the remote to signal XOFF\r\n")
gemdos.Cconws("Press a key to abort\r\n")

-- Loop until output buffer is full or a key is pressed to abort
local status
repeat
status = gemdos.Cauxos()
gemdos.Cauxout(48)
until status == false or gemdos.Cconis()

-- Check output buffer was full
assert(status == false, "The test was aborted\r\n")

-- Completed
gemdos.Cconws("Test gemdos.Cauxos completed\r\n")
