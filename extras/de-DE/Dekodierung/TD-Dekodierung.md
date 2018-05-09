# LOGO! TD Protokoll Referenz Handbuch

Ausgabe Aa

Mai 2018

## Vorwort
Dieses Handbuch richtet sich an Personen, die mit einem Siemens (TM) _LOGO!_ __0BA6__ über die TD-Schnittstelle kommunizieren. Die TD-Schnittstelle verwendete ein PROFIBUS Anwendungs-Protokoll zur Bedienung und Anzeige am _TD_, welches hier als TD-Protokoll bezeichnet wird. In diesem Handbuch wird beschrieben, wie Nachrichten erstellt werden und wie Transaktionen mithilfe des TD-Protokolls ausgeführt werden.

Siemens und LOGO! sind eingetragene Marken der Siemens AG.

PROFIBUS ist eine eingetragene Handelsmarke des PROFIBUS Nutzerorganisation e.V.

## Verwendete oder weiterführende Publikationen

Wertvolle Informationen zum PROFIBUS finden Sie in den folgenden Veröffentlichungen:
  * [PROFIBUS Nutzerorganisation e.V. (PNO)](http://de.profibus.com/)
  * [PROFIBUS feldbusse.de](http://www.feldbusse.de/Profibus/profibus.shtml)
  * [PROFIBUS Wikipedia](http://de.wikipedia.org/wiki/Profibus)

## Inhalt

  * [Kapitel 1 - TD-Schnittstelle](#Kapitel1)
    * [PROFIBUS](#profibus)
    * [RS-485](#rs485)
    * [Fieldbus Data Link (FDL)](#fdl)
  * [Kapitel 2 - TD-Protokoll](#Kapitel2)
    * [Direkt Data Link Mapper (DDLM)](#ddlm)
    * [Anwendungsprotokoll (ALI)](#ali)

----------

# <a name="Kapitel1"></a>Kapitel 1 - TD-Schnittstelle
Bei der _TD_-Schnittstelle (TD = Text Display) handelt es sich um eine Anwendung, die auf dem industriellen PROFIBUS-DP Feldbusstandard aufsetzt. Der Feldbus verbindet die Feldebene (hier _TD_) mit den prozessnahen Komponenten (hier _LOGO!_ Kleinsteuerung), wobei diese Variante speziell für die Kommunikation zwischen _TD_ und den _LOGO!_ ausgelegt ist, um einen vereinfachten Einsatz ermöglichen.

## <a name="profibus"></a>PROFIBUS
PROFIBUS (PROcess FIeld BUS) ist ein Standard für die Feldbus-Kommunikation in der Automatisierungstechnik. Es handelt sich eine vollständige und erprobte Technologie, welche sich bereits bewährt hat und daher zur Anbindung des _TD_ mittels einer PROFIBUS-DP (DP = Dezentrale Peripherie) Variante genutzt wird: 
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
|                Schicht 3 bis 6: leer                 |
+------------------------------------------------------+
|         Schicht 2: (FDL) Fieldbus Data Link          |
+------------------------------------.-----------------+
| Schicht 1: EN 50 170 (RS485)       |  IEC 1158-2     |
'------------------------------------'-----------------'
```
>Bild: Varianten des PROFIBUS

PROFIBUS wurde Ende der 80er Jahre entwickelt und anschließend als Deutsche Norm DIN 19 245 und als europäische Norm EN 50 170 standardistert. Ziel der Normungsbestrebungen war die völlige Unabhängigkeit des Anwenderprogrammes von der Realisierung der Datenübertragung über den Bus. Das Anwenderprogramm benutzt das Kommunikationssystem mit Hilfe sogenannter Dienste (z.B. "send and request data with reply" mit den Dienstprimitiven _request_, _indication_, _response_ und _confirmation_). Das Kommunikationssystem ist nach dem sogenannten ISO/OSI Schichtenmodell (Standard ISO 7498, Open System Interconnection) aufgebaut. Wobei die Schichten 3 bis 6 nicht realisiert sind.

PROFIBUS unterscheidet folgende Gerätetypen:
- Master-Geräte: Ein Master darf Nachrichten ohne externe Aufforderung aussenden
- Slave-Geräte: Sie dürfen nur empfangene Nachrichten quittieren oder auf Anfrage eines Masters Nachrichten an diesen übermitteln. 

Um ein _TD_ an ein _LOGO!_ anzuschließen und darüber Daten auszutauschen, ist es nicht unbedingt erforderlich, dass der PROFIBUS und der Feldbus vollständig verstanden wird. Da nur eine Kommunikation mit dem _LOGO!_ geplant ist, ist dies ohnehin ein sehr einfaches Unterfangen, denn die _TD_-Schnittstelle stellt vollständiges PROFIBUS-Netzwerk dar. 

## <a name="rs485"></a>RS-485
Die Protokollarchitektur von PROFIBUS orientiert sich am ISO/OSI Referenz Modell. In diesem Modell übernimmt jeder Layer genau definierte Aufgaben. Layer 1 (Physical
Layer) definiert die physikalische Übertragungstechnik. Der Einsatzbereich eines Feldbus-Systems wird wesentlich durch die Wahl des Übertragungs-Mediums und der physikalischen Busschnittstelle bestimmt.

Bei der _TD_-Schnittstelle handelt es sich um ein kabelgebundene PROFIBUS DP Variante. Die Anschaltung auf Layer 1 folgt dem Standard TIA/EIA-485. Die Datenübertragung erfolgt über ein abgeschirmtes, verdrilltes Leiterpaar. RS-485 gilt als sehr störfest, ermöglicht Übertragungsraten bis 12 MBaud und ist ein wichtiger Standard in industriellen Feldbus-Anwendungen und ist daher auch beim PROFIBUS DP als Grundversion für Anwendungen im Bereich der Fertigungstechnik, Gebäudeleittechnik und Antriebstechnik festgelegt.

Wie beim PROFIBUS, der auf der TIA/EIA-485-Norm basiert, werden die Pins 3 und 8 von 9-poligen D-Sub-Stecker für die Datenleitung benutzt. Durch die galvanische Trennung im _TD_-Kabel (mittels Optokoppler) wurde das Mitführen der Masseleitung (Pin 5) und einer positiven Spannung (von 3,3V an Pin 1) notwendig. Die Spannungsversorgung vom _TD_  mit 3,3V und die inkompatbible Pin-Belegung zum PROFIBUS (5V an Pin 6) macht eine Anschaltung des _TD_ an einem PROFIBUS-Netzwerk nicht möglich.  

Bei einem PROFIBUS können Bitraten von 9600 Baud bis 12 MBaud projektiert werden. Die Baudrate bei der _TD_-Schnittslle ist auf 19.200 Baud festgelegt. Bei einer Übertragungsrate von 19.200 Baud ist eine theoretische Reichweite von bis zu 1200m möglich. Das eingesetzte _TD_-Kabel weicht jedoch beim Aderdurchmesser, -querschnitt, Wellenwiderstand und Kapazitätsbelag ab. Zudem erfolgt die Spannungsversorgung der Optokoppler im _TD_-Kabel vom _TD_ mit (nur) 3,3V. Daher sind in der Paxis ohne geeignete Anpassungen nur Längen bis ca. 20m möglich. 

Das eingesetzte Übertragungsverfahren ist halbduplex, asynchron und zeichenorientiert. Die Daten werden innerhalb eines 11 Bit-Zeichenrahmens im NRZ-Code (Non Return to Zero) übertragen, beginnend mit einem Starbit, das logisch Null ist. Die Zeichnübertragung endet mit einem Stoppbit, das immer eine logische Eins enthält. Auf das Startbit folgt die zu übertragenden Information als Datenbits. Nach den Datenbits und vor dem Stopbit wird ein Paritätsbit gesendet. Die Zahl der Datenbits beträgt bei der _TD_-Schnittstelle 8 Bit, wobei das niederwertigste Bit (LSB) immer direkt nach dem Startbit und das höchstwertige Bit (MSB) als letztes Datenbit gesendet wird. Die Datenübertragung bedient sich des Zeichenvorrates von `00` bis `FF`. Es werden nicht einzelne Zeichen, sondern Telegramme, bestehend aus Zeichenketten, übertragen (siehe [Schicht 2](#schicht2)).

```
|<-- Übertragungsrahmen ------------------------------------->|
.----.-----.-----.-----.-----.-----.-----.-----.-----.---.----.
| ST | 2^0 | 2^1 | 2^2 | 2^3 | 2^4 | 2^5 | 2^6 | 2^7 | P | SP |
'----'-----'-----'-----'-----'-----'-----'-----'-----'---'----'
     : LSB                                       MSB :
     |<-- Informations-Byte ------------------------>|
```
>Bild: Informations-Byte im 11 Bit-Übertragungsrahmen von Schicht 1

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
- 8–bit binary, hexadecimal 0–9, A–F

## <a name="fdl"></a>Fieldbus Data Link (FDL)
PROFIBUS verwendet ein einheitliches Buszugriffsprotokoll (Fieldbus Data Link = FDL). Es ist der Schicht 2 des OSI-Referenzmodells zugeordnet. Es beinhaltet auch die Funktionen der Datensicherung sowie die Abwicklung der Übertragungsprotokolle und der Telegramme. Die Schicht 2 wird bei PROFIBUS als Fieldbus Data Link (FDL) bezeichnet. Die Buszugriffssteuerung (Medium Access Control = MAC) legt das Verfahren fest, zu welchem Zeitpunkt ein Busteilnehmer Daten senden kann. PROFIBUS berücksichtigt hierbei zwei Buszugriffssteuerung:
- Token-Passing-Verfahren für die Kommunikation zwischen den Automatisierungsgeräten (Master).
- Master-Slave-Verfahren für die Kommunikation zwischen einem Automatisierungsgerät (Master) und den Peripheriegeräten (Slaves) 

Im Folgenden betrachten wir nur das Master-Slave-Verfahren, da nur dieses an der _TD_-Schnittstelle angewandt wird. Der Master hat hierbei die Möglichkeit, Nachrichten an ein Slave zu übermitteln bzw. Nachrichten vom Slave abzuholen. 

Eine weitere Aufgabe des Buszugriffsprotokolls (FDL) ist die Datensicherung. Die Telegramme nutzen mehere Mechanismen um eine hohe Datenübertragungssicherheit zu gewährleisten. Dies wird durch die Anwendung bzw. Auswahl von Start- und Endezeichen, Synchronisierung, Paritätsbit und Kontrollbyte erreicht. 

### Telegramme
Ein PROFIBUS-Telegramm besteht aus dem Telegrammheader, den Nutzdaten, einem Sicherungsbyte und dem End-Delimiter (Ausnahme: Tokentelegramm)

Folgende Telegramme sind für das PROFIBUS-Buszugriffsprotokoll (FDL) definiert:
- SD1: Format mit fester Informationsfeldlänge ohne Daten (L = 3) 
- SD2: Format mit variabler Informationsfeldlänge (L = 4..249)
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

Von den fünf genannten Telegrammen, wird (lat aktuellem Stand) für die Kommunikation vom _TD_ zum _LOGO!_ nur das SD2 Telegramm (Telegram mit variabler Datenlänge) verwendet.

Folgend der Aufbau des SD2 Telegrams:
```
.-----.----.-----.-----.----.----.----.--- ~ ~ ---.-----.----.
| SD2 | LE | LEr | SD2 | DA | SA | FC | Datenfeld | FCS | ED |
'-----'----'-----'-----'----'----'----'--- ~ ~ ---'-----'----'
|<-- FDL --------------------------------------------------->|
```
>Bild: SD2 Telegramm von Schicht 2

Die Länge des Datenfeldes beträgt maximal 246 Bytes.

Bedeutung der Abkürzungen: 
- SD2: Startbyte (Start Delimiter) _"variable Datenlänge"_, Code `68`
- DA: Zieladressbyte (Destination Address )
- SA: Quelladressbyte Source Address 
- FC: Kontrollbyte (Frame Control) zur Festlegung des Telegramtyps (_Senden_, _Anfordern_, _Quitieren_, etc.)
- FCS: Sicherungsbyte (Frame Check Sequence)
- LE: Längenbyte (Length), Wert 4 bis 249
- LEr: Wiederholung (Length repeated) des Längenbytes zur Sicherung
- ED: Endebyte (End Delimiter), Code `16`

### Adressierung
Das PROFIBUS-Buszugriffsprotokoll arbeitet verbindungslos. Es ermöglicht neben der Punkt-zu-Punkt-Datenübertragung auch Mehrpunktübertragung z.B. via Broadcast-Kommunikation. Der Adressbereich für DA und SA (Ident-Nummer bzw. Stationsadresse) ist von 0 bis 126. Die Adresse 127 steht für eine Multi- bzw. Broadcast-Adresse. Die _TD_-Schnitstelle nutzt die Broadcast-Kommunikation, obwohl physikalisch eine direkte Verbindung vorliegt. 

### Dienste der Schicht 2
Das PROFIBUS-Buszugriffsprotokoll (FDL) stellt den PROFIBUS-Anwendungsprotokollen folgende Dienste zur Verfügung:
- SDN (Send Data with No Acknowledge)
- SDA (Send Data with Acknowledge)
- SRD (Send and Request Data with Reply)
- CSRD (Cyclic SRD)

Von den vier möglichen Diensten werden von PROFIBUS-DP nur die Dienste SDN und SRD genutzt. Für die Kommunikation vom _TD_ zum _LOGO!_ wird ausschließlich der SDN Dienst (`06`) verwendet. Hierbei sendet das _TD_ eine unquittierte Nachricht an die _LOGO!_ Kleinsteuerung.

# <a name="Kapitel2"></a>Kapitel 2 - TD-Protokoll

## <a name="ddlm"></a>Direkt Data Link Mapper (DDLM)
Das Höchstwertiges Bit (MSB) in DA oder SA zeigt an, ob eine Adresserweiterung via Dienstzugangspunkt (Service Access Point = SAPs) im Datenfeld vorliegt. Die PROFIBUS-Dienstzugangspunkte (SAP) sind in den Bytes (vom datenfeld) DSAP oder SSAP vermerkt. 

```
|<-- Schicht 2 --------------------------------------------------- /~
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
>Bild: Adresserweiterung Schicht 2 (FDL) mit Dienstzugangspunkten Schicht 7 (DDLM)

Das _TD_ nutzt für DA die Adresserweiterung, d.h. das _TD_-Protokoll nutzt ein Anwendungsprotokoll oberhalb vom DDLM mit Dienstzugangspunkt (SAP). Die Dienste der Schicht 7 (DDLM) werden über die Adresserweiterung angezeigt und über Dienstzugangspunkte der Schicht 7 aufgerufen. 

### Dienste der Schicht 7
Im Gegensatz zum Standard verwendeten das _TD_ nicht die Dienstzugangspunkte inkl. zugehörigen Funktionen von PROFIBUS-DP sondern nutzt einen eigenen DDLM-Dienst mit Ziel-Dienstzugangspunkt (DSAP) `06` und Quell-Dienstzugangspunkt (SSAP) `01`.

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
>Bild: _TD_ DDLM Dienst (DSAP 6 und SSAP 1)


## <a name="ali"></a>TD-Anwendungsprotokoll (ALI)
Die vom _TD_ genutzten DDLM-Dienste versehen ihre Daten mit einem eigenen Schicht-7-Rahmen: dem _TD_-Anwendungsprotokoll. Da keine Objekte und keine Objektlisten im DDML existieren, wird die Kennzeichnung der Daten in anderer Weise durchgeführt. Unter der Annahme das der Slave modular aufgebaut ist, wird das _TD_-Anwendungsprotokoll gebildet aus der Funktionskennung, der Modulnummer, einer Kennziffer zur Unterscheidung innerhalb des Moduls und der Länge der zu übertragenden Daten. 

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
>Bild: DDLM eingebettet in Telegramm

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
DA: Destination Address = 80 = 1000.0000
    Im jeweiligen Adressbyte werden nur die niederwertigsten 7Bit für die Stationsadresse verwendet.
        b7: Extension bit = 1; Adresserweiterung mit Dienstzugangspunkt (SAP Service Access Point)
        b6..b0: Adresse 0
SA: Source Address = 7F = 127 = 0111.1111
        b7: Extension bit = 0; keine Adresserweiterung
        b6..b0: 127 = Broadcast-Adresse
FC: Function Code = 6; SDN (Send Data with No Acknowledge) high
DSAP: Ziel-Dienstzugangspunkt; 6 = 0000.0110
        b7: Extension bit = 0
        b6: Typ bit = 0; Region/Segment-Adresse
        b5..b0: Adresse 6
SSAP: Quell-Dienstzugangspunkt; 1 = 0000.0001
        b7: Extension bit = 0
        b6: Typ bit = 0
        b5..b0: Adresse 1
DU: Protocol Data Unit; Nettodaten (max 246 Bytes)
FCS: Frame Check Sequence; CheckSum8 Modulo 256
ED: End Delimiter (= 0x16)
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
>Bild: _TD_-Anwendungsprotokoll eingebettet im Telegramm


### TD Funktionstasten

Beispiel F4 off:
```
68 00 0A 00 0A 68
80 7F 06 06 01
01      //
00      // 
02      // Byte Count = 2
09      // Command 09 (set/write)
24      // 24 = 0010 0100: b5=1 -> off, 4 -> F4
3C      // CheckSum8 Modulo 256 (80..24)
16      // End Delimiter
```

Beispiel F4 on:
```
68 00 0A 00 0A 68
80 7F 06 06 01
01
00
02      // Byte Count = 2
09      // Command 09 (set/write)
13      // 13 = 0001 0011: b4=1 -> on, 3 -> F3
2B      // CheckSum8 Modulo 256 (80..13)
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
send>68 00 0a 00 0a 68  80 7F 06 06 01 01  00 01  08  16 16
```

Darstellungsformat:
```
68 00 0a 00 0a 68
80 7F 06 06 01 01
00
01      // Byte Count = 1
08      // Command 08 (get/read)
16      // CheckSum8 Modulo 256 (80..08)
16      // End Delimiter
```

Index der Werte beim Online-Test:
```
  16       Inputs 1-8
  17       Inputs 9-16
  18       Inputs 17-32
  19       TD-Function Keys
  20       Outputs 1-8
  21       Outputs 9-16
  22       Merker 1-8
  23       Merker 9-16
  24       Merker 17-24
  25       Merker 25-27
  26       Shift register 1-8
  27       Cursor Keys C1-C4
  28       analog Input 1 Low
  29       analog Input 1 High
  30       analog Input 2 Low
  31       analog Input 2 High
  32       analog Input 3 Low
  33       analog Input 3 High
  34       analog Input 4 Low
  35       analog Input 4 High
  36       analog Input 5 Low
  37       analog Input 5 High
  38       analog Input 6 Low
  39       analog Input 6 High
  40       analog Input 7 Low
  41       analog Input 7 High
  42       analog Input 8 Low
  43       analog Input 8 High
  44       analog Output 1 Low
  45       analog Output 1 High
  46       analog Output 2 Low
  47       analog Output 2 High
  48       analog Merker 1 Low
  49       analog Merker 1 High
  50       analog Merker 2 Low
  51       analog Merker 2 High
  52       analog Merker 3 Low
  53       analog Merker 3 High
  54       analog Merker 4 Low
  55       analog Merker 4 High
  56       analog Merker 5 Low
  57       analog Merker 5 High
  58       analog Merker 6 Low
  59       analog Merker 6 High
```

# Prüfsumme
Jedem Telegramm wird eine 8-Bit-Prüfsumme hinzugefügt. Alle Datenbytes, zum Teil auch Bytes des Rahmens, werden Modulo-256 aufsummiert. Modulo-256 bedeutet dabei, dass bei jeder Summierung der Übertrag in das Bit mit der Wertigkeit 256 einfach ignoriert wird. Die entstandene 8 Bit lange Prüfsumme wird vom Sender ins Telegramm eingefügt. Der Empfänger prüft die empfangenen Daten und führt die selbe Addition durch. Die Prüfsumme muss gleich sein. 
