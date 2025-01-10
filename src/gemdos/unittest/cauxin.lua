-- Test gemdos.Cauxin
gemdos.Cconws("Test gemdos.Cauxin\r\n")

-- Instructions
gemdos.Cconws("Send the letter a from the remote\r\n")

-- Read the character from aux
local c = gemdos.Cauxin()

-- Was the letter a received?
assert(c == 97, "Wrong ASCII code: " .. c .. " expected 97")

-- Completed
gemdos.Cconws("Test gemdos.Cauxin completed\r\n")
