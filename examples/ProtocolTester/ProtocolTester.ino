#ifdef ARDUINO_AVR_UNO
  #if ARDUINO != 10805
    #error Arduino 1.8.5 required.
  #endif
  #include <CustomSoftwareSerial.h>
#endif

#define BUFFER_SIZE    80

char receivedChars[BUFFER_SIZE*2]; // an array to store the received data
boolean newData = false;
byte message[BUFFER_SIZE];  // an array to store the message data

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

void setup() {
  // initialize digital pin LED_BUILTIN as an output and turn the LED off
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);   
  
  // Init Monitor interface
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.println("Monitor is ready.");

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
      if (ndx >= sizeof(receivedChars)) {
        ndx = sizeof(receivedChars) - 1;
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

  delay(10);
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
    sprintf(tmp, "%.2X", data[i]);
    Serial.print(tmp); Serial.print(" ");
  }
}
