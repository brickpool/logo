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
 *  
*/

#include "Arduino.h"
#include "LogoPG.h"

// For further informations about structures (the byte arrays and they meanins)
// see http://github.com/brickpool/logo

// LOGO Connection Request
const byte LOGO_CR[] = {
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
#define PDU_INVALID 0x03  // Illegal access
#define PDU_ERR     0x04  // parity error-, overflow or telegram error
#define PDU_UNKNOWN 0x05  // Unknown command
#define PDU_XOR_ERR 0x06  // XOR-check incorrect
#define PDU_SIM_ERR 0x07  // Faulty on simulation 

#define TIMEOUT     500   // 500 ms

// The LOGO has reserved fixed memory addresses for inputs, outputs, flags in the VM memory above the 850th byte.
// These depending on the model (Logo 0BA7 or 0BA8). Our library should represent the VM memory as 0BA7 address scheme.
#define VM_I_ADDR     I_ADDR_0BA7
#define VM_AI_ADDR    AI_ADDR_0BA7
#define VM_Q_ADDR     Q_ADDR_0BA7
#define VM_AQ_ADDR    AQ_ADDR_0BA7
#define VM_M_ADDR     M_ADDR_0BA7
#define VM_AM_ADDR    AM_ADDR_0BA7
#define VM_I_SIZE     3
#define VM_AI_SIZE    16
#define VM_Q_SIZE     2
#define VM_AQ_SIZE    4
#define VM_M_SIZE     4
#define VM_AM_SIZE    12

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
  ConnType  = PG;
  Connected = false;
  LastError = 0;
  PDULength = 0;
  OffsetI   = I_0BA6;
  OffsetF   = F_0BA6;
  OffsetQ   = Q_0BA6;
  OffsetM   = M_0BA6;
  OffsetS   = S_0BA6;
  OffsetC   = C_0BA6;
  OffsetAI  = AI_0BA6;
  OffsetAQ  = AQ_0BA6;
  OffsetAM  = AM_0BA6;
  RecvTimeout = TIMEOUT;
  StreamClient = NULL;
}

LogoClient::LogoClient(pstream Interface)
{
  ConnType  = PG;
  Connected = false;
  LastError = 0;
  PDULength = 0;
  OffsetI   = I_0BA6;
  OffsetF   = F_0BA6;
  OffsetQ   = Q_0BA6;
  OffsetM   = M_0BA6;
  OffsetS   = S_0BA6;
  OffsetC   = C_0BA6;
  OffsetAI  = AI_0BA6;
  OffsetAQ  = AQ_0BA6;
  OffsetAM  = AM_0BA6;
  RecvTimeout = TIMEOUT;
  StreamClient = Interface;
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

  // For LOGO 0BA4 to 0BA6 the only compatible memory that we can read is the IO-buffer.
  // We will represented this as V memory, that is seen by all HMI as DB 1.
  if (Area != LogoAreaDB && DBNumber != 1)
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

  // Mapping 0BA4, 0BA5 or 0BA6 PDU.DATA to 0BA7 VM-adresses
  TotElements = Amount; // WordSize = 1 (An element has a size of one byte)

  // Set buffer to 0
  SizeRequested = TotElements;
  memset(Target+Offset, 0, SizeRequested);

  // Skip if Start before first VM address
  Address = VM_I_ADDR;
  if (Start < Address)
  {
    MaxElements = Address - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    SizeRequested = NumElements;
    // no copy

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Copy 'input' PDU data to 'input' VM memory
  Address = VM_I_ADDR+VM_I_SIZE+1;
  if (Start < Address)
  {
    MaxElements = Address - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    SizeRequested = NumElements;
    memcpy(Target+Offset, &PDU.DATA[OffsetI], SizeRequested);

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Copy 'analoge intput' PDU data to 'analoge intput' VM memory
  Address = VM_AI_ADDR+VM_AI_SIZE+1;
  if (Start < Address)
  {
    MaxElements = Address - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    SizeRequested = NumElements;
    memcpy(Target+Offset, &PDU.DATA[OffsetAI], SizeRequested);

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Copy 'output' PDU data to 'output' VM memory
  Address = VM_Q_ADDR+VM_Q_SIZE+1;
  if (Start < Address)
  {
    MaxElements = Address - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    SizeRequested = NumElements;
    memcpy(Target+Offset, &PDU.DATA[OffsetQ], SizeRequested);

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Copy 'analoge output' PDU data to 'analoge output' VM memory
  Address = VM_AQ_ADDR+VM_AQ_SIZE+1;
  if (Start < Address)
  {
    MaxElements = Address - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    SizeRequested = NumElements;
    memcpy(Target+Offset, &PDU.DATA[OffsetAQ], SizeRequested);

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Copy 'merker' PDU data to 'merker' VM memory
  Address = VM_M_ADDR+VM_M_SIZE+1;
  if (Start < Address)
  {
    MaxElements = Address - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    SizeRequested = NumElements;
    memcpy(Target+Offset, &PDU.DATA[OffsetM], SizeRequested);

    TotElements -= NumElements;
    Start += NumElements;

    Offset += SizeRequested;
  }

  // Copy 'analoge merker' PDU data to 'merker' VM memory
  Address = VM_AM_ADDR+VM_AM_SIZE+1;
  if (Start < Address)
  {
    MaxElements = Address - Start;
    NumElements = MaxElements > TotElements ? TotElements : MaxElements;

    SizeRequested = NumElements;
    memcpy(Target+Offset, &PDU.DATA[OffsetAM], SizeRequested);
    
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
    return SetLastError(LastError | errLogoFunction);

  if (Status != LogoCpuStatusStop)
  {
    if (StreamClient->write(LOGO_START, sizeof(LOGO_START)) != sizeof(LOGO_START))
      return SetLastError(errStreamDataSend | errLogoSendingPDU);
  
    // Setup the telegram
    memset(&PDU, 0, sizeof(PDU));

    // Get 1 Byte
    RecvPacket(PDU.H, 1); 
    if (LastError)
      return SetLastError(LastError | errLogoDataRead);
  
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
    return SetLastError(LastError | errLogoFunction);

  if (Status != LogoCpuStatusRun)
  {
    if (StreamClient->write(LOGO_STOP, sizeof(LOGO_STOP)) != sizeof(LOGO_STOP))
      return SetLastError(errStreamDataSend | errLogoSendingPDU);
  
    // Setup the telegram
    memset(&PDU, 0, sizeof(PDU));

    // Get 1 Byte
    RecvPacket(PDU.H, 1);
    if (LastError)
      return SetLastError(LastError | errLogoDataRead);
  
    LastPDUType = PDU.H[0];   // Store PDU Type
    if (LastPDUType != ACK)   // Connection confirmed
      return SetLastError(errPGInvalidPDU | errLogoFunction);
  }

  return SetLastError(0);
}

int LogoClient::GetPlcStatus(int *Status)
{
  *Status = LogoCpuStatusUnknown;
  
  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnectionFailed | errLogoInvalidPDU);

  if (StreamClient->write(LOGO_MODE, sizeof(LOGO_MODE)) != sizeof(LOGO_MODE))
    return SetLastError(errStreamDataSend | errLogoSendingPDU);

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
    return SetLastError(errPGInvalidPDU | errLogoDataRead);
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
    return SetLastError(LastError | errLogoFunction);
  
  // Operation mode must be RUN if we use LOGO_GET
  if (Status != LogoCpuStatusRun) // Exit with Error if the LOGO is not in operation mode RUN
    return SetLastError(errPGInvalidPDU);

  if (StreamClient->write(LOGO_GET, sizeof(LOGO_GET)) != sizeof(LOGO_GET))
    return SetLastError(errStreamDataSend | errLogoSendingPDU);

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
      case PDU_INVALID:
        // Illegal access
        return SetLastError(errPGInvalidPDU | errLogoDataWrite);
      case PDU_ERR:
        // parity error-, overflow or telegram error
        return SetLastError(errPGInvalidPDU | errLogoDataRead);
      case PDU_UNKNOWN: 
        // Unknown command
        return SetLastError(errPGInvalidPDU | errLogoFunction);
      case PDU_XOR_ERR:
        // XOR-check incorrect
        break;
      case PDU_SIM_ERR:
        return SetLastError(errPGInvalidPDU | errLogoInvalidPDU);
      default:
        return SetLastError(errPGInvalidPDU | errLogoInvalidPDU);
    }

  }
  else
    return SetLastError(errPGInvalidPDU | errLogoFunction);

  return SetLastError(0);
}

int LogoClient::RecvPacket(byte buf[], size_t Size)
{
  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnectionFailed);

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
      return SetLastError(errStreamConnectionReset | errLogoDataRead);

    return SetLastError(errStreamDataRecvTout | errLogoDataRead);
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
    return SetLastError(errStreamDataSend | errLogoSendingPDU);

  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));
  
  // Get 5 bytes
  RecvPacket(PDU.H, 5);
  if (LastError)
    return SetLastError(LastError | errLogoDataRead);

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType != ACK)   // Connection confirm
    return SetLastError(errPGConnectionFailed | errLogoFunction);

  return SetLastError(0);
}

int LogoClient::NegotiatePduLength()
{
  if (PDULength)  // Exit if length has already been determined
    return SetLastError(0);
  
  PDULength = 0;

  if (!Connected) // Exit with Error if not connected
    return SetLastError(errPGConnectionFailed);

  int Status;
  GetPlcStatus(&Status);
  if (LastError)
    return SetLastError(LastError | errLogoFunction);
  
  // Operation mode must be RUN if we use LOGO_GET
  if (Status != LogoCpuStatusRun) // Exit with Error if the LOGO is not in operation mode RUN
    return SetLastError(errPGInvalidPDU);


  if (StreamClient->write(LOGO_GET, sizeof(LOGO_GET)) != sizeof(LOGO_GET))
    return SetLastError(errStreamDataSend | errLogoSendingPDU);
  
  // Setup the telegram
  memset(&PDU, 0, sizeof(PDU));
  
  // Get 26 bytes
  RecvPacket(PDU.H, Size_0BA4);
  if (LastError)
    return SetLastError(LastError | errLogoDataRead);

  LastPDUType = PDU.H[0];   // Store PDU Type
  if (LastPDUType != ACK)   // Connection confirm
    return SetLastError(errPGNegotiatingPDU | errLogoFunction);

  // Get next bytes and count number of received bytes
  PDULength = Size_0BA4;
  while (StreamClient->available() > 0)
  {
    if (StreamClient->read() > 0)
      PDULength++;
  }

  if (PDULength == PduSize0BA4 || PDULength == PduSize0BA5)
  {
    OffsetI   = I_0BA4;
    OffsetF   = 0;
    OffsetQ   = Q_0BA4;
    OffsetM   = M_0BA4;
    OffsetS   = S_0BA4;
    OffsetC   = C_0BA4;
    OffsetAI  = AI_0BA4;
    OffsetAQ  = AQ_0BA4;
    OffsetAM  = AM_0BA4;
  }
  else if (PDULength == PduSize0BA6)
  {
    OffsetI   = I_0BA6;
    OffsetF   = F_0BA6;
    OffsetQ   = Q_0BA6;
    OffsetM   = M_0BA6;
    OffsetS   = S_0BA6;
    OffsetC   = C_0BA6;
    OffsetAI  = AI_0BA6;
    OffsetAQ  = AQ_0BA6;
    OffsetAM  = AM_0BA6;
  }
  else if (PDULength > MaxPduSize)
  {
    PDULength = 0;
    return SetLastError(errPGNegotiatingPDU | errBufferTooSmall);
  }
  else
  {
    PDULength = 0;
    return SetLastError(errPGNegotiatingPDU | errLogoDataRead);
  }

  return SetLastError(0);
}

int LogoClient::SetLastError(int Error)
{
  LastError = Error;
  return Error;
}
