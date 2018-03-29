#include <CustomSoftwareSerial.h>
#include "LogoPG.h"

const byte rxPin = 2;
const byte txPin = 3;

// set up the SoftwareSerial object
CustomSoftwareSerial LogoSerial(rxPin, txPin);
// set up the LogoClient object
LogoClient LOGO(&LogoSerial);

void setup() {
  // initialize digital pin LED_BUILTIN as an output and turn the LED off
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // Init Monitor interface
  Serial.begin(9600);
  while (!Serial) ; // Needed for Leonardo only

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
    if (Info.sch_rel > 0)
    {
      Serial.print("CPU protection level:");
      Serial.print(" sch_schal=");
      Serial.print(Info.sch_schal);
      Serial.print(", sch_par=");
      Serial.print(Info.sch_par);
      Serial.print(", sch_rel=");
      Serial.print(Info.sch_rel);
      Serial.print(", bart_sch=");
      Serial.println(Info.sch_rel);
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
  if (ErrNo & 0x00FF)
  {
    // turn the built-in LED off
    digitalWrite(LED_BUILTIN, LOW);
    Serial.println("LOGO ERROR, disconnecting.");
    LOGO.Disconnect(); 
  }
}

