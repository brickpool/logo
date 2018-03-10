# 0BA5 Dekodierung

## Verwendete Ressourcen 
- Funktionsblock 0/130
- REM 0/60
- Digitaler Eingang 1/24
- Digitaler Ausgang 1/16
- Flag 0/24
- Analogeingang 0/8
- Textfeld 0/10
- Analogausgang 0/2
- Programmspeicherbereich 0/2000
- Blockname 0/64
- Analogmerker (Register) 0/6
- Cursortasten 0/4
- Schieberegister 0/1
- Schieberegister Bit 0/8
- Offener Anschluss 0/16
- Maximale Schachtelungstiefe I1-Q1: ?

## Fehlercodes:
- 15 02 Timeout, bei Befehl 04/05 ist der zweite Zyklus der Operation abgelaufen
- 15 03 Auslesen über Sepichergrenze
- 15 05 Unbekannter Befehl / Dieser Modus wird nicht unterstützt! RUN ?
- 15 07 @RUN wird in diesem Modus nicht unterstützt

## Adressübersicht

| Beispiel    | Adresse     | Länge |   |                                                        |
|-------------|-------------|-------|---|--------------------------------------------------------|
|             | 0522        | 1     | W |                                                        |
|             | [0552]        | 1     |   | Standardanzeige nach dem Einschalten                   |
| 05 53 00 05 | [0553] - 0558 | 5     |   | Einstellung des Analogausgangs im Betriebszustand STOP |
|             | 055E        | 1     |   |                                                        |
|             | 055F        | 1     |   |                                                        |
| 05 66 00 0A | 0566 - 0570 | 10    |   | Passwortspeicherbereich                                |
| 05 70 00 10 | 0570 - 0580 | 16    |   | Programmname                                           |
|             | 0580 - 05C0 |       |   | = 0 (0040H = 64)                                       |
| 05 C0 00 40 | 05C0 - 0600 | 64    |   | Blocknamenindex                                        |
| 06 00 02 00 | 0600 - 0800 | 512   |   | Blockname                                              |
| 08 00 02 80 | 0800 - 0A80 | 640   |   | Textfeld 10; 64 Bytes / jedes Textfeld                 |
|             | 0A80 - 0C00 |       |   | = 0 (0180h = 384)                                      |
| 0C 00 00 14 | 0C00 - 0014 | 20    |   | Verweis auf Ein-/Ausgänge, Merker (0E20 - 0EE8)        |
| 0C 14 01 04 | 0C14 - 0D18 | 260   |   | Verweis auf Programmspeicher (130 Blöcken)             |
|             | 0D18 - 0E20 | null  |   | (0108h = 264)                                          |
| 0E 20 00 28 | 0E20 - 0E48 | 40    |   | Digitalausgänge Q1 bis Q16                             |
| 0E 48 00 3C | 0E48 - 0E84 | 60    |   | Merker M1 bis M24                                      |
| 0E 84 00 14 | 0E84 - 0E98 | 20    |   | Analogausgang AQ1 bis AQ2                              |
| 0E 98 00 28 | 0E98 - 0EC0 | 40    |   | unbeschaltete Ausgänge X1 bis X16                      |
| 0E C0 00 28 | 0EC0 - 0EE8 | 40    |   |                                                        |
| 0E E8 07 D0 | 0EE8 - 16B8 | 2000  |   | Programmspeicherbereich                                |
|             | 4100        | 1     | W |                                                        |
|             | 4400        | 1     | W | = 00, Clock-Schreibinitialisierung                     |
|             | 4740        | 1     | W | = 00, Passwort. Die Übertragung beginnt                |
|             | 48FF        | 1     | R | Passwort vorhanden? ja 40h; nein 00h                   |
|             | 1F00        | 1     |   |                                                        |
|             | 1F01        | 1     |   |                                                        |
|             | 1F02        | 1     |   | Revision Byte                                          |
|             | FB00 - FB05 | 6     |   | LOGO! Uhr                                              |
| 01 FB 00    |             |       |   | LOGO! Uhr Parameter 1                                  |
| ...         |             |       |   | ..                                                     |
| 01 FB 05    |             |       |   | LOGO! Uhr Parameter 6                                  |

__Hinweis:__
Maximaler Bereich = 0E 20 08 98 Adr 0E20 - 16B8


## Textfeld
Speicherbereich: 0800 - 0A80, 640 Bytes (40 * 16) 

Standarddaten:
```
FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 // (40x)
   ... ...
XOR
```

## <a name="0552"></a>Standardanzeige nach dem Einschalten

Speicherbereich: 0552, 1 Byte

Zugriffsmethode:
```
01 05 52 [XX]
02 05 52
```

XX: Wert 01 = Eingabe/Ausgabe; FF = Zeit/Datum

## <a name="0553"></a>Analogausgang im STOP-Modus

Speicherbereich: 0553 - 0558, Anzahl = 5

Zugriffsmethode: `05/04 05 53 00 05`

Bereich: 0.00 - 9.99

Darstellungsformat:
```
B1 B2    B3    B4    B5    B6
B1 AQ1Va AQ1Vb AQ2Va AQ2Vb (XOR)
```

```
IF B1 = 01
  Alle Ausgänge haben den letzten Wert
THEN
{
  AQ1 fester Ausgangswert B2 B3
  AQ2 fester Ausgangswert B4 B5
}
```

Berechnungsmethode:
```
00 C4 03 D5 01 13
  ~ ~ ~ ~ ~ ~
    \ / \ /
    / \ / \
  03 C4 01 D5 (hexadezimal)
    964 469 (Dezimal)
 ______________
      100

   9.64 4.69
```

Beispiel:
```
01 00 00 00 00 | 01
00 50 00 28 00 | 78
```

## Standardanzeige nach dem Einschalten

B1 = 01 Eingang / Ausgang; B1 = 00 Zeit / Datum

## Programmname

Standarddaten
```
20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20
```

## RTC-Uhr

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
01 FB XX YY   // XX = [00-05], YY = Wert,
-> 06         // OK

01 43 00 00   // Bestätigen
```

### Auslesen
```
01 44 00 00       // initialisieren
02 FB XX          // XX: Adresse
-> 06 03 FB XX YY // YY: Wert
```


## Blocknamenindex, Blockname

Speicherbereich Blocknamensindex: 0A-0E = B001-B005

Blockname: 8 Byte Länge, bei weniger als 8 Byte wird mit `00` aufgefüllt, gefolgt von `FF`.

Beispiele
```
6B 75 61 69 30 31 00 FF
4B 55 41 49 41 42 43 44
```

# Konstanten und Klemmen - Co

## Digitalausgänge - Q
Die Digitalausgänge Q1 bis Q16 befinden sich im Speicherbereich 0E20 - 0EC0.

Darstellungsformat:
```
80 00 Q1a Q1b ... ... Q8a  Q8b  FF FF // (20 Byte)
80 00 Q9a Q9b ... ... Q16a Q16b FF FF
```

QXa QXb: X = Element Q1-16

## Analogausgänge - AQ
Die Analogen Ausgänge AQ1 und AQ2 befinden sich im Speicherbereich 0E84 - 0E98.


## Offene Klemmen - X
Die Offenen Klemmen X1 bis X16 befinden sich im Speicherbereich 0E98 - 0EC0.

Darstellungsformat:
```
80 00 X1a  X1b  ... ... X8a  X8b  FF FF // (20 Byte)
80 00 X9a  X9b  ... ... X16a X16b FF FF
```

Xza Xzb: z = Element X1-16

## Liste Konstanten
HEX   | Konstantent | Beschreibung
------|-------------|-------------------------------
FC    | Float       | 
FD    | Pegel hi    | Blockeingang logisch = 1
FE    | Pegel lo    | Blockeingang logisch = 0

## Liste Eingänge und Merker
HEX   | Klemme/Konst. | Beschreibung
------|---------------|-------------------------------
00-17 | I1..24        | Digitaleingänge
50-67 | M1..24        | Digitalmerker
80-87 | AI1..8        | Analogeingänge
92-97 | AM1..6        | Analogmerker
A0-A3 | C1..3         | Cursortasten (▲, ▼, <, >)
B0-B7 | S1..8         | Schieberegisterbits


# Grundfunktionen - GF

## Format
Format einheitlich, vielfache von 20 Bytes = 1Byte <80 00> + 16Byte <Daten> + 2Byte <FF FF> + XOR.
```
80 00 1a 1b ... ... 8a 8b FF FF // (20 Byte)
XX ll Pa Da Pb Db Pc Dc Pd Dd ...
```

```
LL: Funktionsblock
ll: ??

Px: GF siehe Liste Grundfunktionen

Dx:
  Hi ---------------- Lo
     b7 b6 b5 b4 0000

  b7 = 0, dies ist eine Konstante oder Klemme
  b7 = 1, dies ist ein Block

  b6 = 0, Konnektor normal
  b6 = 1, Konnektor negiert

```

Konnektor Beispiel:
```
| Konnektor | Verschiedenes (Port...)                 |
| --------------------------------------------------- |
| normal    | 0A 80 | 1000 0000 = 80 | 0000 0000 = 00 |
| negiert   | 0A C0 | 1100 0000 = C0 | 0100 0000 = 40 |
```

Beispiel
```
05 0E 98 00 28
->
80 00 0A 80 FF FF 17 80 14 80 12 80 FF FF FF FF FF FF FF FF
80 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
1B
```

__Hinweis:__ nicht verwendete Ports werden mit FF angezeigt.

Block | HEX | TEN
------|-----|-----
B001  | 0A  | 10
B002  | -   | -
B014  | 17  | 23
B011  | 14  | 20
B009  | 12  | 18

Block | HEX | TEN | Offset (-10)
------|-----|-----|-------------
B001  | 0A  | 10  | 0
B009  | 12  | 18  | 8
B011  | 14  | 20  | 10
B014  | 17  | 23  | 13



## Liste Grundfunktionen
HEX | BIN       | Grundfunktion
----|-----------|----------------------------
01  | 0000 0001 | AND (UND)
02  | 0000 0010 | OR (ODER)
03  | 0000 0011 | NOT (Negation, Inverter)
04  | 0000 0100 | NAND (UND nicht)
05  | 0000 0101 | NOR (ODER nicht)
06  | 0000 0110 | XOR (exklusiv ODER)
07  | 0000 0111 | AND mit Flankenauswertung
08  | 0000 1000 | NAND mit Flankenauswertung


# Sonderfunktionen - SF

## Liste Sonderfunktionen
HEX | RAM (Bytes) | Rem (Bytes) | Beschreibung
----|-------------|-------------|---------------------------------
12  | 12          | 3           | Speichernde Einschaltverzögerung
21  | 8           | 3           | Einschaltverzögerung
22  | 12          | 3           | Ausschaltverzögerung
23  | 12          | 1           | Stromstoßrelais
24  | 20          | -           | Wochenschaltuhr
25  | 8           | 1           | Selbsthalterelais
2B  | 28          | 5           | Vor-/Rückwärtszähler
2D  | 12          | 3           | Asynchroner Impulsgeber


## Einschaltverzögerung
Speicherbereich: Programmspeicherbereich [0EE8 +]

Darstellungsformat:
```
21 40 01 00 7A 80 00 00 FF FF FF FF
XX Xp Yt Yt Z2 Z1 00 00 FF FF FF FF
```

```
XX: Funktionsblock
Xp: Funktionsblockparameter
  Hi ---------------- Lo
  b7 b6 b5 b4 0000
  ~~~~~
  b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
  b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)
Yt Yt: Eingang Trg
Z1 Z2: Parameter T (T ist die Zeit, nach der der Ausgang eingeschaltet wird)
```

Beispiel:
```
21 40 01 00 7A 80 00 00 // bei Verspätung 2: 2 (m: s)
21 40 01 00 7A C0 00 00 // bei Verspätung 2: 2 (h: m)
21 C0 01 00 FE 41 00 00 // Einschaltverzögerung 5:10 (s: 1 / 100s) Aktivierung Remanenz
```

## Ausschaltverzögerung
Speicherbereich: Programmspeicherbereich [0EE8 +]

Darstellungsformat:
```
22 80 01 00 02 00 1F CD 00 00 00 00
XX Xp Yt Yt Yr Yr Z2 Z1 00 00 00 00
```

```
XX Funktionsblock
Xp Funktionsblockparameter
 Hi ---------------- Lo
    b7 b6 b5 b4 0000
    ~~~~~
    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Yt Yt: Eingang Trg
Yr Yr: Eingang R
Z1 Z2: Parameter T (Der Ausgang schaltet aus, wenn die Verzögerungszeit T abläuft)
```


Beispiel:
```
80 01 00 02 00 1F CD 00 00 00 00 // Disconnect Verzögerung RAM: 12, REM: 3; 55:59 (h: m)
```

## Speichernde Einschaltverzögerung

Speicherbereich: Programmspeicherbereich [0EE8 +]

RAM/Rem: 12/3

Darstellungsformat:
```
27 40 02 00 FF FF 00 40 00 00 00 00
27 80 02 00 FF FF 36 81 00 00 00 00
XX Xp Yt Yt Yr Yr Z2 Z1 00 00 00 00
```

```
XX Funktionsblock
Xp Funktionsblockparameter
 Hi ---------------- Lo
    b7 b6 b5 b4 0000
    ~~~~~
    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Yt Yt: Eingang Trg
Yr Yr: Eingabe R-Element
Z1 Z2: Zeitdefinition (siehe [LOGO! Funktionsblock Zeitdefinition])
```


Beispiel:
```
27 80 02 00 FF FF 36 81 00 00 00 00 // Remanenz aktiv, Parameterschutz aktiv; Trg = I3, Yr = NA; 5:10 (h: m)
```

## Asynchroner Impulsgeber

Speicherbereich: Programmspeicherbereich [0EE8 +]

RAM/Rem: 12/3

Darstellungsformat:
```
2D 40 02 00 FF FF 02  80  02  80  00 00
XX Xp Yt Yt Yr Yr ZH2 ZH1 ZL2 ZL1 00 00
```

```
XX Funktionsblock
Xp Funktionsblockparameter
 Hi ---------------- Lo
    b7 b6 b5 b4 0000
    ~~~~~
    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Yt Yt: Eingang En
Yr Yr: Eingang INV
ZH1 ZH2: Parameter TH (Impulsdauer TH, siehe Handbuch)
ZL1 ZL2: Parameter TL (Impulspausendauer TL, siehe Handbuch)
```


## Vor-/Rückwärtszähler

Speicherbereich: Programmspeicherbereich [0EE8 +]

RAM/Rem: 28/5

Darstellungsformat:
```
2B 40 FF FF 02 00 FF FF 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 25 00 0A 80 FF FF 00 00
23 00 02 00 FF FF FF FF 00 00 00 00

2B 40 [FF FF] [02 00] [FF FF] [00 00 00 00 00 00 00 00] [00 00 00 00 00 00 00 00]
XX Xp [R    ] [Cnt  ] [Dir  ] [Parameter On           ] [Parameter Off          ]
25 00 0A 80 FF FF 00 00 23 00 02 00 FF FF FF FF 00 00 00 00
```

```
XX Funktionsblock
Xp Funktionsblockparameter
 Hi ---------------- Lo
    b7 b6 b5 b4 0000
    ~~~~~
    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 3 Bytes REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Eingang R
Eingang Cnt
Eingang Dir
Parameter
  On: Einschaltschwelle, Wertebereich: 0 ... 999999
  Off: Ausschaltschwelle, Wertebereich: 0 ... 999999
StartVal: Ausgangswert, ab dem entweder vorwärts oder rückwärts gezählt wird. (0BA6)
```

## Selbsthalterelais

RAM/Rem: 8/1

Darstellungsformat:
```
25 00 0A 80 FF FF 00 00
25 00 [0A 80] [FF FF] 00 00
XX Xp [S    ] [R    ] 00 00
```

```
XX Funktionsblock
Xp Funktionsblockparameter
 Hi ---------------- Lo
    b7 b6 b5 b4 0000
    ~~~~~
    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 1 Byte REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Eingabe S
Eingang R
```

## Stromstoßrelais
RAM/Rem: 12/1

Darstellungsformat:
```
23 00 02 00 FF FF FF FF 00 00 00 00
23 00 [02 00] [FF FF] [FF FF] 00 00 00 00
XX Xp [Trg  ] [S    ] [R    ] 00 00 00 00
```

```
XX Funktionsblock
Xp Funktionsblockparameter
 Hi ---------------- Lo
    b7 b6 b5 b4 0000
    ~~~~~
    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 1 Byte REM
    b6: Parameterschutz, 0 = aktiv, 1 = Nein (Def)

Eingang Trg
Eingabe S
Eingang R
  Parameter
  RS (Vorrang Eingang R) oder
  SR (Vorrang Eingang S)
```

## Wochenschaltuhr
Speicherbereich: Programmspeicherbereich [0EE8 +]

RAM/Rem: 20/-

Darstellungsformat:
```
24 40 F2 00 A0 00 FF FF FF FF FF FF FF FF 2A 00 00 00 00 00
24 40 [(F2 00) (A0 00)] [(FF FF) (FF FF)] [(FF FF) (FF FF)] [2A 00 00 00 00 00]
XX Xp TOa2 TOa1 TCa2 TCa1 TOb2 TOb1 TCb2 TCb1 TOc2 TOC1 TCc2 TCc1 TWa TWb TWcxxxxxx]
```

```
XX Funktionsblock
Xp Funktionsblockparameter
 Hi ---------------- Lo
    b7 b6 b5 b4 0000
    ~~~~~
    b7: Remanenz, 1 = Aktiv; 0 = Nein; * Remanenz nutzt 1 Byte REM

     Txax: Periode 1, Txbx: Periode 2, Txcx: Periode 3;

     TOx1 TOx2: Pünktliche Definition [0-23: 0-59 (h: m)
       TOX2 TOx1
        \ /
        / \
       TOX1 TOx2
       Zeit T = 60 x h + m

     TCx1 TCx2: Aus-Zeit-Definition [0-23: 0-59 (h: m)
       TCx2 TCx1
        \ /
        / \
       TCx1 TCx2
       Zeit T = 60 x h + m

       TOx1 TOx2 / TCx1 TCx2 = FF FF = Deaktivierung / Deaktivierung der Abschaltung
       Ein- / Auszeit exp:
        F2 = 1111 0010 = 242 Zehn = 60 × 4 + 2 = 242 // Einschaltzeit [4: 2 (h: m)]
        A0 = 1010 0000 = 160 (Zehn) = (60 x 2) + 40 = 160 // AUS-Moment [2:40 (h: m)]

     TWx: Arbeitstagendefinition aktivieren
      Hi ----------------------- Lo
         b7 b6 b5 b4 b3 b2 b1 b0

      b0 = Sonntag, b1 = Woche1, b2 = Woche2, b3 = Woche3, b4 = Woche4, b5 = Woche5, b6 = Woche6, b7 = x;
      TWx = 00 (Def)

      Beispiel
        2A = 0010 1010 // Woche 1, Woche 3, Woche 5,
        0E = 0000 1110 // Woche 1, Woche 2, Woche 3,
        41 = 0100 0001 // Woche 6, Sonntag
```

Beispiel:
```
24 40 F2 00 A0 00 FF FF FF FF FF FF FF FF 2A 00 00 00 00 00
24 40 [(F2 00) (A0 00)] [(FF FF) (FF FF)] [(FF FF) (FF FF)] [2A 00 00 00 00 00]
Sitzung 1: {Geschäftstage: Montag, Woche 3, Woche 5; Pünktlich [4: 2 (h: m)]; Feierabend [2:40 (h: m)]}
  M-W-F--, 04: 02h, 02: 40h

24 40 F2 00 A0 00 36 01 FF FF FF FF FF FF 2A 0E 00 00 00 00
24 40 [(F2 00) (A0 00)] [(36 01) (FF FF)] [(FF FF) (FF FF)] [2A 0E 00 00 00 00]
Periode 1, {Geschäftstag: Montag, Woche 3, Woche 5, pünktlich [4: 2 (h: m)], Feierabend [2:40 (h: m)]}
Zeitraum 2, {Geschäftstag: Montag, 2. Woche, 3. Woche; Einschaltzeit [5:20 (h: m)];
  M-W-F-- 04: 02h 02: 40h MTW ---- 05: 10h -: -

Periode 1, Periode 2, Periode 3

Zeit 1,
Arbeitstage: Montag, Woche 2, Woche 3, Woche 4, Woche 5, Woche 6, Sonntag

Keine Verbindung herstellen
Pünktlich [0-23: 0-59 (h: m)]

Schalte nicht aus
Auszeit [0-23: 0-59 (h: m)]
```

## Analogwertüberwachung

RAM/Rem: 20/-

Darstellungsformat:
```
39 40 FD 00 92 00 C8 00 66 00 00 00 00 00 00 00 00 00 00 00
39 40 [(FD 00) (92 00)] C8 00 66 00 00 00 00 00 00 00 00 00 00 00
XX Xp [(En   ) (Ax   )] C8 00 66 00 00 00 00 00 00 00 00 00 00 00
```
  
```
Eingang En
Eingang Ax

Parameter
C8 = 1100 1000 = 200
66 = 0110 0110 = 102
```

## Definition der Funktionsblockzeit

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
  ~~~~~~~~~~~~~~~~~ = Ten5999: Hex176F
```

## Textfeld

RAM/Rem: 2/10

```
08 00 02 80 | 0800 - 0A80 | 640 | // (40x16Byte)

64 Bytes / pro Textfeld
-------------------------------------------------
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
~~ XX ~~ YY ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ZZ ~~~~~ KK
                
         0B 2B 00 00 // Block02, Parameter 1
         0B 2B 01 00 // Block02, Parameter 2
                4C 65 6E 3A // [Len:]
                43 6E 74 3A // [Cnt:]
         80 50 72 69 20 81 4E 78 74 // [↑ Pri ↓ Nxt]
XX:
  01: Nein / Nur Text
  02: Fügen Sie den Block ein
      02 04 [0B 2B 01 00
        ~~~~~~ ~~~~~~~~~~~~~
        Blockeinfügeposition Blocknummer Blockparameternummer
  03: aktuelle Uhrzeit, belegte Breite 8
  04: aktuelles Datum, Berufsbreite 10
  05: Nachrichtenaktivierungszeit, Besetzungsbreite 8
  06: Nachrichtenaktivierungsdatum, Belegungsbreite 10

JJ:
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

ZZ: Text (ACSII)-Zeichen, wenn die Zeile einen Block hat, 
  repräsentieren die ersten 4 Bytes den Block.

80 Pfeil nach oben ↑
81 Pfeil nach unten ↓
```

Beispiel:
```
03 04 20 20 20 20 00 00 00 00 00 00 00 00 00 00
02 04 0B 2B 02 00 4C 65 6E 3A 20 20 00 00 00 00
02 04 0B 2B 01 00 43 6E 74 3A 20 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00
 
01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
02 06 14 2B 00 00 54 6F 6C 4C 65 6E 00 00 00 00
02 06 17 2B 00 00 54 69 6D 65 73 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00

----

03 04 [20 20 20 20 00 00 00 00 00 00 00 00] 00 00
02 04 [0B 2B 02 00 4C 65 6E 3A 20 20 00 00] 00 00
02 04 [0B 2B 01 00 43 6E 74 3A 20 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00
 
01 00 [00 00 00 00 00 00 00 00 00 00 00 00] 00 00
02 06 [14 2B 00 00 54 6F 6C 4C 65 6E 00 00] 00 00
02 06 [17 2B 00 00 54 69 6D 65 73 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00

--------------------------------------------
01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
02 06 14 2B 00 00 54 6F 6C 4C 65 6E 00 00 00 00
02 05 17 2B 00 00 54 69 6D 65 73 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00

01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
02 00 14 2B 00 00 54 6F 6C 4C 65 6E 00 00 00 00
02 05 17 2B 00 00 54 69 6D 65 73 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00

01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
02 02 14 2B 00 00 41 20 20 5A 20 20 00 00 00 00
02 05 17 2B 00 00 54 69 6D 65 73 20 00 00 00 00
01 00 80 50 72 69 20 81 4E 78 74 20 20 20 00 00
----
01 00 [00 00 00 00 00 00 00 00 00 00 00 00] 00 00
02 06 [14 2B 00 00 54 6F 6C 4C 65 6E 00 00] 00 00
02 05 [17 2B 00 00 54 69 6D 65 73 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00

01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
02 00 [14 2B 00 00 54 6F 6C 4C 65 6E 00 00] 00 00
02 05 [17 2B 00 00 54 69 6D 65 73 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00

01 00 [00 00 00 00 00 00 00 00 00 00 00 00] 00 00
02 02 [14 2B 00 00 41 20 20 5A 20 20 00 00] 00 00 // [BLOCK] A _ _ Z
02 05 [17 2B 00 00 54 69 6D 65 73 20 00 00] 00 00
01 00 [80 50 72 69 20 81 4E 78 74 20 20 20] 00 00

03 04 [20 20 20 20 00 00 00 00 00 00 00 00] 00 00 // die aktuelle Uhrzeit
04 00 [20 BA 00 00 00 00 00 00 00 00 00 00] 00 00 // Das aktuelle Datum
05 00 [00 00 00 00 00 00 00 00 20 20 20 9F] 00 00 // Nachrichtenfreigabezeit
06 00 [00 00 00 00 00 00 00 00 00 00 20 8F] 00 00 // Meldungsaktivierungsdatum
```

## Speicherbereich 0C 00
Rolle:
Verweis auf Ein-/Ausgänge und Merker.

Länge:
20 Bytes

Die ersten 20 Bytes sind fest und verweisen auf die 0E20 - 0EE8 20-Byte-Grenzen, die jeweils als 16 Bit-Zeiger dargestellt sind.
```
40 = 2 * 20
60 = 3 * 20
20 = 1 * 20
40 = 2 * 20
40 = 2 * 20

2+3+1+2+2 = 10*16bit Zeiger
```

Bereich     | Anz | Zeiger            | Beschreibung
------------|-----|-------------------|------------------
0E20 - 0E48 | 40  | 0000, 0014        | Digitaler Ausgang 16
0E48 - 0E84 | 60  | 0028, 003C, 0050  | Merker 24
0E84 - 0E98 | 20  | 0064              | Analogausgang 2
0E98 - 0EC0 | 40  | 0078, 008C        | offener Ausgang 16
0EC0 - 0EE8 | 40  | 00A0, 00B4        | 

Befehl:
```
05 0C 00 00 14
```

Ausgabe:
```
          |<----------------------- 20 Bytes ----------------------->|
HEX MSB:  00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
HEX LSB:  00 00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4
Decimal:  00    20    40    60    80    100   120   140   160   180
Delta:       20    20    20    20    20    20    20    20    20
```

## Speicherbereich 0C 14
Rolle:
Zeiger auf den Funktionsblock im Programmspeicherbereich. 

Länge:
260 Bytes. 0BA5 hat maximal 130 Blöcke und ein Funktionsblock belegt 2 Bytes: 260/2 = 130.

Beschreibung: 
Jeweils 16bit Zeiger (ungleich FFFFh) zeigt auf ein Funktionsblock im Programmspeicher. 
   
Befehl:
```
05 0C 14 01 04
```

Ausgabe mit gelöschten Programm
```
00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
|<----------------------- 20 Bytes ----------------------->|
FF FF FF FF FF FF FF FF FF FF FF
```

Beispiel 1: REM = 3, Ausschaltverzögerung
```
00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
|<----------------------- 20 Bytes ----------------------->|
C8 00 FF FF FF FF FF FF FF FF FF FF
```

Der erste Funktionsblock liegt im Programmspeicher 0EE8 - 0E20 = 00C8

Beispiel 1: Programm "Wickelmaschine"
```
00 00 14 00 28 00 3C 00 50 00 64 00 78 00 8C 00 A0 00 B4 00
|<----------------------- 20 Bytes ----------------------->|
C8 00 D0 00 E8 00 F4 00 00 01 08 01 14 01 1C 01 28 01 30 01
3C 01 54 01 60 01 6C 01 84 01 FF FF FF FF
```

```
HEX MSB:  C8 00 D0 00 E8 00 F4 00 00 01 08 01 14 01 1C 01 28 01 30 01
          3C 01 54 01 60 01 6C 01 84 01 FF FF
HEX LSB:  00 C8 00 D0 00 E8 00 F4 01 00 01 08 01 14 01 1C 01 28 01 30
          01 3C 01 54 01 60 01 6C 01 84
Dezimal:  200   208   232   244   256   264   276   284   296   304
          316   340   352   364   388
Delta:       8     24    12    12    8     12    8     12    8     12
             24    12    12    24
```

## Zeit/Datum oder Eingabe/Ausgabe

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

  
## Version und Firmware 
   
Chip:
```
/ ----------------- \
| O                 |
| LOGO              |
| V2.0.2            |
| 721533            |
| 0650EP004         |
|
\ ----------------- /
```

Read Byte | Wert
----------|-----
1F02      | 42
1F00      | 04
1F01      | 00
48FF      | 00

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

## Speicherbereich 1E 00

```
02 1E 00
02 1E 01
02 1E 02
02 1D 03
02 1E 04
02 1E 05
02 1E 06
02 1D 07
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


# Anmerkungen zu 0BA6

| Beispiel    | Adresse     | Länge |   |                                      |
| ------------|-------------|-------|---|--------------------------------------|
| 0C 00 01 A4 | 0C00 - 0DA4 | 420   |   | Anzahl der Blöcke 200 / REM 250      |
| 0E E8 0E D8 | 0EE8 - 1DC0 | 3800  |   | Programmspeicherbereich 1DC0h = 7616 |
