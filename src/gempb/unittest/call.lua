local vdi_control = gempb.const.Pbid.vdi_control
local vdi_intin_sz = gempb.const.Pbsize.vdi_intin
local vdi_ptsin_sz = gempb.const.Pbsize.vdi_ptsin

local aes_control = gempb.const.Pbid.aes_control
local aes_addrin = gempb.const.Pbid.aes_addrin
local aes_addrout = gempb.const.Pbid.aes_addrout
local aes_intin_sz = gempb.const.Pbsize.aes_intin
local aes_intout_sz = gempb.const.Pbsize.aes_intout
local aes_addrin_sz = gempb.const.Pbsize.aes_addrin
local aes_addrout_sz = gempb.const.Pbsize.aes_addrout

-- Create the parameter block
local pb = gempb.create_pb()

local ok
-- Test using pb:call to set array values and read array value
for k, v in pairs(gempb.const.Pbid) do
  if v ~= vdi_control and v ~= aes_control then
    gemdos.Cconws("Testing: " .. k .. "\r\n")

    -- get the size of the array
    local array_size = gempb.const.Pbsize[k]

    -- Make up a table of values which will be used for the setting call
    local setting_t = {}
    for i = 1, array_size do
      setting_t[i] = i
    end

    -- Write values into parameter block array
    local r = pb:call(v, #setting_t, table.unpack(setting_t))
    assert(r == nil)

    -- Fake vdi call then read the values from the parameter block array
    local t = table.pack(pb:call(vdi_control, 2, 0, 0, v, #setting_t))
    assert(t.n == #setting_t)

    -- Check the values match
    for kk, vv in ipairs(t) do
      assert(vv == setting_t[kk])
    end

    -- Fake aes call then read the values from the parameter block array
    local t = table.pack(pb:call(aes_control, 2, 0, 0, v, #setting_t))
    assert(t.n == #setting_t)

    -- Check the values match
    for kk, vv in ipairs(t) do
      assert(vv == setting_t[kk])
    end

    -- Reading zero values must produce zero values
    assert(pb:call(vdi_control, 2, 0, 0, v, 0) == nil)
    assert(pb:call(aes_control, 2, 0, 0, v, 0) == nil)

    -- Read from offset two, for two less than array size, with fake vdi call
    t = table.pack(pb:call(vdi_control, 2, 0, 0, v, 0x20000 | #setting_t - 2))
    assert(t.n == #setting_t - 2)
    for kk, vv in ipairs(t) do
      assert(vv == setting_t[kk + 2])
    end

    -- Read from offset two, for two less than array size, with fake aes call
    t = table.pack(pb:call(aes_control, 2, 0, 0, v, 0x20000 | #setting_t - 2))
    assert(t.n == #setting_t - 2)
    for kk, vv in ipairs(t) do
      assert(vv == setting_t[kk + 2])
    end

    -- Set offset 1 and 2 to -1 and -2
    local r = pb:call(v, 0x10002, -1, -2)
    assert(r == nil)

    -- First value must be same as before
    local first = pb:call(vdi_control, 2, 0, 0, v, 1)
    assert(first == 1)
    first = pb:call(aes_control, 1, 0, v, 1)
    assert(first == 1)

    -- Second two values must be -1 and -2
    local second, third = pb:call(vdi_control, 2, 0, 0, v, 0x10002)
    assert(second == -1 and third == -2)
    second, third = pb:call(aes_control, 2, 0, 0, v, 0x10002)
    assert(second == -1 and third == -2)

    -- Subsequent values must continue as before
    local fourth, fifth = pb:call(vdi_control, 2, 0, 0, v, 0x30002)
    assert(fourth == 4 and fifth == 5)
    fourth, fifth = pb:call(aes_control, 2, 0, 0, v, 0x30002)
    assert(fourth == 4 and fifth == 5)

    -- Check range of stored values
    if v == aes_addrin or v == aes_addrout then
      -- Check 32 bit signed value can be stored
      local r = pb:call(v, 2, 2147483647, -1)
      assert(r == nil)
      local first, second = pb:call(vdi_control, 2, 0, 0, v, 2)
      assert(first == 2147483647 and second ==  -1)
      first, second = pb:call(aes_control, 1, 0, v, 2)
      assert(first == 2147483647 and second ==  -1)
    else
      -- Check 16 bit signed value can be stored
      local r = pb:call(v, 2, 32767, -1)
      assert(r == nil)
      local first, second = pb:call(vdi_control, 2, 0, 0, v, 2)
      assert(first == 32767 and second ==  -1)
      first, second = pb:call(aes_control, 2, 0, 0, v, 2)
      assert(first == 32767 and second ==  -1)

      -- A max of 65535 is allowed, but it is really -1
      r = pb:call(v, 2, 65535, -32768)
      assert(r == nil)
      local first, second = pb:call(vdi_control, 2, 0, 0, v, 2)
      assert(first == -1 and second ==  -32768)
      first, second = pb:call(aes_control, 2, 0, 0, v, 2)
      assert(first == -1 and second ==  -32768)

      -- Check out of range value can not be stored
      -- Too large
      ok = pcall(function() pb:call(v, 1, 65536 ) end)
      assert(not ok)

      -- Too small
      ok = pcall(function() pb:call(v, 1, -32769 ) end)
      assert(not ok)
    end

    -- Setting after end of array must fail
    ok = pcall(function() pb:call(v,
      0x10000 | #setting_t, table.unpack(setting_t)) end)
    assert(not ok)
    ok = pcall(function() pb:call(v, #setting_t << 16 | 1, 1) end)
    assert(not ok)

    -- Getting after end of array must fail
    ok = pcall(function() pb:call(aes_control, 2, 0, 0, v,
      #setting_t << 16 | 1) end)
    assert(not ok)
    -- But getting the last value must succeed
    local last = pb:call(aes_control, 2, 0, 0, v, #setting_t - 1 << 16 | 1)
    assert(last == setting_t[#setting_t])

    -- Reading too many values must fail
    ok = pcall(function() pb:call(aes_control, 2, 0, 0, v, #setting_t + 1) end)
    assert(not ok)
  else
    gemdos.Cconws("Skipping: " .. k .. "\r\n")
  end
end

-- Maximum vdi_control intin values must succeed
pb:call(vdi_control, 4, 0, 0, 0, vdi_intin_sz)
-- Too many vdi_control intin values must fail
ok = pcall(function() pb:call(vdi_control, 4, 0, 0, 0, vdi_intin_sz + 1) end)
assert(not ok)

-- Maximum vdi_control ptsin values must succeed
pb:call(vdi_control, 5, 0, 0, 0, 0, vdi_ptsin_sz//2)
-- Too many vdi_control ptsin values must fail
ok = pcall(function() pb:call(vdi_control, 5, 0, 0, 0, 0, vdi_ptsin_sz//2 + 1) end)
assert(not ok)

-- Maximum aes_control intin values must succeed
pb:call(aes_control, 2, 0, aes_intin_sz)
-- Too many aes_control intin values must fail
ok = pcall(function() pb:call(aes_control, 2, 0, aes_intin_sz + 1) end)
assert(not ok)

-- Maximum aes_control intout values must succeed
pb:call(aes_control, 3, 0, 0, aes_intout_sz)
-- Too many aes_control intout values must fail
ok = pcall(function() pb:call(aes_control, 3, 0, 0, aes_intout_sz + 1) end)
assert(not ok)

-- Maximum aes_control addrin values must succeed
pb:call(aes_control, 4, 0, 0, 0, aes_addrin_sz)
-- Too many aes_control addrin values must fail
ok = pcall(function() pb:call(aes_control, 4, 0, 0, 0, aes_addrin_sz + 1) end)
assert(not ok)

-- Maximum aes_control addrout values must succeed
pb:call(aes_control, 5, 0, 0, 0, 0, aes_addrout_sz)
-- Too many aes_control addrout values must fail
ok = pcall(function() pb:call(aes_control, 5, 0, 0, 0, 0, aes_addrout_sz + 1) end)
assert(not ok)
