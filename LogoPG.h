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
 *  2018-02-24: Version 0.3.1, change PDUSize and mapping
*/

#ifndef LogoPG_h_
#define LogoPG_h_

#define LOGO_PG_0_3

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
#define PduSize0BA4   71    // LOGO 0BA4 telegram size
#define PduSize0BA5   71    // LOGO 0BA5 telegram size
#define PduSize0BA6   81    // LOGO 0BA6 telegram size
#define MinPduSize    71    // Minimum data PDU size (0BA4)
#define MaxPduSize    81    // Maximum data PDU size (0BA6)

#define ACK         0x06    // Confirmation Response
#define RUN         0x01    // Mode run
#define STOP        0x42    // Mode stop
#define NOK         0x15    // Exception Response
#define AA          0xAA    // End delimiter

// LOGO ID Area (Area that we want to read/write)
#define LogoAreaDB  0x84

const byte LogoCpuStatusUnknown = 0x00;
const byte LogoCpuStatusRun     = 0x08;
const byte LogoCpuStatusStop    = 0x04;

#define Size_WR 6

typedef Stream *pstream;
typedef byte   *pbyte;
typedef int    *pint;

typedef struct {
  byte H[Size_WR];                // PDU Header
  byte DATA[MaxPduSize-Size_WR];  // PDU Data
} TPDU;
extern TPDU PDU;

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

  // Extended functions
  int PlcStart();   // start PLC
  int PlcStop();    // stop PLC
  int GetPlcStatus(int *Status);

private:
  byte LastPDUType; // First byte of a received message
  word ConnType;    // Programming or running mode
  
  pstream StreamClient;
  
  int PDULength;    // PDU length negotiated (0 if not negotiated)
  int PDUHeaderLen; // PDU header length negotiated (0 if not negotiated)
  byte* Mapping;   // PDU Data mapping to VM

  int RecvIOPacket(size_t *Size);
  int RecvPacket(byte buf[], size_t Size);
  int StreamConnect();
  int LogoConnect();
  int NegotiatePduLength();
  int SetLastError(int Error);
};


/*
***********************************************************************
* PDU data
* position      description
* 0BA4 0BA5 0BA6
***********************************************************************
    23  23  33  input 1-8
    24  24  34  input 9-16
    25  25  35  input 17-24
                
            36  TD function key F1-F4
                
    26  26  37  output 1-8
    27  27  38  output 9-16
                
    28  28  39  merker 1-8
    29  29  40  merker 9-16
    30  30  41  merker 17-24
            42  merker 25-27
                
    31  31  43  shift register 1-8
                
    32  32  44  cursor key C1-C4
                
    33  33  45  analog input 1 low
    34  34  46  analog input 1 high
    35  35  47  analog input 2 low
    36  36  48  analog input 2 high
    37  37  49  analog input 3 low
    38  38  50  analog input 3 high
    39  39  51  analog input 4 low
    40  40  52  analog input 4 high
    41  41  53  analog input 5 low
    42  42  54  analog input 5 high
    43  43  55  analog input 6 low
    44  44  56  analog input 6 high
    45  45  57  analog input 7 low
    46  46  58  analog input 7 high
    47  47  59  analog input 8 low
    48  48  60  analog input 8 high
                
    49  49  61  analog output 1 low
    50  50  62  analog output 1 high
    51  51  63  analog output 2 low
    52  52  64  analog output 2 high
                
    53  53  65  analog merker 1 low
    54  54  66  analog merker 1 high
    55  55  67  analog merker 2 low
    56  56  68  analog merker 2 high
    57  57  69  analog merker 3 low
    58  58  70  analog merker 3 high
    59  59  71  analog merker 4 low
    60  60  72  analog merker 4 high
    61  61  73  analog merker 5 low
    62  62  74  analog merker 5 high
    63  63  75  analog merker 6 low
    64  64  76  analog merker 6 high
***********************************************************************
*/

// LOGO 0BA4 and 0BA5 index in PDU.DATA
#define I_0BA4     0x16
#define Q_0BA4     0x19
#define M_0BA4     0x1B
#define S_0BA4     0x1E
#define C_0BA4     0x1F
#define AI_0BA4    0x20
#define AQ_0BA4    0x30
#define AM_0BA4    0x34

// LOGO 0BA6 index in PDU.DATA
#define I_0BA6     0x20
#define F_0BA6     0x23
#define Q_0BA6     0x24
#define M_0BA6     0x26
#define S_0BA6     0x2A
#define C_0BA6     0x2B
#define AI_0BA6    0x2C
#define AQ_0BA6    0x3C
#define AM_0BA6    0x40

/*
 * The LOGO > 0BA6 has reserved fixed memory addresses for inputs,
 * outputs, flags in the Variable Memory above the 850th byte.
 * These depending on the model (0BA7 or 0BA8). Our library should
 * represent the Variable Memory as 0BA7 address scheme.
 *
 * The function keys and cursor keys can not be read directly.
 * The keys must be mapped to the V address in the software via the
 * VM (Variable Memory) assignment.
 *
 * Not all of the VM space is available for accessing.You can specify
 * a maximum of 64 parameters. If you try to specify more than 64
 * parameters, LogoClient generate an error code.
 *
 ***********************************************************************
 * VM data
 * position      description
 * 0BA7 0BA8
 ***********************************************************************
   923  1024     input 1-8
   924  1025     input 9-16
   925  1026     input 17-24
   
   942  1064     output 1-8
   943  1065     output 9-16
        1066     output 17-20
   
   926  1032     analog input 1 high
   927  1033     analog input 1 low
   928  1034     analog input 2 high
   929  1035     analog input 2 low
   930  1036     analog input 3 high
   931  1037     analog input 3 low
   932  1038     analog input 4 high
   933  1039     analog input 4 low
   934  1040     analog input 5 high
   935  1041     analog input 5 low
   936  1042     analog input 6 high
   937  1043     analog input 6 low
   938  1044     analog input 7 high
   939  1045     analog input 7 low
   930  1046     analog input 8 high
   941  1047     analog input 8 low
   
   944  1072     analog output 1 high
   945  1073     analog output 1 low
   946  1074     analog output 2 high
   947  1075     analog output 2 low
        1076     analog output 3 high
        1077     analog output 3 low
        1078     analog output 4 high
        1079     analog output 4 low
        1080     analog output 5 high
        1081     analog output 5 low
        1082     analog output 6 high
        1083     analog output 6 low
        1084     analog output 7 high
        1085     analog output 7 low
        1086     analog output 8 high
        1087     analog output 8 low
   
   948  1104     merker 1-8
   949  1105     merker 9-16
   950  1106     merker 17-24
   951           merker 25-27
        1107     merker 25-32
        1108     merker 33-40
        1109     merker 41-48
        1110     merker 49-56
        1111     merker 47-64
   
   952  1118     analog merker 1 high
   953  1119     analog merker 1 low
   954  1120     analog merker 2 high
   955  1121     analog merker 2 low
   956  1122     analog merker 3 high
   957  1123     analog merker 3 low
   958  1124     analog merker 4 high
   959  1125     analog merker 4 low
   960  1126     analog merker 5 high
   961  1127     analog merker 5 low
   962  1128     analog merker 6 high
   963  1129     analog merker 6 low
   964  1130     analog merker 7 high
   965  1131     analog merker 7 low
   966  1132     analog merker 8 high
   967  1133     analog merker 8 low
   968  1134     analog merker 9 high
   969  1135     analog merker 9 low
   970  1136     analog merker 10 high
   971  1137     analog merker 10 low
   972  1138     analog merker 11 high
   973  1139     analog merker 11 low
   974  1140     analog merker 12 high
   975  1141     analog merker 12 low
   976  1142     analog merker 13 high
   977  1143     analog merker 13 low
   978  1144     analog merker 14 high
   979  1145     analog merker 14 low
   980  1146     analog merker 15 high
   981  1147     analog merker 15 low
   982  1148     analog merker 16 high
   983  1149     analog merker 16 low
 ***********************************************************************
*/

// LOGO 0BA7 adress values in VM memory
#define VM_I01_08  923
#define VM_I09_16  924
#define VM_I17_24  925

#define VM_AI1_Hi  926
#define VM_AI1_Lo  927
#define VM_AI2_Hi  928
#define VM_AI2_Lo  929
#define VM_AI3_Hi  930
#define VM_AI3_Lo  931
#define VM_AI4_Hi  932
#define VM_AI4_Lo  933
#define VM_AI5_Hi  934
#define VM_AI5_Lo  935
#define VM_AI6_Hi  936
#define VM_AI6_Lo  937
#define VM_AI7_Hi  938
#define VM_AI7_Lo  939
#define VM_AI8_Hi  940
#define VM_AI8_Lo  941

#define VM_Q01_08  942
#define VM_Q09_16  943

#define VM_AQ1_Hi  944
#define VM_AQ1_Lo  945
#define VM_AQ2_Hi  946
#define VM_AQ2_Lo  947

#define VM_M01_08  948
#define VM_M09_16  949
#define VM_M17_24  950
#define VM_M25_27  951

#define VM_AM1_Hi  952
#define VM_AM1_Lo  953
#define VM_AM2_Hi  954
#define VM_AM2_Lo  955
#define VM_AM3_Hi  956
#define VM_AM3_Lo  957
#define VM_AM4_Hi  958
#define VM_AM4_Lo  959
#define VM_AM5_Hi  960
#define VM_AM5_Lo  961
#define VM_AM6_Hi  962
#define VM_AM6_Lo  963
#define VM_AM7_Hi  964
#define VM_AM7_Lo  965
#define VM_AM8_Hi  966
#define VM_AM8_Lo  967

#define VM_AM9_Hi  968
#define VM_AM9_Lo  969
#define VM_AM10_Hi 970
#define VM_AM10_Lo 971
#define VM_AM11_Hi 972
#define VM_AM11_Lo 973
#define VM_AM12_Hi 974
#define VM_AM12_Lo 975
#define VM_AM13_Hi 976
#define VM_AM13_Lo 977
#define VM_AM14_Hi 978
#define VM_AM14_Lo 979
#define VM_AM15_Hi 980
#define VM_AM15_Lo 981
#define VM_AM16_Hi 982
#define VM_AM16_Lo 983

#define VM_DIAG    984
#define VM_RTC_YY  985
#define VM_RTC_MM  986
#define VM_RTC_DD  987
#define VM_RTC_hh  988
#define VM_RTC_mm  989
#define VM_RTC_ss  990

// LOGO 0BA7 index in VM
#define I_0BA7     VM_I01_08
#define Q_0BA7     VM_Q01_08
#define M_0BA7     VM_M01_08
#define AI_0BA7    VM_AI1_Hi
#define AQ_0BA7    VM_AQ1_Hi
#define AM_0BA7    VM_AM9_Hi

#endif
