# LOGO! TD Protokoll Referenz Handbuch

Ausgabe Aj

Juni 2018

## Vorwort
Mit der Einführung der 7. _LOGO!_ Generation __0BA6__ im Jahre 2008 hat _Siemens_ die Möglichkeit geschaffen ein abgesetztes Text-Display via seriellen Kabel anzuschalten. Durch Einsatz des Displays wurden die Einsatzgebiete der _LOGO!_ Kleinsteuerung erweitert. Das Display bietet neben dem Anzeigen von Meldungen auch die Bedienung und Parametrisierung im Betriebsmodus _RUN_. Leider wurde das verwendete Kommuikationsprotokoll von _Siemens_ nicht offengelegt, daher ist diese Funktionserweiterung für die Anschaltung an andere Kommunikationsnetz bislang unmöglich. In Versuchsreihen konnte ein Teil des Protokolls entschlüsselt werden. Die Ergebnisse wurden in Form des vorliegenden Handbuches dokumentiert. 

Dieses Handbuch richtet sich an Personen, die mit einer Siemens _LOGO!_ Kleinsteuerung vom Typ __0BA6__ über die Schnittstelle des _Text Displays_ kommunizieren wollen. Die Schnittstelle verwendet ein _PROFIBUS_ Anwendungs-Protokoll zur Bedienung und Anzeige am _Text Displays_, welches hier als _TD_-Protokoll bezeichnet wird. In diesem Handbuch wird beschrieben, wie Nachrichten erstellt werden und wie Transaktionen mithilfe des _TD_-Protokolls ausgeführt werden.

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
    * [Cursor-/Funktionstasten `09`](#09)
    * [Uhrzeit/Datum `10`](#10)
    * [Display Update `18`](#18)
    * [Parametrierung `21`](#21)
    * [Adressierung `30`](#30)
    * [Verweis auf Blocknamen `3c`](#3c)
    * [Blocknamen `3d`](#3d)
    * [Klemmenspeicher `40`](#40)
    * [Programmzeilenspeicher `41..4x`](#41)
    * [Verweis auf Meldetexte `5b`](#5b)
    * [Meldetext `61`](#61)
  * [Anhang](#anhang)
    * [Prüfsumme](#fcs)
    * [RS485-TTL-Anschaltung](#ttl)

----------

# <a name="kapitel1"></a>Kapitel 1 - TD-Schnittstelle
Bei der _TD_-Schnittstelle (TD = Text Display) handelt es sich um eine Anwendung, die sich an den industriellen _PROFIBUS-DP_ Feldbusstandard anlehnt. Der Feldbus verbindet die Feldebene (hier _TD_) mit den prozessnahen Komponenten (hier _LOGO!_ Kleinsteuerung), wobei diese Variante speziell für die Kommunikation zwischen _TD_ und den _LOGO!_ ausgelegt ist, um einen vereinfachten Einsatz ermöglichen.

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
Im Bereich der seriellen Übertrageung haben sich eine Reihe von Formaten etabliert. Das für das Text-Display eingesetzte Protokoll (kurz TD-Protokoll) wurde maßgeblich vom _PROFIBUS DP_ Protokoll beeinflußt. Das _PROFIBUS_ Protokoll wird, von vielen Firmen bzw. Produkten unterstützt. Für die Entwickler lag es wohl nahe, auf etablierte Verfahren zu setzen, da _Siemens_ maßgeblich an der Standardisierung vom _PROFIBUS_ mitgewirkt hatte. Dieses Kapitel behandeln den am PROFIBUS DP Standard angelehnten Protokollanteil. 

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
Die vom _TD_ genutzten _DDLM_-Dienste versehen ihre Daten mit einem eigenen Schicht-7-Rahmen: dem _TD_-Anwendungsprotokoll. Da keine Objekte und keine Objektlisten im _DDML_ existieren, wird die Kennzeichnung der Daten in anderer Weise durchgeführt.  

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

Beispiel:
```
send> 68 00 0A 00 0A 68 80 7F 06 06 01 01 00 02 09 11 29 16
```

Darstellungsformat:
```
|<-- FDL --------------------------------------------------->|
                             |<-- DDLM -------------->|
68  00 0A 00 0A 68  80 7F 06 06   01   [01 00 02 09 11] 29  16
SD2 [LE ] [LEr] SD2 DA SA FC DSAP SSAP [ALI           ] FCS ED

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
ALI: Application Layer Interface (variable Länge)
FCS: Frame Check Sequence von DA bis inkl. DU; CheckSum8 Modulo 256
ED: End Delimiter = 16h
```

----------

# <a name="kapitel3"></a>Kapitel 3 - TD-Profile
Das folgende Kapitel zeigt, wie sich das _PROFIBUS DP_ Anwendungsprotokoll für das _TD_ (folgend als _TD_-Profil bezeichnet) im _PROFIBUS-DP_ Telegramm darstellt. Auch wenn sich einige Unterschiede zwischen den jeweiligen TD-Profilen ergeben, besitzen diese doch einen übereinstimmenden Protokollaufbau. Alle Informationen werden im Telegram mit folgender Struktur gespeichert:

```
|<-- FDL ----------------------------------------->|
            |<-- DDLM ----------------->|
.-----.-----.------.------.-------------.-----.----.
| SD2 | ... | DSAP | SSAP | ALI         | FCS | ED |
'-----'-----'------'------'-------------'-----'----'
                         /               \
                        /                 \
                       .----.----.----.----.
                       | NU | BC | OP | DU |
                       '----'----'----'----'
                       |<-- TD-Profil ---->|
```
>Abb: _TD_-Anwendungsprotokoll eingebettet im PROFIBUS DDLM Rahmen

Feldname | Länge   | Verwendung
---------|---------|---------------------------
`NU`     | 1 Byte  | unbekannt (Name Unknown)
`BC`     | 2 Bytes | Längenfeld (Byte Count)
`OP`     | 1 Byte  | Befehlstyp (OPcode)
`DU`     | n Bytes | Protokolldaten (Data Unit)

Die einzelnen Felder haben folgende Bedeutung:
* Die Bedeutung des ersten Bytes ist nicht bekannt. Die Versuchreihen zeigten hier bislang immer einen konstanten Wert von 01h an. 
* Das Längenfeld `BC` umfasst zwei Byte und spezifiziert die Länge der nachfolgenden Daten (inkl. Feld `OP`) in Byte. Dabei wird das MSB zuerst gespeichert. 
* Das Feld `OP` ist ein Byte lang und beschreibt den Befehlstyp (nachfolgend auch als _Opcode_ bezeichnet). 
* Das Datenfeld `DU` ist optional und besitzt eine variable Länge, die vom _Opcode_ abhängt und durch das Längenfeld `BC` spezifiziert wird. Im Datenfeld finden sich Werte, Parameter, (Zeiger-)Referenzen und Inhalte vom Schaltprogramm. 

## <a name="03"></a>Diagnose `03`
Das _TD_-Protokoll nutzt den _Opcode_ `03`, um Diagnoseinformationen von der _LOGO!_ Kleinsteuerung zu erhalten. Der Diagnosetelegramm wird unter anderem verwendet, um den Status, Betriebszustand und benutzerspezifische Ereignisse zu erfragen. Das Text-Display (Master) fragt hierzu zyklisch (ungefähr einmal pro Sekunde) die _LOGO!_ Steuerung (Slave) ab. Die Antwort erfolgt ebenfalls mit dem _Opcode_ `03` (_Response_-Telegram) und hat ein festes Format, welches einen 7 Byte langen Informationsteil hat.

Im Informationsteil wird die Check-Summe vom Schaltprogramm mitgesendet (Byte 6 und 7). Anhand der Check-Summe kann das _TD_ erkennen, ob das bei der Initialisierung geladenen Schaltprogramm noch aktuell ist. 

_Opcode_:
```
send> 68 00 09 00 09 68 80 7F 06 06 01
01 00 01 03
11 16
recv< 68 00 10 00 10 68 7F 80 06 06 01
01 00 08 03
01 00 00 00 00 7B C4
58 16
```

Darstellungsformat:
```
                                 |<-- ALI -->|
68 00 09 00 09 68 80 7F 06 06 01 [01 00 01 03] 11  16
                                 [01 [Bc ] Op]

                                 |<-- ALI ----------------------->|
                                 |            |<-- DU ----------->|
68 00 10 00 10 68 7F 80 06 06 01 [01 00 08 03 01 00 00 00 00 7B C4] 58 16
                                 [01 [Bc ] Op Om D2 Pm D4 D5 [Chk ]

Bc: Byte Count (Typ Word, Big Endian)
Op: Opcode 03h = Diagnosis
Om: Operating Mode;
    01h = RUN Mode
    02h = STOP Mode
    20h = Parameter Mode
    42h = Programming Mode

D2: Datenbyte Nr. 2; Bedeutung unbekannt;
    FFh = (nach Push gesetzt, ggf. Busy?)

Pm: Programming Mode; LOGO!Soft Comfort sendet ein Schaltprogramm zur LOGO!
    00h = Idle
    02h = PUSH Notification
    04h = PUSH Complete

D4: Datenbyte Nr. 4; Bedeutung unbekannt;
D5: Datenbyte Nr. 5; Bedeutung unbekannt;
    01h = (b7 wurde nach Meldetext gesetzt, warum?)
Chk: Schaltprogramm Checksum
```

## <a name="0405"></a>Stop/Start `04/05`
Das Stoppen oder das Starten eines Programmes wird mit den _Opcode_ `04` für _Stop_ und `05` für _Start_ ausgelöst. Mit diesen Befehlen wird das in der _LOGO!_ (Slave) gespeicherte Program gestartet oder gestoppt. Sobald der Befehl im Menü ausgewählt wird, wird der _Start_ bzw. _Stop_-Befehl gesendet. Nachdem der Befehl ausgeführt wurde, wird das Ergebnis der Operation mit einem _Response_-Telegram beantwortet (z.B. Datenbyte = `06` für Ack). Die Beschreibung des Antwortcodes ist in einem eigenen Abschnitt beschrieben. 

## <a name="08"></a>Online-Test (I/O-Daten) `08`
Response und Request

Beispiel:
```
send> 68 00 0A 00 0A 68 80 7F 06 06 01
01 00 01 08
16 16
recv< 68 00 35 00 35 68 7F 80 06 06 01
01 00 2D 08
00 00 00 ...
XX 16
```

Darstellungsformat:
```
                                 |<-- ALI -->|
68 00 09 00 09 68 80 7F 06 06 01 [01 00 01 08] 16 16
                                 [01 [Bc ] Op]

                                 |<-- ALI ---------------->|
                                 |            |<-- DU ---->|
68 00 35 00 35 68 7F 80 06 06 01 [01 00 2D 08 00 00 00 ... ] XX 16
                                 [01 [Bc ] Op [Pa          ]

Bc: Byte Count = 1
Op: Opcode 08h = Online Test
Pa: Parameter, siehe Tabelle folgend
```

Position | Parameter
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
10 | Cursor Keys C1..C4
11 | Shift register 1..8
12 | Merker 25..27
13 | analog Input 1 MSB
14 | analog Input 1 LSB
15 | analog Input 2 MSB
16 | analog Input 2 LSB
17 | analog Input 3 MSB
18 | analog Input 3 LSB
19 | analog Input 4 MSB
20 | analog Input 4 LSB
21 | analog Input 5 MSB
22 | analog Input 5 LSB
23 | analog Input 6 MSB
24 | analog Input 6 LSB
25 | analog Input 7 MSB
26 | analog Input 7 LSB
27 | analog Input 8 MSB
28 | analog Input 8 LSB
29 | analog Output 1 MSB
30 | analog Output 1 LSB
31 | analog Output 2 MSB
32 | analog Output 2 LSB
33 | analog Merker 1 MSB
34 | analog Merker 1 LSB
35 | analog Merker 2 MSB
36 | analog Merker 2 LSB
37 | analog Merker 3 MSB
38 | analog Merker 3 LSB
39 | analog Merker 4 MSB
40 | analog Merker 4 LSB
41 | analog Merker 5 MSB
42 | analog Merker 5 LSB
43 | analog Merker 6 MSB
44 | analog Merker 6 LSB
>Tab: Parameter beim Befehlstyp Online-Test

## <a name="09"></a>Cursor-/Funktionstasten `09`
Die vier Cursortasten `^`, `>`, `v` und `<` können in einem Schaltprogramm als Eingang genutzt werden. Die Eingänge der Cursortasten des _LOGO! TD_ sind mit den Eingängen der Cursortasten des _LOGO!_ Basismoduls identisch. Die Verwendung erfolgt im Modus _RUN_ mittels `ESC` + gewünschte Cursortaste `C`. Das _TD_ hat vier Funktionstasten `F1`, `F2`, `F3` und `F4` welche ebenfalls, wie die Cursortasten, im Schaltprogramm als Eingang genutzt werden können, wenn sich die _LOGO!_ Steuerung im Modus _RUN_ befindet. 

Der _Request_ erfolgt mit einem Datenbyte. Nachdem der Befehl ausgeführt wurde, wird das Ergebnis der Operation mit einem _Response_-Telegram beantwortet (z.B. Datenbyte = `06` für Ack, siehe Antwortcodes im eigenen Abschnitt).

Darstellungsformat:
```
                                 |<-- ALI ------>|
                                 |            |DU|
68 00 0A 00 0A 68 80 7F 06 06 01 [01 00 02 09 24 ] 3C 16
                                 [01 [Bc ] Op Btn]

Bc: Byte Count (Typ Word, Big Endian)
Op: Opcode 09h = Button Key
Btn: Tastencode 24h = 0010.0100b
        0  0  1  0  0  1  0  0
    MSB --+--+--+--*--+--+--+-- LSB
        b7 b6 b5 b4 b3 b2 b1 b0

        b7:
        b6:
        b5..b0:
          10.0100b = F4 released
          10.0011b = F3 released
          10.0010b = F2 released
          10.0001b = F1 released
          01.1001b = Cursor released

          01.0100b = F4 pressed
          01.0011b = F3 pressed
          01.0010b = F2 pressed
          01.0001b = F1 pressed

          00.1000b = C4 pressed
          00.0111b = C3 pressed
          00.0110b = C2 pressed
          00.0101b = C1 pressed
```

Beispiel F4 off:
```
68 00 0A 00 0A 68 // SD2; Länge = 10 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01    // 
00 02 // Byte Count = 2
09    // Opcode 09h (Func Key)
24    // 24h = 0010.0100b: F4 off
3C    // CheckSum8 Modulo 256 (DA incl. DU: 80..24)
16    // End Delimiter
```

Beispiel F4 on:
```
68 00 0A 00 0A 68 // SD2; Länge = 10 Byte
80 7F 06 06 01    // SDN; DA:DSAP = 0:6; SA:SSAP = 127:1 (127 = Broadcast)
01    // 
00 02 // Byte Count = 2
09    // Opcode 09h (Func Key)
13    // 13h = 0001.0011b: F3 on
2B    // CheckSum8 Modulo 256 (DA incl. DU: 80..13)
16    // End Delimiter
```

Weitere Beispiele:
```
// F1 on
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  11  29 16
// F1 off
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  21  39 16
// F2 on
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  12  2A 16
// F2 off
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  22  3A 16
// F3 on
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  13  2B 16
// F3 off
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  23  3B 16
// F4 on
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  14  2C 16
// F4 off
send>68 00 0A 00 0A 68 80 7F 06 06 01  01 00 02 09  24  3C 16
```

## <a name="10"></a>Uhrzeit/Datum `10`
Der _Opcode_ `10` _Date Time_ liest die aktuelle Uhrzeit, das Datum und die Sommer-/Winterzeit aus der Hardware-Uhr der _LOGO!_ Keinsteuerung aus. Der _Request_ erfolgt ohne Daten. Das Ergebnis der Operation wird von der _LOGO_ Steuerung mit einem _Response_-Telegram beantwortet.

Beispiel:
```
send>68 00 09 00 09 68 80 7F 06 06 01
01 00 01 10
1E 16
recv<68 00 10 00 10 68 7F 80 06 06 01
01 00 08 10
10 05 12 08 02 03 01
5A 16
```

Darstellungsformat:
```
                                 |<-- ALI -->|
68 00 09 00 09 68 80 7F 06 06 01 [01 00 01 10] 1E 16
                                 [01 [Bc ] Op]

                                 |<-- ALI ----------------------->|
                                 |            |<--- DU ---------->|
68 00 0A 00 0A 68 7F 80 06 06 01 [01 00 08 10 10 05 12 08 02 03 01] 5A 16
                                 [01 [Bc ] Op DD MM YY mm hh Wd SW]

Bc: Byte Count (Typ Word, Big Endian)
Op: Opcode 10h = Date Time
DD: Tag; Wertebereich 01..1F (1 bis 31)
MM: Monat; Wertebereich 01..0C (1 bis 12)
YY: Jahr; Wertebereich beginnend bei 08 (entspricht 2008)
mm: Minuten; Wertebereich 01..3B (1 bis 59)
hh: Stunden; Wertebereich 00..17 (0 bis 23)
Wd: Wochentag; Wertebereich 00..06 (So bis Sa)
SW: 01 = Sommerzeit; 00 = Winterzeit
```

Beispiel Response (nur DU):
```
01    //
00 08 // Byte Count = 8
10    // Opcode 10h (Clock)
04    // Tag 4
06    // Monat Juni
12    // Jahr 2018
13    // Minute 19
16    // Stunde 22 
02    // Dienstag
01    // Sommerzeit
```

## <a name="18"></a>Display Update `18`

Beispiel Response (nur DU, Meldetext fest, 2 Meldetexte, Block B002):
```
      |<-- DU --------------------------------------- ...
0000  00 00 00 02 00 00 00 00 00 00 00 02 00 00 00 00
0010  00 00 00 02 00 00 00 00 00 00 00 01 00 00 00 00
0020  00 00 00 00 80 81 ff ff ff ff ff ff ff ff ff ff
0030  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
0040  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
0050  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
0060  ff ff ff ff 00 00 ff 00
```

## <a name="21"></a>Parametrierung `21`
Der Befehl _Set Parameter_ `21` dient dem Einstellen der Parameter der Blöcke. Es können unter anderem Verzögerungszeiten, Schaltzeiten, Schwellwerte, Überwachungszeiten und Ein- und Ausschaltschwellen geändert werden, ohne das das Schaltprogramm geändert werden muss. 

Vorteil: In der Betriebsart _Parametrieren_ arbeitet die _LOGO!_ Kleinsteuerung das Schaltprogramm weiter ab. Sobald die geänderten Parameter (in der Betriebsart _Parametrieren_) mit der Taste _OK_ quittiert wurden, wird der Befehl _Set Parameter_ gesendet. Nachdem der Befehl ausgeführt wurde, wird das Ergebnis der Operation mit einem _Response_-Telegram (üblicherweise mit dem Datenbyte = `06` für Ack) beantwortet. 

__Hinweis:__ Das erfolgreiche Ändern von Parametern setzt voraus, dass die für den Block im Schaltprogramm eingestellte Schutzart dies erlaubt (Parameterschutz = `+`). 

Beispiel:
```
send>68 00 37 00 37 68 80 7F 06 06 01
01 00 2F 21
00 0F 00 FC 00 14 CE 04 EC 04 FF FF FF FF FF FF
FF FF 7F 00 00 00 00 00 21 40 0F 80 00 80 00 00
21 40 0F 80 2C 81 00 00 21 40 0F 80 89 83
BE 16
recv<68 00 0A 00 0A 68 7F 80 06 06 01
01 00 02 21
06
36 16
```

Darstellungsformat (Request, nur ALI):
```
|<-- ALI ----------------------------------------------- ...
|             |<-- DU ---------------------------------- ...
01  00 2F  21  00 0F   00 FC   00 14   CE 04 EC 04 FF FF ...
01 [00 2F] 21 [00 0F] [00 FC] [00 14] [CE 04 EC 04 FF FF ...
01 [Bc   ] Op [Bl   ] [Po   ] [Pc   ] [Dn ...

Bc: Byte Count (Typ Word, Big Endian)
Op: Opcode 21h = Set Parameter
Bl: Blocknummer (Typ Word, Big Endian)
Po: Zeigeradresse (Typ Word, Big Endian)
Pc: Anzahl Parameter Bytes (Anzahl ist inkl. Feldlänge von Pc)
Dn: Datenbyte an Stelle n (n = 3..Pc)
```

## <a name="30"></a>Adressierung `30`
Der Befehl _Addressing_ `30` benennt die indizierten Speicherbereiche (Register) vom Programmzeilenspeicher für die Ausgänge, Merker und Funktionsblöcke. Das Ziel eines Registers ist eine Speicherzelle im Programmzeilenspeicher. Die von der _LOGO!_ Kleinsteuerung zurückgemeldeten Register werden vom _TD_ genutzt, um auf die Struktur des Schaltprogramms zu schließen, welche über den _Opcode_ `40` (und folgend) abgefragt werden. Die Position ergibt sich aus den Inhalt des jeweiligen Registers, das auf den Speicherort vom Programmzeilenspeicher verweist. 

Der _Opcode_ `30` gibt bei einer _LOGO!_ __0BA6__ 420 Bytes Netto-Daten zurück. Die ersten 20 Bytes verweisen auf (weitere) 10*20 Bytes für Ausgänge und Merker (siehe Tabelle folgend). Die nächsten 400 Bytes verweisen auf die 200 Funktionsblöcke im Programmzeilenspeicher. Der Verweis wird als 16 Bit-Offset-Adresse (Little Endian) dargestellt. 

Beispiel:
```
recv<68 01 AD 01 AD 68 7F 80 06 06 01
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

Darstellungsformat Response (nur DU, 20 Bytes):
```
       |<-- DU --------------------------------------- ...
0000   00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00
0010   A0 00 B4 00 .. .. ..

             |<----------------------- 20 Bytes ---------------------->|
HEX (Lo Hi): 00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
HEX (Hi,Lo): 00,00 00,14 00,28 00,3C 00,50 00,64 00,78 00,8C 00,A0 00,B4
Dezimal:     00    20    40    60    80    100   120   140   160   180
Speicherbedarf: 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20
```
>Abb: Register Ausgänge und Merker

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
>Tab: Übersicht Register Ausgänge und Merker

Unter Verwendung des ausgelesen Wertes ist es möglich, den Block im Speicherbereich anzusprechen. Das Register für Block B001 ist an Stelle `21..22` zu finden, der Block B002 an Stelle `23..24`, Block B003 an `25..26`, usw. Der Wert `FFFF` bedeutet, dass der Block nicht im Schaltprogramm verwendet wird.

Darstellungsformat Response (nur DU, Bytes > 20):
```
   ... -- DU ----------------------------------------- ...
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
>Abb: Register für Funktionsblöcke

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
>Tab: Übersicht Register Funktionsblöcke

\*) Block-Nr. B019 wird im Schaltprogramm nicht verwendet!

## <a name="3c"></a>Verweis auf Blocknamen `3c`
Es können maximal 100 Blöcke einen Blocknamen erhalten.

Beispiel:
```
send> 68 00 09 00 09 68 80 7F 06 06 01
01 00 01 3C
4A 16
recv< 68 00 0C 00 0C 68 7F 80 06 06 01
01 00 04 3C
02 0A 0F
68 16
```

Darstellungsformat:
```
                                 |<-- ALI -->|
68 00 09 00 09 68 80 7F 06 06 01 [01 00 01 3C] 4A 16
                                 [01 [Bc ] Op]

                                 |<-- ALI ------------ ...
                                 |            |<--DU-- ...
68 00 0C 00 0C 68 7F 80 06 06 01 [01 00 06 3C 02 0A 0F ...
                                 [01 [Bc ] Op Pc B1 B2 ...

Bc: Byte Count (Typ Word, Big Endian)
Op: Opcode 3Ch = Block Name Reference
Pc: Anzahl Parameter Bytes, Wertebereich 01..64h
Bn: Block Nummer an Stelle n (n = 1..Pc)
```

Position | HEX | DEC | Block
---------|-----|-----|------
1        | 0A  | 10  | B001
2        | 0F  | 15  | B006
>Tab: Auswertung Beispiel _Verweis Blocknamen_

## <a name="3d"></a>Blocknamen `3d`
In LOGO!Soft Comfort können für eine _LOGO!_ Kleinsteuerung der Generation __0BA6__ für bis zu 100 Blöcke achtstellige Blocknamen vergeben werden. Die maximale Länge eines Blocknamens beträgt 8 Byte, bei weniger als 8 Byte wird der Text mit `00` terminiert und mit `FF` aufgefüllt.

Beispiel:
```
send> 68 00 09 00 09 68 80 7F 06 06 01
01    //
00 01 // Byte Count = 1
3D    // Opcode 3Dh (Block Name Memory)
4B 16
recv< 68 00 09 00 09 68 80 7F 06 06 01
01                      //
00 09                   // Byte Count = 9
3D                      // Opcode 3Dh (Block Name Memory)
44 69 73 70 6C 61 79 00 // ACSII = 'Display'\0
29 16
```

## <a name="40"></a>Klemmenspeicher `40`
Als Klemme werden alle Anschlüsse und Zustände bezeichnet. Hierzu zählen Digitaleingänge, Analogeingänge, Digitalausgänge, Analogausgänge, Merker (inkl. Anlaufmerker), Analoge Merker, Schieberegisterbits, Cursortasten, Pegel und die Offenen Klemmen. Klemmen, die aufgrund eines Verknüpfungseinganges ein Speicherplatz besitzen, sind die Ausgänge _Q1_ bis _Q16_, _AQ1_ und _AQ2_, die Merker _M1_ bis _M24_ und _AM1_ bis _AM6_, sowie die 16 unbeschaltete Ausgänge _X1_ bis _X16_.

Die Verknüpfungen im Schaltprogramm auf den Eingang einer Ausgangsklemme oder eines Merkes werden mittels des Befehls `40` vom _TD_ abgefragt. 

Beispiel:
```
send> 68 00 09 00 09 68 80 7F 06 06 01
01 00 01 40
4E 16
recv< 68 00 D3 00 D3 68 7F 80 06 06 01 
01 00 CB 40
0000   80 00 0A 80 0B 80 A2 00 A3 00 FF FF FF FF FF FF
0010   FF FF FF FF 80 00 FF FF FF FF FF FF FF FF FF FF
0020   FF FF FF FF FF FF FF FF 80 00 FF FF FF FF FF FF
0030   FF FF FF FF FF FF FF FF FF FF FF FF 80 00 FF FF
0040   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0050   80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0060   FF FF FF FF 80 00 FF FF FF FF FF FF FF FF FF FF
0070   FF FF FF FF FF FF FF FF 80 00 FF FF FF FF FF FF
0080   FF FF FF FF FF FF FF FF FF FF FF FF 80 00 FF FF
0090   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00A0   80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00B0   FF FF FF FF 80 00 FF FF FF FF FF FF FF FF FF FF
00C0   FF FF FF FF FF FF FF FF 00 20
E6 16
```

Das Format ist einheitlich und ist als vielfache von 20 Bytes = 2 Bytes `80 00` + 16 Bytes `<Daten>` + 2 Bytes `FF FF` abgelegt.

Position   | Anz | Beschreibung
-----------|-----|------------------------------------
0000..0027 | 40  | Digitaler Ausgang 1-16
0028..0063 | 60  | Merker 1-24
0064..0077 | 20  | Analogausgang 1-2; Analogmerker 1-6
0078..009F | 40  | offener Ausgang 1-16
00A0..00C7 | 40  | (Reserve ??)
00C8..00C9 | 2   | (End of Record ??)
>Tab: Adressübersicht Ausgänge und Merker

Auswertung (nur DU):
```
    |<-- DU --------------------------------------------------- ...
    80 00 0A 80 0B 80 A2 00 A3 00 FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    00 20
... --->|


    |<-- DU ----------------------------------------------------- ...
    80 00 [0A 80 0B 80 A2 00 A3 00 FF FF FF FF FF FF FF FF] FF FF
          [1a 1b ...                             ... 8a 8b]
    :
    :
    80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
    00 20
... --->|
    [EOR]
```

Nicht benutzte Anschlüsse (freie Eingänge) im Schaltprogramm werden mit `FFFF` angezeigt. 

```
Na: Eingang, abhängig von b7
Nb: BIN MSB --+--+--+--*++++ LSB
            b7 b6 b5 b4 0000

    b7 = 0, Xa = Konstante oder Klemme
    b7 = 1, Xa = Blocknummer
    b6 = 0
    b5 = 0
    b4 = 0

EOR: End of Record
```

Na Nb: N = Element 1-8

## <a name="41"></a>Programmzeilenspeicher `41..4x`
Der Programmzeilenspeicher ist Teil des Schaltprogramms und wird für die Parametrisierung und korrekten Darstellung der Variablen im Meldetext vom Text-Display ausgelesen. Es werden nicht alle 200 Blöcke am Stück vom _TD_ ausgelesen. Vielmehr werden die einzelen aufeinander folgenden Speicherbereiche mittels der Opcodes `41..4x` abgefragt. 

Beispiel:
```
send> 68 00 09 00 09 68 80 7F 06 06 01
01 00 01 41
4F 16
recv< 68 01 0F 01 0F 68 7F 80 06 06 01
01 01 07 41
0000   00 C8 00 0C 01 00 0E 80 10 80 14 80 1D 80 FF FF 
0010   00 D4 00 0C 01 00 0E 80 11 80 19 80 FF FF FF FF 
0020   00 E0 00 0C 01 00 0E 80 12 80 1A 80 FF FF FF FF
0030   00 EC 00 0C 01 00 0E 80 13 80 1B 80 FF FF FF FF
0040   00 F8 00 04 03 00 00 00 00 FC 00 14 24 40 CE 04
0050   EC 04 FF FF FF FF FF FF FF FF 7F 00 00 00 00 00
0060   01 10 00 08 21 40 0F 80 00 80 00 00 01 18 00 08
0070   21 40 0F 80 2C 81 00 00 01 20 00 08 21 40 0F 80
0080   89 83 00 00 01 28 00 08 21 40 0F 80 DC 85 00 00
0090   01 30 00 04 03 00 15 80 01 34 00 08 21 40 10 80
00A0   2C 81 00 00 01 3C 00 08 21 40 11 80 58 82 00 00
00B0   01 44 00 08 21 40 12 80 58 82 00 00 01 4C 00 08
00C0   21 40 13 80 2C 81 00 00 01 54 00 04 03 00 16 80
00D0   01 58 00 04 03 00 17 80 01 5C 00 04 03 00 18 80
00E0   01 60 00 0C 02 00 1F 80 1E 80 FF FF FF FF FF FF
00F0   01 6C 00 10 35 40 81 00 64 00 C8 00 1E 00 00 00
0100   00 00 00 00 00 00
0C 16
```

Für den Aufbau von DU gibt es mehrere Randbedingungen:
* Die ersten beide Bytes enthalten den Adressregister im Programmzeilenspeicher. Die Registerwerte werden vorab vom Textdisplay mit einem eigenem Befeh (Opcode `30`) abgefragt. 
* Im folgenden Byte (Offset 02h) steht die Länge des Blocks im Speicher. Der Wert variiert dabei im Abhängigkeit von der Funktion des Blocks.
* Die Formatlänge der nachfolgenden Daten ist variabel, durch 4 teilbar, daher ggf. mit Füllbytes (Padding) aufgefüllt und darf 252 Bytes nicht überschreiten. 

Auch ohne Kenntnis der Bedeutung der Datenbytes lässt sich die Struktur in DU gut erkennen:
```
      |<-- DU --------------------------------------- ...
      |<-- B1 ------------------------------------->|
0000  00 C8 00 0C 01 00 0E 80 10 80 14 80 1D 80 FF FF
      [Reg] [Pc ] Fc Pa [Dn.........................]

      |<-- B2 ------------------------------------->|
0010  00 D4 00 0C 01 00 0E 80 11 80 19 80 FF FF FF FF
      [Reg] [Pc ] Fc Pa [Dn.........................]

      |<-- B3 ------------------------------------->|
0020  00 E0 00 0C 01 00 0E 80 12 80 1A 80 FF FF FF FF
      [Reg] [Pc ] Fc Pa [Dn.........................]

      |<-- B4 ------------------------------------->|
0030  00 EC 00 0C 01 00 0E 80 13 80 1B 80 FF FF FF FF
      [Reg] [Pc ] Fc Pa [Dn.........................]

      |<-- B5 ------------->| |<-- B6 --------------- ...
0040  00 F8 00 04 03 00 00 00 00 FC 00 14 24 40 CE 04
      [Reg] [Pc ] Fc Pa [Dn ] [Reg] [Pc ] Fc Pa [Dn..

  ... -- B6 ----------------------------------------- ... 
0050  EC 04 FF FF FF FF FF FF FF FF 7F 00 00 00 00 00
      ..............................................]

  ... -- B6 --------------------------->| |<-- B7 --- ...
0060  01 10 00 08 21 40 0F 80 00 80 00 00 01 18 00 08  
      [Reg] [Pc ] Fc Pa [Dn.............] [Reg] [Pc ]

  ... -- B7 --------------->| |<-- B8 --------------- ...
0070  21 40 0F 80 2C 81 00 00 01 20 00 08 21 40 0F 80

  ... -- B8 --->| |<-- B9 ------------------------->|
0080  89 83 00 00 01 28 00 08 21 40 0F 80 DC 85 00 00

      |<-- B10 ------------>| |<-- B11 -------------- ...
0090  01 30 00 04 03 00 15 80 01 34 00 08 21 40 10 80

  ... -- B11 -->| |<-- B12 ------------------------>|
00A0  2C 81 00 00 01 3C 00 08 21 40 11 80 58 82 00 00

      |<-- B13 ------------------------>| |<-- B14 -- ...
00B0  01 44 00 08 21 40 12 80 58 82 00 00 01 4C 00 08

  ... -- B14 -------------->| |<-- B15 ------------>|
00C0  21 40 13 80 2C 81 00 00 01 54 00 04 03 00 16 80

      |<-- B16 ------------>| |<-- B17 ------------>|
00D0  01 58 00 04 03 00 17 80 01 5C 00 04 03 00 18 80

      |<-- B18 ------------------------------------>|
00E0  01 60 00 0C 02 00 1F 80 1E 80 FF FF FF FF FF FF

      |<-- B19 -------------------------------------- ...
00F0  01 6C 00 10 35 40 81 00 64 00 C8 00 1E 00 00 00

  ... -- B19 -------->|
0100  00 00 00 00 00 00

Bn: Block an Stelle n (n = 1 bis max. 200)
Reg: Registerwert (Typ Word, Big Endian), siehe auch Opcode 30
Pc: Anzahl Parameter Bytes (inkl. Fc und Pa)
Fc: Funktions-Code
      Wert < 20h: GF, siehe Liste Grundfunktionen
      Wert > 20h: SF, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter, immer 00 bei GF
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

Dn: Datenbyte an Stelle n (n = 1..Pc-2), funktionabhängig
```

## <a name="5b"></a>Verweis auf Meldetexte `5b`
Es können maximal 50 Meldetext vergeben werden. Jeder Verweis auf ein Meldetext ist 2 Bytes lang und ist nennt zudem den Zeichensatz 1 oder den Zeichensatz 2. 

Darstellungsformat:
```
send> 68 00 09 00 09 68 80 7F 06 06 01
01    //
00 01 // Byte Count = 1
5B    // Opcode 5Bh (Message Text Reference)
69 16 
recv< 68 00 6D 00 6D 68 7F 80 06 06 01
01    //
00 65 // Byte Count = 101
5B    // Opcode 5Bh (Message Text Reference)

0000   00 01 01 01 FF FF FF FF FF FF FF FF FF FF FF FF
0010   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0020   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0030   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0040   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0050   FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
0060   FF FF FF FF

70 16
```

Auswertung (Anhand der ersten 16 Zeichen von DU):
```
       |<-- DU --------------------------------------- ...
0000   00 01 01 01 FF FF FF FF FF FF FF FF FF FF FF FF

|<-- DU ----------------------- ...
[00 01] [01 01] [FF FF] [FF FF] ...
[R1 C1] [R2 C2] [R3 C3] [R4 C4] ...

Rn: Verweis Meldetext
    00-31h = 0-49d = Meldetext 1 bis 50
    FF = nicht verwendet
Cn: Zeichensatz vom Meldetext
    01 = Zeichensatz 1
    02 = Zeichensatz 2

Position n (n = 1..50)
```

## <a name="61"></a>Meldetext `61`
Jeweils ein Meldetext belegt 128 Bytes: jeweils 4 Zeilen a 24 Bytes für `<Daten/Zeichen>` zzgl. 2 Bytes `<Header-Daten>` und 6 Bytes `00`.

Einstellungen für Meldetexte:
* __En__: Ein Wechsel des Zustands von 0 auf 1 am Eingang
* __P__: Priorität des Meldetexts 0..127, Meldeziel, Tickerart, Ticker-Einstellungen
* __Ack__: Quittierung des Meldetexts
* __Par__: Parameter oder Aktualwert einer bereits programmierten anderen Funktion
* __EnTime__: Anzeige der Uhrzeit zum Zeitpunkt des Signalzustandswechsels
* __EnDate__: Anzeige des Datums zum Zeitpunkt des Signalzustandswechsels
* __E/A-Zustandsnamen__: Anzeige des Namens eines digitalen Eingangs- oder Ausgangszustands
* __Analogeingang__: Anzeige des (nach Analogzeit) aktualisierten Analogeingangswerts 
* __Q__: bleibt gesetzt, solange der Meldetext ansteht


Das Folgendes Beispiel zeigt die Abfrage und die Antwort zwei aufeinander folgende Meldetexte:
```
send> 68 00 09 00 09 68 80 7F 06 06 01
01    //
00 01 // Byte Count = 1
61    // Opcode 61h (Message Texts)
6F 16
recv< 68 01 09 01 09 68 7F 80 06 06 01
01    //
01 01 // Byte Count = 257
61    // Opcode 61h (Message Texts)

0000   43 31 80 20 6F 6E 20 20 20 20 20 20 20 20 20 20  // Zeile 1 = 'C1^ on ...
0010   20 20 20 20 20 20 20 20 20 00 00 00 00 00 00 00
0020   20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20  // Zeile 2
0030   20 20 20 20 20 20 20 20 00 00 00 00 00 00 00 00
0040   20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20  // Zeile 3
0050   20 20 20 20 20 20 20 20 00 00 00 00 00 00 00 00
0060   20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20  // Zeile 4
0070   20 20 20 20 20 20 20 20 00 00 00 00 00 00 00 00

0080   43 32 81 20 6F 6E 20 20 20 20 20 20 20 20 20 20  // Zeile 1 = 'C2v on ...
0090   20 20 20 20 20 20 20 20 20 00 00 00 00 00 00 00
00a0   20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20  // Zeile 2
00b0   20 20 20 20 20 20 20 20 00 00 00 00 00 00 00 00
00c0   20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20  // Zeile 3
00d0   20 20 20 20 20 20 20 20 00 00 00 00 00 00 00 00
00e0   20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20  // Zeile 4
00f0   20 20 20 20 20 20 20 20 00 00 00 00 00 00 00 00

14 16
```

Auswertung einer Zeile (nur DU):
```
       |<-- DU --------------------------------------- ...
0000   43 31 80 20 6F 6E 20 20 20 20 20 20 20 20 20 20
0010   20 20 20 20 20 20 20 20 20 00 00 00 00 00 00 00

|<-- DU ----------------------------------------------------------------- ...
[43 31 80 20 6F 6E 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20]
[Txt                                                                    ] 

... -- DU -------------------- ...
   [20 00] [00 00 00 00 00 00]
   [Pa   ] [Dn               ]

Txt: maximal 24 ASCII Zeichen, aufgefüllt mit Leerzeichen (20h)
    Sonderzeichen:
      80: Pfeil nach oben '^'
      81: Pfeil nach unten 'v'
Pa: Parameter 
Dn: Datenbyte an Stelle n (n = 1..6)
```

----------

# Anhang

## <a name="fcs"></a>Prüfsumme
Jedem Telegramm wird eine 8-Bit-Prüfsumme hinzugefügt. Alle Datenbytes, zum Teil auch Bytes des Rahmens, werden Modulo-256 aufsummiert. Modulo-256 bedeutet dabei, dass bei jeder Summierung der Übertrag in das Bit mit der Wertigkeit 256 einfach ignoriert wird. Die entstandene 8 Bit lange Prüfsumme wird vom Sender ins Telegramm eingefügt. Der Empfänger prüft die empfangenen Daten und führt die selbe Addition durch. Die Prüfsumme muss gleich sein.

Die Implementierung ist einfach, da nur eine 8-Bit-Prüfsumme für eine Folge von hexadezimalen Bytes berechnet werden muss. Wir verwenden eine Funktion `F(bval, cval)`, die ein Datenbyte und einen Prüfwert eingibt und einen neu berechneten Prüfwert ausgibt. Der Anfangswert für `cval` ist 0. Die Prüfsumme kann mit der folgenden Beispielfunktion (in _C_-Sprache) berechnet werden, die wir für jedes Byte des Datenfelds wiederholt aufrufen. Die 8-Bit-Prüfsumme ist das Zweierkomplement der Summe aller Bytes.

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

