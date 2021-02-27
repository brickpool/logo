# Changelog
This CHANGELOG file should help that the library becomes a standardized open source project. All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2021-02-27

### Added
- Support of three privileged levels LogoClient::SetSessionPassword, LogoClient::ClearSessionPassword
- Parameter Mode `RUN_P` LogoClient::GetPlcStatus
- Updated examples for compatibility with Arduino Leonado boards

### Changed
- Update Library Reference Manual (RefManual.md) to Rev. Ak
- Protection Level in LogoClient::GetProtection

### Fixed
- Output in example PlcInfoDemo.ino

## [0.5.3] - 2021-01-17
### Added
- Example LogoClient::SerialPlotter.ino added to the project folder
- Updated examples for compatibility with Arduino MKR boards
- Block oriented function LogoClient::GetDBSize
- Block oriented function LogoClient::DBGet
- DebugUtils in LogoPG.h and LogoPG.cpp

### Changed
- Using fixed-width integer types regardless of which Arduino is being targeted

### Removed
- ArduinoLog in LogoPG.h and LogoPG.cpp

### Fixed
- Example ProtocolTester.ino maximum indexing for receivedChars

## [0.5.2] - 2020-12-23
### Added
- Low Level function LogoClient::ReadBlock
- Security function LogoClient::SetSessionPassword
- Security function LogoClient::ClearSessionPassword
- Logging (library ArduinoLog)

### Changed
- Protection Level in GetProtection
- Update Library Reference Manual (RefManual.md) to Rev. Ai
- DTE Interface Images
- Update Examples for compatibility with Arduino Mega boards

### Fixed
- GetOrderCode: Support of 0BA6.ES10
- StreamConnect: Clearing serial buffer for Reconnection
- ReadArea: VM Mapping (correct access to the program space)
- Reduce some compiler warnings

## [0.5.1] - 2018-09-18
### Added
- Support of 0BA6.ES10
- Wiki Page

### Changed
- Move "Undocumented LOGO! 0BA5" to the Wiki
- Move "LOGO! PG Protocol Reference Guide" to the Wiki

## [0.5.0] - 2018-03-29
### Added
- CHANGELOG.md added to the project folder
- Library Reference Manual (RefManual.md) added to the project folder
- DTE Interface description (DTE-Interface.md) added to the project folder
- Date/Time functions: LogoClient::GetPlcDateTime and WritePlcDateTime
- System info function: LogoClient::GetOrderCode
- Private functions: LogoClient::GetOrderCode, WriteByte and CpuError
- Security function: LogoClient::GetProtection
- Example ReadClockDemo.ino and WriteClockDemo.ino added to the project folder
- Example PlcInfoDemo.ino added to the project folder

### Changed
- Customization of CPU Exception Codes for LogoClient::CpuError
- LogoClient::RecvControlResponse uses the LogoClient::CpuError function
- Rename LOGO_CR to LOGO6_CR and LOGO_REVISION to LOGO4_CR

### Removed
- typedef pstream for Stream*

### Fixed
- Validation of DBNumber and Start in LogoClient::ReadArea
- Reading Exception Code in LogoClient::RecvControlResponse

## 0.4.3 - 2018-03-01
### Added
- Example CyclicReading.ino added to the project folder

### Changed
- LogoClient::RecvControlResponse now with cyclic data reading

## 0.4.2 - 2018-02-27
### Added
- Example FetchDataDemo.ino added to the project folder

### Changed
- Optimizations in LogoClient

### Fixed
- Several bug fixes

## 0.4.0 - 2018-02-26
### Added
- Now different memory models are supported (as in Settimino)
- LogoClient::RecvControlResponse

### Changed
- LogoHelper indexing from PDU to VM
- Update file PG-protocol.md to Rev. Bg

### Removed
- LogoClient::RecvIOPacket

## 0.3.1 - 2018-02-24
### Changed
- PDU related constants
- struct of TPDU
- VM mapping table

## 0.3.0 - 2018-02-20
### Added
- First executable version (not fully tested)
- Example ProtocolTester.ino added to the project folder
- Example RunStopDemo.ino added to the project folder
- VM mapping table for assigning the inputs, outputs and flags to the 0BA7 address layout
- Rev. B: LOGO! PG Protocol Reference Guide (PG-protocol.md) created

### Changed
- LogoClient::ReadArea
- LogoClient error codes
- Update in file keywords.txt

### Removed
- LogoClient::ErrorText

### Fixed
- PDU related constants
- CPU Exception Codes
- LogoClient::ReadArea
- LogoClient::NegotiatePduLength
- LogoClient::PlcStop

## 0.2.0 - 2018-02-19
### Added
- Rev. A: LOGO! PG Protocol Reference Guide (PG-protocol.md) added to the project folder

## 0.2.0-alpha - 2018-02-15
### Added
- VM indexing
- LogoClient::ReadArea
- CPU Exception Codes

### Changed
- LogoClient::Serial to LogoClient::Stream
- Telegrams LOGO\_STATUS to LOGO\_MODE

### Removed 
- LogoClient::WaitForData

### Fixed
- LogoHelper memory access to PDU
- Name of file keywords.txt

## 0.1.2 - 2018-02-13
### Changed
- Change licence from MIT to GPL-3.0, because Settimino is distributed as shared library with full source code under GNU Library or Lesser General Public License version 3.0

## 0.1.0-alpha - 2018-02-12
### Added
- Pre alpha version of the Library (not compiled, not tested)
- LogoPG.h added to the project folder
- LogoPG.cpp added to the project folder
- keywords.txt added to the project folder

## 0.1.0-pre-alpha - 2018-02-07
### Added
- Initial version created
- LICENCE.md added to the project
- README.md added to the project

[Unreleased]: https://github.com/brickpool/logo/compare/v0.5.3...HEAD
[0.5.3]: https://github.com/brickpool/logo/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/brickpool/logo/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/brickpool/logo/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/brickpool/logo/compare/v0.4.3...v0.5.0
