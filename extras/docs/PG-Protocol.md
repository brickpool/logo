# LOGO! PG Protocol Reference Guide

Rev. Bx

Mai 2018

## Preface
This guide is written for persons who will communicate with a Siemens (TM) _LOGO!_ __0BA4__, __0BA5__ or __0BA6__ using the PG Interface. The PG Interface used an undocumented protocol for program loading, diagnostics, etc. which is referred to here as PG protocol. This guide describes how messages are constructed, and how transactions take place by using the PG protocol. 

Siemens and LOGO! are registered trademarks of Siemens AG.

## Used and Related Publications
This reference guide cite and uses passages of text from the following documentation:
  * [Modicon Modbus Protocol Reference Guide](modbus.org/docs/PI_MBUS_300.pdf) published by Modbus Organization, Inc.

Refer to the following publication for details about well known commands:
  * SNATAX @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") Data Monitoring, PLC Control, System Info (__0BA6__)
  * cacalderon @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") PLC Control, System Info (__0BA5__) and LOGO DE-9 cable pin-out
  * ask @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/21314/?page=0&pageSize=10 "Logo! Datenlogger") data monitoring python script (__0BA4__)
  * Superbrudi @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/52023/?page=0&pageSize=10 "Excel Logo Logger Overview") data monitoring excel VBA script (__0BA5__ and __0BA6__)

Refer to the following publications for details about the related commands categories of Date and Time, Password Security and Cyclic Data Read
  * chengrui @ [http://www.ad.siemens.com.cn](http://www.ad.siemens.com.cn/club/bbs/post.aspx?a_id=637887&b_id=3 "Siemens s7-200 and LOGO communication") Date and Time
  * neiseng @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") Password Security (@post 23)
  * neiseng @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") Cyclic Data Read (@post 29)

Refer to the following publication for details about the LOGO address layout:
  * neiseng @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") decodes most of the functions and the __0BA5__ data address space (@post 42)

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
    * [Message Frame](#message-frame)
    * [Data Commands Supported by LOGO](#data-commands-supported-by-logo)
    * [Write Byte Command `01`](#write-byte-command-01)
    * [Read Byte Command `02`](#read-byte-command-02)
    * [Write Block Command `04`](#write-block-command-04)
    * [Read Block Command `05`](#read-block-command-05)
  * [Chapter 3 - Control Commands](#chapter-3---control-commands)
    * [Message Frame](#message-frame-1)
    * [Control Commands Supported by LOGO](#control-commands-supported-by-logo)
    * [Stop Operating `12`](#stop-operating-12)
    * [Start Fetch Data `13`](#start-fetch-data-13)
    * [Stop Fetch Data `14`](#stop-fetch-data-14)
    * [Operating Mode `17`](#operating-mode-17)
    * [Start Operating `18`](#start-operating-18)
    * [Diagnostic `1b`](#disgnostic-1b)
  * [Chapter 4 - Tool Commands](#chapter-4---tool-commands)
    * [Message Frame](#message-frame-2)
    * [Tool Commands Supported by LOGO](#tool-commands-supported-by-logo)
    * [Clear Program `20`](#clear-program-20)
    * [Connection Request `21`](#connection-request-21)
    * [Restart `22`](#restart-22)
  * [Chapter 5 - Errors and Confirmations](#chapter-5---errors-and-confirmations)
    * [Confirmed Codes Used by LOGO](#confirmed-codes-used-by-logo)
    * [Acknowledge Response `06`](#acknowledge-response-06)
    * [Exception Response `15`](#exception-response-15)
  * [Appendix A - Address Scheme](#appendix-a---address-scheme)
  * [Appendix B - Application Notes](#appendix-b---application-notes)
  * [Appendix C - Checksum Generation](#appendix-c---checksum-generation)


----------

# Chapter 1 - PG Protocol

## Introducing PG Protocol
The common language used by all _LOGO!_ devices is the PG protocol. This protocol defines a message structure that controllers will recognize and use, regardless of the type of networks over which they communicate.

Standard Interface cable for _LOGO!_ __0BA0__ to __0BA6__ controllers use an 4-wire RS–232C compatible serial interface that defines connector pin-outs, cabling, signal levels, transmission baud rates, and parity checking.

The Siemens Software _LOGO!_ Comfort communicate using a _master–slave technique_, in which only a personal computer called _DTE_ (data terminal equipment) can initiate transactions (called _queries_). The _LOGO!_ device called _DCE_ (data communication equipment) respond by supplying the requested data to the _DTE_, or by taking the action requested in the query.

### The Query–Response Cycle

Direction | Query message from _DTE_ | Response message from _DCE_
--- | --- | ---
PC->LOGO | Command \[data\] | 
LOGO->PC | | Confirmation \[data\]
PC->LOGO | Command \[data\] | 
LOGO->PC | | Confirmation \[data\]
... | ... | ...
>Figure _DTE-DCE_ Query–Response Cycle

__The Query__: The command code in the query tells the _LOGO!_ device what kind of action to perform. The data bytes contain any additional information that the _LOGO!_ will need to perform the function. 

For example, command code `05` will query the _LOGO!_ to read a memory block and respond the content. The _Data_ field must contain the information telling the _LOGO!_ which address to start at and how many bytes to read.

__The Response__: If the _LOGO!_ makes a normal response, the first byte in the response contains an positive confirmation code. The confirmation code allows the _DTE_ to check that the message contents are valid. The following data bytes contain the data collected by the _LOGO!_, such a value or status. If an error occurs, the _LOGO!_ response is an error response, followed by on byte, which contain a exception code that describes the error.

## The Serial Transmission Mode

When the PC communicate to the _LOGO!_ controller with using the PG protocol, each 8–bit byte in a message contains hexadecimal characters. The main advantage of using hexadecimal characters is that its greater character density allows better data throughput than for example ASCII for the same baud rate. Each message must be transmitted in a continuous stream. 

The specification for each communication via the PG Interface:

### Cable / Connectors:
- 5-wire TIA-574
- PC (DTE Connector) DE-9 male
- LOGO! (DCE Connector) DE-9 female

### Pinout:
- [x] RxD Receive Data; _DTE_ in direction; pin 2
- [x] TxD Transmit Data; _DTE_ out direction; pin 3
- [x] DTR Data Terminal Ready; _DTE_ out direction; pin 4 \*)
- [x] GND Ground; pin 5
- [ ] RTS Request to Send; _DTE_ out direction; pin 7 \*)

__Note:__ \*) DTS and/or RTS are used to power the plug electronics

### Baud rate / Bits per byte:
- 9600 baud rate
- 1 start bit
- 8 data bits, least significant bit sent first
- 1 bit for even parity
- 1 stop bit
- RTS (or DTS) set to high (>= 5V)

### Coding System:
- 8–bit binary, hexadecimal 0–9, A–F

## The Message Frame
In either of the two transmission modes (query or request), all data are placed by the transmitting device into a message that has a known beginning and ending point. This allows receiving devices to begin at the start of the message, read the address portion and determine which data is addressed, and to know when the message is completed. Partial messages can be detected and errors can be set as a result.

Start | Content
--- | ---
1 byte | n bytes
Query/Response | Optional
>Figure Message Frame

The next _Figures_ shows an example of a _DTE_ query message and a _LOGO!_ normal response. Both examples show the field contents in hexadecimal, and also show how a message framed.

The _DTE_ query is a monitoring request to the _LOGO!_ device. The message requests a _Fetch Data_ command for monitoring. 

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `55` | Control
Function | `13 13` | Fetch Data
Byte Count | `00` | Number of additional bytes
Trailer | `aa` | End Delimiter
>Figure _DTE_ Query message

The _LOGO!_ response with an acknowledgment, indicating this is a normal response. The _Byte Count_ field specifies how many bytes are being returned.

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Command | `55` | Control
Function | `11 11` | Data Response
Byte Count | `40 00` | Number of bytes 64 (dec)
Data | `00 7f .. 00` | data block
Trailer | `aa` | End Delimiter
>Figure _LOGO!_ Response message

### Command Query
All commands are packed into a message by the _DTE_ sending device, which have a known structure. Valid command codes are in the range of `01` to `55` hexadecimal. Some of these codes apply to all _LOGO!_ controllers, while some codes apply only to certain models. Current codes are described in the following chapters.

When a message is sent from a _DTE_ to a _LOGO!_ device the _Command Code_ field tells the _LOGO!_ what kind of action to perform. Examples are to read the _RUN/STOP_ operation mode; to read the data contents; to read the diagnostic status of the _LOGO!_; to write some designated data; or to allow loading, recording, or verifying the program within the _LOGO!_. 

Start | Content
--- | --- 
1 byte | n bytes
Command Code | Optional
>Figure Query Message Frame

The _Content_ field can be nonexistent (length of zero) in certain kinds of messages.

### Confirmation Response
When the _LOGO!_ responds to the _DTE_, it uses the confirmation code to indicate either a normal (error–free) response or that some kind of error occurred (called _exception response_). For a normal response, the _LOGO!_ simply confirm the message with an acknowledgment. For an exception response, the _LOGO!_ returns an negative-acknowledgement with an exception code.

In addition to the error confirmation code for an exception response, the _LOGO!_ places a unique code into the _Content_ field of the response message. This tells the _DTE_ what kind of error occurred, or the reason for the exception. The _DTE_ application program has the responsibility of handling exception responses. Typical processes are to post subsequent retries of the message, to try diagnostic messages to the _LOGO!_, and to notify the operator.

Start | Content
--- | ---
1 byte | n bytes
Confirmation Code | Optional
>Figure Response Message Frame

The _Content_ field can be nonexistent (length of zero) in certain kinds of messages. 

### How Numerical Values are Expressed
Unless specified otherwise, numerical values (such as addresses, codes, or data) are expressed as hexadecimal values in the text and in the message fields of the figures. 

### Content Field
The _Content_ field of a message sent from a _DTE_ to a _LOGO!_ device may contain additional information, depending on the query. The content field is constructed using sets of two hexadecimal digits, in the range of `00` to `FF` hexadecimal.

If no error occurs, the _Content_ field of a response from the _LOGO!_ to the _DTE_ contains the content requested. If an error occurs, the field contains an exception code that the PDE application can use to determine the next action to be taken.

### How a Function Field is Handled
If a _Function_ field exists, then this consists of two bytes with same value. Valid function codes are in the range of `11 11` to `18 18` hexadecimal. Functions that are inserted into a message without addressing something in the memory use a terminator (called _end delimiter_) `AA`. The allowable bytes transmitted for the data content are hexadecimal `00` to `FF` (including `AA`).

### How a Address Field is Handled
The _Address_ field of a message frame contains two bytes (__0BA4__, __0BA5__) or four bytes (__0BA6__). Valid device addresses or memory addresses depends on the _LOGO!_ controller. A _DTE_ addresses the memory by placing the address in the _Address_ field of the message. When the _LOGO!_ sends its response, it echos the address in the _Address_ field of the response to let the _DTE_ know which address is requested.

### How to Use the Byte Count Field
If you need to transfer more than one data byte from the _DTE_ to the _LOGO!_ device, then you must use a _Byte Count_ value that indicates the number of bytes in your message data. When storing responses in buffers, you should use the _Byte Count_ value, which is the number of bytes in your message data. The value refers to the following field contents.

For example, if the _DTE_ requests the _LOGO!_ to read a group of data (e.g. function code `05`), the content specifies the starting address and how many bytes are to be read. If the _DTE_ writes to a group of data to the _LOGO!_ (e.g. function code `04`), the content specifies the starting address, the count of data bytes to follow in the _Data_ field, and the data to be written into the registers. 

### How a Data Field is Handled
The _Data_ field is constructed using sets of two hexadecimal digits, in the range of `00` to `FF` hexadecimal.

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

The _DTE_ is configured by the user to wait for a predetermined timeout interval before aborting the transaction. This interval is set to be long enough for any
_LOGO!_ to respond normally (in general between 75 and 600 ms). If the _LOGO!_ detects a transmission error, the message will be acted upon with an exception response. When the timeout will expire the _DTE_’s program has to handle these state.

### Parity Checking
Users must configure controllers for Even Parity checking. Since Even Parity is specified, the quantity of 1 bits will be counted in the data portion over all eight data bits. The parity bit will then be set to a 0 or 1 to result in an Even total of 1 bits. 

For example, these eight data bits are contained:

```
1100 0101
```

The total quantity of 1 bits in the frame is four. If Even Parity is used, the frame’s parity bit will be a 0, making the total quantity of 1 bits still an even number (four). If Odd Parity is used, the parity bit will be a 1, making an odd quantity (five).

When the message is transmitted, the parity bit is calculated and applied to the frame of each byte. The receiving device counts the quantity of 1 bits and
sets an error if they are not the same as configured for that device (_DTE_ and _DCE_ must be configured to use the even parity check method).

Note that parity checking can only detect an error if an odd number of bits are picked up or dropped in a character frame during transmission. 

### XOR Checking
For the block commands `04` and `05`, the _DTE_ query or _LOGO!_ response messages include an error–checking field that is based on a Checksum XOR method. The _Checksum_ field checks the contents of the entire data. It is applied regardless of any parity check method used for the individual characters of the message. 

The _Checksum_ field is one byte, containing an 8–bit binary value. The Checksum value is calculated by the transmitting device, which appends the XOR value to the message. The receiving _DTE_ program must calculate the Checksum during receipt of the message, and compares the calculated value to the actual value it received in the _Checksum_ field. If the two values are not equal, an error results.

__Note:__ The application of _Checksum_ field in response message are not mandatory. 


----------

# Chapter 2 - Data Commands

## Message Frame

Command | Address | Content
--- | --- | ---
1 byte | 2 or 4 bytes | n bytes
Data Code | 16/32bit Address | Optional
>Figure _Data Command_ Frame

The content field is usually required. It is not available (length of zero) only for the read byte command `02`. The format depends on the command codes.

__Note:__ _LOGO!_ version 0BA6 uses 32bit addresses, version 0BA4 and 0BA5 16bit addresses.

## Data Commands Supported by LOGO
The listing below shows the data command codes supported by _LOGO!_. Codes are listed in hexadecimal.

_Y_ indicates that the command is supported. _N_ indicates that it is not supported.

Code | Name | __0BA4__ | __0BA5__ | __0BA6__
--- | --- | --- | --- | ---
`01` | Write Byte Command | Y | Y | Y
`02` | Read Byte Command | Y | Y | Y
`04` | Write Block Command | Y | Y | Y
`05` | Read Block Command | Y | Y | Y

## Write Byte Command `01`

### Description
The command writes a byte value to the specified memory address of the _LOGO!_ device. For example, the contents of a byte in the memory of the _LOGO!_ device can be manipulated with this command. 

### Query
The query message specifies the Byte reference to be writing. The data are addressed starting at zero.

Command | Address | Data
--- | --- | ---
1 byte | 2 bytes | 1 byte
Data Code | 16/32bit Address | Data Byte
>Figure _Write Byte_ Query Message

The _Address_ field is an offset of the memory specified by the _LOGO!_ device. The _Data_ field is a numeric expression that write a byte value into the memory. 

Here is an example of a request for write `00` to the memory address `1f 02`:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `01` | Write Byte
Address | `1f 02` | 16bit Address
Data | `00` | Data Byte
>Figure Example _Write Byte_ Query

### Response
The normal response is a simple Acknowledgment of the query, returned after the data byte has been written.

Here is an example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `06` | Acknowledgment
>Figure Example _Write Byte_ Response
 
## Read Byte Command `02`

### Description
Read Byte is a memory function that returns the byte stored at a specified memory location. 

The maximum value of the address depends on the _LOGO!_ controller. In the _LOGO!_ device is an addressing error exception handling implemented. For example, an instruction for an empty address causes an exception response.

### Query
The query message reads a Byte value from the specified address and send it as a return value to the _DTE_.

Command | Address
--- | ---
1 byte | 2 bytes
Data Code | 16/32bit Address
>Figure _Read Byte_ Query Message

Here are two examples of a request to read a byte from the address (`00 ff`)`1f 02`:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `02` | Read Byte
Address | `1f 02` | 16bit Address
>Figure Example _Read Byte_ Query

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `02` | Read Byte
Address | `00 ff 1f 02` | 32bit Address
>Figure Example _Read Byte_ Query __0BA6__

### Response
The byte value in the response message is packed into the _Data_ field. 

Here is a example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Command | `03` | Data Response
Address | `00 ff 1f 02` | 32bit Address
Data | `40` | Data Byte
>Figure Example _Read Byte_ Response __0BA6__

## Write Block Command `04`

### Description
Writes data contents of bytes into the Memory of the _LOGO!_ device. 

### Query
The command contains the standard fields of command code, address offset and Byte Count. The rest of the command specifies the group of bytes to be written into the _LOGO!_ device. 

Command | Address | Byte Count | Data | Checksum
--- | --- | --- | --- | ---
1 byte | 2 or 4 bytes | 2 bytes | n bytes | 1 byte
Data Code | 16/32bit Address | Number of bytes | Data Content | CheckSum8 XOR
>Figure _Write Block_ Query Message

### Response
The normal response is an confirmation of the query, returned after the data contents have been written.

## Read Block Command `05`

### Description
Reads the binary contents at the specified Memory address of the _LOGO!_ device.

### Query
The query message specifies the starting Byte and quantity of Data to be read. The data are addressed starting at zero.

Command | Address | Byte Count
--- | --- | ---
1 byte | 2 or 4 bytes | 2 bytes
Data Code | 16/32bit Address | Number of bytes
>Figure _Read Block_ Query Message

The following example reads the program name from _LOGO!_ memory:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `05` | Read Byte
Address | `05 70` | 16bit Address
Byte Count | `00 10` | Number of bytes 16 (dec)
>Figure Example _Read Block_ Query

### Response
The data in the response message is sent as hexadecimal binary content. The number of data bytes sent corresponds to the requested number of bytes.

Command | Data | Checksum
--- | --- | ---
1 byte | n bytes | 1 Byte
Confirmation Code | Data Block | CheckSum8 XOR
>Figure _Read Byte_ Response Message

Here is an example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Data | `48 65 6C 6C 6F 20 77 6F 72 6C 64 21 20 20 20 20` | Data Block
Checksum | `21` | XOR Byte
>Figure Example _Read Block_ Response

In this example the program name is read out. The maximum text width is 16 characters. The reading direction is from left to right. In addition, the XOR checksum value is used in this example (`21` hex).

Format | Data
--- | ---
Hexadecimal | `48 65 6C 6C 6F 20 77 6F 72 6C 64 21 20 20 20 20`
ASCII | `_H _e _l _l _o __ _w _o _r _l _d _! __ __ __ __`
>Figure Example _Read Block_ Data decoded


----------

# Chapter 3 - Control Commands

## Message Frame
All control commands are placed into a frame that has a known beginning and ending point. They start with `55` and end with `AA`. The function code specifies the control command to be executed. The function code consists of two bytes and both bytes have the same value. 

A typical message frame is shown below.

Start | Function | Content | End
--- | --- | --- | ---
1 byte | 2 bytes | n bytes | 1 byte
Control Code | Function Field | Optional | End Delimiter
>Figure _Control Command_ Frame

The content of a control message sent from a _DTE_ to a _LOGO!_ device may contains additional information that the _LOGO!_ must use to perform the action defined by the command code. 

## Control Commands Supported by LOGO

The listing below shows the function codes for the control command `55` supported by _LOGO!_. Codes are listed in hexadecimal.

_Y_ indicates that the command is supported. _N_ indicates that it is not supported.

Function | Name | __0BA4__ | __0BA5__ | __0BA6__
--- | --- | --- | --- | ---
`12` | Stop Operating | Y | Y | Y
`13` | Start Fetch Data | Y | Y | Y
`14` | Stop Fetch Data | ? | Y | Y
`17` | Operation Mode | Y | Y | Y
`18` | Start Operating | Y | Y | Y
`1b` | Diagnostic | N | N | N

## Stop Operating `12`

### Description
Send to _LOGO!_ to change the operation mode to _STOP_

### Query

Command | Function | Trailer
--- | --- | --- 
1 byte | 2 bytes | 1 byte 
Control Code | Function Code | End Delimiter
>Figure Function Message Frame

Here is an example how to set the operation mode to _STOP_:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `55` | Control
Function | `12 12` | Stop Operating
Trailer | `aa` | End Delimiter
>Figure Example _Stop Operating_ Query

### Response
A normal response contains a confirmation that the _LOGO!_ device has completed the command successfully.

Here is an example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `06` | Acknowledgment
>Figure Example _Stop Operating_ Response

## Start Fetch Data `13`

### Description
This function fetching the current data from the _LOGO!_ device. The _LOGO!_ device responds with ACK (`06`), followed by control code `55`, the response function code `11` and the data (length depends on the device type) or NAK (`15`), followed by an exception code. The fetching of the data can be done once or continuously (called _cyclic data query_).

To fetch data or start a continuously polling, the _Data_ field must be existent and must set to `00`. If a confirmation code `06` is sent by the _DTE_ to the _LOGO!_ device within 600 ms, the _LOGO!_ device sends updated data (cyclic data read). To stop a data reading the Control Code `14` (_Stop Fetch Data_) must be sent. 

The distance between the data transfers (scan distance) depends on the cycle time of the _LOGO!_ device and the number of requested data (byte count). The data of the inputs and outputs as well as the flags are always read out as a block. The scan distance is about 200 ms (byte count = 0), so valid cycle times are greater than 200 ms. For a shorter cycle time, the requesting _DTE_ system will not receive all data. 

### Query

Command | Function | Byte Count | Data 1) | Trailer
--- | --- | --- | --- | ---
1 byte | 2 bytes | 1 byte | 1 byte | 1 byte
Control Code | Function Code | Number of bytes | Data bytes 1) | End Delimiter
>Figure _Start Fetch Data_ Query Message

__Notes:__ 1) Used when the _Byte Count_ is greater than zero

Here is an example of a single request of fetching the monitoring data from _LOGO!_ device:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `55` | Control
Function | `13 13` | Fetch Data
Byte Count | `02` | Number of additional bytes = 2
Data | `0b` `0a` | Block B002, B001
Trailer | `aa` | End Delimiter
>Figure Example _Start Fetch Data_ Query

### Response

Command | Command | Function | Byte Count | Data | Trailer
--- | --- | --- | --- | --- | ---
1 byte | 1 byte | 2 bytes | 2 bytes | n bytes | 1 byte
Confirmation Code | Control Code | Function Code | Number of bytes | Data Block | End Delimiter
>Figure _Fetch Data_ Response Message

The _Byte Count_ value indicates the number of bytes that are followed (excluding the _End Delimiter_ `AA`). The _Byte Count_ is of the data type Word and in the format _Little-Endian_ (LoByte, HiByte).

__Notes:__
Minimum _Byte Count_ value
- __0BA4__ = 40 (hex) = 64 bytes
- __0BA5__ = 40 (hex) = 64 bytes
- __0BA6__ = 4a (hex) = 74 bytes

The _Data_ field includes input image registers, run-time variables, etc. and the data for input, output, cursor key states, and the additionally requested variables.

The listing below shows the position in the _Data_ field for the well known values. The positions start at one and are listed in decimal.

_N_ indicates that it is not supported.

Register | __0BA4__ | __0BA5__ | __0BA6__ | Description
--- | --- | --- | --- | ---
B | 6 | 6 | 6 | Block output
I | 23 | 23 | 31 | input
F | N | N | 34 | function keys
O | 26 | 26 | 35 | output
M | 28 | 38 | 37 | flag
S | 31 | 31 | 41 | shift register
C | 32 | 32 | 42 | cursor keys
AI | 33 | 33 | 43 | analog input
AO | 49 | 49 | 59 | analog output
AM | 53 | 53 | 63 | analog flag


The examples shows how the _Byte Count_ field is implemented in a _LOGO!_ fetching data response:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Command | `55` | Control
Function | `11 11` | Data Response
Byte Count | `40 00` | Number of bytes 64 (dec)
Data | `7f 66` `11 2a` `00` `80 01 10 00 00 00 00 00 00 00 00` | Data Block 00-0f
Data | `00 00 00 00 00 a8` `00 00 00` `00 00` `00 00 00` `00` `00` | Data Block 10-1f
Data | `00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00` | Data Block 20-2f
Data | `00 00 00 00` `00 00 00 00 00 00 00 00 00 00 00 00` | Data Block 30-3f
Trailer | `aa` | End Delimiter
>Figure Example _Fetch Data_ Response __0BA4__


Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Command | `55` | Control
Function | `11 11` | Data Response
Byte Count | `40 00` | Number of bytes 64 (dec)
Data | `35 08` `11 2a` `00` `00 00 00 00 00 00 00 00 00 00 00` | Data Block 00-0f
Data | `00 00 00 00 00 0C` `09 00 00` `01 00` `00 00 00` `00` `00` | Data Block 10-1f
Data | `00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00` | Data Block 20-2f
Data | `00 00 00 00` `00 00 00 00 00 00 00 00 00 00 00 00` | Data Block 30-3f
Trailer | `aa` | End Delimiter
>Figure Example _Fetch Data_ Response __0BA5__


Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Command | `55` | Control
Function | `11 11` | Data Response
Byte Count | `44 00` | Number of bytes 68 (dec)
Data | `f4 5f` `11 2a` `04` `04 00 00 00 00 00 00 00 00 00 00` | Data Block 00-0f
Data | `00 00 00 00 00 00` `00 00 00` `00 00` `00 00 00` `01` `00` | Data Block 10-1f
Data | `00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00` | Data Block 20-2f
Data | `00 00 00 00` `00 00 00 00 00 00 00 00 00 00 00 00` | Data Block 30-3f
Data | `01 00 22 80` | Data Block 40-43
Trailer | `aa` | End Delimiter
>Figure Example _Fetch Data_ Response __0BA5__ with 4 addional bytes


Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Command | `55` | Control
Function | `11 11` | Data Response
Byte Count | `4a 00` | Number of bytes 74 (dec)
Data | `b7 c4` `19 2c` `00` `10 84 6b 00 00 00 00 00 00 00 00` | Data Block 00-0f
Data | `00 00 00 00 00 00 00 00 00 00 00 00 00 00` `00 00` | Data Block 10-1f
Data | `00` `00` `00 00` `00 00 00 00` `00` `00` `00 00 00 00` `00 00`| Data Block 20-2f
Data | `00 00 00 00 00 00 00 00 00 00` `00 00 00 00` `00 00` | Data Block 30-3f
Data | `00 00 00 00 00 00 00 00 00 00` | Data Block 40-49
Trailer | `aa` | End Delimiter
>Figure Example _Fetch Data_ Response __0BA6__


## Stop Fetch Data `14`

### Description
The execution of this command completes the monitoring. There are no further return data and any remaining data are discarded.

## Operating Mode `17`

### Description
The Control Command `17` queries the current operating mode.

### Query

Status query from _DTE_ to the _LOGO!_ device to query the operating mode.

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `55` | Control
Function | `17 17` | Ask operation mode
Trailer | `aa` | End Delimiter
>Figure Example _Operating Mode_ Query

### Response

The format of a normal response is shown below. The data content depends on the current operating mode. They are listed on the following heading.

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation | `06` | Acknowledgment
Data | `01` | Current Operating Mode is RUN
>Figure Example _Operating Mode_ Response

### A Summary of Operation Modes

These are the Operation Modes returned by _LOGO!_ controllers in the second byte of the confirmation response:

Data | Meaning
--- | ---
`01` | _LOGO!_ in _RUN_ mode
`20` | _LOGO!_ in Parameter mode
`42` | _LOGO!_ in _STOP_ mode


## Start Operating `18`

### Description
Executing the command switches the connected _LOGO!_ device from the _STOP_ mode to the _RUN_ mode.

### Query
Send to _LOGO!_ to change the operation mode to _RUN_

Command | Function | Trailer
--- | --- | --- 
1 byte | 2 bytes | 1 byte 
Control Code | Function Code | End Delimiter
>Figure Function Message Frame

Here is an example how to set the operation mode to _RUN_:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `55` | Control
Function | `18 18` | Start Operating
Trailer | `aa` | End Delimiter
>Figure Example _Start Operating_ Query

### Response
A normal response contains a confirmation that the _LOGO!_ device has completed the command successfully.

Here is an example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `06` | Acknowledgment
>Figure Example _Start Operating_ Response

## Diagnostic `1b`
Diagnostic is only supportet by _LOGO!_ 0BA7 and above.

----------

# Chapter 4 - Tool Commands

## Message Frame
For example, in a request from the _DTE_ to the _LOGO!_ to respond with his serial no (function code `21` hexadecimal), the _LOGO!_ does not require any additional information. The command code alone specifies the action.

## Tool Commands Supported by LOGO
The listing below shows the information command codes supported by _LOGO!_. Codes are listed in hexadecimal.

_Y_ indicates that the command is supported. _N_ indicates that it is not supported.

Code | Name | __0BA4__ | __0BA5__ | __0BA6__
--- | --- | --- | --- | ---
`20` | Clear Program | N | N | Y
`21` | Connection Request | N | N | Y
`22` | Restart | N | N | Y

## Clear Program `20`
This command allows you to clear the circuit program in the connected _LOGO!_ device and the program password if a password exists. The circuit program and password (if configured) remain in the _LOGO!_ device. _LOGO!_ devices prior to version __0BA6__ do not support this function. 

Here is an example of a request to read the current _Clear Program_:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `20` | Control
>Figure Example _Clear Program_ Query

Here is an example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation Code | `06` | Acknowledgment
Data | `20` | Current Operating Mode is EDIT
>Figure Example _Acknowledge_ Response

## Connection Request `21`
Send to _LOGO!_ a _Connection Request_ `21`:

controller | command | request | response | description
--- | --- | --- | --- | ---
0BA4 | Connection Request | `21` | _n/a_ | no Response
0BA5.Standard | Connection Request | `21` | `15` `05` | Exception Response `05`
0BA6.Standard | Connection Request | `21` | `06` `03` `21` `43` | Confirmation Response `43`
0BA6.ES3 | Connection Request | `21` | `06` `03` `21` `44` | Confirmation Response `44`
>Figure Example _Connection Request_

## Restart `22`
In the case of a _LOGO!_ device __0BA6__, the execution of further commands is no longer possible after an error (for example, unauthorized memory access; exception code `03`). Additional commands are always answered with an exception code (e.g. _DEVICE TIMEOUT_ `02` or _ILLEGAL ACCESS_ `03`) by the LOGO device. To restart the communication (after an exception response), the _Restart_ command `21` is used.

__Notes:__  The _Restart_ command '21' is currently only confirmed for the _LOGO!_ device __0BA6__.


# Chapter 5 - Errors and Confirmations

----------

## Confirmed Codes Used by LOGO
The listing below shows the confirmation response code used by _LOGO!_. Codes are listed in hexadecimal.

_Y_ indicates that the confirmation is supported. _N_ indicates that it is not supported.

Code | Name | __0BA4__ | __0BA5__ | __0BA6__
--- | --- | --- | --- | ---
`06` | Acknowledge Response | Y | Y | Y
`15` | Exception Response | Y | Y | Y

## Acknowledge Response `06`

### Description
_LOGO!_ confirmation code `06` (ACK), followed by zero or n bytes of data. The response message depends on the request. It can consist of a simple _ACK_ or additionally contain the requested data. 

### Response

Confirmation | Content
--- | --- 
1 byte | n bytes
Confirmation Code | Optional
>Figure _Acknowledge_ Response Message

Here is an example of a request to read the current _Operation Mode_:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `55` | Control
Function | `17 17` | Ask operation mode
Trailer | `aa` | End Delimiter
>Figure Example _Operating Mode_ Query

Here is an example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation Code | `06` | Acknowledgment
Data | `42` | Current Operating Mode is STOP
>Figure Example _Acknowledge_ Response

## Exception Response `15`

### Description
_LOGO!_ confirmation code `15` (NOK), followed by an exception code (1 byte). 

### Response
The exception code can be a transport or protocol error. The field examples are in hexadecimal.

Confirmation | Content
--- | --- 
1 byte | 1 byte
Confirmation Code | Exception Code
>Figure _Exception_ Response Message

The next two Figures shows an example of a _DTE_ query and a exception response from a _LOGO!_ __0BA4__ device (operation mode _STOP_):

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Command | `21` | Read Byte
>Figure Example _Faulty Command_ Query __0BA4__

Here is an example of a response to the query above:

Field Name | Code \(hex\) | Meaning
--- | --- | ---
Confirmation Code | `15` | Exception
Exception Code | `05` | Unknown command
>Figure Example _Exception_ Response __0BA4__

## Exception Codes
Type | Name | Meaning
--- | --- | ---
`01` | DEVICE BUSY | _LOGO!_ can not accept a telegram
`02` | DEVICE TIMEOUT | Resource unavailable, the second cycle of the write operation timed out
`03` | ILLEGAL ACCESS | Illegal access, read across the border
`04` | PARITY ERROR | parity, overflow or telegram error
`05` | UNKNOWN COMMAND | Unknown command, this mode is not supported
`06` | XOR INCORRECT | XOR-check incorrect
`07` | SIMULATION ERROR | Faulty on simulation, _RUN_ is not supported in this mode


----------

# Appendix A - Address Scheme

This Appendix contains information about the memory address ranges of the _LOGO!_ controller.

## LOGO __0BA5__
The listing below shows the address scheme of the _LOGO!_ device __0BA5__. Codes are listed in hexadecimal.

_R_ indicates that is supported in operation mode _RUN_. _W_ indicates that write is supported.

Base Address | Byte Count (dec) | Access | Meaning | Example
----------- | --- | --- | --- | ---
0522        | 1   | W   |     | `01 05 22 00`
--          | --  | --  | --  | --
0552        | 1   | W   | Display at power-on? I/O = `01`; DateTime = `FF` | `02 05 52`
--          | --  | --  | --  | --
0553 - 0557 | 5   |     | Analog output in mode _STOP_ | `05 05 53 00 05`
--          | --  | --  | --  | --
055E        | 1   | W   | Program Checksum Hi-Byte | `02 05 5E`
055F        | 1   | W   | Program Checksum Lo-Byte | `02 05 5F`
--          | --  | --  | --  | --
0566 - 056F | 10  |     | Password memory area | `05 05 66 00 0A`
0570 - 057F | 16  |     | Program Name | `05 05 70 00 10`
--          | --  | --  | --  | --
05C0 - 05FF | 64  |     | Block Name index | `05 05 C0 00 40`
0600 - 07FF | 512 |     | Block Name | `05 06 00 02 00`
0800 - 0A7F | 640 |     | Text Box 1..10 (64 bytes per Text Box) | `05 08 00 02 80`
--          | --  | --  | --  | --
0C00 - 0D17 | 280 |     | Program memory index | `05 0C 00 01 18`
--          | --  | --  | --  | --
0E20 - 0E47 | 40  |     | Digital output Q1..16 | `05 0E 20 00 28`
0E48 - 0E83 | 60  |     | Merker M1..24 | `05 0E 48 00 3C`
0E84 - 0E97 | 20  |     | Analog output AQ1..2 | `05 0E 84 00 14`
0E98 - 0EBF | 40  |     | Open Connector X1..16 | `05 0E 98 00 28`
0EC0 - 0EE7 | 40  |     |     | `05 0E C0 00 28`
0EE8 - 16B7 | 2000 |    | Program memory area | `05 0E E8 07 D0`
--          | --  | --  | --  | --
4100        | 1   | W   |     | `01 41 00 00`
--          | --  | --  | --  | --
4300        | 1   | W   | Write RTC DT = `00` | `01 43 00 00`
4301        | 1   | W   | Write RTC S/W = `00` | `01 43 01 00`
--          | --  | --  | --  | --
4400        | 1   | W   | Load RTC DT = `00` | `01 44 00 00`
4401        | 1   | W   | Load RTC S/W = `00` | `01 44 01 00`
--          | --  | --  | --  | --
4740        | 1   | W   | Password R/W initialization; Data Byte = `00` | `01 47 40 00`
--          | --  | --  | --  | --
4800        | 1   | W   |     | `01 48 00 00`
--          | --  | --  | --  | --
48FF        | 1   | W   | Password set? yes = `40`; no = `00` | `02 48 FF`
--          | --  | --  | --  | --
1F00        | 1   |     |     | `02 1F 00`
1F01        | 1   |     |     | `02 1F 01`
1F02        | 1   | R   | Ident Number | `02 1F 02`
1F03        | 1   |     | Version character = `V`| `02 1F 03`
1F04 - 1F08 | 5   |     | Firmware | `02 1F 04` `..`
--          | --  | --  | --  | --
FB00 - FB05 | 6   | W   | Clock memory area | `01 FB 00 03` `..`


----------

# Appendix B - Application Notes

This Appendix contains information and suggestions for using the protocol in your application.

## Maximum Query/Response Parameters
The listings in this section show the maximum amount of data that each controller can request or send in a _DTE_ query, or return in a _LOGO!_ response. All 
codes are in hexadecimal and the quantities (number of bytes) are in decimal. The correct amount of data (c = _Byte Count_) is a multiple of 4 bytes.

### Query Parameters List __0BA4__ and __0BA5__

_N_ indicates that it is not supported. _0_ indicates that the command generate no response. 

Command | Description | Query | Response 1)
--- | --- | --- | ---
`01` | Write Byte Command | 4 | 1
`02` | Read Byte Command | 3 | 5
`04` | Write Block Command | 6 + c | 1
`05` | Read Block Command | 5 | 2 + c
`12` | Stop Operating | 4 | 1
`13` | Start Fetch Data | 5 | 70 + c
`14` | Stop Fetch Data | 4 | 0
`17` | Operating Mode | 4 | 2
`18` | Start Operating | 4 | 1
`20` | Clear Program | N | (0,2)
`21` | Connection Request | N | (0,2)
`22` | Restart | N | (0,2)
>Figure Maximum Q/R Parameters __0BA4__ and __0BA5__

__Notes:__ 1) The information in brackets applies to the _LOGO!_ Version __0BA4__, __0BA5__

### Response Parameter List __0BA4__ and __0BA5__

Command | Description | Query 1) | Response
--- | --- | --- | ---
`03` | Read Byte Response | (`02`) | 5
`06` | Acknowledge Response | 1 | 1 + n
`11` | Fetch Data Response | (`13`) | 70 + c
`15` | Exception Response | (`..`) | 2
>Figure Maximum R Parameters __0BA4__ and __0BA5__

__Notes:__ 1) The information in brackets shows the command code to which a response related.

### Query Parameter List for __0BA6__

Command | Description | Query | Response
--- | --- | --- | ---
`01` | Write Byte Command | 4 | 1
`02` | Read Byte Command | 3 | 7
`04` | Write Block Command | 8 + c | 1
`05` | Read Block Command | 7 | 2 + c
`12` | Stop Operating | 4 | 1
`13` | Start Fetch Data | 5 | 80 + c
`14` | Stop Fetch Data | 4 | 0
`15` | Exception Response | N | 2
`17` | Operating Mode | 4 | 2
`18` | Start Operating | 4 | 1
`20` | Clear Program | 1 | 2
`21` | Connection Request | 1 | 6
`22` | Restart | 1 | 1
>Figure Maximum Q/R Parameters __0BA6__

### Response Parameter List for __0BA6__

Command | Description | Query 1) | Response
--- | --- | --- | ---
`03` | Read Byte Response | (`02`) | 7
`06` | Acknowledge Response | 1 | 1 + n
`11` | Fetch Data Response | (`13`) | 80 + c
`15` | Exception Response | (`..`) | 2
>Figure Maximum R Parameters __0BA6__

__Notes:__ 1) The information in brackets shows the command code to which a response related.

## Estimating Serial Transaction Timing

### The Transaction Sequence
The following sequence of events occurs during a serial transaction. Letters in parentheses ( ) refer to the timing notes at the end of the listing.

1. The _DTE_ composes the message
2. The query message is transmitted to the _LOGO!_ ( 1 )
3. The _LOGO!_ processes the query message ( 2 ) ( 3 )
4. The _LOGO!_ calculates an error check field ( 4 )
5. The response message is transmitted to the _DTE_ ( 1 )
6. The _DTE_ application acts upon the response and its data

### Timing Notes
1. Use the following formula to estimate the transmission time:
```
            1000 * (character count) * (bits per character)   1000 * (count of bytes) * 8
Time (ms) = ----------------------------------------------- = ---------------------------
                              Baud Rate                                   9600
```

2. The message is processed at the end of the controller cycle. The worst–case delay is one cycle time, which occurs if the controller has just
begun a new cycle. The cycle time of each function is less than 0.1 ms.

The time allotted for servicing the PG interface at the end of the controller cycle (before beginning a new cycle) depends upon the controller model.

3. The Commands `04`, `05`, and `13` permit the _DTE_ to request more data than can be processed during the time allotted for servicing the _LOGO!_ PG interface. If the _LOGO!_ cannot process all of the data, it will buffer the data and process it at the end of subsequent cycle.

4. Checksum calculation time is about 0.1 ms for each 8 bits of data to be returned in the response.

## Application Examples
The following examples show some simple command blocks and the resulting output values.

### Read Ident Number
Read the revision byte from the _LOGO!_ address `1f 02`:

Command | Query | Response | Description
--- | --- | --- | ---
Read Byte | `02` `1f 02` | `06` `03` `1f 02` `40` | connection established to `40` (_LOGO!_ __0BA4__)
Read Byte | `02` `1f 02` | `06` `03` `00 ff 1f 02` `43` | connection established to `43` (_LOGO!_ __0BA6__)
>Figure Example _Read Ident Number_

### Read Firmware
Commands for reading the Firmware (only available for __0BA5__ and __0BA6__). The access is only available in mode _STOP_. 

The Firmware can be read out on the _LOGO!_ device as follows:

1. Device _Operating Mode_
2. _Read Byte_ at address `[00 ff] 1f 02` for reading the _Ident Number_.
2. _Read Byte_ at address `[00 ff] 1f 03` for reading the version character = `V`.
4. _Read Byte_(s)
 + _Major release_ 1st character at address `[00 ff] 1f 04`
 + _Major release_ 2nd character at address `[00 ff] 1f 05`
 + _Minor release_ 1st character at address `[00 ff] 1f 06`
 + _Minor release_ 2nd character at address `[00 ff] 1f 07`
 + _Patch level_ 1st character at address `[00 ff] 1f 08`
 + _Patch level_ 2nd character at address `[00 ff] 1f 09`

Example for the 1st major version of a firmware, in the 3rd minor version with the 32nd error correction (V1.03.32):

Command | Query | Response | Description
--- | --- | --- | ---
Operation Mode | `55` `17 17` `aa` | `06` `42` | operation mode _STOP_ (`42`, _RUN_ = `01`)
Read Byte | `02` `00 ff 1f 02` | `06` `03` `00 ff 1f 02` `43` | connection established to `43` (_LOGO!_ __0BA6__)
Read Byte | `02` `00 ff 1f 03` | `06` `03` `00 ff 1f 03` `56` | major release 1st character = `V` (ASCII)
Read Byte | `02` `00 ff 1f 04` | `06` `03` `00 ff 1f 04` `30` | major release 1st character = `0` (ASCII)
Read Byte | `02` `00 ff 1f 05` | `06` `03` `00 ff 1f 05` `31` | major release 2nd character = `1` (ASCII)
Read Byte | `02` `00 ff 1f 06` | `06` `03` `00 ff 1f 06` `30` | minor release 1st character = `0` (ASCII)
Read Byte | `02` `00 ff 1f 07` | `06` `03` `00 ff 1f 07` `33` | minor release 2nd character = `3` (ASCII)
Read Byte | `02` `00 ff 1f 08` | `06` `03` `00 ff 1f 08` `33` | patch release 1st character = `3` (ASCII)
Read Byte | `02` `00 ff 1f 09` | `06` `03` `00 ff 1f 09` `32` | patch release 2nd character = `2` (ASCII)
>Figure Example _Read Firmware_ __0BA6__

__Note:__ The firmware can only be read in _STOP_ mode.

### Read Clock
Commands for reading the RTC-Clock (if available). The access is only available in mode _STOP_.

The clock can be read out on the _LOGO!_ device as follows:

1. Device _Operating Mode_
2. _Write Byte_ `00` to address `[00 ff] 44 00` for initialize reading
3. _Read Byte_(s)
 + _Day_ at address `[00 ff] fb 00`
 + _Month_ at address `[00 ff] fb 01`
 + _Year_ at address `[00 ff] fb 02`
 + _Minute_ at address `[00 ff] fb 03`
 + _Hour_ at address `[00 ff] fb 04`
 + _Day-Of-Week_ at address `[00 ff] fb 05`

_Read Clock_ Example:

Command | Query | Response | Description
--- | --- | --- | ---
Connection Request | `21` | `06` `03` `21` `44` | connection established to `44` (_LOGO!_ __0BA6__)
Operation Mode | `55` `17 17` `aa` | `06` `42` | operation mode _STOP_ (`42`, _RUN_ = `01`)
Write Byte | `01` `44 00` `00` | `06` | clock reading initialized
Read Byte | `02` `fb 00` | `06` `03` `00 ff fb 00` `1e` | day = 30 (dec)
Read Byte | `02` `fb 01` | `06` `03` `00 ff fb 01` `0c` | month = 12 (dec)
Read Byte | `02` `fb 02` | `06` `03` `00 ff fb 02` `09` | year = 09 (dec)
Read Byte | `02` `fb 03` | `06` `03` `00 ff fb 03` `1c` | minute = 28 (dec)
Read Byte | `02` `fb 04` | `06` `03` `00 ff fb 04` `14` | hour = 20 (dec)
Read Byte | `02` `fb 05` | `06` `03` `00 ff fb 05` `03` | day-of-week = 3 (dec)
>Figure Example _Read Clock_ __0BA6__

__Note:__ The clock can only be read in _STOP_ mode.

### Write Clock
Commands for writing the RTC-Clock (if available). The access is only available in mode _STOP_.

The clock can be set on the _LOGO!_ device as follows:

1. Device _Operating Mode_
2. _Write Byte_(s)
 + _Day_ to address `[00 ff] fb 00`
 + _Month_ to address `[00 ff] fb 01`
 + _Year_ to address `[00 ff] fb 02`
 + _Minute_ to address `[00 ff] fb 03`
 + _Hour_ to address `[00 ff] fb 04`
 + _Day-Of-Week_ to address `[00 ff] fb 05`
3. _Write Byte_ `00` to address `[00 ff] 43 00` for writing complete

_Write Clock_ Example:

Command | Query | Response | Description
--- | --- | --- | ---
Connection Request | `21` | `06` `03` `21` `44` | connection established to `44` (_LOGO!_ __0BA6__)
Operation Mode | `55` `17 17` `aa` | `06` `42` | operation mode _STOP_ (`42`, _RUN_ = `01`)
Write Byte | `01` `fb 00` `1e` | `06` | day = 30 (dec)
Write Byte | `01` `fb 01` `0c` | `06` | month = 12 (dec)
Write Byte | `01` `fb 02` `09` | `06` | year = 09 (dec)
Write Byte | `01` `fb 03` `24` | `06` | minute = 36 (dec)
Write Byte | `01` `fb 04` `14` | `06` | hour = 20 (dec)
Write Byte | `01` `fb 05` `03` | `06` | day-of-week = 3 (dec)
Write Byte | `01` `43 00` `00` | `06` | clock writing completed
>Figure Example _Write Clock_ __0BA6__

__Note:__ The clock can only be set in _STOP_ mode.

### Password set?
The password can only be read or set in _STOP_ mode.

The Example shows if a _Password_ is set:

Command | Query | Response | Description
--- | --- | --- | ---
Ident Number | `02` `1f 02` | `06` `03` `1f 02` `42` | connection established to `42` (_LOGO!_ __0BA5__)
Operation Mode | `55` `17 17` `aa` | `06` `42` | operation mode _STOP_ (`42`, _RUN_ = `01`)
Read Byte | `02` `48 ff` | `06` `03` `48 ff` `40` | password exist _Y_ (= `40`, _N_ = `00`)
>Figure Example _Read Password_ __0BA5__

__Note:__ The commands order for reading and setting the password will not be described here. A program with password would not be protected otherwise. 

### Memory Access
The access is only available in mode _STOP_.

Here are a few example sequences for accessing the memory depending on operating mode:

```
 Set RTC
 Tx: 02 1f 02 55 17 17 aa 01 44 00 00
 Rx:
 @STOP 06 03 1F 02 42 06 42 06
 @RUN: 06 03 1F 02 42 06 01

 Detect LOGO! RUN?
 Tx: 55 17 17 AA
 Rx:
 @STOP 06 42
 @RUN 06 01

 Stop LOGO! RUN
 Tx: 55 12 12 AA
 Rx: 06

 Start LOGO!
 Tx: 55 18 18 AA
 Rx: 06

 Read the data
 Tx: 05 05 C0 00 40
 Rx:
 @STOP 06 ...
 @RUN n/a
```
>Figure Example _Memory Access_


----------

# Appendix C - Checksum Generation

## Checksum Generation
The _Checksum_ field is one byte, containing a 8–bit binary value. The Checksum value is calculated by the transmitting device, which appends the Checksum to the _Data_ field. The receiving device recalculates a Checksum during receipt of the message, and compares the calculated value to the actual value it received in the Checksum field. If the two values are not equal, an error results.

Only the data bytes of a message are used for generating the Checksum. _Command_, _Address_ and _Byte Count_ fields, and the _End_ delimiter, do not apply to the Checksum. 

### Example
The implementation is simple because only an 8-bit checksum must be calculated for a sequence of hexadecimal bytes. We use a function `F(bval,cval)` that inputs one data byte and a check value and outputs a recalculated check value. The initial value for `cval` is 0. The checksum can be calculated using the following example function (in C language), which we call repeatedly for each byte of the _Data_ field. The 8-bit checksum is the XOR off all bytes.

```
int F_chk_8( int bval, int cval )
{
  return ( bval ^ cval ) % 256;
}
```
>Figure Checksum implementation in C language

__Note:__ 
Therefore the Checksum value returned from the function can be directly placed into the message for transmission.
