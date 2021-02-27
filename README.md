# Logo33lib
Siemens (TM) LOGO! Library for Arduino

The library is based on the implementation of [Settimino](http://settimino.sourceforge.net/). The library support _LOGO!_ __0BA4__, __0BA5__ and __0BA6__ via the serial programming interface (PG-interface). In the future the library will also support the interface for the _Text Display_ (TD-interface) which is only available for the _LOGO!_ __0BA6__ and __0BA7__.

Information about the API is described in the document [LOGO! Library Reference Manual](/extras/docs/RefManual.md).

All information about the protocols and details to the _LOGO!_ PLC are described in the associated [Wiki](http://github.com/brickpool/logo/wiki).

## Releases
The current library version is [0.5.3](http://github.com/brickpool/logo/releases). This version is not the final version, it is a release candidate and has implemented only the PG protocol.

## Examples
The [examples](http://github.com/brickpool/logo/tree/master/examples) directory contains some examples that illustrate how the library can be used. 

## Dependencies
- _LOGO!_ controller version __0BA4__, __0BA5__ or __0BA6__, e.g. part number `6ED1052-1MD00-0BA6`
- _LOGO!_ PC cable, part number `6ED1057-1AA00-0BA0`
- [Arduino board](http://www.arduino.cc/), e.g. Leonado or MKR WiFi 1010
- [DTE-Interface](https://github.com/brickpool/logo/wiki/DTE-Interface) for connection to the Arduino board
- Arduino Time Library [TimeLib](https://github.com/PaulStoffregen/Time) for memory model `_EXTENDED`

## License
The library is licensed under the [GNU Lesser General Public License v3.0](/LICENSE) (same as [Settimino](http://settimino.sourceforge.net/)). However, this library distributes and uses code from other Open Source Projects that have their own licenses. 

## Credits
This library is created by J. Schneider.

Special thanks go to Davide Nardella for creating [Snap7](http://snap7.sourceforge.net/) and [Settimino](http://settimino.sourceforge.net/) and Nei Seng for the analysis of the __0BA5__.
