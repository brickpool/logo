#include "Arduino.h"
#include "LogoPG.h"

// For further informations about structures (the byte arrays and they meanins)
// see http://github.com/brickpool/logo


// LOGO Connection Request Telegram
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

// LOGO Status Request Telegram
const byte LOGO_STATUS[] = {
    0x55, 0x17, 0x17, 0xAA
};

#define BAUDRATE  9600  // data rate in bits per second (baud)
#define TIMEOUT   500   // 500 ms

TPDU PDU;

LogoHelper LH;

byte RxOffsetQ = 0;
byte RxOffsetS = 0;

byte range[AA_END];

//-----------------------------------------------------------------------------
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
	return BitAt(&PDU.DATA[0], ByteIndex, BitIndex);
}

byte LogoHelper::ByteAt(void *Buffer, int index)
{
	pbyte Pointer = pbyte(Buffer) + index;
	return *Pointer;
}

byte LogoHelper::ByteAt(int index)
{
	return ByteAt(&PDU.DATA, index);
}

word LogoHelper::WordAt(void *Buffer, int index)
{
	word hi = (*(pbyte(Buffer) + index)) << 8;
	return hi+*(pbyte(Buffer) + index+1);
}

word LogoHelper::WordAt(int index)
{
	return WordAt(&PDU.DATA, index);
}

int LogoHelper::IntegerAt(void *Buffer, int index)
{
	word w = WordAt(Buffer, index);
	return *(pint(&w));
}

int LogoHelper::IntegerAt(int index)
{
	return IntegerAt(&PDU.DATA, index);
}


//-----------------------------------------------------------------------------
LogoClient::LogoClient()
{
  ConnType = PG;
  Connected = false;
  LastError = 0;
  PDULength = 0;
  RecvTimeout = TIMEOUT;
  SerialClient = pserial(0);
}

LogoClient::LogoClient(pserial Interface)
{
	ConnType = PG;
	Connected = false;
	LastError = 0;
	PDULength = 0;
	RecvTimeout = TIMEOUT;
	SerialClient = Interface;
}

LogoClient::~LogoClient()
{
	Disconnect();
}

int LogoClient::SetLastError(int Error)
{
	LastError = Error;
	return Error;
}

int LogoClient::WaitForData(uint16_t Size, uint16_t Timeout)
{
	unsigned long Elapsed = millis();
	uint16_t BytesReady;

	do
	{
		BytesReady = SerialClient->available();
		if (BytesReady < Size)
			delayMicroseconds(500);
		else
			return SetLastError(0);

		// Check for rollover - should happen every 52 days without turning off Arduino.
		if (millis() < Elapsed)
			Elapsed = millis(); // Resets the counter, in the worst case we will wait some additional millisecs.

	} while (millis()-Elapsed < Timeout);	

	// Here we are in timeout zone, if there's something into the buffer, it must be discarded.
	if (BytesReady > 0) 
	{
		// Clearing serial incomming buffer
    while (BytesReady-- > 0) (Serial.read());
	}

	return SetLastError(errStreamDataRecvTout);
}

int LogoClient::RecvPacket(uint8_t *buf, uint16_t Size)
{
	WaitForData(Size, RecvTimeout);
	if (LastError != 0)
		return LastError;
	if (SerialClient->readBytes(buf, Size) != Size)
		return SetLastError(errStreamConnectionReset);
	return SetLastError(0);
}

void LogoClient::SetConnectionParams(pserial Interface)
{
	SerialClient = Interface;
}

void LogoClient::SetConnectionType(uint16_t ConnectionType)
{
	ConnType = ConnectionType;
}

int LogoClient::ConnectTo(pserial Interface)
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
			PGConnect();
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
    SerialClient->end();
		Connected = false;
		PDULength = 0;
		LastError = 0;
	}	
}

int LogoClient::SerialConnect()
{
  if (SerialClient)
  {
    SerialClient->begin(BAUDRATE);
		return SetLastError(0);
  }
	else
		return SetLastError(errStreamConnectionFailed);
}

int LogoClient::LogoConnect()
{
	if (SerialClient->write(&LOGO_CR[0], sizeof(LOGO_CR)) == sizeof(LOGO_CR))
	{
		RecvPacket(PDU.H, 5);
		if (LastError == 0)
		{
      LastPDUType = PDU.H[0];   // Store PDU Type
			if (LastPDUType == CC)    // Connection confirm
				return 0;
			else
				return SetLastError(errPGInvalidPDU);
		}
		else
			return LastError;
	}
	else
		return SetLastError(errPGConnectionFailed);
}

int LogoClient::RecvIOPacket(uint16_t *Size)
{
  bool Done = false;
  LastError = 0;

  // TBD
  while ((LastError == 0) && !Done)
  {
    // Get 1 byte
    RecvPacket(PDU.H, 1); 
    if (LastError == 0)
    {
      *Size = GetPDULength();
      if ((*Size > MaxPduSize) || (*Size < MinPduSize))
        LastError = errPGInvalidPDU;
      else
        Done = true; // a valid Length != 1 && >0BA3 && <0BA7
      }
    }
  }
  if (LastError == 0)
  {
    LastPDUType = PDU.H[0]; // Stores PDU Type, we need it 
    *Size -= Size_WR;
    // We need to align with PDU.DATA
    RecvPacket(Target, *Size);
  }
  return LastError;
}

