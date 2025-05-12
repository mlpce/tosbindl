#!/usr/bin/env bash
set -e

# This script converts the source files to GEMDOS compatible 8.3 filenames.
# It then creates a zip file, adding the files with LF converted to CRLF.

# Make 8.3 directory structure
rm -Rfv 8.3/TOSBINDL*
mkdir -p 8.3/TOSBINDL/BUILD/TOS/LATTICEC
mkdir -p 8.3/TOSBINDL/SRC/GEMDOS/UNITTEST

function copy_lower_upper() {
  local wild_path=$1
  for path in $wild_path
  do
    local destination_path=$(echo $path | tr [:lower:] [:upper:])
    cp -v $path 8.3/TOSBINDL/BUILD/TOS/$destination_path
  done
}

# Copy files as 8.3 filenames
cp -v ../../LICENSE 8.3/TOSBINDL
copy_lower_upper "latticec/tbgemdos.prj"
copy_lower_upper "latticec/tosbindl.prj"
copy_lower_upper "../../src/gemdos/gemdos_[cdfmpst].[ch]"
copy_lower_upper "../../src/gemdos/gemdosi.[ch]"
copy_lower_upper "../../src/gemdos/tbgemdos.[ch]"
copy_lower_upper "../../src/gemdos/unittest/cauxin.lua"
copy_lower_upper "../../src/gemdos/unittest/cauxis.lua"
copy_lower_upper "../../src/gemdos/unittest/cauxos.lua"
copy_lower_upper "../../src/gemdos/unittest/cauxout.lua"
copy_lower_upper "../../src/gemdos/unittest/cconin.lua"
copy_lower_upper "../../src/gemdos/unittest/cconos.lua"
copy_lower_upper "../../src/gemdos/unittest/cconout.lua"
copy_lower_upper "../../src/gemdos/unittest/cconrs.lua"
copy_lower_upper "../../src/gemdos/unittest/cconws.lua"
copy_lower_upper "../../src/gemdos/unittest/cnecin.lua"
copy_lower_upper "../../src/gemdos/unittest/cprnos.lua"
copy_lower_upper "../../src/gemdos/unittest/cprnout.lua"
copy_lower_upper "../../src/gemdos/unittest/crawcin.lua"
copy_lower_upper "../../src/gemdos/unittest/crawio.lua"
copy_lower_upper "../../src/gemdos/unittest/dcreate.lua"
copy_lower_upper "../../src/gemdos/unittest/ddelete.lua"
copy_lower_upper "../../src/gemdos/unittest/dfree.lua"
copy_lower_upper "../../src/gemdos/unittest/dgetdrv.lua"
copy_lower_upper "../../src/gemdos/unittest/dgetpath.lua"
copy_lower_upper "../../src/gemdos/unittest/dsetdrv.lua"
copy_lower_upper "../../src/gemdos/unittest/dsetpath.lua"
copy_lower_upper "../../src/gemdos/unittest/fattrib.lua"
copy_lower_upper "../../src/gemdos/unittest/fcestdhd.lua"
copy_lower_upper "../../src/gemdos/unittest/fclose.lua"
copy_lower_upper "../../src/gemdos/unittest/fcreate.lua"
copy_lower_upper "../../src/gemdos/unittest/fdatime.lua"
copy_lower_upper "../../src/gemdos/unittest/fdelete.lua"
copy_lower_upper "../../src/gemdos/unittest/fdup.lua"
copy_lower_upper "../../src/gemdos/unittest/fforce.lua"
copy_lower_upper "../../src/gemdos/unittest/fopen.lua"
copy_lower_upper "../../src/gemdos/unittest/fread.lua"
copy_lower_upper "../../src/gemdos/unittest/frename.lua"
copy_lower_upper "../../src/gemdos/unittest/fseek.lua"
copy_lower_upper "../../src/gemdos/unittest/fsfirst.lua"
copy_lower_upper "../../src/gemdos/unittest/fsnext.lua"
copy_lower_upper "../../src/gemdos/unittest/fwrite.lua"
copy_lower_upper "../../src/gemdos/unittest/malloc.lua"
copy_lower_upper "../../src/gemdos/unittest/mfree.lua"
copy_lower_upper "../../src/gemdos/unittest/mshrink.lua"
copy_lower_upper "../../src/gemdos/unittest/pexec0.lua"
copy_lower_upper "../../src/gemdos/unittest/pexec0rx.lua"
copy_lower_upper "../../src/gemdos/unittest/pterm.lua"
copy_lower_upper "../../src/gemdos/unittest/pterm0.lua"
copy_lower_upper "../../src/gemdos/unittest/readme.txt"
copy_lower_upper "../../src/gemdos/unittest/sversion.lua"
copy_lower_upper "../../src/gemdos/unittest/tgetdate.lua"
copy_lower_upper "../../src/gemdos/unittest/tgettime.lua"
copy_lower_upper "../../src/gemdos/unittest/tsetdate.lua"
copy_lower_upper "../../src/gemdos/unittest/tsettime.lua"
copy_lower_upper "../../src/gemdos/unittest/unittest.lua"
copy_lower_upper "../../src/gemdos/unittest/utility.lua"
copy_lower_upper "../../src/tosbindl.[ch]"

# Zip up files, converting LF to CRLF
pushd 8.3
zip -l -r TOSBINDL.ZIP TOSBINDL
popd
