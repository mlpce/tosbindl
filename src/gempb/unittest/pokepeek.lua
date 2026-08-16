local aes_addrin = gempb.const.Pbid.aes_addrin
local aes_addrout = gempb.const.Pbid.aes_addrout

-- Create the parameter block
local pb = gempb.create_pb()

-- Test pb:set and pb:get
for k,v in pairs(gempb.const.Pbid) do
  gemdos.Cconws("k: " .. k .. "\r\n")

  -- get the size of the array
  local array_size = gempb.const.Pbsize[k]

  -- Poke a value at a time
  for i = 0, array_size - 1 do
    pb:poke(v, i, i)
  end

  -- Peek a value at a time
  for i = 0, array_size - 1 do
    assert(pb:peek(v, i) == i)
  end

  -- Poke and peek multiple values

  -- Set a portion of the array
  pb:poke(v, 1, -1, -2 )

  -- First value must be same as before
  local zero = pb:peek(v, 0)
  assert(zero == 0)

  -- next two values must be -1 and -2
  local one, two = pb:peek(v, 1, 2)
  assert(one == -1 and two == -2)

  -- Subsequent values must continue as before
  local three, four = pb:peek(v, 3, 2)
  assert(three == 3 and four == 4)

  -- Check range of stored values
  if v == aes_addrin or v == aes_addrout then
    -- Check 32 bit signed value can be stored
    pb:poke(v, 0, 2147483647, -1)
    local zero, one = pb:peek(v, 0, 2)
    assert(zero == 2147483647 and one == -1)
  else
    -- Check 16 bit signed value can be stored
    pb:poke(v, 0, 32767, -1)
    local zero, one = pb:peek(v, 0, 2)
    assert(zero == 32767 and one == -1)

    -- A max of 65535 is allowed, but it is really -1
    pb:poke(v, 0, 65535, -32768)
    zero, one = pb:peek(v, 0, 2)
    assert(zero == -1 and one == -32768)

    -- Check out of range value can not be stored
    -- Too large.
    local ok = pcall(function() pb:poke(v, 0, 65536 ) end)
    assert(not ok)

    -- Too small
    ok = pcall(function() pb:poke(v, 0, -32769 ) end)
    assert(not ok)
  end

  -- Setting before the beginning of the array must fail
  local ok = pcall(function() pb:poke(v, -1, 0) end)
  assert(not ok)

  -- Setting after the end of the array must fail
  ok = pcall(function() pb:poke(v, array_size, 0) end)
  assert(not ok)

  -- Getting before the begining of the array must fail
  ok = pcall(function() pb:peek(v, -1) end)
  assert(not ok)

  -- Getting after the end of the array must fail
  ok = pcall(function() pb:peek(v, array_size) end)
  assert(not ok)

  -- Reading a negative number of values must fail
  ok = pcall(function() pb:peek(v, 0, -1) end)
  assert(not ok)

  -- Reading two many values must fail
  ok = pcall(function() pb:peek(v, 0, array_size + 1) end)
  assert(not ok)
end
