# LOGO! TD Protokoll Referenz Handbuch

Ausgabe Ag

Juni 2018

## Vorwort
Dieses Handbuch richtet sich an Personen, die mit einem Siemens (TM) _LOGO!_ __0BA6__ über die Schnittstelle des _Text Displays_ kommunizieren. Die Schnittstelle verwendet ein _PROFIBUS_ (TM) Anwendungs-Protokoll zur Bedienung und Anzeige am _Text Displays_, welches hier als _TD_-Protokoll bezeichnet wird. In diesem Handbuch wird beschrieben, wie Nachrichten erstellt werden und wie Transaktionen mithilfe des _TD_-Protokolls ausgeführt werden.

_Siemens_ und _LOGO!_ sind eingetragene Marken der __Siemens AG__.

_PROFIBUS_ ist eine eingetragene Handelsmarke des __PROFIBUS Nutzerorganisation e.V__.

## Verwendete oder weiterführende Publikationen

Wertvolle Informationen zum _PROFIBUS_ finden Sie in den folgenden Veröffentlichungen:
  * [PROFIBUS Nutzerorganisation e.V. (PNO)](http://de.profibus.com/)
  * [PROFIBUS feldbusse.de](http://www.feldbusse.de/Profibus/profibus.shtml)
  * [PROFIBUS Wikipedia](http://de.wikipedia.org/wiki/Profibus)

Informationen zu RS485 und deren Anschaltung an ein Mcrocontroller finden Sie in den folgenden Veröffentlichungen:
  * [MAX485 RS-485 Modul](http://github.com/brickpool/Grove/blob/master/Communication/RS485/MAX485_RS-485_Module.md)
  * [An Arduino and RS485](http://pskillenrules.blogspot.com/2009/08/arduino-and-rs485.html)

## Inhalt

  * [Kapitel 1 - TD-Schnittstelle](#kapitel1)
    * [PROFIBUS](#profibus)
    * [RS-485](#rs485)
    * [Fieldbus Data Link (FDL)](#fdl)
  * [Kapitel 2 - TD-Protokoll](#kapitel2)
    * [Direkt Data Link Mapper (DDLM)](#ddlm)
    * [Anwendungsprotokoll (ALI)](#ali)
  * [Kapitel 3 - TD-Profile](#kapitel3)
    * [Diagnose `03`](#03)
    * [Stop/Start `04/05`](#0405)
    * [Online-Test (I/O-Daten) `08`](#08)
    * [TD Funktionstasten `09`](#09)
    * [Uhrzeit/Datum `10`](#10)
    * [Parametrierung `21`](#21)
    * [Adressierung `30`](#30)
  * [Anhang](#anhang)
    * [Prüfsumme](#fcs)
    * [RS485-TTL-Anschaltung](#ttl)

----------

# <a name="kapitel1"></a>Kapitel 1 - TD-Schnittstelle
Bei der _TD_-Schnittstelle (TD = Text Display) handelt es sich um eine Anwendung, die auf dem industriellen _PROFIBUS-DP_ Feldbusstandard aufsetzt. Der Feldbus verbindet die Feldebene (hier _TD_) mit den prozessnahen Komponenten (hier _LOGO!_ Kleinsteuerung), wobei diese Variante speziell für die Kommunikation zwischen _TD_ und den _LOGO!_ ausgelegt ist, um einen vereinfachten Einsatz ermöglichen.

## <a name="profibus"></a>PROFIBUS
_PROFIBUS_ (PROcess FIeld BUS) ist ein Standard für die Feldbus-Kommunikation in der Automatisierungstechnik. Es handelt sich eine vollständige und erprobte Technologie, welche sich bereits bewährt hat und daher zur Anbindung des _TD_ mittels der Variante PROFIBUS-DP (DP = Dezentrale Peripherie) genutzt wird: 
```
.------------------.-----------------.-----------------.
| PROFIBUS-FMS     | PROFIBUS-DP     | PROFIBUS-PA     |
+------------------+-----------------+-----------------+
| Profile für      | Profile für     | Profile für     |
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

_PROFIBUS_ wurde Ende der 80er Jahre entwickelt und anschließend als Deutsche Norm DIN 19 245 und als europäische Norm EN 50 170 standardistert. Ziel war es die völlige Unabhängigkeit des Anwenderprogrammes von der Realisierung der Datenübertragung über den Bus. Das Anwenderprogramm benutzt das Kommunikationssystem mit Hilfe sogenannter Dienste (z.B. "send and request data with reply" mit den Dienstprimitiven _request_, _indication_, _response_ und _confirmation_).

Das Kommunikationssystem ist nach dem sogenannten ISO/OSI Schichtenmodell (Standard ISO 7498, Open System Interconnection) aufgebaut. Wobei die Schichten 3 bis 6 nicht realisiert sind.

_PROFIBUS_ unterscheidet folgende Gerätetypen:
- Master-Geräte: Ein Master darf Nachrichten ohne externe Aufforderung aussenden
- Slave-Geräte: Sie dürfen nur empfangene Nachrichten quittieren oder auf Anfrage eines Masters Nachrichten an diesen übermitteln. 

Um ein _TD_ an ein _LOGO!_ anzuschließen und darüber Daten auszutauschen, ist es nicht unbedingt erforderlich, dass der _PROFIBUS_ und der Feldbus vollständig verstanden wird. Da nur eine Kommunikation mit dem _LOGO!_ geplant ist, ist dies eine sehr einfaches Variante, denn die _TD_-Schnittstelle soll kein vollständiges PROFIBUS-Netzwerk darstellen. 

## <a name="rs485"></a>RS-485
Die Protokollarchitektur von _PROFIBUS_ orientiert sich am _ISO/OSI_ Referenz Modell. In diesem Modell übernimmt jeder Layer genau definierte Aufgaben. Layer 1 (Physical Layer) definiert die physikalische Übertragungstechnik. Der Einsatzbereich eines Feldbus-Systems wird wesentlich durch die Wahl des Übertragungs-Mediums und der physikalischen Busschnittstelle bestimmt.

Bei der _TD_-Schnittstelle handelt es sich um ein kabelgebundene _PROFIBUS-DP_ Variante. Die Anschaltung auf Layer 1 folgt dem Standard TIA/EIA-485. Die Datenübertragung erfolgt über ein abgeschirmtes, verdrilltes Leiterpaar. RS-485 gilt als sehr störfest, ermöglicht Übertragungsraten bis 12 MBaud und ist ein wichtiger Standard in industriellen Feldbus-Anwendungen und ist daher auch beim _PROFIBUS-DP_ als Grundversion für Anwendungen im Bereich der Fertigungstechnik, Gebäudeleittechnik und Antriebstechnik festgelegt.

Wie beim _PROFIBUS_, der auf der TIA/EIA-485-Norm basiert, werden die Pins 3 und 8 von 9-poligen D-Sub-Stecker für die Datenleitung benutzt. Durch die galvanische Trennung im _TD_-Kabel (mittels Optokoppler) wurde das Mitführen der Masseleitung (Pin 5) und einer positiven Spannung (von 3,3V an Pin 1) notwendig. Die Spannungsversorgung vom _TD_  mit 3,3V und die inkompatbible Pin-Belegung zum _PROFIBUS_ (5V an Pin 6) macht eine Anschaltung des _TD_ an einem _PROFIBUS_-Netzwerk nicht möglich.  

Bei einem _PROFIBUS_ können Bitraten von 9600 Baud bis 12 MBaud projektiert werden. Die Baudrate bei der _TD_-Schnittslle ist auf 19.200 Baud festgelegt. Bei einer Übertragungsrate von 19.200 Baud ist eine theoretische Reichweite von bis zu 1200m möglich. Das eingesetzte _TD_-Kabel weicht jedoch beim Aderdurchmesser, -querschnitt, Wellenwiderstand und Kapazitätsbelag ab. Zudem erfolgt die Spannungsversorgung der Optokoppler im _TD_-Kabel vom _TD_ mit (nur) 3,3V. Daher sind in der Paxis ohne geeignete Anpassungen nur Längen bis ca. 20m möglich. 

Das eingesetzte Übertragungsverfahren ist halbduplex, asynchron und zeichenorientiert. Die Daten werden innerhalb eines 11 Bit-Zeichenrahmens im NRZ-Code (Non Return to Zero) übertragen, beginnend mit einem Starbit, das logisch Null ist. Die Zeichnübertragung endet mit einem Stoppbit, das immer eine logische Eins enthält. Auf das Startbit folgt die zu übertragenden Information als Datenbits. Nach den Datenbits und vor dem Stopbit wird ein Paritätsbit gesendet. Die Zahl der Datenbits beträgt bei der _TD_-Schnittstelle 8 Bit, wobei das niederwertigste Bit (LSB) immer direkt nach dem Startbit und das höchstwertige Bit (MSB) als letztes Datenbit gesendet wird. Die Datenübertragung bedient sich des Zeichenvorrates von `00` bis `FF`. Es werden nicht einzelne Zeichen, sondern Telegramme, bestehend aus Zeichenketten, übertragen (siehe [Schicht 2](#schicht2)).

```
|<-- Übertragungsrahmen ------------------------------------->|
.----.-----.-----.-----.-----.-----.-----.-----.-----.---.----.
| ST | 2^0 | 2^1 | 2^2 | 2^3 | 2^4 | 2^5 | 2^6 | 2^7 | P | SP |
'----'-----'-----'-----'-----'-----'-----'-----'-----'---'----'
     : LSB                                       MSB :
     |<-- Informations-Byte ------------------------>|
```
>Abb: Informations-Byte im 11 Bit-Übertragungsrahmen von Schicht 1

Bedeutung der Abkürzungen: 
- ST: Startbit (immer logisch `0`)
- 2^0 bis 2^7: Informations-Byte
- P: Paritätsbit
- SP: Stoppbit (immer logisch `1`)

Zusammgefasst lautet die Spezifikation für die Kommunikation über die TD-Schnittstelle:

### Kabel / Stecker:
- 4-adrig
- TD; SUB-D 9-pol Buchse; mänlich (m)
- LOGO! propitärer 6-pol Stecker; weiblich (f)

### Belegung _LOGO!_ 6 pol:
- [x] GND Masse; Pin 1
- [x] VCC Spannungsversorgung; Pin 2
- [ ] Pin 3
- [ ] Pin 4
- [x] Rx Datenempfang; Pin 5
- [x] Tx Datenübermittlung; Pin 6

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
- 1 bit für gerade Pärität (E)
- 1 Stop bit

### Kodierung:
- 8-bit binary, hexadecimal 0-9, A-F

## <a name="fdl"></a>Fieldbus Data Link (FDL)
_PROFIBUS_ verwendet ein einheitliches Buszugriffsprotokoll (Fieldbus Data Link = FDL). Es ist der Schicht 2 des OSI-Referenzmodells zugeordnet. Es beinhaltet auch die Funktionen der Datensicherung sowie die Abwicklung der Übertragungsprotokolle und der Telegramme. Die Buszugriffssteuerung (Medium Access Control = MAC) legt das Verfahren fest, zu welchem Zeitpunkt ein Busteilnehmer Daten senden kann. _PROFIBUS_ berücksichtigt hierbei zwei Buszugriffssteuerung:
- Token-Passing-Verfahren für die Kommunikation zwischen Automatisierungsgeräten (Master).
- Master-Slave-Verfahren für die Kommunikation zwischen einem Automatisierungsgerät (Master) und den Peripheriegeräten (Slaves) 

Im Folgenden betrachten wir nur das Master-Slave-Verfahren, da nur dieses an der _TD_-Schnittstelle angewandt wird. Der Master (_TD_) hat hierbei die Möglichkeit, Nachrichten an ein Slave (_LOGO!_) zu übermitteln bzw. Nachrichten vom Slave abzuholen. 

Eine weitere Aufgabe des Buszugriffsprotokolls (FDL) ist die Datensicherung. Die Telegramme nutzen mehere Mechanismen um eine hohe Datenübertragungssicherheit zu gewährleisten. Dies wird durch die Anwendung bzw. Auswahl von Start- und Endezeichen, Synchronisierung, Paritätsbit und Kontrollbyte erreicht. 

### Telegramme
Ein PROFIBUS-Telegramm besteht aus dem Telegrammheader, den Nutzdaten, einem Sicherungsbyte und dem End-Delimiter (Ausnahme: Tokentelegramm)

Folgende Telegramme sind für das _PROFIBUS_-Buszugriffsprotokoll (FDL) definiert:
- SD1: Format mit fester Informationsfeldlänge ohne Daten (L = 3) 
- SD2: Format mit variabler Informationsfeldlänge (L = 4..65531)
- SD3: Format mit fester Informationsfeldlänge mit Daten (L = 11)
- SD4: Token-Telegramm
- SC: Kurzquittung

Telegramm | Code (hex) | Bezeichnung
--------- | ---------- | -------------------------------------
SD1       | `10`       | Start Delimiter _"keine Daten"_
SD2       | `68`       | Start Delimiter _"variable Datenlänge"_
SD3       | `A2`       | Start Delimiter _"8 Bytes"_
SD4       | `DC`       | Start Delimiter _"Token"_
SC        | `E5`       | Single Character 
>Tabelle: Übersicht der Telegramme

Von den fünf genannten Telegrammen, wird (nach aktuellem Kenntnisstand) für die Kommunikation vom _TD_ zum _LOGO!_ nur das _SD2_ Telegramm (Telegram mit variabler Datenlänge) verwendet.

Folgend der Aufbau des _SD2_ Telegrams:
```
.-----.----.-----.-----.----.----.----.--- ~ ~ ---.-----.----.
| SD2 | LE | LEr | SD2 | DA | SA | FC | Datenfeld | FCS | ED |
'-----'----'-----'-----'----'----'----'--- ~ ~ ---'-----'----'
|<-- FDL --------------------------------------------------->|
```
>Abb: _SD2_ Telegramm von Schicht 2

Die Länge des Datenfeldes beträgt maximal 65528 Bytes.

Bedeutung der Abkürzungen: 
- SD2: Startbyte (Start Delimiter) _"variable Datenlänge"_, Code `68`
- DA: Zieladressbyte (Destination Address)
- SA: Quelladressbyte Source Address 
- FC: Kontrollbyte (Frame Control) zur Festlegung des Telegramtyps (_Senden_, _Anfordern_, _Quitieren_, etc.)
- FCS: Sicherungsbyte (Frame Check Sequence)
- LE: Längenword (Length), Wertebereich (4 bis 65531)
- LEr: Wiederholung (Length repeated) des Längenword zur Sicherung
- ED: Endebyte (End Delimiter), Code `16`

### Adressierung
Das PROFIBUS-Buszugriffsprotokoll arbeitet verbindungslos. Es ermöglicht neben der Punkt-zu-Punkt-Datenübertragung auch Mehrpunktübertragung z.B. via Broadcast-Kommunikation. Der Adressbereich für _DA_ und _SA_ (Ident-Nummer bzw. Stationsadresse) ist von 0 bis 126. Die Adresse 127 steht für eine Multi- bzw. Broadcast-Adresse. Die _TD_-Schnitstelle nutzt die Broadcast-Kommunikation, obwohl physikalisch eine direkte Verbindung vorliegt. 

### Dienste der Schicht 2
Das PROFIBUS-Buszugriffsprotokoll (FDL) stellt den _PROFIBUS_-Anwendungsprotokollen folgende Dienste zur Verfügung:
- SDN (Send Data with No Acknowledge)
- SDA (Send Data with Acknowledge)
- SRD (Send and Request Data with Reply)
- CSRD (Cyclic SRD)

Von den vier möglichen Diensten werden von _PROFIBUS-DP_ nur die Dienste _SDN_ und _SRD_ genutzt. Für die Kommunikation vom _TD_ zum _LOGO!_ wird ausschließlich der _SDN_ Dienst (`06`) verwendet. Hierbei sendet das _TD_ eine unquittierte Nachricht an die _LOGO!_ Kleinsteuerung.

----------

# <a name="kapitel2"></a>Kapitel 2 - TD-Protokoll

## <a name="ddlm"></a>Direkt Data Link Mapper (DDLM)
Das Höchstwertiges Bit (MSB) in _DA_ oder _SA_ zeigt an, ob eine Adresserweiterung via Dienstzugangspunkt (Service Access Point = SAPs) im Datenfeld vorliegt. Die PROFIBUS-Dienstzugangspunkte (SAP) sind in den Bytes (vom Datenfeld) _DSAP_ oder _SSAP_ vermerkt. 

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

Das _TD_ nutzt für _DA_ die Adresserweiterung, d.h. das _TD_-Protokoll nutzt ein Anwendungsprotokoll oberhalb vom _DDLM_ mit Dienstzugangspunkt (SAP). Die Dienste der Schicht 7 (DDLM) werden über die Adresserweiterung angezeigt und über Dienstzugangspunkte der Schicht 7 aufgerufen. 

### Dienste der Schicht 7
Im Gegensatz zum Standard verwendeten das _TD_ nicht die Dienstzugangspunkte inkl. zugehörigen Funktionen von _PROFIBUS-DP_ sondern nutzt einen eigenen _DDLM_-Dienst mit Ziel-Dienstzugangspunkt (DSAP) `06` und Quell-Dienstzugangspunkt (SSAP) `01`.

PROFIBUS-DP kennt die folgenden Gerätetypen: 
- DP-Master Klasse 1 (DPM1): Steuerung 
- DP-Master Klasse 2 (DPM2): Bediengerät, Konfigurationstool
- Slave 

Das _TD_ ist ein Bediengerät und somit dem Gerätetyp _DPM2_ zugeordnet. Die _LOGO!_ Kleinsteuerng ist der Slave. Folgend die Darstellung des Dienstumfanges vom _TD_:
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
Die vom _TD_ genutzten _DDLM_-Dienste versehen ihre Daten mit einem eigenen Schicht-7-Rahmen: dem _TD_-Anwendungsprotokoll. Da keine Objekte und keine Objektlisten im _DDML_ existieren, wird die Kennzeichnung der Daten in anderer Weise durchgeführt. Unter der Annahme das der Slave modular aufgebaut ist, wird das _TD_-Anwendungsprotokoll gebildet aus der Funktionskennung, der Modulnummer, einer Kennziffer zur Unterscheidung innerhalb des Moduls und der Länge der zu übertragenden Daten. 

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

SD2: 0x68 = SD2; Daten variabler Länge
LE: Länge der Nettodaten, (inkl. DA, SA, FC, DSAP, SSAP)
LEr: Wiederholung der Nettodaten Länge
DA: Destination Address = 80h = 1000.0000b
    Im jeweiligen Adressbyte werden nur die niederwertigsten 7Bit für die Stationsadresse verwendet.
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
FCS: Frame Check Sequence von DA bis inkl. DU; CheckSum8 Modulo 256
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


# <a name="kapitel3"></a>Kapitel 3 - TD-Profile

## <a name="03"></a>Diagnose `03`
Das _TD_-Protokoll nutzt den Befehl `03`, um Diagnoseinformationen von der _LOGO!_ Kleinsteuerung zu erhalten. Das Diagnosetelegramm wird unter anderem verwendet, um den Status, Betriebszustand und benutzerspezifische Ereignisse zu erfragen. Das Text-Display (Master) fragt hierzu zyklisch (ungefähr einmal pro Sekunde) die _LOGO!_ Steuerung (Slave) ab. Die Antwort erfolgt ebenfalls mit dem Befehl `03` (_Response_-Telegram) und hat ein festes Format, welches einen 7 Byte langen Informationsteil hat.

Im Informationsteil wird auch eine Check-Summe vom Schaltprogramm mitgesendet (Byte 6 und 7). Anhand der Check-Summe kann das _TD_ erkennen, ob das bei der Initialisierung geladenen Schaltprogramm noch aktuell ist. 

Befehl:
```
send>68 00 09 00 09 68
80 7F 06 06 01
01 00 01 03
11 16
recv<68 00 10 00 10 68
7F 80 06 06 01
01 00 08 03
01 00 00 00 00 7B C4
58 16
```

Darstellungsformat:
```
68 00 09 00 09 68 80 7F 06 06 01 [01 00 01 03 ] 11 16
                                 [DU          ]
                                 [01 [Bc ] Cmd]

68 00 10 00 10 68 7F 80 06 06 01 [01 00 08 03  01 00 00 00 00 7B C4] 58 16
                                 [DU                               ]
                                 [01 [Bc ] Cmd Op [Dn    ] D5 [Chk ]

Bc: Byte Count (Typ Word, Big Endian)
Cmd: Befehl 03h = Diagnosis
Op: Operating Mode;
    01h = RUN Mode
    02h = STOP Mode
    20h = Parameter Mode

Dn: Datenbyte an Stelle n (n = 3..4) = 00h
D5: Datenbyte Nr. 5; Bedeutung unbekannt;
    01h = (b7 wurde nach Meldetext gesetzt, warum?)
Chk: Schaltprogramm Checksum
```

## <a name="0405"></a>Stop/Start `04/05`
Das Stoppen oder das Starten eines Programmes wird mit den Befehl `04` für _Stop_ und `05` für _Start_ ausgelöst. Mit diesen Befehlen wird das in der _LOGO!_ (Slave) gespeicherte Program gestartet oder gestoppt. Sobald der Befehl im Menü ausgewählt wird, wird der _Start_ bzw. _Stop_-Befehl gesendet. Nachdem der Befehl ausgeführt wurde, wird das Ergebnis der Operation mit einem _Response_-Telegram beantwortet (z.B. Datenbyte = `06` für Ack). Die Beschreibung des Antwortcodes ist in einem eigenen Abschnitt beschrieben. 

## <a name="08"></a>Online-Test (I/O-Daten) `08`
Response und Request

Befehl:
```
send>68 00 0A 00 0A 68
80 7F 06 06 01 01
00
01 08
16 16
```

#### Request

Darstellungsformat:
```
68 00 09 00 09 68 // SD2; Länge = 9 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01    //
00 01 // Byte Count = 1
08    // Befehl 08h (Online Test)
16    // CheckSum8 Modulo 256 (DA incl. DU: 80..08)
16    // End Delimiter
```

#### Response

Darstellungsformat:
```
68 00 35 00 35 68 // SD2; Länge = 53 Byte
7F 80 06 06 01    // SDN; DA:DSAP = 127:6; SA:SSAP = 0:1 (127 = Broadcast)
01    // 
00 2D // Byte Count = 45
08    // Befehl 08h (Online Test)
00 00 00 ... 
XX    // CheckSum8 Modulo 256 (DA incl. DU: 7F..08)
16    // End Delimiter
```

Index | Parameter
--- | ---
1 | Inputs 1..8
2 | Inputs 9..16
3 | Inputs 17..32
4 | Outputs 1..8
5 | Outputs 9..16
6 | Function Keys F1..F4
7 | Merker 1..8
8 | Merker 9..16
9 | Merker 17..24
10 | Merker 25..27
11 | Shift register 1..8
12 | Cursor Keys C1..C4
13 | analog Input 1 high
14 | analog Input 1 low
15 | analog Input 2 high
16 | analog Input 2 low
17 | analog Input 3 high
18 | analog Input 3 low
19 | analog Input 4 high
20 | analog Input 4 low
21 | analog Input 5 high
22 | analog Input 5 low
23 | analog Input 6 high
24 | analog Input 6 low
25 | analog Input 7 high
26 | analog Input 7 low
27 | analog Input 8 high
28 | analog Input 8 low
29 | analog Output 1 high
30 | analog Output 1 low
31 | analog Output 2 high
32 | analog Output 2 low
33 | analog Merker 1 high
34 | analog Merker 1 low
35 | analog Merker 2 high
36 | analog Merker 2 low
37 | analog Merker 3 high
38 | analog Merker 3 low
39 | analog Merker 4 high
40 | analog Merker 4 low
41 | analog Merker 5 high
42 | analog Merker 5 low
43 | analog Merker 6 high
44 | analog Merker 6 low
>Tab: Index der Werte beim Online-Test

## <a name="09"></a>TD Funktionstasten `09`
Der _Request_ erfolgt mit einem Datenbyte. Nachdem der Befehl ausgeführt wurde, wird das Ergebnis der Operation mit einem _Response_-Telegram beantwortet (z.B. Datenbyte = `06` für Ack, siehe Antwortcodes im eigenen Abschnitt).

Darstellungsformat:
```
68 00 0A 00 0A 68 80 7F 06 06 01 [01 00 02 09  24] 3C 16
                                 [DU             ]
                                 [01 [BC ] CMD Fx]

Bc: Byte Count (Typ Word, Big Endian)
Cmd: Befehl 09h = Function Key
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
68 00 0A 00 0A 68 // SD2; Länge = 10 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01    // 
00 02 // Byte Count = 2
09    // Befehl 09h (Func Key)
24    // 24h = 0010.0100b: b5=1 -> off, 4 -> F4
3C    // CheckSum8 Modulo 256 (DA incl. DU: 80..24)
16    // End Delimiter
```

Beispiel F4 on:
```
68 00 0A 00 0A 68 // SD2; Länge = 10 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01    // 
00 02 // Byte Count = 2
09    // Befehl 09h (Func Key)
13    // 13h = 0001.0011b: b4=1 -> on, 3 -> F3
2B    // CheckSum8 Modulo 256 (DA incl. DU: 80..13)
16    // End Delimiter
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

## <a name="10"></a>Uhrzeit/Datum `10`
Der Befehl `10` _Date Time_ liest die aktuelle Uhrzeit, das Datum und die Sommer-/Winterzeit aus der Hardware-Uhr der _LOGO!_ Keinsteuerung aus. Der _Request_ erfolgt ohne Daten. Das Ergebnis der Operation wird von der _LOGO_ Steuerung mit einem _Response_-Telegram beantwortet.

Befehl:
```
send>68 00 09 00 09 68
80 7F 06 06 01
01 00 01 10
1E 16
recv<68 00 10 00 10 68
7F 80 06 06 01
01 00 08 10
10 05 12 08 02 03 01
5A 16
```

Darstellungsformat:
```
68 00 09 00 09 68 80 7F 06 06 01  01 00 01 10  1E 16
                                 [DU          ]
                                 [01 [Bc ] Cmd]

68 00 0A 00 0A 68 7F 80 06 06 01 [01 00 08 10  10 05 12 08 02 03 01] 5A 16
                                 [DU                               ]
                                 [01 [Bc ] Cmd DD MM YY mm hh Wd SW]

Bc: Byte Count (Typ Word, Big Endian)
Cmd: Befehl 10h = Date Time
DD: Tag; Wertebereich 01..1F (1 bis 31)
MM: Monat; Wertebereich 01..0C (1 bis 12)
YY: Jahr; Wertebereich beginnend bei 03 (entspricht 2003)
mm: Minuten; Wertebereich 01..3B (1 bis 59)
hh: Stunden; Wertebereich 00..17 (0 bis 23)
Wd: Wochentag; Wertebereich 00..06 (So bis Sa)
SW: 01 = Sommerzeit; 00 = Winterzeit
```

Beispiel (Response, nur DU):
```
01    //
00 08 // Byte Count = 8
10    // Befehl 10h (Clock)
04    // Tag 4
06    // Monat Juni
12    // Jahr 2018
13    // Minute 19
16    // Stunde 22 
02    // Dienstag
01    // Sommerzeit
```

## <a name="21"></a>Parametrierung `21`
Der Befehl _Set Parameter_ `21` dient dem Einstellen der Parameter der Blöcke. Es können unter anderem Verzögerungszeiten, Schaltzeiten, Schwellwerte, Überwachungszeiten und Ein- und Ausschaltschwellen geändert werden, ohne das das Schaltprogramm geändert werden muss. 

Vorteil: In der Betriebsart _Parametrieren_ arbeitet die _LOGO!_ Kleinsteuerung das Schaltprogramm weiter ab. Sobald die geänderten Parameter (in der Betriebsart _Parametrieren_) mit der Taste _OK_ quittiert wurden, wird der Befehl _Set Parameter_ gesendet. Nachdem der Befehl ausgeführt wurde, wird das Ergebnis der Operation mit einem _Response_-Telegram (üblicherweise mit dem Datenbyte = `06` für Ack) beantwortet. 

__Hinweis:__ Das erfolgreiche Ändern von Parametern setzt voraus, dass die für den Block im Schaltprogramm eingestellte Schutzart dies erlaubt (Parameterschutz = `+`). 

Befehl:
```
send>68 00 37 00 37 68
80 7F 06 06 01
01 00 2F 21 00 0F 00 FC 00 14 CE 04 EC 04 FF FF
FF FF FF FF FF FF 7F 00 00 00 00 00 21 40 0F 80
00 80 00 00 21 40 0F 80 2C 81 00 00 21 40 0F 80
89 83
BE 16
recv<68 00 0A 00 0A 68
7F 80 06 06 01
01 00 02 21 06
36 16
```

Darstellungsformat (Request, nur DU):
```
01  00 2F  21   00 0F   00 FC   00 14   CE 04 EC 04 FF FF ...
01 [00 2F] 21  [00 0F] [00 FC] [00 14] [CE 04 EC 04 FF FF ...
01 [Bc   ] Cmd [Bl   ] [Po   ] [Pc   ] [Dn ...

Bc: Byte Count (Typ Word, Big Endian)
Cmd: Befehl 21h = Set Parameter
Bl: Blocknummer (Typ Word, Big Endian)
Po: Zeigeradresse (Typ Word, Big Endian)
Pc: Anzahl Parameter Bytes (Anzahhl ist inkl. Feldlänge von Pc)
Dn: Datenbyte an Stelle n (n = 3..Pc)
```

## <a name="30"></a>Adressierung `30`
Der Befehl _Addressing_ `30` benennt die indizierten Speicherbereiche (Indexregister) vom Programmzeilenspeicher für die Ausgänge, Merker und Funktionsblöcke. Das Ziel eines Indexregisters ist eine Speicherzelle im Programmzeilenspeicher. Die von der _LOGO!_ Kleinsteuerung zurückgemeldeten Indexregister werden vom _TD_ genutzt, um auf die Struktur des Schaltprogramms zuzugreifen, welche über den Befehl `40` (und folgend) abgefragt werden. Die Adresse ergibt sich aus den Inhalt des jeweiligen Indexregisters, das auf den Speicherort vom Programmzeilenspeicher verweist. 

Der Befehl `30` gibt bei einer _LOGO!_ __0BA6__ 420 Bytes Netto-Daten zurück. Die ersten 20 Bytes verweisen auf (weitere) 10*20 Bytes für Ausgänge und Merker (siehe Tabelle folgend). Die nächsten 400 Bytes verweisen auf die 200 Funktionsblöcke im Programmzeilenspeicher. Der Verweis wird als 16 Bit-Offset-Adresse (Little Endian) dargestellt. 

Befehl:
```
recv<68 01 AD 01 AD 68
7F 80 06 06 01
01 01 A5 30
0000   00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00
0010   A0 00 B4 00 C8 00 D4 00 E0 00 EC 00 F8 00 FC 00
0020   10 01 18 01 20 01 28 01 30 01 34 01 3C 01 44 01
0030   4C 01 54 01 58 01 5C 01 FF FF 60 01 6C 01 7C 01
0040   8C 01 FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0050   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0060   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0070   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0080   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0090   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00A0   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00B0   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00C0   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00D0   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00E0   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00F0   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0100   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0110   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0120   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0130   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0140   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0150   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0160   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0170   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0180   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0190   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
01A0   FF FF FF FF
EB 16
```

### Indexregister Ausgänge und Merker

Darstellungsformat (Response, nur Netto-Daten, 20 Bytes):
```
0000   00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00
0010   A0 00 B4 00 .. .. ..

             |<----------------------- 20 Bytes ---------------------->|
HEX (Lo Hi): 00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
HEX (Hi,Lo): 00,00 00,14 00,28 00,3C 00,50 00,64 00,78 00,8C 00,A0 00,B4
Dezimal:     00    20    40    60    80    100   120   140   160   180
Speicherbedarf: 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20
```

Zeiger | Beschreibung
-------|------------------------------------
0000   | Digitaler Ausgang 1-8
0014   | Digitaler Ausgang 9-16
0028   | Merker 1-8
003C   | Merker 9-16
0050   | Merker 17-24
0064   | Analogausgang 1-2; Analogmerker 1-6
0078   | offener Ausgang 1-8
008C   | offener Ausgang 9-16
00A0   | Merker 25-27
00B4   | (Reserve ??)
>Tab: Übersicht Indexregister Ausgänge und Merker

### Indexregister für Funktionsblöcke
Unter Verwendung des ausgelesen Wertes ist es möglich, den Block im Speicherbereich anzusprechen. Das Indexregister für Block B001 ist an Stelle `21..22` zu finden, der Block B002 an Stelle `23..24`, Block B003 an `25..26`, usw. Der Wert `FFFF` bedeutet, dass der Block nicht im Schaltprogramm verwendet wird.

Darstellungsformat (Response, nur Netto-Daten, Bytes > 20):
```
0010   .. .. .. .. C8 00 D4 00 E0 00 EC 00 F8 00 FC 00
0020   10 01 18 01 20 01 28 01 30 01 34 01 3C 01 44 01
0030   4C 01 54 01 58 01 5C 01 FF FF 60 01 .. .. .. ..

             |<----------------------- 20 Bytes ---------------------->|
HEX (Lo Hi): C8 00 D4 00 E0 00 EC 00 F8 00 FC 00 10 01 18 01 20 01 28 01
HEX (Hi,Lo): 00,C8 00,D4 00,E0 00,EC 00,F8 00,FC 01,10 01,18 01,20 01,28
Dezimal:     200   212   224   236   248   252   272   280   288   296
Speicherbedarf: 12 -- 12 -- 12 -- 12 --- 4 -- 20 --- 8 --- 8 --- 8 --- 8

             |<----------------------- 20 Bytes ---------------------->|
HEX (Lo Hi): 30 01 34 01 3C 01 44 01 4C 01 54 01 58 01 5C 01 FF FF 60 01
HEX (Hi,Lo): 01,30 01,34 01,3C 01,44 01,4C 01,54 01,58 01,5C FF,FF 01,60
Dezimal:     304   308   316   324   332   340   344   348   n/a   352
Speicherbedarf:  4 --- 8 --- 8 --- 8 --- 8 --- 4 --- 4 ------ 8 ----- 12
```

Zeiger | Block-Nr | Speicher
-------|----------|---------
00C8   | B001     | 12 Bytes
00D4   | B002     | 12 Bytes
00E0   | B003     | 12 Bytes
00EC   | B004     | 12 Bytes
00F8   | B005     | 4 Bytes
00FC   | B006     | 20 Bytes
0110   | B007     | 8 Bytes
0118   | B008     | 8 Bytes
0120   | B009     | 8 Bytes
0128   | B010     | 8 Bytes
0130   | B011     | 4 Bytes
0134   | B012     | 8 Bytes
013C   | B013     | 8 Bytes
0144   | B014     | 8 Bytes
014C   | B015     | 8 Bytes
0154   | B016     | 4 Bytes
0158   | B017     | 4 Bytes
015C   | B018     | 8 Bytes
n/a *) | B019     | 0 Bytes
0160   | B020     | 12 Bytes
>Tab: Übersicht Indexregister Funktionsblöcke

\*) Block-Nr. B019 wird im Schaltprogramm nicht verwendet!

----------

# Anhang

## <a name="fcs"></a>Prüfsumme
Jedem Telegramm wird eine 8-Bit-Prüfsumme hinzugefügt. Alle Datenbytes, zum Teil auch Bytes des Rahmens, werden Modulo-256 aufsummiert. Modulo-256 bedeutet dabei, dass bei jeder Summierung der Übertrag in das Bit mit der Wertigkeit 256 einfach ignoriert wird. Die entstandene 8 Bit lange Prüfsumme wird vom Sender ins Telegramm eingefügt. Der Empfänger prüft die empfangenen Daten und führt die selbe Addition durch. Die Prüfsumme muss gleich sein.

Die Implementierung ist einfach, da nur eine 8-Bit-Prüfsumme für eine Folge von hexadezimalen Bytes berechnet werden muss. Wir verwenden eine Funktion `F(bval, cval)`, die ein Datenbyte und einen Prüfwert eingibt und einen neu berechneten Prüfwert ausgibt. Der Anfangswert für `cval` ist 0. Die Prüfsumme kann mit der folgenden Beispielfunktion (in C-Sprache) berechnet werden, die wir für jedes Byte des Datenfelds wiederholt aufrufen. Die 8-Bit-Prüfsumme ist das Zweierkomplement der Summe aller Bytes.

```
int F_chk_8( int bval, int cval )
{
  return ( bval ^ cval ) % 256;
}
```
>Abb: Implementation der 8-Bit-Prüfsumme in _C_


## <a name="ttl"></a>RS485-TTL-Anschaltung
TTL Anschaltung (z.B für Anschaltung an ein Microcontroller) via _MAX RS485 Module_  [HCMODU0081](http://hobbycomponents.com/wired-wireless/663-max485-rs485-transceiver-module). Das Modul ist von LC Electronic. Der Zugriff auf den Bus wird nicht automatisch vom Modul erledigt, sondern über die beiden "enable" Eingänge RE ("Receiver enabled" = high bei Daten empfangen) und DE ("Driver enable" = low bei Daten senden) gesteuert. Die Anschlüsse an P1 haben TTL-Pegel, die Anschlüsse an P2 sind für die Versorgung des Moduls und hat zudem die A-B-Anschlüsse für die Anschaltung an den RS485-BUS. 

### Belegung P1 (links):
- [x] DI: Driver Input (TTL-pin Tx); Pin 1
- [x] DE: Driver Output Enable (`high` für Tx); Pin 2
- [x] RE: Receiver Output Enable (`low` für Rx); Pin 3
- [x] R0: Receiver Output (TTL-pin Rx); Pin 4

### Belegung P2 (rechts):
- [x] VCC: 5V; Pin 1
- [x] B: Invertierender Empfängereingang / Treiberausgang; Pin 2
- [x] A: Nicht invertierender Empfängereingang / Treiberausgang; Pin 3
- [x] GND: 0V \*); Pin 4

__Hinweis:__ \*) Das Mitführen der Masseleitung ist nicht notwendig, wird aber bei großen Leitungslängen empfohlen, da es sonst zu größeren Potentialdifferenzen zwischen den Busteilnehmern kommen kann, die die Kommunikation behindern.

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

Zu beachten ist das R7 (120 Ohm) eine passive Bus-Terminierung vornimmt, die eventuell so nicht gewünscht ist (z.B. wegen hohem Stromverbrauch, oder Terminierung am falschen Ort) und R7 dann ggf. ausgelötet oder ersetzt werden muss, um zum Beispiel einen Kondensator in Reihe zum Abschlusswiderstand einzubringen, damit im Ruhezustand der Strom annähernd Null geht. Zusätzlich könnten die Wiederstände R5 und R6 (sog. "local bias resistors") für ein RS485-Netzwerk ungeeignet sein, um wirksam undefinierte Buspegel bei inaktiven Leitungstreibern zu kompensieren, da die Werte in einigen Anwendungsfällen zu hoch sind.

Zusammenfassend ist jedoch festzuhalten, dass die Widerstände R5-R7 vom RS485 Modul für die Anschaltung an die _TD_-Schnittstelle unverändert übernommen werden können. Der Vollständigkeitshalber möchte ich jedoch an dieser Stelle einen passenden Abschluss für ein RS485-Netzwerk mit externem BIAS-Netzwerk (sog. "network bias resistores") darstellen: 
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

