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

Some shortcomings:
CPRNOS.LUA. It attempts to loop until the buffer is full, but I have no printer
so testing here is incomplete and it's possible that the parallel interface
runs fast enough that the buffer will not fill. Perhaps it can be tested
through redirection to aux which can be run at a low bps to fill the buffer.
CPRNOUT.LUA. I have no printer so output was captured to a file through HATARI.
CCONOS.LUA. The console is always ready - again perhaps this can be tested
through redirection.
