#include <CustomSoftwareSerial.h>

#define BUFFER_SIZE    80

char receivedChars[BUFFER_SIZE*2]; // an array to store the received data
boolean newData = false;
byte message[BUFFER_SIZE];  // an array to store the message data

const byte rxPin = 2;
const byte txPin = 3;

// set up the SoftwareSerial object
CustomSoftwareSerial LogoSerial(rxPin, txPin);

void setup() {
  // Init Monitor interface
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.println("Monitor is ready.");

  // Init CustomSoftwareSerial
  LogoSerial.begin(9600, CSERIAL_8E1);
  // Setup Time, 1s.
  delay(1000);
  if (LogoSerial.isListening())
    Serial.println("SoftSerial is listening.");
}

void loop()
{
  // http://forum.arduino.cc/index.php?topic=288234.0
  // recv from monitor
  static byte ndx = 0;
  static byte cnt = 0;
  const char endMarker = '\n';
  const char delimiter = ' ';
  char rc;

  while (Serial.available() > 0 && newData == false)
  {
    rc = Serial.read();

    if (rc != endMarker) 
    {
      receivedChars[ndx] = rc;
      ndx++;
      if (ndx >= BUFFER_SIZE) {
        ndx = BUFFER_SIZE - 1;
      }
    }
    else 
    {
      receivedChars[ndx] = '\0'; // terminate the string
      ndx = 0;
      newData = true;
      cnt = parseBytes(receivedChars, delimiter, message, sizeof(message), 16);
    }
  }

  // send to PLC
  if (newData)
  {
    Serial.print("send> ");
    printHex(message, cnt);
    LogoSerial.write(message, cnt);
    Serial.println();

    newData = false;
  }
  
  // recv from PLC
  if (LogoSerial.available() > 0)
  {
    Serial.print("recv< ");
    cnt = 0;
    while (LogoSerial.available() > 0) 
    {
      message[cnt++] = LogoSerial.read();
      if (cnt >= sizeof(message))
        break;
    }
    printHex(message, cnt);
    Serial.println();
  }
}

// https://stackoverflow.com/questions/35227449/convert-ip-or-mac-address-from-string-to-byte-array-arduino-or-c
int parseBytes(const char* str, char sep, byte* bytes, int maxBytes, int base) 
{
  int i = 0;
  while (i < maxBytes) 
  {
    bytes[i++] = strtoul(str, NULL, base);  // Convert byte
    str = strchr(str, sep);               // Find next separator
    if (str == NULL || *str == '\0') 
      break;                              // No more separators, exit
    str++;                                // Point to next character after separator
  }
  return i;
}

// https://forum.arduino.cc/index.php?topic=38107.0
void printHex(byte *data, size_t length) // prints 8-bit data in hex with leading zeroes
{
  char tmp[16];
  for (int i = 0; i < length; i++) 
  {
    sprintf(tmp, "0x%.2X", data[i]);
    Serial.print(tmp); Serial.print(" ");
  }
}

