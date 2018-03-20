# LOGO! Adressdekodierung für __0BA5__

Ausgabe Aj

März 2018

## Vorwort
Diese Anleitung ist für Personen, die mit einer Siemens (TM) LOGO! SPS über die PG-Schnittstelle kommunizieren. Die PG-Schnittstelle verwendet ein undokumentiertes Protokoll zum Programm laden, lesen und zur Diagnose. Dieses Handbuch beschreibt, wie die Adressierung in einer _LOGO!_ SPS, Version __0BA5__ erstellt ist, um z.B. mit Hilfe des PG-Protokolls darauf zuzugreifen. 

Die hier beschriebenen Beispiele sind unverbindlich und dienen der allgemeinen Information über die Addressierung innerhalb von _LOGO!_. Die eigene Kleinsteuerung kann sich hiervon unterscheiden.

Für einen ordnungsgemäßen Betrieb ist der Benutzer selbst verantwortlich. Verweisen möchte ich auf die jeweils gültigen Handbücher und Vorgaben und systembezogenen Installationsvorschriften vom Hersteller.

Irrtum und Änderung vorbehalten.

_Siemens_ und _LOGO!_ sind eingetragene Marken der Siemens AG.

## Verwendete oder weiterführende Publikationen
Wertvolle Informationen finden Sie in den folgenden Veröffentlichungen:
  * [LOGO! Handbuch Ausgabe 05/2006](http://www.google.de/search?q=A5E00380834-02), Bestellnummer 6ED1050-1AA00-0AE6
  * [SPS Grundlagen](http://www.sps-lehrgang.de/ "SPS Lehrgang")

Einzelheiten zum _LOGO!_-Adresslayout finden Sie in den folgenden Veröffentlichungen:
  * neiseng @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") dekodierte den Datenadressraum einer __0BA5__ (@post 42)

## Inhalt

  * [Kapitel 1 - Architektur](#Kapitel1)
    * Systemarchitektur
    * Speicherarchitektur
    * [Adressübersicht](#Adresslayout)
  * [Kapitel 2 - Parameterspeicher](#Kapitel2)
    * [Displayinhalt nach Netz-Ein](#0552)
    * [Analogausgang im STOP-Modus](#0553)
    * [Programmname](#0570)
    * [Verweis auf Blocknamen](#05C0)
    * [Blockname](#0600)
    * [Textfeld](#0800)
    * [Version und Firmware](#1F02)
    * [Passwort vorhanden](#48FF)
    * [Echtzeituhr](#FB00)
  * [Kapitel 3 - Klemmenspeicher](#Kapitel3)
    * [Konstanten und Klemmen - Co](#Co)
    * [Verweis auf Ausgänge, Merker](#0C00)
    * [Digitalausgänge - Q](#0E20)
    * [Merker - M](#0EC0)
    * [Analogausgänge, Analoge Merker - AQ, AM](#0E84)
  * [Kapitel 4 - Programmzeilenspeicher](#0EE8)
    * Blöcke und Blocknummern
    * [Verweis auf Blöcke](#0C14)
    * [Grundfunktionen - GF](#GF)
    * [Sonderfunktionen - SF](#SF)
    * Grundwissen Sonderfunktionen
    * [Einschaltverzögerung](#SF21)
    * [Ausschaltverzögerung](#SF22)
    * [Stromstoßrelais](#SF23)
    * [Wochenschaltuhr](#SF24)
    * [Selbsthalterelais](#SF25)
    * [Speichernde Einschaltverzögerung](#SF27)
    * [Vor-/Rückwärtszähler](#SF2B)
    * [Asynchroner Impulsgeber](#SF2D)
    * [Analogwertüberwachung](#SF39)
  * [Kapitel 5 - Sonstiger Speicher](#Kapitel5)
    * [Speicherbereich 1E00](#1E00)
    * [Speicherbereich 2000](#2000)
    * Speicherbereiche 0522, 055E-5F
    * Erfassbare Daten mit Befehl `55`
  * [Anhang](#Anhang)
    * [0BA5 Ressourcen](#Ressourcen)
    * Verwendete Abkürzungen

----------

# <a name="Kapitel1"></a>Kapitel 1 - Architektur

## Systemarchitektur
Das _LOGO!_ Basismodul ist das Herzstück. In dem Basismodul wird das Schaltprogramm sequentiell und zyklisch abgearbeitet, sowie alle logischen Funktionen ausgeführt. Die Basismodul besitzt eine Verbindungsschnittstelle zum Programmiergerät (PC/PG), zu den installierten Ein-/Ausgängen (I/Q) und kommuniziert über eine BUS-Verbindung mit angeschlossenen Erweiterungsmodulen. 

Innerhalb des Basismoduls sind verschiedene Systembereiche untergebracht, damit die verschieden Vorgänge ablaufen können. Im folgenden Bild ist der Aufbau schematisch dargestellt.
```
.------------------------------------.
| PE      O  O  O  O  O  O  O  O     |
+------------------------------------+
|                 PG-Schnittstelle ###
| .------------.----------.--------. |
| | Steuereinh.| Speicher | Zähler | |
| '-----o------'-----o----'----o---' |
|  =====|=====Busverbindung====|===###
| .-----o------.-----o----.----o---. |
| | Rechenwerk | Merker   | Zeiten | |
| '------------'----------'--------' |
+------------------------------------+
| PA      O  O  O  O  O  O  O  O     |
'------------------------------------'
```

Zu den Systembereichen eines Basismoduls gehören:
-	Steuereinheit
-	Rechenwerk
-	Speicher
-	Prozessabbild der Eingänge (PE)
-	Prozessabbild der Ausgänge (PA)
-	Zeiten
-	Zähler
-	Merker

### Steuereinheit
Die Steuereinheit wird verwendet, um den gesamten Ablauf innerhalb des Basismoduls zu koordinieren. Dazu gehören u.a. die Koordination der internen Vorgänge und der Datentransport.

Die Programmbefehle werden aus dem Speicher ausgelesen und Zeile für Zeile ausgeführt. Die Verarbeitung erfolgt in vier Stufen. Zuerst wird der Befehl gelesen, dann wird der Befehl entschlüsselt. Als nächstes werden die Zustände der Eingangsoperanden ausgelesen und in das Prozessabbild der Eingänge PE geschrieben, und schließlich wird der Befehl ausgeführt, wobei weitere Werte wie Zeiten, Zählern und Flags berücksichtigt werden. Als letzter Schritt wird ein Befehlszähler aktualisiert und der Zyklus beginnt erneut. Das Ergebnis der Programmbearbeitung wird in das Prozessabbild der Ausgänge PA geschrieben, die wiederum die Ausgänge neu setzen.

Die Steuereinheit wird über die Busverbindung mit den anderen Systembereichen wie Rechnwerk, Zeiten, Zähler usw. verbunden. Unmittelbar nach Anlegen der Netzspannung werden die nicht remanenten Zähler, Zeiten und Merker sowie die Prozessabbilder der Eingänge und Ausgänge zurückgesetzt.

### Rechenwerk
Der Begriff wird häufig synonym mit arithmetisch-logische Einheit (ALU) gebraucht, genau genommen stellt eine ALU jedoch lediglich die zentrale Komponente eines Rechenwerks dar, das zusätzlich aus einer Reihe von Hilfs- und rttusregistern besteht. Die ALU selbst enthält hingegen keine Registerzellen und stellt somit ein reines Schaltnetz dar.

Die ALU verknüpft zwei Binärwerte (Akku1 und Akku 2) mit gleicher Stellenzahl miteinander und stellt das Ergenis der Rechenoperation in Akku 1 zur verfügung. Es können sowohl Bit, Byte oder Wortoperationen durchgeführt werden. 

### Zeiten, Zähler und Merker
Für diese Systembereiche sind eigene Speicherbereiche vorhanden, in denen die Steuereinheit die Daten entsprechend den Datentypen ablegt. Merker sind interne Ausgänge, in die Zwischenergebnisse gespeichert werden. Auf sie kann lesend und schreibend zugegriffen werden. Merker sind flüchtig, die bei Spannungsausfall ihre Daten verlieren.

### Prozessabbild der Eingänge und Ausgänge
Die Zustände der Eingänge und Ausgänge werden in den Speicherbereichen PE und PA gespeichert. Auf diese Daten wird während der Programmbearbeitung zugegriffen. 

### Programmierschnittstelle (PG)
Die LOGO! Kleinsteuerung besitzt eine PG-Schnittstelle, um die Verbindung zum Programmiergerät/PC herzustellen. Über die Schnittstelle kann kann das Programm in das Basismodul übertragen werden. Sie dient leider nicht zum Anschluss von Erweiterungsbaugruppen oder Bedien- und Beobachtungsgeräten wie bei einer Standard SPS. 

### Bussystem
Das Bussystem kann unterteilt werden in ein Rückwandbus und Peripheriebus. Der Rückwandbus ist ein interner Bus der optimiert ist für die interne Kommunikation im Basismodul. Der Peripheriebus wird auch als P-Bus bezeichnet. Hierüber läuft der Datenverkehr zwischen dem Basismudul und den Erweiterungsmodulen. An der rechten Seite vom Basismodul befindet dich die Schnittstelle für den P-Bus. Über Busverbinder werden die Erweiterungsmodule an den P-Bus vom Basismmoudul verbunden. 

## Speicherarchitektur
Der Speicherbereich innerhalb eines Basismoduls ist in mehrere Bereiche aufgeteilt, wobei jeder Speicherbereich eigene Aufgaben erfüllt. Vereinfacht gesagt besteht der Speicher im Basismodul aus dem Systemspeicher, dem Ladespeicher und dem Arbeitsspeicher.

Alle Konfigurationsdaten sind im Basismodul gespeichert. Unter anderem das Anwenderprogramm, sowie die Symboltabelle und evtl. noch Meldetexte und Blocknamen. Das Anwenderprogramm besteht aus Steuerungsbefehlen und Steuerungsdaten, die in Programmbausteinen und Datenbausteinen untergebracht sind. 

Zusätzlich ist die Firmware mit untergebracht. Die Firmware sorgt dafür, dass das Programm in der korrekten Reihenfolge abgearbeitet wird. Für die Firmeare ist ein eigener Festwertspeicher im Basismoduls vorhanden. 

### <a name="Festwertspeicher"></a>Festwertspeicher
Der Festwertspeicher ist ein Nur-Lese-Speicher (engl. Read Only Memory, kurz ROM). Hierauf befindet sich die _LOGO!_ Firmware, welche vom Hersteller Siemens stammt. Read Only deshalb, weil der Speicher nicht gelöscht oder geändert werden kann und zudem nicht flüchtig ist. Bei Spannungsausfall bleiben die Daten erhalten. 

### Ladespeicher 
Über die Schnittstelle zum Programmiergerät werden die gesamten Schaltdaten inkl. der Konfiguration in den Ladespeicher geladen. Der Ladespeicher kann zusätzölich auf sogenannte Memory Cards gesichert werden. Die Daten bleiben auch bei Spannungsausfall erhalten. 

### Arbeitsspeicher 
Beim Arbeitsspeicher (engl. Random Access Memory, kurz RAM) handelt es sich um einen flüchtiger Speicher, d.h. der Inhalt geht nach einem Spannungsausfall verloren. Er ist als ein Schreib-/Lesespeicher konzipiert. Vom Ladespeicher werden die ablaufrelevanten Teile des Programms in den Arbeitsspeicher geladen. Dazu zählen insbesondere der Klemmenspeicher und Programmzeilenspeicher (vergl. S7 Programmbausteine) sowie die Speicherbereiche für Passwort, Programmname, Textboxen und Blocknamen (vergl. S7 Datenbausteine). 

### Systemspeicher 
Im Systemspeicher werden die Zustände der Eingänge und Ausgänge über das Prozessabbild (PE und PA), die Zeiten, Zähler, Merker und der Datenstack gespeichert. 

### Adressierung
_LOGO!_ __0BA5__ nutzt eine 16-Bit-Adressierung. Vereinfacht dargestellt bedeutet dies, dass die Speicherarchitektur so ausgelegt ist, dass jede Speicherstelle duch einen 16Bit-Zeiger (also 2 Byte) direkt addressiert werden kann. Die _LOGO!_ Kleinsteuerung __0BA5__ nutzt teilweise eine Segmentierung, sodas auch 8Bit-Zeiger (Verweise) zu Anwendung kommen, um eine Speicherstelle zu adressieren. 

### Speichereinheit
Die kleinste adressierbare Einheit (Speicherstelle) ist ein Byte. Es besteht aus 8 Bits und sein Inhalt wird hier vorwiegend mit zwei hexadezimalen Ziffern angegeben, wobei jede Ziffer für 4 Bits entsprechend einem Halbbyte steht. Das Halbbyte wird hier teilweise auch als [Nibble](#http://de.wikipedia.org/wiki/Nibble) bezeichnet. Es umfasst eine Datenmenge von 4 Bits. 

### Byte-Reihenfolge
Die Byte-Reihenfolge im _LOGO!_ ist [Little-Endian](#http://de.wikipedia.org/wiki/Byte-Reihenfolge), sprich das kleinstwertige Byte wird an der Anfangsadresse gespeichert bzw. die kleinstwertige Komponente zuerst genannt.

### Bitdarstellung
Bei Bitdarstellungen werden die Bits innerhalb einer Binärzahl nach [LSB-0](#http://de.wikipedia.org/wiki/Bitwertigkeit) nummeriert, d.h. gemäß ihrer absteigenden Wertigkeit (gelesen von links nach rechts) ist das Bit0 (= das Bit Index 0) das niedrigstwertige. 

## <a name="Adresslayout"></a>Adressübersicht

### Parameter
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
|             | 0522        | 1     | W |                                                        |
|             | [0552](#0552)        | 1     |   | Displayinhalt nach Netz-Ein                            |
| 05 53 00 05 | [0553](#0553) - 0558 | 5     |   | Einstellung des Analogausgangs im Betriebszustand STOP |
|             | 055E        | 1     |   |                                                        |
|             | 055F        | 1     |   |                                                        |
| 05 66 00 0A | 0566 - 0570 | 10    |   | Passwortspeicherbereich                                |
| 05 70 00 10 | [0570](#0570) - 0580 | 16    |   | Programmname                                           |
|             | 0580 - 05C0 | 64    |   | = 0 (64 = 0040h)                                       |

### Textbausteine
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 05 C0 00 40 | [05C0](#05C0) - 0600 | 64    |   | Verweis auf Blockname                                  |
| 06 00 02 00 | [0600](#0600) - 0800 | 512   |   | Blocknamen 8 Zeichen                                   |
| 08 00 02 80 | [0800](#0800) - 0A80 | 640   |   | 10 Meldetexte; jeweils 64 Bytes pro Textfeld           |
|             | 0A80 - 0C00 | 384   |   | = 0 (384 = 0180h)                                      |

### Indirekte Adressierung
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 0C 00 00 14 | [0C00](#0C00) - 0C14 | 20    |   | Verweis auf Ausgänge, Merker (0E20 - 0EE8)             |
| 0C 14 01 04 | [0C14](#0C14) - 0D18 | 260   |   | Verweis auf Programmzeilenspeicher (130 Blöcke)              |
|             | 0D18 - 0E20 | 264   |   | = 0 (264 = 0108h)                                      |

### Schaltprogramm
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 0E 20 00 28 | [0E20](#0E20) - 0E48 | 40    |   | Digitalausgänge Q1 bis Q16                             |
| 0E 48 00 3C | [0E48](#0E48) - 0E84 | 60    |   | Merker M1 bis M24                                      |
| 0E 84 00 14 | [0E84](#0E84) - 0E98 | 20    |   | Analogausgang AQ1, AQ2 / Analoge Merker AM1 bis AM6    |
| 0E 98 00 28 | [0E98](#0E98) - 0EC0 | 40    |   | Offene Klemme X1 bis X16                               |
| 0E C0 00 28 | 0EC0 - 0EE8 | 40    |   |                                                        |
| 0E E8 07 D0 | [0EE8](#0EE8) - 16B8 | 2000  |   | Programmzeilenpeicher                                  |

### Firmware
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
|             | 1F00        | 1     |   |                                                        |
|             | 1F01        | 1     |   |                                                        |
| 02 1F 02    | [1F02](#1F02)        | 1     | R | Ident Nummmer                                          |
| 02 1F 03    | [1F03](#1F02) - 1F09 | 6     | R | Revision der Firmware                                  |

### Systemfunktion Echtzeituhr
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
|             | 4100        | 1     | W |                                                        |
| 01 43 00 00 | [4300](#FB00)        | 1     | W | = 00, Werte in Echtzeituhr übernehmen                  |
| 01 44 00 00 | [4400](#FB00)        | 1     | W | = 00, Werte aus Echtzeituhr laden                      |

### Systemfunktion Passwort
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 01 47 40 00 | 4740        | 1     | W | = 00, Passwort lesen/setzen initialisieren             |
| 02 48 FF    | [48FF](#48FF)        | 1     | R | Passwort vorhanden?                                    |

### Parameter Echtzeituhr
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 02 FB 00    | [FB00](#FB00) - FB05 | 6     |   | Echtzeituhr                                            |


__Hinweis:__
Maximaler Bereich = 0E 20 08 98 Adr. 0E20 - 16B8

----------

# <a name="Kapitel2"></a>Kapitel 2 - Parameterspeicher

## <a name="0552"></a>Displayinhalt nach Netz-Ein
Mit Displayinhalt nach Netz-Ein wird festgelegtt, was auf dem Display der _LOGO!_ angezeigt wird, wenn Sie diese eingeschaltet wird. 

Die Festlegung des Displayinhaltes nach Netz-Ein ist Teil der Parametereigenschaften (vergl. S7 Systemdatenbaustein) und wird beim Übertragen des Schaltprogramms ebenfalls übertragen und auf der _LOGO!_ gespeichert.

Speicherbereich: 0552, 1 Byte

Zugriffsmethode: Lesen und Schreiben

Darstellungsformat:
```
send> 02 05 52 
recv< 06
03 05 52 00
```

```
05 52 00
05 52 [Val]

Val:
  00 = Datum/Uhrzeit
  01 = Ein-/Ausgänge
```

## <a name="0553"></a>Analogausgang im Betriebszustand _STOP_
Analogausgänge können nach einem Wechsel von _RUN_ in _STOP_ auf vordefinierte Ausgangswerte oder auf die Werte, die vor dem Wechsel in den Betriebszustand _STOP_ vorhanden waren, gesetzt werden.

Das Verhalten der Analogausgänge im Zustand _STOP_ ist Teil der Parametereigenschaften (vergl. S7 Systemdatenbaustein) und wird beim Übertragen des Schaltprogramms ebenfalls übertragen und auf der _LOGO!_ gespeichert.

Speicherbereich: 0553 - 0558, Anzahl = 5 Bytes

Zugriffsmethode: Lesen und Schreiben

Abfrage:
```
send> 05 05 53 00 05 
recv< 06
00 C4 03 D5 01
13
```

Wertebereich: 0.00 - 9.99

Darstellungsformat:
```
00  [C4 03] [D5 01]
Val [AQ1  ] [AQ2  ]

Pa:
  if (Val == 01)
  {
    Alle Ausgänge behalten den letzten Wert bei;
  }
  else
  {
    AQ1 Wert im Betriebsart STOP;
    AQ2 Wert im Betriebsart STOP;
  }

AQn:
  [C4 03] [D5 01]
    \ /     \ /
    / \     / \
   03 C4   01 D5  (HEX)
   964     469    (Dec)
   -------------
   9.64    4.69
```

## <a name="0570"></a>Programmname

Speicherbereich: 0570, 10 Bytes

Zugriffsmethode: Lesen und Schreiben

Standarddaten
```
20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20
```

## <a name="05C0"></a>Verweis auf Blocknamen

Speicherbereich: 05C0 - 0600, 64 Bytes

Adressverweis:
```
      Speicher 05C0            Speicher 0600
    .---------------.        .---------------.
05C0| Blockindex 1  |------->| 8 Bytes/ASCII |0600
05C1|            2  |------->| 8 Zeichen     |0608
05C2|            3  |------->| 8 Zeichen     |0610
 :  |            :  |        | :             | :
 :  |            :  |        | :             | :
    |               |        |               |
    |               |        |               |
05FE| Blockindex 63 |------->| 8 Zeichen     |07F0
05FF| Blockindex 64 |------->| 8 Zeichen     |07F8
    '---------------'        '---------------'
```
Es können maximal 64 Blöcke einen Blocknamen erhalten.

Beispiel:
```
send> 05 05 C0 00 10 
recv< 06
0A 0C FF FF FF FF FF FF FF FF FF FF FF FF FF FF
06
```

HEX | DEC | Block | Adresse
----|-----|-------|--------
0A  | 10  | B001  | 0600
0C  | 12  | B003  | 0608
FF  | 255 | -     | -

## <a name="0600"></a>Blockname
In LOGO!Soft Comfort können für bis zu 64 Blöcke achtstellige Blocknamen vergeben werden.

Speicherbereich: 0600 - 0800, 512 Bytes (8 * 64)

Zugriffsmethode: Lesen und Schreiben

Die Länge beträgt 8 Byte, bei weniger als 8 Byte wird der Text mit `00` terminiert und mit `FF` aufgefüllt.

Standarddaten:
```
send> 05 06 00 00 18 
recv< 06 
FF FF FF FF FF FF FF FF
FF FF FF FF FF FF FF FF
FF FF ...
```

Beispiel:
```
send> 05 06 00 00 18 
recv< 06 
31 32 33 34 00 FF FF FF   // 12345
38 37 36 35 34 33 32 31   // 87654321
41 42 43 44 45 00 FF FF   // ABCDE
B2                        // XOR
```
Das Beispiel zeigt die Blöcke B001 bis B003

## <a name="0800"></a>Textfeld
Ein Meldetext belegt 64 Bytes: jeweils 4 Zeilen a 12 Bytes für <Daten/Zeichen> zzgl. 2 Bytes <Header-Daten> und 2 Bytes <00 00>.

Speicherbereich: 0800 - 0A80, 640 Bytes (10*4*16)

vergl. S7 Datenbaustein

Standarddaten:
```
FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 // (40x)
...
```

Darstellungsformat:
```
03 04 20 20 20 20 00 00 00 00 00 00 00 00 00 00
02 04 0B 2B 00 00 4C 65 6E 3A 20 20 00 00 00 00
02 04 0B 2B 01 00 43 6E 74 3A 20 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00
-------------------------------------------------
03 04 [20 20 20 20 00 00 00 00 00 00 00 00] 00 00
02 04 [0B 2B 00 00 4C 65 6E 3A 20 20 00 00] 00 00
02 04 [0B 2B 01 00 43 6E 74 3A 20 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00
Pa Po [--------------- Txt ---------------]
                
Pa: Parameter
  01: reiner Text
  02: Blockparameter
      02 04 [0B 2B 01 00 ...
         +-  +- +- '-+-'   
         |   |  |    '-- Parameter 2
         |   |  '------- ASCII Zeichen "+"
         |   '---------- Blocknummer B002
         '-------------- Startposition 4
  03: aktuelle Uhrzeit, Breite 8
  04: aktuelles Datum, Breite 10
  05: Nachrichtenaktivierungszeit, Breite 8
  06: Nachrichtenaktivierungsdatum, Breite 10

Po: Position
  Bei Pa=01   : Anfangsposition des Textes (linksbündig)
  Bei Pa=02   : Position Blockparameter (linksbündig)
  Bei Pa=03-06: Anfangsposition Zeit oder Datum (linksbündig)

Txt: Text
    maximal 12 ASCII-Zeichen
    
    Sonderzeichen:
      80: Pfeil nach oben ▲
      81: Pfeil nach unten ▼

    Hinweis: wenn die Zeile einen Block hat, repräsentieren die ersten 2 Bytes den Block
    und die nächsten 2 Bytes den Parameter.
```

Auswertung:
```
03 04 [20 20 20 20 00 00 00 00 00 00 00 00] 00 00
02 04 [0B 2B 00 00 4C 65 6E 3A 20 20 00 00] 00 00
       0B 2B 00 00                // Block B002, Parameter 1
       0B 2B 01 00                // Block B002, Parameter 2
                   4C 65 6E 3A    // Text "Len:"
                   43 6E 74 3A    // Text "Cnt:"
       80 50 72 69 20 81 4E 78 74 // Text "▲Pri ▼Nxt"
```

Beispiele:
```
01 00 [00 00 00 00 00 00 00 00 00 00 00 00] 00 00 // 
02 02 [14 2B 00 00 41 20 20 5A 20 20 00 00] 00 00 // Block B011; "+"; Parameter 1; "A__Z"
02 05 [17 2B 00 00 54 69 6D 65 73 20 00 00] 00 00 // Block B014; "+"; Parameter 1; "Times"
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00 // Text "▲Pri ▼Nxt"

03 04 [20 20 20 20 00 00 00 00 00 00 00 00] 00 00 // aktuelle Uhrzeit
04 00 [20 BA 00 00 00 00 00 00 00 00 00 00] 00 00 // aktuelles Datum
05 00 [00 00 00 00 00 00 00 00 20 20 20 9F] 00 00 // Nachrichtenaktivierungszeit
06 00 [00 00 00 00 00 00 00 00 00 00 20 8F] 00 00 // Meldungsaktivierungsdatum
```

## <a name="1F02"></a>Version und Firmware

Zugriffsmethode: Lesen

Variante | Bezeichnung | Bestellnummer
--- | --- | ---
Basic | _LOGO!_ 12/24RC | 6ED1052-1MD00-0BA5
Basic | _LOGO!_ 24 \* | 6ED1052-1CC00-0BA5
Basic | _LOGO!_ 24RC (AC) | 6ED1052-1HB00-0BA5
Basic | _LOGO!_ 230RC (AC) | 6ED1052-1FB00-0BA5
Pure  | _LOGO!_ 12/24 RCo \* | 6ED1052-2MD00-0BA5
Pure  | _LOGO!_ 24o \* | 6ED1052-2CC00-0BA5
Pure  | _LOGO!_ 24 RCo (AC) | 6ED1052-2HB00-0BA5
Pure  | _LOGO!_ 230 RCo | 6ED1052-2FB00-0BA5

\*: zusätzlich mit Analogeingängen

Chip:
```
.-----------------.
| o               |
| LOGO            |
| V2.0.2          |
| 721533          |
| 0650EP004       |
|                 |
'-----------------'
```

Befehle:
```
send> 02 1F 00
recv< 06 03 1F 00 04
send> 02 1F 01
recv< 06 03 1F 01 00 
send> 02 1F 02
recv< 06 03 1F 02 42 
send> 02 1F 03
recv< 06 03 1F 03 56 
send> 02 1F 04
recv< 06 03 1F 04 32
send> 02 1F 05
recv< 06 03 1F 05 30
send> 02 1F 06
recv< 06 03 1F 06 32
send> 02 1F 07
recv< 06 03 1F 07 30
send> 02 1F 08
recv< 06 03 1F 08 30
```
Auswertung:

Read Byte | HEX | BIN       | Bedeutung
----------|-----|-----------|-------------
1F00      | 04  | 0000 0100 | ??
1F01      | 00  | 0000 0000 | ??
1F02      | 42  | 0100 0010 | Ident = 0BA5

Read Byte | HEX | DEC | ASCII
----------|-----|-----|------
1F03      | 56  | 86  | V
1F04      | 32  | 50  | 2
1F05      | 30  | 48  | 0
1F06      | 32  | 50  | 2
1F07      | 30  | 48  | 0
1F08      | 30  | 48  | 0

Firmware = V2.02.00

## <a name="48FF"></a>Passwort vorhanden
_LOGO!_ __0BA5__ bietet einen Passwortschutz, um den Zugriff auf das Schlatprogramm einzuschränken. Durch das Einrichten eines Passworts kann nur nach Eingabe eine Passwortes auf das Schaltprogramm und bestimmte Parameter zugegriffen werden. Ohne Passwort ist der uneingeschränkte Zugriff auf die _LOGO!_ Ressourcen möglich.

Das Passwort hat eine Länge von 10 Zeichen. Groß- und Kleinschreibung spielt beim Passwort keine Rolle, da das Passwort in Großbuchstaben abgespeichert wird. Das Passwort ist ein Parameter (vergl. S7 Systemdatenbaustein) und wird beim Übertragen des Schaltprogramms auf
die _LOGO!_ ebenfalls übertragen und auf der _LOGO!_ gespeichert. 

Befehl:
```
send> 02 48 FF
recv< 06 03 48 FF 00
```

Read Byte | Wert | Beschreibung
----------|------|-------------
48FF      | 40   | ja
48FF      | 00   | nein

## <a name="FB00"></a>Echtzeituhr
Alle Datums- und Zeitwerte sind im BCD-Format codieren. Die Echtzeituhr startet nach längerem Stromausfall oder nach Speicherverlust mit folgendem Datum und folgender Zeit:
- Datum: 01-Jan-2000
- Zeit: 00:00:00
- Wochentag: Sonntag

__Hinweis:__ _LOGO!_ prüft nicht, ob der Wochentag mit dem Datum übereinstimmt.

Speicherbereich: FB00, 6*1 Byte

Adresse | Wert
--------|-----------
FB00    | Tag
FB01    | Monat
FB02    | Jahr
FB03    | Minuten
FB04    | Stunden
FB05    | Wochentag \*)

\*) 1=Sonntag, 7=Samstag

### Echtzeituhr auslesen
Die Schreibbefehl _Echtzeituhr lesen_ liest die aktuelle Uhrzeit und das aktuelle Datum aus der Hardware-Uhr und lädt beide in einen 6-Byte-Zeitpuffer mit Beginn an Adresse FB00.

Befehlsfolge:
```
send> 01 44 00 00     // Werte der Echtzeituhr laden
recv< 06              // OK
send> 02 FB XX        // XX = [00-05]
recv< 06 03 FB XX YY  // YY = Wert
```

### Echtzeituhr setzen
Der Befehl Echtzeituhr setzen schreibt die aktuelle Uhrzeit und das aktuelle Datum der Hardware-Uhr in den 6-Byte-Zeitpuffer mit Beginn an die Adresse FB00.

Befehlsfolge
```
send> 01 FB XX YY     // XX = [00-05], YY = Wert
recv< 06              // OK
send> 01 43 00 00     // Werte in Echtzeituhr uebernehmen
recv< 06              // OK
```

----------

# <a name="Kapitel3"></a>Kapitel 3 - Klemmenspeicher

## <a name="Co"></a>Konstanten und Klemmen - Co
Als Klemme werden alle Anschlüsse und Zustände bezeichnet (engl. Connectors = Co). Hierzu zählen Digitaleingänge, Analogeingänge, Digitalausgänge, Analogausgänge, Merker (inkl. Anlaufmerker), Analoge Merker, Schieberegisterbits, Cursortasten, Pegel und die Offenen Klemmen.

Klemmen sind Bestandteil des Schaltprogramms (vergl. S7 Programmbaustein) und somit Teil des Hauptprogramm (vergl. S7 Organisationsbaustein OB1). 

### Darstellung am Verknüpfungseingang
Sie sind nicht im Programmzeilenpeicher 0EE8 abgelegt, sondern werden mit einem festen 16bit Wert (Datentyp Word) und einem Wertebereich 0000..00FE am Eingang eines Blocks, Merkers oder einer Ausgangsklemme dargestellt. 

Das höherwertige Byte vom Word ist immer 00. Das niederwertige Byte vom Word (LoByte) zeigt den Klemmentyp bzw. nennt die Konstante (siehe Listen folgend).

### Liste Klemmen
LoByte HEX | Klemme/Merker | Beschreibung
-----------|---------------|-------------------------------
00-17      | I1..24        | Digitaleingänge
30-3F      | Q1..16        | Digitalausgänge
50-67      | M1..24        | Merker
80-87      | AI1..8        | Analogeingänge
92-97      | AM1..6        | Analoge Merker
A0-A3      | C1..3         | Cursortasten (▲, ▼, <, >)
B0-B7      | S1..8         | Schieberegisterbits

### Liste Konstanten
LoByte HEX | Konstante | Beschreibung
-----------|-----------|--------------------------
FC         | Float     | (Verwendung ??)
FD         | Pegel hi  | Blockeingang logisch = 1
FE         | Pegel lo  | Blockeingang logisch = 0
FF         | x         | nicht benutzter Anschluss

### Format im Speicher
Klemmen, die aufgrund eines Verknüpfungseinganges ein Speicherplatz besitzen, sind die Ausgänge Q1 bis Q16, AQ1 und AQ2, die Merker M1 bis M24 und AM1 bis AM6, sowie die 16 unbeschaltete Ausgänge X1 bis X16. 

Die Verdrahtung auf den Eingang einer Ausgangsklemme oder eines Merkes werden im Speicherbereich ab 0E20 - 0EC0, 200 Bytes (10*20 Bytes) abgelegt.

Das Format ist einheitlich und ist als vielfache von 20 Bytes = 2 Bytes `80 00` + 16 Bytes `<Eingänge>` + 2 Bytes `FF FF` abgelegt.
```
80 00 1a 1b ... ... 8a 8b FF FF // (20 Byte)
```

Nicht benutzte Anschlüsse (freie Eingänge) im Schaltprogramm werden mit `FFFF` angezeigt. 

```
Na: Eingang, abhängig von b7
Nb: BIN Hi --+--+--+--*++++ Lo
           b7 b6 b5 b4 0000

    b7 = 0, Xa = Konstante oder Klemme
    b7 = 1, Xa = Blocknummer
    b6 = 0
    b5 = 0
    b4 = 0
```

Na Nb: N = Element 1-8

Das folgende Beispiel zeigt, dass wie der Eingang von Q1 mit der Klemme I1 (0000) verbunden ist.

Schaltprogramm:
```
    .---
    |
I1--| Q1
    '---
```

Abfrage der Klemmen Q1-16
```
send> 05 0E 20 00 28 
recv< 06
80 00 00 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
00 
```

Das Beispiel zeigt auch, dass die anderen Ausgänge Q2-16 im Schaltprogramm nicht verwendet werden (= FFFF).

## <a name="0C00"></a>Verweis auf Ausgänge, Merker
20 Bytes fest, die jeweils (weitere) 20 Bytes im Speicherbereich für Ein-/Ausgänge und Merker verweisen. Der Verweis wird als 16 Bit-Offset-Adresse dargestellt. 

Speicherbereich: 0C00 - 0C14, 20 Bytes (10 * 2)

Adressverweis:
```
      Speicher 0C00            Speicher 0E20
    .----------------.       .---------------.
0C00| 0E20 Offset 1  |------>| 20 Bytes      |0E20+0000 = 0E20
0C02| 0E20 Offset 2  |------>| 20 Bytes      |0E20+0014 = 0E34
    o----------------o       o---------------o
0C04| 0E20 Offset 3  |------>| 20 Bytes      |0E20+0028 = 0E48
 :  |             :  |       | :             | :
 :  |             :  |       | :             | :
    o----------------o       o---------------o
    |                |       |               |
    o----------------o       o---------------o
    |                |       |               |
    |                |       |               |
    o----------------o       o---------------o
0C10| 0E20 Offset 9  |------>| 20 Bytes      |0E20+00A0 = 0EC0
0C12| 0E20 Offset 10 |------>| 20 Bytes      |0E20+00B4 = 0ED4
    '----------------'       '---------------'
```

Bereich     | Anz | Zeiger            | Beschreibung
------------|-----|-------------------|------------------------
0E20 - 0E48 | 40  | 0000, 0014        | Digitaler Ausgang 1..16
0E48 - 0E84 | 60  | 0028, 003C, 0050  | Merker 1..24
0E84 - 0E98 | 20  | 0064              | Analogausgang 1, 2
0E98 - 0EC0 | 40  | 0078, 008C        | offener Ausgang 1..16
0EC0 - 0EE8 | 40  | 00A0, 00B4        | (Reserve ??)

Befehl:
```
send> 05 0C 00 00 14
recv< 06
00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
D4
```

Auswertung:
```
             |<----------------------- 20 Bytes ---------------------->|
HEX (Lo-Hi): 00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
HEX (Hi-Lo): 00 00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4
Dezimal:     00    20    40    60    80    100   120   140   160   180
Speicherbedarf: 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20
```

## <a name="0E20"></a>Digitalausgänge - Q
Die Digitalausgänge Q1 bis Q16 befinden sich im Speicherbereich 0E20 - 0EC0 (2*20 Bytes).

Darstellungsformat:
```
80 00 Q1a Q1b ... ... Q8a  Q8b  FF FF // (20 Byte)
80 00 Q9a Q9b ... ... Q16a Q16b FF FF
```

Q<n>a Q<n>b: n = Element 1-16

## <a name="0EC0"></a>Merker - M
Die Digitalausgänge M1 bis M24 befinden sich im Speicherbereich 0EC0 - 0E84 (3*20 Bytes).

Darstellungsformat:
```
80 00 M1a  M1b  ... ... M8a  M8b  FF FF // (20 Byte)
80 00 M9a  M9b  ... ... M16a M16b FF FF
80 00 M17a M17b ... ... M24a M24b FF FF
```

M<n>a M<n>b: n = Element 1-24

## <a name="0E84"></a>Analogausgänge, Analoge Merker - AQ, AM
Die Analogen Ausgänge AQ1 und AQ2 befinden sich im Speicherbereich 0E84 - 0E98 (1*20 Bytes).

Darstellungsformat:
```
80 00 AQ1a AQ1b AQ2a AQ2b AM1a AM1b ... ... AM6a AM6b  FF FF // (20 Byte)
```

AQ<n>a AQ<n>b: n = Element AQ1-2<br />
AM<n>a AM<n>b: n = Element AM1-6

## <a name="0E98"></a>Offene Klemmen - X
Die Offenen Klemmen X1 bis X16 befinden sich im Speicherbereich 0E98 - 0EC0 (2*20 Bytes).

Darstellungsformat:
```
80 00 X1a  X1b  ... ... X8a  X8b  FF FF // (20 Byte)
80 00 X9a  X9b  ... ... X16a X16b FF FF
```

X<n>a X<n>b: n = Element 1-16

----------

# <a name="0EE8"></a>Kapitel 4 - Programmzeilenspeicher
Der Programmzeilenspeicher ist Teil des Schaltprogramm (vergl. S7 Programmbaustein) und wird zur Arbeitung des Hauptprogramm (vergl. S7 Organisationsbaustein OB1) in den Arbeitsspeicher geladen. Der zugehörige Code ist Teil der Firmware und daher nicht adressierbar. 

## Blöcke und Blocknummern
Ein Block ist eine Funktion, die eine Ausgangsinformationen Aufgrund einer Informationen an den Eingängen setzt. Die Firmware bestimmt die nutzbaren Funktionen, die für unterschiedliche Aufgaben eingesetzt werden können (vergl. S7 Systemfunktionen). 

### Darstellung am Verknüpfungseingang
Alle Blöcke sind im Programmzeilenpeicher 0EE8 abgelegt und werden mit einem 16bit Wert (Datentyp Word) im Wertebereich 8000..C08C am Eingang eines Blocks, Merkers oder einer Ausgangsklemme dargestellt. 

Bei einem Block ist das Most Significant Bit (MSB = `1`) vom Word immer gesetzt. Das niederwertige Byte vom Word (LoByte) benennt die Blocknummer im Wertebereich 0A..8C, entsprechend B001 bis B130.

Bestimmte Eingänge von Grund- und Sonderfunktionen können einzeln negieren, d.h. liegt an dem bestimmten Eingang eine `1` an, so verwendet das Schaltprogramm eine `0`. Liegt eine `0` an, so wird eine `1` verwendet. Diese Information ist im Bit7 vom HiByte gespeichert:

Eingang | HiByte | BIN
--------|--------|---------------
normal  | 80     | 1000 0000 = 80
negiert | C0     | 1100 0000 = C0

### Zuordnen einer Blocknummer
Die Erklärung erfolgt Anhand eines Beispiels. Im Beispiel kommen die Klemmen Q1 und Q2 zur Anwendung (ungleich FFFF).

Die Klemmen sind wie folgt verdrahtet:
- Der Eingang von Q1 ist mit dem Ausgang von Block B001 verbunden
- Eingang Q2 mit Ausgang B005

So sieht das zugehörige Schaltprogramm aus:
```
    .---
    |
B1--| Q1
    '---
    .---
    |
B5--| Q2
    '---
```

Abfrage der Klemmen Q1-Q16
```
send> 05 0E 20 00 28 
recv< 06
80 00 0A 80 0E 80 FF FF FF FF FF FF FF FF FF FF FF FF FF FF
80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
04 
```

Klemme | Block | HEX | DEC
-------|-------|-----|-----
Q1     | B001  | 0A  | 10
Q2     | B005  | 0E  | 10
Q3-16  | -     | FF  | -

Block | HEX | DEC | Offset (-9)
------|-----|-----|-------------
B001  | 0A  | 10  | 1
B005  | 0E  | 14  | 5

## <a name="0C14"></a>Verweis auf Blöcke
Zeiger auf die Blöcke im Programmzeilenpeicher 0EE8. Jeweils ein 16bit-Zeiger (ungleich FFFF, hex) zeigt auf ein Block. Ein Block ist eine Funktion, die Eingangsinformationen in Ausgangsinformationen umsetzt. Die Länge eine Blocks im Programmzeilenspeicher ist variabel.

Die Größe beträgt 260 Bytes (0BA5 hat maximal 130 Blöcke und der Zeiger eines Funktionsblocks belegt 2 Bytes: 260/2 = 130).

Speicherbereich: 0C14 - 0D18, 260 Bytes (130 * 2).

Adressverweis:
```
      Speicher 0C14            Speicher 0EE8
    .-----------------.      .---------------.
0C14| 0E20 Offset 1   |----->| Block n Bytes |0E20+Offset 1 = 0EE8
0C16| 0E20 Offset 2   |----->| Block n Bytes |0E20+Offset 2
0C18| 0E20 Offset 3   |----->| Block n Bytes |0E20+Offset 3
 :  |             :   |      | :             | :
 :  |             :   |      | :             | :
    |                 |      |               |
    |                 |      |               |
0D14| 0E20 Offset 129 |----->| Block n Bytes |0E20+Offset 129
0D16| 0E20 Offset 130 |----->| Block n Bytes |0E20+Offset 130
    '-----------------'      '---------------'
```
Zeigerarithmetik: unter Verwendung des ausgelesen Wertes ist es möglich, einen Zeiger auf 0E20 um den gelesen Offset-Anteil zu erhöhnen und damit den Block im Speicherbereich anzusprechen. 

Der erste Block liegt im Programmzeilenspeicher 0EE8 = 0E20 + 00C8, d.h. Der Wert an Adresse 0C14 (Offset 1) ist entweder 00C8 oder FFFF, wenn kein Programm vorhanden ist.

Befehl:
```
send> 05 0C 14 01 04
```

Ausgabe mit gelöschten Programm:
```
recv< 06
FF FF FF FF FF FF FF FF FF FF FF FF ...
```

Programm bestehend aus einem Block:
```
recv< 06
C8 00 FF FF FF FF FF FF FF FF FF FF ...
```

Beispielschaltprogramm "Ermittlung von Speicherbedarf" aus dem Handbuch:
```
      B3
     .---.       B2
No1--|.-.|      .---.
No2--|'-'|------| & |       B1
No3--|   |    x-|   |      .---.
     '---'   .--|   |------|>=1|
             |  '---'    x-|   |
      B4     |         I2--|   |--Q1
     .---.   |             '---'
     |.-.|   |
 I1--|--'|   |
Par--|   |---'
     '---'       B6
                .---.       B5
            I3--| & |      .---.
            I4--|   |      |'--|
              x-|   |------|.-.|
                '---' Par--|   |--Q2
                           '---'
```

Block | Funktion                 | Speicherbedarf
------|--------------------------|---------------
B1    | OR                       | 12 Bytes
B2    | AND                      | 12 Bytes
B3    | Wochenschaltuhr          | 20 Bytes
B4    | Einschaltverzögerung \*) | 8 Bytes
B5    | Treppenlichtschalter     | 12 Bytes
B6    | AND                      | 12 Bytes

\*) Parametriert mit Remanenz

Abfrage der Offset-Werte:
```
send> 05 0C 14 00 14
recv< 06
C8 00 D4 00 E0 00 F4 00 FC 00 08 01 FF FF FF FF FF FF FF FF FD
```

Auswertung:
```
HEX (Lo-Hi): C8 00 D4 00 E0 00 F4 00 FC 00 08 01 FF FF FF FF FF FF FF FF
HEX (Hi-Lo): 00 C8 00 D4 00 E0 00 F4 00 FC 01 08 FF FF FF FF FF FF FF FF
Dezimal:     200   212   224   244   252   264
Speicherbedarf: 12 -- 12 -- 20 --- 8 -- 12 --
```

## <a name="GF"></a>Grundfunktionen - GF
Grundfunktionen sind einfache Grundverknüpfungsglieder der boolschen Algebra.

### Format im Speicher
Die Formatlänge ist variabel und hat 4, 8 oder 12 Bytes = 2 Bytes `<GF> 00` + 0 bis 8 Bytes `<Eingänge>` + 0 bis 2 Bytes `FF FF`.
```
GF 00 1a 1b                         // (4 Bytes)
GF 00 1a 1b 2a 2b FF FF             // (8 Bytes)
GF 00 1a 1b 2a 2b 3a 3b 4a 4b FF FF // (12 Bytes)
```
GF: Funktionsblock, siehe Liste Grundfunktionen

```
Na: Eingang, abhängig von b7
Nb: BIN Hi --+--+--+--*++++ Lo
           b7 b6 b5 b4 0000

    b7 = 0, Xa = Konstante oder Klemme
    b7 = 1, Xa = Blocknummer
    b6 = 0, Konnektor normal (nicht negiert)
    b6 = 1, Konnektor negiert
    b5 = 0
    b4 = 0
```

Na Nb: N = Element 1-4

Nicht benutzte Anschlüsse im Schaltprogramm werden mit `FFFF` angezeigt.

Folgend das Beispiel "Ermittlung von Speicherbedarf" aus dem Handbuch.

Schaltprogramm:
```
     B1
    .---.
B2--|>=1|
  x-|   |
I2--|   |--Q1
    '---'
```

Abfrage von Block B001:
```
send> 05 0E E8 00 0C
recv< 06
02 00 0B 80 FF FF 01 00 FF FF FF FF
88
```

Auswertung:
```
02 00 [0B 80] [FF FF] [01 00] [FF FF] FF FF   // Little-Endian
02 00 [80,0B] [FF,FF] [00,01] [FF FF] FF FF   // Hi,Lo
GF 00 [Nr,B2] [--,--] [Co,I2] [--,--]         // OR
```

### Liste Grundfunktionen
HEX | BIN       | RAM (Bytes) | Bezeichnung der Grundfunktion
----|-----------|-------------|------------------------------
01  | 0000 0001 | 12          | AND (UND)
02  | 0000 0010 | 12          | OR (ODER)
03  | 0000 0011 | 4           | NOT (Negation, Inverter)
04  | 0000 0100 | 12          | NAND (UND nicht)
05  | 0000 0101 | 12          | NOR (ODER nicht)
06  | 0000 0110 | 8           | XOR (exklusiv ODER)
07  | 0000 0111 | 12          | AND mit Flankenauswertung
08  | 0000 1000 | 12          | NAND mit Flankenauswertung

## <a name="SF"></a>Sonderfunktionen - SF
Sonderfunktionen sind ähnlich wir die Grundfunktionen im Speicher abgelegt. Neben den Verknüpfungseingängen sind beinhalten diese jedoch Zeitfunktionen, Remanenz und verschiedenste Parametriermöglichkeiten.

### Format im Speicher
Die Formatlänge ist variabel und hat 8, 12, 20 oder 24 Bytes = 2 Bytes `<SF> <Pa>` + 4 bis 20 Bytes `<Daten>` + 2 Bytes `FF FF`.

SF: Block, siehe Liste Sonderfunktionen<br />
Pa: Parameter, siehe Blockparameter

### Liste Sonderfunktionen
HEX | RAM (Bytes) | REM (Bytes) | Beschreibung
----|-------------|-------------|---------------------------------
[21](#SF21)  | 8           | 3           | Einschaltverzögerung
[22](#SF22)  | 12          | 3           | Ausschaltverzögerung
[23](#SF23)  | 12          | 1           | Stromstoßrelais
[24](#SF24)  | 20          | -           | Wochenschaltuhr
[25](#SF25)  | 8           | 1           | Selbsthalterelais
[27](#SF27)  | 12          | 3           | Speichernde Einschaltverzögerung
[2B](#SF2B)  | 24          | 5           | Vor-/Rückwärtszähler
[2D](#SF2D)  | 12          | 3           | Asynchroner Impulsgeber
[31](#SF31)  | 12          | 3           | Treppenlichtschalter
[39](#SF39)  | 20          | -           | Analogwertüberwachung

## Grundwissen Sonderfunktionen

### Bezeichnung der Eingänge:
- __S__ (_Set_): Über den Eingang S kann der Ausgang auf `1` gesetzt.
- __R__ (_Reset_): Der Rücksetzeingang R schaltet Ausgänge auf `0`.
- __Trg__ (_Trigger_): Über diesen Eingang wird der Ablauf einer Funktion gestartet.
- __Cnt__ (_Count_): Über diesen Eingang werden Zählimpulse aufgenommen.
- __Fre__ (_Frequency_): Auszuwertende Frequenzsignale werden an den Eingang mit dieser Bezeichnung angelegt.
- __Dir__ (_Direction_): Über diesen Eingang legen Sie die Richtung fest.
- __En__ (_Enable_): Dieser Eingang aktiviert die Funktion eines Blocks. Liegt der Eingang auf `0`, werden andere Signale vom Block ignoriert.
- __Inv__ (_Invert_): Das Ausgangssignal des Blocks wird invertiert, wenn dieser Eingang angesteuert wird.
- __Ral__ (_Reset all_): Alle internen Werte werden zurückgesetzt.

### Zeitverhalten
Bei bestimmten Sonderfunktionen kann eine Zeit parametriert werden. _LOGO!_ verfügt über Zeiten, die in unterschiedlichen Auflösungen (Inkrementen der Zeitbasis) zählen. Jede Zeit wird als Speichertyp _TW_ gespeichert mit folgenden zwei Angaben:
- Zeitwert: Diese ganze Zahl (14 Bit) ohne Vorzeichen speichert den Wert der Zeit.
- Zeitbasis: Bit 16 und 15 legen die Zeitbasis fest, die mit dem voreingestellten Zeitwert eingegeben wird.

Darstellung | Zeitbasis | Inkrement | Wert
--- | --- | --- | ---
(s:1/100) | s | 10 ms | 1
(m:s) | m | Sekunden | 2
(h:m) | h | Minuten | 3

Darstellungsformat:
```
.. xx Ta Tb xx ..
.. xx [TW ] xx ..

xx:    irgendein Byte
Ta Tb: Zeit
  Ta Tb
   \ /
   / \
  Tb,Ta = TW

    |       Tb (byte)       |       Ta (byte)       |
  Hi --+--*--+--+--+--+--+--|--+--+--+--+--+--+--+-- Lo
     bF bE|bD ..       .. b8|b7 ..          .. b1 b0

  bF,bE = 0,0 Zeitbasis (h:m), Wertebereich (0-23:0-59)
  bF,bE = 1,1 Zeitbasis (h:m), Wertebereich (0-99:0-59)
  bF,bE = 1,0 Zeitbasis (m:s), Wertebereich (0-99:0-59)
  bF,bE = 0,1 Zeitbasis (s:1/100s), Wertebereich (0-99:0-99)

  byte b = TW >> 14;  // bF..bE (2bit) -> Zeitbasis (VB)
  word v = TW & 7FFF; // bD..b0 (14bit) -> Zeitwert (VW)
  if (b == 3)
  {
    // Zeitbasis Stunden; Inkrement Minuten; (h:m)
    h = v / 60;
    m = v % 60;
  }
  else if (b == 2)
  {
    // Zeitbasis Minuten; Inkrement Sekunden; (m:s)
    m = v / 60;
    s = v % 60;
  }
  else if (b == 1)
  {
    // Zeitbasis Sekunden; Inkrement 10ms; (s:1/100)
    s = v / 100;
    10ms = v % 100;
  }
```

Beispiel:
```
21 40 01 00 7A 80 00 00 // Einschaltverzögerung 2:02 (m: s)
21 40 01 00 7A C0 00 00 // Einschaltverzögerung 2:02 (h: m)
21 40 01 00 CA 40 00 00 // Einschaltverzögerung 2:02 (s: 1 / 100s)
21 C0 01 00 FE 41 00 00 // Einschaltverzögerung 5:10 (s: 1 / 100s), Remanenz
21 00 01 00 FE 41 00 00 // Einschaltverzögerung 5:10 (s: 1 / 100s), Parameterschutz
```

### Zähler
_LOGO!_ __0BA5__ verfügt nur über eine Art von Zähler, welcher an einem Zähleingang die steigenden Flanken zählt. Der Zähler zählt sowohl vorwärts als auch rückwärts. Der Zählerwert ist eine 32Bit Ganzzahl vom Datentyp _ZD_ und wird ohne Vorzeichen gespeichert. Der gültige Wertebereich des Zählers liegt zwischen 0...999999.

Darstellungsformat:
```
.. xx 00 06 6C BC xx ..
.. xx Za Zb Zc Zd xx ..
.. xx [ZD       ] xx ..

xx:    irgendein Byte
Za-Zd: Zählerwert

  Za Zb Zc Zd
      \ /
      / \
  Zd Zc Zb Za
  00 06 6C BC = 421052
```
Maximaler Zählerwert F423F:
```
  Za Zb Zc Zd
      \ /
      / \
  Zd Zc Zb Za
  00 0F 42 3F = 999999
```

## <a name="SF21"></a>Einschaltverzögerung
Mit der Funktion _Einschaltverzögerung_ wird das Setzen des Ausgangs _Q_ um die programmierte Zeitdauer _T_ verzögert. Die Zeit _Ta_ startet (_Ta_ ist die in _LOGO!_ aktuelle Zeit vom Typ Word), wenn das Eingangssignal _Trg_ von `0` auf `1` wechselt (positive Signalflanke). Wenn die Zeitdauer abgelaufen ist (Ta > T), liefert der Ausgang _Q_ den Signalzustand `1`. Der Ausgang _Q_ bleibt so lange gesetzt, wie der Triggereingang die `1` führt. Wenn der Signalzustand am Triggereingang von `1` auf `0` wechselt, wird der Ausgang _Q_ zurückgesetzt. Die Zeitfunktion wird wieder gestartet, wenn eine neue positive Signalflanke am Starteingang erfasst wird. 

### Programmspeicher auslesen
RAM/REM: 8/3

Darstellungsformat:
```
21 40 01 00 7A 80 00 00 FF FF FF FF
21 40 [01 00] [7A 80] 00 00 FF FF FF FF
SF Pa [Trg  ] [Par  ] 00 00 FF FF FF FF
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

Trg: Eingang Trg (Co oder GF/SF)
Par: Parameter T (T ist die Zeit, nach der der Ausgang eingeschaltet wird)
```
Folgend das Beispiel "Ermittlung von Speicherbedarf" aus dem Handbuch.

Schaltprogramm:
```
      B4
     .---.
     |.-.|
 I1--|--'|
Par--|   |--B2
     '---'
```

Abfrage von Block B004:
```
send> 05 0F 14 00 08 
recv< 06
21 40 00 00 7A 80 00 00
9B 
```

Auswertung:
```
21 40 [00 00] [7A 80] 00 00  // Little-Endian
21 40 [00 00] [80,7A] 00 00  // Hi,Lo
SF Pa [Co I1] [Par T] 00 00  // Einschaltverzögerung, 02:02 (m: s)
```

Weitere Beispiele:
```
21 40 01 00 7A C0 00 00 // Einschaltverzögerung 02:02 (h: m)
21 C0 01 00 FE 41 00 00 // Einschaltverzögerung 05:10 (s: 1/100s), Remanenz aktiviert
```

## <a name="SF22"></a>Ausschaltverzögerung
Mit der Funcktion _Ausschaltverzögerung_ wird das Zurücksetzen des Ausgangs _Q_ um die parametrierte Zeitdauer _T_ verzögert. Der Ausgang _Q_ wird mit positiver Signalflanke gesetzt (Eingang _Trg_ wechselt von `0` auf `1`). Wenn der Signalzustand am Eingang _Trg_ wieder auf `0` wechselt (negative Signalflanke), läuft die parametrierte Zeitdauer _T_ ab. Der Ausgang _Q_ bleibt gesetzt, solange die Zeitdauer _Ta_ läuft (Ta < T). Nach dem Ablauf der Zeitdauer _T_ (T > Ta) wird der Ausgang _Q_ zurückgesetzt. Falls der Signalzustand am Eingang _Trg_ auf `1` wechselt, bevor die Zeitdauer _T_ abgelaufen ist, wird die Zeit zurückgesetzt. Der Signalzustand am Ausgang _Q_ bleibt weiterhin auf `1` gesetzt. 

RAM/REM: 12/3

Darstellungsformat:
```
22 80 01 00 02 00 1F CD 00 00 00 00
22 80 [01 00] [02 00] [1F CD] 00 00 00 00
SF Pa [Trg  ] [R    ] [Par  ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

Trg: Eingang Trg (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par: Parameter T (Der Ausgang schaltet aus, wenn die Verzögerungszeit T abläuft)
```

Beispiel:
```
22 80 01 00 02 00 1F CD 00 00 00 00 // Ausschalterzögerung 55:59 (h: m)
```

## <a name="SF23"></a>Stromstoßrelais
Bei der Funktion _Stromstoßrelais_ wechselt der Ausgang _Q_ bei jedem elektrischen Impuls am Eingang _Trg_ sein Signalzustand. Ist der Ausgang _Q_ zurückgesetzt (`0`) so wird er gesetzt (`1`) ist der Ausgang _Q_ gesetzt (`1`) wird dieser zurückgesetzt (`0`).

Der Ausgang _Q_ kann mittels der Eingänge _S_ und _R_ vorbelegt werden. Wenn der Signalzustand am Eingang _S_ `1` und am Eingang _R_ `0` ist, wird der Ausgang _Q_ auf `1` gesetzt. Wenn der Signalzustand am Eingang _S_ `0` und am Eingang _R_ `1` ist, wird der Ausgang _Q_ auf `0` zurückgesetzt. Der Eingang _R_ dominiert den Eingang _S_.

RAM/REM: 12/1

Darstellungsformat:
```
23 00 02 00 FF FF FF FF 00 00 00 00
23 00 [02 00] [FF FF] [FF FF] 00 00 00 00
SF Pa [Trg  ] [S    ] [R    ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

Trg: Eingang Trg (Co oder GF/SF)
S: Eingabe S (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par:
  RS (Vorrang Eingang R) oder
  SR (Vorrang Eingang S)
```

## <a name="SF24"></a>Wochenschaltuhr
Der Ausgang _Q_ wird über drei parametrierbares Ein- und Ausschaltzeiten (Einstellnocken _No1_, _No2_, _No3_) gesteuert. Der Wertebereich für die Schaltzeitpunkte (Ein- oder Ausschaltzeit) liegt zwischen `00:00` und `23:59` Uhr. In Summe können 6 Schaltzeitpunkte vom Datentyp _TW_ angegeben sein. Die Auswahl der Wochentagen erfolgt durch Aktivierung der zugeordneten Tage, wobei jeder Tag einen Speicher-Bit innerhalb eines Bytes zugeordnet ist. Wenn das zugehörige Bit auf 1 gesetzt ist, ist der Tag festgelegt. 

__Hinweis:__ Da die _LOGO!_ Kleinsteuerung Typ 24/24o keine Uhr besitzt, ist die Wochenschaltuhr bei dieser Variante nicht nutzbar. 

RAM/REM: 20/-

Darstellungsformat:
```
24 40 F2 00 A0 00 FF FF FF FF FF FF FF FF 2A 00 00 00 00 00
24 40 [F2 00] [A0 00] [FF FF] [FF FF] [FF FF] [FF FF]  2A 00 00  00 00 00
SF Pa [On1  ] [Off1 ] [On2  ] [Off2 ] [On3  ] [Off3 ]  D1 D2 D3
SF Pa [No1          ] [No2          ] [No3          ] [Wo-Tage ]
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein; * REM (Def)
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

No1: Nockenparameter 1
No2: Nockenparameter 2
No3: Nockenparameter 3

  OnX:  Einschaltzeitpunkt hh:mm (0-23:0-59); min. 0000, max. 059F
        FF FF = deaktiviert
        OnL OnH
          \ /
          / \
        OnH,OnL = TW
        word t = TW & 0x07FF; // Zeitwert in Minuten
        h = t / 60;
        m = t % 60;
  
        Beispiel:
        F2 = 1111 0010 = 242 (Dec) = 60 × 4 + 2 = 242   // On = 04:02h
  
  OffX: Ausschaltzeitpunkt hh:mm (0-23:0-59)
        FF FF = deaktiviert
        OffL OffH
           \ /
           / \
        OffH,OffL = TW
        word t = TW & 0x07FF; // Zeitwert in Minuten
        h = t / 60;
        m = t % 60;
  
        Beispiel:
        A0 = 1010 0000 = 160 (Dec) = 60 * 2 + 40 = 160  // Off = 02:40h

Dx: Wochentage
    Dx = 00 (Def)
    Dx = täglich (D=MTWTFSS) = 7F

    Hi ----------------------- Lo
       b7 b6 b5 b4 b3 b2 b1 b0
       -  S  F  T  W  T  M  S

    b0 = Sonntag,     // D=------S
    b1 = Montag,      // D=M------
    b2 = Dienstag,    // D=-T-----
    b3 = Mittwoch,    // D=--W----
    b4 = Donnerstag,  // D=---T---
    b5 = Freitag,     // D=----F--
    b6 = Samstag,     // D=-----S-
    b7 = - (ohne Bedeutung)

    Beispiele:
    2A = 0010 1010 // D=M-W-F--
    0E = 0000 1110 // D=MTW----
    41 = 0100 0001 // D=-----SS
```

Folgend das Beispiel "Ermittlung von Speicherbedarf" aus dem Handbuch.

Schaltprogramm:
```
      B3
     .---.
No1--|.-.|
No2--|'-'|--B2
No3--|   |
     '---'
```

Abfrage, Block B003
```
send> 05 0F 00 00 14 
recv< 06
24 40 F2 00 A0 00 36 01 FF FF FF FF FF FF 2A 0E 00 00 00 00
25 
```

Auswertung:
```
24 40 F2 00 A0 00 36 01 FF FF FF FF FF FF 2A 0E 00 00 00 00
24 40 [F2 00] [A0 00] [36 01] [FF FF] FF FF FF FF [2A 0E] 00 00 00 00
No1: D=M-W-F---, On=04:02, Off=02:40
No2: D=MTW ----, On=05:10, Off=--:--
```

## <a name="SF25"></a>Selbsthalterelais
Mit der Funktion _Selbsthalterelais_ wird der Ausgang _Q_ abhängig vom Signalzustand an den Eingängen _S_ und _R_ gesetzt oder zurückrücksetzt. Wenn der Signalzustand am Eingang _S_ `1` und am Eingang _R_ `0` ist, wird der Ausgang _Q_ auf `1` gesetzt. Wenn der Signalzustand am Eingang _S_ `0` und am Eingang _R_ `1` ist, wird der Ausgang _Q_ auf `0` zurückgesetzt. Der Eingang _R_ dominiert den Eingang _S_. Bei einem Signalzustand `1` an beiden Eingängen _S_ und _R_ wird der Signalzustand des Ausganges _Q_ auf `0` gesetzt. 

RAM/REM: 8/1

Darstellungsformat:
```
25 00 0A 80 FF FF 00 00
25 00 [0A 80] [FF FF] 00 00
SF Pa [S    ] [R    ] 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

S: Eingabe S (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
```

## <a name="SF27"></a>Speichernde Einschaltverzögerung

RAM/REM: 12/3

Darstellungsformat:
```
27 80 02 00 FF FF 36 81 00 00 00 00
27 80 [02 00] [FF FF] [36 81] 00 00 00 00
SF Pa [Trg  ] [R    ] [Par  ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

Trg: Eingang Trg (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par: Parameter T (T ist die Zeit, nach der der Ausgang eingeschaltet wird)
```

Beispiel:
```
27 80 02 00 FF FF 36 81 00 00 00 00
```
Remanenz aktiv, Parameterschutz aktiv, Trg = I3, R = -, 05:10 (h:m)

## <a name="SF2B"></a>Vor-/Rückwärtszähler
Der Zähler erfasst binäre Impulse am Eingang _Cnt_ und zählt den internen Zähler _Z_ vom Datentyp _ZD_ hoch oder runter. Über den Eingang _Dir_ (`0`:Z=Z+1, `1`:Z=Z-1) wird zwischen Vorwärts- und Rückwärtszählen umgeschaltet. Der interne Zähler _Z_ kann durch den Rücksetzeingang _R_ auf den Wert `0` zurückgesetzt werden. Über den Parameter _On_ oder _Off_ wird die Schaltschwelle für den Ausgang _Q_ definiert. Sofern der Zähler _Z_ die obere Schaltschwelle (Z > On) erreicht bzw. überschreitet wird der Ausgang _Q_ auf `1` und bei erreichen bzw. unterschreiten der unteren Schaltschwell (Z < Off) wird Q auf `0` gesetzt. Der Wertebereich für _On_, _Off_ und _Z_ ist von 0 bis 999999.

RAM/REM: 24/5

Darstellungsformat:
```
send> 05 0F 00 00 18
recv< 06
2B 40 FF FF FF FF FF FF 3F 42 0F 00 BC 6C 06 00 00 00 00 00 00 00 00 00 CF
2B 40 [FF FF] [FF FF] [FF FF] [3F 42 0F 00] [BC 6C 06 00] 00 00 00 00 00 00 00 00
SF Pa [R    ] [Cnt  ] [Dir  ] [On         ] [Off        ] 00 00 00 00 00 00 00 00
SF Pa [R    ] [Cnt  ] [Dir  ] [Par                      ] 00 00 00 00 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

R: Eingang R (Co oder GF/SF)
Cnt: Eingang Cnt (Co oder GF/SF)
Dir: Eingang Dir (Co oder GF/SF)
Par:
  On: Einschaltschwelle (0 ... 999999)
  B1 B2 B3 B4
      \ /
      / \
  B4 B3 B2 B1
  00 0F 42 3F = 999999

  Off: Ausschaltschwelle (0 ... 999999)
  B1 B2 B3 B4
      \ /
      / \
  B4 B3 B2 B1
  00 06 6C BC = 421052
```

## <a name="SF2D"></a>Asynchroner Impulsgeber
Mit der Funktion _Asynchroner Impulsgeber_ können wird der Ausgang _Q_ für eine vorprogrammierte Zeitdauer _TH_ gesetzt und für eine vorprogrammierte Zeitdauer _TL_ zurückgesetzt. Die Funktion startet, wenn das Signal am Eingang _En_ von `0` auf `1` (positive Flanke) wechselt. Mit dem Start läuft die programmierte Zeitdauer _TH_ bzw. _TL_ ab. Der Ausgang _Q_ wird für die Zeitdauer _TH_ gesetzt und für _TL_ zurückgesetzt. Über den Eingang _Inv_ lässt sich der Ausgang _Q_ des Impulsgeber invertieren. Die aktuelle Zeit _Ta_ vom Datentyp _TW_ bennent die Zeitdauer des letzten Flankenwechsels (wechsel von `1` auf `0` bzw. von `0` auf `1`) von Ausgang _Q_. 

RAM/REM: 12/3

Darstellungsformat:
```
2D 40 02 00 FF FF 02 80 02 80 00 00
2D 40 [02 00] [FF FF] [02 80] [02 80] 00 00
SF Pa [En   ] [INV  ] [TH   ] [TL   ] 00 00
SF Pa [En   ] [INV  ] [Par          ] 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

En: Eingang En (Co oder GF/SF)
INV: Eingang INV (Co oder GF/SF)
Par:
  TH: Parameter TH (Impulsdauer), siehe Zeitverhalten
  TL: Parameter TL (Impulspausendauer), siehe Zeitverhalten
```

## <a name="SF39"></a>Analogwertüberwachung

RAM/REM: 20/-

Darstellungsformat:
```
39 40 FD 00 92 00 C8 00 66 00 00 00 00 00 00 00 00 00 00 00
39 40 [FD 00] [92 00] [C8 00 66 00 00 00 00 00 00 00 00 00 00 00
SF Pa [En   ] [Ax   ] [Par ... 
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi --+--+--+--*++++ Lo
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein; * REM (Def)
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Def)

En: Eingang En (Co oder GF/SF)
Ax: Eingang Ax (Co oder GF/SF)
Par:
  A: Verstärkung (Gain) (+/-10,00)
  B: Nullpunktverschiebung (Offset) (+/-10000)
  Delta: Differenzwert unter Aen-/Ein-/Ausschwellwert (+/-20000)
  p: Anzahl der Nachkommastellen (0,1,2,3)

  C8 = 1100 1000 = 200
  66 = 0110 0110 = 102
```

----------

# <a name="Kapitel5"></a>Kapitel 5 - Sonstiger Speicher

## <a name="1E00"></a>Speicherbereich 1E00

```
send>
02 1E 00
02 1E 01
02 1E 02
02 1E 03
02 1E 04
02 1E 05
02 1E 06
02 1E 07
recv< 00 00 00 00 00 00 00 00
```

## <a name="2000"></a>Speicherbereich 2000

```
send>
02 20 00
02 20 01
02 20 02
02 20 03
02 20 04
02 20 05
02 20 06
02 20 07
recv< 00 00 00 00 00 00 00 00
```

## Speicherbereiche 0522, 055E-5F

AI7-> AM6-> AQ2 / AI2-> AM6-> AQ2

0522
```
00 | 74 / 00 | 00
```

055E
```
53 | 53 / 4E | 4E
```

055F
```
09 | 09 / 09 | 09
```

```
74 = 0111 0100
53 = 0101 0011
09 = 0000 1001
```

## Erfassbare Daten mit Befehl `55`
Die Tabelle zeigt die erfassbaren Variablen und Parameter inkl. zugehörigen Datentyp, die über den Befehl `55` abgefragt werden können. Die Angabe VB, VW oder VD (Byte =1, Wort = 2 oder Doppelwort = 4) gibt gleichzeitig die Anzahl der Bytes vor, die der Datentyp benötigt. 

Blockbeschreibung                 | Variable/Parameter:Datentyp(en)                   | VM-Syntax             | Beispiel
----------------------------------|---------------------------------------------------|-----------------------|-----------
Einschaltverzögerung              | Ta:VW,VB; T:VW,VB                                 | T[a]<vm>,<n>          | `Ta100,6`
Ausschaltverzögerung              | Ta:VW,VB; T:VW,VB                                 | T[a]<vm>,<n>          | `T110,3`
Ein-/Ausschaltverzögerung         | Ta:VW,VB; TH:VW,VB; TL:VW,VB                      | T(aHL)<vm>,<n>        | `TH120,6`
Speichernde Einschaltverzögerung  | Ta:VW,VB; T:VW,VB                                 | T[a]<vm>,<n>          | `Ta130,3`
Wischrelais (Impulsausgabe)       | Ta:VW,VB; T:VW,VB                                 | T[a]<vm>,<n>          | `Ta140,6`
Flankengetriggertes Wischrelais   | Ta:VW,VB; TH:VW,VB; TL:VW,VB; N:VB                | (T[aHL],N)<vm>,<n>    | `N150,1`
Asynchroner Impulsgeber           | TH:VW,VB; TL:VW,VB                                | T(H,L)<vm>,<n>        | `TH160,6`
Zufallsgenerator                  | TH:VW,VB; TL:VW,VB                                | T(H,L)<vm>,<n>        | `TH170,3`
Treppenlichtschalter              | Ta:VW,VB; T:VW,VB; T!:VW,VB; T!L:VW,VB            | T[a,![L]]<vm>,<n>     | `T!L180,3`
Komfortschalter                   | Ta:VW,VB; T:VW,VB; TL:VW,VB; T!:VW,VB; T!L:VW,VB  | T[a,L,![L]]<vm>,<n>   | `Ta190,15`
Vor-/Rückwärtszähler              | Cn:VD; On:VD; Off:VD                              | (Cn,On,Off)<vm>,<n>   | `Cn200,12`
Betriebsstundenzähler             | OT:VD; MN:VW; MI:VW                               | (OT,MN,MT)<vm>,<n>    | `OT210,8`
Analogkomperator                  | A:V_; B:V_; On:VW; Off:VW; p:VB                   | (AB,On,Off,p)<vm>,<n> | -
Analoger Multiplexer              | V1:VW; V2:VW; V3:VW; V4;VW; p:VB; AQ:VW           | (V(1-4),p,AQ)<vm>,<n> | `V1230,2`
Rampensteuerung                   | L1:V_; L2:V_; AQ:VW; A:V_; B:V_; p:VB;            | -                     | -
PI-Regler                         | -                                                 | -                     | -

### Mögliche Anwendung
Über den Blocknamen könnten bis zu 64 Parameter einem Variablenspeicher ähnlich __0BA7__ zugeordnet werden. Die obige Tabelle zeigt neben den erfassbaren Variablen und Block-Parametern auch die zugehörige Syntax für eine mögliche Anwendung mit einem Variablenspeicher. 

Im Folgenden die VM-Adressierung mit zugehörigem Datentyp nach __0BA7__:
```
V B 100
| | '--- Adresse des Byte
| '----- Zugriff auf Byteformat
'------- Bereichskennung

MSB           LSB
|-+-+-+-+-+-+-+-|
|7    VB100    0|
```

```
V W 100
| | '--- Adresse des Bytes
| '----- Zugriff auf Wortformat
'------- Bereichskennung

MSB                            LSB
|-+-+-+-+-+-+-+-||-+-+-+-+-+-+-+-|
|15   VB100    8||7    VB101    0|
```

```
V D 100
| | '--- Adresse des Bytes
| '----- Zugriff auf Doppelwortformat
'------- Bereichskennung

MSB                                                             LSB
|-+-+-+-+-+-+-+-||-+-+-+-+-+-+-+-||-+-+-+-+-+-+-+-||-+-+-+-+-+-+-+-|
|31   VB100   24||23   VB101   16||15   VB102    8||7    VB103    0|
```

# Anhang

## <a name="Ressourcen"></a>__0BA5__ Ressourcen
Das Handbuch beschreibt ausschließlich das _LOGO!_ Gerät in der Version __0BA5__. Die folgend genannten Ressourcen dienen der Vergleichbarkeit und sind aus LOGO!Soft Comfort ausgelesen:
- Funktionsblöcke: 130
- REM: 60
- Digitaleingänge: 24
- Digitalausgänge: 16
- Merker: 24
- Analogeingänge: 8
- Meldetexte: 10
- Analogausgänge: 2
- Programmzeilenpeicher: 2000
- Blocknamen: 64
- Analoge Merker: 6
- Cursortasten: 4
- Schieberegister: 1
- Schieberegisterbits: 8
- Offene Klemme: 16

## Verwendete Abkürzungen
- __0BA5__: _LOGO!_ Kleinsteuerung der 6.Generation (wird in diesem Handbuch beschrieben).
- __B001__: Block Nummer B1
- __Cnt__ (_Count_): Zählimpulse
- __Co__ (_Connector_): Klemme
- __Dir__ (_Direction_): Festlegung der Richtung
- __En__ (_Enable_): aktiviert die Funktion eines Blocks.
- __Fre__ (_Frequency_): Auszuwertende Frequenzsignale
- __GF__: Grundfunktionen
- __Inv__ (_Invert_): Ausgangssignal des Blocks wird invertiert
- __No__ (_Nocken_): Parameter der Zeitschaltuhr
- __Par__: Parameter
- __R__ (_Reset_): Rücksetzeingang
- __Ral__ (_Reset all_): internen Werte werden zurückgesetzt
- __S__ (_Set_): Eingang wird gesetzt
- __SF__: Sonderfunktionen
- __T__ (_Time_): Zeit-Parameter
- __Trg__ (_Trigger_): Ablauf einer Funktion wird gestartet
