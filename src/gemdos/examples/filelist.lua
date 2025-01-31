-- FileList.process(path[, fud]) will list all the files in the path and its
-- subdirectories. If called with the fud parameter missing the list will be
-- output to the console, otherwise to the passed file userdata.
local FileList = {}

local gemdos = gemdos
local Error = gemdos.const.Error
local Fsfirst = gemdos.Fsfirst
local dir_attribute = gemdos.const.Fattrib.dir
local file_mask = gemdos.const.Fattrib.readonly | gemdos.const.Fattrib.hidden |
  gemdos.const.Fattrib.system | gemdos.const.Fattrib.dir

-- Process a path recursively
local function process_path(path, fud)
  local dirs = {}
  local files = {}

  -- Save the DTAs for directories and files
  local ec, dta = Fsfirst(path .. "\\*.*", file_mask)
  while (ec == 0) do
    local entry_name = dta:name()
    local entry_attr = dta:attr()
    if entry_attr & dir_attribute ~= 0 then
      if entry_name ~= "." and entry_name ~= ".." then
        dirs[#dirs + 1] = dta:copydta()
      end
    else
      files[#files + 1] = dta:copydta()
    end
    local msg
    ec, msg = dta:snext()
  end

  -- Did an unwanted error occur?
  -- ENMFIL (no more files) and EFILNF (directory is empty) are ok
  if ec < 0 and ec ~= Error.ENMFIL and ec ~= Error.EFILNF then
    fud:writes("Error while processing path " .. path .. "\r\n");
    return ec, 0, 0
  end

  -- Process all directories, keep a summed count of bytes, directories and
  -- files contained in all the directories
  local sub_files_bytes = 0
  local sub_dirs = 0
  local sub_files = 0
  for _,dta in ipairs(dirs) do
    local sub_path = path .. "\\" .. dta:name()
    -- Process the directory
    local proc_sub_files_bytes_or_ec, proc_sub_dirs, proc_sub_files =
      process_path(sub_path, fud)
    if proc_sub_files_bytes_or_ec >= 0 then
      sub_files_bytes = sub_files_bytes + proc_sub_files_bytes_or_ec
      sub_dirs = sub_dirs + proc_sub_dirs
      sub_files = sub_files + proc_sub_files
    else
      ec = proc_sub_files_bytes_or_ec
      break
    end
  end

  -- Did a subdirectory return an unwanted error?
  if ec < 0 and ec ~= Error.ENMFIL and ec ~= Error.EFILNF then
    return ec, 0, 0
  end

  -- Print out all the entries in this directory
  fud:writes(path .. "\r\n");

  local print_entry = function(dta)
    local name = dta:name()
    local year, month, day, hour, minute, second =
        dta:datime()
    local length = dta:length()
    local attr = dta:attr()

    fud:writes("  " .. name .. string.rep(" ", 14 - name:len()) ..
      string.format(
        "%s  0x%02x  ", attr & dir_attribute ~= 0 and "DIR" or "FIL",
        attr) .. string.format("%04d/%02d/%02d %02d:%02d:%02d  ",
        year, month, day, hour, minute, second) .. length .. "\r\n")
  end

  -- First print the directory entries
  for _,dta in ipairs(dirs) do
    print_entry(dta)
  end

  -- Second print out the file entries
  local this_directory_files_bytes = 0
  for _,dta in ipairs(files) do
    print_entry(dta)
    this_directory_files_bytes = this_directory_files_bytes + dta:length()
  end

  local all_bytes = this_directory_files_bytes + sub_files_bytes
  fud:writes(string.format(
    "  %d directories (%d bytes) %d files (%d bytes)\r\n",
    #dirs, sub_files_bytes, #files, this_directory_files_bytes))

  return all_bytes, sub_dirs + #dirs, sub_files + #files
end

-- List the contents of a path
-- Second parameter is optional file userdata for output (defaults to con:)
function FileList.process(path, fud)
  if type(path) ~= "string" then
    error("Path must be a string", 2)
  end

  local ec, local_fud
  if fud == nil then
    ec, local_fud = gemdos.Fopen("con:", gemdos.const.Fopen.writeonly)
    if ec < 0 then
      error("Could not open con:")
    end
    fud = local_fud
  end

  local total_bytes, total_dirs, total_files
  total_bytes, total_dirs, total_files = process_path(path, fud)
  if total_bytes >= 0 then
    fud:writes(string.format("%d bytes in %d directories and %d files\r\n",
      total_bytes, total_dirs, total_files))
  else
    fud:writes("Error: " .. total_bytes .. "\r\n")
  end

  if local_fud then
    local_fud:close()
  end
end

return FileList
