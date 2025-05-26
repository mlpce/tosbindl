local ForceStdHandle = {}

local allowed_handles = {}
for k,v in pairs(gemdos.const.Fdup) do
  allowed_handles[v] = k
end

-- Calls passed function with standard handle forced to handle returned by opener
function ForceStdHandle.ForcedFileCall(standard_handle, opener, fn)
  if not allowed_handles[standard_handle] then
    error("Invalid standard handle", 2)
  end

  if type(opener) ~= "function" or type(fn) ~= "function" then
    error("Function expected", 2)
  end

  -- Duplicate original standard handle
  local dup_ec, dupfud <close> = gemdos.Fdup(standard_handle);
  if dup_ec ~= 0 then
    gemdos.Cconws("Could not dup\r\n")
    return false
  end

  -- Open file with opener
  local ec, fud <close> = opener()
  if ec ~= 0 then
    gemdos.Cconws("Could not open with opener\r\n")
    return false
  end

  -- Set standard handle to the filename handle
  ec = gemdos.Fforce(fud, standard_handle)
  if ec ~= 0 then
    gemdos.Cconws("Could not force standard handle\r\n")
    return false;
  end

  -- Call the function
  local result = table.pack(pcall(fn, standard_handle, fud))

  -- Set standard handle back to original handle
  ec = gemdos.Fforce(dupfud, standard_handle)
  if ec ~= 0 then
    gemdos.Cconws("Could set standard handle back to original handle")
  end

  ec = dupfud:close()
  if ec ~= 0 then
    gemdos.Cconws("force: dupfud:close() returned " .. ec .. "\r\n")
  end

  -- fud may have been detached by fn
  if fud:handle() ~= 0 then
    ec = fud:close()
    if ec ~= 0 then
      gemdos.Cconws("force: fud:close() returned " .. ec .. "\r\n")
    end
  end

  -- Return results
  return table.unpack(result)
end

return ForceStdHandle
