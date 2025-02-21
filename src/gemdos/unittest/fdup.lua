-- Test gemdos.Fdup
gemdos.Cconws("Test gemdos.Fdup\r\n")

for k,v in pairs(gemdos.const.Fdup) do
  local ec, fud = gemdos.Fdup(v);
  assert(ec == 0);
  fud:close()
end

-- Completed
gemdos.Cconws("Test gemdos.Fdup completed\r\n")
