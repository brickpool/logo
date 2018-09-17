# LOGO! Dissectors
Wireshark Dissectors for the serial _LOGO! PG_ and _TD protocol_ used by the _LOGO!_ PLC.

* __logopg.lua__ is a Wireshark dissector for the serial _PG protocol_ that is exchanged between the _PC_ (Personal Computer) and the _LOGO!_ __0BA4__, __0BA5__ or __0BA6__. 
* __logotd.lua__ is a small (and not complete!) Wireshark dissector for the _TD protocol_ that is exchanged between the _TD_ (Text Display) and the _LOGO!_ __0BA6__ over the serial _TD interface_ (_withdrawn_). 

The protocols run on a proprietary serial hardware. Currently Wireshark cannot capture from this proprietary hardware directly. An RS232 (_PG interface_) or RS485 (_TD interface_) monitor interface is required, which transfers the data to a serial interface from the PC.

The Dissectors are tested with the Serial port capture program [SerialPCAP](https://github.com/j123b567/SerialPCAP), written by Jan Breuer.
