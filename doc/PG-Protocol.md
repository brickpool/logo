# LOGO! PG Protocol Reference Guide
Rev. Ba

February 2018

## Preface
This guide is written for persons who will communicate with a Siemens (TM) LOGO! 0BA4, 0BA5 or 0BA6 using the PG Interface. The PG Interface used an undocumented protocol for program loading, diagnostics, etc. which is referred to here as PG protocol. This guide describes how messages are constructed, and how transactions take place by using the PG protocol. 

Siemens and LOGO! are registered trademarks of Siemens AG.

## Used and Related Publications
This reference guide cite and uses passages of text from the following documentation:
  * [Modicon Modbus Protocol Reference Guide](modbus.org/docs/PI_MBUS_300.pdf) published by Modbus Organization, Inc.

Refer to the following publication for details about well known Monitoring commands:
  * SNATAX @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") data monitoring functions (0BA6)
  * cacalderon @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") data monitoring functions (0BA5) and LOGO DE-9 cable pin-out
  * ask @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/21314/?page=0&pageSize=10 "Logo! Datenlogger") data monitoring python script (0BA4)
  * Superbrudi @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/52023/?page=0&pageSize=10 "Excel Logo Logger Overview") data monitoring excel VBA script (0BA5 and 0BA6)
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") low latency data monitoring (@post 29)

Refer to the following publications for details about the related communications for Clock/RTC, Password control functions:
  * chengrui @ [http://www.ad.siemens.com.cn](http://www.ad.siemens.com.cn/club/bbs/post.aspx?a_id=637887&b_id=3 "Siemens s7-200 and LOGO communication") Clock control function
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") Password control function (@post 23)

Refer to the following publication for details about the LOGO address layout:
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") decodes most of the functions and the 0BA5 data address space (@post 42)

Refer to the following publication for details about the RS232 specifications and use cases:
  * [RS232 Specifications and standard](https://www.lammertbies.nl/comm/info/RS-232_specs.html) by Lammert Bies
  * [LOGO! Interface](https://www.elektormagazine.com/magazine/elektor-199907/34458) by W. Kriegmaier Elektor 7/1999 page 55
  * [Get power out of PC RS-232 port](http://www.epanorama.net/circuits/rspower.html) by Tomi Engdahl
  * [RS-232 vs. TTL Serial Communication](https://www.sparkfun.com/tutorials/215) by SparkFun

## Contents
  * [Chapter 1 - PG Protocol](#chapter-1---pg-protocol)
    * [Introducing PG Protocol](#introducing-pg-protocol)
    * [The Serial Transmission Mode](#the-serial-transmission-mode)
    * [The Message Frame](#the-message-frame)
    * [Error Checking Methods](#error-checking-methods)
  * [Chapter 2 - Data Commands](#chapter-2---data-commands)
    * [Data Commands Supported by LOGO](#data-commands-supported-by-logo)
  * [Chapter 3 - Control Commands](#chapter-3---control-commands)
    * [Control Commands Supported by LOGO](#control-commands-supported-by-logo)
  * [Chapter 4 - Connection Commands](#chapter-4---connection-commands)
    * [Hello Request 21](#hello-request-21)
  * [Chapter 5 - Errors and Confirmations](#chapter-5---errors-and-confirmations)
    * [Confirmed Codes Used by LOGO](#confirmed-codes-used-by-logo)
    * [Acknowledge Response 06](#acknowledge-response-06)
    * [Exception Responses 15](#exception-responses-15)
  * [Appendix A - Application Examples](#appendix-a---application-examples)

# Chapter 1 - PG Protocol

## Introducing PG Protocol
The common language used by all LOGO! devices is the PG protocol. This protocol defines a message structure that controllers will recognize and use, regardless of the type of networks over which they communicate.

Standard Interface cable for LOGO! 0BA0 to 0BA6 controllers use an [5-wire RS–232C](https://en.wikipedia.org/wiki/RS-232#3-wire_and_5-wire_RS-232) compatible serial interface that defines connector pin-outs, cabling, signal levels, transmission baud rates, and parity checking.

The Siemens Software LOGO! Comfort communicate using a _master–slave technique_, in which only a personal computer called _DTE_ (data terminal equipment) can initiate transactions (called _queries_). The LOGO! device called _DCE_ (data communication equipment) respond by supplying the requested data to the DTE, or by taking the action requested in the query.

### The Query–Response Cycle

Direction | Query message from DTE | Response message from DCE
--- | --- | ---
PC->LOGO | Command \[data\] | 
LOGO->PC | | Confirmation \[data\]
PC->LOGO | Command \[data\] | 
LOGO->PC | | Confirmation \[data\]
... | ... | ...
>Figure DTE-DCE Query–Response Cycle

__The Query__: The command code in the query tells the LOGO device what kind of action to perform. The data bytes contain any additional information that the LOGO will need to perform the function. 

For example, command code `05` will query the LOGO to read a memory block and respond the content. The data field must contain the information telling the LOGO which address to start at and how many bytes to read.

__The Response__: If the LOGO makes a normal response, the first byte in the response contains an positive confirmation code. The confirmation code allows the DTE to check that the message contents are valid. The following data bytes contain the data collected by the LOGO, such a value or status. If an error occurs, the LOGO response is an error response, followed by on byte, which contain a exception code that describes the error.

## The Serial Transmission Mode

When the PC communicate to the LOGO controller with using the PG protocol, each 8–bit byte in a message contains hexadecimal characters. The main advantage of using hexadecimal characters is that its greater character density allows better data throughput than for example ASCII for the same baud rate. Each message must be transmitted in a continuous stream. 

The specification for each communication via the PG Interface:

### Cable / Connectors:
- 5-wire TIA-574
- PC (DTE Connector) DE-9 male
- LOGO (DCE Connector) DE-9 female

### Pinout:
- [x] RxD Receive Data; DTE in direction; pin 2
- [x] TxD Transmit Data; DTE out direction; pin 3
- [x] DTR Data Terminal Ready; DTE out direction; pin 4 \* )
- [x] GND Ground; pin 5
- [ ] RTS Request to Send; DTE out direction; pin 7 \* )

>\* ) DTS and/or RTS are used to power the plug electronics

### Baud rate / Bits per Byte:
- 9600 baud rate
- 1 start bit
- 8 data bits, least significant bit sent first
- 1 bit for even parity
- 1 stop bit
- DTS (or RTS) set to high (>= 5V)

### Coding System:
- 8–bit binary, hexadecimal 0–9, A–F

## The Message Frame
In either of the two transmission modes (query or request), all data are placed by the transmitting device into a message that has a known beginning and ending point. This allows receiving devices to begin at the start of the message, read the address portion and determine which data is addressed, and to know when the message is completed. Partial messages can be detected and errors can be set as a result.

Start | Content
--- | ---
1 Byte | n Bytes
Query/Response | Optional
>Figure Message Frame

The next two _Figure_ shows an example of a DTE query message and a LOGO normal response. Both examples show the field contents in hexadecimal, and also show how a message framed.

The DTE query is a data monitoring request to the LOGO device. The message requests a data block for monitoring. 

Field Name | Code \(hex\) | Meaning
--- | --- | ---
command | `55` | control
function | `13 13` | data monitoring request
data | `00` | continuously requested
trailer | `aa` | end delimiter
>Figure DTE query message

The LOGO response with an acknowledgment, indicating this is a normal response. The _byte count_ field specifies how many bytes are being returned.

Field Name | Code \(hex\) | Meaning
--- | --- | ---
confirmation | `06` | acknowledgment
command | `55` | control
function | `11 11` | data monitoring response
byte count | `40` | data length 64 (dec) bytes
data | `00 7f .. 00` | data monitoring block
trailer | `aa` | end delimiter
>Figure LOGO response message

### Command Query
All commands are packed into a message by the DTE sending device, which have a known structure. Valid command codes are in the range of `01` to `55` hexadecimal. Some of these codes apply to all LOGO controllers, while some codes apply only to certain models. Current codes are described in the following chapters.

When a message is sent from a DTE to a LOGO device the command code field tells the LOGO what kind of action to perform. Examples are to read the RUN/STOP operation mode; to read the data contents; to read the diagnostic status of the LOGO; to write some designated data; or to allow loading, recording, or verifying the program within the LOGO. 

Start | Content
--- | --- 
1 Byte | n Bytes
Command Code | Optional
>Figure Query Message Frame

The content field can be nonexistent (length of zero) in certain kinds of messages.

### Confirmation Response
When the LOGO responds to the DTE, it uses the confirmation code to indicate either a normal (error–free) response or that some kind of error occurred (called an exception response). For a normal response, the LOGO simply confirm the message with an acknowledgment. For an exception response, the LOGO returns an negative-acknowledgement with an exception code.

In addition to the error confirmation code for an exception response, the LOGO places a unique code into the data field of the response message. This tells the DTE what kind of error occurred, or the reason for the exception. The DTE application program has the responsibility of handling exception responses. Typical processes are to post subsequent retries of the message, to try diagnostic messages to the LOGO, and to notify the operator.

Start | Content
--- | ---
1 Byte | n Bytes
Confirmation Code | Optional
>Figure Response Message Frame

The content field can be nonexistent (length of zero) in certain kinds of messages.  

### How Numerical Values are Expressed
Unless specified otherwise, numerical values (such as addresses, codes, or data) are expressed as hexadecimal values in the text and in the message fields of the figures. 

### Content Field
The content field of a message sent from a DTE to a LOGO device may contain additional information, depending on the query. The content field is constructed using sets of two hexadecimal digits, in the range of `00` to `FF` hexadecimal.

If no error occurs, the content field of a response from the LOGO to the DTE contains the content requested. If an error occurs, the field contains an exception code that the PDE application can use to determine the next action to be taken.

### How a Function Field is Handled
If a function code field exists, then this consists of two bytes with same value. Valid function codes are in the range of `11 11` to `18 18` hexadecimal. Functions that are inserted into a message without addressing something in the memory use a terminator (called end delimiter) `AA`. The allowable bytes transmitted for the data content are hexadecimal `00` to `FF` (including `AA`).

### How a Address Field is Handled
The address field of a message frame contains two bytes (0BA4, 0BA5) or four bytes (0BA6). Valid device addresses or memory addresses depends on the LOGO controller. A DTE addresses the memory by placing the address in the address field of the message. When the LOGO sends its response, it echos the address in the address field of the response to let the DTE know which address is requested.

### How to Use the Byte Count Field
If you need to transfer more than one data byte from the DTE to the LOGO device, then you must use a Byte Count value that indicates the number of bytes in your message data. When storing responses in buffers, you should use the Byte Count value, which is the number of bytes in your message data. The value refers to the following field contents.

For example, if the DTE requests the LOGO to read a group of data (e.g. function code `05`), the content specifies the starting address and how many bytes are to be read. If the DTE writes to a group of data to the LOGO (e.g. function code `04`), the content specifies the starting address, the count of data bytes to follow in the data field, and the data to be written into the registers. 

### How a Data Field is Handled
The data field is constructed using sets of two hexadecimal digits, in the range of `00` to `FF` hexadecimal.

### How Characters are Transmitted Serially
When messages are transmitted via the PG Interface, each byte is sent in this order (left to right):

  _Least Significant Bit (LSB) . . . Most Significant Bit (MSB)_

As a reminder, the communication takes place with parity check. The bit sequence is:

```
Start | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | Par | Stop
```
>Figure Bit Order

## Error Checking Methods
The PG serial communication use two kinds of error checking. Parity checking (even) is applied to each character. Frame checking (XOR) is applied to some kind of messages. Both the character check and message frame check are generated by the device and applied to the message contents before transmission. The receiving device checks each character and the entire message frame during the reception.

The DTE is configured by the user to wait for a predetermined timeout interval before aborting the transaction. This interval is set to be long enough for any
LOGO to respond normally (in general between 75 and 600 ms). If the LOGO detects a transmission error, the message will be acted upon with an exception response. When the timeout will expire the DTE’s program has to handle these state.

### Parity Checking
Users must configure controllers for Even Parity checking. Since Even Parity is specified, the quantity of 1 bits will be counted in the data portion over all eight data bits. The parity bit will then be set to a 0 or 1 to result in an Even total of 1 bits. 

For example, these eight data bits are contained:

```
1100 0101
```

The total quantity of 1 bits in the frame is four. If Even Parity is used, the frame’s parity bit will be a 0, making the total quantity of 1 bits still an even number (four). If Odd Parity is used, the parity bit will be a 1, making an odd quantity (five).

When the message is transmitted, the parity bit is calculated and applied to the frame of each byte. The receiving device counts the quantity of 1 bits and
sets an error if they are not the same as configured for that device (DTE and DCE must be configured to use the even parity check method).

Note that parity checking can only detect an error if an odd number of bits are picked up or dropped in a character frame during transmission. 

### LRC/CRC/XOR Checking
For read block commands `02`, the LOGO response messages include an error–checking field that is based on a Cyclical Redundancy Check (or CRC variant) method. The CRC field checks the contents of the entire data. It is applied regardless of any parity check method used for the individual characters of the message. 

The CRC field is one byte, containing an 8–bit binary value. The CRC value is calculated by the transmitting device, which appends the CRC to the message. The receiving DTE program must calculate the CRC during receipt of the message, and compares the calculated value to the actual value it received in the CRC field. If the two values are not equal, an error results.

>__Note:__ The application of CRC in response message frames are not confirmed yet.


# Chapter 2 - Data Commands

## Message Frame

Command | Address | Content
--- | --- | --- | ---
1 byte | 2 or 4 bytes | n Bytes
Command Code | 16 or 32bit Address | Optional
>Figure Data Command Frame

The content field is usually required. It is not available (length of zero) only for the read byte command `02`. The format depends on the command codes. 

## Data Commands Supported by LOGO
The listing below shows the data command codes supported by LOGO. Codes are listed in hexadecimal.

_Y_ indicates that the command is supported. _N_ indicates that it is not supported.

Code | Name | 0BA4 | 0BA5 | 0BA6
--- | --- | --- | --- | ---
`01` | Write Byte Command | Y | Y | Y
`02` | Read Byte Command | Y | Y | Y
`04` | Write Block Command | Y | Y | Y
`05` | Read Block Command | Y | Y | Y

## Write Byte Command `01`

### Description
The command writes a byte value to the specified Memory address of the LOGO device. 

### Query

Command | Address | Data
--- | --- | ---
1 byte | 2 or 4 bytes | 1 byte
Command Code `01` | 16/32bit Address | Data Byte
>Figure Write Byte Query Message

## Read Byte Command `02`

### Description
There is a simple message to writing a single byte.

### Query

Command | Address
--- | ---
1 byte | 2 or 4 bytes
Command Code `01` | 16/32bit Address
>Figure Read Byte Query Message

## Write Block Command `04`

### Description
Writes data contents of bytes into the Memory of the LOGO device. 

### Query
The command contains the standard fields of command code, address scheme and byte count. The rest of the command specifies the group of bytes to be written into the LOGO device. 

Command | Address | Byte Count | Data
--- | --- | --- | ---
1 byte | 2 or 4 bytes | 1 byte | n Bytes
Command Code | 16/32bit Address | Number of Bytes | Data Content
>Figure Write Block Query Message

## Read Block Command `05`

### Description
Reads the binary contents in bytes from the LOGO device.

### Query
The query message indicates the start address and the number of data bytes to be read. 

Command | Address | Byte Count
--- | --- | --- | ---
1 byte | 2 or 4 bytes | 1 byte
Command Code | 16/32bit Address | Number of Bytes
>Figure Read Block Query Message


# Chapter 3 - Control Commands

## Message Frame

Command | Function | Content
--- | --- | ---
1 byte | n Bytes
Command Code | Function Field | Optional
>Figure Control Command Frame

The content field can be nonexistent (length of zero) in certain kinds of messages. The content of a control message sent from a DTE to a LOGO device may contains additional information that the LOGO must use to perform the action defined by the command code.

## Control Commands Supported by LOGO

The listing below shows the function codes for the control command `55` supported by LOGO. Codes are listed in hexadecimal.

_Y_ indicates that the command is supported. _N_ indicates that it is not supported.

Command | Function | Name | 0BA4 | 0BA5 | 0BA6
--- | --- | --- | --- | --- | ---
`55` | `11` | Data Response Function 1) | Y | Y | Y
`55` | `12` | Stop Operating Function | Y | Y | Y
`55` | `13` | Data Monitoring Function 2) | Y | Y | Y
`55` | `17` | Operation Mode | Y | Y | Y
`55` | `18` | Start Operating Function | Y | Y | Y

>__Notes:__
>
>1) LOGO Response of function `13`
>
>2) DTE Query for function `11`

## Data Monitoring `55 11` and `55 13`

### Description
tbd

LOGO! response with ACK (`06`) followed by data (length depends on device type) or NAK (`15`) followed by an exception code. 

### Query

Command | Function | Data \1) | End
--- | --- | --- | ---
1 Byte | 2 Bytes | 1 Byte | 1 Byte
Command Code | Function Code | Data Content | End Delimiter
>Figure Function Message Frame

Here is an example of a request to read the monitoring data from LOGO device:

```
55  13 13  00  aa
```
>Figure Example Data Monitoring Query

### Response

Command | Function | Byte Count | Data
--- | --- | --- | ---
1 Byte | 2 Bytes | 1 Byte | n Bytes
Command Code | Function Code | Number of Bytes | Data Content
>Figure Function Message with Content

Here is an example of a response to the query above:

```
:06
:55:11:11:40:00:7f:66:11:2a:00:80:01:10:00:00:00
:00:00:00:00:00:00:00:00:00:00:a8:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:aa
```
>Figure Example 0BA4 Monitoring Response


```
:06
:55:11:11:4a:00:b7:c4:19:2c:00:10:84:6b:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:aa
```
>Figure Example 0BA6 Monitoring Response

__Notes:__
Data length (incl. end delimiter `AA`)
- 0BA4 = 68 bytes
- 0BA5 = 70 bytes
- 0BA6 = 80 bytes

The examples above shows how the byte count field is implemented in a LOGO data monitoring response.

## Stop Operating `55 12`

Send to LOGO! to change the operation mode to _STOP_:

command | request | response | description
--- | --- | --- | ---
set operation mode STOP | `55 :12:12 :aa` | `06` | LOGO! has successfully executed the command

## Operating Mode `55 17`
Send to LOGO! to ask the Operation Mode:

command | request | response | description
--- | --- | --- | ---
ask operation mode | `55 :17:17 :aa` | `06 :01` | LOGO! in RUN mode
ask operation mode | `55 :17:17 :aa` | `06 :42` | LOGO! in STOP mode

## Start Operating `55 18`

Send to LOGO! to change the operation mode _RUN_:

command | request | response | description
--- | --- | --- | ---
set operation mode RUN | `55 :18:18 :aa` | `06` | LOGO! has successfully executed the command


# Chapter 4 - Connection Commands

## Connection Message Frame
For example, in a request from the DTE to the LOGO to respond with his serial no (function code `21` hexadecimal), the LOGO does not require any additional information. The command code alone specifies the action.

## Connection Codes Supported by LOGO
The listing below shows the connection command codes supported by LOGO. Codes are listed in hexadecimal.

_Y_ indicates that the command is supported. _N_ indicates that it is not supported.

Code | Name | 0BA4 | 0BA5 | 0BA6
--- | --- | --- | --- | ---
`21` | Connection Request | N | Y | Y

## Hello Request `21`
Send to LOGO a _hello request_ `21`:

LOGO | command | request | response | description
--- | --- | --- | --- | ---
0BA4 | hello request | `21` | _n/a_ | no response
0BA5 | hello request | `21` | `06 03 21 42` | hello response 42 (LOGO! 0BA5)
0BA6 | hello request | `21` | `06 03 21 43` | hello response 43 (LOGO! 0BA6.Standard)
0BA6 | hello request | `21` | `06 03 21 44` | hello response 44 (LOGO! 0BA6)
>Figure _Hello Request_


# Chapter 5 - Errors and Confirmations

## Confirmed Codes Used by LOGO
The listing below shows the confirmation response code used by LOGO. Codes are listed in hexadecimal.

_Y_ indicates that the confirmation is supported. _N_ indicates that it is not supported.

Code | Name | 0BA4 | 0BA5 | 0BA6
--- | --- | --- | --- | ---
`06` | Acknowledge Response | Y | Y | Y
`15` | Exception Responses | Y | Y | Y

## Acknowledge Response `06`
LOGO! confirmation code `06` (ACK), followed by zero or n bytes of data.

Example:
```
Query
55 17 17 aa

Response
06 42
```
>Figure DTE Query and LOGO _Confirmation Response_

## Exception Responses `15`
LOGO confirmation code `15` (NOK), followed by an exception code (1 byte). The exception code can be a transport or protocol error.

The next Figure shows an example of a DTE query and LOGO exception response. The field examples are shown in hexadecimal. 

```
Query
XX XX XX

Response
15 05
```
>Figure DTE Query and LOGO _Exception Response_

## Exception Codes
Type | Name | Meaning
--- | --- | ---
`01` | DEVICE BUSY | LOGO can not accept a telegram
`02` | DEVICE TIMEOUT | Resource unavailable, the second cycle of the write operation timed out
`03` | ILLEGAL ACCESS | Illegal access, read across the border
`04` | PARITY ERROR | parity, overflow or telegram error
`05` | UNKNOWN COMMAND | Unknown command, this mode is not supported
`06` | XOR INCORRECT | XOR-check incorrect
`07` | SIMULATION ERROR | Faulty on simulation, RUN is not supported in this mode


# Appendix A - Application Examples

## Read Revision
Read the revision byte from the LOGO address `1f 02`:

command | query | response | description
--- | --- | --- | ---
read byte | `02 1f 02` | `06 03  1f 02  40` | connection established to 40 (LOGO! 0BA4)
read byte | `02 1f 02` | `06 03  00 ff 1f 02  43` | connection established to 43 (LOGO! 0BA6)
>Figure _Read Revision_

## Read Clock
Read commands for RTC:
1. Device status inquiry
2. Write byte `00` to Address \[00 FF\] 44 00 to initialize reading
3. Read byte(s)
  + _day_ at Address \[00 FF\] FB 00
  + _month_ at address \[00 FF\] FB 01
  + _year_ at address \[00 FF\] FB 02
  + _minute_ at address \[00 FF\] FB 03
  + _hour_ at address \[00 FF\] FB 04
  + _day-of-week_ at address \[00 FF\] FB 05

Example Read Clock LOGO 0BA6:

```
:21           hello request
:55:17:17:aa  ask operation mode

:01           write command
:00:ff:44:00  address (clock reading initialized)
:00           value = 0x00

:02           read command
:00:ff:fb:00  address (day)
:02           read command
:00:ff:fb:01  address (month)
:02           read command
:00:ff:fb:02  address (year)
:02           read command
:00:ff:fb:03  address (time)
:02           read command
:00:ff:fb:04  address (hour)
:02           read command
:00:ff:fb:05  address (day of week)
```
>Figure Query _Read Clock_


```
:06:03:21:44  inquiry response
:06:42        operation mode STOP

:06           write completed (clock reading initialized)

:02           read response
:00:ff:fb:00  address (day)
:1e           value = 30
:02           read response
:00:ff:fb:01  address (month)
:0c           value = 12
:02           read response
:00:ff:fb:02  address (year)
:09           value = 09
:02           read response
:00:ff:fb:03  address (time)
:1c           value = 28
:02           read response
:00:ff:fb:04  address (hour)
:14           value = 20
:02           read response
:00:ff:fb:05  address (day of week)
:03           value = 03
```
>Figure Response _Read Clock_


## Write clock
Write commands for RTC:
1. Device status inquiry
2. Write byte(s)
  + _day_ to Address \[00 FF\] FB 00
  + _month_ to address \[00 FF\] FB 01
  + _year_ to address \[00 FF\] FB 02
  + _minute_ to address \[00 FF\] FB 03
  + _hour_ to address \[00 FF\] FB 04
  + _day-of-week_ to address \[00 FF\] FB 05
3. Write byte `00` to Address \[00 FF\] 43 00 writing complete

Write Clock Example:

```
:21           inquiry request
:55:17:17:aa  ask operation mode

:01           write command
:00:ff:fb:00  address (day)
:1e           value = 30
:01           write command
:00:ff:fb:01  address (month)
:0c           value = 12
:01           write command
:00:ff:fb:02  address (year)
:09           value = 09
:01           write command
:00:ff:fb:03  address (minute)
:24           value = 36
:01           write command
:00:ff:fb:04  address (hour)
:14           value = 20
:01           write command
:00:ff:fb:05  address (day of week)
:03           value = 03
:01           write command
:00:ff:43:00  address (clock writing complete)
:00           value 0x00
```
>Figure Query _Write Clock_


```
:06:03:21:44  inquiry response
:06:42        operation mode STOP

:06           write completed (day)
:06           write completed (month)
:06           write completed (year)
:06           write completed (minute)
:06           write completed (hour)
:06           write completed (day of week)
:06           write completed (clock writing complete)
```
>Figure Response _Write Clock_
