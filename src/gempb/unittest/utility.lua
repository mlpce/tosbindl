local major, minor, micro = gempb.utility.version()
assert(major >= 1 and minor >= 0 and micro >= 0)

-- screen device id
local devid = gempb.utility.scr_devid()
assert(devid >= 2 and devid <= 4)

-- returns non-zero if gdos present
local gdos_present = gempb.utility.vq_gdos()
assert(gdos_present == 0 or gdos_present == -1)
