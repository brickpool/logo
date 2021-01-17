#ifdef ARDUINO_AVR_UNO
  #if ARDUINO != 10805
    #error Arduino 1.8.5 required.
  #endif
  #include <CustomSoftwareSerial.h>
#endif
#include <ArduinoLog.h>
#include "LogoPG.h"

byte buf[2];

// set up the LogoSerial object
#ifdef CustomSoftwareSerial_h
  #if defined(SERIAL_8E1)
    #undef  SERIAL_8E1
  #endif
  #define SERIAL_8E1  CSERIAL_8E1
  #define rxPin       2
  #define txPin       3
  CustomSoftwareSerial LogoSerial(rxPin, txPin);
#else
  // Mega board Serial1:
  //      rxPin       19
  //      txPin       18
  // MKR board Serial1:
  //      rxPin       13
  //      txPin       14
  #define LogoSerial  Serial1
#endif

// set up the LogoClient object
LogoClient LOGO(&LogoSerial);

void setup() {
  // Init Monitor interface
  Serial.begin(9600);
  while (!Serial) {
   ; // wait for serial port to connect. Needed for native USB port only
  }

  // LOG_LEVEL_SILENT, LOG_LEVEL_FATAL, LOG_LEVEL_ERROR, LOG_LEVEL_WARNING, LOG_LEVEL_NOTICE, LOG_LEVEL_TRACE, LOG_LEVEL_VERBOSE
  // Note: set to LOG_LEVEL_SILENT if you want to use the serial plotter. This will stop the serial logging
  Log.begin(LOG_LEVEL_SILENT, &Serial);

  // Start the LOGO Serial interface
  LogoSerial.begin(9600, SERIAL_8E1);
  // Setup Time, 1s.
  delay(1000); 
#ifdef CustomSoftwareSerial_h
  if (LogoSerial.isListening())
#else
  if (LogoSerial)
#endif
    Serial.println("LogoSerial is ready.");
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
      Serial.print("FETCH DATA ... ");
      // read first analog input
      Result = LOGO.ReadArea(LogoAreaDB, 1, AI_0BA7, sizeof(buf), buf);
      if (Result == 0)
      {
        Serial.print("OK: ");
        Serial.println(LH.WordAt(buf, 0));
      }
      else
        CheckError(Result);
    }
    else
    {
      Serial.println("STARTING THE PROG");
      LOGO.PlcStart(); 
    }
  }
  else
    CheckError(Result);

  delay(2000);  
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
  if (ErrNo & 0x01FF)
  {
    Serial.println("LOGO ERROR, disconnecting.");
    LOGO.Disconnect(); 
  }
}
