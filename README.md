# LogoPG
Siemens (tm) LOGO! Library for Arduino

The library is based on the implementation of Settimino. Only _LOGO!_ __0BA4__ to __0BA6__ are supported via the serial programming interface.

All information about the protocol is described in a separate document: [LOGO! PG Protocol Reference Guide](/doc/PG-Protocol.md)

## Releases
The current library version is [0.4.3](https://github.com/brickpool/logo/releases). This version is not the final version, it is a release candidate 4, with patchlevel 3.

## Examples
This directory contains the library and some examples that illustrate how the library can be used. The examples were tested with an Arduino UNO. Other hardware has not been tried.
- [ProtocolTester.ino](/examples/ProtocolTester/ProtocolTester.ino) This example can mainly be used as a tester for the _LOGO!_ PG-protocol.
- [RunStopDemo.ino](/examples/RunStopDemo/RunStopDemo.ino) A simple program which connects to the _LOGO!_ controller and switches between the operating modes _RUN_ and _STOP_.
- [FetchDataDemo.ino](/examples/FetchDataDemo/FetchDataDemo.ino) The sample program uses the _LOGO!_ PG-protocol command _Fetch Data_.
- [CyclicReading.ino](/examples/CyclicReading/CyclicReading.ino) Cyclic reading of inputs, outputs and flags. The example uses the same function as the LOGO!Soft Routine _Online Test_.

## Dependencies
- Arduino board, e.g. UNO
- _LOGO!_ controller, release __0BA4__, __0BA5__ or __0BA6__

## License
The library is licensed under the [GNU Library or Lesser General Public License version 3.0](/LICENSE). However, LogoPG distributes and uses code from other Open Source Projects that have their own licenses. 

## Credits
LogoPG is created by J. Schneider.

Special thanks go to Davide Nardella for creating [Snap7](http://snap7.sourceforge.net/) and [Settimino](http://settimino.sourceforge.net/), Nei Seng for the analysis of the 0BA5 and Jan Breuer for his [SerialPCAP](https://github.com/j123b567/SerialPCAP).
