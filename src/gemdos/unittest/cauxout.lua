-- Test gemdos.Cauxout
gemdos.Cconws("Test gemdos.Cauxout\r\n")

-- The message to send
local str = "hello"

-- Instructions
gemdos.Cconws("Observe the message \"" .. str .. "\" on the remote\r\n")

-- Send the message to the remote
for i=1,#str do
  gemdos.Cauxout(str:byte(i))
end

-- Completed
gemdos.Cconws("Test gemdos.Cauxout completed\r\n")
