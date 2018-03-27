# DTE-Interface

Ausgabe Af

März 2018

## Hardware
Auf Basis eines Arduino UNO mit RS-232 Schnittstellte wird eine Verbindung zu einem _LOGO!_ der Baureihe __0BA5__ (__0BA4__ und __0BA6__ sollten ebenfalls unterstützt werden) hergestellt.

Damit das PG-Interface an das Arduino mit Shield angeschlossen werden kann, wird eine RS-232 Schnittstelle (offiziell [TIA/EIA-232-F](https://de.wikipedia.org/wiki/RS-232)) benötigt. Der Arduino UNO fungiert als Terminal (_DTE_) und die Kleinsteuerung _LOGO!_ als Übertragungseinrichtung (_DCE_).

Ohne Gender-Changer (Stecker-Stecker) und weiteren Anpassung sind weder das [RS232 Shield von SparkFun (V2)](https://www.sparkfun.com/products/retired/13029), [Seeed (V1)](http://wiki.seeed.cc/RS232_Shield/) noch das [Tinysine (RS232/485 Shield)](http://www.tinyosshop.com/arduino-rs232-rs485-shield) nutzbar.

Auch bei den [RS232 Shifter von SkarkFun](https://www.sparkfun.com/products/449) bzw. China-Clones wird üblicherweise auch auf eine Flusssteuerung verzichtet, so dass oft nur die Leitungen von RxD, TxD, GND (Masse) und VCC (Positive Spannung 5V) verdrahtet sind. Die Ausführung der Schnittstelle mit nur drei Drähten ([3-wire](https://en.wikipedia.org/wiki/RS-232#3-wire_and_5-wire_RS-232)) langt jedoch nicht, da die Spannung vom Anschluss DTR (oder RTS) zur Versorgung der integrierten Optokoppler und des Schnittstellenwandlers vom Siemens PG-Kabel benötigt werden. 

Fazit: Sofern nicht zum Lötkolben gegriffen werden soll, scheint es nur wenig Auswahl an vorkonfektionierter Hardware zu geben. So habe ich nur zwei RS232 zu TTL Konverter gefunden, die den Anforderungen entprechen (DTE-Interface mit Flussteuerung):
- Model NS-RS232-02 from [NulSom Inc.](http://www.nulsom.com/)
- [RS232 SP3232 TTL to male serial port TTL to RS232](http://www.google.de/search?q=192090081615)

Ich habe mich jedoch entschlossen die RS232-Schnittstelle mit notwendigen Pegelwandler auf einem [Prototype-Shield](#Schaltung) unterzubringen. Nähres im folgendem Abschnitt.

![alt text][DTEshield]
>Abb: VeeCad Layout

## Schaltung
Der Schaltungsentwurf von „Werner Kriegmeier“ ([Elektor 7-8/1999](https://www.elektormagazine.de/magazine/elektor-199907/31905)) bietet die notwendigen Informationen zur Beschaltung des Siemens PG-Kabels (DCE). Basierend darauf wird die passende _DTE_ Schaltung im Prototypeing-Bereich ein MAX232 Level-Shifter ([Conrad #152281](http://www.google.de/search?q=Conrad+152281)) inkl. fünf 1µF Kondensatoren ([Conrad #453382](http://www.google.de/search?q=Conrad+453382)) für die Datenleitungen RX, TX und die Versorgung der Signalleitung DTR eingebracht.

Damit die Möglichkeit zum Monitoring am PC erhalten bleibt, kommt nicht die Standard-Schnittstelle ([HardwareSerial](https://www.arduino.cc/reference/en/language/functions/communication/serial/)) über Pin 0 und 1 vom Arduino UNO zur Anwendung, sondern es werden unter Nutzung der [CustomSoftwareSerial](https://github.com/ledongthuc/CustomSoftwareSerial) Bibliothek die Pins 2 für RX (TTL Pin 9 von IC1) und Pin 3 für TX (TTL Pin 10 von IC1) verwendet. Zur Versorgung der Elektronik im PG-Kabel wird DTR fest verdrahtet (Pin 11 von IC1 an Masse, Pin 14 von IC1 an Pin 4 vom DB9-Stecker). 

Der 9polige D-Sub-Stecker ([Conrad #716690](http://www.google.de/search?q=Conrad+716690)) wird über einen Pfostenstecker ([Conrad #741648](http://www.google.de/search?q=Conrad+741648)) mit dem Shield verbunden. 

![alt text][DTEcircuit]
Abb: TinyCad Schaltung

[DTEshield]: https://github.com/brickpool/logo/blob/master/extras/images/DTE-Interface_Shield_Layout.png "DTE Interface Shield"

[DTEcircuit]: https://github.com/brickpool/logo/blob/master/extras/images/DTE-Interface_Shield_Schematic.png "DTE Interface Circuit"
