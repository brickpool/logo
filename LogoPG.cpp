/*
 * LogoPG library, Version 0.4.1
 * 
 * Portion copyright (c) 2018 by Jan Schneider
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
 * Changelog: 
 *  see the associated *.h
*/

#include "Arduino.h"
#include "LogoPG.h"
#include <avr/pgmspace.h>

// For further informations about the structures, command codes, byte arrays and their meanings
// see http://github.com/brickpool/logo

// LOGO Connection Request
const byte LOGO_CR[] = {
  0x21
};

// LOGO Read Revision Request
const byte LOGO_REVISION[] = {
  0x02, 0x1F, 0x02
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

#endif // _EXTENDED

// If an error has occurred, the LOGO send a negative confirmation 0x14 (NOK)
// and then an error byte with the following codes
#define PDU_BUSY    0x01  // LOGO can not accept a telegram
#define PDU_TIMEOUT 0x02  // Resource unavailable
#define PDU_INVALID 0x03  // Illegal access
#define PDU_PAR_ERR 0x04  // parity error-, overflow or telegram error
#define PDU_UNKNOWN 0x05  // Unknown command
#define PDU_XOR_ERR 0x06  // XOR-check incorrect
#define PDU_SIM_ERR 0x07  // Faulty on simulation 

#define TIMEOUT     500   // set timeout between 75 and 600 ms

#define VM_START      0     // first valid address
#define VM_USER_AREA  0     // user defined area
#define VM_NDEF_AREA1 851   // not defined area #1
#define VM_0BA7_AREA  923   // area for 0BA7
#define VM_DDT_AREA   984   // diagnostic, date and time area
#define VM_NDEF_AREA2 1003  // not defined area #2
#define VM_END        1023  // last valid address

// Store mapping in flash (program) memory instead of SRAM

/*
// VM Mapping byte 851 to 922
const PROGMEM byte VM_MAP_851_922[] =
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
const PROGMEM byte VM_MAP_923_983_0BA4[] =
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
const PROGMEM byte VM_MAP_923_983_0BA6[] =
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
const PROGMEM byte VM_MAP_984_1002[] =
{
  0xFF,                                           // 984      : Diagnostic bit array
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,             // 985-990  : RTC (YY-MM-DD-hh:mm:ss)
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 991-998  : S7 date time (YYYY-MM-DD-hh:mm:ss)
  0xFF, 0xFF, 0xFF, 0xFF,                         // 999-1002 : S7 date time (nanoseconds)
}

// VM Mapping byte 1003 to 1023
const PROGMEM byte VM_MAP_1003_1023[] =
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
  if (ByteIndex < VM_0BA7_AREA || ByteIndex >= VM_DDT_AREA)
    return false;

  // https://www.arduino.cc/reference/en/language/variables/utilities/progmem/
  ByteIndex = pgm_read_byte_near(LogoClient::Mapping + ByteIndex- VM_0BA7_AREA);

  if (ByteIndex > MaxPduSize-Size_WR-1)
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
  if (index < VM_0BA7_AREA || index >= VM_DDT_AREA)
    return 0;
  
  index = pgm_read_byte_near(LogoClient::Mapping + index - VM_0BA7_AREA);
  
  if (index > MaxPduSize-Size_WR-1)
    return 0;
  else
    return ByteAt(PDU.DATA, index);
}

word LogoHelper::WordAt(void *Buffer, int index)
{
  word hi = (*(pbyte(Buffer) + index)) << 8;
  return hi+*(pbyte(Buffer) + index+1);
}

word LogoHelper::WordAt(int index)
{
  if (index < VM_0BA7_AREA || index >= VM_DDT_AREA)
    return 0;
  
  index = pgm_read_byte_near(LogoClient::Mapping + index - VM_0BA7_AREA);
  
  if (index > MaxPduSize-Size_WR-1)
    return 0;
  else
    return WordAt(PDU.DATA, index);
}

int LogoHelper::IntegerAt(void *Buffer, int index)
{
  word w = WordAt(Buffer, index);
  return *(pint(&w));
}

int LogoHelper::IntegerAt(int index)
{
  if (index < VM_0BA7_AREA || index >= VM_DDT_AREA)
    return 0;
  
  index = pgm_read_byte_near(LogoClient::Mapping + index - VM_0BA7_AREA);
  
  if (index > MaxPduSize-Size_WR-1)
    return 0;
  else
    return IntegerAt(PDU.DATA, index);
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
  Mapping       = VM_MAP_923_983_0BA6;
  RecvTimeout   = TIMEOUT;
  StreamClient  = NULL;
}

LogoClient::LogoClient(pstream Interface)
{
  ConnType      = PG;
  Connected     = false;
  LastError     = 0;
  PDULength     = 0;
  Mapping       = VM_MAP_923_983_0BA6;
  RecvTimeout   = TIMEOUT;
  StreamClient  = Interface;
}

LogoClient::~LogoClient()
{
  Disconnect();
}

// -- Basic functions ---------------------------------------------------
void LogoClient::SetConnectionParams(pstream Interface)
{
  StreamClient = Interface;
}

void LogoClient::SetConnectionType(word ConnectionType)
{
  // The LOGO 0BA4 tp 0BA6 supports only the PG protocol
  // The PG protocol is used by the software LOGO Comfort (the developing tool)
  // to perform system tasks such as program upload/download, run/stop and configuration.
  // Other protocols are not implemented yet.
  if (ConnectionType != PG)
    SetLastError(errPGConnect | errCliFunction);
  ConnType = ConnectionType;
}

int LogoClient::ConnectTo(pstream Interface)
{
  SetConnectionParams(Interface);
  return Connect();
}

int LogoClient::Connect()
{
  LastError = 0;
  if (!Connected)
  {
    StreamConnect();
    if (LastError == 0) // First stage : Stream Connection
    {
      LogoConnect();
      if (LastError == 0) // Second stage : PG Connection
      {
        LastError = NegotiatePduLength(); // Third stage : PDU negotiation
      }
    }  
  }
  Connected = LastError == 0;
  return LastError;
}

void LogoClient::Disconnect()
{
  if (Connected)
  {
    Connected = false;
    PDULength = 0;
    LastError = 0;
  }  
}

int LogoClient::ReadArea(int Area, word DBNumber, word Start, word Amount, void *ptrData)
{
  int Address;
  size_t NumElements;
  size_t MaxElements;
  size_t TotElements;
  size_t SizeRequested;

  pbyte Target = pbyte(ptrData);
  size_t Offset = 0;
	const int WordSize = 1;  // DB1 element has a size of one byte

  // For LOGO 0BA4 to 0BA6 the only compatible information that we can read are inputs, outputs, flags and rtc.
  // We will represented this as V memory, that is seen by all HMI as DB 1.
  if (Area != LogoAreaDB && DBNumber != 1)
    SetLastError(errPGInvalidPDU | errCliInvalidPDU);

  // Access only allowed between 0 and 1023
  if (Start < VM_START && Start > VM_END)
    SetLastError(errPGInvalidPDU | errCliInvalidPDU);
    
#if defined _EXTENDED
  int Status;
  GetPlcStatus(&Status);
  if (LastError)
    return SetLastError(LastError);
  
  // Operation mode must be RUN if we use LOGO_FETCH_DATA
  if (Status != LogoCpuStatusRun) // Exit with Error if the LOGO is not in operation mode RUN
    return SetLastError(errPGInvalidPDU | errCliFunction);
#endif // _EXTENDED

  if (StreamClient->write(LOGO_FETCH_DATA, sizeof(LOGO_FETCH_DATA)) != sizeof(LOGO_FETCH_DATA))
    return SetLastError(errStreamDataSend);

  size_t Length;
  RecvControlResponse(&Length);
  if (LastError)
    return LastError;

  if (LastPDUType != ACK)         // Check Confirmation
    return SetLastError(errPGInvalidPDU | errCliFunction);

  if (Length != GetPDULength())
    return SetLastError(errPGInvalidPDU | errCliInvalidPDU);
  
  // Done, as long as we only use the internal buffer
  if (ptrData == NULL)
    return SetLastError(0);

  TotElements = Amount;

  // Set buffer to 0
  SizeRequested = TotElements * WordSize;
  memset(Target+Offset, 0, SizeRequested);

  // Skip if Start points to user defined VM memory
  if (Start >= VM_USER_AREA && Start < VM_NDEF_AREA1)
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
      byte val = PDU.DATA[Mapping[Address++]];
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


// -- Normal functions ------------------------------------------------
#ifdef _EXTENDED
int LogoClient::PlcStart()
{
  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnect | errCliInvalidPDU);

  int Status;
  GetPlcStatus(&Status);
  if (LastError)
    return LastError;

  if (Status == LogoCpuStatusStop)
  {
    if (StreamClient->write(LOGO_START, sizeof(LOGO_START)) != sizeof(LOGO_START))
      return SetLastError(errStreamDataSend);
  
    // Setup the telegram
    memset(&PDU, 0, sizeof(PDU));

    size_t Length;
    RecvControlResponse(&Length);   // Get PDU response
    if (LastError)
      return SetLastError(LastError | errCliDataRead);
  
    if (LastPDUType != ACK)         // Check Confirmation
      return SetLastError(errPGInvalidPDU | errCliFunction);
  
    if (Length != 1)                // 1 is the expected value
      return SetLastError(errPGInvalidPDU | errCliInvalidPDU);
  }

  return SetLastError(0);
}

int LogoClient::PlcStop()
{
  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnect | errCliInvalidPDU);

  int Status;
  GetPlcStatus(&Status);
  if (LastError)
    return LastError;

  if (Status != LogoCpuStatusStop)
  {
    if (StreamClient->write(LOGO_STOP, sizeof(LOGO_STOP)) != sizeof(LOGO_STOP))
      return SetLastError(errStreamDataSend);
  
    // Setup the telegram
    memset(&PDU, 0, sizeof(PDU));

    size_t Length;
    RecvControlResponse(&Length);   // Get PDU response
    if (LastError)
      return SetLastError(LastError | errCliDataRead);
  
    if (LastPDUType != ACK)         // Check Confirmation
      return SetLastError(errPGInvalidPDU | errCliFunction);
  
    if (Length != 1)                // 1 is the expected value
      return SetLastError(errPGInvalidPDU | errCliInvalidPDU);
  }

  return SetLastError(0);
}

int LogoClient::GetPlcStatus(int *Status)
{
  *Status = LogoCpuStatusUnknown;
  
  if (StreamClient->write(LOGO_MODE, sizeof(LOGO_MODE)) != sizeof(LOGO_MODE))
    return SetLastError(errStreamDataSend);

  memset(&PDU, 0, sizeof(PDU));   // Setup the telegram
  
  size_t Length;
  RecvControlResponse(&Length);   // Get PDU response
  if (LastError)
    return SetLastError(LastError | errCliDataRead);

  if (LastPDUType != ACK)         // Check Confirmation
    return SetLastError(errPGInvalidPDU | errCliFunction);

  if (Length != sizeof(PDU.H)+1)  // Size of Header + 1 Data Byte is the expected value
    return SetLastError(errPGInvalidPDU | errCliInvalidPDU);

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

#endif // _EXTENDED

// -- Private functions -------------------------------------------------
int LogoClient::RecvControlResponse(size_t *Size)
{
  *Size = 0;  // Start with a size of 0

  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnect);
  
  if (PDULength == 0) // Exit with Error if not negotiated
    return SetLastError(errCliNegotiatingPDU);
  
  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));  
  
  // Get first byte
  RecvPacket(PDU.H, 1); 
  if (LastError)
    return SetLastError(LastError | errCliDataRead);
  *Size = 1;                // Update Size

  LastPDUType = PDU.H[0];   // Store PDU Type

  if (LastPDUType == ACK)   // Connection confirmed
  {
    // Get next Byte
    RecvPacket(PDU.DATA, 1);
    if (LastError == errStreamDataRecvTout)
      // OK, there are probably no more data available, for example Control Commands 0x12, 0x18
      return SetLastError(0);
    else if (LastError)
      // Other error than timeout
      return SetLastError(LastError | errCliDataRead);
    *Size = Size_WR+1;      // Update Size

    if (PDU.DATA[0] != 0x55)
      // OK, the response has no Control Code 0x55, for example Control Commands 0x17
      return SetLastError(0);

    // Copy Control Code 0x55 to the Header and set Data Byte to zero
    PDU.H[1] = PDU.DATA[0];
    PDU.DATA[0] = 0;
    *Size = 2;              // Update Size

    // Get Function Code (2 bytes)
    RecvPacket(&PDU.H[2], 2);
    if (LastError)
      return SetLastError(LastError | errCliDataRead);
    *Size += 2;             // Update Size

    if (PDU.H[2] != 0x11 || PDU.H[3] != 0x11)
      // Error, the response does not have the expected Function Code 0x11
      return SetLastError(errPGInvalidPDU | errCliInvalidPDU);
    
    // Get Number of Bytes and the Padding Byte (2 bytes)
    RecvPacket(&PDU.H[4], 2);
    if (LastError)
      return SetLastError(LastError | errCliDataRead);
    *Size += 2;             // Update Size

    // Store Number of Bytes
    size_t ByteCount = PDU.H[4];

    if (*Size+ByteCount < MinPduSize)
      return SetLastError(errPGInvalidPDU);
    else if (*Size+ByteCount > MaxPduSize)
      return SetLastError(errPGInvalidPDU | errCliBufferTooSmall);

    // Get the Data Block (n bytes)
    RecvPacket(PDU.DATA, ByteCount);
    if (LastError)
      return SetLastError(LastError | errCliDataRead);
    *Size += ByteCount;     // Update Size
    
    // Get End Delimiter (1 byte)
    byte Trailer[1];
    RecvPacket(Trailer, 1);
    if (LastError)
      return SetLastError(LastError | errCliDataRead);
  }
  else if (LastPDUType == NOK)    // Request not confirmed
  {
    // Get next byte
    RecvPacket(PDU.H[1], 1);
    if (LastError)
      return SetLastError(LastError | errCliDataRead);
    *Size = 2;              // Update Size

    // Get Error Type
    switch (PDU.H[1]) {
      case PDU_BUSY:
        // LOGO can not accept a telegram
        return SetLastError(errPGInvalidPDU | errCliSendingPDU);
      case PDU_TIMEOUT:
        // Resource unavailable, the second cycle of the operation timed out
        return SetLastError(errPGInvalidPDU | errCliDataRead);
      case PDU_INVALID:
        // Illegal access, read across the border
        return SetLastError(errPGInvalidPDU | errCliDataRead);
      case PDU_PAR_ERR:
        // parity error-, overflow or telegram error
        return SetLastError(errPGInvalidPDU | errCliSendingPDU);
      case PDU_UNKNOWN: 
        // Unknown command, this mode is not supported
        return SetLastError(errPGInvalidPDU | errCliInvalidPDU);
      case PDU_XOR_ERR:
        // XOR-check incorrect
        return SetLastError(errPGInvalidPDU | errCliSendingPDU);
        break;
      case PDU_SIM_ERR:
        // Faulty on simulation, RUN is not supported in this mode
        return SetLastError(errPGInvalidPDU | errCliInvalidPDU);
      default:
        return SetLastError(errPGInvalidPDU | errCliDataRead);
    }

  }
  else
    return SetLastError(errPGInvalidPDU | errCliFunction);

  return SetLastError(0);
}

int LogoClient::RecvPacket(byte buf[], size_t Size)
{
/*
  // If you doesn't need to transfer more than 80 byte (the length of a PDU) you can uncomment the next two lines
  if (Size > MaxPduSize)
    return SetLastError(errStreamDataRecv | errCliBufferTooSmall);
*/

  // To recognize a timeout we save the number of milliseconds (since the Arduino began running the current program)
  unsigned long Elapsed = millis();

  // The Serial buffer can hold only 64 bytes, so we can't use readBytes()
  size_t i = 0;
  while (i < Size)
  {
    if (StreamClient->available())
      buf[i++] = StreamClient->read();
    else
      delayMicroseconds(500);
    
    // The next line are important for rollover after approximately 50 days.
    // Since the millis() is unsigned long, also the testing
    // and updating the time must be done with unsigned long.
    // https://playground.arduino.cc/Code/TimingRollover
    if (millis()-Elapsed > RecvTimeout)
      break; // Timeout
  }

  // Here we are in timeout zone, if there's something into the buffer, it must be discarded.
  if (i < Size)
  {
    // Clearing serial incomming buffer
    // http://forum.arduino.cc/index.php?topic=396450.0
    while (StreamClient->available() > 0)
      StreamClient->read();

    if ((i > 0) && (buf[i-1] == AA))
      // Timeout, but we have an End delimiter
      return SetLastError(errStreamConnectionReset);

    return SetLastError(errStreamDataRecvTout);
  }

  return SetLastError(0);
}

int LogoClient::StreamConnect()
{
  if (StreamClient == NULL) // Is a stream already assigned?
    return SetLastError(errStreamConnectionFailed);

  return SetLastError(0);
}

int LogoClient::LogoConnect()
{
  if (StreamClient == NULL) // Exit with Error if stream is not assigned
    return SetLastError(errStreamConnectionFailed);

  if (StreamClient->write(LOGO_CR, sizeof(LOGO_CR)) != sizeof(LOGO_CR))
    return SetLastError(errStreamDataSend);

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));
  
  // Get 4 bytes
  RecvPacket(PDU.H, 4);
  if (LastError == errStreamDataRecvTout)       // 0BA4 doesn't support a connection request
  {
    if (StreamClient->write(LOGO_REVISION, sizeof(LOGO_REVISION)) != sizeof(LOGO_REVISION))
      return SetLastError(errStreamDataSend);

    // Get 5 bytes
    RecvPacket(PDU.H, 5);
    if (LastError)
      return SetLastError(errPGConnect);
  }  
  else if (LastError)
    return SetLastError(errPGConnect);

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType != ACK)   // Check Confirmation
    return SetLastError(errPGConnect);

  // Note PDU is not aligned
  return SetLastError(0);
}

int LogoClient::NegotiatePduLength()
{
  size_t Length = 0;
  if (PDULength)  // Exit if length has already been determined
    return SetLastError(0);
  
  PDULength = 0;

  if (StreamClient->write(LOGO_CR, sizeof(LOGO_CR)) != sizeof(LOGO_CR))
    return SetLastError(errStreamDataSend);

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));
  
  // Get 4 bytes
  Length = 4;
  RecvPacket(PDU.H, Length);
  if (LastError == errStreamDataRecvTout)       // 0BA4 doesn't support a connection request
  {
    if (StreamClient->write(LOGO_REVISION, sizeof(LOGO_REVISION)) != sizeof(LOGO_REVISION))
      return SetLastError(errStreamDataSend);

    // Get 5 bytes
    Length = 5;
    RecvPacket(PDU.H, Length);
    if (LastError)
      return SetLastError(errCliNegotiatingPDU);
  }
  else if (LastError)
    return SetLastError(errCliNegotiatingPDU);

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType != ACK)   // Check Confirmation
    return SetLastError(errPGConnect);

  // We should align PDU
  PDU.DATA[0] = PDU.H[Length-1];
  PDU.H[Length-1] = 0;

  switch (PDU.DATA[0]) {
    case 0x40:
    case 0x42:
      // 0BA4
      // 0BA5
      PDULength = PduSize0BA4;
      Mapping = VM_MAP_923_983_0BA4;
      break;
    case 0x43:
    case 0x44:
      // 0BA6
      // 0BA6.ES3
      PDULength = PduSize0BA6;
      Mapping = VM_MAP_923_983_0BA6;
      break;
    default:
      // 0BAx
      return SetLastError(errCliNegotiatingPDU);
  } 

  return SetLastError(0);
}

int LogoClient::SetLastError(int Error)
{
  LastError = Error;
  return Error;
}
