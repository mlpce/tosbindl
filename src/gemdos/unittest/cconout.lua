-- Test gemdos.Cconout
gemdos.Cconws("Test gemdos.Cconout\r\n")

-- The message to output
local str = "hello"

-- Instructions
gemdos.Cconws("Observe the message \"" .. str .. "\"\r\n")

-- Output the string using Cconout
for i=1,#str do
  gemdos.Cconout(str:byte(i))
end

-- Completed
gemdos.Cconws("\r\nTest gemdos.Cconout completed\r\n")
