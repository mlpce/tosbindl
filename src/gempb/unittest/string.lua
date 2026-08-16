-- Create the parameter block
local pb = gempb.create_pb()
local vdi_intin = gempb.const.Pbid.vdi_intin
local vdi_intout = gempb.const.Pbid.vdi_intout
local vdi_intin_size = gempb.const.Pbsize.vdi_intin
local vdi_intout_size = gempb.const.Pbsize.vdi_intout

-- Write a string to intin
local in_string = "This is a string going in"
pb:setstr(0, in_string)

-- Check the string that was written
local tbl = pb:get(vdi_intin, 0, #in_string)
local combined = string.char(table.unpack(tbl))
assert(combined == in_string)
gemdos.Cconws(combined .. "\r\n")

-- Write a table to intout
local tbl_string = "This is a string coming out"
tbl = table.pack(string.byte(tbl_string, 1, -1))
pb:set(vdi_intout, 0, tbl)

-- Check the string that comes out
local out_string = pb:getstr(0, #tbl_string)
assert(out_string == tbl_string)
gemdos.Cconws(out_string .. "\r\n")

-- Send max size string in
local long_str = string.rep(' ', vdi_intin_size)
pb:setstr(0, long_str)

-- Check the max string that was written
tbl = pb:get(vdi_intin, 0, #long_str)
combined = string.char(table.unpack(tbl))
assert(combined == long_str)

-- Setting too long string must fail
local ok = pcall(function() pb:setstr(0, long_str .. " ") end)
assert(not ok)
ok = pcall(function() pb:setstr(1, long_str) end)
assert(not ok)

-- Write a max length table to intout
tbl_string = string.rep(' ', vdi_intout_size)
tbl = table.pack(string.byte(tbl_string, 1, -1))
pb:set(vdi_intout, 0, tbl)

-- Check the string that comes out
out_string = pb:getstr(0, #tbl_string)
assert(out_string == tbl_string)

-- Getting too long string must fail
ok = pcall(function() pb:getstr(0, vdi_intout_size + 1) end)
assert(not ok)
ok = pcall(function() pb:getstr(1, vdi_intout_size) end)
assert(not ok)
