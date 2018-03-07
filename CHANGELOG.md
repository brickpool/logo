# Changelog
This CHANGELOG file should help that the library becomes a standardized open source project. All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.5.0-beta - 2018-03-06
### Added
- CHANGELOG added to the project folder
- Library Reference Manual (RefManual.md) added to the project folder
- LogoClient::GetPlcDateTime
- LogoClient::ReadByte, WriteByte and CpuError
- Example ReadClockDemo.ino

### Changed
- Customization of exception codes for LogoClient::CpuError
- LogoClient::RecvControlResponse uses the LogoClient::CpuError function
- Rename LOGO_CR to LOGO6_CR and LOGO_REVISION to LOGO4_CR
- LogoClient::RecvControlResponse uses the LogoClient::CpuError function

### Fixed
- Validation of DBNumber in LogoClient::ReadArea
- Exception Code in LogoClient::RecvControlResponse

## 0.4.3 - 2018-03-01
### Added
- Examples CyclicReading.ino
- LogoClient::RecvControlResponse now with cyclic data reading

## 0.4.2 - 2018-02-27
### Added
- Example FetchDataDemo.ino

### Changed
- Optimizations in LogoClient

### Fixed
- Serveral bug fixing

## 0.4.0 - 2018-02-26
### Added
- Now different memory models are supported
- LogoClient::RecvControlResponse

### Changed
- LogoHelper indexing from PDU to VM

### Removed
- LogoClient::RecvIOPacket

## 0.3.1 - 2018-02-24
### Changed
- PDU related constants
- struct of TPDU
- VM mapping table

## 0.3.0 - 2018-02-20
### Added
- First executable version, not fully tested
- Examples RunStopDemo.ino, ProtocolTester.ino
- VM mapping table

### Changed
- LogoClient::ReadArea
- LogoClient error codes

### Removed
- LogoClient::ErrorText

### Fixed
- PDU related constants
- _LOGO!_ Exception Codes
- LogoClient::ReadArea
- LogoClient::NegotiatePduLength
- LogoClient::PlcStop

## 0.2.0 - 2018-02-15:
Alpha version created, not tested.
### Added
- VM indexing
- LogoClient::ReadArea
- _LOGO!_ Exception codes

### Changed
- LogoClient::Serial to LogoClient::Stream
- Telegrams LOGO\_STATUS to LOGO\_MODE

### Removed 
- LogoClient::WaitForData

### Fixed
- Bug fix in LogoHelper for memory access to PDU
- Name of file keywords.txt

## 0.1.2 - 2018-02-13
### Changed
- Change licence from MIT to GPL-3.0, because Settimino is distributed as shared library with full source code under GNU Library or Lesser General Public License version 3.0

## 0.1.1 - 2018-02-12
### Added
- Pre alpha version of LogoPG.h, LogoPG.cpp, keywords.txt (not compiled, not tested)

## 0.1.0 - 2018-02-07
### Added
- Initial version created
- LICENCE.md added to the project
- README.md added to the project

[Unreleased]: https://github.com/brickpool/logo/compare/v0.4.3...HEAD
[0.5.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.5.0...v0.4.3

