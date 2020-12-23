/*
 * LogoPG library, Version 0.5.2-20201223
 *
 * Portion copyright (c) 2018,2020 by Jan Schneider
 *
 * LogoPG provided a library under ARDUINO to read data from a
 * Siemens(tm) LOGO! PLC via the serial programing interface.
 * Only LOGO 0BA4 to 0BA6 are supported.
 *
 ***********************************************************************
 *
 * This file is based on the implementation of SETTIMINO Version 1.1.0
 * The project SETTIMINO is an ARDUINO Ethernet communication library
 * for S7 Siemens(tm) PLC
 *
 * Copyright (c) of SETTIMINO 2013 by Davide Nardella
 *
 * SETTIMINO is free software: we can redistribute it and/or modify
 * it under the terms of the Lesser GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License.
 *
 * Please visit http://settimino.sourceforge.net/ for more information
 * of SETTIMINO
 *
 ***********************************************************************
 *
 * Changelog: https://github.com/brickpool/logo/blob/master/CHANGELOG.md
 *
*/

#include "Arduino.h"
#ifdef _EXTENDED
#include "TimeLib.h"
#endif
#include "LogoPG.h"
#include <avr/pgmspace.h>
#include "ArduinoLog.h"

// For further informations about the structures, command codes, byte arrays and their meanings
// see http://github.com/brickpool/logo

/*
  Arduino has not a multithreaded environment and we can only use one LogoClient instance.
  To save memory we can define telegrams and data areas as globals, since only one client can be used at time.
*/


// LOGO 0BA4 Connection Request (Read Ident Number)
const byte LOGO4_CR[] = {
  0x02, 0x1F, 0x02
};

// LOGO 0BA6 Connection Request
const byte LOGO6_CR[] = {
  0x21
};

// LOGO Confirmation Request
const byte LOGO_ACK[] = {
  0x06
};

// LOGO Fetch PLC Data Request Telegram
const byte LOGO_FETCH_DATA[] = {
  0x55, 0x13, 0x13, 0x00, 0xAA
};

#ifdef _EXTENDED

// LOGO Put PLC in STOP state Telegram
const byte LOGO_STOP[] = {
  0x55, 0x12, 0x12, 0xAA
};

// LOGO Put PLC in RUN state Telegram
const byte LOGO_START[] = {
  0x55, 0x18, 0x18, 0xAA
};

// LOGO Operation Mode Request Telegram
const byte LOGO_MODE[] = {
  0x55, 0x17, 0x17, 0xAA
};

#define ADDR_CLK_W_GET      0x00FF4400UL
#define ADDR_CLK_RW_DAY     0x00FFFB00UL
#define ADDR_CLK_RW_MONTH   0x00FFFB01UL
#define ADDR_CLK_RW_YEAR    0x00FFFB02UL
#define ADDR_CLK_RW_MINUTE  0x00FFFB03UL
#define ADDR_CLK_RW_HOUR    0x00FFFB04UL
#define ADDR_CLK_RW_DOW     0x00FFFB05UL
#define ADDR_CLK_W_SET      0x00FF4300UL

const PROGMEM char ORDER_CODE[Size_OC] = "6ED1052-xxx00-0BAx";
#define ADDR_OC_R_ASC_V     0x00FF1F03UL  // ASCII = V
#define ADDR_OC_R_MAJOR     0x00FF1F04UL  // ASCII = X.__.__
#define ADDR_OC_R_MINOR1    0x00FF1F05UL  // ASCII = _.X_.__
#define ADDR_OC_R_MINOR2    0x00FF1F06UL  // ASCII = _._X.__
#define ADDR_OC_R_PATCH1    0x00FF1F07UL  // ASCII = _.__.X_
#define ADDR_OC_R_PATCH2    0x00FF1F08UL  // ASCII = _.__._X

#define ADDR_PWD_W_ACCESS   0x00FF4740UL  // Password access
#define ADDR_PWD_R_MAGIC1   0x00FF1F00UL  // Password 1st magic byte (= 0x04)
#define ADDR_PWD_R_MAGIC2   0x00FF1F01UL  // Password 2nd magic byte (= 0x00)
#define ADDR_PWD_R_EXISTS   0x00FF48FFUL  // Password exist (Y = 0x40, N = 0x00)
#define ADDR_PWD_R_MEM      0x00FF0566UL  // Password storage
#define ADDR_PWD_W_OK       0x00FF4800UL  // Password ok

#endif // _EXTENDED

// There are 3 privilege levels ranging from 0 which is the least privileged,
// to 15 which is most privileged.
#define PWD_LEVEL_ZERO          0x00    // unknown, limited in operation mode RUN
#define PWD_LEVEL_RESTRICTED    0x01    // restricted access in operation mode STOP
#define PWD_LEVEL_FULL          0x0F    // full access in operation mode STOP

// If an error has occurred, the LOGO send a negative confirmation 0x15 (NOK)
// and then an error byte with the following codes
#define cpuCodeDeviceBusy       0x01    // LOGO can not accept a telegram
#define cpuCodeDeviceTimeOut    0x02    // Resource unavailable
#define cpuCodeInvalidAccess    0x03    // Illegal access
#define cpuCodeParityError      0x04    // parity error-, overflow or telegram error
#define cpuCodeUnknownCommand   0x05    // Unknown command
#define cpuCodeXorIncorrect     0x06    // XOR-check incorrect
#define cpuCodeSimulationError  0x07    // Faulty on simulation

// Since the millis() is unsigned long, also the testing
// and updating the time must be done with unsigned long.
// https://playground.arduino.cc/Code/TimingRollover
#define TIMEOUT       500UL             // set timeout between 200 and 600 ms
#define CYCLETIME     600UL             // set cycle time for function 0x13 between 190 and 600 ms

#define VM_START      0                 // first valid address
#define VM_USER_AREA  0                 // user defined area
#define VM_NDEF_AREA1 851               // not defined area #1
#define VM_0BA7_AREA  923               // area for 0BA7
#define VM_DDT_AREA   984               // diagnostic, date and time area
#define VM_NDEF_AREA2 1003              // not defined area #2
#define VM_END        1023              // last valid address

#define VM_FIRST      VM_0BA7_AREA      // first address for access
#define VM_LAST       VM_DDT_AREA       // last address for access

// Store mapping in flash (program) memory instead of SRAM

/*
  // VM Mapping byte 851 to 922
  const byte VM_MAP_851_922[] PROGMEM =
  {
                    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 851-855
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 856-863
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 872-863
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 880-887
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 888-895
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 896-903
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 896-903
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 904-911
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 912-919
  0xFF, 0xFF, 0xFF,                               // 920-922
  }
*/

// VM 0BA7 Mapping for 0BA4 and 0BA5
const byte VM_MAP_923_983_0BA4[] PROGMEM =
{
  0x16, 0x17, 0x18,                               // 923-925  : input 1-24
  0x21, 0x20, 0x23, 0x22, 0x25, 0x24, 0x27, 0x26, // 926-933  : analoge input 1-4
  0x29, 0x28, 0x2B, 0x2A, 0x2D, 0x2C, 0x2F, 0x2E, // 934-941  : analoge input 5-8
  0x19, 0x1A,                                     // 942-943  : output 1-16
  0x31, 0x30, 0x33, 0x32,                         // 944-947  : analoge output 1-2
  0x1B, 0x1C, 0x1D, 0xFF,                         // 948-951  : flag 1-27
  0x35, 0x34, 0x37, 0x36, 0x39, 0x38, 0x3B, 0x3A, // 952-959  : analoge flag 1-4
  0x3D, 0x3C, 0x3F, 0x3E, 0xFF, 0xFF, 0xFF, 0xFF, // 960-967  : analoge flag 5-8
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 968-975  : analoge flag 9-12
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 976-983  : analoge flag 13-16
};

// VM 0BA7 Mapping for 0BA6
const byte VM_MAP_923_983_0BA6[] PROGMEM =
{
  0x1E, 0x1F, 0x20,                               // 923-925  : input 1-24
  0x2B, 0x2A, 0x2D, 0x2C, 0x2F, 0x2E, 0x31, 0x30, // 926-933  : analoge input 1-4
  0x33, 0x32, 0x35, 0x34, 0x37, 0x36, 0x39, 0x38, // 934-941  : analoge input 5-8
  0x22, 0x23,                                     // 942-943  : output 1-16
  0x3B, 0x3A, 0x3D, 0x3C,                         // 944-947  : analoge output 1-2
  0x24, 0x25, 0x26, 0x27,                         // 948-951  : flag 1-27
  0x3F, 0x3E, 0x41, 0x40, 0x43, 0x42, 0x45, 0x44, // 952-959  : analoge flag 1-4
  0x47, 0x46, 0x49, 0x48, 0xFF, 0xFF, 0xFF, 0xFF, // 960-967  : analoge flag 5-8
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 968-975  : analoge flag 9-12
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 976-983  : analoge flag 13-16
};

/*
  #ifdef _EXTENDED
  // VM Mapping for diagnostic, date and time
  const byte VM_MAP_984_1002[] PROGMEM =
  {
  0xFF,                                           // 984      : Diagnostic bit array
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,             // 985-990  : RTC (YY-MM-DD-hh:mm:ss)
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 991-998  : S7 date time (YYYY-MM-DD-hh:mm:ss)
  0xFF, 0xFF, 0xFF, 0xFF,                         // 999-1002 : S7 date time (nanoseconds)
  }

  // VM Mapping byte 1003 to 1023
  const byte VM_MAP_1003_1023[] PROGMEM =
  {
  0xFF, 0xFF, 0xFF, 0xFF,                         // 1003-1007
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 1008-1015
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF  // 1016-1023
  }
  #endif // _EXTENDED
*/

TPDU PDU;

#ifdef _LOGOHELPER

LogoHelper LH;

//***********************************************************************

bool LogoHelper::BitAt(void *Buffer, int ByteIndex, byte BitIndex)
{
  byte mask[] = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80};
  pbyte Pointer = pbyte(Buffer) + ByteIndex;

  if (BitIndex > 7)
    return false;
  else
    return (*Pointer & mask[BitIndex]);
}

bool LogoHelper::BitAt(int ByteIndex, int BitIndex)
{
  if (ByteIndex < VM_FIRST || ByteIndex > VM_LAST - 1)
    return false;

  // https://www.arduino.cc/reference/en/language/variables/utilities/progmem/
  ByteIndex = pgm_read_byte(LogoClient::Mapping + ByteIndex - VM_FIRST);

  if (ByteIndex > MaxPduSize - Size_RD - 1)
    return false;
  else
    return BitAt(PDU.DATA, ByteIndex, BitIndex);
}

byte LogoHelper::ByteAt(void *Buffer, int index)
{
  pbyte Pointer = pbyte(Buffer) + index;
  return *Pointer;
}

byte LogoHelper::ByteAt(int index)
{
  if (index < VM_FIRST || index > VM_LAST - 1)
    return 0;

  index = pgm_read_byte(LogoClient::Mapping + index - VM_FIRST);

  if (index > MaxPduSize - Size_RD - 1)
    return 0;
  else
    return ByteAt(PDU.DATA, index);
}

word LogoHelper::WordAt(void *Buffer, int index)
{
  word hi = (*(pbyte(Buffer) + index)) << 8;
  return hi + *(pbyte(Buffer) + index + 1);
}

word LogoHelper::WordAt(int index)
{
  if (index < VM_FIRST || index > VM_LAST - 2)
    return 0;

  byte hi = pgm_read_byte(LogoClient::Mapping + index - VM_FIRST);
  byte lo = pgm_read_byte(LogoClient::Mapping + index + 1 - VM_FIRST);

  if (hi > MaxPduSize - Size_RD - 1)
    return 0;
  else
    return (PDU.DATA[hi] << 8) + PDU.DATA[lo];
}

int LogoHelper::IntegerAt(void *Buffer, int index)
{
  word w = WordAt(Buffer, index);
  return *(pint(&w));
}

int LogoHelper::IntegerAt(int index)
{
  if (index < VM_FIRST || index > VM_LAST - 2)
    return 0;

  byte hi = pgm_read_byte(LogoClient::Mapping + index - VM_FIRST);
  byte lo = pgm_read_byte(LogoClient::Mapping + index + 1 - VM_FIRST);

  if (hi > MaxPduSize - Size_RD - 1)
    return 0;
  else
    return (PDU.DATA[hi] << 8) + PDU.DATA[lo];
}

#endif // _LOGOHELPER

//***********************************************************************

byte* LogoClient::Mapping = NULL;

LogoClient::LogoClient()
{
  ConnType      = PG;
  Connected     = false;
  LastError     = 0;
  PDULength     = 0;
  PDURequested  = 0;
  AddrLength    = 0;
  AccessMode    = PWD_LEVEL_ZERO;
  Mapping       = (byte*)VM_MAP_923_983_0BA6;
  RecvTimeout   = TIMEOUT;
  StreamClient  = NULL;
}

LogoClient::LogoClient(Stream *Interface)
{
  ConnType      = PG;
  Connected     = false;
  LastError     = 0;
  PDULength     = 0;
  PDURequested  = 0;
  AddrLength    = 0;
  AccessMode    = PWD_LEVEL_ZERO;
  Mapping       = (byte*)VM_MAP_923_983_0BA6;
  RecvTimeout   = TIMEOUT;
  StreamClient  = Interface;
}

LogoClient::~LogoClient()
{
  Disconnect();
}

// -- Basic functions ---------------------------------------------------
void LogoClient::SetConnectionParams(Stream *Interface)
{
  StreamClient = Interface;
}

void LogoClient::SetConnectionType(word ConnectionType)
{
  // The LOGO 0BA4 to 0BA6 supports only the PG protocol
  // The PG protocol is used by the software 'LOGO! Soft Comfort' (the developing tool)
  // to perform system tasks such as program upload/download, run/stop and configuration.
  // Other protocols (for exapmle the TD protocol) are not implemented yet.
  if (ConnectionType != PG)
    SetLastError(errCliFunction);
  ConnType = ConnectionType;
}

int LogoClient::ConnectTo(Stream *Interface)
{
  SetConnectionParams(Interface);
  return Connect();
}

int LogoClient::Connect()
{
  Log.trace(F("try to connect to %X" CR), StreamClient);
  LastError = 0;
  if (!Connected)
  {
    StreamConnect();
    if (LastError == 0)                 // First stage : Stream Connection
    {
      LogoConnect();
      if (LastError == 0)               // Second stage : PG Connection
      {
        // Third stage : PDU negotiation
        LastError = NegotiatePduLength();
      }
    }
  }
  Connected = LastError == 0;
  return LastError;
}

void LogoClient::Disconnect()
{
  Log.trace(F("disconnecting.." CR));
  if (Connected)
  {
    Connected     = false;
    LastError     = 0;
    PDULength     = 0;
    PDURequested  = 0;
  }
}

int LogoClient::ReadArea(int Area, word DBNumber, word Start, word Amount, void *ptrData)
{
  int Address;
  size_t NumElements;
  size_t MaxElements;
  size_t TotElements;
  size_t SizeRequested;
  size_t Length;

  pbyte Target = pbyte(ptrData);
  size_t Offset = 0;
  const int WordSize = 1;               // DB1 element has a size of one byte
  static unsigned long LastCycle;       // variable for storing the time from the last call
  // declared statically, so that it can used locally

  // For LOGO 0BA4 to 0BA6 the only compatible information that we can read are inputs, outputs, flags and rtc.
  // We will represented this as V memory, that is seen by all HMI as DB 1.
  if (Area != LogoAreaDB || DBNumber != 1)
    SetLastError(errPGInvalidPDU);

  // Access only allowed between 0 and 1023
  if ((int)Start < VM_START || Start > VM_END)
    SetLastError(errPGInvalidPDU);

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  // fetch data or cyclic data read?
  // The next line will also notice a rollover after about 50 days.
  // https://playground.arduino.cc/Code/TimingRollover
  if (millis() - LastCycle > CYCLETIME)
  {
    // fetch data or start a continuously polling!
#if defined _EXTENDED
    int Status;
    if (GetPlcStatus(&Status) != 0)
      return LastError;

    // operation mode must be RUN if we use LOGO_FETCH_DATA
    // so exit with an Error if the LOGO is not in operation mode RUN
    if (Status != LogoCpuStatusRun)
      return SetLastError(errCliFunction);
#endif // _EXTENDED

    if (StreamClient->write(LOGO_FETCH_DATA, sizeof(LOGO_FETCH_DATA)) != sizeof(LOGO_FETCH_DATA))
      return SetLastError(errStreamDataSend);

    RecvControlResponse(&Length);
    if (LastError)
      return LastError;
  }
  else
  {
    // cyclic reading of data!
    Log.verbose(F("cyclic reading" CR));
    // If code 06 is sent to the LOGO device within 600 ms,
    // the LOGO device sends updated data (cyclic data read).
    if (StreamClient->write(LOGO_ACK, sizeof(LOGO_ACK)) != sizeof(LOGO_ACK))
      return SetLastError(errStreamDataSend);

    PDU.H[0] = 0;
    RecvPacket(&PDU.H[1], GetPDULength() - 1);
    if (LastError)
      return LastError;
    Length = GetPDULength() - 1;

    // Get End Delimiter (1 byte)
    if (RecvPacket(PDU.T, 1) != 0)
      return LastError;
    Length++;

    if (PDU.H[1] != 0x55 || PDU.T[0] != AA)
      // Error, the response does not have the expected frame 0x55 .. 0xAA
      return SetLastError(errCliInvalidPDU);

    PDU.H[0] = ACK;
  }

  if (LastPDUType != ACK)               // Check Confirmation
    return SetLastError(errCliFunction);

  if (Length != (size_t)GetPDULength())
    return SetLastError(errCliInvalidPDU);

  // To recognize a cycle time we save the number of milliseconds
  // since the last successful call of the current function
  LastCycle = millis();

  // Done, as long as we only use the internal buffer
  if (ptrData == NULL)
    return SetLastError(0);

  TotElements = Amount;

  // Set buffer to 0
  SizeRequested = TotElements * WordSize;
  memset(Target + Offset, 0, SizeRequested);

  // Skip if Start points to user defined VM memory
  if ((int)Start >= VM_USER_AREA && Start < VM_NDEF_AREA1)
  {
    MaxElements = VM_NDEF_AREA1 - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    Address = Start - VM_USER_AREA;
    SizeRequested = NumElements * WordSize;
    // no copy

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Map 851 to 922 VM memory
  if (Start >= VM_NDEF_AREA1 && Start < VM_0BA7_AREA)
  {
    MaxElements = VM_0BA7_AREA - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    Address = Start - VM_NDEF_AREA1;
    SizeRequested = NumElements * WordSize;
    // tbd, no copy yet

    TotElements -= NumElements;
    Start += NumElements;
  }

  // Copy PDU data to VM 0BA7 memory
  if (Start >= VM_0BA7_AREA && Start < VM_DDT_AREA)
  {
    MaxElements = VM_DDT_AREA - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    Address = Start - VM_0BA7_AREA;
    SizeRequested = NumElements * WordSize;
    while (SizeRequested-- > 0)
    {
      // byte val = PDU.DATA[Mapping[Address++]]
      byte val = PDU.DATA[pgm_read_byte(Mapping + Address++)];
      if (val != 0xFF)
        Target[Offset++] = val;
    }

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Copy telemetry data to 'diagnostic, date and time' VM memory
  if (Start >= VM_DDT_AREA && Start < VM_NDEF_AREA2)
  {
    MaxElements = VM_NDEF_AREA2 - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    Address = Start - VM_DDT_AREA;
    SizeRequested = NumElements * WordSize;
    // tbd, no copy yet

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Map 1003 to 1023 VM memory
  if (Start >= VM_NDEF_AREA2 && Start < VM_END)
  {
    MaxElements = VM_END - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    Address = Start - VM_NDEF_AREA2;
    SizeRequested = NumElements * WordSize;
    // tbd, no copy yet

    /* last one, we don't need it
      TotElements -= NumElements;
      Start += NumElements;

      Offset += SizeRequested;
    */
  }

  return SetLastError(0);
}


// -- Extended functions ------------------------------------------------
#ifdef _EXTENDED
int LogoClient::PlcStart()
{
  int Status;

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  if (GetPlcStatus(&Status) != 0)
    return LastError;

  if (Status == LogoCpuStatusStop)
  {
    if (StreamClient->write(LOGO_START, sizeof(LOGO_START)) != sizeof(LOGO_START))
      return SetLastError(errStreamDataSend);

    // Setup the telegram
    memset(&PDU, 0, sizeof(PDU));

    size_t Length;
    RecvControlResponse(&Length);       // Get PDU response
    if (LastError)
      return LastError;

    if (LastPDUType != ACK)             // Check Confirmation
      return SetLastError(errCliFunction);

    if (Length != 1)                    // 1 is the expected value
      return SetLastError(errCliInvalidPDU);
  }

  return SetLastError(0);
}

int LogoClient::PlcStop()
{
  int Status;

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  if (GetPlcStatus(&Status) != 0)
    return LastError;

  if (Status != LogoCpuStatusStop)
  {
    if (StreamClient->write(LOGO_STOP, sizeof(LOGO_STOP)) != sizeof(LOGO_STOP))
      return SetLastError(errStreamDataSend);

    // Setup the telegram
    memset(&PDU, 0, sizeof(PDU));

    size_t Length;
    RecvControlResponse(&Length);       // Get PDU response
    if (LastError)
      return LastError;

    if (LastPDUType != ACK)             // Check Confirmation
      return SetLastError(errCliFunction);

    if (Length != 1)                    // 1 is the expected value
      return SetLastError(errCliInvalidPDU);
  }

  return SetLastError(0);
}

int LogoClient::GetPlcStatus(int *Status)
{
  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  *Status = LogoCpuStatusUnknown;

  if (StreamClient->write(LOGO_MODE, sizeof(LOGO_MODE)) != sizeof(LOGO_MODE))
    return SetLastError(errStreamDataSend);

  memset(&PDU, 0, sizeof(PDU));         // Setup the telegram

  size_t Length;
  RecvControlResponse(&Length);         // Get PDU response
  if (LastError)
    return LastError;

  if (LastPDUType != ACK)               // Check Confirmation
    return SetLastError(errCliFunction);

  if (Length != sizeof(PDU.H) + 1)      // Size of Header + 1 Data Byte is the expected value
    return SetLastError(errCliInvalidPDU);

  switch (PDU.DATA[0]) {
    case RUN:
      *Status = LogoCpuStatusRun;
      break;
    case STOP:
      *Status = LogoCpuStatusStop;
      break;
    default:
      *Status = LogoCpuStatusUnknown;
  }

  return SetLastError(0);
}

int LogoClient::GetPlcDateTime(TimeElements *DateTime)
{
  Log.trace(F("System clock read requested" CR));
  int Status;                           // Operation mode

  if (DateTime == NULL)                 // Exit with Error if DateTime is undefined
    return SetLastError(errPGInvalidPDU);

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  // Check operation mode
  if (GetPlcStatus(&Status) != 0)
    return LastError;
  if (Status != LogoCpuStatusStop)
    return SetLastError(errCliFunction);

  // clock reading initialized
  if (WriteByte(ADDR_CLK_W_GET, 0x00) != 0)
    return LastError;

  // clock reading day
  if (ReadByte(ADDR_CLK_RW_DAY, &DateTime->Day) != 0)
    return LastError;

  // clock reading month
  if (ReadByte(ADDR_CLK_RW_MONTH, &DateTime->Month) != 0)
    return LastError;

  // clock reading year
  if (ReadByte(ADDR_CLK_RW_YEAR, &DateTime->Year) != 0)
    return LastError;
  DateTime->Year = y2kYearToTm(DateTime->Year);

  // clock reading hour
  if (ReadByte(ADDR_CLK_RW_HOUR, &DateTime->Hour) != 0)
    return LastError;

  // clock reading minute
  if (ReadByte(ADDR_CLK_RW_MINUTE, &DateTime->Minute) != 0)
    return LastError;

  // clock reading day-of-week
  if (ReadByte(ADDR_CLK_RW_DOW, &DateTime->Wday) != 0)
    return LastError;
  DateTime->Wday += 1;                  // day of week, sunday is day 1

  memset(&PDU, 0, PDURequested);        // Clear the telegram
  DateTime->Second = 0;                 // set secounds to 0

  return SetLastError(0);
}

int LogoClient::GetPlcDateTime(time_t *DateTime)
{
  TimeElements tm;

  if (GetPlcDateTime(&tm) != 0)
    return LastError;

  *DateTime = makeTime(tm);             // convert to time_t
  return SetLastError(0);
}

int LogoClient::SetPlcDateTime(TimeElements DateTime)
{
  Log.trace(F("System clock write requested" CR));
  int Status;                           // Operation mode

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  // Check operation mode
  if (GetPlcStatus(&Status) != 0)
    return LastError;
  if (Status != LogoCpuStatusStop)
    return SetLastError(errCliFunction);

  // clock writing day
  if (WriteByte(ADDR_CLK_RW_DAY, DateTime.Day) != 0)
    return LastError;

  // clock writing month
  if (WriteByte(ADDR_CLK_RW_MONTH, DateTime.Month) != 0)
    return LastError;

  // clock writing year
  if (WriteByte(ADDR_CLK_RW_YEAR, tmYearToY2k(DateTime.Year)) != 0)
    return LastError;

  // clock writing hour
  if (WriteByte(ADDR_CLK_RW_HOUR, DateTime.Hour) != 0)
    return LastError;

  // clock writing minute
  if (WriteByte(ADDR_CLK_RW_MINUTE, DateTime.Minute) != 0)
    return LastError;

  // clock writing day-of-week (sunday is day 0)
  if (WriteByte(ADDR_CLK_RW_DOW, (DateTime.Wday - 1) % 7) != 0)
    return LastError;

  // clock writing completed
  if (WriteByte(ADDR_CLK_W_SET, 0x00) != 0)
    return LastError;

  memset(&PDU, 0, PDURequested);        // Clear the telegram

  return SetLastError(0);
}

int LogoClient::SetPlcDateTime(time_t DateTime)
{
  TimeElements tm;

  breakTime(DateTime, tm);              // break time_t into elements

  if (SetPlcDateTime(tm) != 0)
    return LastError;

  return SetLastError(0);
}

int LogoClient::SetPlcSystemDateTime()
{
  if (timeStatus() == timeNotSet)
    // the time has never been set, the clock started on Jan 1, 1970
    return SetLastError(errCliFunction);

  if (SetPlcDateTime(now()) != 0)
    return LastError;

  return SetLastError(0);
}

int LogoClient::GetOrderCode(TOrderCode *Info)
{
  int Status;                           // Operation mode

  if (Info == NULL)                     // Exit with Error if Info is undefined
    return SetLastError(errPGInvalidPDU);

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  // Set Info to predefined values
  strcpy_P(Info->Code, ORDER_CODE);
  Info->V1 = 0;
  Info->V2 = 0;
  Info->V3 = 0;

  switch (IdentNo) {
    case 0x40:
      // 0BA4
      Info->Code[Size_OC - 2] = '4';
      break;
    case 0x42:
      // 0BA5
      Info->Code[Size_OC - 2] = '5';
      break;
    case 0x43:
      // 0BA6
    case 0x44:
      // 0BA6.ES3
    case 0x45:
      // 0BA6.ES10
      Info->Code[Size_OC - 2] = '6';
      break;
    default:
      // 0BAx
      return SetLastError(errCliFunction);
  }

  // Check operation mode
  if (GetPlcStatus(&Status) != 0)
    return LastError;
  if (Status != LogoCpuStatusStop)
    return SetLastError(0);

  byte ch;
  // reading ASCII = V
  if (ReadByte(ADDR_OC_R_ASC_V, &ch) != 0)
    return LastError;
  if (ch != 'V') return SetLastError(0);

  // reading ASCII = X.__.__
  if (ReadByte(ADDR_OC_R_MAJOR, &ch) != 0)
    return LastError;
  if (ch > '0') Info->V1 = ch - '0';

  // reading ASCII = _.X_.__
  if (ReadByte(ADDR_OC_R_MINOR1, &ch) != 0)
    return LastError;
  if (ch > '0') Info->V2 = (ch - '0') * 10;

  // reading ASCII = _._X.__
  if (ReadByte(ADDR_OC_R_MINOR2, &ch) != 0)
    return LastError;
  if (ch > '0') Info->V2 += ch - '0';

  // reading ASCII = _.__.X_
  if (ReadByte(ADDR_OC_R_PATCH1, &ch) != 0)
    return LastError;
  if (ch > '0') Info->V3 = (ch - '0') * 10;

  // reading ASCII = _.__._X
  if (ReadByte(ADDR_OC_R_PATCH2, &ch) != 0)
    return LastError;
  if (ch > '0') Info->V3 += ch - '0';

  return SetLastError(0);
}

int LogoClient::SetSessionPassword(char *password)
{
  int Status;                           // Operation mode
  byte by;

  Log.trace(F("Security request : Set session password" CR));

  if (password == NULL)                 // Exit with Error if password is undefined
    return SetLastError(errPGInvalidPDU);

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  // By default, define zero mode
  AccessMode = PWD_LEVEL_ZERO;

  // Check operation mode
  if (GetPlcStatus(&Status) != 0)
    return LastError;

  if (Status == LogoCpuStatusStop)
  {
    // Set restricted mode
    AccessMode = PWD_LEVEL_RESTRICTED;

    // Start the sequence for reading out the password
    if (WriteByte(ADDR_PWD_W_ACCESS, 0) != 0)
      return LastError;

    if (ReadByte(ADDR_PWD_R_MAGIC1, &by) != 0)
      return LastError;
    if (by != 0x04) return SetLastError(errCliDataRead);

    if (ReadByte(ADDR_PWD_R_MAGIC2, &by) != 0)
      return LastError;
    if (by != 0x00) return SetLastError(errCliDataRead);

    // Check if a password exists
    if (ReadByte(ADDR_PWD_R_EXISTS, &by) != 0)
      return LastError;

    if (by == 0x40)                     // Password set
    {
      // Read 10 bytes from addr 0566
      if (ReadBlock(ADDR_PWD_R_MEM, 10, PDU.DATA) != 0)
        return LastError;

      // Compare the two password strings
      if (strncmp(password, (const char*)PDU.DATA, 10) != 0)
        return SetLastError(errCliFunction);

      // Login successful
      if (WriteByte(ADDR_PWD_W_OK, 0) != 0)
        return LastError;
    }

    AccessMode = PWD_LEVEL_FULL;
  }

  Log.trace(F("--> OK" CR));
  return SetLastError(0);
}

int LogoClient::ClearSessionPassword()
{
  int Status;                           // Operation mode
  byte pw;

  Log.trace(F("Security request : Clear session password" CR));

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  // By default, define zero mode
  AccessMode = PWD_LEVEL_ZERO;

  // Check operation mode
  if (GetPlcStatus(&Status) != 0)
    return LastError;

  if (Status == LogoCpuStatusStop)
  {
    // Set restricted mode
    AccessMode = PWD_LEVEL_RESTRICTED;

    // Check if a password exists
    if (ReadByte(ADDR_PWD_R_EXISTS, &pw) != 0)
      return LastError;

    if (pw != 0x40)                     // Password not set
      AccessMode = PWD_LEVEL_FULL;
  }

  Log.trace(F("--> OK" CR));
  return SetLastError(0);
}

int LogoClient::GetProtection(TProtection *Protection)
{
  int Status;                           // Operation mode

  if (Protection == NULL)               // Exit with Error if Protection is undefined
    return SetLastError(errPGInvalidPDU);

  if (!Connected)                       // Exit with Error if not connected
    return SetLastError(errPGConnect);

  // Set Protection to predefined values
  memset(Protection, 0, sizeof(TProtection));

  // Check operation mode
  if (GetPlcStatus(&Status) != 0)
    return LastError;

  if (Status == LogoCpuStatusStop)
  {
    byte pw;
    if (ReadByte(ADDR_PWD_R_EXISTS, &pw) == 0 && pw == 0x40)
    {
      Protection->sch_schal = 3;        // Protection level set with the mode selector = STOP and password set
      Protection->sch_par = 3;          // write/read protection
      Protection->sch_rel = 3;          // Set valid protection level
    }
    else
    {
      Protection->sch_schal = 1;        // Protection level set with the mode selector = STOP
      Protection->sch_par = 1;          // no protection
      Protection->sch_rel = 1;          // Set valid protection level
    }
    Protection->bart_sch = 3;           // Mode selector setting = STOP
    // anl_sch = 0;
  }
  else
  {
    Protection->sch_schal = 2;          // Protection level set with the mode selector = RUN
    // sch_par = 0;
    Protection->sch_rel = 2;            // Set valid protection level
    Protection->bart_sch = 1;           // Mode selector setting = RUN
    // anl_sch = 0;
  }

  return SetLastError(0);
}

void LogoClient::ErrorText(int Error, char *Text, int TextLen)
{
  if (Text == NULL || TextLen <= 0)
    return;

  memset(Text, 0, TextLen);
  switch (Error)
  {
    case 0 :
      strncpy_P(Text, PSTR("OK"), TextLen);
      return;
    case errStreamConnectionFailed :
      strncpy_P(Text, PSTR("Stream Connection failed."), TextLen);
      return;
    case errStreamConnectionReset :
      strncpy_P(Text, PSTR("Connection reset by the peer."), TextLen);
      return;
    case errStreamDataRecvTout :
      strncpy_P(Text, PSTR("Data Receiving timeout."), TextLen);
      return;
    case errStreamDataSend :
      strncpy_P(Text, PSTR("Stream Sending error."), TextLen);
      return;
    case errStreamDataRecv :
      strncpy_P(Text, PSTR("Stream Receiving error."), TextLen);
      return;
    case errPGConnect :
      strncpy_P(Text, PSTR("Connection refused by the PLC."), TextLen);
      return;
    case errPGInvalidPDU :
      strncpy_P(Text, PSTR("Invalid parameters supplied to the function."), TextLen);
      return;
    case errCliInvalidPDU :
      strncpy_P(Text, PSTR("Client received invalid PDU."), TextLen);
      return;
    case errCliSendingPDU :
      strncpy_P(Text, PSTR("Client sending invalid PDU."), TextLen);
      return;
    case errCliDataRead :
      strncpy_P(Text, PSTR("Error reading data from the PLC."), TextLen);
      return;
    case errCliDataWrite :
      strncpy_P(Text, PSTR("Error writing data to the PLC."), TextLen);
      return;
    case errCliFunction :
      strncpy_P(Text, PSTR("Client function refused by the PLC."), TextLen);
      return;
    case errCliBufferTooSmall :
      strncpy_P(Text, PSTR("The Buffer supplied to the function is too small."), TextLen);
      return;
    case errCliNegotiatingPDU :
      strncpy_P(Text, PSTR("Error negotiating the PDU length."), TextLen);
      return;
    default:
      if (TextLen > 20)
        sprintf_P(Text, PSTR("Unknown error : 0x%02x"), Error);
      return;
  };
}

#endif // _EXTENDED

// -- Private functions -------------------------------------------------
int LogoClient::RecvControlResponse(size_t *Size)
{
  *Size = 0;                            // Start with a size of 0

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));

  // Get first byte
  if (RecvPacket(PDU.H, 1) != 0)
    return LastError;
  (*Size)++;                            // Update size = 1

  LastPDUType = PDU.H[0];               // Store PDU Type
  if (LastPDUType == ACK)               // Connection confirmed
  {
    // Get next Byte
    RecvPacket(&PDU.H[1], 1);
    if (LastError & errStreamDataRecvTout)
      // OK, there are probably no more data available, for example Control Commands 0x12, 0x18
      return SetLastError(0);
    else if (LastError)
      // Other error than timeout
      return LastError;
    (*Size)++;                          // Update size = 2

    if (PDU.H[1] != 0x55)               // Control Command Code
    {
      // OK, the response has no Control Code 0x55, for example Control Commands 0x17
      *Size = Size_RD + 1;              // Update size = 7
      // We need to align with PDU.DATA
      PDU.DATA[0] = PDU.H[1];
      PDU.H[1] = 0;
      return SetLastError(0);
    }

    // Get Function Code (2 bytes)
    if (RecvPacket(&PDU.H[2], 2) != 0)
      return LastError;
    *Size += 2;                         // Update size = 4

    if (PDU.H[2] != 0x11 || PDU.H[3] != 0x11)
      // Error, the response does not have the expected Function Code 0x11
      return SetLastError(errCliDataRead);

    // Get Number of Bytes and the Padding Byte (2 bytes)
    if (RecvPacket(&PDU.H[4], 2) != 0)
      return LastError;
    *Size += 2;                         // Update Size = 6

    // Store Number of Bytes
    size_t ByteCount = PDU.H[4];

    if (*Size + ByteCount < MinPduSize)
      return SetLastError(errCliInvalidPDU);
    else if (*Size + ByteCount > MaxPduSize)
      return SetLastError(errCliBufferTooSmall);

    // Get the Data Block (n bytes)
    if (RecvPacket(PDU.DATA, ByteCount) != 0)
      return LastError;
    *Size += ByteCount;                 // Update Size = 6+ByteCount

    // Get End Delimiter (1 byte)
    if (RecvPacket(PDU.T, 1) != 0)
      return LastError;

    if (PDU.T[0] != AA)
      // Error, the response does not have the expected value 0xAA
      return SetLastError(errCliInvalidPDU);
  }
  else if (LastPDUType == NOK)          // Request not confirmed
  {
    // Get next byte
    if (RecvPacket(&PDU.H[1], 1) != 0)
      return LastError;
    (*Size)++;                          // Update Size = 2

    // Get Error Type
    return SetLastError(CpuError(PDU.H[1]));
  }
  else
    return SetLastError(errCliInvalidPDU);

  return SetLastError(0);
}

/*
#define SIZE_OF_BUFFER MaxPduSize
*/

int LogoClient::RecvPacket(byte buf[], size_t Size)
{
/*
  // http://github.com/charlesdobson/circular-buffer
  static int circularBuffer[SIZE_OF_BUFFER] = { 0 };  // Empty circular buffer
  static int readIndex     = 0;                  // Index of the read pointer
  static int writeIndex    = 0;                  // Index of the write pointer
  static int bufferLength  = 0;                  // Number of values in circular buffer
*/

  size_t Length = 0;

  /*
    // If you doesn't need to transfer more than 80 byte (the length of a PDU) you can uncomment the next two lines
    if (Size > MaxPduSize)
      return SetLastError(errCliBufferTooSmall);
  */

/*
  // Check if circular buffer contains data
  if (bufferLength > 0)
    Log.verbose(F("circular buffer contains data" CR));

  while (Length < Size && bufferLength > 0)
  {
    // Output from circular buffer
    buf[Length++] = circularBuffer[readIndex];

    bufferLength--;                   // Decrease used buffer size after reading
    readIndex++;                      // Increase readIndex position to prepare for next read

    // If at last index in circular buffer, set readIndex back to 0
    if (readIndex == SIZE_OF_BUFFER) {
      readIndex = 0;
    }
  }
*/

  // To recognize a timeout we save the number of milliseconds (since the Arduino began running the current program)
  unsigned long Elapsed = millis();

  // The Serial buffer can hold only 64 bytes, so we can't use readBytes()
  while (Length < Size)
  {
    if (StreamClient->available())
      buf[Length++] = StreamClient->read();
    else
      delayMicroseconds(500);

    // The next line will also notice a rollover after about 50 days.
    // https://playground.arduino.cc/Code/TimingRollover
    if (millis() - Elapsed > RecvTimeout) {
      Log.warning(F("Timeout > %d" CR), RecvTimeout);
      break; // Timeout
    }
  }

  // Here we are in timeout zone, if there's something into the buffer, it must be discarded.
  if (Length < Size)
  {
/*
    // Clearing circular buffer
    readIndex     = 0;
    writeIndex    = 0;
    bufferLength  = 0;
*/
    // Clearing serial incomming buffer
    // http://forum.arduino.cc/index.php?topic=396450.0
    while (StreamClient->available() > 0) {
      StreamClient->read();
    }

    if (Length > 0 && buf[Length - 1] == AA)
      // Timeout, but we have an End delimiter
      return SetLastError(errStreamConnectionReset);

    return SetLastError(errStreamDataRecvTout);
  }

/*
  // Input additional bytes to the circular buffer
  while (StreamClient->available()) {
    // Check if buffer is full
    if (bufferLength == SIZE_OF_BUFFER) {
      Log.error(F("RX buffer is full" CR));
      break;
    }
    // Write byte to address of circular buffer index
    circularBuffer[writeIndex] = StreamClient->read();
    bufferLength++;                     // Increase used buffer size after writing
    writeIndex++;                       // Increase writeIndex position to prepare for next write

    // If at last index in circular buffer, set writeIndex back to 0
    if (writeIndex == SIZE_OF_BUFFER) {
      writeIndex = 0;
    }
  }
*/

  return SetLastError(0);
}

int LogoClient::StreamConnect()
{
  if (StreamClient == NULL)             // Is a stream already assigned?
    return SetLastError(errStreamConnectionFailed);

  // Clearing serial incomming buffer
  // http://forum.arduino.cc/index.php?topic=396450.0
  while (StreamClient->available() > 0)
    StreamClient->read();

  return SetLastError(0);
}

int LogoClient::LogoConnect()
{
  if (StreamClient == NULL)             // Exit with Error if stream is not assigned
    return SetLastError(errStreamConnectionFailed);

  if (StreamClient->write(LOGO6_CR, sizeof(LOGO6_CR)) != sizeof(LOGO6_CR))
    return SetLastError(errStreamDataSend);

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));
  PDURequested = 4;

  // Get 4 bytes
  RecvPacket(PDU.H, PDURequested);
  // 0BA4 and 0BA5 doesn't support a connection request
  if (LastError & errStreamDataRecvTout)
  {
    if (StreamClient->write(LOGO4_CR, sizeof(LOGO4_CR)) != sizeof(LOGO4_CR))
      return SetLastError(errStreamDataSend);

    // Get 5 bytes
    PDURequested = 5;
    if (RecvPacket(PDU.H, PDURequested) != 0)
      return SetLastError(errPGConnect);
  }
  else if (LastError)
    return SetLastError(errPGConnect);

  LastPDUType = PDU.H[0];               // Store PDU Type
  if (LastPDUType != ACK)               // Check Confirmation
    return SetLastError(errPGConnect);

  // Note PDU is not aligned
  return SetLastError(0);
}

int LogoClient::NegotiatePduLength()
{
  PDULength = 0;

  if (StreamClient->write(LOGO6_CR, sizeof(LOGO6_CR)) != sizeof(LOGO6_CR))
    return SetLastError(errStreamDataSend);

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));
  PDURequested = 4;

  // Get 4 bytes
  RecvPacket(PDU.H, PDURequested);
  if (LastError & errStreamDataRecvTout)
  {
    // 0BA4 and 0BA5 doesn't support a connection request
    if (StreamClient->write(LOGO4_CR, sizeof(LOGO4_CR)) != sizeof(LOGO4_CR))
      return SetLastError(errStreamDataSend);

    // Get 5 bytes
    PDURequested = 5;
    if (RecvPacket(PDU.H, PDURequested) != 0)
      return SetLastError(errCliNegotiatingPDU);
  }
  else if (LastError)
    return LastError;

  LastPDUType = PDU.H[0];               // Store PDU Type
  if (LastPDUType != ACK)               // Check Confirmation
    return SetLastError(errCliNegotiatingPDU);

  IdentNo = PDU.H[PDURequested - 1];
  switch (IdentNo) {
    case 0x40:
      // 0BA4
    case 0x42:
      // 0BA5
      PDULength = PduSize0BA4;
      AddrLength = AddrSize0BA4;
      Mapping = (byte*)VM_MAP_923_983_0BA4;
      break;
    case 0x43:
      // 0BA6
    case 0x44:
      // 0BA6.ES3
    case 0x45:
      // 0BA6.ES10
      PDULength = PduSize0BA6;
      AddrLength = AddrSize0BA6;
      Mapping = (byte*)VM_MAP_923_983_0BA6;
      break;
    default:
      // 0BAx
      return SetLastError(errCliNegotiatingPDU);
  }

  Log.trace(F("PDU negotiated length: %d bytes" CR), PDULength);
  return SetLastError(0);
}

int LogoClient::SetLastError(int Error)
{
  LastError = Error;
  return Error;
}

int LogoClient::ReadByte(dword Addr, byte *Data)
{
  size_t Length = 0;

  if (Data == NULL)
    return SetLastError(errCliInvalidPDU);
  *Data = 0;

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));

  PDU.H[Length++] = 0x02;               // Read Byte Command Code
  if (AddrLength == 4)
  {
    PDU.H[Length++] = highByte(word(Addr >> 16));
    PDU.H[Length++] = lowByte(word(Addr >> 16));
  }
  PDU.H[Length++] = highByte(word(Addr));
  PDU.H[Length++] = lowByte(word(Addr));

  if (StreamClient->write(PDU.H, Length) != Length)
    return SetLastError(errStreamDataSend);

  // Setup the telegram
  memset(&PDU, 0, Length);
  PDURequested = 2 + AddrLength + 1;

  // Get first byte
  if (RecvPacket(PDU.H, 1) != 0)
    return LastError;

  LastPDUType = PDU.H[0];               // Store PDU Type
  if (LastPDUType == ACK)               // Connection confirmed
  {
    // Get next bytes
    if (RecvPacket(&PDU.H[1], PDURequested - 1) != 0)
      return LastError;

    if (PDU.H[1] != 0x03)
      // Error, the response does not have the expected Code 0x03
      return SetLastError(errCliDataRead);

    // We should align PDU
    if ((size_t)PDURequested < sizeof(PDU.H))
    {
      PDU.DATA[0] = PDU.H[PDURequested - 1];
      PDU.H[PDURequested - 1] = 0;
      PDURequested = Size_RD + 1;
    }
  }
  else if (LastPDUType == NOK)          // Request not confirmed
  {
    // Get second byte
    if (RecvPacket(&PDU.H[1], 1) != 0)
      return LastError;

    // Get Error Type
    return SetLastError(CpuError(PDU.H[1]));
  }
  else
    return SetLastError(errCliDataRead);

  *Data = PDU.DATA[0];
  return SetLastError(0);
}

int LogoClient::WriteByte(dword Addr, byte Data)
{
  size_t Length = 0;

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));

  PDU.H[Length++] = 0x01;               // Write Byte Command Code
  if (AddrLength == 4)
  {
    PDU.H[Length++] = highByte(word(Addr >> 16));
    PDU.H[Length++] = lowByte(word(Addr >> 16));
  }
  PDU.H[Length++] = highByte(word(Addr));
  PDU.H[Length++] = lowByte(word(Addr));

  PDU.H[Length++] = Data;

  if (StreamClient->write(PDU.H, Length) != Length)
    return SetLastError(errStreamDataSend);

  // Setup the telegram
  memset(&PDU, 0, Length);
  PDURequested = 1;

  // Get first byte
  if (RecvPacket(PDU.H, 1) != 0)
    return LastError;

  LastPDUType = PDU.H[0];               // Store PDU Type
  if (LastPDUType != ACK)               // Check Confirmation
  {
    if (LastPDUType == NOK)             // Get Exception Code
    {
      // Get second byte
      if (RecvPacket(&PDU.H[1], 1) != 0)
        return LastError;
    }
    return SetLastError(errCliDataWrite);
  }

  return SetLastError(0);
}

int LogoClient::ReadBlock(dword Addr, word ByteCount, byte *Data)
{
  size_t Length = 0;
  byte Checksum = 0;

  if (Data == NULL)
    return SetLastError(errCliInvalidPDU);
  memset(Data, 0, ByteCount);

  // Send the Query message
  memset(&PDU, 0, sizeof(PDU));
  // Read Block Command Code
  PDU.H[Length++] = 0x05;
  // Address Field
  if (AddrLength == 4)
  {
    PDU.H[Length++] = highByte(word(Addr >> 16));
    PDU.H[Length++] = lowByte(word(Addr >> 16));
  }
  PDU.H[Length++] = highByte(word(Addr));
  PDU.H[Length++] = lowByte(word(Addr));
  // Number of bytes
  PDU.H[Length++] = highByte(ByteCount);
  PDU.H[Length++] = lowByte(ByteCount);
  // Send Query
  if (StreamClient->write(PDU.H, Length) != Length)
    return SetLastError(errStreamDataSend);

  // Receive the Response message
  memset(&PDU, 0, Length);
  // Get first byte
  if (RecvPacket(PDU.H, 1) != 0)
    return LastError;
  LastPDUType = PDU.H[0];               // Store PDU Type

  if (LastPDUType == ACK)               // Connection confirmed
  {
    // Get Data Block
    Length = 0;                         // Init statement
    while (Length < ByteCount)
    {
      PDURequested = ByteCount - Length;
      if (PDURequested > MaxPduSize)
        PDURequested = MaxPduSize;
      if (RecvPacket(Data + Length, PDURequested) != 0)
        return LastError;
      Length += PDURequested;           // Iteration expression
    }

    // Get Checksum
    if (RecvPacket(PDU.T, 1) != 0)
      return LastError;

    // Calculate Checksum (only the data field are used for this)
    for (unsigned int i = 0; i < ByteCount; i++)
      Checksum = (*(Data + i) ^ Checksum) % 256;

    if (PDU.T[0] != Checksum)
      // Error, the response does not have the correct Checksum
      return SetLastError(errCliDataRead);
  }
  else if (LastPDUType == NOK)          // Request not confirmed
  {
    // Get second byte
    if (RecvPacket(&PDU.H[1], 1) != 0)
      return LastError;

    // Get Error Type
    return SetLastError(CpuError(PDU.H[1]));
  }
  else
    return SetLastError(errCliDataRead);

  return SetLastError(0);
}

int LogoClient::CpuError(int Error)
{
  switch (Error)
  {
    case 0:
      return 0;
    case cpuCodeDeviceBusy:
      // LOGO can not accept a telegram
      return errCliSendingPDU;
    case cpuCodeDeviceTimeOut:
      // Resource unavailable, the second cycle of the operation timed out
      return errCliSendingPDU;
    case cpuCodeInvalidAccess:
      // Illegal access, read across the border
      return errCliDataRead;
    case cpuCodeParityError:
      // parity error-, overflow or telegram error
      return errCliSendingPDU;
    case cpuCodeUnknownCommand:
      // Unknown command, this mode is not supported
      return errCliFunction;
    case cpuCodeXorIncorrect:
      // XOR-check incorrect
      return errCliDataWrite;
    case cpuCodeSimulationError:
      // Faulty on simulation, RUN is not supported in this mode
      return errCliFunction;
    default:
      return errCliInvalidPDU;
  };
};
