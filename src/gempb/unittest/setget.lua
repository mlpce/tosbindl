local aes_addrin = gempb.const.Pbid.aes_addrin
local aes_addrout = gempb.const.Pbid.aes_addrout

-- Create the parameter block
local pb = gempb.create_pb()

-- Test pb:set and pb:get
for k,v in pairs(gempb.const.Pbid) do
  gemdos.Cconws("k: " .. k .. "\r\n")

  -- get the size of the array
  local array_size = gempb.const.Pbsize[k]

  -- Make up a table of values which will be used for the set
  local setting_t = {}
  for i = 1,array_size do
    setting_t[i] = i
  end

  -- Set the array using the table
  pb:set(v, 0, setting_t)

  -- Get the array into a new table
  local getting_t = pb:get(v, 0, array_size)
  -- Check the tables are equal
  assert(#getting_t == #setting_t)
  for i = 1,array_size do
    assert(getting_t[i] == setting_t[i])
  end

  -- Reading zero values must produce empty table
  assert(#pb:get(v, 0, 0) == 0)

  -- Not specifying number of values to read means read from offset to end
  -- of array. An offset of 1 is used here, so array_size - 1 values must
  -- be read into the table.
  assert(#pb:get(v, 1) == array_size - 1)

  -- Set a portion of the table
  pb:set(v, 1, { -1, -2 })

  -- First value must be same as before
  local first = pb:get(v, 0, 1)
  assert(#first == 1 and first[1] == setting_t[1])

  -- Second two values must be -1 and -2
  local second_two = pb:get(v, 1, 2)
  assert(#second_two == 2 and second_two[1] == -1 and second_two[2] == -2)

  -- Subsequent values must continue as before
  local subsequent = pb:get(v, 3, 2)
  assert(#subsequent == 2 and subsequent[1] == 4 and subsequent[2] == 5)

  -- Check range of stored values
  if v == aes_addrin or v == aes_addrout then
    -- Check 32 bit signed value can be stored
    pb:set(v, 0, { 2147483647, -1 })
    local t = pb:get(v, 0, 2)
    assert(t[1] == 2147483647 and t[2] == -1)
  else
    -- Check 16 bit signed value can be stored
    pb:set(v, 0, { 32767, -1 })
    local t = pb:get(v, 0, 2)
    assert(t[1] == 32767 and t[2] == -1)

    -- A max of 65535 is allowed, but it is really -1
    pb:set(v, 0, { 65535, -32768 })
    local t = pb:get(v, 0, 2)
    assert(t[1] == -1 and t[2] == -32768)

    -- Check out of range value can not be stored
    -- Too large
    local ok = pcall(function() pb:set(v, 0, { 65536 } ) end)
    assert(not ok)

    -- Too small
    ok = pcall(function() pb:set(v, 0, { -32769 } ) end)
    assert(not ok)
  end

  -- Setting before the beginning of the array must fail
  local ok = pcall(function() pb:set(v, -1, setting_t) end)
  assert(not ok)

  -- Setting after the end of the array must fail
  ok = pcall(function() pb:set(v, 1, setting_t) end)
  assert(not ok)

  -- Getting before the begining of the array must fail
  ok = pcall(function() pb:get(v, -1, array_size) end)
  assert(not ok)

  -- Getting after the end of the array must fail
  ok = pcall(function() pb:get(v, 1, array_size) end)
  assert(not ok)

  -- Reading a negative number of values must fail
  ok = pcall(function() pb:get(v, 0, -1) end)
  assert(not ok)

  -- Reading two many values must fail
  ok = pcall(function() pb:get(v, 0, array_size + 1) end)
  assert(not ok)
end
