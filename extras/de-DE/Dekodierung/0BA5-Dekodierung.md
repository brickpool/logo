# Undocumented LOGO! __0BA5__
## Aufbau, Funktionsweise und Programmierung

Ausgabe Ar

Juni 2018

## Vorwort
Dieses Handbuch beschreibt die Interna einer _LOGO!_ Kleinsteuerung Version __0BA5__, um unter Nutzung der PG-Schnittstelle darauf zuzugreifen. Die PG-Schnittstelle verwendet hierzu ein nicht dokumentiertes Protokoll zum Programm laden, lesen und zur Diagnose. 

Die hier beschriebenen Informationen und Beispiele sind unverbindlich und dienen der allgemeinen Verständnis über Aufbau, Adressierung und Anwendung der Systeminterna. Die eigene Kleinsteuerung kann sich hiervon unterscheiden. 

Für einen ordnungsgemäßen Betrieb ist der Benutzer selbst verantwortlich. Verweisen möchte ich auf die jeweils gültigen Handbücher und Vorgaben und systembezogenen Installationsvorschriften vom Hersteller.

_Siemens_ und _LOGO!_ sind eingetragene Marken der Siemens AG.

## Verwendete oder weiterführende Publikationen
Wertvolle Informationen finden Sie in den folgenden Veröffentlichungen:
  * [LOGO! Handbuch Ausgabe 05/2006](http://www.google.de/search?q=A5E00380834-02), Bestellnummer 6ED1050-1AA00-0AE6
  * [SPS Grundlagen](http://www.sps-lehrgang.de/ "SPS Lehrgang")
  * [Translation Method of Ladder Diagram on PLC with Application to an Manufacturing Process](http://www.google.de/search?q=A+Translation+Method+of+Ladder+Diagram+on+PLC+with+Application+to+an+Manufacturing+Process) von Hyung Seok Kim und weiteren Autoren

Einzelheiten zum _LOGO!_-Adresslayout finden Sie in den folgenden Veröffentlichungen:
  * neiseng @ [https://www.amobbs.com](https://www.amobbs.com/thread-3705429-1-1.html "Siemens LOGO! Pictures") dekodierte den Datenadressraum einer __0BA5__ (@post 42)

## Inhalt

  * [Kapitel 1 - Architektur](#Kapitel1)
    * [Systemarchitektur](#systemarchitektur)
    * [Speicherarchitektur](#speicherarchitektur)
    * [Adressübersicht](#Adresslayout)
  * [Kapitel 2 - Parameterspeicher](#Kapitel2)
    * [Displayinhalt nach Netz-Ein](#0552)
    * [Analogausgang im STOP-Modus](#0553)
    * [Programmname](#0570)
    * [Verweis auf Blocknamen](#05C0)
    * [Blockname](#0600)
    * [Textfeld](#0800)
    * [Ident und Firmware Version](#1F02)
    * [Passwort vorhanden](#48FF)
    * [Echtzeituhr](#FB00)
  * [Kapitel 3 - Klemmenspeicher](#Kapitel3)
    * [Konstanten und Klemmen - Co](#Co)
    * [Verweis auf Ausgänge, Merker](#0C00)
    * [Digitalausgänge - Q](#0E20)
    * [Merker - M](#0EC0)
    * [Analogausgänge, Analoge Merker - AQ, AM](#0E84)
  * [Kapitel 4 - Programmzeilenspeicher](#0EE8)
    * [Blöcke und Blocknummern](#Blockbeschreibung)
    * [Verweis auf Blöcke](#0C14)
    * [Grundfunktionen - GF](#GF)
    * [Sonderfunktionen - SF](#SF)
    * [Grundwissen Sonderfunktionen](#Grundwissen-SF)
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
    * [Speicherbereiche 0522](#0522)
    * [Schaltprogramm Checksum](#055E)
    * [Erfassbare Daten](#erfassbare-daten)
  * [Anhang](#anhang)
    * [0BA5 Ressourcen](#Ressourcen)
    * [Verwendete Abkürzungen](#Abk)

----------

# <a name="Kapitel1"></a>Kapitel 1 - Architektur

## Systemarchitektur
Das _LOGO!_ Basismodul ist das Herzstück. In dem Basismodul wird das Schaltprogramm sequentiell und zyklisch abgearbeitet, sowie alle logischen Funktionen ausgeführt. Das Basismodul besitzt neben den installierten Ein-/Ausgängen (_I_/_Q_) eine Verbindungsschnittstelle zum Programmiergerät (_PC/PG_) und eine BUS-Erweiterung, um angeschlossenen Erweiterungsmodulen zu kommunizieren. 

Innerhalb des Basismoduls sind verschiedene Systembereiche untergebracht, damit die verschieden Vorgänge ablaufen können. Im folgenden Bild ist der Aufbau schematisch dargestellt.
```
            .------------------------.
            | Eingänge               |
            '------------------------'
    ..........|..|..|..|..|..|..|..|..........
              v  v  v  v  v  v  v  v         
.---+------------------------------------.   
|   | PE      O  O  O  O  O  O  O  O     |    :
|   +------------------------------------+    :
|   |       .-------> PG-Schnittstelle ### <--:--> Programmiergerät
|   |       v                            |    :
|   | .------------.----------.--------. |    :
|   | | Steuereinh.| Speicher | Zähler | |    :
| P | '-----o------'-----o----'----o---' |    :
| S |  =====|=====Busverbindung====|===### <--:--> Erweiterungsmodule
| U | .-----o------.-----o----.----o---. |    :
|   | | Rechenwerk | Merker   | Zeiten | |    :
|   | '------------'----------'--------' |
|   |                                    |
|   +------------------------------------+
|   | PA      O  O  O  O  O  O  O  O     |
'---+------------------------------------'
    ..........|..|..|..|..|..|..|..|..........
              v  v  v  v  v  v  v  v
            .------------------------.
            | Ausgänge               |
            '------------------------'

```
>Abb: Schema Systembereiche

Zu den Systembereichen eines Basismoduls gehören:
- Steuereinheit
- Rechenwerk
- Speicher
- Prozessabbild der Eingänge (_PE_)
- Prozessabbild der Ausgänge (_PA_)
- Zeiten
- Zähler
- Merker

Zur Peripherie gehören
- Stromversorgung (_PSU_)
- PG-Schnittstelle und Progammiergerät (PC mit LOGO!Soft Comfort)
- Eingänge (Eingangsklemmen)
- Ausgänge (Relais: LOGO! R/RC/RCo, Transitoren:_LOGO!_ 24/24o)
- Erweiterungsmodule (DM8, DM16, AM2, CM)


### Steuereinheit
Die Steuereinheit wird verwendet, um den gesamten Ablauf innerhalb des Basismoduls zu koordinieren. Dazu gehören u.a. die Koordination der internen Vorgänge und der Datentransport.

Die Übersetzung des Schaltprogramms in ausführbare Anweisungen erfolgt sobald _LOGO!_ in den Betriebszustand _RUN_ wechselt. Die Verknüpfungen vom Schaltprogramm werden aus dem Ladespeicher gelesen, in einem Zwischencode (Steuerungsprogramm) übersetzt und in den Arbeitsspeicher gehalten (1).

Kennzeichen einer jeden SPS ist die über die Firmware gesteuerte zyklische Programmabarbeitung, so auch bei der LOGO! Kleinsteuerung. Im Betriebszustand _RUN_ führt die LOGO! die Anweisungem vom Schaltprogramm zyklisch aus. Die Steuereinheit ruft bei jedem Zyklus das Steuerungsprogramm auf führt die Anweisungsbefehle Schrittweise aus. Typische Zykluszeiten liegen im Bereich von etwa 100 ms (Zykluszeit je Funktion < 0,1ms).

Ein Programzyklus wird in drei Schritten ausgeführt:
1. Zuerst erfolgt eine Initialisierung des Programmzyklus. Hierbei werden Zeiten gestartet, die Ausgänge anhand des Prozessabbildes der Ausgänge _PA_ gesetzt, sowie die Zustände der Eingänge ausgelesen und in das Prozessabbild der Eingänge _PE_ übernommen.
2. Anschließend werden die Anweisungsbefehle vom Steuerungsprogramm sequentiell abgearbeitet, wobei weitere Werte wie Zeiten, Zählern und Merker berücksichtigt werden.
3. Als letzter Schritt wird die PG-Schnittstelle für Senden/Empfangen von Daten bedient, der interne Status aktualisiert und der Zyklus beginnt erneut. 

```
.------->--------.
|                V
|  .-------------o-------------.  ...
|  | Zeiten starten            |   :
|  |...........................|   :
|  | PA auf Ausgänge abbilden  |   Initialisierung
|  |...........................|   :
|  | Eingänge auf PE abbilden  |   :
|  o---------------------------o  ...
|  | Programmausführung unter  |   :
|  | von Nutzung PE, PA sowie  |   :
|  | Zeiten, Zähler und Merker |   :
^  | 1. Anweisung              |   Ausführung,
|  | 2. Anweisung              |   Steuerungsprogramm
|  | ...                       |   :
|  | n. Anweisung              |   :
|  o---------------------------o  ...
|  | Senden/Empfangen von      |   :
|  | Daten der                 |   :
|  | PG-Schnittstelle          |   Daten austauschen,
|  |...........................|   Status aktualisieren
|  | Status aktualisieren      |   :
|  '-------------o-------------'  ...
|                V
'-------<--------'
```
>Abb: Schematische Darstellung Prozessabbild

Die Steuereinheit ist über die Busverbindung mit den anderen Systembereichen wie Rechenwerk, Zeiten, Zähler usw. verbunden. Unmittelbar nach Anlegen der Netzspannung werden die remanenten Zähler, Zeiten und Merker sowie die Prozessabbilder der Eingänge und Ausgänge gesetzt.


### Rechenwerk
Der Begriff wird häufig synonym mit Arithmetisch-Logischen Einheit (_ALU_) gebraucht, genau genommen stellt eine _ALU_ jedoch lediglich die zentrale Komponente eines Rechenwerks dar, das zusätzlich aus einer Reihe von Hilfs- und Statusregistern besteht. Die _ALU_ selbst enthält hingegen keine Registerzellen und stellt somit ein reines Schaltnetz dar.

Beim Ausführen von Operationen verknüpft die _ALU_ zwei Binärwerte (Akku1 und Akku 2) mit gleicher Stellenzahl miteinander und stellt das Ergebnis der Rechenoperation in Akku 1 zur Verfügung. Es können sowohl Bit, Byte oder Wortoperationen durchgeführt werden. 

```
/---------------------------------------------------\
<                 Datenbus 16 bit                   >
\---------------------------------------------------/
          ^                               |
          |                               |
          v                               v
|--- Akku1 16bit ---|           |--- Akku2 16bit ---|
|++++*++++|++++*++++|-.       .-|++++*++++|++++*++++|
          ^           |       |
          |           v       v       .-------------.
          |          .-.     .-. <--- | Ablauf-     |
          |          \  \___/  / ---> | Steuerung   |
          |           \  ALU  /       +-------------+
          |            \_____/        | Status/Flag-|
          |               |           | Register    |
          '-------<-------'           '-------------' 
```
>Abb: Schematische Darstellung Arithmetisch-Logischen Einheit

### Zeiten, Zähler und Merker
Für diese Systembereiche sind eigene Speicherbereiche vorhanden, in denen die Steuereinheit die Daten entsprechend den Datentypen ablegt. Merker sind interne Ausgänge, in die Zwischenergebnisse gespeichert werden. Auf sie kann lesend und schreibend zugegriffen werden. Merker sind flüchtig, die bei Spannungsausfall ihre Daten verlieren.

### Prozessabbild der Eingänge und Ausgänge
Die Zustände der Eingänge und Ausgänge werden in den Speicherbereichen _PE_ und _PA_ gespeichert. Auf diese Daten wird während der Programmbearbeitung zugegriffen. 

```
   :                           :
   o---------------------------o
   |    I1-I24/AI1-8 => PE     |
   |...........................|
   | Eingänge lesen und Werte  |  
   | in das "Prozessabbild der |
   | Eingänge" (PE) schreiben  |
   o---------------------------o
   :                           :
   :                           :
   o---------------------------o
   |    PA => Q1-16/AQ1-2      |
   |...........................|
   | Ausgänge setzen anhand    |
   | der Werte vom "Prozess-   |
   | abbild der Ausgänge" (PA) |
   o---------------------------o
   :                           :
```
>Abb: Schema _PE_ und _PA_ im Programmzyklus

### Programmierschnittstelle (PG)
Die _LOGO!_ Kleinsteuerung besitzt eine PG-Schnittstelle, um die Verbindung zum Programmiergerät/PC herzustellen. Im Betriebszustand _STOP_ kann über die Schnittstelle das Schaltprogramm zwischen PC und Basismodul (und umgekehrt) übertragen werden, sowie Parameter (Echtzeituhr, Displayanzeige, Passwort, Programmname) gesetzt werden. Im Betriebszustand _RUN_ können mittels der _Online-Test_-Funktion aktuelle Werte (Eingänge, Ausgänge, Zustände, Zeiten, Zähler etc.) ausgelesen werden. Die Schnittstelle dient leider nicht zum Anschluss von Erweiterungsbaugruppen oder Bedien- und Beobachtungsgeräten wie bei einer Standard SPS. 

_N_ nicht unterstützt, _R_ lesen unterstützt, _W_ schreiben unterstützt

Funktion, Datenelement| _RUN_ | _STOP_
----------------------|-------|-------
Netz-Ein Anzeige      | N     | R/W
Wert _AQ_ bei _STOP_  | N     | R/W
Passwort              | N     | R/W
Programmname          | N     | R/W
Blockname             | N     | R/W
Meldetexte            | N     | R/W
Schaltprogramm        | N     | R/W
Parameter             | N     | R/W
Ident Nummer          | R     | R
Firmware              | N     | R
Echtzeituhr           | N     | R/W
Blocksignalzustand    | R     | N
Digitaleingänge _I_   | R     | N
Digitalausgänge _Q_   | R     | N
Digitale Merker_ M_   | R     | N
Cursor _C_            | R     | N
Schiebregisterbits _S_| R     | N
Analoge Eingänge _AI_ | R     | N
Analoge Ausgänge _AQ_ | R     | N
Analoge Merker _AM_   | R     | N
Aktuelle Zeitwerte    | R     | N
Aktuelle Zählerwerte  | R     | N
Aktuelle Analogwerte  | R     | N
>Tab: Unterstützte Datenkommunikation mit Programmiergerät

### Bussystem
Das Bussystem kann unterteilt werden in ein Rückwandbus und Peripheriebus. Der Rückwandbus ist ein interner Bus der optimiert ist für die interne Kommunikation im Basismodul. Der Peripheriebus wird auch als _P-Bus_ bezeichnet. Hierüber läuft der Datenverkehr zwischen dem Basismodul und den Erweiterungsmodulen. An der rechten Seite vom Basismodul befindet dich die Schnittstelle für den _P-Bus_. Über Busverbinder werden die Erweiterungsmodule an den P-Bus vom Basismodul verbunden.

Hinsichtlich der Spannungsklassen gelten Regeln, die beim Verbinden mit dem _P-Bus_ beachtet werden müssen! Detaillierte Informationen zur Integration der Erweiterungs- bzw. Kommunikationsmodule (Einbaureihenfolge etc.) finden sich im _LOGO!_ Handbuch. 

## Speicherarchitektur
Der Speicherbereich innerhalb eines Basismoduls ist in mehrere Bereiche aufgeteilt, wobei jeder Speicherbereich eigene Aufgaben erfüllt. Vereinfacht gesagt besteht der Speicher im Basismodul aus dem Ladespeicher, dem Arbeitsspeicher und dem Systemspeicher. 

Zusätzlich ist die Firmware mit untergebracht. Die Firmware sorgt dafür, dass das Programm in der korrekten Reihenfolge abgearbeitet wird. Für die Firmware ist ein eigener Festwertspeicher im Basismodul vorhanden. 

Folgend die Auflistung der verwendeten Speichertypen: 
- [Festwertspeicher](#festwertspeicher)
- [Ladespeicher](#ladespeicher)
- [Arbeitsspeicher](#arbeitsspeicher)
- [Systemspeicher](#systemspeicher)

Die Programmbearbeitung erfolgt ausschließlich im Bereich von Arbeitsspeicher und Systemspeicher. Die folgende Abbildung veranschaulicht das Zusammenspiel:
```
   Ladespeicher          Arbeitsspeicher         Systemspeicher
.-----------------.     .---------------.     .-------------------.
| Klemmenspeicher |--1->| Interpreter   |--.  | Prozessabb. Eing. |
| Programmzeilen- |     |...............|  |  |...................|
| speicher        |  .->| Funktionen    |  |  | Prozessabb. Ausg. |
|.................|  |  |...............|  2  |...................|
| Passwort        |  5  | Programmdaten |  |  | Zeiten (T)        |
| Programmname    |  |  | Anweisungs-   |  |  | Zähler (C)        |
| ...             |  '--| befehle (4)   |<-'  | Merker (M)        |
|                 |     | ...           |     |...................|
|                 |     |               |     | Stack             |
|                 |     |               |<-3->|...................|
|                 |     |               |     | Statusdaten       |
|                 |     |               |     | ...               |
'-----------------'     '---------------'     '-------------------'
```
>Abb: Speicher Blockdiagramm

### Festwertspeicher
Der Festwertspeicher ist ein Nur-Lese-Speicher (engl. Read Only Memory, kurz _ROM_). Hierauf befindet sich die _LOGO!_ Firmware, welche vom Hersteller Siemens stammt. _Read Only_ deshalb, weil der Speicher nicht gelöscht oder geändert werden kann und zudem nicht flüchtig ist. Bei Spannungsausfall bleiben die Daten erhalten. 

### Ladespeicher
Alle Konfigurationsdaten sind im Ladespeicher vom Basismodul gespeichert. Unter anderem das Anwenderprogramm, sowie die Funktionsparameter und evtl. noch Passwort, Programmname, Meldetexte und Blocknamen. Der Ladespeicher ist ein digitaler Flash-EEPROM Speicherbaustein. Die Daten bleiben auch bei Spannungsausfall erhalten. Über die Schnittstelle zum Programmiergerät werden die Schaltdaten inkl. der Konfiguration (kurz Schaltprogram) in den Ladespeicher geladen.

### Arbeitsspeicher
Beim Arbeitsspeicher (engl. Random Access Memory, kurz _RAM_) handelt es sich um einen flüchtiger Speicher, d.h. der Inhalt geht nach einem Spannungsausfall verloren. Er ist als ein Schreib-/Lesespeicher konzipiert.

Im Arbeitsspeicher werden die ablaufrelevanten Programm- und Datenbausteine sowie Konfigurationsdaten abgelegt (4). Der Arbeitsspeicher dient zur Abarbeitung, sowie zur Bearbeitung der Daten des Steuerungsprogramms (5). Dazu werden die vom Ladespeicher ablaufrelevanten Teile des Schaltrogramms beim Wechsel vom Betriebszustand _STOP_ nach _RUN_ geladen (1) und von einem Interpreter übersetzt und das Ergebnis als Steuerungsprogramm im Arbeitsspeicher gespeichert (2).

### Systemspeicher
Der Systemspeicher ist ein flüchtiger Speicher (_RAM_) und in Operandenbereiche aufgeteilt. Im Systemspeicher werden die Zustände der Eingänge und Ausgänge über das Prozessabbild (_PE_ und _PA_), die Zeiten (_T_), Zähler (_C_), Merker (_M_) und der Stack und Statusdaten gespeichert. Während eine Programzyklus werden auf die Datem im Systemspeicher zugegriffen und Programmzustände aktualisiert (3). 

### Adressierung
_LOGO!_ __0BA5__ nutzt eine 16-Bit-Adressierung. Vereinfacht dargestellt bedeutet dies, dass die Speicherarchitektur so ausgelegt ist, dass jede Speicherstelle durch einen 16Bit-Zeiger (also 2 Byte) direkt adressiert werden kann. Die _LOGO!_ Kleinsteuerung __0BA5__ nutzt teilweise eine Segmentierung, sodass auch 8Bit-Zeiger (Verweise) zu Anwendung kommen, um eine Speicherstelle zu adressieren. 

### Speichereinheit
Die kleinste adressierbare Einheit (Speicherstelle) ist ein Byte. Es besteht aus 8 Bits und sein Inhalt wird hier mit zwei hexadezimalen Ziffern angegeben, wobei jede Ziffer für 4 Bits entsprechend einem Halb-Byte steht. Das Halb-Byte wird hier teilweise auch als [Nibble](#http://de.wikipedia.org/wiki/Nibble) bezeichnet. Es umfasst eine Datenmenge von 4 Bits. 

Bei Bitdarstellungen werden die Bits innerhalb einer Binärzahl nach [LSB-0](http://de.wikipedia.org/wiki/Bitwertigkeit) nummeriert, d.h. gemäß ihrer absteigenden Wertigkeit (gelesen von links nach rechts) ist das Bit0 (= das Bit Index 0) das niedrigstwertige. 

Darstellung:
```
    |<-------------Byte------------>|
    .---.---.---.---.---.---.---.---. 
MSB | 7   6   5   4 | 3   2   1   0 | LSB
    '---'---'---'---'---'---'---'---'
    |<----Nibble--->|<----Nibble--->|
```
>Abb: Byte, Nibble

### Byte-Reihenfolge
Die Byte-Reihenfolge im _LOGO!_ ist [Little-Endian](http://de.wikipedia.org/wiki/Byte-Reihenfolge), sprich das kleinstwertige Byte wird an der Anfangsadresse gespeichert bzw. die kleinstwertige Komponente zuerst genannt.

Beispiel:
```
16bit Wert
.--.--.
|0A 0B|  
'--'--'  Speicher
 |  |     :____:
 |  '---->| 0B | Adresse a
 '------->| 0A | Adresse a+1
          :    :
```
>Abb: Byte-Reihenfolge im Speicher bei Little-Endian

## <a name="Adresslayout"></a>Adressübersicht
Das folgende Adresslayout ist ein Abbild des dekodierten Ladespeichers einer _LOGO!_ __0BA5__. Auf den Lagespeicher kann (bis auf wenige Ausnahmen) nur im Betriebszustand _STOP_ zugegriffen werden. 

### Parameter
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
|             | [0522](#0522)        | 1     | W |                                                        |
|             | [0552](#0552)        | 1     |   | Displayinhalt nach Netz-Ein                            |
| 05 53 00 05 | [0553](#0553) - 0558 | 5     |   | Einstellung des Analogausgangs im Betriebszustand _STOP_ |
| 02 05 5E    | [055E](#055E)        | 1     |   | Schaltprogramm Checksum HiByte                         |
| 02 05 5F    | [055F](#055E)        | 1     |   | Schaltprogramm Checksum LoByte                         |
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
| 0E E8 07 D0 | [0EE8](#0EE8) - 16B8 | 2000  |   | Programmzeilenspeicher                                 |

### Firmware
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 02 1F 00    | 1F00        | 1     |   |                                                        |
| 02 1F 01    | 1F01        | 1     |   |                                                        |
| 02 1F 02    | [1F02](#1F02)        | 1     | R | Ident Nummer                                           |
| 02 1F 03    | [1F03](#1F02) - 1F08 | 5     | R | Revision der Firmware                                  |

### Systemfunktion Echtzeituhr, S/W
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
|             | 4100        | 1     | W |                                                        |
| 01 43 00 00 | [4300](#FB00)        | 1     | W | Werte speichern: RTC=00                                |
| 01 43 01 00 | [4301](#FB00)        | 1     | W | Werte speichern: S/W=00                                |
| 01 44 00 00 | [4400](#FB00)        | 1     | W | Werte laden: RTC=00                                    |
| 01 44 01 00 | [4400](#FB00)        | 1     | W | Werte laden: S/W=00                                    |

### Systemfunktion Passwort
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 01 47 40 00 | 4740        | 1     | W | = 00, Passwort lesen/setzen initialisieren             |
| 01 48 00 00 | 4800        | 1     | W |                                                        |
| 02 48 FF    | [48FF](#48FF)        | 1     | R | Passwort vorhanden?                                    |

### Parameter Echtzeituhr
| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
| 02 FB 00    | [FB00](#FB00) - FB05 | 6     |   | Echtzeituhr, Sommer-/Winterzeitumstellung              |


__Hinweis:__
Maximaler Bereich = 0E 20 08 98 Adr. 0E20 - 16B8

----------

# <a name="Kapitel2"></a>Kapitel 2 - Parameterspeicher

## <a name="0552"></a>Displayinhalt nach Netz-Ein
Mit Displayinhalt nach Netz-Ein wird festgelegt, was auf dem Display der _LOGO!_ angezeigt wird, wenn Sie diese eingeschaltet wird. 

Die Festlegung des Displayinhaltes nach Netz-Ein ist Teil der Parametereigenschaften (vergl. _S7_ Systemdatenbaustein) und wird beim Übertragen des Schaltprogramms ebenfalls übertragen und auf der _LOGO!_ gespeichert.

Speicherbereich: 0552, 1 Byte

Zugriffsmethode: Lesen und Schreiben

### Darstellungsformat im Ladespeicher
```
send> 02 05 52 
recv< 06
03 05 52 00
```

```
05 52 00
05 52 [Val]

Val:
  00 = Text
  01 = Ein-/Ausgänge
  FF = Datum/Uhrzeit
```

## <a name="0553"></a>Analogausgang im Betriebszustand _STOP_
Analogausgänge können nach einem Wechsel von _RUN_ in _STOP_ auf vordefinierte Ausgangswerte oder auf die Werte, die vor dem Wechsel in den Betriebszustand _STOP_ vorhanden waren, gesetzt werden.

Das Verhalten der Analogausgänge im Zustand _STOP_ ist Teil der Parametereigenschaften (vergl. _S7_ Systemdatenbaustein) und wird beim Übertragen des Schaltprogramms ebenfalls übertragen und auf der _LOGO!_ gespeichert.

Speicherbereich: `0553..0558`, Anzahl = 5 Bytes

Abfrage:
```
send> 05 05 53 00 05 
recv< 06
00 C4 03 D5 01
13
```

Wertebereich: 0.00 - 9.99

### Darstellungsformat im Ladespeicher
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

Speicherbereich: `05C0..0600`, 64 Bytes

Folgend die Schematische Darstellung der Adressverweis auf die Programmzeilenspeicher:
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
>Abb: Adressverweis Blocknamen

__Hinweis:__ Es können maximal 64 Blöcke einen Blocknamen erhalten.

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
>Tab: Auswertung Beispiel _Adressverweis Blocknamen_

## <a name="0600"></a>Blockname
In LOGO!Soft Comfort können für bis zu 64 Blöcke achtstellige Blocknamen vergeben werden.

Speicherbereich: `0600..0800`, 512 Bytes (8 * 64)

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
Ein Meldetext belegt 64 Bytes: jeweils 4 Zeilen a 12 Bytes für `<Daten/Zeichen>` zzgl. 2 Bytes `<Header-Daten>` und 2 Bytes `00 00`.

Speicherbereich: `0800..0A80`, 640 Bytes (10*4*16)

Vergl. _S7_ Datenbaustein

Standarddaten:
```
FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 // (40x)
...
```

### Darstellungsformat im Ladespeicher
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
  01: Reiner Text
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

## <a name="1F02"></a>Ident und Firmware Version
Software _Version_ und _Release_ sind nicht offengelegt. _Siemens_ pflegt üblicherweise Bezeichnungen für (geplante) veröffentlichte Entwicklungsstände, die hier jedoch nicht 1:1 angewandt werden können. Zur Benennungen der Firmware verwendet dieses Handbuch den Begriff _Version_. Die verwendete _LOGO!_ Hardware wird über eine Kennung kurz _Ident Nummer_ identifiziert. 

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
>Abb: Aufdruck auf Chip

Befehle:
```
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
recv< 06 03 1F 08 32
```
Auswertung:

Read Byte | HEX | BIN       | Bedeutung
----------|-----|-----------|-------------
1F02      | 42  | 0100 0010 | Ident = 0BA5
>Tab: Ident Nummer

Read Byte | HEX | DEC | ASCII
----------|-----|-----|------
1F03      | 56  | 86  | V
1F04      | 32  | 50  | 2
1F05      | 30  | 48  | 0
1F06      | 32  | 50  | 2
1F07      | 30  | 48  | 0
1F08      | 32  | 50  | 2
>Tab: Speicheradressen der Firmware Version

Firmware = V2.02.02

## <a name="48FF"></a>Passwort vorhanden
_LOGO!_ __0BA5__ bietet einen Passwortschutz, um den Zugriff auf das Schaltprogramm einzuschränken. Durch das Einrichten eines Passworts kann nur nach Eingabe eines Passwortes auf das Schaltprogramm und bestimmte Parameter zugegriffen werden. Ohne Passwort ist der uneingeschränkte Zugriff auf die _LOGO!_ Ressourcen möglich.

Das Passwort hat eine Länge von 10 Zeichen. Groß- und Kleinschreibung spielt beim Passwort keine Rolle, da das Passwort in Großbuchstaben abgespeichert wird. Das Passwort ist ein Parameter (vergl. _S7_ Systemdatenbaustein) und wird beim Übertragen des Schaltprogramms auf die _LOGO!_ ebenfalls übertragen und dort gespeichert. 

### Passwort gesetzt?

Befehl:
```
send> 02 48 FF
recv< 06 03 48 FF 00
```

Read Byte | Wert | Beschreibung
----------|------|-------------
48FF      | 40   | ja
48FF      | 00   | nein
>Tab: Passwort gesetzt/nicht gesetzt

### Passwort R/W
Ein Schaltprogramm mit Passwort sollte geschützt bleiben. Das Knacken eines Passwortes ist nicht Zielsetzung dieser Beschreibung, daher sind die Systemfunktionen und Befehlsfolgen für das Auslesen und Setzen des Passwortes hier nicht beschrieben. 

## <a name="FB00"></a>Echtzeituhr, S/W
Alle Datums- und Zeitwerte sind Bytewerte. Die Echtzeituhr (RTC) startet nach längerem Stromausfall oder nach Speicherverlust mit folgendem Datum und folgender Zeit:
- Datum: `01-Jan-2003`
- Zeit: `00:00:00`
- Wochentag: Sonntag

__Hinweis:__ _LOGO!_ prüft nicht, ob der Wochentag mit dem Datum übereinstimmt.

Im LOGO! kann eine automatische Sommer-/Winterzeitumstellung (S/W) aktivieren werden. Zusätzlich können Beginn und Ende der Sommerzeit parametrisiert werden. Entweder über vordefinierte Profile (EU, UK, US, AUS, AUS-TAS, NZ) und manuell. Die Profile haben einen Zeitunterscheid von 60 Minuten. Bei der manuellen Eingabe kann eine minutengenaue Angabe von bis zu 180 Minuten hinterlegt werden. 

### Übergabespeicher
Die jeweilige Systemfunktion (SFC) für die Echtzeituhr und Sommer/Winterzeitumstellung wird über einen Schreibbefehl unter Angabe eines Parameters (1 Byte) auf eine vordefinierte Adresse (_PC->LOGO_: `4300`,`4301` / _LOGO->PC_: `4400`,`4401`) aufgerufen. Die Werte der Echtzeituhr bzw. die S/W-Parameter werden in einem dafür reservierten Speicherbereich zwischen dem Programmiergerät (_PG/PC_) und den internen _LOGO!_ Ressourcen ausgetauscht (sog. Übergabespeicher).

Speicherbereich: `FB00`, 6*1 Byte

Adresse | RTC-Wert       | S/W-Wert
--------|----------------|-----------------
FB00    | Tag            | Länderauswahl \*)
FB01    | Monat          | Ende Monat
FB02    | Jahr           | Ende Tag
FB03    | Minuten        | Beginn Monat
FB04    | Stunden        | Beginn Tag
FB05    | Wochentag \**) | Zeitverschiebung
>Tab: Übergabespeicher von Echtzeituhr und Sommer/Winterzeitumstellung

\*) 0=deaktiviert<br />
\**) 1=Sonntag, 7=Samstag

Wert | Länderauswahl
-----|-----------------------------------
00   | deaktiviert
01   | EU: Europäische Union
02   | UK: Großbritannien und Nordirland
03   | US: Vereinigte Staaten von Amerika
04   | Frei einstellbar \*)
05   | AUS: Australien
06   | AUS-TAS: Tasmanien
07   | NZ: Neuseeland
>Tab: Übergabespeicher FB00, Länderauswahl 

\*) `FB01..FB05` hat benutzerdefinierte Daten und Uhrzeiten für die Umstellung

### Echtzeituhr auslesen (LOGO->PC)
Die Systemfunktion _Echtzeituhr lesen_ (Byte `00` an Adresse `4400` schreiben) liest die aktuelle Uhrzeit und das aktuelle Datum aus der Hardware-Uhr und lädt die Werte in einen 6-Byte-Übergabespeicher, welcher an Adresse `FB00` beginnt.

Befehlsfolge:
```
send> 01 44 00 00     // Werte der Echtzeituhr laden
recv< 06              // OK
send> 02 FB XX        // XX = [00-05]
recv< 06 03 FB XX YY  // YY = Wert
```

__Hinweis:__ Der Befehl ist nicht erfolgreich, sofern _LOGO!_ nicht mit einer Echtzeituhr ausgestattet ist (`6ED1052-xCC00-0BA5`).

### Echtzeituhr setzen (PC->LOGO)
Die Systemfunktion _Echtzeituhr setzen_ (Byte `00` an Adresse `4300` schreiben) schreibt die aktuelle Uhrzeit und das aktuelle Datum der Hardware-Uhr in den 6-Byte-Übergabespeicher (Adresse `FB00..FB05`).

Befehlsfolge:
```
send> 01 FB 00 01     // Tag = 01
recv< 06              // OK
send> 01 FB 01 02     // Monat = 02 (Februar)
recv< 06              // OK
send> 01 FB 02 12     // Jahr = 18 (2018)
recv< 06              // OK
send> 01 FB 03 1E     // Minuten = 30
recv< 06              // OK
send> 01 FB 04 0C     // Stunden = 12
recv< 06              // OK
send> 01 FB 05 01     // Wochentag = 01 (Sonntag)
recv< 06              // OK
send> 01 43 00 00     // Werte in Echtzeituhr übernehmen
recv< 06              // OK
```

__Hinweis:__ Der Befehl ist nicht erfolgreich, sofern _LOGO!_ nicht mit einer Echtzeituhr ausgestattet ist (6ED1052-xCC00-0BA5).

### Sommer-/Winterzeitumstellung auslesen (LOGO->PC)
Die Systemfunktion _S/W-Umstellung lesen_  (Byte `00` an Adresse `4401` schreiben) liest die Werte für die Sommer-/Winterzeitumstellung aus der Hardware-Uhr und lädt diese in den Übergabespeicher (Adresse `FB00..FB05`).

Befehlsfolge:
```
send> 01 44 01 00     // Parameter S/W-Umstellung laden
recv< 06              // OK
send> 02 FB XX        // XX = [00-05]
recv< 06 03 FB XX YY  // YY = Wert
```

### Sommer-/Winterzeitumstellung setzen (PC->LOGO)
Die Systemfunktion _S/W-Umstellung setzen_ (Byte `00` an Adresse `4301` schreiben) schreibt die Werte für die Sommer-/Winterzeitumstellung der Hardware-Uhr in den 6-Byte-Übergabespeicher (Adresse `FB00..FB05`).

Befehlsfolge:
```
send> 01 FB 00 04     // 04 = Frei einstellbar
recv< 06              // OK
send> 01 FB 01 0A     // Sommerzeit Ende Monat = 10 (Oktober)
recv< 06              // OK
send> 01 FB 02 19     // Sommerzeit Ende Tag = 25
recv< 06              // OK
send> 01 FB 03 03     // Sommerzeit Anfang Monat = 03 (März)
recv< 06              // OK
send> 01 FB 04 05     // Sommerzeit Anfang Tag = 05
recv< 06              // OK
send> 01 FB 04 3C     // Zeitverschiebung 60 Minuten
recv< 06              // OK
send> 01 43 01 00     // Parameter S/W-Umstellung übernehmen
recv< 06              // OK
```

----------

# <a name="Kapitel3"></a>Kapitel 3 - Klemmenspeicher

## <a name="Co"></a>Konstanten und Klemmen - Co
Als Klemme werden alle Anschlüsse und Zustände bezeichnet (engl. Connectors = _Co_). Hierzu zählen Digitaleingänge, Analogeingänge, Digitalausgänge, Analogausgänge, Merker (inkl. Anlaufmerker), Analoge Merker, Schieberegisterbits, Cursortasten, Pegel und die Offenen Klemmen.

Klemmen sind Bestandteil des Schaltprogramms (vergl. _S7_ Programmbaustein) und somit Teil des Hauptprogramm (vergl. _S7_ Organisationsbaustein OB1). 

### Darstellung am Verknüpfungseingang
Sie sind nicht im Programmzeilenspeicher `0EE8` abgelegt, sondern werden mit einem festen 16bit Wert (Datentyp Word) und einem Wertebereich `0000..00FE` am Eingang eines Blocks, Merkers oder einer Ausgangsklemme dargestellt. 

Das höherwertige Byte vom Word ist immer `00`. Das niederwertige Byte vom Word (LoByte) zeigt den Klemmentyp bzw. nennt die Konstante.

LoByte HEX | Klemme/Merker | Beschreibung
-----------|---------------|-------------------------------
00-17      | I1..24        | Digitaleingänge
30-3F      | Q1..16        | Digitalausgänge
50-67      | M1..24        | Merker
80-87      | AI1..8        | Analogeingänge
92-97      | AM1..6        | Analoge Merker
A0-A3      | C1..3         | Cursortasten (▲, ▼, <, >)
B0-B7      | S1..8         | Schieberegisterbits
>Tab: Liste _Klemmen_

LoByte HEX | Konstante | Beschreibung
-----------|-----------|--------------------------
FC         | Float     | (Verwendung ??)
FD         | Pegel hi  | Blockeingang logisch = 1
FE         | Pegel lo  | Blockeingang logisch = 0
FF         | x         | nicht benutzter Anschluss
>Tab: Liste _Konstanten_

### Format im Speicher
Klemmen, die aufgrund eines Verknüpfungseinganges ein Speicherplatz besitzen, sind die Ausgänge _Q1_ bis _Q16_, _AQ1_ und _AQ2_, die Merker _M1_ bis _M24_ und _AM1_ bis _AM6_, sowie die 16 unbeschaltete Ausgänge _X1_ bis _X16_. 

Die Verdrahtung auf den Eingang einer Ausgangsklemme oder eines Merkes werden im Speicherbereich `0E20..0EC0` mit 200 Bytes (10*20 Bytes) abgelegt.

Das Format ist einheitlich und ist als vielfache von 20 Bytes = 2 Bytes `80 00` + 16 Bytes `<Daten>` + 2 Bytes `FF FF` abgelegt.
```
80 00 1a 1b ... ... 8a 8b FF FF // (20 Byte)
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
```

Na Nb: N = Element 1-8

Das folgende Beispiel zeigt, dass wie der Eingang von _Q1_ mit der Klemme _I1_ (`0000`) verbunden ist.

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

Das Beispiel zeigt auch, dass die anderen Ausgänge _Q2_-_Q16_ im Schaltprogramm nicht verwendet werden (`FFFF`).

## <a name="0C00"></a>Verweis auf Ausgänge, Merker
20 Bytes fest, die auf jeweils (weitere) 10*20 Bytes im Speicherbereich für Ausgänge und Merker verweisen. Der Verweis wird als 16 Bit-Offset-Adresse dargestellt. 

Die Adressverweise befinden sich im Speicherbereich `0C00..0C14` (10*2 Bytes).

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
>Abb: Verweis auf Ausgänge, Merker

Bereich     | Anz | Zeiger            | Beschreibung
------------|-----|-------------------|------------------------------------
0E20 - 0E48 | 40  | 0000, 0014        | Digitaler Ausgang 1-16
0E48 - 0E84 | 60  | 0028, 003C, 0050  | Merker 1-24
0E84 - 0E98 | 20  | 0064              | Analogausgang 1-2; Analogmerker 1-6
0E98 - 0EC0 | 40  | 0078, 008C        | offener Ausgang 1-16
0EC0 - 0EE8 | 40  | 00A0, 00B4        | (Reserve ??)
>Tab: Adressübersicht Ausgänge und Merker

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
HEX (Lo Hi): 00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
HEX (Hi,Lo): 00,00 00,14 00,28 00,3C 00,50 00,64 00,78 00,8C 00,A0 00,B4
Dezimal:     00    20    40    60    80    100   120   140   160   180
Speicherbedarf: 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20 -- 20
```

### <a name="0E20"></a>Digitalausgänge - Q
Die Digitalausgänge _Q1_ bis _Q16_ befinden sich im Speicherbereich `0E20..0EC0` (2*20 Bytes).

Darstellungsformat
```
80 00 Q1a Q1b ... ... Q8a  Q8b  FF FF // (20 Byte)
80 00 Q9a Q9b ... ... Q16a Q16b FF FF
```

`Q<n>a Q<n>b`: _n_ = Element 1-16

### <a name="0EC0"></a>Merker - M
Die Digitalausgänge _M1_ bis _M24_ befinden sich im Speicherbereich `0EC0..0E84` (3*20 Bytes).

Darstellungsformat:
```
80 00 M1a  M1b  ... ... M8a  M8b  FF FF // (20 Byte)
80 00 M9a  M9b  ... ... M16a M16b FF FF
80 00 M17a M17b ... ... M24a M24b FF FF
```

`M<n>a M<n>b`: _n_ = Element 1-24

### <a name="0E84"></a>Analogausgänge, Analoge Merker - AQ, AM
Die Analogen Ausgänge _AQ1_ und _AQ2_ befinden sich im Speicherbereich `0E84..0E98` (1*20 Bytes).

Darstellungsformat:
```
80 00 AQ1a AQ1b AQ2a AQ2b AM1a AM1b ... ... AM6a AM6b  FF FF // (20 Byte)
80 00 [AQ1    ] [AQ2    ] [AM1    ] ... ... [AM6    ]  FF FF // (20 Byte)

A<Xn>:
  X = Q oder M (AQ<n> oder AM<n>)
  n = 1..8

  Beispiel:
    X=Q und n=2: AQ2
  
  AXa AXb
    \ /
    / \
  AXb,AXa = AX

  AX ist ein 16bit Interger Wert
  
    |       AXb (byte)      |       AXa (byte)      |
 MSB --*--+--+--+--+--+--+--|--+--+--+--+--+--+--+-- LSB
     bF|bE ..          .. b8|b7 ..          .. b1 b0

  bF: Vorzeichenbit
    bF=1:negativ; bE..b9:Zahlenwert
    bF=0:positiv; bE..b9:Zahlenwert

  Beispiel: 
  int16_t i = AX;  // signed int
```


`AQ<n>`: _n_ = Element _AQ1-2_<br />
`AM<n>`: _n_ = Element _AM1-6_

### <a name="0E98"></a>Offene Klemmen - X
Die Offenen Klemmen _X1_ bis _X16_ befinden sich im Speicherbereich `0E98..0EC0` (2*20 Bytes).

Darstellungsformat:
```
80 00 X1a  X1b  ... ... X8a  X8b  FF FF // (20 Byte)
80 00 X9a  X9b  ... ... X16a X16b FF FF
```

`X<n>a X<n>b`: _n_ = Element 1-16

## Format im Online-Test
Die Zustände der Klemmen - Eingänge _I1_ bis _I24_, Ausgänge _Q1_ bis _Q16_, _AQ1_ und _AQ2_, Merker _M1_ bis _M24_ und _AM1_ bis _AM6_ - können im Betriebszustand _RUN_ über die PG-Schnittstelle ausgelesen werden. 

Beispielschaltprogramm:
```
               .---.B001
    .----------| & |
    |       .--|   |-- Q1
    |       |  '---' 
I1--o   I2--o
    |       |  .---.B130
    |       '--|>=1|
    '----------|   |-- Q2
               '---' 
```
>Abb: Schaltprogramm _Signalzustand im Online-Test_

Befehl:
```
send> 55 13 13 00 AA 
recv< 06 
recv< 55 11 11 40 00
6D 0A
11
2A
00
80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 52
03 00 00 03 00 00 00 00
00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00
AA 
```

### Digitale Klemmen im Modus _RUN_
Der Signalzustand für die Digitalen Eingänge _I1-24_, Ausgänge _Q1-16_ und Merker _M1-24_ kann mittels des Online-Test Befehls `55 13 13 .. AA` abgefragt werden. Der Signalzustand wird dabei als 1Bit-Wert im Datenbereich von Byte 23 bis Byte 30 dargestellt (24*I + 16*Q + 24*M = 24 + 16 + 24Bits = 8 Bytes). 

Darstellungsformat:
```
55 11 11 40 00 ......  03  00  00   03 00   00  00  00  00 ...
55 11 11 40 00 xxxxxx [03  00  00] [03 00] [00  00  00] xx ...
               D1-D22 [D23 D24 D25 D26 D27 D28 D29 D30]
                      [I1-24     ] [Q1-16] [M1-24     ]

xx: irgendwelche Bytes
Dn: Datenbyte an Stelle n

D23: BIN MSB --+--+--+--*--+--+--+-- LSB
             b7 b6 b5 b4 b3 b2 b1 b0

    b7 = Signalzustand I8
    b6 = Signalzustand I7
    b5 = Signalzustand I6
    b4 = Signalzustand I5
    b3 = Signalzustand I4
    b2 = Signalzustand I3
    b1 = Signalzustand I2
    b0 = Signalzustand I1

D24-25: BIN MSB --+--+--+--*--+--+--+-- LSB
                b7 b6 b5 b4 b3 b2 b1 b0

    b7 = Signalzustand I16, I24, ...
    b6 = Signalzustand I15, I23, ...
    b5 = Signalzustand I14, I22, ...
    b4 = Signalzustand I13, I21, ...
    b3 = Signalzustand I12, I20, ...
    b2 = Signalzustand I11, I19, ...
    b1 = Signalzustand I10, I18, ...
    b0 = Signalzustand I09, I17, ...

D26-27: BIN MSB --+--+--+--*--+--+--+-- LSB
                b7 b6 b5 b4 b3 b2 b1 b0

    b7 = Signalzustand Q8, Q16
    b6 = Signalzustand Q7, Q15
    b5 = Signalzustand Q6, Q14
    b4 = Signalzustand Q5, Q13
    b3 = Signalzustand Q4, Q12
    b2 = Signalzustand Q3, Q11
    b1 = Signalzustand Q2, Q10
    b0 = Signalzustand Q1, Q09

D28-30: BIN MSB --+--+--+--*--+--+--+-- LSB
                b7 b6 b5 b4 b3 b2 b1 b0

    b7 = Signalzustand M8, M16, M24
    b6 = Signalzustand M7, M15, M23
    b5 = Signalzustand M6, M14, M22
    b4 = Signalzustand M5, M13, M21
    b3 = Signalzustand M4, M12, M20
    b2 = Signalzustand M3, M11, M19
    b1 = Signalzustand M2, M10, M18
    b0 = Signalzustand M1, M09, M17
```

Auswertung:
```
xx [03  00  00] [03 00] [00  00  00] xx ...
   [D23 D24 D25 D26 D27 D28 D29 D30]

Datenbyte 23:    03      = 0000 0011 // I1 = 1; I2 = 1; I3-8 = 0
Datenbyte 24-25: 00      = 0000 0000 // I9-I24 = 0
Datenbyte 26:    03      = 0000 0011 // Q1 = 1; Q2 = 1; Q3-8 = 0
Datenbyte 28-30: 00      = 0000 0000 // M1-M24 = 0
```

### Analoge Klemmen im Modus _RUN_
Der Wert für die Anlogen Eingänge _AI1-8_, Ausgänge _AQ1-2_ und Merker _AM1-6_ kann mittels des Online-Test Befehls `55 13 13 ..AA` abgefragt werden. Der Signalzustand wird dabei als 16Bit-Wert im Datenbereich von Byte 31 bis Byte 63 dargestellt (8*AI + 2*AQ + 6*AM = 8*16 + 2*16 + 6*16Bits = 32 Bytes). 

Der Wertebereich ist von -32768 bis +32767, wobei 0-10V auf interne Werte von 0 bis 1000 abgebildet werden.

Darstellungsformat:
```
55 11 11 40 00  xxxxxx
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 xx

55 11 11 40 00 [D1-D30]
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[AI1] [AI2] [AI3] [AI4] [AI5] [AI6] [AI7] [AI8]
00 00 00 00
[AQ1] [AQ2]
00 00 00 00 00 00 00 00 00 00 00 00 xx
[AM1] [AM2] [AM3] [AM4] [AM5] [AM6]


xx: irgendwelche Bytes
Dn: Datenbyte an Stelle n

AXn:
  X = I,Q oder M (AIn, AQn oder AMn)
  n = 1..8

  Beispiel:
    X=I und n=8: AI8
  
  AXa AXb
    \ /
    / \
  AXb,AXa = AX

  AX ist ein 16bit Interger Wert
  
    |       AXb (byte)      |       AXa (byte)      |
 MSB --*--+--+--+--+--+--+--|--+--+--+--+--+--+--+-- LSB
     bF|bE ..          .. b8|b7 ..          .. b1 b0

  bF: Vorzeichenbit
    bF=1:negativ; bE..b9:Zahlenwert
    bF=0:positiv; bE..b9:Zahlenwert
```

----------

# <a name="0EE8"></a>Kapitel 4 - Programmzeilenspeicher
Der Programmzeilenspeicher ist Teil des Schaltprogramms (vergl. _S7_ Programmbaustein) und wird zur Abarbeitung des Hauptprogramm (vergl. _S7_ Organisationsbaustein OB1) in den Arbeitsspeicher geladen. Der zugehörige Code ist Teil der Firmware und daher nicht adressierbar. 

## <a name="Blockbeschreibung"></a>Blöcke und Blocknummern
Ein Block ist eine Funktion, die eine Ausgangsinformationen Aufgrund einer Informationen an den Eingängen setzt. Die Firmware bestimmt die nutzbaren Funktionen, die für unterschiedliche Aufgaben eingesetzt werden können (vergl. _S7_ Systemfunktionen). 

### Darstellung am Verknüpfungseingang
Alle Blöcke sind im Programmzeilenspeicher `0EE8` abgelegt und werden mit einem 16bit Wert (Datentyp Word) im Wertebereich `8000..C08C` am Eingang eines Blocks, Merkers oder einer Ausgangsklemme dargestellt. 

Bei einem Block ist das Most Significant Bit (MSB = `1`) vom Word immer gesetzt. Das niederwertige Byte vom Word (_LoByte_) benennt die Blocknummer im Wertebereich `0A..8C`, entsprechend _B001_ bis _B130_.

Bestimmte Eingänge von Grund- und Sonderfunktionen können einzeln negieren, d.h. liegt an dem bestimmten Eingang eine `1` an, so verwendet das Schaltprogramm eine `0`. Liegt eine `0` an, so wird eine `1` verwendet. Diese Information ist im Bit 7 vom _HiByte_ gespeichert:

Eingang | HiByte | BIN
--------|--------|---------------
normal  | 80     | 1000 0000 = 80
negiert | C0     | 1100 0000 = C0

### Zuordnen einer Blocknummer
Die Erklärung erfolgt Anhand eines Beispiels. Im Beispiel kommen die Klemmen _Q1_ und _Q2_ zur Anwendung (ungleich `FFFF`).

Die Klemmen sind wie folgt verdrahtet:
- Der Eingang von _Q1_ ist mit dem Ausgang von Block _B001_ verbunden
- Eingang _Q2_ mit Ausgang _B005_

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
>Abb: Schaltprogramm _Zuordnung der Blocknummer_

Abfrage der Klemmen _Q1-Q16_
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
Q2     | B005  | 0E  | 14
Q3-16  | -     | FF  | -
>Tab: Zuordnung der Blocknummer zum Ausgang

Block | HEX | DEC | Offset (-9)
------|-----|-----|-------------
B001  | 0A  | 10  | 1
B005  | 0E  | 14  | 5
>Tab: Bestimmung der Blocknummer

### Darstellung im Modus _RUN_
Das Signalergebnis am Ausgang eines Blockes kann mittels des Online-Test Befehls `55 13 13 .. AA` abgefragt werden. Das Signalergebnis wird dabei als 1Bit-Wert im Datenbereich von Byte 6 bis Byte 22 dargestellt (130 Blöcke = 128+2 Bits = 16 Bytes + 2 Bits). 

Beispielschaltprogramm:
```
               .---.B001
    .----------| & |
    |       .--|   |-- Q1
    |       |  '---' 
I1--o   I2--o
    |       |  .---.B130
    |       '--|>=1|
    '----------|   |-- Q2
               '---' 
```
>Abb: Schaltprogramm _Signalzustand im Online-Test_

Befehl:
```
send> 55 13 13 00 AA 
recv< 06 
recv< 55 11 11 40 00
6D 0A 11 2A
00
80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 52
03 00 00 03 00 00 00 00
00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00
AA 
```

Darstellungsformat:
```
55 11 11 40 00 .....  80 00 00 00 00 00 00 00 00 00 00 00 00 00 00  00  52 03 ...
55 11 11 40 00 xxxxx [80 00 00 00 00 00 00 00 00 00 00 00 00 00 00  00  52] x ...
               D1-D5 [D6 D7 ...                                ... D16 D22]

x: irgendein Byte
Dn: Datenbyte an Stelle n

D6: BIN MSB --+--+--+--*--+--+--+-- LSB
            b7 b6 b5 b4 b3 b2 b1 b0

    b7 = Signalergebnis Block B008
    b6 = Signalergebnis Block B007
    b5 = Signalergebnis Block B006
    b4 = Signalergebnis Block B005
    b3 = Signalergebnis Block B004
    b2 = Signalergebnis Block B003
    b1 = Signalergebnis Block B002
    b0 = Signalergebnis Block B001

D7-21: BIN MSB --+--+--+--*--+--+--+-- LSB
               b7 b6 b5 b4 b3 b2 b1 b0

    b7 = Signalergebnis Block B016, B024, ...
    b6 = Signalergebnis Block B015, B023, ...
    b5 = Signalergebnis Block B014, B022, ...
    b4 = Signalergebnis Block B013, B021, ...
    b3 = Signalergebnis Block B012, B020, ...
    b2 = Signalergebnis Block B011, B019, ...
    b1 = Signalergebnis Block B010, B018, ...
    b0 = Signalergebnis Block B009, B017, ...

D22: BIN MSB ++++*++---+-- LSB
             xxxx xx b1 b0
    b7-b3: x = irgendein Bit
    b1 = Signalergebnis Block B130
    b0 = Signalergebnis Block B129
```

Auswertung:
```
xx [80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 52] xx
    D6 --------------------------------------------D22

Datenbyte 6:     80      = 1000 0000 // B001: Q = 1; B002-B008: Q = 0
Datenbyte 7-21:  00      = 0000 0000 // B009-B128: Q = 0
Datenbyte 22:    52 & 03 = xxxx xx10 // B129: Q = 0; B130: Q = 1
```

## <a name="0C14"></a>Verweis auf Blöcke
Zeiger auf die Blöcke im Programmzeilenspeicher `0EE8`. Jeweils ein 16bit-Zeiger (ungleich `FFFF`) zeigt auf ein Block. Ein Block ist eine Funktion, die Eingangsinformationen in Ausgangsinformationen umsetzt. Die Länge eine Blocks im Programmzeilenspeicher ist variabel.

Die Größe beträgt 260 Bytes (__0BA5__ hat maximal 130 Blöcke und der Zeiger eines Funktionsblocks belegt 2 Bytes: 260/2 = 130).

Speicherbereich: `0C14..0D18` (130*2 Bytes).

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
>Abb: Adressverweis auf Blöcke

Zeigerarithmetik: unter Verwendung des ausgelesen Wertes ist es möglich, einen Zeiger auf `0E20` um den gelesen Offset-Anteil zu erhöhen und damit den Block im Speicherbereich anzusprechen. 

Der erste Block liegt im Programmzeilenspeicher `0EE8` = `0E20` + `00C8`, d.h. Der Wert an Adresse `0C14` (Offset 1) ist entweder `00C8` oder `FFFF`, wenn kein Programm vorhanden ist.

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

Folgend das Beispielschaltprogramm _Ermittlung von Speicherbedarf_ aus dem Handbuch:
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
>Abb: Schaltprogramm _Ermittlung von Speicherbedarf_

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
Nb: BIN MSB --+--+--+--*++++ LSB
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

Folgend das der Ausschnitt von Block B001 aus dem Beispiel _Ermittlung von Speicherbedarf_.

Schaltprogramm:
```
     B1
    .---.
B2--|>=1|
  x-|   |
I2--|   |--Q1
    '---'
```
>Abb: Programm _Ermittlung von Speicherbedarf_, Block B001

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
>Tab: Liste _Grundfunktionen_

## <a name="SF"></a>Sonderfunktionen - SF
Sonderfunktionen sind ähnlich wir die Grundfunktionen im Speicher abgelegt. Neben den Verknüpfungseingängen beinhalten diese jedoch Zeitfunktionen, Remanenz und verschiedenste Parametriermöglichkeiten.

### Darstellungsformat im Ladespeicher
Die Formatlänge ist variabel und hat 8, 12, 20 oder 24 Bytes = 2 Bytes `<SF> <Pa>` + 4 bis 20 Bytes `<Daten>` + 2 Bytes `FF FF`.

SF: Block, siehe Liste Sonderfunktionen<br />
Pa: Parameter, siehe Blockparameter

HEX        | RAM (Bytes) | REM (Bytes) | Beschreibung
-----------|-------------|-------------|---------------------------------
[21](#SF21)| 8           | 3           | Einschaltverzögerung
[22](#SF22)| 12          | 3           | Ausschaltverzögerung
[23](#SF23)| 12          | 1           | Stromstoßrelais
[24](#SF24)| 20          | -           | Wochenschaltuhr
[25](#SF25)| 8           | 1           | Selbsthalterelais
[27](#SF27)| 12          | 3           | Speichernde Einschaltverzögerung
[2B](#SF2B)| 24          | 5           | Vor-/Rückwärtszähler
[2D](#SF2D)| 12          | 3           | Asynchroner Impulsgeber
[2F](#SF2F)| 12          | 3           | Ein-/Ausschaltverzögerung
[31](#SF31)| 12          | 3           | Treppenlichtschalter
[34](#SF34)| 8           | -           | Meldetext
[35](#SF35)| 16          | -           | Analoger Schwellwertschalter
[39](#SF39)| 20          | -           | Analogwertüberwachung
>Tab: Liste _Sonderfunktionen_

## <a name="Grundwissen-SF"></a>Grundwissen Sonderfunktionen

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
------------|-----------|-----------|-----
(s:1/100)   | s         | 10 ms     | 1
(m:s)       | m         | Sekunden  | 2
(h:m)       | h         | Minuten   | 3
>Tab: Darstellung der Zeitbasis

Darstellungsformat:
```
.. xx T1 T2 xx ..
.. xx [T  ] xx ..

xx: irgendein Byte
T: Zeit, 16bit (Word)
  T1 T2
   \ /
   / \
  T2 T1 = T

    |       T2 (byte)       |       T1 (byte)       |
 MSB --+--*--+--+--+--+--+--|--+--+--+--+--+--+--+-- LSB
     bF bE|bD ..       .. b8|b7 ..          .. b1 b0

  bF,bE = 0,0 Zeitbasis (h:m), Wertebereich (0-23:0-59)
  bF,bE = 1,1 Zeitbasis (h:m), Wertebereich (0-99:0-59)
  bF,bE = 1,0 Zeitbasis (m:s), Wertebereich (0-99:0-59)
  bF,bE = 0,1 Zeitbasis (s:1/100s), Wertebereich (0-99:0-99)

  byte b = T >> 14;  // bF..bE (2bit) -> Zeitbasis (VB)
  word v = T & 7FFF; // bD..b0 (14bit) -> Zeitwert (VW)
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
_LOGO!_ __0BA5__ verfügt nur über eine Art von Zähler, welcher an einem Zähleingang die steigenden Flanken zählt. Der Zähler zählt sowohl vorwärts als auch rückwärts. Der Zählerwert ist eine 32Bit Ganzzahl vom Datentyp _VD_ und wird ohne Vorzeichen gespeichert. Der gültige Wertebereich des Zählers liegt zwischen 0...999999.

Darstellungsformat:
```
.. xx 00 06 6C BC xx ..
.. xx C1 C2 C3 C4 xx ..
.. xx [C        ] xx ..

xx:    irgendein Byte
C1-C4: Zählerwert, 32bit (DWord)

  C1 C2 C3 C4
      \ /
      / \
  C4 C3 C2 C1
  00 06 6C BC = 421052
```
Maximaler Zählerwert F423F:
```
  C1 C2 C3 C4
      \ /
      / \
  C4 C3 C2 C1
  00 0F 42 3F = 999999
```

## <a name="SF21"></a>Einschaltverzögerung
Mit der Funktion _Einschaltverzögerung_ wird das Setzen des Ausgangs _Q_ um die programmierte Zeitdauer _T_ verzögert. Die Zeit _Ta_ startet (_Ta_ ist die in _LOGO!_ aktuelle Zeit vom Datentyp _TW_), wenn das Eingangssignal _Trg_ von `0` auf `1` wechselt (positive Signalflanke). Wenn die Zeitdauer abgelaufen ist (_Ta_ > _T_), liefert der Ausgang _Q_ den Signalzustand `1`. Der Ausgang _Q_ bleibt so lange gesetzt, wie der Triggereingang die `1` führt. Wenn der Signalzustand am Triggereingang von `1` auf `0` wechselt, wird der Ausgang _Q_ zurückgesetzt. Die Zeitfunktion wird wieder gestartet, wenn eine neue positive Signalflanke am Starteingang erfasst wird. 

![alt text][Einschaltverzoegerung]
>Abb: Dialog _Einschaltverzögerung_

Die Flags für Remananz und Parameterschutz sowie die Beschaltung von Eingang _Trg_ und der Parameter _T_ werden im Mode _STOP_ abgefragt. Der Zeitoperand _Ta_ und der Signalzustand am Ausgang _Q_ sind im Mode _RUN_ abfragbar. 

RAM/Rem/Online: 8/3/4

### Darstellungsformat im Ladespeicher
```
21 40 01 00 7A 80 00 00 FF FF FF FF
21 40 [01 00] [7A 80] 00 00 FF FF FF FF
SF Pa [Trg  ] [Par  ] 00 00 FF FF FF FF
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

Trg: Eingang Trg (Co oder GF/SF)
Par: Parameter T (T ist die Zeit, nach der der Ausgang eingeschaltet wird)
```

Folgend das Beispiel _Ermittlung von Speicherbedarf_ aus dem Handbuch.

Schaltprogramm:
```
      B4
     .---.
     |.-.|
 I1--|--'|
Par--|   |--B2
     '---'
```
>Abb: Programm _Ermittlung von Speicherbedarf_, Block B004

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

### Format im Online-Test

```
send> 55 13 13 01 0D AA 
recv< 06 
recv< 55 11 11 44 00
F4 5F
11 2A
04
04 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00
01 00 0B 80
AA 

55 11 11 44 00 F4 5F 11 2A 04
55 [11 11] [44 00] [F4 5F] 11 2A 04
Co [Fc   ] [Bc   ] [Chk  ] C1 C2 C3
-----------------------------------
01 00 0B 80 AA
01 00 [0B 80] AA
Pa    [Ta   ] Ed
```

```
Co: Kontrollbefehl = 55
Fc: PG-Funktion = 1111
Bc: 16bit-Wert; Anzahl Datenbytes (inkl. Extrabytes)
  B1 B2
   \ /
   / \
  B1 B2
  00 4A = 74 (DEC)

Chk: Schaltprogramm Checksum
C1: Anzahl Bytes für Blöcke
C2: Anzahl Bytes für Klemmen
C3: Anzahl Extrabytes
Pa: Funktionsbeschreibung Ta
    Pa = 0; Ta stop; Ta = 0 (Standard)
    Pa = 1: Ta läuft; Ta < T
    Pa = 2: Ta stop; Ta = T

Ta: Aktuelle Zeit, siehe Zeitverhalten

Ed: AA = Ende Trennzeichen
```

Schaltprogramm:
```
      B4
     .---.
     |.-.|
 I1--|--'|
Par--|   |--B2
     '---'
```
>Abb: Programm _Ermittlung von Speicherbedarf_, Block B004

Abfrage von Block B004:
```
send> 55 13 13 01 0D AA 
recv< 06 
recv< 55 11 11 44 00
F4 5F
11
2A
04
04 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00
01 00 0B 80
AA 
```

Auswertung:
```
55 11 11    // Kontrollbefehl; Antwort Online-Test
44 00       // 68 Bytes folgen (exkl. AA)
F4 5F       // Schaltprogramm Prüfsumme
11          // 17 Bytes für Blöcke im Datenfeld
2A          // 42 Bytes für Klemmen im Datenfeld
04          // 4 Extra Bytes im Datenfeld
04 00....00 // B,I,M,Q,C,S,AI,AM,AQ (17+42 Bytes)
01          // Ta läuft; Ta < T
00          // VB = 0
0B 80       // Ta = 11s; Zeitbasis (m:s)
AA          // Befehlsende Trennzeichen
```

## <a name="SF22"></a>Ausschaltverzögerung
Mit der Funktion _Ausschaltverzögerung_ wird das Zurücksetzen des Ausgangs _Q_ um die parametrierte Zeitdauer _T_ verzögert. Der Ausgang _Q_ wird mit positiver Signalflanke gesetzt (Eingang _Trg_ wechselt von `0` auf `1`). Wenn der Signalzustand am Eingang _Trg_ wieder auf `0` wechselt (negative Signalflanke), läuft die parametrierte Zeitdauer _T_ ab. Der Ausgang _Q_ bleibt gesetzt, solange die Zeitdauer _Ta_ läuft (_Ta_ < _T_). Nach dem Ablauf der Zeitdauer _T_ (_T_ > _Ta_) wird der Ausgang _Q_ zurückgesetzt. Falls der Signalzustand am Eingang _Trg_ auf `1` wechselt, bevor die Zeitdauer _T_ abgelaufen ist, wird die Zeit zurückgesetzt. Der Signalzustand am Ausgang _Q_ bleibt weiterhin auf `1` gesetzt. 

![alt text][Auschaltverzoergerung]
>Abb: Dialog _Auschaltverzörgerung_

Die Flags für Remanenz und Parameterschutz sowie die Beschaltung von Eingang _Trg_ und der Parameter _T_ werden im Mode _STOP_ abgefragt. Der Zeitoperand _Ta_ und der Signalzustand am Ausgang _Q_ sind im Mode _RUN_ abfragbar. 

RAM/Rem/Online: 12/3/?

### Darstellungsformat im Ladespeicher
```
22 80 01 00 02 00 1F CD 00 00 00 00
22 80 [01 00] [02 00] [1F CD] 00 00 00 00
SF Pa [Trg  ] [R    ] [Par  ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

Trg: Eingang Trg (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par: Parameter T (Der Ausgang schaltet aus, wenn die Verzögerungszeit T abläuft)
```

Beispiel:
```
22 80 01 00 02 00 1F CD 00 00 00 00 // Ausschalterzögerung 55:59 (h: m)
```

## <a name="SF2F"></a>Ein-/Ausschaltverzögerung
Mit der Funktion _Ein-/Ausschaltverzögerung_  wird das Setzen sowie das Zurücksetzen des Ausgangs Q um die programmierte Zeitdauer _TH_ bzw. _TL_ verzögert. Die Einschaltverzögerung wird gestartet, wenn das Eingangssignal an _Trg_ von `0` auf `1` wechselt (positive Signalflanke). Mit dem Start läuft die programmierte Zeitdauer TH ab. Wenn die Zeitdauer (Ta > TH) abgelaufen ist, liefert der Ausgang Q den Signalzustand `1`.

Wenn der Signalzustand am Eingang _Trg_ wieder auf `0` wechselt (negative Signalflanke), läuft die parametrierte Zeitdauer _TL_ ab. Der Ausgang _Q_ bleibt gesetzt, solange die Zeitdauer _Ta_ läuft. Nach dem Ablauf der Zeitdauer _TL_ (Ta > TL) wird der Ausgang _Q_ zurückgesetzt. 

![alt text][Ein-Ausschaltverzoegerung]
>Abb: Dialog _Ein-/Ausschaltverzögerung_

Die Flags für Remanenz und Parameterschutz sowie die Beschaltung von Eingang _Trg_ und die Zeit-Parameter _TH_ und _TL_ werden im Mode _STOP_ abgefragt. Der Zeitoperand _Ta_ und der Signalzustand am Ausgang _Q_ sind im Mode _RUN_ abfragbar. 

RAM/Rem/Online: 12/3/6

### Darstellungsformat im Ladespeicher

```
2F 40  00 00  03 80    E9 43 00 00 FF FF
2F 40 [00 00] [03 80] [E9 43] 00 00 FF FF
SF Pa [Trg  ] [Par          ] 00 00 FF FF
SF Pa [Trg  ] [TH   ] [TL   ] 00 00 FF FF
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

Trg: Eingang Trg (Co oder GF/SF)
Par: siehe Zeitverhalten
  TH: Einschaltzeit, nach der der Ausgang eingeschaltet wird
  TH: Ausschaltzeit, nach der der Ausgang ausgeschaltet wird
```

### Format im Online-Test

```
send> 55 13 13 01 0A AA 
recv< 06 
recv< 55 11 11 46 00
22 8D
11 2A
06
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
50 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00
04 00 00 00 01 80
AA

55 11 11 46 00 22 8D 11 2A 06
55 [11 11] [4A 00] [22 8D] 11 2A 06
Co [Fc   ] [Bc   ] [Chk  ] C1 C2 C3
-----------------------------------
04 00 00 00 01 80 AA
04 00 00 00 [01 80] AA
Pa          [Ta   ] Ed
```

```
Co: Kontrollbefehl = 55
Fc: PG-Funktion = 1111
Bc: 16bit-Wert; Anzahl Datenbytes (inkl. Extrabytes)
  B1 B2
   \ /
   / \
  B1 B2
  00 4A = 74 (DEC)

Chk: Schaltprogramm Checksum
C1: Anzahl Bytes für Blöcke
C2: Anzahl Bytes für Klemmen
C3: Anzahl Extrabytes
Pa: Funktionsbeschreibung Ta
    Pa = 0; Ta stop; Ta = 0 (Standard)
    Pa = 2: Ta stop; Ta = TH
    Pa = 4: Ta läuft; Ta < TH
    Pa = 8: Ta läuft; Ta < TL

Ta: Aktuelle Zeit, siehe Zeitverhalten

Ed: AA = Ende Trennzeichen
```

Auswertung:
```
55 11 11    // Kontrollbefehl; Antwort Online-Test
46 00       // 70 Bytes folgen (exkl. AA)
22 8D       // Schaltprogramm Prüfsumme
11          // 17 Bytes für Blöcke im Datenfeld
2A          // 42 Bytes für Klemmen im Datenfeld
06          // 6 Extra Bytes im Datenfeld
00 00....00 // B,I,M,Q,C,S,AI,AM,AQ (17+42 Bytes)
04          // Ta läuft; Ta < TH
00 00 00    // VB = 0; VW = 0;
01 80       // Ta = 1s; Zeitbasis (m:s)
AA          // Befehlsende Trennzeichen
```

## <a name="SF23"></a>Stromstoßrelais
Bei der Funktion _Stromstoßrelais_ wechselt der Ausgang _Q_ bei jedem elektrischen Impuls am Eingang _Trg_ sein Signalzustand. Ist der Ausgang _Q_ zurückgesetzt (`0`) so wird er gesetzt (`1`) ist der Ausgang _Q_ gesetzt (`1`) wird dieser zurückgesetzt (`0`).

Der Ausgang _Q_ kann mittels der Eingänge _S_ und _R_ vorbelegt werden. Wenn der Signalzustand am Eingang _S_ = `1` und am Eingang _R_ = `0` ist, wird der Ausgang _Q_ auf `1` gesetzt. Wenn der Signalzustand am Eingang _S_ = `0` und am Eingang _R_ = `1` ist, wird der Ausgang _Q_ auf `0` zurückgesetzt. Der Eingang _R_ dominiert den Eingang _S_.

Die Flags für Remanenz und Parameterschutz sowie die Beschaltung von Eingang _S_ und _R_ werden im Mode _STOP_ abgefragt. Der Signalzustand am Ausgang _Q_ ist im Mode _RUN_ abfragbar. 

RAM/Rem/Online: 12/1/?

### Darstellungsformat im Ladespeicher
```
23 00 02 00 FF FF FF FF 00 00 00 00
23 00 [02 00] [FF FF] [FF FF] 00 00 00 00
SF Pa [Trg  ] [S    ] [R    ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

Trg: Eingang Trg (Co oder GF/SF)
S: Eingabe S (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par:
  RS (Vorrang Eingang R) oder
  SR (Vorrang Eingang S)
```

## <a name="SF24"></a>Wochenschaltuhr
Der Ausgang _Q_ wird über drei parametrierbares Ein- und Ausschaltzeiten (Einstellnocken _No1_, _No2_, _No3_) gesteuert. Der Wertebereich für die Schaltzeitpunkte (Ein- oder Ausschaltzeit) liegt zwischen `00:00` und `23:59` Uhr. In Summe können 6 Schaltzeitpunkte vom Datentyp _TW_ angegeben sein. Die Auswahl der Wochentage erfolgt durch Aktivierung der zugeordneten Tage, wobei jeder Tag einem Speicher-Bit innerhalb eines Bytes zugeordnet ist. Wenn das zugehörige Bit auf `1` gesetzt ist, ist der Tag festgelegt. 

![alt text][Wochenschaltuhr]
>Abb: Dialog _Wochenschaltuhr_

__Hinweis:__ Da die _LOGO!_ Kleinsteuerung Typ 24/24o keine Uhr besitzt, ist die Wochenschaltuhr bei dieser Variante nicht nutzbar. 

RAM/Rem/Online: 20/-/5

### Darstellungsformat im Ladespeicher
```
24 40 F2 00 A0 00 FF FF FF FF FF FF FF FF 2A 00 00 00 00 00
24 40 [F2 00] [A0 00] [FF FF] [FF FF] [FF FF] [FF FF]  2A 00 00  00 00 00
SF Pa [On1  ] [Off1 ] [On2  ] [Off2 ] [On3  ] [Off3 ]  D1 D2 D3
SF Pa [No1          ] [No2          ] [No3          ] [Wo-Tage ]
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein; * REM (Standard)
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

No1: Nockenparameter 1
No2: Nockenparameter 2
No3: Nockenparameter 3

  OnX:  Einschaltzeitpunkt hh:mm (0-23:0-59); min. 0000, max. 059F
        FF FF = deaktiviert
        OnL OnH
          \ /
          / \
        OnH,OnL = T
        word t = T & 0x07FF; // Zeitwert in Minuten
        h = t / 60;
        m = t % 60;
  
        Beispiel:
        F2 = 1111 0010 = 242 (Dec) = 60 × 4 + 2 = 242   // On = 04:02h
  
  OffX: Ausschaltzeitpunkt hh:mm (0-23:0-59)
        FF FF = deaktiviert
        OffL OffH
           \ /
           / \
        OffH,OffL = T
        word t = T & 0x07FF; // Zeitwert in Minuten
        h = t / 60;
        m = t % 60;
  
        Beispiel:
        A0 = 1010 0000 = 160 (Dec) = 60 * 2 + 40 = 160  // Off = 02:40h

Dx: Wochentage
    Dx = 00 (Standard)
    Dx = täglich (D=MTWTFSS) = 7F

   MSB --+--+--+--*--+--+--+-- LSB
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

Folgend das Beispiel _Ermittlung von Speicherbedarf_ aus dem Handbuch.

Schaltprogramm:
```
      B3
     .---.
No1--|.-.|
No2--|'-'|--B2
No3--|   |
     '---'
```
>Abb: Programm _Ermittlung von Speicherbedarf_, Block B003

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
Mit der Funktion _Selbsthalterelais_ wird der Ausgang _Q_ abhängig vom Signalzustand an den Eingängen _S_ und _R_ gesetzt oder zurückrücksetzt. Wenn der Signalzustand am Eingang _S_  = `1` und am Eingang _R_ = `0` ist, wird der Ausgang _Q_ auf `1` gesetzt. Wenn der Signalzustand am Eingang _S_ = `0` und am Eingang _R_ = `1` ist, wird der Ausgang _Q_ auf `0` zurückgesetzt. Der Eingang _R_ dominiert den Eingang _S_. Bei einem Signalzustand `1` an beiden Eingängen _S_ und _R_ wird der Signalzustand des Ausganges _Q_ auf `0` gesetzt. 

RAM/Rem/Online: 8/1/?

### Darstellungsformat im Ladespeicher
```
25 00 0A 80 FF FF 00 00
25 00 [0A 80] [FF FF] 00 00
SF Pa [S    ] [R    ] 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

S: Eingang S (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
```

## <a name="SF27"></a>Speichernde Einschaltverzögerung

![alt text][Speichernde_Einschaltverzoegerung]
>Abb: Dialog _Speichernde Einschaltverzögerung_

RAM/Rem/Online: 12/3/?

### Darstellungsformat im Ladespeicher
```
27 80 02 00 FF FF 36 81 00 00 00 00
27 80 [02 00] [FF FF] [36 81] 00 00 00 00
SF Pa [Trg  ] [R    ] [Par  ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

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
Der Zähler erfasst binäre Impulse am Eingang _Cnt_ und zählt den internen Zähler _Cv_ hoch oder runter. Über den Eingang _Dir_ (`0`:Cv=Cv+1, `1`:Cv=Cv-1) wird zwischen Vorwärts- und Rückwärtszählen umgeschaltet. Der interne Zähler _Cv_ kann durch den Rücksetzeingang _R_ auf den Wert `0` zurückgesetzt werden. Über den Parameter _On_ oder _Off_ wird die Schaltschwelle für den Ausgang _Q_ definiert. Sofern der Zähler _Cv_ die obere Schaltschwelle (_Cv_ > _On_) erreicht bzw. überschreitet wird der Ausgang _Q_ auf `1` und bei erreichen bzw. unterschreiten der unteren Schaltschwelle (_Cv_ < _Off_) wird _Q_ auf `0` gesetzt. Der Wertebereich für _On_, _Off_ und _Cv_ ist von 0 bis 999999.

![alt text][Vor-Rueckwaertszaehler]
>Abb: Dialog _Vor-/Rückwärtszähler_

Mit dem Rücksetzeingang _R_ kann der internen Zählwert _Cv_ auf 0 zurückgestellt werden. Solange _R_ gleich `1` ist, ist auch der Ausgang Q auf `0` zurückgesetzt. 

Die Flags für Remanenz und Parameterschutz sowie die Beschaltung der Eingänge _R_, _Cnt_ und _Dir_ und der Parameter  _On_ und _Off_ werden im Mode _STOP_ abgefragt. Der Signalzustand am Ausgang _Q_ und der interne Zählerwert _Cv_ ist im Mode _RUN_ abfragbar. 

RAM/Rem/Online: 24/5/10

### Darstellungsformat im Ladespeicher
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
    MSB --+--+--+--*++++ LSB
        b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

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

### Format im Online-Test

```
send> 55 13 13 01 0A AA 
recv< 06 
recv< 55 11 11 4A 00
3E C9
11 2A
0A
01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00
03 00 00 00 02 00 00 00 00 00
AA 

55 11 11 4A 00 3E C9 11 2A 0A
55 [11 11] [4A 00] [3E C9] 11 2A 0A
Co [Fc   ] [Bc   ] [Chk  ] C1 C2 C3
-----------------------------------
03 00 00 00 02 00 00 00 00 00 AA
[03 00 00 00] [02] 00 00 00 00 00 AA
[Cv         ] [Pa] 00 00 00 00 00 Ed
```

```
Co: Kontrollbefehl = 55
Fc: PG-Funktion = 1111
Bc: 16bit-Wert; Anzahl Datenbytes (inkl. Extrabytes)
  B1 B2
   \ /
   / \
  B1 B2
  00 4A = 74 (DEC)

Chk: Schaltprogramm Checksum
C1: Anzahl Bytes für Blöcke
C2: Anzahl Bytes für Klemmen
C3: Anzahl Extrabytes
Cv: 32bit-Wert; Aktueller Zählerstand
  C1 C2 C3 C4
      \ /
      / \
  C4 C3 C2 C1
  00 00 00 03 = 3 (DEC)

Pa: Funktionsblockparameter
    MSB ++++*--+--+--+-- LSB
        0000 b3 b2 b1 b0
       
    b1: Ausgang Q; 1 = high, 0 = low
    b0: Eingang Cnt; 1 = high, 0 = low

Ed: AA = Ende Trennzeichen
```

Auswertung:
```
55 11 11    // Kontrollbefehl; Antwort Online-Test
4A 00       // 74 Bytes folgen (excl. AA)
3E C9       // Schaltprogramm Prüfsumme
11          // 17 Bytes für Blöcke im Datenfeld
2A          // 42 Bytes für Klemmen im Datenfeld
0A          // 10 Extra Bytes im Datenfeld
01 00....00 // B,I,M,Q,C,S,AI,AM,AQ (17+42 Bytes)
03 00 00 00 // akt. Zählerstand Cv = 3
02          // Ausgang Q = 1; Eingang Cnt = 0
00 00 00 00 // VD = 0; ??
00          // VB = 0; ??
AA          // Befehlsende Trennzeichen
```

## <a name="SF2D"></a>Asynchroner Impulsgeber
Mit der Funktion _Asynchroner Impulsgeber_ können wird der Ausgang _Q_ für eine vorprogrammierte Zeitdauer _TH_ gesetzt und für eine vorprogrammierte Zeitdauer _TL_ zurückgesetzt. Die Funktion startet, wenn das Signal am Eingang _En_ von `0` auf `1` (positive Flanke) wechselt. Mit dem Start läuft die programmierte Zeitdauer _TH_ bzw. _TL_ ab. Der Ausgang _Q_ wird für die Zeitdauer _TH_ gesetzt und für _TL_ zurückgesetzt. Über den Eingang _Inv_ lässt sich der Ausgang _Q_ des Impulsgeber invertieren. Eingang _En_ und _Inv_, Ausgang _Q_ sowie die Parameter _TH_ und _TL_ können im Betriebszustand _STOP_ ausgelesen werden.

![alt text][Impulsgeber]
>Abb: Dialog _Asynchroner Impulsgeber_

Die aktuelle Zeit _Ta_ benennt die Zeitdauer des letzten Flankenwechsels (Wechsel von `1` auf `0` bzw. von `0` auf `1`) von Ausgang _Q_. Ser Signalzustand am Ausgang _Q_, sowie die Variable _Ta_ könne im Betriebszustand _RUN_ ausgelsen werden. 

RAM/Rem/Online: 12/3/?

### Darstellungsformat im Ladespeicher
```
2D 40 02 00 FF FF 02 80 02 80 00 00
2D 40 [02 00] [FF FF] [02 80] [02 80] 00 00
SF Pa [En   ] [Inv  ] [TH   ] [TL   ] 00 00
SF Pa [En   ] [Inv  ] [Par          ] 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

En: Eingang En (Co oder GF/SF)
Inv: Eingang Inv (Co oder GF/SF)
Par:
  TH: Parameter TH (Impulsdauer), siehe Zeitverhalten
  TL: Parameter TL (Impulspausendauer), siehe Zeitverhalten
```

## <a name="SF39"></a>Analogwertüberwachung

RAM/Rem/Online: 20/-/?

### Darstellungsformat im Ladespeicher
```
39 40 FD 00 92 00 C8 00 66 00 00 00 00 00 00 00 00 00 00 00
39 40 [FD 00] [92 00] [C8 00 66 00 00 00 00 00 00 00 00 00 00 00
SF Pa [En   ] [Ax   ] [Par ... 
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
   MSB --+--+--+--*++++ LSB
       b7 b6 b5 b4 0000

    b7: Remanenz; 1 = aktiv, 0 = nein; * REM (Standard)
    b6: Parameterschutz; 0 = aktiv, 1 = inaktiv (Standard)

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

## <a name="0522"></a>Speicherbereiche 0522

AI7-> AM6-> AQ2 / AI2-> AM6-> AQ2

0522
```
00 74 / 00 00
```

```
74 = 0111 0100
```

## <a name="055E"></a>Schaltprogramm Checksum

Im Betriebszustand _RUN_ können mittels der _Online-Test_-Funktion aktuelle Werte ausgelesen werden. Bei der Übertragung wird eine Check-Summe mitgesendet, die mit den Werten von Adresse 055E-055F übereinstimmen muss. Sofern die Werte nicht identisch sind, stimmt das Schaltprogramm in der _LOGO!_ SPS nicht mit dem in _LOGO!Soft Comfort_ geladenen Schaltprogramm überein. Üblicherweise fordert _LOGO!Soft Comfort_ den Anwender auf, das Schaltprogramm zu aktualisieren. 

### Darstellungsformat im Ladespeicher

```
send> 02 05 5E
recv< 06 03 05 5E
6D
send> 02 05 5F
recv< 06 03 05 5F
0A
```

### Format im Online-Test

```
send> 55 13 13 01 0A AA 
recv< 06 
recv< 55 11 11 40 00
6D 0A
11 2A
00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0C 00 00 00 00 00 00 00 00 00 00 0A 02 F1 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00
AA

55 11 11 40 00 6D 0A 11 2A 00
55 [11 11] [40 00] [6D 0A] 11 2A 00
Co [Fc   ] [Bc   ] [Chk  ] C1 C2 C3
```

```
Co: Kontrollbefehl = 55
Fc: PG-Funktion = 1111
Bc: 16bit-Wert; Anzahl Datenbytes (inkl. Extrabytes)
Chk: Schaltprogramm Checksum; identisch mit den Werten an Speicheradresse 055E-055F
C1: Anzahl Bytes für Blöcke
C2: Anzahl Bytes für Klemmen
C3: Anzahl Extrabytes
```

## Erfassbare Daten
Die Tabelle zeigt die erfassbaren Variablen und Parameter inkl. zugehörigen Datentyp, die über den Befehl `55` oder `05` abgefragt werden können. Die Angabe _VB_, _VW_ oder _VD_ (Byte = 1, Wort = 2 oder Doppelwort = 4) gibt gleichzeitig die Anzahl der Bytes vor, die der Datentyp benötigt. 

Blockbeschreibung                 | Aktualwerte oder Parameter              | Datentyp
----------------------------------|-----------------------------------------|-----------
Einschaltverzögerung              | T, Ta                                   | 2*VW
Ausschaltverzögerung              | T, Ta                                   | 2*VW
Ein-/Ausschaltverzögerung         | Ta, TH, TL                              | 3*VW
Speichernde Einschaltverzögerung  | T, Ta                                   | 2*VW
Wischrelais (Impulsausgabe)       | T, Ta                                   | 2*VW
Flankengetriggertes Wischrelais   | Ta, TH, T                               | 3*VW
Asynchroner Impulsgeber           | Ta, TH, TL                              | 3*VW
Zufallsgenerator                  | TH, TL                                  | 2*VW
Treppenlichtschalter              | Ta, T, T!, T!L                          | 4*VW
Komfortschalter                   | Ta, T, TL, T!, T!L                      | 5*VW
Wochenschaltuhr                   | 3* On/Off/Tag                           | 3*VW/VW/VB
Vor-/Rückwärtszähler              | Cv, On, Off                             | 3*VD
Betriebsstundenzähler             | MI, MN, OT                              | 2*VW, VD
Analogkomparator                  | On, Off, A, B, Ax, Ay, dA               | 7*VW
Analoger Multiplexer              | V1, V2, V3, V4, AQ                      | 5*VW
Rampensteuerung                   | L1, L2, MaxL, StSp, Rate, A, B, AQ      | 8*VW
PI-Regler                         | SP, Mq, KC, TI, Min, Max, A, B, PV, AQ  | 10*VW
>Tab: Erfassbare Daten

### Mögliche Anwendung
Über den Blocknamen könnten bis zu 64 Parameter einem Variablenspeicher ähnlich __0BA7__ zugeordnet werden. Die obige Tabelle zeigt neben den erfassbaren Variablen und Block-Parametern auch den zugehörigen Datentyp für eine mögliche Anwendung mit einem Variablenspeicher (VM Adressbereich 0 bis 850 bei Adresstyp VB). 

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
>Abb: VM-Adresstypen

# Anhang

## <a name="Ressourcen"></a>__0BA5__ Ressourcen
Dieses Handbuch beschreibt ausschließlich das _LOGO!_ Gerät in der Version __0BA5__. Die folgend genannten Ressourcen dienen der Vergleichbarkeit:
- Funktionsblöcke: 130
- Rem: 60
- Digitaleingänge: 24
- Digitalausgänge: 16
- Merker: 24
- Analogeingänge: 8
- Meldetexte: 10
- Analogausgänge: 2
- Programmzeilenspeicher: 2000
- Blocknamen: 64
- Analoge Merker: 6
- Cursortasten: 4
- Schieberegister: 1
- Schieberegisterbits: 8
- Offene Klemme: 16
- max. Tiefe des Programmpfads: 58

Zusätzlich noch die Bestellnummern der __0BA5__ Hardware:

Variante | Bezeichnung          | Bestellnummer
---------|----------------------|-------------------
Basic    | _LOGO!_ 12/24RC \*   | 6ED1052-1MD00-0BA5
Basic    | _LOGO!_ 24 \*        | 6ED1052-1CC00-0BA5
Basic    | _LOGO!_ 24RC (AC)    | 6ED1052-1HB00-0BA5
Basic    | _LOGO!_ 230RC (AC)   | 6ED1052-1FB00-0BA5
Pure     | _LOGO!_ 12/24 RCo \* | 6ED1052-2MD00-0BA5
Pure     | _LOGO!_ 24o \*       | 6ED1052-2CC00-0BA5
Pure     | _LOGO!_ 24 RCo (AC)  | 6ED1052-2HB00-0BA5
Pure     | _LOGO!_ 230 RCo      | 6ED1052-2FB00-0BA5
>Tab: __0BA5__ Bestellnummern

\*: zusätzlich mit Analogeingängen

## <a name="Abk"></a>Verwendete Abkürzungen
- __0BA5__: _LOGO!_ Kleinsteuerung der 6. Generation (wird in diesem Handbuch beschrieben)
- __0BA7__: _LOGO!_ Kleinsteuerung der 8. Generation
- __A__: Verstärkung (Gain)
- __ALU__ (_Arithmetic Logic Unit_): elektronisches Rechenwerk
- __AND__: Und-Verknüpfung
- __Ax__: Analogkomparator Eingang _Ax_
- __Ay__: Analogkomparator Eingang _Ay_
- __dA__: Differenzwert von _Ax_ - _Ay_
- __AQ__: Analoger Ausgang
- __B__: Nullpunktverschiebung (Offset)
- __B001__: Block Nummer, B1
- __Bc__ (_Byte count_): Anzahl Bytes
- __BIN__: Binärwert
- __Cnt__ (_Count_): Zählimpulse
- __Co__ (_Connector_): Klemme
- __CRC__ (Cyclic Redundancy Check): Prüfsummenberechnung
- __Cv__ (_Counter value_): Zählerwert
- __DB__: Datenbaustein einer _S7_
- __DEC__ (_Decimal_): Dezimalwert
- __Dir__ (_Direction_): Festlegung der Richtung
- __Ed__: Ende Trennzeichen `AA`
- __En__ (_Enable_): aktiviert die Funktion eines Blocks.
- __FB__: Funktionsbaustein einer S7
- __FC__: Funktion einer S7
- __Fre__ (_Frequency_): Auszuwertende Frequenzsignale
- __GF__: Grundfunktionen
- __HEX__: Hexadezimaler Wert
- __Hi__ (_High_): Signalwert `1`
- __I__ (_Input_): Digitaler Eingang
- __Inv__ (_Invert_): Ausgangssignal des Blocks wird invertiert
- __KC__: Regler Verstärkung
- __Lo__ (_Low_): Signalwert `0`
- __LSB__ (_Least Significant Bit_): Bit mit dem niedrigsten Stellenwert
- __M__: Merker
- __MI__: Parametriertes Wartungsintervall
- __MN__: Verbleibende Restzeit vom Wartungsintervall
- __Mq__: Reglerwert von _AQ_ bei manuellem Betrieb
- __MSB__ (_Most Significant Bit_): Bit mit dem höchsten Stellenwert
- __No__ (_Nocken_): Parameter der Zeitschaltuhr
- __OB__: Organisationsbaustein einer _S7_
- __Off__: Aus
- __On__: Ein
- __OR__: Oder-Verknüpfung
- __OT__: Aufgelaufene Gesamtbetriebszeit
- __p__ (_position_): Anzahl der Nachkommastellen
- __PA__: Prozessabbild der Ausgänge 
- __Par__: Parameter
- __PE__: Prozessabbild der Eingänge
- __PV__: Regelgröße
- __Q__: Digitaler Ausgang
- __R__ (_Reset_): Rücksetzeingang
- __Ral__ (_Reset all_): internen Werte werden zurückgesetzt
- __RAM__ (_Random-Access Memory_): Speicher mit wahlfreiem, direktem Zugriff
- __Rem__ (_Remanenz_): Speicherbereich um Zustände oder Werte zu sichern
- __S__ (_Set_): Eingang wird gesetzt
- __SF__: Sonderfunktionen
- __SFB__: Systemfunktionsbaustein einer _S7_
- __SFC__: Systemfunktion einer _S7_
- __SP__: Regler Sollwertvorgabe
- __T__ (_Time_): Zeit-Parameter
- __Ta__ (_Time actual_): Aktueller Wert einer Zeit
- __TH__ (_Time High_): oberer Zeitwert
- __TI__ (_Time Integral_): Regler Zeitintegral
- __TL__ (_Time Low_): unterer Zeitwert
- __Trg__ (_Trigger_): Ablauf einer Funktion wird gestartet
- __X__: Offene Klemme
- __XOR__: Exklusiv-Oder-Verknüpfung

[Auschaltverzoergerung]: https://github.com/brickpool/logo/blob/master/extras/images/Auschaltverzoergerung.jpg "Auschaltverzörgerung"

[Betriebsstundenzaehler]: https://github.com/brickpool/logo/blob/master/extras/images/Betriebsstundenzaehler.jpg "Betriebsstundenzaehler"

[Ein-Ausschaltverzoegerung]: https://github.com/brickpool/logo/blob/master/extras/images/Ein-Ausschaltverzoegerung.jpg "Ein-/Ausschaltverzögerung"

[Einschaltverzoegerung]: https://github.com/brickpool/logo/blob/master/extras/images/Einschaltverzoegerung.jpg "Einschaltverzögerung"

[Flankengetriggertes_Wischrelais]: https://github.com/brickpool/logo/blob/master/extras/images/Flankengetriggertes_Wischrelais.jpg "Flankengetriggertes Wischrelais"

[Impulsgeber]: https://github.com/brickpool/logo/blob/master/extras/images/Impulsgeber.jpg "Asynchroner Impulsgeber"

[Speichernde_Einschaltverzoegerung]: https://github.com/brickpool/logo/blob/master/extras/images/Speichernde_Einschaltverzoegerung.jpg "Speichernde Einschaltverzögerung"

[Vor-Rueckwaertszaehler]: https://github.com/brickpool/logo/blob/master/extras/images/Vor-Rueckwaertszaehler.jpg "Vor-/Rückwärtszähler"

[Wischrelais]: https://github.com/brickpool/logo/blob/master/extras/images/Wischrelais.jpg "Wischrelais"

[Wochenschaltuhr]: https://github.com/brickpool/logo/blob/master/extras/images/Wochenschaltuhr.jpg "Wochenschaltuhr"

[Zufallsgenerator]: https://github.com/brickpool/logo/blob/master/extras/images/Zufallsgenerator.jpg "Zufallsgenerator"
