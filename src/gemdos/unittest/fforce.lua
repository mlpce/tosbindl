local force_standard_handle = require("fcestdhd")

-- Test gemdos.Fforce
gemdos.Cconws("Test gemdos.Fforce\r\n")

-- Create output file
local ec, fud <close> = gemdos.Fcreate("conoutfc.txt", gemdos.const.Fattrib.none)
gemdos.Cconws("fud handle " .. fud:handle() .. "\r\n")
assert(ec == 0)
fud:close()

local fn = function(standard_handle, fud)
  -- Pexec0 some output
  local pexec0_ec = gemdos.Pexec0("lua.ttp", { "-e print(\"HELLO\")" } )
  if pexec0_ec >= 0 then
    -- fud will have been closed when child exited
    fud:detach()
  end
  assert(pexec0_ec == 0)
end

-- Force coninfce.txt to conin and call fn
local result, err = force_standard_handle.ForcedFilenameCall(gemdos.const.Fdup.conout,
  "conoutfc.txt", fn)
assert(result, err)

-- Open the output for checking
local ec, check_fud <close> = gemdos.Fopen("conoutfc.txt", gemdos.const.Fopen.readonly)
assert(ec == 0)

-- Read string
local ec, str = gemdos.Freads(check_fud, 100)
assert(ec == 7 and str == "HELLO\r\n")

-- Close
ec = check_fud:close()
assert(ec == 0)

gemdos.Cconws("Test gemdos.Fforce completed\r\n")
