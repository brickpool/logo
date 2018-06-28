# Logo33lib
Siemens (TM) LOGO! Library for Arduino

The library is based on the implementation of Settimino. The library support _LOGO!_ __0BA4__, __0BA5__ and __0BA6__ via the serial programming interface (PG-interface). In the future the library will also support the interface for the _Text Display_ (TD-interface) which is only available for the _LOGO!_ __0BA6__.

Information about the API is described in the document [LOGO! Library Reference Manual](/extras/docs/RefManual.md)

All information about the protocols are described in separate documents:
- [LOGO! PG Protocol Reference Guide (en)](/extras/docs/PG-Protocol.md)
- [LOGO! TD Protocol Reference Guide (ge)](/extras/de-DE/Dekodierung/TD-Dekodierung.md)

## Releases
The current library version is [0.5.0](https://github.com/brickpool/logo/releases). This version is not the final version, it is a release candidate, with patchlevel 0 and has implemented only the PG protocol. 

## Examples
This directory contains the library and some examples that illustrate how the library can be used. The examples were tested with an Arduino UNO. Other hardware has not been tried.
- [ProtocolTester.ino](/examples/ProtocolTester/ProtocolTester.ino) This example can mainly be used as a tester for the _LOGO!_ PG-protocol.
- [RunStopDemo.ino](/examples/RunStopDemo/RunStopDemo.ino) A simple program which connects to the _LOGO!_ controller and switches between the operating modes _RUN_ and _STOP_.
- [FetchDataDemo.ino](/examples/FetchDataDemo/FetchDataDemo.ino) The sample program uses the _LOGO!_ PG-protocol command _Fetch Data_.
- [CyclicReading.ino](/examples/CyclicReading/CyclicReading.ino) Cyclic reading of inputs, outputs and flags. The example uses the same function as the LOGO!Soft Routine _Online Test_.
- [ReadClockDemo.ino](/examples/ReadClockDemo/ReadClockDemo.ino) The example reads the date and time from the _LOGO!_ controller.
- [WriteClockDemo.ino](/examples/WriteClockDemo/WriteClockDemo.ino) The example writes a date and time to the _LOGO!_ controller.
- [PlcInfoDemo.ino](/examples/PlcInfoDemo/PlcInfoDemo.ino) The example reads the Ident Number, Firmware version and Protection level from the PLC.

## Dependencies
- _LOGO!_ controller version __0BA4__, __0BA5__ or __0BA6__, e.g. part number `6ED1052-1MD00-0BA6`
- _LOGO!_ PC cable, part number `6ED1057-1AA00-0BA0`
- Arduino board, e.g. [UNO](http://www.arduino.cc/)
- [DTE-Interface](/extras/docs/DTE-Interface.md) for connection to the Arduino board
- Arduino Time Library [TimeLib](https://github.com/PaulStoffregen/Time)
- For the examples, the alternative SoftwareSerial library [CustomSoftwareSerial](https://github.com/ledongthuc/CustomSoftwareSerial)

## License
The library is licensed under the [GNU Lesser General Public License v3.0](/LICENSE). However, Logo33lib distributes and uses code from other Open Source Projects that have their own licenses. 

## Credits
Logo33lib is created by J. Schneider.

Special thanks go to Davide Nardella for creating [Snap7](http://snap7.sourceforge.net/) and [Settimino](http://settimino.sourceforge.net/), Nei Seng for the analysis of the __0BA5__ and Jan Breuer for his [SerialPCAP](https://github.com/j123b567/SerialPCAP).
