-- Unittest for gemdos.Dsetdrv
gemdos.Cconws("Test gemdos.Dsetdrv\r\n")

-- Get the default drive
local default_drive <const> = gemdos.Dgetdrv()

-- Get the drive bits
local drive_bits <const> = gemdos.Dsetdrv(default_drive)

-- Get the drive numbers and drive letters
local drives = {}
for drive = 0,15 do
  if 0 ~= drive_bits & (1 << drive) then
    drives[#drives + 1] = drive
  end
end

-- Set each drive in turn
for i,v in ipairs(drives) do
  assert(drive_bits == gemdos.Dsetdrv(drives[i]))
  assert(drives[i] == gemdos.Dgetdrv())
end

-- Back to the original default
gemdos.Dsetdrv(default_drive)

-- Completed
gemdos.Cconws("Test gemdos.Dsetdrv completed\r\n")
