-- Lua received 500 arguments and used the first as the script path to run.
-- The script path refers to this script.
-- Lua runs this script, placing the script name in arg[0].
-- The remaining arguments go into arg[1], arg[2], arg[3], ...
assert(arg[0] == "pexec0rx.lua")
assert(#arg == 499)

-- Check arguments
for n = 1,499 do
  assert(arg[n] == "Arg: " .. n + 1)
end

gemdos.Pterm0()
