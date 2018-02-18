# LOGO! PG Communication Protocol
The PG Interface used an undocumented protocol for program loading, diagnostics, etc.

The communication setting are:
- baud rate = 9600
- stop bit = 1
- parity = even

Thank you for your contribution to this work:
- Monitoring commands (well known)  
  * SNATAX @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") monitoring commands (0BA6)
  * cacalderon @ [https://forums.ni.com](https://forums.ni.com/t5/LabVIEW/LOGO-PLC-driver-based-on-LabVIEW/td-p/877701 "LOGO! PLC driver based on LabVIEW") monitoring commands (0BA5) and PC cable pinout
  * ask @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/21314/?page=0&pageSize=10 "Logo! Datenlogger") monitoring phyton script (0BA4)
  * Superbrudi @ [https://support.industry.siemens.com](https://support.industry.siemens.com/tf/ww/de/thread/posts/52023/?page=0&pageSize=10 "Excel Logo Logger Overview") monitoring excel VBA script (0BA5 and 0BA6)
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") low latency monitoring (@post 29)
- Clock/RTC commands
  * chengrui @ [http://www.ad.siemens.com.cn](http://www.ad.siemens.com.cn/club/bbs/post.aspx?a_id=637887&b_id=3 "Siemens s7-200 and LOGO communication")
- Passwort commands
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") password commands (@post 23)
- Address layout
  * kjkld @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") decodes most of the commands and the 0BA5 address space (@post 42)

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

LOGO! error code `:15` (NOK), followed by a error type (1 byte):

The error type `:xx` can be a transport or protocol error:
- `:01` Can not accept a telegram
- `:02` Resource unavailable / the second cycle of the write operation timed out
- `:03` Illegal access / read across the border
- `:04` parity, overflow or telegram error
- `:05` Unknown command / this mode is not supported
- `:06` XOR-check incorrect
- `:07` Faulty on simulation / RUN is not supported in this mode

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
3. Read bytes
  + _day_ to Address 00 FF FB 00
  + _month_ to address 00 FF FB 01
  + _year_ to address 00 FF FB 02
  + _minute_ to address 00 FF FB 03
  + _hour_ to address 00 FF FB 04
  + _day-of-week_ to address 00 FF FB 05

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
2. Write bytes
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
