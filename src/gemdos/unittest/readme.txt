These unit tests change and delete data on GEMDOS drives (HD and floppy) and
must only be run in an isolated test environment to prevent data loss.

A blank formatted floppy disk must be inserted into drive A: for the
FATTRIB.LUA test.

Before running the tests, copy LUA.TTP into the UNITTEST directory as it is
called by some of the tests.

The script UNITTEST.LUA can be used to run all the tests that don't require
interaction from the user. To do this, launch LUA.TTP and make sure the current
drive and directory is the UNITTEST directory. An easy way to do this is to
launch the LUA.TTP that was copied into the UNITTEST directory from the GEM
desktop. Then at the Lua prompt, enter dofile("UNITTEST.LUA") to run the non-
interactive tests.

Tests with a filename that begins with 'C' are character based tests and these
often require user interaction, so these must be run manually. dofile can be
used to run these individually, e.g. dofile("CCONOUT.LUA").

For the CAUX*.LUA tests, a serial cable was used connected to minicom on linux
set to 9600 8N1 with flow control turned off, apart from CAUXOS.LUA which was
run at 300 to fill the buffer quickly.

Known Issues

FFORCE.LUA. If this test is looped it will eventually run out of internal
memory. When using EmuTOS the test will fail with ENHNDL. When using TOS 1.04
it will cause an "OUT OF INTERNAL MEMORY: USE FOLDR100.PRG TO GET MORE"
message and the system will hang. The following can be used to demonstrate
this issue:
for i=1,100 do print(i) dofile("FFORCE.LUA") end

CPRNOS.LUA. This test attempts to loop until the buffer is full, but I have no
printer so testing here is incomplete and it's possible that the parallel
interface runs fast enough that the buffer will not fill. Consider testing
through redirection to aux which can be run at a low bps to fill the buffer.

CPRNOUT.LUA. I have no printer so output was captured to a file through HATARI.

CCONOS.LUA. This test is incomplete, as the console is always ready - consider
testing through redirection.
