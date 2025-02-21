# tosbindl

## Atari ST GEMDOS binding for Lua 5.4.

This is a Lua binding to low level GEMDOS functions. The functions available in TOS 1.X have been implemented. EmuTOS 1.3 and TOS 1.04 have been used during developement, no other TOS versions have been tried or tested.

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

If there is a use case to send a lot of data through the character based output functions e.g. Cauxout, then it's worth checking if the throughput is limited by the interpreter execution speed. If it is then a utility function can be written to loop the output using native C code.

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
  Cconin. Wait for a keyboard character.

  ```
  Results
    1. integer: ASCII
    2. integer: Scan code
    3. integer: Shift key bits (requires conterm)
  ```
### gemdos.Cconout (c)
  Cconout. Send character to console.

  ```
  Parameters
    c: integer: character to output
  ```

### gemdos.Cauxin ()
  Cauxin. Wait for character from RS232.

  ```
  Results
    1. integer: character received
  ```
### gemdos.Cauxout (c)
  Cauxout. Send a character to RS232.

  ```
  Parameters
    c: integer: character to send
  ```
### gemdos.Cprnout (c)
  Cprnout. Sends a character to parallel port

  ```
  Parameters
    c: integer: character to send
  ```
  ```
  Results
    1. integer: status code
  ```
### gemdos.Crawio (c)
  Crawio. Raw I/O to Gemdos handle 0 or 1.

  ```
  Parameters
    c: integer: character
       Use A: 255 perform input
       Use B: < 255 Perform output
  ```
  ```
  Results (for Use A only)
    1. integer: ASCII
    2. integer: Scan code
    3. integer: Shift key bits (requires conterm)
  ```

### gemdos.Crawcin ()
  Cconin. Wait for a keyboard character.

  ```
  Results
    1. integer: ASCII
    2. integer: Scan code
    3. integer: Shift key bits (requires conterm)
  ```

### gemdos.Cnecin ()
  Cnecin. Wait for a keyboard character without echo.

  ```
  Results
    1. integer: ASCII
    2. integer: Scan code
    3. integer: Shift key bits (requires conterm)
  ```

### gemdos.Cconws (s)
  Cconws. Write string to screen.

  ```
  Parameters
    s: string: the string to write
  ```

### gemdos.Cconrs (numchars)
  Cconrs. Read a string from the keyboard.

  ```
  Parameters
    numchars: integer: the maximum number of chars to read (up to 255)
  ```
  ```
  Results
    1. string: the string that was input
  ```

### gemdos.Cconis ()
  Cconis. keyboard input status.

  ```
  Results
    1. boolean: true if a character is waiting
  ```

### gemdos.Cconos ()
  Cconos. screen output status.

  ```
  Results
    1. boolean: true if ready to accept a character
  ```

### gemdos.Cprnos ()
  Cprnos. printer output status.

  ```
  Results
    1. boolean: true if printer is ready to accept a character
  ```

### gemdos.Cauxis ()
  Cauxis. RS232 input status.

  ```
  Results
    1. boolean: true if a character is waiting
  ```

### gemdos.Cauxos ()
  Cauxos. RS232 output status.

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
  Outputs:
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
  
  Note: gemdos.const.Fattrib constains attribute constants
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
    2. userdata: on success: file
    2. string: on failure: gemdos error string
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
    2. string: on success: bytes read

  Note: Can return less bytes than requested if EOF reached. Will return 0
  bytes and empty string if EOF already reached.
  ```
### gemdos.Fwrites (file, s [, i [, j]])
  Fwrites. Writes bytes from a string into a file.

  ```
  Parameters
    file: userdata: file userdata
    s: string: the string containing the bytes
    i: integer: position of the first byte in the string (default is first)
    j: integer: position of the last byte in the string (default is last)

  Note: The first byte is at position 1. Negative positions count from end
  of string with -1 being the last byte.
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes written
    1. integer: on failure:  -ve gemdos error number
  ```
### gemdos.Freadt (file, numbytes)
  Freadt. Read bytes from a file into an array table.

  ```
  Parameters
    file: userdata: file
    numbytes: integer: number of bytes to read
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes read
    1. integer: on failure:  -ve gemdos error number
    2. table: on success: array of integers holding bytes read

  Note: Can return less bytes than requested if EOF reached. Will return 0
  bytes and empty table if EOF already reached.
  ```
### gemdos.Fwritet (file, t [, i [, j]])
  Fwritet. Writes bytes from an array table into a file.

  ```
  Parameters
    file: userdata: file
    t: table: the table containing the bytes as integers
    i: integer: position of the first byte to write (default first)
    j: integer: position of the last byte to write (default last)

  Note: The first byte is at position 1. Negative positions count from end
  of the table with -1 being the last byte.
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes written
    1. integer: on failure:  -ve gemdos error number
  ```
### gemdos.Fwritei (file, n)
  Fwritei. Writes an integer value representing a byte into a file

  ```
  Parameters
    file: userdata: file userdata
    n: integer: the value to write
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes written
    1. integer: on failure:  -ve gemdos error number
  ```
### gemdos.Freadi (file)
  Freadi. Reads a byte from a file into an integer

  ```
  Parameters
    file: userdata: file userdata
  ```
  ```
  Results
    1. integer: on success:  >= 0 number of bytes read (zero or one)
    1. integer: on failure:  -ve gemdos error number
    2. integer: on success: value holding byte read

  Note: Will return 0 bytes and value zero if EOF already reached.
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
  Outputs:
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
  Svesion. Get GEMDOS version number.

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

### handle ()
  Get underlying gemdos handle.

  ```
  Results
    1. integer: underlying gemdos handle
  ```
### Self methods
  The following self methods call the equivalent gemdos table file functions. The file userdata parameter is omitted from the parameter list:
  
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
  The following self method calls the equivalent gemdos table Fsnext function. The DTA userdata parameter is omitted from the parameter list:

  snext.

## Memory Userdata functions

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

### writet (offset, t [, i [, j]])
  Writes bytes from an array table into a memory.

  ```
  Parameters
    offset: integer: destination offset into the memory
    t: table: the table containing the bytes as integers
    i: optional integer: position of the first byte to write (default first)
    j: optional integer: position of the last byte to write (default last)

  Note: The first byte is at position 1. Negative positions count from end
  of table with -1 being the last byte.
  ```
  ```
  Results
    1. integer: number of bytes written into the memory
  ```

### readt (offset [, numbytes])
  Read bytes from a memory into an array table.

  ```
  Parameters
    offset: integer: offset
    numbytes: optional integer: number of bytes to read (offset to end if
    missing)
  ```
  ```
  Results
    1. integer: number of bytes read
    2. table: on array of integers holding bytes read
  ```

### writes (offset, s [, i [, j]])
  Writes bytes from a string into a memory.

  ```
  Parameters
    offset: integer: offset
    s: string: the string containing the bytes
    i: integer: position of the first byte in the string (default first)
    j: integer: position of the last byte in the string (default last)

  Note: The first byte is at position 1. Negative positions count from end
  of string with -1 being the last byte.
  ```
  ```
  Results
    1. integer: the number of bytes written
  ```

### reads (offset [, numbytes])
  Reads bytes from a memory into a string.

  ```
  Parameters
    offset: integer: offset
    numbytes: optional integer: number of bytes to read (offset to end if
    missing)
  ```
  ```
  Results
    1. integer: number of bytes read
    2. string: bytes read
  ```

### poke (offset, n)
  Writes byte from integer into a memory.

  ```
  Parameters
    offset: integer: offset
    n: integer: the byte
  ```
  ```
  Results
    1. integer: the old byte value
  ```

### peek (offset)
  Reads a byte from memory into an integer.

  ```
  Parameters
    offset: integer: offset
  ```
  ```
  Results
    1. integer: the byte value
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
  Sets memory to a byte value.

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
  The following self methods call the equivalent gemdos table memory functions. The memory userdata parameter is omitted from the parameter list:

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
