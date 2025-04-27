-- Test gemdos.Pexec0
gemdos.Cconws("Test gemdos.Pexec0\r\n")

-- Arguments table
local args = {
  "pexec0rx.lua" -- First argument - the Lua script to execute
}

-- Add more arguments to make 500 in total
for n = 2,500 do
  args[n] = "Arg: " .. n
end

-- Pexec the Lua interpreter, passing 500 arguments
local err = gemdos.Pexec0("lua.ttp", args)

-- pexec0rx.lua will return 0 if the arguments were correct
assert(err == 0)

-- Empty arguments (i.e. zero length strings) are not supported
local ok
ok = pcall(
  function()
    gemdos.Pexec0("lua.ttp", { { "-e print(\"HELLO\")", "" }})
  end )
assert(not ok)

gemdos.Cconws("Test gemdos.Pexec0 completed\r\n")
