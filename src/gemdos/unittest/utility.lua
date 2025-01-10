-- Unittest for gemdos.utility
gemdos.Cconws("Test gemdos.utility\r\n")

local env_table = gemdos.utility.getenv()
local env_path = gemdos.utility.getenv("PATH")
assert(env_path == env_table.PATH)

gemdos.Cconws("Test gemdos.utility completed\r\n")
