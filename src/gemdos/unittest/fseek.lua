-- Unittest for gemdos.Fseek
gemdos.Cconws("Test gemdos.Fseek\r\n")

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Write values between 0 and 31
for i=0,31 do
  ec = fud:writei(i)
  assert(ec == 1)
end

-- Find current position
local abs_pos = gemdos.Fseek(fud, 0, gemdos.const.Fseek.seek_cur)
assert(abs_pos == 32)

-- EOF so reading produces zero bytes
local num_bytes, val = fud:readi(abs_pos)
assert(num_bytes == 0)

-- Seek relative to end to the beginning of the file
abs_pos = gemdos.Fseek(fud, -32, gemdos.const.Fseek.seek_end)
assert(abs_pos == 0)
num_bytes, val = fud:readi(abs_pos)
assert(num_bytes == 1 and val == 0)

--- Seek relative to end 8 bytes
abs_pos = gemdos.Fseek(fud, -8, gemdos.const.Fseek.seek_end)
assert(abs_pos == 24)
num_bytes, val = fud:readi(abs_pos)
assert(num_bytes == 1 and val == 24)

-- Seek relative to end to end of the file
abs_pos = gemdos.Fseek(fud, 0, gemdos.const.Fseek.seek_end)
assert(abs_pos == 32)
-- EOF so reads zero bytes
num_bytes, val = fud:readi(abs_pos)
assert(num_bytes == 0 and val == 0)

-- Seek relative to start to end of the file
abs_pos = gemdos.Fseek(fud, 32, gemdos.const.Fseek.seek_set)
assert(abs_pos == 32)
-- EOF so reads zero bytes
num_bytes, val = fud:readi(abs_pos)
assert(num_bytes == 0 and val == 0)

-- Seek relative to start 8 bytes
abs_pos = gemdos.Fseek(fud, 8, gemdos.const.Fseek.seek_set)
assert(abs_pos == 8)
num_bytes, val = fud:readi(abs_pos)
assert(num_bytes == 1 and val == 8)

-- Seek relative to start to start
abs_pos = gemdos.Fseek(fud, 0, gemdos.const.Fseek.seek_set)
assert(abs_pos == 0)
num_bytes, val = fud:readi(abs_pos)
assert(num_bytes == 1 and val == 0)

-- Close the file
ec = gemdos.Fclose(fud)
assert(ec == 0)

gemdos.Cconws("Test gemdos.Fseek completed\r\n")
