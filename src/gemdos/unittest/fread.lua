-- Unittest for gemdos.Fread
gemdos.Cconws("Test gemdos.Fread\r\n")

-- Create a new file named TESTFILE
local ec, fud = gemdos.Fcreate("TESTFILE", gemdos.const.Fattrib.none)
assert(ec == 0)
assert(fud:handle() >= 6)

-- Write string
local num = gemdos.Fwrites(fud, "0123456789A")
assert(num == 11)

-- Close the file
ec = gemdos.Fclose(fud)

-- Open the file
ec, fud = gemdos.Fopen("TESTFILE", gemdos.const.Fopen.readonly)

-- Read string
local str
ec, str = gemdos.Freads(fud, 2)
assert(ec == 2 and str == "01")

-- Read table
local tbl
ec, tbl = gemdos.Freadt(fud, 2)
assert(ec == 2 and string.char(table.unpack(tbl)) == "23")

-- Read memory
local mud
ec, mud = gemdos.Malloc(2)
assert(ec == 2)
ec = gemdos.Freadm(fud, mud, 0, 2)
assert(ec == 2)
assert(mud:peek(0) == string.byte("4") and mud:peek(1) == string.byte("5"))

-- Read value
local val
ec, val = gemdos.Freadi(fud, 1)
assert(ec == 1)
assert(val == string.byte("6"))

-- Read string using self
ec, str = fud:reads(1)
assert(ec == 1)
assert(str == "7")

-- Read table using self
ec, tbl = fud:readt(1)
assert(ec == 1)
assert(tbl[1] == string.byte("8"))

-- Read memory using self
ec = fud:readm(mud, 0, 1)
assert(ec == 1)
assert(mud:peek(0) == string.byte("9"))

-- Read value using self
ec, val = fud:readi(1)
assert(ec == 1 and val == string.byte("A"))

-- End of file now reached. Any further reads produce zero bytes
assert(fud:reads(1) == 0)
assert(fud:readt(1) == 0)
assert(fud:readm(mud, 0, 1) == 0)
assert(fud:readi(1) == 0)

-- Close the file
ec = gemdos.Fclose(fud)
assert(ec)

gemdos.Cconws("Test gemdos.Fread completed\r\n")
