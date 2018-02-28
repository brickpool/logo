#include <CustomSoftwareSerial.h>
#include "LogoPG.h"

#define _MONITOR

const byte rxPin = 2;
const byte txPin = 3;

unsigned long checkTime;
const unsigned long checkDelay = 5000; // ms

unsigned long cycleTime;
const unsigned long cycleDelay = 500; // min > 200ms

// set up the SoftwareSerial object
CustomSoftwareSerial LogoSerial(rxPin, txPin);
// set up the LogoClient object
LogoClient LOGO(&LogoSerial);

void setup() {
  // Init Monitor interface
#ifdef _MONITOR
  Serial.begin(9600);
  while (!Serial) {
   ; // wait for serial port to connect. Needed for native USB port only
  }
#endif

  // Start the SoftwareSerial Library
  LogoSerial.begin(9600, CSERIAL_8E1);
  // Setup Time, 1s.
  delay(1000); 
#ifdef _MONITOR
  Serial.println("");
  Serial.println("Cable connected");  
  if (LogoSerial.isListening())
    Serial.println("Softserial is listening !");
#endif

  checkTime = millis();
  cycleTime = millis();
}

void loop() 
{
  // Connection
  while (!LOGO.Connected)
  {
    if (!Connect())
      delay(2000);
  }

  // Operation Mode
  if (millis()-checkTime > checkDelay)
  {
    checkTime = millis();
    int Status;
    int Result = LOGO.GetPlcStatus(&Status);
    if (Result == 0)
    {
      if (Status != LogoCpuStatusRun)
      {
#ifdef _MONITOR
        Serial.println("STARTING THE PROG");
#endif
        LOGO.PlcStart(); 
      }
    }
    else
      CheckError(Result);
  }

  if (millis()-cycleTime > cycleDelay)
  {
    cycleTime = millis();
#ifdef _MONITOR
    Serial.print(cycleTime);
    Serial.print("ms ");
    Serial.print("FETCH DATA ... ");
#endif
    int Result = LOGO.ReadArea(LogoAreaDB, 1, VM_I01_08, 990-923, NULL);
    if (Result == 0)
    {
#ifdef _MONITOR
      Serial.print("Output 8-1, 16-9, analog input 1: 0b");
      printBinaryByte(LH.ByteAt(VM_Q01_08));
      Serial.print(" 0b");
      printBinaryByte(LH.ByteAt(VM_Q09_16));
      Serial.print(" ");
      Serial.print(LH.IntegerAt(VM_AI1_Hi));
      Serial.println();
#endif
    }
    else
      CheckError(Result);
  }
}

bool Connect()
{
  int Result = LOGO.Connect();
#ifdef _MONITOR
  Serial.println("Try to connect with LOGO");
  if (Result == 0) 
  {
    Serial.println("Connected!");
    Serial.print("PDU Length = ");
    Serial.println(LOGO.GetPDULength());
  }
  else
  {
    Serial.println("Connection error!");
  }
#endif
  return Result == 0;
}

void CheckError(int ErrNo)
{
#ifdef _MONITOR
  Serial.print("Error No. 0x");
  Serial.println(ErrNo, HEX);
#endif
  
  // Checks if it's a LOGO Error => we need to disconnect
  if (ErrNo & 0x00FF)
  {
#ifdef _MONITOR
    Serial.println("LOGO ERROR, disconnecting.");
#endif
    LOGO.Disconnect(); 
  }
}

// http://forum.arduino.cc/index.php?topic=246920.0
void printBinaryByte(byte value)
{
  for (byte mask = 0x80; mask; mask >>= 1) 
  {
    Serial.print((mask & value) ? '1' : '0');
  }
}
