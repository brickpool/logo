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

#ifndef LogoPG_h_
#define LogoPG_h_

#define LOGO_PG_0_2

#include "Arduino.h"

// Error Codes 
// from 0x0001 up to 0x00FF are severe errors, the Client should be disconnected
// from 0x0100 are LOGO Errors such as DB not found or address beyond the limit etc..
#define errStreamConnectionFailed   0x0001
#define errStreamConnectionReset    0x0002
#define errStreamDataRecvTout       0x0003
#define errStreamDataSend           0x0004
#define errStreamDataRecv           0x0005
#define errPGConnectionFailed       0x0006
#define errPGNegotiatingPDU         0x0007
#define errPGInvalidPDU             0x0008

#define errLogoInvalidPDU           0x0100
#define errLogoSendingPDU           0x0200
#define errLogoDataRead             0x0300
#define errLogoDataWrite            0x0400
#define errLogoFunction             0x0500
#define errBufferTooSmall           0x0600

// Connection Type
#define PG          0x01

// PDU related constants
#define PduSize0BA4   68    // LOGO 0BA4 telegram size
#define PduSize0BA5   70    // LOGO 0BA5 telegram size
#define PduSize0BA6   80    // LOGO 0BA6 telegram size
#define MinPduSize    68    // Minimum valid telegram size (negotiate 0BA4)
#define MaxPduSize    80    // Maximum valid telegram size (negotiate 0BA6)

#define ACK         0x06    // ACK request
#define RUN         0x01    // Mode run
#define STOP        0x41    // Mode stop
#define NOK         0x14    // Request not confirmed
#define AA          0xAA    // End delimiter of telegram

// LOGO ID Area (Area that we want to read/write)
#define LogoAreaDB  0x84

const byte LogoCpuStatusUnknown = 0x00;
const byte LogoCpuStatusRun     = 0x08;
const byte LogoCpuStatusStop    = 0x04;

#define Size_0BA4     26
#define Size_0BA6     36

typedef Stream *pstream;
typedef byte   *pbyte;
typedef int    *pint;

typedef struct {
  byte H[Size_0BA6];                // PDU Header
  byte DATA[MaxPduSize-Size_0BA6];  // PDU Data
} TPDU;
extern TPDU PDU;

// LOGO 0BA4 and 0BA5 offset values in PDU.DATA
#define I_0BA4        0
#define Q_0BA4        3
#define M_0BA4        5
#define C_0BA4        8
#define S_0BA4        9
#define AI_0BA4       10
#define AQ_0BA4       26
#define AM_0BA4       30

// LOGO 0BA6 offset values in PDU.DATA
#define I_0BA6        0
#define F_0BA6        3
#define Q_0BA6        4
#define M_0BA6        6
#define C_0BA6        10
#define S_0BA6        11
#define AI_0BA6       12
#define AQ_0BA6       28
#define AM_0BA6       32

// LOGO 0BA7 adress values in VM memory
#define I_ADDR_0BA7   923
#define AI_ADDR_0BA7  926
#define Q_ADDR_0BA7   942
#define AQ_ADDR_0BA7  944
#define M_ADDR_0BA7   948
#define AM_ADDR_0BA7  952

class LogoHelper
{
public:
  bool BitAt(void *Buffer, int ByteIndex, byte BitIndex);
  bool BitAt(int ByteIndex, int BitIndex);

  byte ByteAt(void *Buffer, int index);
  byte ByteAt(int index);

  word WordAt(void *Buffer, int index);
  word WordAt(int index);

  int IntegerAt(void *Buffer, int index);
  int IntegerAt(int index);
};
extern LogoHelper LH;

class LogoClient
{
public:
  // Output properties
  bool Connected;   // true if the Client is connected
  int LastError;    // Last Operation error

  // Input properties
  unsigned long RecvTimeout; // Receving timeout in millis

  // Methods
  LogoClient();
  LogoClient(pstream Interface);
  ~LogoClient();

  // Basic functions
  void SetConnectionParams(pstream Interface);
  void SetConnectionType(word ConnectionType);
  int ConnectTo(pstream Interface);
  int Connect();
  void Disconnect();
  int ReadArea(int Area, word DBNumber, word Start, word Amount, void *ptrData);
  int GetPDULength() { return PDULength; }
  int GetPDUHeaderLen() { return Size_0BA4+OffsetI; }

  // Extended functions
  int PlcStart();   // start PLC
  int PlcStop();    // stop PLC
  int GetPlcStatus(int *Status);

private:
  byte LastPDUType; // First byte of a received message
  word ConnType;    // Programming or running mode
  
  pstream StreamClient;
  
  int PDULength;    // PDU Length negotiated (0 if not negotiated)
  int OffsetI;      // PDU Data offset negotiated for input
  int OffsetF;      // ... function keys
  int OffsetQ;      // ... output
  int OffsetM;      // ... merker
  int OffsetS;      // ... shift register
  int OffsetC;      // ... cursor keys
  int OffsetAI;     // ... analog input
  int OffsetAQ;     // ... analog output
  int OffsetAM;     // ... analog merker

  int RecvIOPacket(size_t *Size);
  int RecvPacket(byte buf[], size_t Size);
  int StreamConnect();
  int LogoConnect();
  int NegotiatePduLength();
  int SetLastError(int Error);
};


/*
 ***********************************************************************
 * PDU header
 * position           description
 * 0BA4 0BA5 0BA6
 ***********************************************************************
    0    0    0       Start delimiter
                      0x06  Connection Connect (CC)
                      0x14  Request not confirmed (NOK)

    ...               Data (see above)

    68   70   80      End delimiter
                      AA
 ***********************************************************************


 ***********************************************************************
 * PDU data
 * position           description
 * 0BA4 0BA5 0BA6
 ***********************************************************************
    27   29   37      input 1-8
    28   30   38      input 9-16
    29   31   39      input 17-24
   
              40      TD function key F1-F4
    
    30   32   41      output 1-8
    31   33   42      output 9-16
    
    32   34   43      merker 1-8
    33   35   44      merker 9-16
    34   36   45      merker 17-24
              46      merker 25-27
   
    35   37   47      shift register 1-8

    36   38   48      cursor key C1-C4
    
    37   39   49      analog input 1 low
    38   40   50      analog input 1 high
    39   41   51      analog input 2 low
    40   42   52      analog input 2 high
    41   43   53      analog input 3 low
    42   44   54      analog input 3 high
    43   45   55      analog input 4 low
    44   46   56      analog input 4 high
    45   47   57      analog input 5 low
    46   48   58      analog input 5 high
    47   49   59      analog input 6 low
    48   50   60      analog input 6 high
    49   51   61      analog input 7 low
    50   52   62      analog input 7 high
    51   53   63      analog input 8 low
    52   54   64      analog input 8 high
   
    53   55   65      analog output 1 low
    54   56   66      analog output 1 high
    55   57   67      analog output 2 low
    56   58   68      analog output 2 high
    
    57   59   69      analog merker 1 low
    58   60   70      analog merker 1 high
    59   61   71      analog merker 2 low
    61   62   72      analog merker 2 high
    61   63   73      analog merker 3 low
    62   64   74      analog merker 3 high
    63   65   75      analog merker 4 low
    64   66   76      analog merker 4 high
    65   67   77      analog merker 5 low
    66   68   78      analog merker 5 high
    67   69   79      analog merker 6 low
    68   70   80      analog merker 6 high
 ***********************************************************************
*/

#endif
