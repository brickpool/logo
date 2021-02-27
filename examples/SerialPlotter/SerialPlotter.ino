#ifdef ARDUINO_AVR_UNO
  #if ARDUINO != 10805
    #error Arduino 1.8.5 required.
  #endif
  #include <CustomSoftwareSerial.h>
#endif
#include <ArduinoLog.h>
#include "LogoPG.h"

unsigned long cycleTime;
const unsigned long cycleDelay = 500; // min > 200ms, max < 600ms

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
  // Leonado board Serial1:
  //      rxPin       0
  //      txPin       1
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
  Log.setPrefix(printTimestamp);

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

  cycleTime = millis();
}

void loop() 
{
  // Connection
  while (!LOGO.Connected)
  {
    if (Connect())
    {
      int Status;
      int Result = LOGO.GetPlcStatus(&Status);
      if (Result == 0)
      {
        if (Status != LogoCpuStatusRun)
        {
          Log.notice(F("STARTING THE PROG" CR));
          LOGO.PlcStart(); 
        }
      }
      else
        CheckError(Result);
    }
    else
      delay(2000);
  }

  // Polling Data
  if (millis()-cycleTime > cycleDelay)
  {
    cycleTime = millis();
    int Result = LOGO.ReadArea(LogoAreaDB, 1, VM_I01_08, 990-923, NULL);
    Log.notice(F("POLL DATA ... " CR));
    if (Result == 0)
    {
#if ARDUINO >= 10810
      // https://diyrobocars.com/2020/05/04/arduino-serial-plotter-the-missing-manual/
      Serial.print("Min:0,");

      Serial.print("I1:");
      Serial.print(LH.BitAt(VM_I01_08, 0) ? 50  : 10);
      Serial.print(",");
      Serial.print("I2:");
      Serial.print(LH.BitAt(VM_I01_08, 1) ? 100 : 60);
      Serial.print(",");
      Serial.print("I3:");
      Serial.print(LH.BitAt(VM_I01_08, 2) ? 150 : 110);
      Serial.print(",");
      Serial.print("I4:");
      Serial.print(LH.BitAt(VM_I01_08, 3) ? 200 : 160);
      Serial.print(",");
      Serial.print("I5:");
      Serial.print(LH.BitAt(VM_I01_08, 4) ? 250 : 210);
      Serial.print(",");
      Serial.print("I6:");
      Serial.print(LH.BitAt(VM_I01_08, 5) ? 300 : 260);
      Serial.print(",");

      Serial.print("AI1:");
      Serial.print(LH.IntegerAt(VM_AI1_Hi));
      Serial.print(",");
      Serial.print("AI2:");
      Serial.print(LH.IntegerAt(VM_AI2_Hi));
      Serial.print(",");

      Serial.print("Q1:");
      Serial.print(LH.BitAt(VM_Q01_08, 0) ? 750 : 710);
      Serial.print(",");
      Serial.print("Q2:");
      Serial.print(LH.BitAt(VM_Q01_08, 1) ? 800 : 760);
      Serial.print(",");
      Serial.print("Q3:");
      Serial.print(LH.BitAt(VM_Q01_08, 2) ? 850 : 810);
      Serial.print(",");
      Serial.print("Q4:");
      Serial.print(LH.BitAt(VM_Q01_08, 3) ? 900 : 860);
      Serial.print(",");

      Serial.println("Max:1023");
#else
      Log.notice(F("Analog input 1:"));
      Serial.print(LH.IntegerAt(VM_AI1_Hi));
#endif
    }
    else
      CheckError(Result);
  }
}

bool Connect()
{
  int Result = LOGO.Connect();
  Log.notice(F("Try to connect with LOGO" CR));
  if (Result == 0) 
  {
    Log.notice(F("Connected!" CR));
    Log.notice(F("PDU Length = %d" CR), LOGO.GetPDULength());
  }
  else
  {
    Log.error(F("Connection error!" CR));
  }
  return Result == 0;
}

void CheckError(int ErrNo)
{
  Log.error(F("Error No. %d" CR), ErrNo);
  
  // Checks if it's a LOGO Error => we need to disconnect
  if (ErrNo & 0x01FF)
  {
    Log.error(F("LOGO ERROR, disconnecting." CR));
    LOGO.Disconnect(); 
  }
}

void printTimestamp(Print* _logOutput) {
  char c[12];
  int m = sprintf(c, "%10lu ", millis());
  _logOutput->print(c);
}
