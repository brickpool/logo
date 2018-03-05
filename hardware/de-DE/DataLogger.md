# DataLogger
Rev. Ac

März 2018

## Hardware
Auf Basis eines Arduino UNO und einem [Data Logger Shield](https://learn.adafruit.com/adafruit-data-logger-shield/overview) von Adafruit (alte Version) wird ein Datenlogger-Modul für das _LOGO!_ der Baureihe __0BA6__ (__0BA4__ und __0BA5__ sollten ebenfalls unterstützt werden, ist jedoch nicht getestet) hergestellt.

Damit das PG-Interface an das Arduino mit Shield angeschlossen werden kann, wird eine RS-232 Schnittstelle (offiziell [TIA/EIA-232-F](https://de.wikipedia.org/wiki/RS-232)) benötigt. Der Arduino UNO fungiert als Terminal (_DTE_) und die Kleinsteuerung _LOGO!_ als Übertragungseinrichtung (_DCE_).

Bei den oben genannten Arduino-Shields wird jedoch sehr oft auf jegliche Flusssteuerung verzichtet, so dass nur die Leitungen von RxD, TxD und GND (Masse) verdrahtet werden. Die Ausführung der Schnittstelle mit nur drei Drähten ([3-wire](https://en.wikipedia.org/wiki/RS-232#3-wire_and_5-wire_RS-232)) langt jedoch nicht für die Versorgung der integrierten Optokoppler und des Schnittstellenwandlers vom Siemens PG-Kabel.

Ohne Anpassung sind weder das [RS232 Shield von SparkFun (V2)](https://www.sparkfun.com/products/retired/13029), [Seeed (V1)](http://wiki.seeed.cc/RS232_Shield/) oder [Tinysine (RS232/485 Shield)](http://www.tinyosshop.com/arduino-rs232-rs485-shield), noch die [RS232 Shifter von SkarkFun](https://www.sparkfun.com/products/449) bzw. China-Clones nutzbar, da die Spannung vom Anschluss DTR (und RTS) zur Versorgung verwendet wird.

Da in jedem Fall zu Lötkolben gegriffen werden muss, habe ich mich entschlossen die RS232-Schnittstelle mit notwendigen Pegelwandler auf dem Prototyping-Bereich vom Data Logger Shield unterzubringen. 

## Schaltung
Der Schaltungsentwurf von „Werner Kriegmeier“ ([Elektor 7-8/1999](https://www.elektormagazine.de/magazine/elektor-199907/31905)) bietet die notwendigen Informationen zur Beschaltung des Siemens PG-Kabels (DCE). Basierend darauf wird die passende _DTE_ Schaltung im Prototypeing-Bereich vom Data Logger Shield ein MAX232 Level-Shifter ([Conrad #152281](http://www.google.de/search?q=Conrad+152281)) inkl. vier 1µF Kondensatoren ([Conrad #453382](http://www.google.de/search?q=Conrad+453382)) für die Datenleitungen RX, TX und die Versorgung der Signalleitung DTR eingebracht.

Damit die Möglichkeit zum Monitoring am PC erhalten bleibt, kommt nicht die Standard-Schnittstelle ([HardwareSerial](https://www.arduino.cc/reference/en/language/functions/communication/serial/)) über Pin 0 und 1 vom Arduino UNO zur Anwendung, sondern es werden unter Nutzung der [CustomSoftwareSerial](https://github.com/ledongthuc/CustomSoftwareSerial) Bibliothek die Pins 2 für RX (TTL Pin 9 von IC1) und Pin 3 für TX (TTL Pin 10 von IC1) verwendet. Zur Versorgung der Elektronik im PG-Kabel wird DTR an 5V gelegt. 

Der 9polige D-Sub-Stecker ([Conrad #716690](http://www.google.de/search?q=Conrad+716690)) wird über einen Pfostenstecker ([Conrad #741648](http://www.google.de/search?q=Conrad+741648)) am Data Logging Shield verbunden.
