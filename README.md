# tosbindl

## Atari ST GEMDOS binding for Lua 5.4.

This is a Lua binding to TOS GEMDOS functions. The functions available in TOS 1.X have been implemented. EmuTOS 1.3 and TOS 1.04 have been used during development, no other TOS versions have been tried or tested.

## Lua API

For information about Lua see the [Lua website](https://www.lua.org/). For the copyright notice of the Lua API included by this binding see lua.h.

luaconf.h should be configured with
  1. #define LUA_USE_C89
  2. #define LUA_32BITS 1

## Lua registry

The binding expects the GEMDOS environment pointer (the third parameter to main()) to be stored in the registry as a light userdata with the key "gemdos.envp". The pointer is obtained in the function TOSBINDL_GEMDOS_EnvP.

## Precaution
This binding has the potential to change and destroy data. Development and testing of scripts using this binding should be performed in a safe environment isolated from sensitive data. Additionally, the unit tests themselves change and delete data on GEMDOS drives (HD and floppy) and must only be run in an isolated test environment.

## Implemented functions

### Character functions

Cconin, Cconout, Cauxin, Cauxout, Cprnout, Crawio, Crawcin, Cnecin, Cconws,
Cconrs, Cconis, Cconos, Cprnos, Cauxis, Cauxos.

If there is a use case to send a lot of data through the character based output functions e.g. Cprnout, then it's worth checking if the throughput is limited by the interpreter execution speed. If it is then a utility function can be written to loop the output using native C code.

### Directory functions

Dgetdrv, Dsetdrv, Dfree, Dcreate, Ddelete, Dsetpath, Dgetpath

### File functions

Fcreate, Fopen, Fread, Fwrite, Fseek, Fdelete, Fclose, Frename, Fattrib, Fdatime, Fdup, Fforce, Fsfirst, Fsnext

### Memory functions

Malloc, Mfree, Mshrink

### Process functions

Pterm0, Pterm, Pexec (Mode 0 only)

### System functions

Sversion, Super (for peek and poke)

### Time functions

Tgetdate, Tsetdate, Tgettime, Tsettime

## GEMDOS Functions

The GEMDOS functions are published through a global table 'gemdos'

### gemdos.Cconin ()
  Cconin. Read a character from GEMDOS handle 0 (e.g. keyboard) and echo.

  ```
  Results
    1. integer: Character
    2. integer: Scan code (attached to keyboard)
    3. integer: Shift key bits (attached to keyboard and conterm set)
  ```

### gemdos.Cconout (c)
  Cconout. Write a character to GEMDOS handle 1 (e.g. screen).

  ```
  Parameters
    c: integer: character to output
  ```

### gemdos.Cauxin ()
  Cauxin. Read a character from GEMDOS handle 2 (e.g. serial port [^1]).

  ```
  Results
    1. integer: character received
  ```

### gemdos.Cauxout (c)
  Cauxout. Write a character to GEMDOS handle 2 (e.g. serial port [^1]).

  ```
  Parameters
    c: integer: character to send
  ```

### gemdos.Cprnout (c)
  Cprnout. Write a character to GEMDOS handle 3 (e.g. printer).

  ```
  Parameters
    c: integer: character to send
  ```
  ```
  Results
    1. integer: status code
  ```

### gemdos.Crawio (c)
  Crawio. Raw I/O with GEMDOS handle 0 or 1.
  When used in input mode this function returns three values and operates without echo, waiting, or checking for special characters (e.g. ^C). If no character is available then value one is zero. When used in output mode the function returns no values.
  ```
  Parameters
    c: integer: character
       Use A: 255 perform input
       Use B: < 255 Perform output
  ```
  ```
  Results (for Use A only)
    1. integer: Character (zero if no char available)
    2. integer: Scan code
    3. integer: Shift key bits (conterm set)
  ```

### gemdos.Crawcin ()
  Crawcin. Raw input GEMDOS handle 0 (e.g. keyboard).
  Reads a character without echo and does not check for special control keys (e.g. ^C).

  ```
  Results
    1. integer: Character
    2. integer: Scan code (attached to keyboard)
    3. integer: Shift key bits (attached to keyboard and conterm set)
  ```

### gemdos.Cnecin ()
  Cnecin. Read a character from GEMDOS handle 0 (e.g. keyboard).
  Reads a character without echo and checks for special control keys (e.g. ^C).

  ```
  Results
    1. integer: Character
    2. integer: Scan code (attached to keyboard)
    3. integer: Shift key bits (attached to keyboard and conterm set)
  ```

### gemdos.Cconws (s)
  Cconws. Write a string to GEMDOS handle 1 (e.g. screen).
  Checks for special control keys (e.g. ^C).
  ```
  Parameters
    s: string: the string to write
  ```

### gemdos.Cconrs (numchars)
  Cconrs. Read a string from GEMDOS handle 0 (e.g. keyboard).

  ```
  Parameters
    numchars: integer: the maximum number of chars to read (up to 255)
  ```
  ```
  Results
    1. string: the string that was input
  ```

### gemdos.Cconis ()
  Cconis. Check input status of GEMDOS handle 0 (e.g. keyboard).

  ```
  Results
    1. boolean: true if a character is waiting
  ```

### gemdos.Cconos ()
  Cconos. Check output status of GEMDOS handle 1 (e.g. screen).

  ```
  Results
    1. boolean: true if ready to accept a character
  ```

### gemdos.Cprnos ()
  Cprnos. Check output status of GEMDOS handle 3 (e.g. printer).

  ```
  Results
    1. boolean: true if ready to accept a character
  ```

### gemdos.Cauxis ()
  Cauxis. Check input status of GEMDOS handle 2 (e.g. serial port [^1]).

  ```
  Results
    1. boolean: true if a character is waiting
  ```

### gemdos.Cauxos ()
  Cauxos. Check output status of GEMDOS handle 2 (e.g. serial port [^1]).

  ```
  Results
    1. boolean: true if a character can be output
  ```

### gemdos.Dgetdrv ()
  Dgetdrv. Get the default drive.

  ```
  Results
    1. integer: the default drive (A:=0, B:=1, C:=2, ...)
  ```

### gemdos.Dsetdrv (drive)
  Dsetdrv. Set the default drive and obtain available drives.

  ```
  Parameters
    drive: integer: the drive to set as default (A:=0, B:=1, C:=2, ...)
  ```
  ```
  Results
    1. integer: bits indicating available drives  (1:=A, 2:=B, 4:=C, ...)
  ```

### gemdos.Dfree (drive)
  Dfree. Obtain the disk free information.

  ```
  Parameters
    drive: integer: 0 current drive, otherwise A:=1, B:=2, C:=3, ...
  ```
  ```
  Results
    1. integer: on success: number of free clusters
    1. integer: on failure: -ve gemdos error number
    2. integer: on success: total number of clusters
    3. integer: on success: sector size in bytes
    4. integer: on success: cluster size in sectors
  ```

### gemdos.Dcreate (path)
  Dcreate. Create a directory.

  ```
  Parameters
    path: string: the path of the directory
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
  ```

### gemdos.Ddelete (path)
  Ddelete. Delete a directory.

  ```
  Parameters
    path: string: the path of the directory
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
  ```

### gemdos.Dsetpath (path)
  Dsetpath. Set the drive's default path.

  ```
  Parameters
    path: string: the path of the directory
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
  ```

### gemdos.Dgetpath (drive)
  Dgetpath. Get the drive's default path.

  ```
  Parameters
    drive: integer: the drive to check (0=current, A:=1, B:=2, C:=3, ...)
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
    2. string: on success: path
  ```

### gemdos.Fcreate (path, attributes)
  Fcreate. Create a file.

  ```
  Parameters
    path: string: name
    attributes: integer: attributes

  Note: gemdos.const.Fattrib contains attribute constants
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
    2. userdata: on success: file userdata
  ```

### gemdos.Fopen (path, mode)
  Fopen. Open a file.

  ```
  Parameters
    path: string: name
    mode: integer: mode 0 = readonly, 1 = writeonly, 2 = readwrite

  Note: gemdos.const.Fopen contains mode constants.
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
    2. userdata: on success: file userdata
  ```

### gemdos.Freads (file, numbytes)
  Freads. Read bytes from a file into a string.

  ```
  Parameters
    file: userdata: file userdata
    numbytes: integer: number of bytes to read
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes read
    1. integer: on failure:  -ve gemdos error number
    2. string: on success: the bytes read

  Note: Can return less bytes than requested if EOF reached. Will return 0
  bytes and empty string if EOF already reached.
  ```

### gemdos.Fwrites (file, s [, i [, j]])
  Fwrites. Writes bytes from a string into a file.

  ```
  Parameters
    file: userdata: file userdata
    s: string: the string containing the bytes
    i: integer: position of the first byte in the string (default first)
    j: integer: position of the last byte in the string (default last)

  Note: Positive positions count from the start of the string with the first
  byte at position 1. Negative positions count from the end of string with -1
  being the last byte.
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes written
    1. integer: on failure:  -ve gemdos error number
  ```

### gemdos.Freadt (file, imode, numvalues)
  Freadt. Read values from a file into an array table.

  ```
  Parameters
    file: userdata: file
    imode: integer: mode for integer value conversion
    numvalues: integer: number of values to read

  Note: gemdos.const.Imode contains integer mode constants.
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes read from file
    1. integer: on failure:  -ve gemdos error number
    2. table: on success: array of integers holding values read

  Note: Can return less values than requested if EOF reached. Will return 0
  values and empty table if EOF already reached.
  ```

### gemdos.Fwritet (file, imode, t [, i [, j]])
  Fwritet. Writes values from an array table into a file.

  ```
  Parameters
    file: userdata: file
    imode: integer: mode for integer value conversion
    t: table: the table containing the values as integers
    i: integer: position of the first value to write (default first)
    j: integer: position of the last value to write (default last)

  Note: The first value is at position 1. Negative positions count from end
  of the table with -1 being the last value.
  Note: gemdos.const.Imode contains integer mode constants.
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes written
    1. integer: on failure:  -ve gemdos error number
  ```

### gemdos.Fwritei (file, imode, i1, ...)
  Fwritei. Writes one or more values from integers into a file.

  ```
  Parameters
    file: userdata: file userdata
    imode: integer: mode for integer value conversion
    i1: integer: the first value to write
    ...: optional integer(s): the subsequent values

  Note: gemdos.const.Imode contains integer mode constants.
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes written
    1. integer: on failure:  -ve gemdos error number
  ```

### gemdos.Freadi (file, imode, n)
  Freadi. Read one or more values from a file into integers.

  ```
  Parameters
    file: userdata: file userdata
    imode: integer: mode for integer value conversion
    n: integer: the number of values to read (default 1 maximum 16)

  Note: gemdos.const.Imode contains integer mode constants.
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes read (zero or more)
    1. integer: on failure:  -ve gemdos error number
    ...: optional integer(s): the values read

  Note: Can return less values than requested if EOF reached.
  ```

### gemdos.Freadm (file, memory, offset, numbytes)
  Freadm. Read bytes from a file userdata into a memory userdata

  ```
  Parameters
    file: userdata: file userdata
    memory: userdata: memory userdata
    offset: integer: zero based offset into memory area
    numbytes: integer: number of bytes to read
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes read
    1. integer: on failure:  -ve gemdos error number

  Note: Can read less bytes than requested if EOF reached. Will read 0
  bytes if EOF already reached.
  ```

### gemdos.Fwritem (file, memory, offset, numbytes)
  Fwritem. Write bytes from a memory userdata into a file userdata

  ```
  Parameters
    file: userdata: file userdata
    memory: userdata: memory userdata
    offset: integer: zero based offset into memory area
    numbytes: integer: number of bytes to write
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes written
    1. integer: on failure:  -ve gemdos error number
  ```

### gemdos.Fseek (file, relpos, mode)
  Fseek. Seek position within a file.

  ```
  Parameters
    file: userdata: file userdata
    relpos: integer: relative position
    mode: integer: seekmode relative to: 0 = beginning, 1 = current, 2 = end

  Note: gemdos.const.Fseek contains seek mode constants
  ```
  ```
  Results
    1. integer: on success:  >= 0 new absolute offset from start of file
    1. integer: on failure:  -ve gemdos error number
  ```

### gemdos.Fdelete (path)
  Fdelete. Deletes a file

  ```
  Parameters
    path: string: the name of the file to delete
  ```
  ```
  Results
    1. integer: gemdos error code
  ```

### gemdos.Fclose (file)
  Fclose. Closes a file

  ```
  Parameters
    file: userdata: the file to close
  ```
  ```
  Results
    1. integer: gemdos error code
  ```

### gemdos.Frename (oldname, newname)
  Frename. Renames a file

  ```
  Parameters
    oldname: string: the old name
    newname: string: the new name
  ```
  ```
  Results
    1. integer: gemdos error code
  ```

### gemdos.Fattrib (path, flag, attributes)
  Fattrib. Get and set file attributes.

  ```
  Parameters
    path: string: the name
    flag: integer: flag 0 = get attributes 1 = set attributes
    attributes: integer: the attributes to set

  Note: gemdos.const.Fattrib contains attribute constants.
  ```
  ```
  Results
    1. integer: flags or negtive gemdos error code
  ```

### gemdos.Fdatime (file [, y, m, d, h, m, s])
  Fdatime. Set or get file timestamp

  ```
  Parameters
    file: userdata: file userdata
    y: optional integer: year
    m: optional integer: month
    d: optional integer: day
    h: optional integer: hours
    m: optional integer: minutes
    s: optional integer: seconds

  Use A: When file userdata and integers are passed, set the timestamp
  Use B: When only file userdata is passed, get the timestamp
  ```
  ```
  Results
  Use A:
    1. integer: gemdos error code
  Use B:
    1. integer: on success: >= 1980 year
    1. integer: on failure: -ve gemdos error number
    2. integer: on success: month
    3. integer: on success: day
    4. integer: on success: hours
    5. integer: on success: minutes
    6. integer: on success: seconds
  ```

### gemdos.Fdup (stdhandle)
  Fdup. Duplicate standard file handle

  ```
  Parameters
    stdhandle: integer: standard file handle (0 to 3)

  Note: gemdos.const.Fdup contains handle constants
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
    2. userdata: on success: file userdata
  ```

### gemdos.Fforce (file, stdhandle)
  Fforce. Force standard file handle to file handle

  ```
  Parameters
    file: userdata: file userdata
    stdhandle: integer: standard file handle (0 to 3)

  Note: gemdos.const.Fdup contains handle constants
  ```
  ```
  Results
    1. integer: gemdos error code
  ```

### gemdos.Fsfirst (path, attributes)
  Fsfirst. Search first entry in a directory

  ```
  Parameters
    path: string: name
    attributes: integer: attributes

  Note: gemdos.const.Fattrib contains attribute constants
  ```
  ```
  Results
    1. integer: on success: 0
    1. integer: on failure: -ve gemdos error number
    2. userdata: on success: dta userdata
  ```

### gemdos.Fsnext (dta)
  Fsnext. Search next entry in a directory

  ```
  Parameters
    dta: userdata: dta userdata
  ```
  ```
  Results
    1. integer: gemdos error code
  ```

### gemdos.Malloc (n)
  Malloc. Allocate memory

  ```
  Parameters
    n: integer: either -1 or greater than 0

  Use A: -1 obtains the size of largest block of free memory
  Use B: >0 allocates memory
  ```
  ```
  Results
  Use A:
    1. integer: when obtaining the size of largest block of free memory
  Use B:
    1. integer: on success: number of bytes allocated
    1. integer: on failure: gemdos error code
    2. userdata: on success: memory userdata
  ```

### gemdos.Mfree (memory)
  Mfree. Free memory.

  ```
  Input:
    memory: userdata: memory userdata
  ```
  ```
  Results
    1. integer: zero on success or -ve gemdos error number
  ```

### gemdos.Mshrink (memory, keep)
  Mshrink. Shrink memory.

  ```
  Input:
    memory: userdata: memory userdata
    keep: integer: number of bytes to keep allocated
  ```
  ```
  Results
    1. integer: number of bytes kept on success or -ve gemdos error number
  ```

### gemdos.Pterm0 ()
  Pterm0. Terminate with result code zero.

### gemdos.Pterm (n)
  Pterm. Terminate with result code.

  ```
  Parameters
    n: integer: Return status code
  ```

### gemdos.Pexec0 (path, args)
  Pexec0. Execute a program using Pexec mode zero.

  ```
  Parameters
    path: string: Path of the program's executable.
    args: table: Array of arguments to pass to the child
  ```
  ```
  Results
    1. integer: Return code from child
  ```

### gemdos.Sversion ()
  Sversion. Get GEMDOS version number.

  ```
  Results
    1. integer: Major version
    2. integer: Minor version
  ```

### gemdos.SuperPeek (name)
  SuperPeek. Peek a named address in supervisor mode.

  ```
  Parameters
    name: string: the named address

  Recognised names:
  'conterm' : 0x484
  '_hz_200' : 0x4ba
  ```
  ```
  Results
    1. integer: the value
  ```

### gemdos.SuperPoke (name, n)
  SuperPoke. Poke a named address in supervisor mode

  ```
  Parameters
    name: string: the named address
    n: integer: the value to write

  Recognised names:
  'conterm' : 0x484
  ```

### gemdos.Tgetdate ()
  Tgetdate. Get the date.

  ```
  Results
    1. integer: year
    2. integer: month
    3. integer: day
  ```

### gemdos.Tsetdate (year, month, day)
  Tsetdate. Set the date.

  ```
  Parameters
    year: integer: year
    month: integer: month
    day: integer: day
  ```
  ```
  Results
    1. integer: zero on success or -ve gemdos error number
  ```

### gemdos.Tgettime ()
  Tgettime. Get the time.

  ```
  Results
    1. integer: hours
    2. integer: minutes
    3. integer: seconds
  ```

### gemdos.Tsettime (hours, minutes, seconds)
  Tsettime. Set the time.

  ```
  Parameters
    hours: integer: hours
    minutes: integer: minutes
    seconds: integer: seconds
  ```
  ```
  Results
    1. integer: zero on success or -ve gemdos error number
  ```

## File Userdata Functions

File userdata include a __close metamethod so they can be used with the \<close> variable name attribute.

### handle ()
  Get the underlying gemdos handle.

  ```
  Results
    1. integer: underlying gemdos handle
  ```

### detach ()
  Detach the underlying gemdos handle from the userdata. The gemdos handle will no longer be closed when the userdata is closed or garbage collected, and handle() will return zero. Calling gemdos.Fclose on a detached userdata will raise an error. Useful after calling gemdos.Pexec0 with the file userdata redirected to a standard handle as the underlying gemdos handle will be closed when the child exits.

### Self methods
  The following self methods call the equivalent gemdos table file functions:

  reads, writes, readt, writet, readm, writem, readi, writei, seek, close, datime, force. 

## DTA Userdata Functions

### name ()
  Get the name of the file.

  ```
  Results
    1. string: the name of the file 
  ```

### length ()
  Get the length of the file.

  ```
  Results
    1. integer: the length of the file
  ```

### attr ()
  Get the attributes of the file.

  ```
  Results
    1. integer: the attributes of the file
  ```

### datime ()
  Get the datime of the file.

  ```
  Results
    1. integer: year
    2. integer: month
    3. integer: day
    4. integer: hour
    5. integer: minute
    6. integer: second
  ```

### copydta ()
  Copies the DTA into a new Userdata

  ```
  Results
    1. userdata: Copied dta userdata
  ```

### Self method
  The following self method calls the equivalent gemdos table Fsnext function:

  snext.

## Memory Userdata functions

Memory userdata include a __close metamethod so they can be used with the \<close> variable name attribute.

### address ()
  Get the address of the memory.

  ```
  Returns
    1. integer: address
  ```

### size ()
  Get the size of the memory in bytes

  ```
  Returns
    1. integer: the memory size
  ```

### writet (imode, offset, t [, i [, j]])
  Writes integer values from an array table into a memory.

  ```
  Parameters
    imode: integer: mode for integer value conversion
    offset: integer: destination offset into the memory in bytes
    t: table: the table containing the values as integers
    i: optional integer: position of the first value to write (default first)
    j: optional integer: position of the last value to write (default last)

  Note: Positive positions count from the start of the table with the first
  value at position 1. Negative positions count from end of table with -1
  being the last value.
  Note: gemdos.const.Imode contains integer mode constants. For 16 or 32 bit
  modes offset must be even.
  ```
  ```
  Results
    1. integer: the total number of bytes written into the memory
  ```

### readt (imode, offset [, numvalues])
  Read integer values from a memory into an array table.

  ```
  Parameters
    imode: integer: mode for integer value conversion
    offset: integer: source offset in the memory in bytes
    numvalues: optional integer: number of values to read (offset to end if
    missing)

  Note: gemdos.const.Imode contains integer mode constants. For 16 or 32 bit
  modes offset must be even.
  ```
  ```
  Results
    1. integer: the total number of bytes read from the memory
    2. table: an array of integers holding the values read
  ```

### writes (offset, s [, i [, j]])
  Writes bytes from a string into a memory.

  ```
  Parameters
    offset: integer: destination offset into the memory in bytes
    s: string: the string containing the bytes
    i: integer: position of the first byte in the string (default first)
    j: integer: position of the last byte in the string (default last)

  Note: Positive positions count from the start of the string with the first
  byte at position 1. Negative positions count from the end of string with -1
  being the last byte.
  Note: The write does not include a null terminator. Any required null
  terminator must be written explicitly e.g. mud:writes(0, "example\0")
  ```
  ```
  Results
    1. integer: the total number of bytes written into the memory
  ```

### reads (offset [, numbytes])
  Reads bytes from a memory into a string.

  ```
  Parameters
    offset: integer: source offset in the memory in bytes
    numbytes: optional integer: number of bytes to read (offset to end if
    missing)
  ```
  ```
  Results
    1. integer: the total number of bytes read from the memory
    2. string: the bytes read
  ```

### poke (imode, offset, i1, ...)
  Write one or more values from integers into a memory.
  ```
  Parameters
    imode: integer: mode for integer value conversion
    offset: integer: destination offset into the memory in bytes
    i1: integer: the first value
    ...: optional integer(s): the subsequent values

  Note: gemdos.const.Imode contains integer mode constants. For 16 or 32 bit
  modes offset must be even.
  ```
  ```
  Results
    1. integer: the total number of bytes written into the memory
  ```

### peek (imode, offset, n)
  Read one or more values from a memory into integers.
  ```
  Parameters
    imode: integer: mode for integer value conversion
    offset: integer: source offset in the memory in bytes
    n: integer: the number of values to peek (default 1 maximum 16)

  Note: gemdos.const.Imode contains integer mode constants. For 16 or 32 bit
  modes offset must be even.
  ```
  ```
  Results
    1. integer: the first value
    ...: optional integer(s): the subsequent values
  ```

### comparem (offset, other_memory, other_offset, n)
  Compares data between two (possibly the same) memories.

  ```
  Parameters
    offset: integer: offset
    other_memory: userdata: other memory
    other_offset: integer: other offset
    n: integer: length of data in bytes
  ```
  ```
  Results
    1. integer: result of memcmp
  ```

### copym (offset, src_memory, src_offset, n)
  Copies data between two (possibly the same) memories.

  ```
  Parameters
    offset: integer: destination offset
    src_memory: userdata: source memory
    src_offset: integer: source offset
    n: integer: length of data in bytes
  ```
  ```
  Results
    1. integer: number of bytes copied
  ```

### set (offset, n [, numbytes])
  Sets a memory to a byte value.

  ```
  Parameters
    offset: integer: destination offset
    n: integer: byte value
    numbytes: optional integer: number of bytes to set (the default is from
    offset to end)
  ```
  ```
  Results
    1. integer: number of bytes set
  ```

### Self methods
  The following self methods call the equivalent gemdos table memory functions:

  free, shrink.

## Constants
  Constant tables are published through the table 'gemdos.const'.

### gemdos.const.Error
  EINVFN, EFILNF, EPTHNF, ENHNDL, EACCDN, EIHNDL, ENSMEM, EIMBA, EDRIVE, ENMFIL, ERANGE, EINTRN, EPLFMT, EGSBF

### gemdos.const.Fattrib
  none, readonly, hidden, system, volume, dir, archive

### gemdos.const.Fdup
conin, conout, aux, prn

### gemdos.const.Fopen
  readonly, writeonly, readwrite

### gemdos.const.Fseek
  seek_set, seek_cur, seek_end

### gemdos.const.Imode
  s8, u8, s16, u16, s32

  Imode integer modes control conversion between Lua integers
  and File or Memory data. The imode is passed as parameter to file
  writet/readt/writei/readi functions and memory writet/readt/poke/peek
  functions. These modes are native endian (i.e. big endian on Atari ST).

## Utility functions
  Utility functions are published through the table 'gemdos.utility'

### gemdos.utility.esc ()
  Read a key press if available and raise an error if the key pressed
  is the escape key.

  ```
  Parameters
    None
  ```
  ```
  Results
    None
  ```

### gemdos.utility.getenv ([s])
  Gets an environment variable, or a table containing all environment variables.

  ```
  Parameters
  Use A:
    s: string: name of env var to get
  Use B:
    s: nil: get GEMDOS environment into a table
  ```
  ```
  Results
  Use A:
    1. string: on success: env var
    1. nil: on failure: the env var was not found
  Use B:
    1. table: the GEMDOS environment as a table
  ```

### gemdos.utility.version ()
  Gets the tosbindl GEMDOS binding version number.

  ```
  Results
    1. integer: Major version
    2. integer: Minor version
    3. integer: Micro version
  ```

## Version history

### 1.0.0 Initial version
  1) Initial version.

### 1.1.0 Memory and File userdata API changes
  1) File userdata writei and readi support writing and reading multiple values.
  2) Memory userdata poke and peek support writing and reading multiple values.
  3) File userdata writet/readt/writei/readi now support integer modes controlling conversion between Lua integers and file data. Each function takes an extra imode parameter.
  4) Memory userdata writet/readt/poke/peek now support integer modes controlling conversion between Lua integers and memory data. Each function takes an extra imode parameter.

[^1]: The runtime library may automatically redirect handle 2 to the console to provide stderr, so handle 2 may not be attached to the serial port by default.
