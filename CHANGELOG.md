# Changelog
This CHANGELOG file should help that the library becomes a standardized open source project. All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.4] - 2018-03-04
### Added
- CHANGELOG added to the project folder.
- LogoClient::GetPlcDateTime

## 0.4.3 - 2018-03-01
### Added
- Examples CyclicReading.ino
- LogoClient::RecvControlResponse now with cyclic data reading

## 0.4.2 - 2018-02-27
### Added
- Examples FetchDataDemo.ino 

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
- LICENCE.md
- README.md

[Unreleased]: https://github.com/brickpool/logo/compare/v0.4.3...HEAD
[0.4.4]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.4.4...v0.4.3


