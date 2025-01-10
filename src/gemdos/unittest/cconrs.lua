-- Test gemdos.Cconrs
gemdos.Cconws("Test gemdos.Cconrs\r\n");

-- Check inputting zero characters gives empty string
assert(string.len(gemdos.Cconrs(0)) == 0)

-- Check input of 1 character gives single character string
gemdos.Cconws("Enter one character\r\n");
local str = gemdos.Cconrs(1)
local len = string.len(str)
assert(len == 1, "String length was " .. len .. " expected 1")

gemdos.Cconws("\r\nGot " .. str .. "\r\n");

-- Check input of 8 characters gives eight character string
gemdos.Cconws("Enter eight characters\r\n");
str = gemdos.Cconrs(8)
len = string.len(str)
assert(len == 8, "String length was " .. len .. " expected 8")

gemdos.Cconws("\r\nGot " .. str .. "\r\n");

-- Check input of 255 characters gives 255 character string
gemdos.Cconws("Hold down a character key to repeat for 255 chars\r\n")

str = gemdos.Cconrs(255)
len = string.len(str)
assert(len == 255, "String length was " .. len .. " expected 255")

gemdos.Cconws("\r\nGot " .. str .. "\r\n");

-- Number of characters must be an integer
local ok, m = pcall(function() gemdos.Cconrs(1.2) end)
assert(not ok)

-- Number of characters cannot be negative
ok, m = pcall(function() gemdos.Cconrs(-1) end)
assert(not ok)

-- Can only input up to 255 characters
ok, m = pcall(function() gemdos.Cconrs(256) end)
assert(not ok)

-- Completed
gemdos.Cconws("Test gemdos.Cconrs completed\r\n");
