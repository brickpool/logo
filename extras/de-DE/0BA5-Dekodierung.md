# 0BA5 Dekodierung

## Byte-Reihenfolge
Die Byte-Reihenfolge im LOGO ist Little-Endian, sprich das kleinstwertige Byte wird an der Anfangsadresse gespeichert bzw. die kleinstwertige Komponente zuerst genannt.

Die kleinste adressierbare Einheit (Speicherstelle) ist ein Byte. Es besteht aus 8 Bits und sein Inhalt wird hier vorwiegend mit zwei hexadezimalen Ziffern angegeben, wobei jede Ziffer für 4 Bits entsprechend einem Halbbyte steht. Das Halbbyte wird hier teilweise auch als Nibble bezeichnet. Es umfasst eine Datenmenge von 4 Bits. 

Bei Bitdarstellung werden die Bits innerhalb einer Binärzahl nach LSB-0 nummeriert, d.h. gemäß ihrer absteigenden Wertigkeit (gelesen von links nach rechts) ist das Bit0 (= das Bit Index 0) das niedrigstwertige. 

## Verwendete Ressourcen 
- Funktionsblöcke 130
- REM 60
- Digitaleingänge 24
- Digitalausgänge 16
- Merker 24
- Analogeingänge 8
- Textbox 10
- Analogausgänge 2
- Programmzeilenpeicher 2000
- Blocknamen 64
- Analoge Merker 6
- Cursortasten 4
- Schieberegister 1
- Schieberegisterbits 8
- Offene Klemme 16

## Adressübersicht

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
| 05 C0 00 40 | [05C0](#05C0) - 0600 | 64    |   | Verweis auf Blockname                                  |
| 06 00 02 00 | [0600](#0600) - 0800 | 512   |   | Blockname                                              |
| 08 00 02 80 | [0800](#0800) - 0A80 | 640   |   | Textfeld 10; 64 Bytes / jedes Textfeld                 |
|             | 0A80 - 0C00 | 384   |   | = 0 (384 = 0180h)                                      |
| 0C 00 00 14 | [0C00](#0C00) - 0C14 | 20    |   | Verweis auf Ausgänge, Merker (0E20 - 0EE8)             |
| 0C 14 01 04 | [0C14](#0C14) - 0D18 | 260   |   | Verweis auf Programmspeicher (130 Blöcke)              |
|             | 0D18 - 0E20 | 264   |   | = 0 (264 = 0108h)                                      |
| 0E 20 00 28 | [0E20](#0E20) - 0E48 | 40    |   | Digitalausgänge Q1 bis Q16                             |
| 0E 48 00 3C | [0E48](#0E48) - 0E84 | 60    |   | Merker M1 bis M24                                      |
| 0E 84 00 14 | [0E84](#0E84) - 0E98 | 20    |   | Analogausgang AQ1, AQ2 / Analoge Merker AM1 bis AM6    |
| 0E 98 00 28 | [0E98](#0E98) - 0EC0 | 40    |   | Offene Klemme X1 bis X16                               |
| 0E C0 00 28 | 0EC0 - 0EE8 | 40    |   |                                                        |
| 0E E8 07 D0 | 0EE8 - 16B8 | 2000  |   | Programmzeilenpeicher                                  |
|             | 4100        | 1     | W |                                                        |
|             | [4300](#FB00)        | 1     | W | = 00, RTC schreiben komplett                           |
|             | [4400](#FB00)        | 1     | W | = 00, RTC auslesen angefordert                         |
|             | 4740        | 1     | W | = 00, Passwort lesen/schreiben initialisiert           |
| 01 48 FF    | [48FF](#48FF)        | 1     | R | Passwort vorhanden?                                    |
|             | 1F00        | 1     |   |                                                        |
|             | 1F01        | 1     |   |                                                        |
|             | [1F02](#1F02)        | 1     |   | Revisions Byte                                         |
|             | [FB00](#FB00) - FB05 | 6     |   | RTC-Uhr                                                |

__Hinweis:__
Maximaler Bereich = 0E 20 08 98 Adr 0E20 - 16B8


## <a name="0552"></a>Displayinhalt nach Netz-Ein

Speicherbereich: 0552, 1 Byte

Zugriffsmethode: Lesen und Schreiben

Darstellungsformat:
```
send> 02 05 52 
recv< 06
03 05 52 00
03 05 52 XX
```

```
XX:
  00 = Datum/Uhrzeit
  01 = Ein-/Ausgänge
```

## <a name="0553"></a>Analogausgang im STOP-Modus

Speicherbereich: 0553 - 0558, Anzahl = 5 Bytes

Zugriffsmethode: Lesen und Schreiben

Darstellungsformat:
```
send> 05 05 53 00 05 
recv< 06
00 C4 03 D5 01 13
00 [C4 03] [D5 01] 13
XX [AQ1  ] [AQ2  ] XOR
```

Wertebereich: 0.00 - 9.99

```
IF XX = 01
  Alle Ausgänge behalten den letzten Wert bei
THEN
{
  AQ1 Wert im Betriebsart STOP
  AQ2 Wert im Betriebsart STOP
}
```

Berechnungsmethode:
```
00 [C4 03] [D5 01]
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

## <a name="05C0"></a>Verweis auf Blockname

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
64 Bytes / pro Textfeld

Speicherbereich: 0800 - 0A80, 640 Bytes (40 * 16) 

Standarddaten:
```
FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 // (40x)
...
```

Darstellungsformat:
```
-----------------------------------------------
03 04 20 20 20 20 00 00 00 00 00 00 00 00 00 00
02 04 0B 2B 00 00 4C 65 6E 3A 20 20 00 00 00 00
02 04 0B 2B 01 00 43 6E 74 3A 20 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00

01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
02 06 14 2B 00 00 54 6F 6C 4C 65 6E 00 00 00 00
02 06 17 2B 00 00 54 69 6D 65 73 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00

FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
... ...
FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
6C
-------------------------------------------------
03 04 [20 20 20 20 00 00 00 00 00 00 00 00] 00 00
02 04 [0B 2B 00 00 4C 65 6E 3A 20 20 00 00] 00 00
02 04 [0B 2B 01 00 43 6E 74 3A 20 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00
XX YY ~~~~~~~~~~~~~~~~ ZZ ~~~~~~~~~~~~~~~~~
                
       0B 2B 00 00                // Block02, Parameter 1
       0B 2B 01 00                // Block02, Parameter 2
                  4C 65 6E 3A     // [Len:]
                  43 6E 74 3A     // [Cnt:]
       80 50 72 69 20 81 4E 78 74 // [↑Pri ↓Nxt]
XX:
  01: Nein / Nur Text
  02: Fügen Sie den Block ein
      02 04 [0B 2B 01 00
      ~~~~~ ~~~~~~~~~~~~
      Blockeinfügeposition Blocknummer Blockparameternummer
  03: aktuelle Uhrzeit, Breite 8
  04: aktuelles Datum, Breite 10
  05: Nachrichtenaktivierungszeit, Breite 8
  06: Nachrichtenaktivierungsdatum, Breite 10

YY:
  XX = 01/03 Die Anfangsposition des Textes

  XX = 02 Blockeinfügeposition
    Die Textausrichtung ist linksbündig,
    und der Text an der aktuellen Position wird beim Einfügen des Blocks nach rechts verschoben 
    [Block Parameter Display Length].

  Beispiel
    Originaltext:
       "ABCDE"
    Fügen Sie die aktuelle Uhrzeit nach dem Buchstaben "B" ein:
       "AB [] CDE"

ZZ: Text (ASCII)-Zeichen,
    wenn die Zeile einen Block hat, repräsentieren die ersten 4 Bytes den Block.

    80 Pfeil nach oben ↑
    81 Pfeil nach unten ↓
```

Beispiele:
```
01 00 [00 00 00 00 00 00 00 00 00 00 00 00] 00 00
02 02 [14 2B 00 00 41 20 20 5A 20 20 00 00] 00 00 // [BLOCK] A _ _ Z
02 05 [17 2B 00 00 54 69 6D 65 73 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00

03 04 [20 20 20 20 00 00 00 00 00 00 00 00] 00 00 // die aktuelle Uhrzeit
04 00 [20 BA 00 00 00 00 00 00 00 00 00 00] 00 00 // Das aktuelle Datum
05 00 [00 00 00 00 00 00 00 00 20 20 20 9F] 00 00 // Nachrichtenfreigabezeit
06 00 [00 00 00 00 00 00 00 00 00 00 20 8F] 00 00 // Meldungsaktivierungsdatum
```

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
recv<
06
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

## <a name="0C14"></a>Verweis auf Programmspeicher
Zeiger auf die Blöcke im Programmzeilenpeicher 0EE8. Jeweils ein 16bit-Zeiger (ungleich FFFF, hex) zeigt auf ein Block. Ein Block ist eine Funktion, die Eingangsinformationen in Ausgangsinformationen umsetzt. Die Länge eine Blocks im Programmspeicher ist variabel.

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

Der erste Block liegt im Programmspeicher 0EE8 = 0E20 + 00C8, d.h. Der Wert an Adresse 0C14 (Offset 1) ist entweder 00C8 oder FFFF, wenn kein Programm vorhanden ist.

Befehl:
```
05 0C 14 01 04
```

Ausgabe mit gelöschten Programm:
```
FF FF FF FF FF FF FF FF FF FF FF FF ...
```

Programm bestehend aus einem Block:
```
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

# Konstanten und Klemmen - Co
Als Klemme werden alle Anschlüsse und Zustände bezeichnet (engl. Connectors = Co). Hierzu zählen Digitaleingänge, Analogeingänge, Digitalausgänge, Analogausgänge, Merker (inkl. Anlaufmerker), Analoge Merker, Schieberegisterbits, Cursortasten, Pegel und die Offenen Klemmen.

## Darstellung am Verknüpfungseingang
Sie sind nicht im Programmzeilenpeicher 0EE8 abgelegt, sondern werden mit einem festen 16bit Wert (Datentyp Word) und einem Wertebereich 0000..00FE am Eingang eines Blocks, Merkers oder einer Ausgangsklemme dargestellt. 

Das höherwertige Byte vom Word ist immer 00. Das niederwertige Byte vom Word (LoByte) zeigt den Klemmentyp bzw. nennt die Konstante (siehe Listen folgend).

## Liste Klemmen
LoByte HEX | Klemme/Merker | Beschreibung
-----------|---------------|-------------------------------
00-17      | I1..24        | Digitaleingänge
30-3F      | Q1..16        | Digitalausgänge
50-67      | M1..24        | Merker
80-87      | AI1..8        | Analogeingänge
92-97      | AM1..6        | Analoge Merker
A0-A3      | C1..3         | Cursortasten (▲, ▼, <, >)
B0-B7      | S1..8         | Schieberegisterbits

## Liste Konstanten
LoByte HEX | Konstante | Beschreibung
-----------|-----------|--------------------------
FC         | Float     | (Verwendung ??)
FD         | Pegel hi  | Blockeingang logisch = 1
FE         | Pegel lo  | Blockeingang logisch = 0
FF         | x         | nicht benutzter Anschluss

## Format im Speicher
Klemmen, die aufgrund eines Verknüpfungseinganges ein Speicherplatz besitzen, sind die Ausgänge Q1 bis Q16, AQ1 und AQ2, die Merker M1 bis M24 und AM1 bis AM6, sowie die 16 unbeschaltete Ausgänge X1 bis X16. 

Die Verdrahtung auf den Eingang einer Ausgangsklemme oder eines Merkes werden im Speicherbereich ab 0E20 - 0EC0, 200 Bytes (10*20 Bytes) abgelegt.

Das Format ist einheitlich und ist als vielfache von 20 Bytes = 2 Bytes `80 00` + 16 Bytes `<Eingänge>` + 2 Bytes `FF FF` abgelegt.
```
80 00 1a 1b ... ... 8a 8b FF FF // (20 Byte)
```

Nicht benutzte Anschlüsse (freie Eingänge) im Schaltprogramm werden mit `FFFF` angezeigt. 

```
Xa: Eingang, abhängig von b7
Xb: BIN Hi ---------------- Lo
           b7 b6 b5 b4 0000

    b7 = 0, Xa = Konstante oder Klemme
    b7 = 1, Xa = Blocknummer
    b6 = 0
    b5 = 0
    b4 = 0
```

Xa Xb: X = Element 1-8

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

## <a name="0E20"></a>Digitalausgänge - Q
Die Digitalausgänge Q1 bis Q16 befinden sich im Speicherbereich 0E20 - 0EC0 (2*20 Bytes).

Darstellungsformat:
```
80 00 Q1a Q1b ... ... Q8a  Q8b  FF FF // (20 Byte)
80 00 Q9a Q9b ... ... Q16a Q16b FF FF
```

Qna Qnb: n = Element 1-16

## <a name="0EC0"></a>Merker - M
Die Digitalausgänge M1 bis M24 befinden sich im Speicherbereich 0EC0 - 0E84 (3*20 Bytes).

Darstellungsformat:
```
80 00 M1a  M1b  ... ... M8a  M8b  FF FF // (20 Byte)
80 00 M9a  M9b  ... ... M16a M16b FF FF
80 00 M17a M17b ... ... M24a M24b FF FF
```

Mna Mnb: n = Element 1-24

## <a name="0E84"></a>Analogausgänge, Analoge Merker - AQ, AM
Die Analogen Ausgänge AQ1 und AQ2 befinden sich im Speicherbereich 0E84 - 0E98 (1*20 Bytes).

Darstellungsformat:
```
80 00 AQ1a AQ1b AQ2a AQ2b AM1a AM1b ... ... AM6a AM6b  FF FF // (20 Byte)
```

AQXa AQXb: X = Element AQ1-2<br />
AMXa AMXb: X = Element AM1-6

## <a name="0E98"></a>Offene Klemmen - X
Die Offenen Klemmen X1 bis X16 befinden sich im Speicherbereich 0E98 - 0EC0 (2*20 Bytes).

Darstellungsformat:
```
80 00 X1a  X1b  ... ... X8a  X8b  FF FF // (20 Byte)
80 00 X9a  X9b  ... ... X16a X16b FF FF
```

Xna Xnb: n = Element 1-16

# Blöcke und Blocknummern
Ein Block ist eine Funktion, die eine Ausgangsinformationen Auggrund einer Informationen an den Eingängen setzt.

## Darstellung am Verknüpfungseingang
Alle Blöcke sind im Programmzeilenpeicher 0EE8 abgelegt und werden mit einem 16bit Wert (Datentyp Word) im Wertebereich 8000..C08C am Eingang eines Blocks, Merkers oder einer Ausgangsklemme dargestellt. 

Bei einem Block ist das Most Significant Bit (MSB = `1`) vom Word immer gesetzt. Das niederwertige Byte vom Word (LoByte) benennt die Blocknummer im Wertebereich 0A..8C, entsprechend B001 bis B130.

Bestimmte Eingänge von Grund- und Sonderfunktionen können einzeln negieren, d.h. liegt an dem bestimmten Eingang eine `1` an, so verwendet das Schaltprogramm eine `0`. Liegt eine `0` an, so wird eine `1` verwendet. Diese Information ist im Bit7 vom HiByte gespeichert:

Eingang | HiByte | BIN
--------|--------|---------------
normal  | 80     | 1000 0000 = 80
negiert | C0     | 1100 0000 = C0

## Zuordnen einer Blocknummer
Die Erklärung erfolgt Anhand eines Beispiel. Im Beispiel kommen die Klemmen X1 und X3 bis X5 zur Anwendung (ungleich FFFF).

Die Klemmen sind wie folgt verdahtet:
- Der Eingang von Q1 ist mit dem Ausgang von Block B001 verbunden
- Eingang Qw mit Ausgang B005

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

# Grundfunktionen - GF
Grundfunktionen sind einfache Grundverknüpfungsglieder der boolschen Algebra.

## Format im Speicher
Die Formatlänge ist variabel und hat 4, 8 oder 12 Bytes = 2 Bytes `<GF> 00` + 0 bis 8 Bytes `<Eingänge>` + 0 bis 2 Bytes `FF FF`.
```
GF 00 1a 1b                         // (4 Bytes)
GF 00 1a 1b 2a 2b FF FF             // (8 Bytes)
GF 00 1a 1b 2a 2b 3a 3b 4a 4b FF FF // (12 Bytes)
```
GF: Funktionsblock, siehe Liste Grundfunktionen

```
Xa: Eingang, abhängig von b7
Xb: BIN Hi ---------------- Lo
           b7 b6 b5 b4 0000

    b7 = 0, Xa = Konstante oder Klemme
    b7 = 1, Xa = Blocknummer
    b6 = 0, Konnektor normal (nicht negiert)
    b6 = 1, Konnektor negiert
    b5 = 0
    b4 = 0
```

Xa Xb: X = Element 1,2-4

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
GF Pa [Nr,B2] [--,--] [Co,I2] [--,--]         // OR
```

## Liste Grundfunktionen
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

# Sonderfunktionen - SF
Sonderfunktionen sind ähnlich dem Grundfunktionen im Speicher abgelegt. Neben den Verknüpfungseingängen sind beinhalten diese jedoch Zeitfunktionen, Remanenz und verschiedenste Parametriermöglichkeiten.

## Format im Speicher
Die Formatlänge ist variabel und hat 8, 12, 20 oder 24 Bytes = 2 Bytes `<SF> <Pa>` + 4 bis 20 Bytes `<Daten>` + 2 Bytes `FF FF`.

SF: Block, siehe Liste Sonderfunktionen<br />
Pa: Parameter, siehe Blockparameter

## Liste Sonderfunktionen
HEX | RAM (Bytes) | Rem (Bytes) | Beschreibung
----|-------------|-------------|---------------------------------
[21](#SF21)  | 8           | 3           | Einschaltverzögerung
[22](#SF22)  | 12          | 3           | Ausschaltverzögerung
[23](#SF23)  | 12          | 1           | Stromstoßrelais
[24](#SF24)  | 20          | -           | Wochenschaltuhr
[25](#SF25)  | 8           | 1           | Selbsthalterelais
[27](#SF27)  | 12          | 3           | Speichernde Einschaltverzögerung
[2B](#SF2B)  | 24          | 5           | Vor-/Rückwärtszähler
[2D](#SF2D)  | 12          | 3           | Asynchroner Impulsgeber
[31](#SF31)  | 12          | 3           | Treppenlichschalter
[39](#SF39)  | 20          | -           | Analogwertüberwachung

## Bezeichnung der Eingänge:
- S (Set): Über den Eingang S kann der Ausgang auf `1` gesetzt.
- R (Reset): Der Rücksetzeingang R schaltet Ausgänge auf `0`.
- Trg (Trigger): Über diesen Eingang wird der Ablauf einer Funktion gestart.
- Cnt (Count): Über diesen Eingang werden Zählimpulse aufgenommen.
- Fre (Frequency): Auszuwertende Frequenzsignale werden an den Eingang mit dieser Bezeichnung angelegt.
- Dir (Direction): Über diesen Eingang legen Sie die Richtung fest.
- En (Enable): Dieser Eingang aktiviert die Funktion eines Blocks. Liegt der Eingang auf `0`, werden andere Signale vom Block ignoriert.
- Inv (Invert): Das Ausgangssignal des Blocks wird invertiert, wenn dieser Eingang angesteuert wird.
- Ral (Reset all): Alle internen Werte werden zurückgesetzt.

## <a name="SF21"></a>Einschaltverzögerung

RAM/Rem: 8/3

Darstellungsformat:
```
21 40 01 00 7A 80 00 00 FF FF FF FF
21 40 [01 00] [7A 80] 00 00 FF FF FF FF
SF Pa [Trg  ] [Par  ] 00 00 FF FF FF FF
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Trg: Eingang Trg (Co oder GF/SF)
Par: Parameter [T](#zeitdefinition) (T ist die Zeit, nach der der Ausgang eingeschaltet wird)
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

RAM/Rem: 12/3

Darstellungsformat:
```
22 80 01 00 02 00 1F CD 00 00 00 00
22 80 [01 00] [02 00] [1F CD] 00 00 00 00
SF Pa [Trg  ] [R    ] [Par  ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Trg: Eingang Trg (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par: Parameter [T](#zeitdefinition) (Der Ausgang schaltet aus, wenn die Verzögerungszeit T abläuft)
```

Beispiel:
```
22 80 01 00 02 00 1F CD 00 00 00 00 // Ausschalterzögerung 55:59 (h: m)
```

## <a name="SF23"></a>Stromstoßrelais

RAM/Rem: 12/1

Darstellungsformat:
```
23 00 02 00 FF FF FF FF 00 00 00 00
23 00 [02 00] [FF FF] [FF FF] 00 00 00 00
SF Pa [Trg  ] [S    ] [R    ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 1 Byte REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Trg: Eingang Trg (Co oder GF/SF)
S: Eingabe S (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par:
  RS (Vorrang Eingang R) oder
  SR (Vorrang Eingang S)
```

## <a name="SF24"></a>Wochenschaltuhr

RAM/Rem: 20/-

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
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 0 Byte REM (Def)
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

No1: Nockenparameter 1
No2: Nockenparameter 2
No3: Nockenparameter 3

  OnX:  Einschaltzeitpunkt hh:mm (0-23:0-59)
        FF FF = deaktiviert
        OnL OnH
          \ /
          / \
        OnH OnL
        T = 60 * h + m
  
        Beispiel:
        F2 = 1111 0010 = 242 (Dec) = 60 × 4 + 2 = 242   // On = 04:02h
  
  OffX: Ausschaltzeitpunkt hh:mm (0-23:0-59)
        FF FF = deaktiviert
        OffL OffH
           \ /
           / \
        OffH OffL
        T = 60 * h + m
  
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

RAM/Rem: 8/1

Darstellungsformat:
```
25 00 0A 80 FF FF 00 00
25 00 [0A 80] [FF FF] 00 00
SF Pa [S    ] [R    ] 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 1 Byte REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

S: Eingabe S (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
```

## <a name="SF27"></a>Speichernde Einschaltverzögerung

RAM/Rem: 12/3

Darstellungsformat:
```
27 80 02 00 FF FF 36 81 00 00 00 00
27 80 [02 00] [FF FF] [36 81] 00 00 00 00
SF Pa [Trg  ] [R    ] [Par  ] 00 00 00 00
```

```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Trg: Eingang Trg (Co oder GF/SF)
R: Eingang R (Co oder GF/SF)
Par: Parameter [T](#zeitdefinition) (T ist die Zeit, nach der der Ausgang eingeschaltet wird)
```

Beispiel:
```
27 80 02 00 FF FF 36 81 00 00 00 00
```
Remanenz aktiv, Parameterschutz aktiv, Trg = I3, R = -, 05:10 (h:m)

## <a name="SF2B"></a>Vor-/Rückwärtszähler

RAM/Rem: 24/5

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
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

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
  
StartVal: Ausgangswert, ab dem entweder vorwärts oder rückwärts gezählt wird (0BA6)
```

## <a name="SF2D"></a>Asynchroner Impulsgeber

RAM/Rem: 12/3

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
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

En: Eingang En (Co oder GF/SF)
INV: Eingang INV (Co oder GF/SF)
Par:
  TH: Parameter [TH](#zeitdefinition) (Impulsdauer TH)
  TL: Parameter [TL](#zeitdefinition) (Impulspausendauer TL)
```

## <a name="SF39"></a>Analogwertüberwachung

RAM/Rem: 20/-

Darstellungsformat:
```
39 40 FD 00 92 00 C8 00 66 00 00 00 00 00 00 00 00 00 00 00
39 40 [FD 00] [92 00] [C8 00 66 00 00 00 00 00 00 00 00 00 00 00
SF Pa [En   ] [Ax   ] [Par ... 
```
  
```
SF: Funktionsblock, siehe Liste Sonderfunktionen
Pa: Funktionsblockparameter
    Hi ---------------- Lo
       b7 b6 b5 b4 0000

    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 0 Byte REM (Def)
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

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

## Zeitdefinition

Darstellungsformat:
```
   .. xx Z2 Z1 xx ..

   Format Beschreibung:
    xx: irgendein Byte
    Z1 Z2: Zeitdefinition
      Z2 Z1
       \ /
       / \
      Z1 Z2
      Hi ----------------- [Z1] ----- | ---------------- [Z2] ---> Lo
         b15 b14 | b13 b12 xxxx xxxx b3 b2 b1 b0
         ~~~~~~~
      b15 b14 = 11 Stunden (h: m) [0-99: 0-59]
      b15 b14 = 10 Minuten (m: s) [0-99: 0-59]
      b15 b14 = 01 Sekunde (s: 1 / 100s) [0-99: 0-99]
      
      b13..b0 (14bit)
         Länge der Zeit (m | s | 1 / 100s) Ganzzahl: T,
         if (b15 b14 = 11) // Stunden (h: m)
           T = h * 60 + m
         if (b15 b14 = 10) // Minuten (m: s)
           T = m * 60 + s
         if (b15 b14 = 01) // Sekunde (s: 1 / 100s)
           T = s * 100 + (1 / 100s)
```

Beispiel:
```
  21 40 01 00 7A 80 00 00 / bei Verspätung 2: 2 (m: s)
  21 40 01 00 7A C0 00 00 / bei Verspätung 2: 2 (h: m)
  21 40 01 00 CA 40 00 00 / Einschaltverzögerung 2: 2 (s: 1 / 100s)
  21 C0 01 00 FE 41 00 00 / Einschaltverzögerung 5:10 (s: 1 / 100s) Aktivierung Remanenz
  21 00 01 00 FE 41 00 00 / Einschaltverzögerung 5:10 (s: 1 / 100s) Schutz der Aktivierungsparameter
        ~~~~~
    0111 1010 1000 0000/2: 2 (m: s)
    0111 1010 1100 0000/2: 2 (h: m)
    1100 1010 0100 0000/2: 2 (s: 1 / 100s)
    1111 1110 0100 0001/5: 10 (s: 1 / 100s) Aktiviert den Parameterschutz
    0110 1111 1101 0111 / auf Verspätung 99:59 (h: m)
          \ /
          / \
    10 | 00 0000 0111 1010/2: 2 (m: s)
    11 | 00 0000 0111 1010/2: 2 (h: m) 122?
    01 | 00 0000 1100 1010/2: 2 (s: 1 / 100s) 202
    01 | 00 0001 1111 1110/5: 10 (s: 1 / 100s) Aktiviert den Parameterschutz 510
    11 | 01 0111 0110 1111/99: 59 (h: m) 5999


  41 0100 0001
  FE 1111 1110
  40 0100 0000
  C0 1100 0000

0C 67 | 67 0C / 99:96 (s: 1 / 100s) / 01 | 10 0111 0000 1100/9996 OK
      | 67.0C / 11 | 00 0111.0000 1100/1084
CD 91 | 91 CD / 75:57 (m: s) / 01 | 00 1000 1100 1101/2253
      | 91.CD / 10 | 01 0001.1100 1101/4557 OK = 75 * 60 + 57
CD D1 | D1 CD / 75: 57 (h: m) / 11 | 01 0001 1100 1101/4557 OK = 75 * 60 + 57
      | D1.CD / / 11 | 01 0001.1100 1101/4557 OK = 75 * 60 + 57
6F D7 0110 1111 1101 0111
6F 97 0110 1111 1001 0111
Zehn
59 0111011
99 1100011
0F 67 [67 0F = 0110 0111 0000 1111]

----------------------------
11 01 0111 0110 1111
10 01 0111 0110 1111
  ~~~~~~~~~~~~~~~~~ = Dec 5999 = Hex 176F
```

## <a name="1F02"></a>Version und Firmware 
   
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

Read Byte | Wert
----------|-----
1F00      | 04
1F01      | 00
1F02      | 42

```
42H = 0100 0010 // 01.00.00.10 ??
04H = 0000 0100
```

Version | Bestellnummer
--- | ---
Standard LOGO! 12 / 24RC (DC) | 6ED1052-1MD00-0BA5
LOGO! 24 (DC) | 6ED1052-1CC00-0BA5
LOGO! 24RC (Wechselstrom/Gleichstrom) | 6ED1052-1HB00-0BA5
LOGO! 230RC (Wechselstrom) | 6ED1052-1FB00-0BA5

```
02 1F 00
02 1F 01
02 1F 02
02 1F 03
02 1F 04
02 1F 05
02 1F 06
02 1F 07
-> 04 00 42 56 32 30 32 30
```

```
    1F00  1F01  1F02  | 1F03  1F04  1F05  1F06  1F07
    04    00    42    | 56    32    30    32    30
Dec 04    00    66    | 86    50    48    50    48
Asc             B     | V     2     0     2     0
```

BIOS-Version = 2.02.0

## <a name="48FF"></a>Passwort vorhanden

Read Byte | Wert | Beschreibung
----------|------|-------------
48FF      | 40   | ja
48FF      | 00   | nein

## Speicherbereich 1E 00

```
02 1E 00
02 1E 01
02 1E 02
02 1E 03
02 1E 04
02 1E 05
02 1E 06
02 1E 07
-> 00 00 00 00 00 00 00 00
```

## Speicherbereich 20 00

```
02 20 00
02 20 01
02 20 02
02 20 03
02 20 04
02 20 05
02 20 06
02 20 07
-> 00 00 00 00 00 00 00 00
```

## Speicherbereiche 05 22, 05 5E-5F

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

## <a name="FB00"></a>RTC-Uhr

Speicherbereich: FB00, 6*1 Byte

Adresse | Wert
--- | ---
FB00 | Tag
FB01 | Monat
FB02 | Jahr
FB03 | Minuten
FB04 | Stunden
FB05 | Wochentag

### Schreiben
```
01 FB XX YY   // XX = [00-05], YY = Wert
-> 06         // OK

01 43 00 00   // Werte in RTC uebernehmen
-> 06         // OK
```

### Auslesen
```
01 44 00 00       // Werte aus RTC auslesen
-> 06             // OK
02 FB XX          // XX = [00-05]
-> 06 03 FB XX YY // YY = Wert
```


# Anmerkungen zu 0BA6

| Beispiel    | Adresse     | Länge |   |                                      |
| ------------|-------------|-------|---|--------------------------------------|
| 0C 00 01 A4 | 0C00 - 0DA4 | 420   |   | Anzahl der Blöcke 200 / REM 250      |
| 0E E8 0E D8 | 0EE8 - 1DC0 | 3800  |   | Programmzeilenpeicher 1DC0h = 7616 |
