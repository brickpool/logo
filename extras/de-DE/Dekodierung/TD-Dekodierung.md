# LOGO! TD Protokoll Referenz Handbuch

Ausgabe Ac

Juni 2018

## Vorwort
Dieses Handbuch richtet sich an Personen, die mit einem Siemens (TM) _LOGO!_ __0BA6__ �ber die TD-Schnittstelle kommunizieren. Die TD-Schnittstelle verwendete ein _PROFIBUS_ Anwendungs-Protokoll zur Bedienung und Anzeige am _TD_, welches hier als TD-Protokoll bezeichnet wird. In diesem Handbuch wird beschrieben, wie Nachrichten erstellt werden und wie Transaktionen mithilfe des TD-Protokolls ausgef�hrt werden.

_Siemens_ und _LOGO!_ sind eingetragene Marken der __Siemens AG__.

_PROFIBUS_ ist eine eingetragene Handelsmarke des __PROFIBUS Nutzerorganisation e.V__.

## Verwendete oder weiterf�hrende Publikationen

Wertvolle Informationen zum _PROFIBUS_ finden Sie in den folgenden Ver�ffentlichungen:
  * [PROFIBUS Nutzerorganisation e.V. (PNO)](http://de.profibus.com/)
  * [PROFIBUS feldbusse.de](http://www.feldbusse.de/Profibus/profibus.shtml)
  * [PROFIBUS Wikipedia](http://de.wikipedia.org/wiki/Profibus)

Informationen zu RS485 und deren Anschaltung an ein Mcrocontroller finden Sie in den folgenden Ver�ffentlichungen:
  * [MAX485 RS-485 Modul](http://github.com/brickpool/Grove/blob/master/Communication/RS485/MAX485_RS-485_Module.md)
  * [An Arduino and RS485](http://pskillenrules.blogspot.com/2009/08/arduino-and-rs485.html)

## Inhalt

  * [Kapitel 1 - TD-Schnittstelle](#Kapitel1)
    * [PROFIBUS](#profibus)
    * [RS-485](#rs485)
    * [Fieldbus Data Link (FDL)](#fdl)
  * [Kapitel 2 - TD-Protokoll](#Kapitel2)
    * [Direkt Data Link Mapper (DDLM)](#ddlm)
    * [Anwendungsprotokoll (ALI)](#ali)
  * [Anhang](#anhang)
    * [Pr�fsumme](#fcs)
    * [RS485-TTL-Anschaltung](#ttl)

----------

# <a name="Kapitel1"></a>Kapitel 1 - TD-Schnittstelle
Bei der _TD_-Schnittstelle (TD = Text Display) handelt es sich um eine Anwendung, die auf dem industriellen _PROFIBUS-DP_ Feldbusstandard aufsetzt. Der Feldbus verbindet die Feldebene (hier _TD_) mit den prozessnahen Komponenten (hier _LOGO!_ Kleinsteuerung), wobei diese Variante speziell f�r die Kommunikation zwischen _TD_ und den _LOGO!_ ausgelegt ist, um einen vereinfachten Einsatz erm�glichen.

## <a name="profibus"></a>PROFIBUS
_PROFIBUS_ (PROcess FIeld BUS) ist ein Standard f�r die Feldbus-Kommunikation in der Automatisierungstechnik. Es handelt sich eine vollst�ndige und erprobte Technologie, welche sich bereits bew�hrt hat und daher zur Anbindung des _TD_ mittels der Variante PROFIBUS-DP (DP = Dezentrale Peripherie) genutzt wird: 
```
.------------------.-----------------.-----------------.
| PROFIBUS-FMS     | PROFIBUS-DP     | PROFIBUS-PA     |
+------------------+-----------------+-----------------+
| Profile f�r      | Profile f�r     | Profile f�r     |
| Fertigungs-      | Fertigungs-     | Prozess-        |
| automatisierung  | automatisierung | automatisierung |
|..................'.................'.................|
|          Application Layer Interface (ALI)           |
|......................................................|
| Schicht 7: (FMS) | Schicht 7: (DDLM)                 |
| Fieldbus Message | Direct Data Layer Mapper          |
| Spefification    |                                   |
+------------------'-----------------------------------+
|               Schicht 3 bis 6: leer                  |
+------------------------------------------------------+
|        Schicht 2: (FDL) Fieldbus Data Link           |
+------------------------------------.-----------------+
| Schicht 1: EN 50 170 (RS485)       | IEC 1158-2      |
'------------------------------------'-----------------'
```
>Abb: Varianten vom PROFIBUS

_PROFIBUS_ wurde Ende der 80er Jahre entwickelt und anschlie�end als Deutsche Norm DIN 19 245 und als europ�ische Norm EN 50 170 standardistert. Ziel war es die v�llige Unabh�ngigkeit des Anwenderprogrammes von der Realisierung der Daten�bertragung �ber den Bus. Das Anwenderprogramm benutzt das Kommunikationssystem mit Hilfe sogenannter Dienste (z.B. "send and request data with reply" mit den Dienstprimitiven _request_, _indication_, _response_ und _confirmation_).

Das Kommunikationssystem ist nach dem sogenannten ISO/OSI Schichtenmodell (Standard ISO 7498, Open System Interconnection) aufgebaut. Wobei die Schichten 3 bis 6 nicht realisiert sind.

_PROFIBUS_ unterscheidet folgende Ger�tetypen:
- Master-Ger�te: Ein Master darf Nachrichten ohne externe Aufforderung aussenden
- Slave-Ger�te: Sie d�rfen nur empfangene Nachrichten quittieren oder auf Anfrage eines Masters Nachrichten an diesen �bermitteln. 

Um ein _TD_ an ein _LOGO!_ anzuschlie�en und dar�ber Daten auszutauschen, ist es nicht unbedingt erforderlich, dass der _PROFIBUS_ und der Feldbus vollst�ndig verstanden wird. Da nur eine Kommunikation mit dem _LOGO!_ geplant ist, ist dies eine sehr einfaches Variante, denn die _TD_-Schnittstelle soll kein vollst�ndiges PROFIBUS-Netzwerk darstellen. 

## <a name="rs485"></a>RS-485
Die Protokollarchitektur von _PROFIBUS_ orientiert sich am _ISO/OSI_ Referenz Modell. In diesem Modell �bernimmt jeder Layer genau definierte Aufgaben. Layer 1 (Physical Layer) definiert die physikalische �bertragungstechnik. Der Einsatzbereich eines Feldbus-Systems wird wesentlich durch die Wahl des �bertragungs-Mediums und der physikalischen Busschnittstelle bestimmt.

Bei der _TD_-Schnittstelle handelt es sich um ein kabelgebundene _PROFIBUS-DP_ Variante. Die Anschaltung auf Layer 1 folgt dem Standard TIA/EIA-485. Die Daten�bertragung erfolgt �ber ein abgeschirmtes, verdrilltes Leiterpaar. RS-485 gilt als sehr st�rfest, erm�glicht �bertragungsraten bis 12 MBaud und ist ein wichtiger Standard in industriellen Feldbus-Anwendungen und ist daher auch beim _PROFIBUS-DP_ als Grundversion f�r Anwendungen im Bereich der Fertigungstechnik, Geb�udeleittechnik und Antriebstechnik festgelegt.

Wie beim _PROFIBUS_, der auf der TIA/EIA-485-Norm basiert, werden die Pins 3 und 8 von 9-poligen D-Sub-Stecker f�r die Datenleitung benutzt. Durch die galvanische Trennung im _TD_-Kabel (mittels Optokoppler) wurde das Mitf�hren der Masseleitung (Pin 5) und einer positiven Spannung (von 3,3V an Pin 1) notwendig. Die Spannungsversorgung vom _TD_  mit 3,3V und die inkompatbible Pin-Belegung zum _PROFIBUS_ (5V an Pin 6) macht eine Anschaltung des _TD_ an einem _PROFIBUS_-Netzwerk nicht m�glich.  

Bei einem _PROFIBUS_ k�nnen Bitraten von 9600 Baud bis 12 MBaud projektiert werden. Die Baudrate bei der _TD_-Schnittslle ist auf 19.200 Baud festgelegt. Bei einer �bertragungsrate von 19.200 Baud ist eine theoretische Reichweite von bis zu 1200m m�glich. Das eingesetzte _TD_-Kabel weicht jedoch beim Aderdurchmesser, -querschnitt, Wellenwiderstand und Kapazit�tsbelag ab. Zudem erfolgt die Spannungsversorgung der Optokoppler im _TD_-Kabel vom _TD_ mit (nur) 3,3V. Daher sind in der Paxis ohne geeignete Anpassungen nur L�ngen bis ca. 20m m�glich. 

Das eingesetzte �bertragungsverfahren ist halbduplex, asynchron und zeichenorientiert. Die Daten werden innerhalb eines 11 Bit-Zeichenrahmens im NRZ-Code (Non Return to Zero) �bertragen, beginnend mit einem Starbit, das logisch Null ist. Die Zeichn�bertragung endet mit einem Stoppbit, das immer eine logische Eins enth�lt. Auf das Startbit folgt die zu �bertragenden Information als Datenbits. Nach den Datenbits und vor dem Stopbit wird ein Parit�tsbit gesendet. Die Zahl der Datenbits betr�gt bei der _TD_-Schnittstelle 8 Bit, wobei das niederwertigste Bit (LSB) immer direkt nach dem Startbit und das h�chstwertige Bit (MSB) als letztes Datenbit gesendet wird. Die Daten�bertragung bedient sich des Zeichenvorrates von `00` bis `FF`. Es werden nicht einzelne Zeichen, sondern Telegramme, bestehend aus Zeichenketten, �bertragen (siehe [Schicht 2](#schicht2)).

```
|<-- �bertragungsrahmen ------------------------------------->|
.----.-----.-----.-----.-----.-----.-----.-----.-----.---.----.
| ST | 2^0 | 2^1 | 2^2 | 2^3 | 2^4 | 2^5 | 2^6 | 2^7 | P | SP |
'----'-----'-----'-----'-----'-----'-----'-----'-----'---'----'
     : LSB                                       MSB :
     |<-- Informations-Byte ------------------------>|
```
>Abb: Informations-Byte im 11 Bit-�bertragungsrahmen von Schicht 1

Bedeutung der Abk�rzungen: 
- ST: Startbit (immer logisch `0`)
- 2^0 bis 2^7: Informations-Byte
- P: Parit�tsbit
- SP: Stoppbit (immer logisch `1`)

Zusammgefasst lautet die Spezifikation f�r die Kommunikation �ber die TD-Schnittstelle:

### Kabel / Stecker:
- 4-adrig
- TD; SUB-D 9-pol Buchse; m�nlich (m)
- LOGO! propit�rer 6-pol Stecker; weiblich (f)

### Belegung _LOGO!_ 6 pol:
- [x] GND Masse; Pin 1
- [x] VCC Spannungsversorgung; Pin 2
- [ ] Pin 3
- [ ] Pin 4
- [x] Rx Datenempfang; Pin 5
- [x] Tx Daten�bermittlung; Pin 6

### Belegung _TD_ SUB-D 9 pol:
- [x] VCC Spannungsversorgung 3,3V; Pin 1; sw
- [ ] Pin 2
- [x] Bus B; Pin 3; rt
- [ ] Pin 4
- [x] GND Masse; Pin 5; bn
- [ ] Pin 6
- [ ] Pin 7
- [x] Bus A; Pin 8; or
- [ ] Pin 9

### Baud rate / Bits per byte:
- 19200 Baud
- 1 Start bit
- 8 Databits, LSB zuerst
- 1 bit f�r gerade P�rit�t (E)
- 1 Stop bit

### Kodierung:
- 8-bit binary, hexadecimal 0-9, A-F

## <a name="fdl"></a>Fieldbus Data Link (FDL)
_PROFIBUS_ verwendet ein einheitliches Buszugriffsprotokoll (Fieldbus Data Link = FDL). Es ist der Schicht 2 des OSI-Referenzmodells zugeordnet. Es beinhaltet auch die Funktionen der Datensicherung sowie die Abwicklung der �bertragungsprotokolle und der Telegramme. Die Buszugriffssteuerung (Medium Access Control = MAC) legt das Verfahren fest, zu welchem Zeitpunkt ein Busteilnehmer Daten senden kann. _PROFIBUS_ ber�cksichtigt hierbei zwei Buszugriffssteuerung:
- Token-Passing-Verfahren f�r die Kommunikation zwischen Automatisierungsger�ten (Master).
- Master-Slave-Verfahren f�r die Kommunikation zwischen einem Automatisierungsger�t (Master) und den Peripherieger�ten (Slaves) 

Im Folgenden betrachten wir nur das Master-Slave-Verfahren, da nur dieses an der _TD_-Schnittstelle angewandt wird. Der Master (_TD_) hat hierbei die M�glichkeit, Nachrichten an ein Slave (_LOGO!_) zu �bermitteln bzw. Nachrichten vom Slave abzuholen. 

Eine weitere Aufgabe des Buszugriffsprotokolls (FDL) ist die Datensicherung. Die Telegramme nutzen mehere Mechanismen um eine hohe Daten�bertragungssicherheit zu gew�hrleisten. Dies wird durch die Anwendung bzw. Auswahl von Start- und Endezeichen, Synchronisierung, Parit�tsbit und Kontrollbyte erreicht. 

### Telegramme
Ein PROFIBUS-Telegramm besteht aus dem Telegrammheader, den Nutzdaten, einem Sicherungsbyte und dem End-Delimiter (Ausnahme: Tokentelegramm)

Folgende Telegramme sind f�r das _PROFIBUS_-Buszugriffsprotokoll (FDL) definiert:
- SD1: Format mit fester Informationsfeldl�nge ohne Daten (L = 3) 
- SD2: Format mit variabler Informationsfeldl�nge (L = 4..249)
- SD3: Format mit fester Informationsfeldl�nge mit Daten (L = 11)
- SD4: Token-Telegramm
- SC: Kurzquittung

Telegramm | Code (hex) | Bezeichnung
--------- | ---------- | -------------------------------------
SD1       | `10`       | Start Delimiter _"keine Daten"_
SD2       | `68`       | Start Delimiter _"variable Datenl�nge"_
SD3       | `A2`       | Start Delimiter _"8 Bytes"_
SD4       | `DC`       | Start Delimiter _"Token"_
SC        | `E5`       | Single Character 
>Tabelle: �bersicht der Telegramme

Von den f�nf genannten Telegrammen, wird (nach aktuellem Kenntnisstand) f�r die Kommunikation vom _TD_ zum _LOGO!_ nur das _SD2_ Telegramm (Telegram mit variabler Datenl�nge) verwendet.

Folgend der Aufbau des _SD2_ Telegrams:
```
.-----.----.-----.-----.----.----.----.--- ~ ~ ---.-----.----.
| SD2 | LE | LEr | SD2 | DA | SA | FC | Datenfeld | FCS | ED |
'-----'----'-----'-----'----'----'----'--- ~ ~ ---'-----'----'
|<-- FDL --------------------------------------------------->|
```
>Abb: _SD2_ Telegramm von Schicht 2

Die L�nge des Datenfeldes betr�gt maximal 246 Bytes.

Bedeutung der Abk�rzungen: 
- SD2: Startbyte (Start Delimiter) _"variable Datenl�nge"_, Code `68`
- DA: Zieladressbyte (Destination Address )
- SA: Quelladressbyte Source Address 
- FC: Kontrollbyte (Frame Control) zur Festlegung des Telegramtyps (_Senden_, _Anfordern_, _Quitieren_, etc.)
- FCS: Sicherungsbyte (Frame Check Sequence)
- LE: L�ngenbyte (Length), Wert 4 bis 249
- LEr: Wiederholung (Length repeated) des L�ngenbytes zur Sicherung
- ED: Endebyte (End Delimiter), Code `16`

### Adressierung
Das PROFIBUS-Buszugriffsprotokoll arbeitet verbindungslos. Es erm�glicht neben der Punkt-zu-Punkt-Daten�bertragung auch Mehrpunkt�bertragung z.B. via Broadcast-Kommunikation. Der Adressbereich f�r _DA_ und _SA_ (Ident-Nummer bzw. Stationsadresse) ist von 0 bis 126. Die Adresse 127 steht f�r eine Multi- bzw. Broadcast-Adresse. Die _TD_-Schnitstelle nutzt die Broadcast-Kommunikation, obwohl physikalisch eine direkte Verbindung vorliegt. 

### Dienste der Schicht 2
Das PROFIBUS-Buszugriffsprotokoll (FDL) stellt den _PROFIBUS_-Anwendungsprotokollen folgende Dienste zur Verf�gung:
- SDN (Send Data with No Acknowledge)
- SDA (Send Data with Acknowledge)
- SRD (Send and Request Data with Reply)
- CSRD (Cyclic SRD)

Von den vier m�glichen Diensten werden von _PROFIBUS-DP_ nur die Dienste _SDN_ und _SRD_ genutzt. F�r die Kommunikation vom _TD_ zum _LOGO!_ wird ausschlie�lich der _SDN_ Dienst (`06`) verwendet. Hierbei sendet das _TD_ eine unquittierte Nachricht an die _LOGO!_ Kleinsteuerung.

----------

# <a name="Kapitel2"></a>Kapitel 2 - TD-Protokoll

## <a name="ddlm"></a>Direkt Data Link Mapper (DDLM)
Das H�chstwertiges Bit (MSB) in _DA_ oder _SA_ zeigt an, ob eine Adresserweiterung via Dienstzugangspunkt (Service Access Point = SAPs) im Datenfeld vorliegt. Die PROFIBUS-Dienstzugangspunkte (SAP) sind in den Bytes (vom Datenfeld) _DSAP_ oder _SSAP_ vermerkt. 

```
|<-- Schicht 2 ----------------------------------------------------- /~
                                           :
.-----.-- ~ ~ --.----------.----------.----.------------------------ /~
| SD2 |   ...   | DA       | SA       | FC | Datenfeld
+-----+-- ~ ~ --+-.--------+-.--------+----+-.-.------+-.-.------+-- /~
| 68h |   ...   |1: 0..125 |0: 0..127 | FC |0:0: DSAP |0:0: SSAP |
'-----'-- ~ ~ --'-'--------'-'--------'----'-'-'------'-'-'------'-- /~ 
                 |                         :| |
                 |                         :| '-- Typ Bit
                 '-- Extension Bit         :'---- Extension Bit
                                           :
                                           |<---- Schicht 7 -------- /~
```
>Abb: Adresserweiterung vom Buszugriffsprotokoll (Schicht 2 = _FDL_) mit Dienstzugangspunkten (Schicht 7 = _DDLM_)

Das _TD_ nutzt f�r _DA_ die Adresserweiterung, d.h. das _TD_-Protokoll nutzt ein Anwendungsprotokoll oberhalb vom _DDLM_ mit Dienstzugangspunkt (SAP). Die Dienste der Schicht 7 (DDLM) werden �ber die Adresserweiterung angezeigt und �ber Dienstzugangspunkte der Schicht 7 aufgerufen. 

### Dienste der Schicht 7
Im Gegensatz zum Standard verwendeten das _TD_ nicht die Dienstzugangspunkte inkl. zugeh�rigen Funktionen von _PROFIBUS-DP_ sondern nutzt einen eigenen _DDLM_-Dienst mit Ziel-Dienstzugangspunkt (DSAP) `06` und Quell-Dienstzugangspunkt (SSAP) `01`.

PROFIBUS-DP kennt die folgenden Ger�tetypen: 
- DP-Master Klasse 1 (DPM1): Steuerung 
- DP-Master Klasse 2 (DPM2): Bedienger�t, Konfigurationstool
- Slave 

Das _TD_ ist ein Bedienger�t und somit dem Ger�tetyp _DPM2_ zugeordnet. Die _LOGO!_ Kleinsteuerng ist der Slave. Folgend die Darstellung des Dienstumfanges vom _TD_:
```
.------.    .-------.     .------.
| DPM1 |    | Slave |     | DPM2 |
|      |    |       |     |      |
| n/a  |    | LOGO! |     |  TD  |
|      |    |       |     |      |
|      |    |     (06)---(01)    |
|      |    |       |     |      |
'------'    '-------'     '------'
```
>Abb: _TD DDLM_ Dienst (_DSAP_ 6 und _SSAP_ 1)


## <a name="ali"></a>TD-Anwendungsprotokoll (ALI)
Die vom _TD_ genutzten _DDLM_-Dienste versehen ihre Daten mit einem eigenen Schicht-7-Rahmen: dem _TD_-Anwendungsprotokoll. Da keine Objekte und keine Objektlisten im _DDML_ existieren, wird die Kennzeichnung der Daten in anderer Weise durchgef�hrt. Unter der Annahme das der Slave modular aufgebaut ist, wird das _TD_-Anwendungsprotokoll gebildet aus der Funktionskennung, der Modulnummer, einer Kennziffer zur Unterscheidung innerhalb des Moduls und der L�nge der zu �bertragenden Daten. 

```
|<-- FDL ----------------------------------------------------->|
.-----.----.-----.-----.----.----.----.-------------.-----.----.
| SD2 | LE | LEr | SD2 | DA | SA | FC |    DDLM     | FCS | ED |
'-----'----'-----'-----'----'----'----'-------------'-----'----'
                                     /               \
                                    /                 \
                                   .------.------.-----.
                                   | DSAP | SSAP | ALI |
                                   '------'------'-----'
                                   |<-- DDLM --------->|
```
>Abb: _DDLM_ eingebettet in Telegramm

Befehl:
```
send> 68 00 0A 00 0A 68 80 7F 06 06 01 01 00 02 09 11 29 16
```

Darstellungsformat:
```
68  [00 0A] [00 0A] 68  80 7F 06 06   01   [01 00 02 09 11] 29  16
SD2 [LE   ] [LEr  ] SD2 DA SA FC DSAP SSAP [DU            ] FCS ED

SD2: 0x68 = SD2; Daten variabler L�nge
LE: L�nge der Nettodaten, (inkl. DA, SA, FC, DSAP, SSAP)
LEr: Wiederholung der Nettodaten L�nge
DA: Destination Address = 80h = 1000.0000b
    Im jeweiligen Adressbyte werden nur die niederwertigsten 7Bit f�r die Stationsadresse verwendet.
        1  0  0  0  0  0  0  0
    MSB --|--+--+--*--+--+--+-- LSB
        b7 b6 b5 b4 b3 b2 b1 b0

        b7: Extension bit = 1; Adresserweiterung mit Dienstzugangspunkt (SAP Service Access Point)
        b6..b0: Adresse = 0
SA: Source Address = 7Fh = 127d = 0111.1111b
        0  1  1  1  1  1  1  1
    MSB --|--+--+--*--+--+--+-- LSB
        b7 b6 b5 b4 b3 b2 b1 b0

        b7: Extension bit = 0; keine Adresserweiterung
        b6..b0: 127d = Broadcast-Adresse
FC: Function Code = 6; SDN (Send Data with No Acknowledge) high
DSAP: Ziel-Dienstzugangspunkt; 6 = 0000.0110b
        0  0  0  0  0  1  1  0
    MSB --|--|--+--*--+--+--+-- LSB
        b7 b6 b5 b4 b3 b2 b1 b0

        b7: Extension bit = 0
        b6: Typ bit = 0; Region/Segment-Adresse
        b5..b0: Adresse = 6
SSAP: Quell-Dienstzugangspunkt; 1 = 0000.0001b
        0  0  0  0  0  0  0  1
    MSB --|--|--+--*--+--+--+-- LSB
        b7 b6 b5 b4 b3 b2 b1 b0

        b7: Extension bit = 0
        b6: Typ bit = 0
        b5..b0: Adresse = 1
DU: Protocol Data Unit; Nettodaten (max 246 Bytes)
FCS: Frame Check Sequence von DU; CheckSum8 Modulo 256
ED: End Delimiter = 16h
```

```
|<-- FDL ------------------------------------------------->|
            |<-- DDLM ------------------------->|
.-----.-----.------.------.---------------------.-----.----.
| SD2 | ... | DSAP | SSAP | ALI                 | FCS | ED |
'-----'-----'------'------'---------------------'-----'----'
                         /                       \
                        /                         \
                       .----.----.----.-----.------.
                       | 01 | 00 | BC | CMD | Data |
                       '----'----'----'-----'------'
                       |<-- TD-Protokoll --------->|
```
>Abb: _TD_-Anwendungsprotokoll eingebettet im Telegramm


### TD Funktionstasten

Darstellungsformat:
```
68 00 0A 00 0A 68 80 7F 06 06 01 [01 00 02 09  24] 3C 16
                                 [DU             ]
                                 [01 00 BC Cmd Fx]

BC: Byte Count = 2
Cmd: Set/Write = 09h
Fx: Funktionstaste 24h = 0010.0100b
        0  0  1  0  0  1  0  0
    MSB --+--+--+--*--+--+--+-- LSB
        b7 b6 b5 b4 b3 b2 b1 b0

        b7:
        b6:
        b5: F off = 1
        b4: F on = 1
        b3:
        b2..b0:
          100b = F4
          011b = F3
          010b = F2
          001b = F1
```

Beispiel F4 off:
```
68 00 0A 00 0A 68 // SD2; DU L�nge = 10 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01      // 
00      // 
02      // Byte Count = 2
09      // Command 09h (set/write)
24      // 24h = 0010.0100b: b5=1 -> off, 4 -> F4
3C      // CheckSum8 Modulo 256 (DU: 80..24)
16      // End Delimiter
```

Beispiel F4 on:
```
68 00 0A 00 0A 68 // SD2; DU L�nge = 10 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01      // 
00      // 
02      // Byte Count = 2
09      // Command 09h (set/write)
13      // 13h = 0001.0011b: b4=1 -> on, 3 -> F3
2B      // CheckSum8 Modulo 256 (DU: 80..13)
16      // End Delimiter
```

Weitere Beispiele:
```
// F1 on
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 11   29 16
// F1 off
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 21   39 16
// F2 on
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 12   2A 16
// F2 off
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 22   3A 16
// F3 on
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 13   2B 16
// F3 off
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 23   3B 16
// F4 on
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 14   2C 16
// F4 off
send>68 00 0A 00 0A 68   80 7F 06 06 01 01  00 02  09 24   3C 16
```

### Online-Test-Abfrage der I/O-Daten

Befehl:
```
send>68 00 0A 00 0A 68  80 7F 06 06 01 01  00 01  08  16 16
```

Darstellungsformat:
```
68 00 09 00 09 68 // SD2; DU L�nge = 9 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01      // 
00      // 
01      // Byte Count = 1
08      // Command 08 (get/read)
16      // CheckSum8 Modulo 256 (DU: 80..08)
16      // End Delimiter
```

Index | Parameter
----- | ---------
   16 | Inputs 1-8
   17 | Inputs 9-16
   18 | Inputs 17-32
   19 | TD-Function Keys
   20 | Outputs 1-8
   21 | Outputs 9-16
   22 | Merker 1-8
   23 | Merker 9-16
   24 | Merker 17-24
   25 | Merker 25-27
   26 | Shift register 1-8
   27 | Cursor Keys C1-C4
   28 | analog Input 1 Low
   29 | analog Input 1 High
   30 | analog Input 2 Low
   31 | analog Input 2 High
   32 | analog Input 3 Low
   33 | analog Input 3 High
   34 | analog Input 4 Low
   35 | analog Input 4 High
   36 | analog Input 5 Low
   37 | analog Input 5 High
   38 | analog Input 6 Low
   39 | analog Input 6 High
   40 | analog Input 7 Low
   41 | analog Input 7 High
   42 | analog Input 8 Low
   43 | analog Input 8 High
   44 | analog Output 1 Low
   45 | analog Output 1 High
   46 | analog Output 2 Low
   47 | analog Output 2 High
   48 | analog Merker 1 Low
   49 | analog Merker 1 High
   50 | analog Merker 2 Low
   51 | analog Merker 2 High
   52 | analog Merker 3 Low
   53 | analog Merker 3 High
   54 | analog Merker 4 Low
   55 | analog Merker 4 High
   56 | analog Merker 5 Low
   57 | analog Merker 5 High
   58 | analog Merker 6 Low
   59 | analog Merker 6 High
>Tab: Index der Werte beim Online-Test

----------

# Anhang

## <a name="fcs"></a>Pr�fsumme
Jedem Telegramm wird eine 8-Bit-Pr�fsumme hinzugef�gt. Alle Datenbytes, zum Teil auch Bytes des Rahmens, werden Modulo-256 aufsummiert. Modulo-256 bedeutet dabei, dass bei jeder Summierung der �bertrag in das Bit mit der Wertigkeit 256 einfach ignoriert wird. Die entstandene 8 Bit lange Pr�fsumme wird vom Sender ins Telegramm eingef�gt. Der Empf�nger pr�ft die empfangenen Daten und f�hrt die selbe Addition durch. Die Pr�fsumme muss gleich sein. 

## <a name="ttl"></a>RS485-TTL-Anschaltung
TTL Anschaltung (z.B f�r Anschaltung an ein Microcontroller) via _MAX RS485 Module_  [HCMODU0081](http://hobbycomponents.com/wired-wireless/663-max485-rs485-transceiver-module). Das Modul ist von LC Electronic. Der Zugriff auf den Bus wird nicht automatisch vom Modul erledigt, sondern �ber die beiden "enable" Eing�nge RE ("Receiver enabled" = high bei Daten empfangen) und DE ("Driver enable" = low bei Daten senden) gesteuert. Die Anschl�sse an P1 haben TTL-Pegel, die Anschl�sse an P2 sind f�r die Versorgung des Moduls und hat zudem die A-B-Anschl�sse f�r die Anschaltung an den RS485-BUS. 

### Belegung P1 (links):
- [x] DI: Driver Input (TTL-pin Tx); Pin 1
- [x] DE: Driver Output Enable (`high` f�r Tx); Pin 2
- [x] RE: Receiver Output Enable (`low` f�r Rx); Pin 3
- [x] R0: Receiver Output (TTL-pin Rx); Pin 4

### Belegung P2 (rechts):
- [x] VCC: 5V; Pin 1
- [x] B: Invertierender Empf�ngereingang / Treiberausgang; Pin 2
- [x] A: Nicht invertierender Empf�ngereingang / Treiberausgang; Pin 3
- [x] GND: 0V \*); Pin 4

__Hinweis:__ \*) Das Mitf�hren der Masseleitung ist nicht notwendig, wird aber bei gro�en Leitungsl�ngen empfohlen, da es sonst zu gr��eren Potentialdifferenzen zwischen den Busteilnehmern kommen kann, die die Kommunikation behindern.

Folgend die Schaltung vom Modul zur Integration in die eigene Anwendung:
```
            VCC
             ^
             |
       .---o-o-o---.                   GND
       |   |   |   |                   ===
       |R1 |R2 |R3 |R4 = 10k            |
      .-. .-. .-. .-.                  .-.
      | | | | | | | |                  | |R5
      '-' '-' '-' '-'                  '-'20k
 P1    |   |   |   |      UI            |                   P2
.---.  |   |   |   |     .--------.     |                  .---.
| 4 |--o---)---)---)---1-| RO VCC |-8---)------------------| 1 |
| 3 |------o---)---)---2-| /RE  B |-7---'-----o------------| 2 |
| 2 |----------o---)---3-| DE   A |-6---.-----)---------o--| 3 |
| 1 |--------------o---4-| DI GND |-5---)-----)---------)--| 4 |
'---'                    '--------'     |     |   R7    |  '---'
                                        |     |   ___   |
                                       .-.    '--|___|--'
            R8     D1                  | |R6      120
            ___     //                 '-'20k
        .--|___|---|>|--.               |
        |   1k          |               V
        |    C2 = 0.1uF |              VCC
VCC <<--o-------||------o--| GND       
        |               |
        |    C1 = 10uF  |
        '-------||------'
```
>Abb: _MAX RS485 Module_ Schaltung

Zu beachten ist das R7 (120 Ohm) eine passive Bus-Terminierung vornimmt, die eventuell so nicht gew�nscht ist (z.B. wegen hohem Stromverbrauch, oder Terminierung am falschen Ort) und R7 dann ggf. ausgel�tet oder ersetzt werden muss, um zum Beispiel einen Kondensator in Reihe zum Abschlusswiderstand einzubringen, damit im Ruhezustand der Strom ann�hernd Null geht. Zus�tzlich k�nnten die Wiederst�nde R5 und R6 (sog. "local bias resistors") f�r ein RS485-Netzwerk ungeeignet sein, um wirksam undefinierte Buspegel bei inaktiven Leitungstreibern zu kompensieren, da die Werte in einigen Anwendungsf�llen zu hoch sind.

Zusammenfassend ist jedoch festzuhalten, dass die Widerst�nde R5-R7 vom RS485 Modul f�r die Anschaltung an die _TD_-Schnittstelle unver�ndert �bernommen werden k�nnen. Der Vollst�ndigkeitshalber m�chte ich jedoch an dieser Stelle einen passenden Abschluss f�r ein RS485-Netzwerk mit externem BIAS-Netzwerk (sog. "network bias resistores") darstellen: 
```
VCC
 ^
 |
.-.
| | 720
'-'
 |
 o------ B + ...
_|_
--- 100nF *)
 |
.-.
| | 120
'-'
 |
 0------ A - ...
 |
.-.
| | 720
'-'
 |
===
GND
```
>Abb: Abschlusswiderstand mit BIAS-Netzwerk

__Hinweis:__ \*) Kondensator C mit 100nF ist optional und wird eingesetzt, um im Ruhezustand den Stromverbrauch auf Null abzusenken.

Folgend beispielhaft die Anschaltung des Moduls an den RS485-BUS, die Versorgungsspannung und einen Microcontroller:
```
Rx Out --<--.  .--------------------------------------.  .-->> 5V
            '--| o RO :##:   ___   :##: # .---. VCC o |--' 
 Tx/Rx      .--| o RE :##: =|U1 |= :##: # |(O)|   B o |------( B +
 Dir *) ----+  |           =|___|=        + - +       |
            '--| o DE :##:         :##: # |(O)|   A o |------( A -
            .--| o DI :##:  :###:  :##: # '---' GND o |--. 
Tx Out -->--'  '--------------------------------------'  '--|> GND
```
>Abb: _MAX RS485 Module_ Anschaltung

__Hinweis:__ \*) Tx/Rx Dir: _high_ um Datem zu senden und _low_ um Datem zu empfangen

