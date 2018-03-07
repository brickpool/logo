#include <CustomSoftwareSerial.h>
#include <TimeLib.h>
#include "LogoPG.h"

const byte rxPin = 2;
const byte txPin = 3;

const unsigned long START_TIME = 1357041600; // Jan 1 2013

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
  int Result, Status;
  TimeElements DateTime;
  
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
      Serial.print("DEFAULT: ");
      Result = LOGO.SetPlcDateTime(START_TIME);
      breakTime(START_TIME, DateTime);
    }
    else
    {
      Serial.print("LOGO Clock: ");
      Result = LOGO.GetPlcDateTime(&DateTime);
    }
    if (Result == 0)
    {
      DisplayClock(DateTime);
      Serial.println();
    }
    else
    {
      Serial.println("unknown");
      CheckError(Result);
    }
  }
  else
    CheckError(Result);

  delay(5000);  
}

void DisplayClock(TimeElements DateTime)
{
  const char* dayOfWeek[] = {  "??", "So", "Mo", "Tu", "We", "Th", "Fr", "Sa" };

  Serial.print(dayOfWeek[DateTime.Wday % 8]);
  Serial.print(" ");
  Serial.print(DateTime.Hour);
  Serial.print(":");
  if (DateTime.Minute < 10) Serial.print('0');
  Serial.print(DateTime.Minute);
  Serial.print(" ");
  Serial.print(tmYearToCalendar(DateTime.Year));
  Serial.print("-");
  if (DateTime.Month < 10) Serial.print('0');
  Serial.print(DateTime.Month);
  Serial.print("-");
  if (DateTime.Day < 10) Serial.print('0');
  Serial.print(DateTime.Day);
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
