# LOGO! PG Protocol Reference Guide
Rev. Aa

February 2018

## Preface
This guide is written for persons who will communicate with a Siemens (tm) LOGO! 0BA4, 0BA5 or 0BA6 using the PG Interface.The PG Interface used an undocumented protocol for program loading, diagnostics, etc. which is referred to here as PG protocol. This guide describes how messages are constructed, and how transactions take place by using the PG protocol. 

Siemens and LOGO! are registered trademarks of Siemens AG.

## Related Publications
Refer to the following publication for details about well known Monitoring commands:
  * SNATAX @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") monitoring commands (0BA6)
  * cacalderon @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") monitoring commands (0BA5) and PC cable pinout
  * ask @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/21314/?page=0&pageSize=10 "Logo! Datenlogger") monitoring phyton script (0BA4)
  * Superbrudi @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/52023/?page=0&pageSize=10 "Excel Logo Logger Overview") monitoring excel VBA script (0BA5 and 0BA6)
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") low latency monitoring (@post 29)

Refer to the following publications for details about the related communications for Clock/RTC Passwort commands:
  * chengrui @ [http://www.ad.siemens.com.cn](http://www.ad.siemens.com.cn/club/bbs/post.aspx?a_id=637887&b_id=3 "Siemens s7-200 and LOGO communication") clock commands
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") password commands (@post 23)

Refer to the following publication for details about the LOGO address layout:
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") decodes most of the commands and the 0BA5 address space (@post 42)

# Chapter 1 - PG Protocol

## Introducing PG Protocol
The common language used by all LOGO! devices is the PG protocol.This protocol defines a message structure that controllers will recognize and use, regardless of the type of networks over which they communicate.

Standard Interface cable for LOGO! 0BA0 to 0BA6 controllers use an [5-wire RS–232C](https://en.wikipedia.org/wiki/RS-232#3-wire_and_5-wire_RS-232) compatible serial interfacethat defines connector pinouts, cabling, signal levels, transmission baud rates, and parity checking.

The Siemens Software LOGO! Comfort communicate using a _master–slave technique_, in which only a personal computer called _DTE_ (data terminal equipment) can initiate transactions (called _queries_).The LOGO! device called _DCE_ (data communication equipment) respond by supplying the requested data to the DTE, or by taking the action requested in the query.

### The Query–Response Cycle
__The Query__: The function code in the query tells the LOGO device what kind of action to perform. The data bytes contain any additional information thatthe LOGO will need to perform the function. 

For example, function code `05` will query the LOGO to read a memory block and respond the content.The data field must contain the information telling the LOGO which adress to start at and how many bytes to read.

__The Response__: If the LOGO makes a normal response, the first byte in the response is an acknowledgement of the query.The acknowledge code allows the PC to confirm that the message contents are valid.The following data bytes contain the data collected by the LOGO, such a value or status.If an error occurs, the LOGO response is an error response, followed by on byte, which contain a exception code that describes the error.

## The Serial Transmission Mode

When the PC communicate to the LOGO controller with using the PG mode, each 8–bit byte in a message contains hexadecimal characters.The main advantage of this PG mode is that its greater character density allows better data throughput than for example ASCII for the same baud rate.Each message must be transmitted in a continuous stream. 

The specification for each communication via the PG Interface:

### Cable / Connectors:
- 5-wire TIA-574
- PC (DTE Connector) DE-9 male
- LOGO (DCE Connector) DE-9 female

### Pinout:
- [x] RxD Receive Data; DTE in direction; pin 2
- [x] TxD Transmit Data; DTE out direction; pin 3
- [x] DTR Data Terminal Ready; DTE out direction; pin 4 \*)
- [x] GND Ground; pin 5
- [ ] RTS Request to Send; DTE out direction; pin 7 \*)

>\*) DTS and/or RTS are used to power the plug electronics

### Baudrate / Bits per Byte:
- 9600 baud rate
- 1 start bit
- 8 data bits, least significant bit sent first
- 1 bit for even parity
- 1 stop bit
- DTS (or RTS) set to high (>= 5V)

### Coding System:
- 8–bit binary, hexadecimal 0–9, A–F

## PG Message Framing
All functions or commands are packed into a message by the sending device, which have a known structure or a defined end character (called _end delimiter_).

### How the Function Field is Handled
The function code field of a message frame contains eight bits. Valid codes are in the range of `01` to `55` hexadecimal.Some of these codes apply to all LOGO controllers, while some codes apply only to certain models.Current codes are described in Chapter 2.

When a message is sent from a DTE to a LOGO device the function code field tells the LOGO what kind of action to perform.Examples are to read the RUN/STOP operation mode; to read the data contents; to read the diagnostic status of the LOGO;to write some designated data; or to allow loading, recording, or verifying the program within the LOGO. 

When the LOGO responds to the DTE, it uses the function code field to indicate either a normal (error–free) response orthat some kind of error occurred (called an exception response).For a normal response, the LOGO simply confirm the message with an acknowledge function code.For an exception response, the LOGO returns an error code.

In addition to the error function code for an exception response, the LOGO places a unique code into the data field of the response message.This tells the DTE what kind of error occurred, or the reason for the exception.The DTE application program has the responsibility of handling exception responses.Typical processes are to post subsequent retries of the message, to try diagnostic messages to the LOGO, and to notify the operator.

### Contents of the Data Field
The data field is constructed using sets of two hexadecimal digits, in the range of `00` to `FF` hexadecimal.

The data field of messages sent from a DTE to the LOGO devices contains additional information which the LOGO must use to take the action defined by the function code.

For example, if the DTE requests the LOGO to read a group of data (function code `05`),the data field specifies the starting address and how many bytes are to be read.If the DTE writes to a group of data to the LOGO (function code 04), the data field specifies the starting adress,the count of data bytes to follow in the data field, and the data to be written into the registers. 

If no error occurs, the data field of a response from the LOGO to the DTE contains the data requested.If an error occurs, the field contains an exception code that the PDE application can use to determine the next action to be taken.

The data field can be nonexistent (length of zero) in certain kinds of messages.For example, in a request from the DTE to the LOGO to respond with his serial no (function code `21` hexadecimal),the LOGO does not require any additional information. The function code alone specifies the action.

### How Characters are Transmitted Serially
When messages are transmitted via the PG Interface, each byte is sent in this order (left to right):

  _Least Significant Bit (LSB) . . . Most Significant Bit (MSB)_

As a reminder, the communication takes place with parity check. The bit sequence is:

```
Start | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | Par | Stop
```
>Figure Bit Order

# Chapter 2 - Data and Control Functions

The Communication is divided into these categories:
- connection (`:21`)
- command (`:55`)
- read (`:02`)
- write (`:01`)

In general, the LOGO! device sends back a telegram for each request, but up to three steps are possible. The most important codes and types for a confirmation are:
- confirmation (`:06`)
- error (`:15`)
- data feedback (`:02` and `:55`)

## General response codes
LOGO! confirmation `:06` (OK), sometimes followed by more data.
> Example: operation mode STOP
```
:06:42
```

### Error / Exception Response
LOGO error function code `15` (NOK), followed by an exception type (1 byte):

The exception type can be a transport or protocol error:

Type | Name | Meaning
--- | --- | ---
`01` | DEVICE BUSY | LOGO can not accept a telegram
`02` | DEVICE TIMEOUT | Resource unavailable, the second cycle of the write operation timed out
`03` | ILLEGAL ACCESS | Illegal access, read across the border
`04` | PARITY ERROR | parity, overflow or telegram error
`05` | UNKNOWN COMMAND | Unknown command, this mode is not supported
`06` | XOR INCORRECT | XOR-check incorrect
`07` | SIMULATION ERROR | Faulty on simulation, RUN is not supported in this mode

> Example: this mode is not supported:
```
:15:05
```

LOGO! end delimiter `:aa` at variable data length

>Example
```
:aa
```

## Operating mode commands
Send to LOGO! to ask operation mode:

command | request | response | description
--- | --- | --- | ---
ask operation mode | `:55 :17:17 :aa` | `:06 :01` | LOGO! in RUN mode
ask operation mode | `:55 :17:17 :aa` | `:06 :42` | LOGO! in STOP mode

Send to LOGO! to change the operation mode:

command | request | response | description
--- | --- | --- | ---
set operation mode RUN | `:55 :18:18 :aa` | `:06` | LOGO! has successfully executed the command
set operation mode STOP | `:55 :12:12 :aa` | `:06` | LOGO! has successfully executed the command

## Connection
Send to LOGO! a hello request:

connection command | request | response | description
--- | --- | --- | ---
hello request to 0BA4 | `:21` |  | _no response_
hello request to 0BA5 | `:21` | `:06:03 :21:42` | LOGO! 0BA5
hello request to 0BA6 | `:21` | `:06:03 :21:43` | LOGO! 0BA6.Standard
hello request to 0BA6 | `:21` | `:06:03 :21:44` | LOGO! 0BA6

Send to LOGO! a connection request:

read command | request | response | description
--- | --- | --- | ---
connection request | `:02 :1f:02` | `:06:03 :1f :02:40` | LOGO! 0BA4 connection established
connection request | `:02 :1f:02` | `:06:03 :00:ff :1f :02:43` | LOGO! 0BA6 connection established

## Data communication
Send to LOGO! to ask data:
```
:55
:13:13
:00
:aa
```

LOGO! response with NOK (`:06`) or OK (`:15`) followed by data (length depends on device type)

Data length (incl. end delimiter `:aa`)
- 0BA4 = 68 bytes
- 0BA5 = 70 bytes
- 0BA6 = 80 bytes

>LOGO! 0BA4.Standard output example:
```
:06
:55:11:11:40:00:7f:66:11:2a:00:80:01:10:00:00:00
:00:00:00:00:00:00:00:00:00:00:a8:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:aa
```

>LOGO! 0BA6.Standard output example:
```
:06
:55:11:11:4a:00:b7:c4:19:2c:00:10:84:6b:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:aa
```

### Read Clock

Read commands for RTC:
1. Device status inquiry
2. Write byte `:00` to Address 00 FF 44 00 to initialize reading
3. Read byte(s)
  + _day_ at Address 00 FF FB 00
  + _month_ at address 00 FF FB 01
  + _year_ at address 00 FF FB 02
  + _minute_ at address 00 FF FB 03
  + _hour_ at address 00 FF FB 04
  + _day-of-week_ at address 00 FF FB 05

>Example: sent _read clock_:
```
:21           hello request
:55:17:17:aa  ask operation mode

:01           write command
:00:ff:44:00  address (clock initialized)
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

>Example: receive _read clock_:
```
:06:03:21:44  inquiry resonse
:06:42        operation mode STOP

:06           write completed

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


### Write clock:

Write commands for RTC:
1. Device status inquiry
2. Write byte(s)
  + _day_ to Address 00 FF FB 00
  + _month_ to address 00 FF FB 01
  + _year_ to address 00 FF FB 02
  + _minute_ to address 00 FF FB 03
  + _hour_ to address 00 FF FB 04
  + _day-of-week_ to address 00 FF FB 05
3. Write byte `:00` to Address 00 FF 43 00 to comfirm

>Example: sent _write clock_:
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
:01           write command
:00:ff:43:00  adress (clock confirm)
:00           value 0x00
```

>Example: receive _write clock_:
```
:06:03:21:44  inquiry resonse
:06:42        operation mode STOP

:06           write completed (day)
:06           write completed (month)
:06           write completed (year)
:06           write completed (minute)
:06           write completed (hour)
:06           write completed (day of week)
:06           write completed (clock start/stop)
```
