-- ============================================
-- Seed Data for Arduino Morse Code Course
-- ============================================

-- Insert Course (if not exists)
INSERT INTO courses (title, description, language)
SELECT 'Arduino Morse-kode Blinker', 'Lær å programmere en Arduino til å blinke innebygd LED i Morse-kode basert på tekst sendt via Serial Monitor.', 'arduino'
WHERE NOT EXISTS (SELECT 1 FROM courses WHERE title = 'Arduino Morse-kode Blinker');

-- Insert Modules for Course 2
INSERT INTO modules (course_id, title, description, content, documentation_links, order_num) VALUES
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Variabler, Timing og Oppsett', 'Før vi blinker, må vi definere hvordan. Lær om variabler for å holde styr på LED-pinnen og de ulike tidene i Morse-koden. En prikk (`dotTime`) er satt til 200ms. En strek (`dashTime`) er 3 ganger så lang som en prikk, og pausen mellom signaler i samme bokstav (`pauseTime`) er like lang som en prikk. Definer konstanter for `ledPin`, `dotTime`, `dashTime`, og `pauseTime`. **Erstatt plassholderverdien 0 med riktig utregning for `dashTime` og `pauseTime`**. Sett opp LED-pinnen som utgang og initialiser seriell kommunikasjon.',
'// Definerer pin for LED
const int ledPin = 13;  // Innebygd LED

// Tidsenheter for Morse-kode i millisekunder
const int dotTime = 200;    // Lengde på en prikk
const int dashTime = 0;   // FYLL INN: Strek = 3x prikk
const int pauseTime = 0;  // FYLL INN: Pause mellom signaler = 1x prikk
// Vi definerer flere pauser senere

void setup() {
  // TODO: Initialiser LED-pin som OUTPUT med pinMode()
  // TODO: Start Serial kommunikasjon med 9600 baud
  // TODO: Vent på at Serial er klar (for noen kort)
  // TODO: Skriv ut "Morse Kode Oppsett Klar!" til Serial Monitor
  // TODO: Skriv ut de definerte tidene (dotTime, dashTime, pauseTime) til Serial Monitor
}

void loop() {
  // Foreløpig tom
}',
'[{"title": "Arduino const", "url": "https://www.arduino.cc/reference/en/language/variables/variable-scope-qualifiers/const/"}, {"title": "Arduino int", "url": "https://www.arduino.cc/reference/en/language/variables/data-types/int/"}, {"title": "Arduino pinMode()", "url": "https://www.arduino.cc/reference/en/language/functions/digital-io/pinmode/"}, {"title": "Arduino Serial.begin()", "url": "https://www.arduino.cc/reference/en/language/functions/communication/serial/begin/"}, {"title": "Arduino Serial.println()", "url": "https://www.arduino.cc/reference/en/language/functions/communication/serial/println/"}, {"title": "Morse Code Timing", "url": "https://morsecode.world/international/timing.html"}]',
1),
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Grunnleggende Blinking i Loop', 'Nå skal vi få LED-en til å blinke kontinuerlig i `loop()`-funksjonen. Bruk `digitalWrite()` og `delay()` sammen med tidskonstantene du definerte for å blinke et mønster: én prikk, etterfulgt av én strek, med riktige pauser mellom signalene. Legg også inn en lengre pause (f.eks. 1 sekund) på slutten av `loop()` for å skille repetisjonene.',
'// ... (Konstanter og setup() fra Modul 1) ...

void loop() {
  // TODO: Skriv kode for å blinke en prikk manuelt
  // Hint: PÅ -> delay(dotTime) -> AV -> delay(pauseTime)
  // digitalWrite(...);
  // delay(...);
  // digitalWrite(...);
  // delay(...);

  // TODO: Skriv kode for å blinke en strek manuelt
  // Hint: PÅ -> delay(dashTime) -> AV -> delay(pauseTime)
  // digitalWrite(...);
  // delay(...);
  // digitalWrite(...);
  // delay(...);

  // TODO: Legg til en lengre pause (f.eks. 1000ms) her
  // delay(...);
}',
'[{"title": "Arduino digitalWrite()", "url": "https://www.arduino.cc/reference/en/language/functions/digital-io/digitalwrite/"}, {"title": "Arduino delay()", "url": "https://www.arduino.cc/reference/en/language/functions/time/delay/"}, {"title": "Arduino HIGH/LOW", "url": "https://www.arduino.cc/reference/en/language/variables/constants/constants/"}, {"title": "Arduino loop()", "url": "https://www.arduino.cc/reference/en/language/structure/sketch/loop/"}]',
2),
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Funksjoner for Prikk og Strek', 'Å skrive blinke-logikken manuelt i `loop()` blir fort rotete. La oss lage egne funksjoner for å gjøre koden mer organisert. Definer to nye funksjoner: `blinkDot()` og `blinkDash()`. Flytt blinke-logikken for henholdsvis prikk og strek fra `loop()` inn i disse nye funksjonene. Husk å legge til funksjonsprototyper øverst i koden. Til slutt, endre `loop()` til å *kalle* `blinkDot()` og `blinkDash()` i stedet for å inneholde blinke-logikken direkte.',
'// ... (Konstanter fra Modul 1) ...

// TODO: Legg til funksjonsprototyper for blinkDot og blinkDash her
// void ...();
// void ...();

void setup() {
  // ... (setup() fra Modul 1) ...
}

void loop() {
  // TODO: Kall blinkDot() her
  // TODO: Kall blinkDash() her

  delay(1000); // Pause mellom repetisjoner
}

// TODO: Definer funksjonen blinkDot() her
void blinkDot() {
  // TODO: Implementer logikken for prikk-blinking (PÅ -> delay -> AV -> delay)
}

// TODO: Definer funksjonen blinkDash() her
void blinkDash() {
  // TODO: Implementer logikken for strek-blinking (PÅ -> delay -> AV -> delay)
}',
'[{"title": "Arduino Functions", "url": "https://www.arduino.cc/reference/en/language/structure/functions/"}, {"title": "Function Prototypes", "url": "https://www.arduino.cc/reference/en/language/structure/functions/"}]',
3),
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Morse-kode for Én Bokstav (`blinkCharacter`)', 'Nå begynner vi på selve Morse-oversettelsen! Først, definer nye konstanter for pausene *mellom* bokstaver (`letterPause`, 3x `dotTime`) og *mellom* ord (`wordPause`, 7x `dotTime`). Deretter, lag en ny funksjon `blinkCharacter(char c)` som tar inn en bokstav som parameter. Inne i funksjonen, konverter bokstaven til små bokstaver med `toLowerCase()`. Bruk en `switch`-statement til å håndtere ulike bokstaver. Implementer logikken for ''s'' (tre prikker), ''o'' (tre streker) og mellomrom ('' ''). Husk å legge til riktig pause (`letterPause`) på slutten av funksjonen (justert for `pauseTime`). Test ved å kalle `blinkCharacter()` fra `loop()` med ''s'', ''o'', ''s'', og '' ''.',
'// ... (Konstanter og funksjoner fra Modul 3) ...

// TODO: Definer const int letterPause (3 * dotTime)
// TODO: Definer const int wordPause (7 * dotTime)

// TODO: Legg til funksjonsprototypen for blinkCharacter(char c)

void setup() {
  // ... (setup() fra Modul 1) ...
}

void loop() {
  // TODO: Test ved å kalle blinkCharacter() for ''s'', ''o'', ''s'', '' ''
  // blinkCharacter(''s'');
  // ...
  delay(2000); // Pause mellom test-sekvenser
}

// ... (blinkDot, blinkDash som før) ...

// TODO: Definer funksjonen blinkCharacter(char c) her
void blinkCharacter(char c) {
  // TODO: Konverter c til små bokstaver

  // Serial.print("Blinker: "); Serial.println(c); // Kan være nyttig for debugging

  switch (c) {
    // TODO: Legg til case for ''s'' (3 prikker)
    // case ''s'': ... break;
    // TODO: Legg til case for ''o'' (3 streker)
    // case ''o'': ... break;
    // TODO: Legg til case for '' '' (mellomrom) - husk å justere pausen!
    // case '' '': ... break;
    default:
      return; // Ignorer andre tegn
  }
  // TODO: Legg til pause mellom bokstaver (husk å justere!)
  // delay(...);
}',
'[{"title": "Arduino switch...case", "url": "https://www.arduino.cc/reference/en/language/structure/control-structure/switchcase/"}, {"title": "Arduino char", "url": "https://www.arduino.cc/reference/en/language/variables/data-types/char/"}, {"title": "Arduino toLowerCase()", "url": "https://www.arduino.cc/reference/en/language/variables/data-types/string/functions/tolowercase/"}]',
4),
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Morse-kode for Hele Alfabetet', 'Nå skal `blinkCharacter`-funksjonen utvides til å håndtere hele alfabetet (a-z). Fyll inn `case`-blokkene for hver bokstav i `switch`-statementen ved å kalle `blinkDot()` og `blinkDash()` i riktig rekkefølge. Bruk en Morse-kode tabell som referanse.',
'// ... (blinkCharacter funksjonen fra Modul 4, men med tom switch) ...
void blinkCharacter(char c) {
  c = toLowerCase(c);
  // Serial.print("Blinker: "); Serial.println(c);

  switch (c) {
    // TODO: Legg til case for ''a'' til ''z'' her
    // Eksempel: case ''a'': blinkDot(); blinkDash(); break;

    case '' '':
      delay(wordPause - pauseTime); // Justert pause for mellomrom
      break;
    default:
      return; // Ignorer ukjente tegn
  }
  delay(letterPause - pauseTime); // Justert pause etter bokstav
}',
'[{"title": "International Morse Code", "url": "https://en.wikipedia.org/wiki/Morse_code#Letters,_numbers,_punctuation,_prosigns_for_Morse_code_and_non-English_variants"}]',
5),
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Blinke en Hel Streng (`blinkString`)', 'Vi kan nå blinke én bokstav. La oss lage en funksjon som kan blinke en hel tekststreng! Definer funksjonen `blinkString(String text)`. Bruk en `for`-løkke til å gå gjennom hvert tegn i `text`-strengen (fra indeks 0 til `text.length() - 1`). Inne i løkken, kall `blinkCharacter()` med det aktuelle tegnet (`text[i]`). Husk prototypen! Test funksjonen ved å kalle den fra `setup()` med en test-streng som "hallo".',
'// ... (Konstanter, prototyper og funksjoner fra før) ...

// TODO: Legg til funksjonsprototypen for blinkString(String text)

void setup() {
  // ... (setup() fra Modul 1) ...
  // TODO: Test blinkString() her med f.eks. "hallo"
}

void loop() {
  // Tom
}

// ... (blinkDot, blinkDash, blinkCharacter som før) ...

// TODO: Definer funksjonen blinkString(String text) her
void blinkString(String text) {
  // Serial.print("Blinker streng: "); Serial.println(text); // Debugging

  // TODO: Lag en for-løkke som går fra 0 til lengden av ''text'' - 1
  // for (...) {
  //   TODO: Kall blinkCharacter() med tegnet på nåværende posisjon i løkken
  //   blinkCharacter(text[i]); // Hint
  // }

  // Serial.println("Streng ferdig blinket."); // Debugging
}',
'[{"title": "Arduino String object", "url": "https://www.arduino.cc/reference/en/language/variables/data-types/stringobject/"}, {"title": "Arduino for loop", "url": "https://www.arduino.cc/reference/en/language/structure/control-structure/for/"}, {"title": "String length()", "url": "https://www.arduino.cc/reference/en/language/variables/data-types/string/functions/length/"}, {"title": "String character access []", "url": "https://www.arduino.cc/reference/en/language/variables/data-types/string/functions/charat/"}]',
6),
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Lese Input fra Serial Monitor', 'Gjør programmet interaktivt! Endre `loop()`-funksjonen. Bruk `Serial.available()` til å sjekke om brukeren har skrevet noe i Serial Monitor og trykket Enter. Hvis ja, bruk `Serial.readStringUntil(''\\n'')` til å lese inn teksten i en `String`-variabel. Bruk `trim()` på variabelen for å fjerne unødvendige mellomrom. Skriv ut den mottatte teksten til Serial Monitor med `Serial.print()` for å bekrefte at lesingen fungerer. Fjern test-kallet til `blinkString()` fra `setup()`.',
'// ... (Konstanter, prototyper og funksjoner fra før) ...

void setup() {
  // ... (setup() fra Modul 1) ...
  // TODO: Fjern eventuell test-kode fra setup()
  Serial.println("Skriv inn en setning og trykk Enter..."); // Instruksjon
}

void loop() {
  // TODO: Sjekk om Serial.available() > 0
  if (/* Betingelse her */) {
    // TODO: Les strengen med Serial.readStringUntil(''\\n'') inn i en variabel ''input''
    // String input = ... ;
    // TODO: Bruk input.trim()
    // input... ;

    // TODO: Skriv ut "Mottok: " og verdien av input til Serial Monitor
    // Serial.print(...);
    // Serial.println(...);
  }
}

// ... (resten av funksjonene) ...',
'[{"title": "Arduino Serial.available()", "url": "https://www.arduino.cc/reference/en/language/functions/communication/serial/available/"}, {"title": "Arduino Serial.readStringUntil()", "url": "https://www.arduino.cc/reference/en/language/functions/communication/serial/readstringuntil/"}, {"title": "String trim()", "url": "https://www.arduino.cc/reference/en/language/variables/data-types/string/functions/trim/"}]',
7),
((SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker'), 'Sette Alt Sammen', 'Siste steg! Nå skal vi koble sammen input-lesingen med blinkingen. Inne i `if (Serial.available() > 0)`-blokken i `loop()`, *etter* at du har lest og skrevet ut input, legg til et kall til `blinkString()` med input-variabelen som argument. Legg også til en `Serial.println()` *etter* `blinkString()`-kallet som bekrefter at setningen er ferdig blinket.',
'// ... (Konstanter, prototyper og funksjoner fra før) ...

void setup() {
  // ... (setup() fra Modul 7) ...
}

void loop() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil(''\\n'');
    input.trim();
    Serial.print("Mottok: ");
    Serial.println(input);

    // TODO: Kall blinkString() med input her

    // TODO: Skriv ut bekreftelse ("Setning blinket ferdig: ...") her
  }
}

// ... (resten av funksjonene) ...',
'[]', -- Ingen nye funksjoner
8);

-- Insert Hints for Course 2 Modules using subqueries
-- Module 1 (Order 1)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 1), 'Bruk `const int` for verdier som ikke skal endres.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 1), '`pinMode(ledPin, OUTPUT);` i `setup()` gjør at vi kan kontrollere LED-en.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 1), 'Morse-kode timing er relativ: en strek er 3 prikker lang, pausen mellom signaler i en bokstav er 1 prikk lang.', 3);
-- No hint 4 for module 1

-- Module 2 (Order 2)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 2), 'Koden i `loop()` kjører om og om igjen.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 2), 'For å blinke en prikk: Skru PÅ, vent `dotTime`, skru AV, vent `pauseTime`.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 2), 'For å blinke en strek: Skru PÅ, vent `dashTime`, skru AV, vent `pauseTime`.', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 2), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-arduino">// Definerer pin for LED\nconst int ledPin = 13;  // Innebygd LED\n\n// Tidsenheter for Morse-kode i millisekunder\nconst int dotTime = 200;    // Lengde på en prikk\nconst int dashTime = 600;   // Strek = 3x prikk\nconst int pauseTime = 200;  // Pause mellom signaler = 1x prikk\n\nvoid setup() {\n  // Initialiserer LED-pin som utgang\n  pinMode(ledPin, OUTPUT);\n\n  // Starter seriell kommunikasjon\n  Serial.begin(9600);\n  while (!Serial) { ; } // Vent på seriell port\n  Serial.println("Morse Kode Oppsett Klar!");\n  Serial.println("Definerte tider (ms):");\n  Serial.print("Prikk: "); Serial.println(dotTime);\n  Serial.print("Strek: "); Serial.println(dashTime);\n  Serial.print("Signalpause: "); Serial.println(pauseTime);\n}\n\nvoid loop() {\n  // Foreløpig tom\n}</code></pre>', 4);

-- Module 3 (Order 3)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 3), 'Lag funksjonene `void blinkDot() { ... }` og `void blinkDash() { ... }`.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 3), 'Flytt den manuelle blinke-logikken fra `loop()` inn i de respektive funksjonene.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 3), 'Husk å legge til prototypene `void blinkDot();` og `void blinkDash();` før `setup()`.', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 3), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-arduino">// ... (Konstanter fra Modul 1) ...\n\nvoid setup() {\n  // ... (setup() fra Modul 1) ...\n}\n\nvoid loop() {\n  // Blink en prikk manuelt\n  digitalWrite(ledPin, HIGH); // PÅ\n  delay(dotTime);             // Vent prikk-tid\n  digitalWrite(ledPin, LOW);  // AV\n  delay(pauseTime);           // Vent signalpause-tid\n\n  // Blink en strek manuelt\n  digitalWrite(ledPin, HIGH); // PÅ\n  delay(dashTime);            // Vent strek-tid\n  digitalWrite(ledPin, LOW);  // AV\n  delay(pauseTime);           // Vent signalpause-tid\n\n  // Legg til en lengre pause for å skille repetisjoner tydelig\n  delay(1000);\n}</code></pre>', 4);

-- Module 4 (Order 4)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 4), 'Funksjonen må ta imot en `char` (character) som input parameter.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 4), 'Bruk `toLowerCase(c)` for å sikre at både ''S'' og ''s'' gir samme resultat.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 4), 'En `switch(c)` lar deg sjekke verdien av `c` mot ulike `case ''bokstav'':`-blokker. Husk `break;`.', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 4), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-arduino">// ... (Konstanter fra Modul 1) ...\n\n// Prototyper for funksjoner\nvoid blinkDot();\nvoid blinkDash();\n\nvoid setup() {\n  // ... (setup() fra Modul 1) ...\n}\n\nvoid loop() {\n  // Kall funksjonene\n  blinkDot();\n  blinkDash();\n\n  // Legg til en lengre pause for å skille repetisjoner\n  delay(1000);\n}\n\n// Funksjon for å blinke en prikk\nvoid blinkDot() {\n  digitalWrite(ledPin, HIGH);\n  delay(dotTime);\n  digitalWrite(ledPin, LOW);\n  delay(pauseTime);\n}\n\n// Funksjon for å blinke en strek\nvoid blinkDash() {\n  digitalWrite(ledPin, HIGH);\n  delay(dashTime);\n  digitalWrite(ledPin, LOW);\n  delay(pauseTime);\n}</code></pre>', 4);

-- Module 5 (Order 5)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 5), 'Søk etter "Morse Code Alphabet" for å finne prikk/strek-kombinasjonene.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 5), 'Vær systematisk når du legger inn hver `case ''bokstav'': ... break;`.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 5), 'Dobbeltsjekk koden for noen vanlige bokstaver (som E, T, A, N).', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 5), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-arduino">// ... (Konstanter og prototyper fra Modul 4) ...\n\nvoid setup() {\n  // ... (setup() fra Modul 1) ...\n}\n\nvoid loop() {\n  // Test blinkCharacter (midlertidig)\n  blinkCharacter(''s'');\n  blinkCharacter(''o'');\n  blinkCharacter(''s'');\n  blinkCharacter('' ''); // Test mellomrom\n  delay(2000); // Lengre pause\n}\n\n// ... (blinkDot, blinkDash som før) ...\n\n// Funksjon for å blinke en enkelt bokstav i Morse-kode\nvoid blinkCharacter(char c) {\n  c = toLowerCase(c);\n  Serial.print("Blinker: "); Serial.println(c);\n  switch (c) {\n    case ''s'': blinkDot(); blinkDot(); blinkDot(); break;\n    case ''o'': blinkDash(); blinkDash(); blinkDash(); break;\n    case '' '': delay(wordPause - pauseTime); break;\n    default: return;\n  }\n  delay(letterPause - pauseTime);\n}</code></pre>', 4);

-- Module 6 (Order 6)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 6), 'Funksjonen må ta en `String` (med stor S) som parameter.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 6), 'En `for`-løkke kan iterere fra `int i = 0` til `i < text.length()`.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 6), 'Inne i løkken, kall `blinkCharacter(text[i])` for å blinke tegnet på posisjon `i`.', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 6), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-arduino">// ... (Konstanter og prototyper fra Modul 4) ...\n\nvoid setup() {\n  // ... (setup() fra Modul 1) ...\n}\n\nvoid loop() {\n  // Test blinkCharacter (midlertidig)\n  blinkCharacter(''s'');\n  blinkCharacter(''o'');\n  blinkCharacter(''s'');\n  blinkCharacter('' ''); // Test mellomrom\n  delay(2000); // Lengre pause\n}\n\n// ... (blinkDot, blinkDash som før) ...\n\n// Funksjon for å blinke en enkelt bokstav i Morse-kode\nvoid blinkCharacter(char c) {\n  c = toLowerCase(c);\n  Serial.print("Blinker: "); Serial.println(c);\n  switch (c) {\n    case ''a'': blinkDot(); blinkDash(); break;\n    case ''b'': blinkDash(); blinkDot(); blinkDot(); blinkDot(); break;\n    case ''c'': blinkDash(); blinkDot(); blinkDash(); blinkDot(); break;\n    case ''d'': blinkDash(); blinkDot(); blinkDot(); break;\n    case ''e'': blinkDot(); break;\n    case ''f'': blinkDot(); blinkDot(); blinkDash(); blinkDot(); break;\n    case ''g'': blinkDash(); blinkDash(); blinkDot(); break;\n    case ''h'': blinkDot(); blinkDot(); blinkDot(); blinkDot(); break;\n    case ''i'': blinkDot(); blinkDot(); break;\n    case ''j'': blinkDot(); blinkDash(); blinkDash(); blinkDash(); break;\n    case ''k'': blinkDash(); blinkDot(); blinkDash(); break;\n    case ''l'': blinkDot(); blinkDash(); blinkDot(); blinkDot(); break;\n    case ''m'': blinkDash(); blinkDash(); break;\n    case ''n'': blinkDash(); blinkDot(); break;\n    case ''o'': blinkDash(); blinkDash(); blinkDash(); break;\n    case ''p'': blinkDot(); blinkDash(); blinkDash(); blinkDot(); break;\n    case ''q'': blinkDash(); blinkDash(); blinkDot(); blinkDash(); break;\n    case ''r'': blinkDot(); blinkDash(); blinkDot(); break;\n    case ''s'': blinkDot(); blinkDot(); blinkDot(); break;\n    case ''t'': blinkDash(); break;\n    case ''u'': blinkDot(); blinkDot(); blinkDash(); break;\n    case ''v'': blinkDot(); blinkDot(); blinkDot(); blinkDash(); break;\n    case ''w'': blinkDot(); blinkDash(); blinkDash(); break;\n    case ''x'': blinkDash(); blinkDot(); blinkDot(); blinkDash(); break;\n    case ''y'': blinkDash(); blinkDot(); blinkDash(); blinkDash(); break;\n    case ''z'': blinkDash(); blinkDash(); blinkDot(); blinkDot(); break;\n    case '' '': delay(wordPause - pauseTime); break;\n    default: return;\n  }\n  delay(letterPause - pauseTime);\n}</code></pre>', 4);

-- Module 7 (Order 7)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 7), '`Serial.available() > 0` er sann hvis det er data som venter på å bli lest.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 7), '`Serial.readStringUntil(''\\n'')` leser tegn helt til den finner et linjeskift-tegn.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 7), '`input.trim()` er nyttig for å fjerne usynlige tegn før eller etter teksten.', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 7), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-arduino">// ... (Konstanter og prototyper fra Modul 6) ...\n\nvoid setup() {\n  // ... (setup() fra Modul 1) ...\n  blinkString("sos"); // Test\n}\n\nvoid loop() {\n  // Tom\n}\n\n// ... (blinkDot, blinkDash, blinkCharacter som før) ...\n\n// Funksjon for å blinke en hel streng\nvoid blinkString(String text) {\n  Serial.print("Blinker streng: "); Serial.println(text);\n  for (int i = 0; i < text.length(); i++) {\n    blinkCharacter(text[i]);\n  }\n  Serial.println("Streng ferdig blinket.");\n}</code></pre>', 4);

-- Module 8 (Order 8)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 8), 'Kallet til `blinkString()` skal bruke variabelen `input` som argument.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 8), 'Bruk `Serial.println()` for å skrive ut bekreftelsen.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 8), 'Last opp koden og test ved å skrive inn tekst i Serial Monitor og trykke Enter!', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 8), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-arduino">// ... (Konstanter og prototyper fra Modul 6) ...\n\nvoid setup() {\n  Serial.begin(9600);\n  while (!Serial) { ; }\n  pinMode(ledPin, OUTPUT);\n  Serial.println("Morse Kode Blinker Klar!");\n  Serial.println("Skriv inn en setning og trykk Enter...");\n}\n\nvoid loop() {\n  if (Serial.available() > 0) {\n    String input = Serial.readStringUntil(''\\n'');\n    input.trim();\n    Serial.print("Mottok: ");\n    Serial.println(input);\n    // blinkString(input); // Kommer her\n  }\n}\n\n// ... (blinkDot, blinkDash, blinkCharacter, blinkString som før) ...\n</code></pre>', 4);