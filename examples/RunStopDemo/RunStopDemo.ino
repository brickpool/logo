#include <CustomSoftwareSerial.h>
#include "LogoPG.h"

const byte rxPin = 2;
const byte txPin = 3;

// set up the SoftwareSerial object
CustomSoftwareSerial LogoSerial(rxPin, txPin);
// set up the LogoClient object
LogoClient LOGO(&LogoSerial);

void setup() {
  // Init Monitor interface
  Serial.begin(9600);
  while (!Serial) {
   ; // wait for serial port to connect. Needed for native USB port only
  }

  // Start the SoftwareSerial Library
  LogoSerial.begin(9600, CSERIAL_8E1);
  // Setup Time, 1s.
  delay(1000); 
  Serial.println("");
  Serial.println("Cable connected");  
  if (LogoSerial.isListening())
    Serial.println("Softserial is listening !");
}

void loop() 
{
  int Result, Status;
  
  // Connection
  while (!LOGO.Connected)
  {
    if (!Connect())
      delay(2000);
  }
  
  Result = LOGO.GetPlcStatus(&Status);
  if (Result == 0)
  {
    if (Status == LogoCpuStatusRun)
    {
      Serial.println("STOPPING THE PROG");
      LOGO.PlcStop();
    }
    else
    {
      Serial.println("STARTING THE PROG");
      LOGO.PlcStart(); 
    }
  }
  else
    CheckError(Result);

  delay(3000);  
}

bool Connect()
{
  int Result = LOGO.Connect();
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
  return Result == 0;
}

void CheckError(int ErrNo)
{
  Serial.print("Error No. 0x");
  Serial.println(ErrNo, HEX);
  
  // Checks if it's a LOGO Error => we need to disconnect
  if (ErrNo & 0x00FF)
  {
    Serial.println("LOGO ERROR, disconnecting.");
    LOGO.Disconnect(); 
  }
}

