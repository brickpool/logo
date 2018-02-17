# LOGO! PG Communication Protocol
The PG Interface used an undocumented oritocol for program loading, diagnostics, etc.

The communication setting are:
- baud rate = 9600
- stop bit = 1
- parity = even

In general, the LOGO! device sends back a telegram with every request

## General response codes
> LOGO! response OK
```
:06
```

>LOGO! returned an error code _0x15_ (NOK), followed by a error type (1 byte):
```
:15
:XX
```

The error type _0xXX_ can be a transport or protocol error: 
- 0x01 LOGO can not accept a telegram
- 0x02 Resource unavailable
- 0x03 Illegal access
- 0x04 parity error-, overflow or telegram error
- 0x05 Unknown command
- 0x06 XOR-check incorrect
- 0x07 Faulty on simulation 

>LOGO! end delimiter
```
:aa
```

## Operating mode commands
Send to LOGO! to ask operation mode:
```
:55
:17:17
:aa
```

>LOGO! in RUN mode
```
:06
:01
```

>LOGO! in STOP mode
```
:06
:42
```

Send to LOGO! to change to operation mode to RUN:
```
:55
:18:18
:aa
```

Send to LOGO! to to change to operation mode to STOP:
```
:55
:12:12
:aa
```

>LOGO! has successfully executed the operation command
```
:06
```

## Connection
Send to LOGO! a connection request
```
02:1f:02
```

>LOGO! 0BA4.Standard connection established
```
:06:03
:1f
:02:40
```

>LOGO! 0BA6.Standard connection established
```
:06:03
:00:ff
:1f
:02:43
```


## Data communication
Send to LOGO! to ask data:
```
:55
:13:13
:00
:aa
```

LOGO! response with NOK (_0x06_) or OK (_0x15_) followed by data (length depends on device type)

Data length (incl. end delimiter _0xAA_)
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

## 0BA6 only
Send to LOGO! a inquiry request:
```
:21
```

>LOGO! inquiry resonse:
```
:06:03
:21:XX
```
The type _0xXX_ can have following values, for example: 
- 0x43 LOGO! 06BA.Standard
- 0x44 LOGO! 06BA


### Reception example
Sent:
```
:21               inquiry request
:55:17:17:aa      ask operation mode
```

>Receive:
```
:06:03:21:44      inquiry resonse
:06:42            program Status STOP
```


### Read Clock example

Read commands for RTC:
1. Device status inquiry
2. Write byte 0x00 to Address 00 FF 44 00
3. Read byte <day> to Address 00 FF FB 00
4. Read byte <month> to address 00 FF FB 01
5. Read byte <date> to address 00 FF FB 02
6. Read byte <time> to address 00 FF FB 03
7. Read byte <hour> to address 00 FF FB 04
8. Read byte <day of week> to address 00 FF FB 05

Sent:
```
:21           inquiry request
:55:17:17:aa  ask operation mode

:01           write command 
:00:ff:44:00  address (?)
:00           value = 0x00

:02           read command
:00:ff:fb:00  address (day)
:02           read command
:00:ff:fb:01  address (month)
:02           read command
:00:ff:fb:02  address (date)
:02           read command
:00:ff:fb:03  address (time)
:02           read command
:00:ff:fb:04  address (hour)
:02           read command
:00:ff:fb:05  address (day of week)
```

>Receive:
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
:00:ff:fb:02  address (date)
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


### Write clock example:

Write commands for RTC:
1. Device status inquiry
2. Write byte <day> to Address 00 FF FB 00
3. Write byte <month> to address 00 FF FB 01
4. Write byte <date> to address 00 FF FB 02
5. Write byte <time> to address 00 FF FB 03
6. Write byte <hour> to address 00 FF FB 04
7. Write byte <day of week> to address 00 FF FB 05
8. Start/stop the clock

Sent:
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
:00:ff:fb:02  address (date)
:09           value = 09
:01           write command
:00:ff:fb:03  address (time)
:24           value = 36
:01           write command
:00:ff:fb:04  address (hour)
:14           value = 20
:01           write command
:00:ff:fb:05  address (day of week)
:03           value = 03
:01           write command
:00:ff:43:00  adress (clock start/stop)
:00           value 0x00 (start)
```

>Receive:
```
:06:03:21:44  inquiry resonse
:06:42        operation mode STOP

:06           write completed (day)
:06           write completed (month)
:06           write completed (date)
:06           write completed (time)
:06           write completed (hour)
:06           write completed (day of week)
:06           write completed (clock start/stop)
```
