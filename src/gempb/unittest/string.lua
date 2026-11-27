-- Create the parameter block
local pb = gempb.create_pb()
local vdi_intin = gempb.const.Pbid.vdi_intin
local vdi_intout = gempb.const.Pbid.vdi_intout
local vdi_intin_size = gempb.const.Pbsize.vdi_intin
local vdi_intout_size = gempb.const.Pbsize.vdi_intout

-- Write a string to intin
gemdos.Cconws("Checking writing string to intin\r\n")
local in_string = "This is a string going in"
pb:setstr(0, in_string)

-- Check the string that was written
local tbl = pb:get(vdi_intin, 0, #in_string)
local combined = string.char(table.unpack(tbl))
assert(combined == in_string)

-- Write a table to intout
gemdos.Cconws("Checking reading string from intout\r\n")
local tbl_string = "This is a string coming out"
tbl = table.pack(string.byte(tbl_string, 1, -1))
pb:set(vdi_intout, 0, tbl)

-- Check the string that comes out
local out_string = pb:getstr(0, #tbl_string)
assert(out_string == tbl_string)

-- Send max size string in
gemdos.Cconws("Checking writing max size string to intin\r\n")
local long_str = string.rep(' ', vdi_intin_size)
pb:setstr(0, long_str)

-- Check the max string that was written
tbl = pb:get(vdi_intin, 0, #long_str)
combined = string.char(table.unpack(tbl))
assert(combined == long_str)

-- Setting too long string must fail
gemdos.Cconws("Checking writing too long string to intin fails\r\n")
local ok = pcall(function() pb:setstr(0, long_str .. " ") end)
assert(not ok)
ok = pcall(function() pb:setstr(1, long_str) end)
assert(not ok)

-- Write a max length table to intout
tbl_string = string.rep(' ', vdi_intout_size)
tbl = table.pack(string.byte(tbl_string, 1, -1))
pb:set(vdi_intout, 0, tbl)

-- Check the string that comes out
gemdos.Cconws("Checking reading max size string from intout\r\n")
out_string = pb:getstr(0, #tbl_string)
assert(out_string == tbl_string)

-- Getting too long string must fail
gemdos.Cconws("Checking reading too long string from intout fails\r\n")
ok = pcall(function() pb:getstr(0, vdi_intout_size + 1) end)
assert(not ok)
ok = pcall(function() pb:getstr(1, vdi_intout_size) end)
assert(not ok)

-- Test ranges of positional arguments relative to a string
assert("cd" == string.char(table.unpack(
  pb:get(vdi_intin, 0, pb:setstr(0, "abcd", 3, 6)))))
assert("abc" == string.char(table.unpack(
  pb:get(vdi_intin, 0, pb:setstr(0, "abcd", -7, 3)))))
assert("" == string.char(table.unpack(
  pb:get(vdi_intin, 0, pb:setstr(0, "abcd", -7, -5)))))
assert("" == string.char(table.unpack(
  pb:get(vdi_intin, 0, pb:setstr(0, "abcd", 5, 6)))))
assert("" == string.char(table.unpack(
  pb:get(vdi_intin, 0, pb:setstr(0, "abcd", 3, 2)))))

-- Write a string with first and last positions
local function test_setstr_pos(str, first_pos, last_pos)
  local <const> num_written = pb:setstr(0, str, first_pos, last_pos)

  -- For different signs adjust the other position so
  -- the signs are the same.
  local first, last
  if first_pos * last_pos > 0 then
    first, last = first_pos, last_pos
  elseif first_pos > 0 then
    first, last = first_pos, #str + last_pos + 1
  else
    first, last = #str + first_pos + 1, last_pos
  end

  -- For sequenced indices, the number of bytes written
  -- is the difference between them plus one.
  if first <= last then
    -- Check num chars written
    assert(num_written == last - first + 1)
  else
    -- For reversed indices, the number of bytes written
    -- must be zero.
    assert(num_written == 0)
  end

  -- Extract the data that was written to intin
  local tbl = pb:get(vdi_intin, 0, num_written)
  local written = string.char(table.unpack(tbl))
  -- The data must be the same as the equivalent string.sub call
  assert(written == string.sub(str, first_pos, last_pos))
end

-- Test positive and negative string positions
local function test_setstr_positions(str)
  local <const> str_len = #str
  -- Test positive string positions
  gemdos.Cconws("Checking setstr with positive string positions\r\n")
  for first_pos = 1, str_len do
    for last_pos = str_len, 1, -1 do
      test_setstr_pos(str, first_pos, last_pos)
    end
  end
  -- Test negative string positions
  gemdos.Cconws("Checking setstr with negative string positions\r\n")
  for first_pos = -str_len, -1 do
    for last_pos = -1, -str_len, -1 do
      test_setstr_pos(str, first_pos, last_pos)
    end
  end
  -- Test positive and negative string positions
  gemdos.Cconws(
    "Checking setstr with positive and negative string positions\r\n")
  for first_pos = 1, str_len do
    for last_pos = -1, -str_len, -1 do
      test_setstr_pos(str, first_pos, last_pos)
    end
  end
  -- Test negative and positive string posotions
  gemdos.Cconws(
    "Checking setstr with negative and positive string positions\r\n")
  for first_pos = -str_len, -1 do
    for last_pos = str_len, 1, -1 do
      test_setstr_pos(str, first_pos, last_pos)
    end
  end
end

test_setstr_positions("0123456789ABCDEF")
