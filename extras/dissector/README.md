# LOGO! Dissectors
A Wireshark dissector for the serial LOGO PG and TD protocol used by the _LOGO!_ PLC

* __logopg.lua__ is a Wireshark dissector for the serial __PG protocol__ that is exchanged between the PC and the _LOGO!_ __0BA4__ to __0BA6__. 
* __logotd.lua__ is a small (and not complete!) Wireshark dissector for the __TD protocol__ that is exchanged between the _TD_ (Text Dispplay) and the _LOGO!_ __0BA6__. 

The Dissectors are tested with the Serial port capture program [SerialPCAP](https://github.com/j123b567/SerialPCAP), written by Jan Breuer. 