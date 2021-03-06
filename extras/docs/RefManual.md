# LOGO! PG Library Reference Manual

Rev. Ak

Januar 2021

## Preface
Siemens (TM) LOGO! library for Arduino. 

The library is based on the implementation of [Settimino](http://settimino.sourceforge.net/) and [Snap7](http://snap7.sourceforge.net/). Only _LOGO!_ __0BA4__ to __0BA6__ are supported via the serial programming interface.

## Used and Related Publications

Refer to the following publications for details about the application programming interface:
  * [Settimino Reference manual](http://settimino.sourceforge.net/) published by Davide Nardella
  * [Snap7 Reference manual](http://snap7.sourceforge.net/) published by Davide Nardella

Refer to the following publication for details about the protocol using the PG-Interface:
  * [LOGO! PG Protocol Reference Guide](http://github.com/brickpool/logo/wiki/PG-Protocol) published by J. Schneider

## Contents

  * [LogoClient syntax](#logoclient-syntax)
    * [Administrative functions](#administrative-functions)
      * [Connect()](#connect)
      * [ConnectTo()](#connect-to)
      * [SetConnectionParams()](#set-connection-params)
      * [SetConnectionType()](#set-connection-type)
      * [Disconnect()](#disconnect)
    * [Base Data I/O functions](#base-data-functions)
      * [ReadArea()](#read-area)
    * [Block oriented functions](#block-functions)
      * [GetDBSize()](#get-db-size)
      * [DBGet()](#db-get)
    * [Date/Time functions](#datetime-functions)
      * [GetPlcDateTime()](#get-plc-datetime)
      * [SetPlcDateTime()](#set-plc-datetime)
      * [SetPlcSystemDateTime()](#set-plc-system-datetime)
    * [System info functions](#systeminfo-functions)
      * [GetOrderCode()](#get-order-code)
      * [GetPDULength()](#get-pdu-length)
    * [PLC control functions](#control-functions)
      * [PlcStart()](#plc-start)
      * [PlcStop()](#plc-stop)
      * [GetPlcStatus()](#get-plc-status)
    * [Security functions](#security-functions)
      * [SetSessionPassword()](#set-session-password)
      * [ClearSessionPassword()](#clear-session-password)
      * [GetProtection()](#get-protection)
    * [Properties](#properties)
      * [LastError](#last-error)
      * [ErrorText](#error-text)
      * [RecvTimeout](#recv-timeout)
      * [Connected](#connected)
  * [Additional description](#additional-description)
    * [Memory models](#memory-models)
    * [Error codes](#error-codes)


----------

# LogoClient Syntax

ARDUINO has not a multithreaded environment and we can only use one LogoClient instance.

## <a name="administrative-functions"></a>API - Administrative functions

### <a name="connect"></a>LogoClient.Connect()
Connects the Client to the _LOGO!_ with the parameters specified in the previous call of `ConnectTo()` or `SetConnectionParams()`.

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="connect-to"></a>LogoClient.ConnectTo(Stream \*Interface)
Connects the Client to the hardware connected via the serial port.

 - `Interface` Stream object for example "Serial"

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="set-connection-params"></a>LogoClient.SetConnectionParams(Stream \*Interface)
Links the Client to a stream object.

 - `Interface` Stream object for example "Serial"

### <a name="set-connection-type"></a>LogoClient.SetConnectionType(ConnectionType)
Sets the connection resource type, i.e the way in which the Clients connects to the _LOGO!_ device.

 - `ConnectionType`

Connection Type | Value | Description
--- | --- | --- 
`PG` | `0x01` | PG

### <a name="disconnect"></a>LogoClient.Disconnect()
Disconnects "gracefully" the Client from the _LOGO!_ device.

## <a name="base-data-functions"></a>API - Base Data I/O functions

### <a name="read-area"></a>LogoClient.ReadArea(int Area, word DBNumber, word Start, word Amount, void \*ptrData)
This is the main function to read data from a _LOGO!_ device. With it Inputs, Outputs and Flags can be read.

 - `Area` Area identifier, must always be `LogoAreaDB`
 - `DBNumber` DB number if area = `LogoAreaDB`, must always be `1`
 - `Start` Offset to start
 - `Amount` Amount of __words__ to read
 - `ptrData` Pointer to memory area

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

## <a name="block-functions"></a>API - Block oriented functions

### <a name="get-db-size"></a>LogoClient.GetDBSize(word DBNumber, size_t *Size)
Returns the size of a given DB Number. This function is useful to upload an entire DB.

 - `DBNumber` DB number if area = `LogoAreaDB`, must always be `1`
 - `Size` DB Size in bytes

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="db-get"></a>LogoClient.DBGet(word DBNumber, void \*ptrData, size_t *Size)
This is a wrapper function of ReadArea(). It simply internally calls ReadArea() with `Area` = `LogoAreaDB`, `Start` = `0` and `Amount` = GetDBSize().

 - `DBNumber` DB number if area = `LogoAreaDB`, must always be `1`
 - `ptrData` Pointer to memory area
 - `Size` In: Buffer size available; Out: Bytes Uploaded

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

__Remarks:__
This function first gathers the DB size via GetDBSize then calls ReadArea if the Buffer size is greater than the DB size, otherwise returns an error.

## <a name="datetime-functions"></a>API - Date/Time functions

### <a name="get-plc-datetime"></a>LogoClient.GetPlcDateTime(TimeElements \*dateTime)
Reads _LOGO!_ date and time.

 - `dateTime`, see below

The `dateTime` argument is a _C_ structure, defined in the Time Library:
```
typedef unsigned long time_t;

typedef struct {
  uint8_t Second; // seconds after the minute   0-59 
  uint8_t Minute; // minutes after the hour     0-59
  uint8_t Hour;   // hours since midnight       0-23
  uint8_t Wday;   // day of week, sunday is day 1 
  uint8_t Day;    // day of the month           1-31
  uint8_t Month;  // months                     1-12
  uint8_t Year;   // offset from 1970;
} TimeElements;
```
__Remarks:__
The Time library includes low-level conversion functions between system time and individual time elements. The function returns 0 seconds for each call.

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="set-plc-datetime"></a>LogoClient.SetPlcDateTime(TimeElements dateTime)
Sets the _LOGO!_ date and time.

 - `dateTime` a element with the _C_ structure `TimeElements`

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

__Remarks:__
This function is subject to the security level set.

### <a name="set-plc-system-datetime"></a>LogoClient.SetPlcSystemDateTime()
Sets the _LOGO!_ date and time in accord to the _DTE_ system time. The internal system time is based on the standard Unix time (number of seconds since Jan 1, 1970). 

__Note:__ The system time begins at zero when the sketch starts. The internal time can be synchronized to an external time source using the Time library.

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

__Remarks:__
This function is subject to the security level set.

## <a name="systeminfo-functions"></a>API - System info functions

### <a name="get-order-code"></a>LogoClient.GetOrderCode(TOrderCode \*Info)
Gets CPU order code and version info.

 - `Info`, see below

The `Info` argument is an _C_ structure defined in the library:
```
typedef struct {
  char Code[19];  // Order Code
  byte V1;        // Version V1.V2.V3
  byte V2;
  byte V3;
} TOrderCode;
```

The Order code is a null terminated _C_ string such as `6ED1052-xxx00-0BA6`.
Please note, for the _LOGO!_ __0BA4__ device and in operation mode _RUN_, the firmware can not be read out (V1 to V3 have a value of `0`).

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="get-pdu-length"></a>LogoClient.GetPDULength()
Returns the PDU length negotiated between the client and the _LOGO!_ device during the connection or `0` on error.

__Note:__ All data transfer functions handle this information by themselves and split the telegrams automatically if needed.

## <a name="control-functions"></a>API - PLC control functions

### <a name="plc-start"></a>LogoClient.PlcStart()
Puts the _LOGO!_ device in operation mode _RUN_.

Returns a `0` on success and when the _LOGO!_ device is already running, otherwise an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="plc-stop"></a>LogoClient.PlcStop()
Puts the _LOGO!_ device in operation mode _STOP_.

Returns a `0` on success and when the _LOGO!_ device is already stopped, otherwise an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="get-plc-status"></a>LogoClient.GetPlcStatus(int \*Status)
Returns the CPU status (running/stopped) into `Status` reference.

 - `Status`, see below

Status values:

Const | Value | Meaning
--- | --- | --- 
LogoCpuStatusUnknown | 0x00 | The CPU status is unknown.
LogoCpuStatusRun | 0x08 | The CPU is running.
LogoCpuStatusStop | 0x04 | The CPU is stopped.

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

## <a name="security-functions"></a>API - Security functions
The password protects the circuit program in _LOGO!_. Editing values and parameters, or viewing the circuit program in _LOGO!_, or uploading the circuit program from _LOGO!_ is only possible after you have entered the password. 

__Note:__ Depending on the protection level, each library function is checked before the command can be executed. Regardless of the protection level, diagnostic functions and reading of the variable table are possible. 

### <a name="set-session-password"></a>LogoClient.SetSessionPassword(char \*password)
Send the password to the _LOGO!_ to meet its security level.

 - `password` Password

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

A `password` accepted by a _LOGO!_ is an 10 chars string, a longer password will be trimmed. Only upper case charaters from `A` to `Z` can be used for the `password`.

### <a name="clear-session-password"></a>LogoClient.ClearSessionPassword()
Clears the password set for the current session.

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

### <a name="get-protection"></a>LogoClient.GetProtection(TProtection \*Protection)
Gets the CPU protection level info.

 - `Protection`, see below

The `Protection` argument is an _C_ structure defined in the library:
```
typedef struct {
  byte sch_schal;
  byte sch_par;
  byte sch_rel;
  byte bart_sch;
  byte anl_sch;
} TProtection;
```

Returns a `0` on success or an `Error` code (see Errors Code List [below](#error-codes)).

Field Values:

Protection  | Values | Description
--- | --- | --- 
`sch_schal` | 1,2,3 | Protection level set by the operating mode switch (1:no protection, 2:read protection, 3:read/write protection)
`sch_par` | 0,1,2,3 | Parameterized protection level (1:full access, 2:read protection, 3:read/write protection, 0:no password, undefined or cannot be determined)
`sch_rel` | 0,1,2,3 | Valid protection level of the CPU (level 1-3, 0: cannot be determined)
`bart_sch` | 1,2,3 | Position of the operating mode switch (1:RUN, 2:RUN_P, 3:STOP, 0:undefined or cannot be determined)
`anl_sch` | 0 | Position of the startup mode switch (0:undefined, does not exist or cannot be determined)

__Remarks:__  
The _LOGO!_ does not use protection levels like a S7, but protection level `1` (no protection) to `3` (read/write protection) are comparable (value `sch_rel`).

The _LOGO!_ configuration can only be read out in the operating mode _STOP_ (value `bart_sch`).

There is no startup mode switch for the _LOGO!_. Therefore, the value for `anl_sch` is always `0`.

Further information about the `SFC 51` system function can be found in the _SIMATIC S7_ Online Help.

## <a name="properties"></a>API - Properties

### <a name="last-error"></a>LogoClient.LastError
Returns the last job result.

### <a name="error-text"></a>LogoClient.ErrorText(int Error)
Returns a textual explanation of Error.

### <a name="recv-timeout"></a>LogoClient.RecvTimeout
Returns the timeout value.

### <a name="connected"></a>LogoClient.Connected
Returns the connection status.


----------

# Additional description

## Memory models
To save memory we can define different memory models: __Small__, __Normal__ and __Extended__

By default library is released as Extended.

These directives are visible from your sketch:

`#define _SMALL`<br />
or<br />
`#define _NORMAL`<br />
or<br />
`#define _EXTENDED`


## Error codes

### Severe Error codes
Severe errors, the Client should be disconnected:

Mnemonic | HEX | Meaning
--- | --- | ---
`errStreamConnectionFailed` | `0x0001` | Stream Connection error
`errStreamConnectionReset` | `0x0002` | Connection reset by the peer
`errStreamDataRecvTout` | `0x0003` | A timeout occurred waiting a reply
`errStreamDataSend` | `0x0004` | Stream error while sending the data
`errStreamDataRecv` | `0x0005` | Stream error while receiving the data
`errPGConnect` | `0x0006` | _LOGO!_ connection failed
`errPGNegotiatingPDU` | `0x0007` | _LOGO!_ negotiation failed
`errPGInvalidPDU` | `0x0008` | Malformed Telegram supplied

### Device Error codes
_LOGO!_ device errors such as DB not found or address beyond the limit:

Mnemonic | HEX | Meaning
--- | --- | ---
`errCliInvalidPDU` | `0x0100` | Invalid Telegram received
`errCliSendingPDU` | `0x0200` | Error sending a Telegram
`errCliDataRead` | `0x0300` | Error during data read
`errCliDataWrite` | `0x0400` | Error during data write
`errCliFunction` | `0x0500` | The _LOGO!_ reported an error for this function
`errCliBufferTooSmall` | `0x0600` | The supplied buffer is too small

