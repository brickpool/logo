#ifdef ARDUINO_AVR_UNO
  #if ARDUINO != 10805
    #error Arduino 1.8.5 required.
  #endif
  #include <CustomSoftwareSerial.h>
#endif
#include <ArduinoLog.h>
#include "LogoPG.h"

unsigned long cycleTime;
const unsigned long cycleDelay = 500; // min > 200ms

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
  // Serial1:
  //      rxPin       18
  //      txPin       19
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

  // Start the SoftwareSerial Library
  LogoSerial.begin(9600, SERIAL_8E1);
  // Setup Time, 1s.
  delay(1000); 
  Serial.println("");
  Serial.println("Cable connected");  
#ifdef CustomSoftwareSerial_h
  if (LogoSerial.isListening())
#else
  if (LogoSerial)
#endif
    Serial.println("LogoSerial is ready.");

  cycleTime = millis();
  // LOG_LEVEL_SILENT, LOG_LEVEL_FATAL, LOG_LEVEL_ERROR, LOG_LEVEL_WARNING, LOG_LEVEL_NOTICE, LOG_LEVEL_TRACE, LOG_LEVEL_VERBOSE
  // Note: if you want to fully remove all logging code, uncomment #define DISABLE_LOGGING in Logging.h
  //       this will significantly reduce your project size
  Log.begin(LOG_LEVEL_VERBOSE, &Serial);
  Log.setPrefix(printTimestamp);
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
          Serial.println("STARTING THE PROG");
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
    Serial.print("POLL DATA ... ");
    if (Result == 0)
    {
      Serial.print("Output 8-1, 16-9, analog input 1:");
      Serial.print(" 0b");
      printBinaryByte(LH.ByteAt(VM_Q01_08));
      Serial.print(" 0b");
      printBinaryByte(LH.ByteAt(VM_Q09_16));
      Serial.print(" ");
      Serial.print(LH.IntegerAt(VM_AI1_Hi));
      Serial.println();
    }
    else
      CheckError(Result);
  }
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

// http://forum.arduino.cc/index.php?topic=246920.0
void printBinaryByte(byte value)
{
  for (byte mask = 0x80; mask; mask >>= 1) 
  {
    Serial.print((mask & value) ? '1' : '0');
  }
}

void printTimestamp(Print* _logOutput) {
  char c[12];
  int m = sprintf(c, "%10lu ", millis());
  _logOutput->print(c);
}
