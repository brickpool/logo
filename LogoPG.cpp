/*
 * LogoPG library, pre alpha version
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
 *  2018-02-07: Initial version created
 *  2018-02-15: alpha Version
 *  2018-02-20: Version 0.3
*/

#include "Arduino.h"
#include "LogoPG.h"
#include <avr/pgmspace.h>

// For further informations about structures (the byte arrays and they meanins)
// see http://github.com/brickpool/logo

// LOGO Connection Request
const byte LOGO_CR[] = {
  0x21
};

// LOGO Read Revision Request
const byte LOGO_REVISION[] = {
  0x02, 0x1F, 0x02
};

// LOGO Put PLC in STOP state Telegram
const byte LOGO_STOP[] = {
  0x55, 0x12, 0x12, 0xAA
};

// LOGO Put PLC in RUN state Telegram
const byte LOGO_START[] = {
  0x55, 0x18, 0x18, 0xAA
};

// LOGO Get PLC Request Telegram
const byte LOGO_GET[] = {
  0x55, 0x13, 0x13, 0x00, 0xAA
};

// LOGO Operation Mode Request Telegram
const byte LOGO_MODE[] = {
  0x55, 0x17, 0x17, 0xAA
};

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
  0x00, 0x01, 0x02,                               // 923-925  : input 1-24
  0x0B, 0x0A, 0x0D, 0x0C, 0x0F, 0x0E, 0x11, 0x10, // 926-933  : analoge input 1-4
  0x13, 0x12, 0x15, 0x14, 0x17, 0x16, 0x19, 0x18, // 934-941  : analoge input 5-8
  0x03, 0x04,                                     // 942-943  : output 1-16
  0x1B, 0x1A, 0x1D, 0x1C,                         // 944-947  : analoge output 1-2
  0x05, 0x06, 0x07, 0xFF,                         // 948-951  : merker 1-27
  0x1F, 0x1E, 0x21, 0x20, 0x23, 0x22, 0x25, 0x24, // 952-959  : analoge merker 1-4
  0x27, 0x26, 0x29, 0x28, 0xFF, 0xFF, 0xFF, 0xFF, // 960-967  : analoge merker 5-8
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 968-975  : analoge merker 9-12
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 976-983  : analoge merker 13-16
};
  
// VM 0BA7 Mapping for 0BA6
const PROGMEM byte VM_MAP_923_983_0BA6[] =
{
  0x00, 0x01, 0x02,                               // 923-925  : input 1-24
  0x0D, 0x0C, 0x0F, 0x0E, 0x11, 0x10, 0x13, 0x12, // 926-933  : analoge input 1-4
  0x15, 0x14, 0x17, 0x16, 0x19, 0x18, 0x1B, 0x1A, // 934-941  : analoge input 5-8
  0x04, 0x05,                                     // 942-943  : output 1-16
  0x1D, 0x1C, 0x1F, 0x1E,                         // 944-947  : analoge output 1-2
  0x06, 0x07, 0x08, 0x09,                         // 948-951  : merker 1-27
  0x21, 0x20, 0x23, 0x22, 0x25, 0x24, 0x27, 0x26, // 952-959  : analoge merker 1-4
  0x29, 0x28, 0x2B, 0x2A, 0xFF, 0xFF, 0xFF, 0xFF, // 960-967  : analoge merker 5-8
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 968-975  : analoge merker 9-12
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 976-983  : analoge merker 13-16
};

/*  
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
*/

TPDU PDU;

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
  return BitAt(PDU.DATA, ByteIndex, BitIndex);
}

byte LogoHelper::ByteAt(void *Buffer, int index)
{
  pbyte Pointer = pbyte(Buffer) + index;
  return *Pointer;
}

byte LogoHelper::ByteAt(int index)
{
  return ByteAt(PDU.DATA, index);
}

word LogoHelper::WordAt(void *Buffer, int index)
{
  word hi = (*(pbyte(Buffer) + index)) << 8;
  return hi+*(pbyte(Buffer) + index+1);
}

word LogoHelper::WordAt(int index)
{
  return WordAt(PDU.DATA, index);
}

int LogoHelper::IntegerAt(void *Buffer, int index)
{
  word w = WordAt(Buffer, index);
  return *(pint(&w));
}

int LogoHelper::IntegerAt(int index)
{
  return IntegerAt(PDU.DATA, index);
}


//***********************************************************************
LogoClient::LogoClient()
{
  ConnType      = PG;
  Connected     = false;
  LastError     = 0;
  PDULength     = 0;
  PDUHeaderLen  = Size_0BA6;
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
  PDUHeaderLen  = Size_0BA6;
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
    SetLastError(errPGConnectionFailed | errLogoFunction);
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
    SetLastError(errPGInvalidPDU | errLogoInvalidPDU);

  // Access only allowed between 0 and 1023
  if (Start < VM_START && Start > VM_END)
    SetLastError(errPGInvalidPDU | errLogoInvalidPDU);
    
  size_t Length;
  RecvIOPacket(&Length);
  if (LastError)
    return LastError;

  if (Length != GetPDULength())
    return SetLastError(errPGInvalidPDU | errLogoDataRead);
  
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


// -- Extended functions ------------------------------------------------
int LogoClient::PlcStart()
{
  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnectionFailed | errLogoInvalidPDU);

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

    // Get 1 Byte
    RecvPacket(PDU.H, 1); 
    if (LastError)
      return SetLastError(LastError | errLogoFunction);
  
    LastPDUType = PDU.H[0];   // Store PDU Type
    if (LastPDUType != ACK)   // Connection confirmed
      return SetLastError(errPGInvalidPDU | errLogoFunction);
  }

  return SetLastError(0);
}

int LogoClient::PlcStop()
{
  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnectionFailed | errLogoInvalidPDU);

  int Status;
  GetPlcStatus(&Status);
  if (LastError)
    return LastError;

  if (Status == LogoCpuStatusRun)
  {
    if (StreamClient->write(LOGO_STOP, sizeof(LOGO_STOP)) != sizeof(LOGO_STOP))
      return SetLastError(errStreamDataSend);
  
    // Setup the telegram
    memset(&PDU, 0, sizeof(PDU));

    // Get 1 Byte
    RecvPacket(PDU.H, 1);
    if (LastError)
      return SetLastError(LastError | errLogoFunction);
  
    LastPDUType = PDU.H[0];   // Store PDU Type
    if (LastPDUType != ACK)   // Connection confirmed
      return SetLastError(errPGInvalidPDU | errLogoFunction);
  }

  return SetLastError(0);
}

int LogoClient::GetPlcStatus(int *Status)
{
  *Status = LogoCpuStatusUnknown;
  
  if (StreamClient->write(LOGO_MODE, sizeof(LOGO_MODE)) != sizeof(LOGO_MODE))
    return SetLastError(errStreamDataSend);

  memset(&PDU, 0, sizeof(PDU));  // Setup the telegram
  
  RecvPacket(PDU.H, 2); // Get 2 Bytes
  if (LastError)
    return SetLastError(LastError | errLogoDataRead);

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType != ACK)   // Connection confirmed
    return SetLastError(errPGInvalidPDU | errLogoFunction);

  if (PDU.H[1] == RUN)
  {
    *Status = LogoCpuStatusRun;
  }
  else if (PDU.H[1] == STOP)
  {
    *Status = LogoCpuStatusStop;
  }
  else
  {
    return SetLastError(errPGInvalidPDU | errLogoFunction);
  }
	
  return SetLastError(0);
}

// -- Private functions -------------------------------------------------
int LogoClient::RecvIOPacket(size_t *Size)
{
  *Size = 0;  // Start with a size of 0

  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnectionFailed);
  
  if (PDULength == 0) // Exit with Error if not negotiated
    return SetLastError(errPGNegotiatingPDU);
  
  int Status;
  GetPlcStatus(&Status);
  if (LastError)
    return SetLastError(LastError);
  
  // Operation mode must be RUN if we use LOGO_GET
  if (Status != LogoCpuStatusRun) // Exit with Error if the LOGO is not in operation mode RUN
    return SetLastError(errPGInvalidPDU | errLogoFunction);

  if (StreamClient->write(LOGO_GET, sizeof(LOGO_GET)) != sizeof(LOGO_GET))
    return SetLastError(errStreamDataSend);

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));  
  
  // Get first byte
  RecvPacket(PDU.H, 1); 
  if (LastError)
    return SetLastError(LastError | errLogoDataRead);
  *Size = 1;                // Update Size

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType == ACK)   // Connection confirmed
  {
    // Get PDU Header
    RecvPacket(&PDU.H[1], GetPDUHeaderLen()-1);
    if (LastError)
      return SetLastError(LastError | errLogoDataRead);
    *Size = GetPDUHeaderLen();    // Update Size

    // Get PDU Data
    RecvPacket(PDU.DATA, GetPDULength() - GetPDUHeaderLen());
    if (LastError)
      return SetLastError(LastError | errLogoDataRead);
    *Size = GetPDULength();       // Update Size
  }
  else if (LastPDUType == NOK)    // Request not confirmed
  {
    // Get next byte
    RecvPacket(&PDU.H[1], 1);
    if (LastError)
      return SetLastError(LastError | errLogoDataRead);
    *Size = 2;  // Update Size

    // Get Error Type
    switch (PDU.H[1]) {
      case PDU_BUSY:
        // LOGO can not accept a telegram
        return SetLastError(errPGInvalidPDU | errLogoSendingPDU);
      case PDU_TIMEOUT:
        // Resource unavailable, the second cycle of the write operation timed out
        return SetLastError(errPGInvalidPDU | errLogoDataRead);
      case PDU_INVALID:
        // Illegal access, read across the border
        return SetLastError(errPGInvalidPDU | errLogoDataWrite);
      case PDU_PAR_ERR:
        // parity error-, overflow or telegram error
        return SetLastError(errPGInvalidPDU | errLogoInvalidPDU);
      case PDU_UNKNOWN: 
        // Unknown command, this mode is not supported
        return SetLastError(errPGInvalidPDU | errLogoInvalidPDU);
      case PDU_XOR_ERR:
        // XOR-check incorrect
        return SetLastError(errPGInvalidPDU | errLogoDataRead);
        break;
      case PDU_SIM_ERR:
        // Faulty on simulation, RUN is not supported in this mode
        return SetLastError(errPGInvalidPDU | errLogoDataRead);
      default:
        return SetLastError(errPGInvalidPDU | errLogoDataRead);
    }

  }
  else
    return SetLastError(errPGInvalidPDU | errLogoFunction);

  return SetLastError(0);
}

int LogoClient::RecvPacket(byte buf[], size_t Size)
{
/*
  // If you doesn't need to transfer more than 80 byte (the length of a PDU) you can uncomment the next two lines
  if (Size > MaxPduSize)
    return SetLastError(errStreamDataRecv | errBufferTooSmall);
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
  if (LastError == errStreamDataRecvTout)   // 0BA4 doesn't support a connection request
  {
    if (StreamClient->write(LOGO_REVISION, sizeof(LOGO_REVISION)) != sizeof(LOGO_REVISION))
      return SetLastError(errStreamDataSend);

    // Get 5 bytes
    RecvPacket(PDU.H, 5);
    if (LastError)
      return SetLastError(errPGConnectionFailed);
  }  
  else if (LastError)
    return SetLastError(errPGConnectionFailed);

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType != ACK)   // Connection confirm
    return SetLastError(errPGConnectionFailed);

  return SetLastError(0);
}

int LogoClient::NegotiatePduLength()
{
  if (PDULength)  // Exit if length has already been determined
    return SetLastError(0);
  
  PDULength = 0;

  if (StreamClient->write(LOGO_REVISION, sizeof(LOGO_REVISION)) != sizeof(LOGO_REVISION))
    return SetLastError(errStreamDataSend);
  
  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));
  
  // Get 5 bytes
  RecvPacket(PDU.H, 5);
  if (LastError)
    return SetLastError(LastError | errLogoDataRead);

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType != ACK)   // Connection confirm
    return SetLastError(errPGNegotiatingPDU);

  byte revision = 0;        // Revision Byte
  if (PDU.H[3] == 0xFF)     // 0BA6 and response a dword address
  {
    // Get 2 more bytes
    RecvPacket(&PDU.H[5], 2);
    if (LastError)
      return SetLastError(LastError | errLogoDataRead);
    revision = PDU.H[6];
  } 
  else
    revision = PDU.H[4];

  switch (revision) {
    case 0x40:
      // 0BA4
      PDULength = PduSize0BA4;
      PDUHeaderLen = Size_0BA4;
      Mapping = VM_MAP_923_983_0BA4;
      break;
    case 0x42:
      // 0BA5
      PDULength = PduSize0BA5;
      PDUHeaderLen = Size_0BA5;
      Mapping = VM_MAP_923_983_0BA4;
      break;
    case 0x43:
    case 0x44:
      // 0BA6
      PDULength = PduSize0BA6;
      PDUHeaderLen = Size_0BA6;
      Mapping = VM_MAP_923_983_0BA6;
      break;
    default:
      // 0BAx
      return SetLastError(errPGNegotiatingPDU);
  } 

  return SetLastError(0);
}

int LogoClient::SetLastError(int Error)
{
  LastError = Error;
  return Error;
}
