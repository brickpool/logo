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
#define OP          0x02

// PDU related constants
#define MinPduSize  666     // Minimum LOGO valid telegram size
#define MaxPduSize  80      // Maximum LOGO valid telegram size
#define CC          0x06    // Connection confirmed
#define NOK         0x14    // Connection not confirmed

// Ist jedoch ein Fehler aufgetreten, dann sendet die LOGO! eine negative Bestätigung (21)
// und anschließend ein Fehlerbyte mit folgenden Codes:
#define PDU_BUSY    0x01    // LOGO! kann kein Telegramm annehmen
#define PDU_INVALID 0x03    // Nicht zulässiger Zugriff
#define PDU_ERR     0x04    // Paritäts-, Überlauf- oder Telegramm-Fehler
#define PDU_UNKNOWN 0x05    // Unbekanntes Kommando
#define PDU_XOR_ERR 0x06    // XOR-Summe fehlerhaft
#define PDU_SIM_ERR 0x07    // Simulationsfehler

// LOGO ID Area (Area that we want to read/write)
#define LogoAreaDB  0x84

const byte LogoCpuStatusUnknown = 0x00;
const byte LogoCpuStatusRun     = 0x08;
const byte LogoCpuStatusStop    = 0x04;

extern byte RxOffsetQ;
extern byte RxOffsetS;
#define Size_RD     666
#define Size_WR     27

typedef HardwareSerial  *pserial;
typedef byte            *pbyte;
typedef word            *pword;
typedef int             *pint;

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
private:
	uint8_t LastPDUType;
	uint16_t ConnType;
	
	pserial SerialClient;
	
	int PDULength;    // PDU Length negotiated
	int WaitForData(uint16_t Size, uint16_t Timeout);
	int RecvIOPacket(uint16_t *Size);
	int RecvPacket(uint8_t *buf, uint16_t Size);
	int SerialConnect();
	int LogoConnect();
	int NegotiatePduLength();
	int SetLastError(int Error);
public:
	// Output properties
	bool Connected;   // true if the Client is connected
	int LastError;    // Last Operation error
	// Input properties
	uint16_t RecvTimeout; // Receving timeour
	// Methods
	LogoClient();
	LogoClient(pserial Interface);
	~LogoClient();
	// Basic functions
	void SetConnectionParams(pserial Interface);
	void SetConnectionType(uint16_t ConnectionType);
	int ConnectTo(pserial Interface);
	int Connect();
	void Disconnect();
	int ReadArea(int Area, uint16_t DBNumber, uint16_t Start, uint16_t Amount, void *ptrData); 
	int GetPDULength() { return PDULength; }
	// Extended functions
  int PlcStart(); // Warm start
  int PlcStop();
  int GetPlcStatus(int *Status);
	void ErrorText(int Error, char *Text, int TextLen);
};


/*
-------------------------------------------------------------------------------------------
 Logo-Parameter
 0BA4 0BA5 0BA6
 Pos  Pos  Pos      Bezeichnung
-----------------------------------
 27   29   37       Eingänge 1-8
 28   30   38       Eingänge 9-16
 29   31   39       Eingänge 17-24

           40       TD-Funktionstasten
 
 30   32   41       Ausgänge 1-8
 31   33   42       Ausgänge 9-16
 
 32   34   43       Merker 1-8
 33   35   44       Merker 9-16
 34   36   45       Merker 17-24
           46       Merker 25-27

 35   37   47       Schieberegister 1-8
 36   38   48       Cursortasten C1-C4
 
 37   39   49       Analogeingang 1 Low
 38   40   50       Analogeingang 1 High
 39   41   51       Analogeingang 2 Low
 40   42   52       Analogeingang 2 High
 41   43   53       Analogeingang 3 Low
 42   44   54       Analogeingang 3 High
 43   45   55       Analogeingang 4 Low
 44   46   56       Analogeingang 4 High
 45   47   57       Analogeingang 5 Low
 46   48   58       Analogeingang 5 High
 47   49   59       Analogeingang 6 Low
 48   50   60       Analogeingang 6 High
 49   51   61       Analogeingang 7 Low
 50   52   62       Analogeingang 7 High
 51   53   63       Analogeingang 8 Low
 52   54   64       Analogeingang 8 High

 53   55   65       Analogausgang 1 Low
 54   56   66       Analogausgang 1 High
 55   57   67       Analogausgang 2 Low
 56   58   68       Analogausgang 2 High
 
 57   59   69       Analogmerker 1 Low
 58   60   70       Analogmerker 1 High
 59   61   71       Analogmerker 2 Low
 61   62   72       Analogmerker 2 High
 61   63   73       Analogmerker 3 Low
 62   64   74       Analogmerker 3 High
 63   65   75       Analogmerker 4 Low
 64   66   76       Analogmerker 4 High
 65   67   77       Analogmerker 5 Low
 66   68   78       Analogmerker 5 High
 67   69   79       Analogmerker 6 Low
 68   70   80       Analogmerker 6 High
*/


//#define LOGO_0BA4
//#define LOGO_0BA5
#define LOGO_0BA6

#ifdef LOGO_0BA4
#define I_OFFSET  27
#define Q_OFFSET  30
#define M_OFFSET  32
#define C_OFFSET  36
#undef  F_OFFSET
#define S_OFFSET  35
#define AI_OFFSET 37
#define AQ_OFFSET 53
#define AM_OFFSET 57
#define AA_END    69
#endif

#ifdef LOGO_0BA5
#define I_OFFSET  29
#define Q_OFFSET  32
#define M_OFFSET  34
#define C_OFFSET  38
#define S_OFFSET  37
#define AI_OFFSET 39
#define AQ_OFFSET 55
#define AM_OFFSET 59
#define AA_END    71
#endif

#ifdef LOGO_0BA6
#define I_OFFSET  37
#define Q_OFFSET  41
#define M_OFFSET  43
#define C_OFFSET  48
#define F_OFFSET  40
#define S_OFFSET  47
#define AI_OFFSET 49
#define AQ_OFFSET 65
#define AM_OFFSET 69
#define AA_END    81
#endif

extern byte range[AA_END];

// Eingänge (datatype: bit)
#define I1    ((range[I_OFFSET+0] & (1 << 0)) > 0)
#define I2    ((range[I_OFFSET+0] & (1 << 1)) > 0)
#define I3    ((range[I_OFFSET+0] & (1 << 2)) > 0)
#define I4    ((range[I_OFFSET+0] & (1 << 3)) > 0)
#define I5    ((range[I_OFFSET+0] & (1 << 4)) > 0)
#define I6    ((range[I_OFFSET+0] & (1 << 5)) > 0)
#define I7    ((range[I_OFFSET+0] & (1 << 6)) > 0)
#define I8    ((range[I_OFFSET+0] & (1 << 7)) > 0)
#define I9    ((range[I_OFFSET+1] & (1 << 0)) > 0)
#define I10   ((range[I_OFFSET+1] & (1 << 1)) > 0)
#define I11   ((range[I_OFFSET+1] & (1 << 2)) > 0)
#define I12   ((range[I_OFFSET+1] & (1 << 3)) > 0)
#define I13   ((range[I_OFFSET+1] & (1 << 4)) > 0)
#define I14   ((range[I_OFFSET+1] & (1 << 5)) > 0)
#define I15   ((range[I_OFFSET+1] & (1 << 6)) > 0)
#define I16   ((range[I_OFFSET+1] & (1 << 7)) > 0)
#define I17   ((range[I_OFFSET+2] & (1 << 0)) > 0)
#define I18   ((range[I_OFFSET+2] & (1 << 1)) > 0)
#define I19   ((range[I_OFFSET+2] & (1 << 2)) > 0)
#define I20   ((range[I_OFFSET+2] & (1 << 3)) > 0)
#define I21   ((range[I_OFFSET+2] & (1 << 4)) > 0)
#define I22   ((range[I_OFFSET+2] & (1 << 5)) > 0)
#define I23   ((range[I_OFFSET+2] & (1 << 6)) > 0)
#define I24   ((range[I_OFFSET+2] & (1 << 7)) > 0)

// Ausgänge (datatype: bit)
#define Q1    ((range[Q_OFFSET+0] & (1 << 0)) > 0)
#define Q2    ((range[Q_OFFSET+0] & (1 << 1)) > 0)
#define Q3    ((range[Q_OFFSET+0] & (1 << 2)) > 0)
#define Q4    ((range[Q_OFFSET+0] & (1 << 3)) > 0)
#define Q5    ((range[Q_OFFSET+0] & (1 << 4)) > 0)
#define Q6    ((range[Q_OFFSET+0] & (1 << 5)) > 0)
#define Q7    ((range[Q_OFFSET+0] & (1 << 6)) > 0)
#define Q8    ((range[Q_OFFSET+0] & (1 << 7)) > 0)
#define Q9    ((range[Q_OFFSET+1] & (1 << 0)) > 0)
#define Q10   ((range[Q_OFFSET+1] & (1 << 1)) > 0)
#define Q11   ((range[Q_OFFSET+1] & (1 << 2)) > 0)
#define Q12   ((range[Q_OFFSET+1] & (1 << 3)) > 0)
#define Q13   ((range[Q_OFFSET+1] & (1 << 4)) > 0)
#define Q14   ((range[Q_OFFSET+1] & (1 << 5)) > 0)
#define Q15   ((range[Q_OFFSET+1] & (1 << 6)) > 0)
#define Q16   ((range[Q_OFFSET+1] & (1 << 7)) > 0)

// Merker (datatype: bit)
#define M1    ((range[M_OFFSET+0] & (1 << 0)) > 0)
#define M2    ((range[M_OFFSET+0] & (1 << 1)) > 0)
#define M3    ((range[M_OFFSET+0] & (1 << 2)) > 0)
#define M4    ((range[M_OFFSET+0] & (1 << 3)) > 0)
#define M5    ((range[M_OFFSET+0] & (1 << 4)) > 0)
#define M6    ((range[M_OFFSET+0] & (1 << 5)) > 0)
#define M7    ((range[M_OFFSET+0] & (1 << 6)) > 0)
#define M8    ((range[M_OFFSET+0] & (1 << 7)) > 0)
#define M9    ((range[M_OFFSET+1] & (1 << 0)) > 0)
#define M10   ((range[M_OFFSET+1] & (1 << 1)) > 0)
#define M11   ((range[M_OFFSET+1] & (1 << 2)) > 0)
#define M12   ((range[M_OFFSET+1] & (1 << 3)) > 0)
#define M13   ((range[M_OFFSET+1] & (1 << 4)) > 0)
#define M14   ((range[M_OFFSET+1] & (1 << 5)) > 0)
#define M15   ((range[M_OFFSET+1] & (1 << 6)) > 0)
#define M16   ((range[M_OFFSET+1] & (1 << 7)) > 0)
#define M17   ((range[M_OFFSET+2] & (1 << 0)) > 0)
#define M18   ((range[M_OFFSET+2] & (1 << 1)) > 0)
#define M19   ((range[M_OFFSET+2] & (1 << 2)) > 0)
#define M20   ((range[M_OFFSET+2] & (1 << 3)) > 0)
#define M21   ((range[M_OFFSET+2] & (1 << 4)) > 0)
#define M22   ((range[M_OFFSET+2] & (1 << 5)) > 0)
#define M23   ((range[M_OFFSET+2] & (1 << 6)) > 0)
#define M24   ((range[M_OFFSET+2] & (1 << 7)) > 0)
#ifdef LOGO_0BA6
#define M25   ((range[M_OFFSET+3] & (1 << 0)) > 0)
#define M26   ((range[M_OFFSET+4] & (1 << 1)) > 0)
#define M27   ((range[M_OFFSET+4] & (1 << 2)) > 0)
#define M28   ((range[M_OFFSET+4] & (1 << 3)) > 0)
#define M29   ((range[M_OFFSET+4] & (1 << 4)) > 0)
#define M30   ((range[M_OFFSET+4] & (1 << 5)) > 0)
#define M31   ((range[M_OFFSET+4] & (1 << 6)) > 0)
#define M32   ((range[M_OFFSET+4] & (1 << 7)) > 0)
#endif

// Cursortaste C1 - C4 (datatype: bit)
#define C1    ((range[C_OFFSET+0] & (1 << 0)) > 0)
#define C2    ((range[C_OFFSET+0] & (1 << 1)) > 0)
#define C3    ((range[C_OFFSET+0] & (1 << 2)) > 0)
#define C4    ((range[C_OFFSET+0] & (1 << 3)) > 0)

// Funktionstaste F1 - F4 (datatype: bit)
#ifdef F_OFFSET
#define F1    ((range[F_OFFSET+0] & (1 << 0)) > 0)
#define F2    ((range[F_OFFSET+0] & (1 << 1)) > 0)
#define F3    ((range[F_OFFSET+0] & (1 << 2)) > 0)
#define F4    ((range[F_OFFSET+0] & (1 << 3)) > 0)
#endif

// Schieberegister (datatype: bit)
#define S1    ((range[S_OFFSET+0] & (1 << 0)) > 0)
#define S2    ((range[S_OFFSET+0] & (1 << 1)) > 0)
#define S3    ((range[S_OFFSET+0] & (1 << 2)) > 0)
#define S4    ((range[S_OFFSET+0] & (1 << 3)) > 0)
#define S5    ((range[S_OFFSET+0] & (1 << 4)) > 0)
#define S6    ((range[S_OFFSET+0] & (1 << 5)) > 0)
#define S7    ((range[S_OFFSET+0] & (1 << 6)) > 0)
#define S8    ((range[S_OFFSET+0] & (1 << 7)) > 0)

// Analoge Eingänge (datatype: word)
#define AI1   ((word)(range[AI_OFFSET+ 1] << 8) + range[AI_OFFSET+ 0])
#define AI2   ((word)(range[AI_OFFSET+ 3] << 8) + range[AI_OFFSET+ 2])
#define AI3   ((word)(range[AI_OFFSET+ 5] << 8) + range[AI_OFFSET+ 4])
#define AI4   ((word)(range[AI_OFFSET+ 7] << 8) + range[AI_OFFSET+ 6])
#define AI5   ((word)(range[AI_OFFSET+ 9] << 8) + range[AI_OFFSET+ 8])
#define AI6   ((word)(range[AI_OFFSET+11] << 8) + range[AI_OFFSET+10])
#define AI7   ((word)(range[AI_OFFSET+13] << 8) + range[AI_OFFSET+12])
#define AI8   ((word)(range[AI_OFFSET+15] << 8) + range[AI_OFFSET+14])

// Analoge Ausgänge (datatype: word)
#define AQ1   ((word)(range[AQ_OFFSET+ 1] << 8) + range[AQ_OFFSET+ 0])
#define AQ2   ((word)(range[AQ_OFFSET+ 3] << 8) + range[AQ_OFFSET+ 2])

// Analoge Merker (datatype: word)
#define AM1   ((word)(range[AM_OFFSET+ 1] << 8) + range[AM_OFFSET+ 0])
#define AM2   ((word)(range[AM_OFFSET+ 3] << 8) + range[AM_OFFSET+ 2])
#define AM3   ((word)(range[AM_OFFSET+ 5] << 8) + range[AM_OFFSET+ 4])
#define AM4   ((word)(range[AM_OFFSET+ 7] << 8) + range[AM_OFFSET+ 6])
#define AM5   ((word)(range[AM_OFFSET+ 9] << 8) + range[AM_OFFSET+ 8])
#define AM6   ((word)(range[AM_OFFSET+11] << 8) + range[AM_OFFSET+10])

#endif
