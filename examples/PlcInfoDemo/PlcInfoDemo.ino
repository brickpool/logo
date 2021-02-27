#ifdef ARDUINO_AVR_UNO
  #include <CustomSoftwareSerial.h>
#endif
#include "LogoPG.h"

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
  // initialize digital pin LED_BUILTIN as an output and turn the LED off
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // Init Monitor interface
  Serial.begin(9600);
  while (!Serial) {
   ; // wait for serial port to connect. Needed for native USB port only
  }

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
  int Result;
  
  // Connection
  while (!LOGO.Connected)
  {
    if (!Connect())
      delay(2000);
  }

  // System info functions
  TProtection Info;
  Result = LOGO.GetProtection(&Info);
  if (Result == 0)
  {
    if (Info.bart_sch > 0)
    {
      Serial.print("CPU protection level:");
      Serial.print(" sch_schal=");
      Serial.print(Info.sch_schal);
      Serial.print(", sch_par=");
      Serial.print(Info.sch_par);
      Serial.print(", sch_rel=");
      Serial.print(Info.sch_rel);
      Serial.print(", bart_sch=");
      Serial.println(Info.bart_sch);
      // 'anl_sch' is always 0
    }
  }
  else
    CheckError(Result);

  // Security functions
  TOrderCode OrderCode;
  Result = LOGO.GetOrderCode(&OrderCode);
  if (Result == 0)
  {
    Serial.print("Order code: ");
    Serial.println(OrderCode.Code);
    // print firmware version, if the values are valid
    if (OrderCode.V1 > 0 && OrderCode.V2 > 0 && OrderCode.V3 > 0)
    {
      char Version[] = "V0.00.00";
      sprintf(Version, "V%d.%02d.%02d", 
        OrderCode.V1, 
        OrderCode.V2, 
        OrderCode.V3
      );
      Serial.print("Firmware version: ");
      Serial.println(Version);
    }
  }
  else
    CheckError(Result);

  delay(10000);
}

bool Connect()
{
  int Result = LOGO.Connect();
  Serial.println("Try to connect with LOGO");
  if (Result == 0) 
  {
    // turn the built-in LED on
    digitalWrite(LED_BUILTIN, HIGH);
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
    // turn the built-in LED off
    digitalWrite(LED_BUILTIN, LOW);
    Serial.println("LOGO ERROR, disconnecting.");
    LOGO.Disconnect(); 
  }
}
