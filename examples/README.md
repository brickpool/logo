# Examples
This directory contains the library and some examples that illustrate how the library can be used.

- [ProtocolTester.ino](/examples/ProtocolTester/ProtocolTester.ino) This example can mainly be used as a tester for the _LOGO!_ PG-protocol.
- [RunStopDemo.ino](/examples/RunStopDemo/RunStopDemo.ino) A simple program which connects to the _LOGO!_ controller and switches between the operating modes _RUN_ and _STOP_.
- [FetchDataDemo.ino](/examples/FetchDataDemo/FetchDataDemo.ino) The sample program uses the _LOGO!_ PG-protocol command _Fetch Data_.
- [CyclicReading.ino](/examples/CyclicReading/CyclicReading.ino) Cyclic reading of inputs, outputs and flags. The example uses the same function as the LOGO!Soft Routine _Online Test_.
- [ReadClockDemo.ino](/examples/ReadClockDemo/ReadClockDemo.ino) The example reads the date and time from the _LOGO!_ controller.
- [WriteClockDemo.ino](/examples/WriteClockDemo/WriteClockDemo.ino) The example writes a date and time to the _LOGO!_ controller.
- [PlcInfoDemo.ino](/examples/PlcInfoDemo/PlcInfoDemo.ino) The example reads the Ident Number, Firmware version and Protection level from the PLC.
- [SerialPlotter.ino](/examples/SerialPlotter/SerialPlotter.ino) This example allowing you to natively graph data from your _LOGO!_ controller by using the Arduino Serial Plotter function.

## Dependencies

Some examples need addional libraries.

- Arduino Time Library [TimeLib](https://github.com/PaulStoffregen/Time)
- Simple log library [ArduinoLog](https://github.com/thijse/Arduino-Log)
- Alternative SoftwareSerial library [CustomSoftwareSerial](https://github.com/ledongthuc/CustomSoftwareSerial)

## Boards

The examples were tested with the following Boards. Other hardware has not been tried.

- Arduino UNO (only Arduino IDE 1.8.5 is supported)
- Arduino Leonado (Arduino IDE 1.8.13)
- Arduino Mega (Arduino IDE >= 1.8.5)
- Arduino MKR WiFi 1010 (Arduino IDE 1.8.13)
