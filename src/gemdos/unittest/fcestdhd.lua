local ForceStdHandle = {}

-- Calls passed function with standard handle forced to the filename
function ForceStdHandle.ForcedFilenameCall(standard_handle, filename, fn)
  -- Duplicate original standard handle
  local dup_ec, dupfud <close> = gemdos.Fdup(standard_handle);
  if dup_ec ~= 0 then
    gemdos.Cconws("Could not dup\r\n")
    return false
  end

  -- Open filename
  local ec, fud <close> = gemdos.Fopen(filename, gemdos.const.Fopen.readwrite);
  if ec ~= 0 then
    gemdos.Cconws("Could not open filename\r\n")
    return false
  end

  -- Set standard handle to the filename handle
  ec = gemdos.Fforce(fud, standard_handle)
  if ec ~= 0 then
    gemdos.Cconws("Could not force standard handle\r\n")
    return false;
  end

  -- Call the function
  local result = table.pack(pcall(fn))

  -- Set standard handle back to original handle
  ec = gemdos.Fforce(dupfud, standard_handle)
  if ec ~= 0 then
    gemdos.Cconws("Could set standard handle back to original handle")
  end

  -- Return results
  return table.unpack(result)
end

return ForceStdHandle
