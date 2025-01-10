-- Test gemdos.Cprnout
gemdos.Cconws("Test gemdos.Cprnout\r\n")

-- The message to send
local str = "hello"

-- Instructions
gemdos.Cconws("Observe the message \"" .. str .. "\" on the printer\r\n")

-- Send the message to the printer
for i=1,#str do
  gemdos.Cprnout(str:byte(i))
end

-- Completed
gemdos.Cconws("Test gemdos.Cprnout completed\r\n")
