# DTE-Interface for connecting the LOGO! PG-Cable

Rev. Aa

March 2018

## Compact RS232 to TTL Converter with Male DB9

The Model NS-RS232-02 from [NulSon Inc.](http://www.nulsom.com/) is a compact UART to RS232 Converter Module for connection the Arduino to the PG Cable. 

I have ordered this version, although I was not sure if the DB9 connector is standard and whether the necessary connection for the power supply (here RTS) is usable. The product works according to the [5-wire](https://en.wikipedia.org/wiki/RS-232#3-wire_and_5-wire_RS-232) RS232 standard. Therefore, it is well suited for our layout. 

### Specs.
- Convert TTL (__T__ransistor-__T__ransistor __L__ogic) level signals to __RS-232__ interface 
- D-SUB 9pin (RS232) __MALE__ connector mounting
- Supports 3V to 5.5V power supply (we must use 5V for our project)
- IC: SP3232
- Pitch: 2.54mm 
- RTS, CTS optionally available pins

### PIN Layout

DB9 Pin | Name | Signal
--- | --- | ---
1 | GND | Ground
2 | &darr; TX | Transmit Data
3 | &uarr; RX | Receive Data
4 | VCC | Voltage 5V
6 | RTS | Request to Send 1)

__Note:__ 1) Pin 4 and 6 have to be bridged to power the electronics in the PG-Cable. 

![alt text][RS232converter]
>Figure _RS232 Converter_ connected to the Arduino

### Usefull links
- [Compact RS232 to TTL Converter with Male DB9 (3.3V to 5V)](http://www.google.com/search?q=compact+rs232+ttl+converter+3.3v+to+5v+male "Google search")
- [NS-RS232-02 Datasheet](http://www.nulsom.com/datasheet/NS-RS232_en.pdf)

[RS232converter]: https://github.com/brickpool/logo/blob/master/extras/images/RS232_to_TTL_converter.jpg "RS232 to TTL Converter"
