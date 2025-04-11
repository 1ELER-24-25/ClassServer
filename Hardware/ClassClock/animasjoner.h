#ifndef ANIMASJONER_H
#define ANIMASJONER_H

#include <Adafruit_NeoPixel.h>

//************************************************************
//************          TIMEANIMASJON    ********************
//************************************************************

void blink() {
   for (int blink = 0; blink < 5; blink++) {
  for (int i = 0; i < NUMPIXELS; i++) {
    if (blink % 3 == 0) {
      strip.setPixelColor(i, 130, 0, 0); 
    } else if (blink % 3 == 1) {
      strip.setPixelColor(i, 130, 0, 0); 
    } else {
      strip.setPixelColor(i, 130, 0, 0); 
    }
  }
  strip.show();
  delay(50);
  strip.clear();
  strip.show();
  delay(50);
 }
}

// Kode fra animasjon for slutten av dagen
void alarm(uint32_t c, uint8_t wait) {
  for (int j=0; j<6; j++) {  
    for (int q=0; q < 7; q++) {
      for (uint16_t i=0; i < strip.numPixels(); i+=7) {
        strip.setPixelColor(i+q, c);    
      }
      strip.show();
      delay(wait);
      for (uint16_t i=0; i < strip.numPixels(); i+=7) {
        strip.setPixelColor(i+q, 0);    
      }
    }
  }
}

//************************************************************
//************   ANIMASJON FOR FRIMINUTT  ********************
//************************************************************

// Funksjon for å kjøre en pulserende lys-effekt
void friminuttAnimasjon() {
  Serial.println("Starter friminutt animasjon");

  int center = NUMPIXELS / 2;                  // Finn midtpunktet av NeoPixel-stripen
  
  // Farger for de ulike effektene, fordelt for variasjon
  uint32_t color1 = strip.Color(255, 0, 0);    // Rød
  uint32_t color2 = strip.Color(0, 0, 255);    // Blå
  uint32_t color4 = strip.Color(255, 255, 0);  // Gul
  uint32_t color5 = strip.Color(255, 165, 0);  // Oransje
  uint32_t color6 = strip.Color(255, 20, 147); // Rosa

  // Del 1: Roterende regnbueeffekt fra midten ut til kantene
  for (int spread = 0; spread < NUMPIXELS / 2; spread++) {
    for (int i = 0; i <= spread; i++) {
      strip.setPixelColor(center - i, color1); // Fyll fra midten til venstre
      strip.setPixelColor(center + i, color2); // Fyll fra midten til høyre
    }
    strip.show(); delay(20);
    color1 = strip.Color(random(255), random(255), random(255)); // Endre farge for variert effekt
    color2 = strip.Color(random(255), random(255), random(255));
  }

  for (int blink = 0; blink < 5; blink++) {
  for (int i = 0; i < NUMPIXELS; i++) {
    // Veksle mellom gul, oransje og rosa i et blinkemønster
    if (blink % 3 == 0) {
      strip.setPixelColor(i, color4); // Gul hver tredje blink
    } else if (blink % 3 == 1) {
      strip.setPixelColor(i, color5); // Oransje
    } else {
      strip.setPixelColor(i, color6); // Rosa
    }
  }
  strip.show();
  delay(50);
  strip.clear();
  strip.show();
  delay(50);
 }

  // Del 3: Bølgeeffekt som beveger seg langs stripen med fargene gul, rosa og oransje
 for (int wave = 0; wave < NUMPIXELS / 3; wave++) {  // Forkortet bølgelengde
  for (int i = 0; i < NUMPIXELS; i++) {
    // Bestem fargen basert på bølgeposisjonen for en levende overgang
    if ((i + wave) % 3 == 0) {
      strip.setPixelColor(i, strip.Color(255, 255, 0)); // Gul
    } else if ((i + wave) % 3 == 1) {
      strip.setPixelColor(i, strip.Color(255, 20, 147)); // Rosa
    } else {
      strip.setPixelColor(i, strip.Color(255, 165, 0)); // Oransje
    }
  }
  strip.show();
  delay(40); // Økt delay for å korte ned på total varighet
 }


  // Del 4: Fargebølge som beveger seg rundt stripen med oransje og rosa
  for (int wave = 0; wave < 10; wave++) {
    for (int i = 0; i < NUMPIXELS; i++) {
      strip.setPixelColor(i, (i + wave) % 4 == 0 ? color4 : color5); // Veksle mellom oransje og rosa
    }
    strip.show();
    delay(50);
  }

  // Del 5: Fading til av med alle farger
  for (int brightness = 255; brightness >= 0; brightness -= 12) {
    for (int i = 0; i < NUMPIXELS; i++) {
      uint32_t currentColor = strip.getPixelColor(i);
      uint8_t r = (currentColor >> 16) & 0xFF;
      uint8_t g = (currentColor >> 8) & 0xFF;
      uint8_t b = currentColor & 0xFF;
      strip.setPixelColor(i, strip.Color(r * brightness / 255, g * brightness / 255, b * brightness / 255));
    }
    strip.show();
    delay(20);
  }

  strip.clear();
  strip.show(); // Slå av alle lysene til slutt
}

//************************************************************
//************ ANIMASJON FERDIG FOR DAGEN ********************
//************************************************************

void ring(uint32_t farge, uint8_t delayTid) {
  for(int i=0; i<NUMPIXELS; i++) { 
    strip.setPixelColor(i, farge);
    strip.show(); 
    delay(delayTid); 
  } 
}

void runde(uint32_t c, uint8_t wait) {
  for (int j=0; j<6; j++) {  
    for (int q=0; q < 11; q++) {
      for (uint16_t i=0; i < strip.numPixels(); i+=11) {
        strip.setPixelColor(i+q, c);    
      }
      strip.show();
      delay(wait);
      for (uint16_t i=0; i < strip.numPixels(); i+=11) {
        strip.setPixelColor(i+q, 0);    
      }
    }
  }
}

void skruAv() {
  for(int i=0; i<NUMPIXELS; i++) {
    strip.setPixelColor(i, 0); 
  }
  strip.show(); 
}

//************************************************************
//************          HELGEANIMASJON    ********************
//************************************************************

void HelgAnimasjon() {
  const int NUM_BALLS = 2;            // To baller som kolliderer
  const int NUM_STARS = 6;            // Flere ninja-stjerner
  int delayTime = 10;                 // Forsinkelse for animasjonshastighet
  unsigned long startTime = millis(); // Starttid for tidsbegrensning

  // Regnbuebølge
for (int cycle = 0; cycle < 3; cycle++) {
    // Fade fra blå til hvit på første halvdel, hvit til blå på andre halvdel
    for (int brightness = 0; brightness < 255; brightness += 5) {
      for (int i = 0; i < NUMPIXELS; i++) {
        if (i < NUMPIXELS/2) {
          // Første halvdel: fade fra blå til hvit
          strip.setPixelColor(i, strip.Color(brightness, brightness, 255));
        } else {
          // Andre halvdel: fade fra hvit til blå
          strip.setPixelColor(i, strip.Color(255-brightness, 255-brightness, 255));
        }
      }
      strip.show();
      delay(10);
    }
    
    // Fade tilbake
    for (int brightness = 255; brightness >= 0; brightness -= 5) {
      for (int i = 0; i < NUMPIXELS; i++) {
        if (i < NUMPIXELS/2) {
          // Første halvdel: fade fra hvit til blå
          strip.setPixelColor(i, strip.Color(brightness, brightness, 255));
        } else {
          // Andre halvdel: fade fra blå til hvit
          strip.setPixelColor(i, strip.Color(255-brightness, 255-brightness, 255));
        }
      }
      strip.show();
      delay(10);
    }
    
    // Alternerende fade-effekt
    for (int j = 0; j < 2; j++) {
      // Fade inn annenhver LED
      for (int brightness = 0; brightness < 255; brightness += 5) {
        for (int i = 0; i < NUMPIXELS; i++) {
          if (i % 2 == j) {
            // Fade til hvit
            strip.setPixelColor(i, strip.Color(255, 255, brightness));
          } else {
            // Hold blå
            strip.setPixelColor(i, strip.Color(0, 0, 255));
          }
        }
        strip.show();
        delay(10);
      }
      
      // Fade ut annenhver LED
      for (int brightness = 255; brightness >= 0; brightness -= 5) {
        for (int i = 0; i < NUMPIXELS; i++) {
          if (i % 2 == j) {
            // Fade til blå
            strip.setPixelColor(i, strip.Color(0, 0, brightness));
          } else {
            // Hold blå
            strip.setPixelColor(i, strip.Color(0, 0, 255));
          }
        }
        strip.show();
        delay(10);
      }
    }
  }

  // Bouncing ball-animasjon med haleeffekt
  float positions[NUM_BALLS] = {0, NUMPIXELS - 1};  // Startposisjon for hver ball
  float velocities[NUM_BALLS] = {0.5, -0.5};        // Ballene starter mot hverandre
  int colors[NUM_BALLS][3];                         // RGB-farge for hver ball
  int trails[NUM_BALLS] = {10, 10};                 // Halelengde for hver ball

  // Initialiser hver ball med tilfeldig farge
  for (int i = 0; i < NUM_BALLS; i++) {
    colors[i][0] = random(100, 255);                // Rød komponent
    colors[i][1] = random(100, 255);                // Grønn komponent
    colors[i][2] = random(100, 255);                // Blå komponent
  }

  // Initialiser ninja-stjerner med raskere bevegelse
  float starPositions[NUM_STARS] = {5, 15, 25, 35, 45, 55}; // Startposisjon for hver stjerne
  float starSpeed = 1.5;                                   // Høyere hastighet for stjernene
  int starTrails[NUM_STARS] = {8, 8, 8, 8, 8, 8};          // Halelengde for hver stjerne
  int starColors[NUM_STARS][3];                            // RGB-farge for hver stjerne

  // Tilfeldige farger for stjerner
  for (int i = 0; i < NUM_STARS; i++) {
    starColors[i][0] = random(200, 255);                   // Lysere rødfarge
    starColors[i][1] = random(200, 255);                   // Lysere grønnfarge
    starColors[i][2] = random(200, 255);                   // Lysere blåfarge
  }

  // Animasjon med tidsbegrensning på ett minutt
  while (millis() - startTime < 60000) {
    strip.clear();  // Tøm stripen hver ramme

    // Oppdater baller
    for (int i = 0; i < NUM_BALLS; i++) {
      positions[i] += velocities[i]; // Oppdater posisjon

      // Kollisjonsdeteksjon mellom ballene
      if (abs(positions[0] - positions[1]) < 1) {
        int tempColor[3] = {colors[0][0], colors[0][1], colors[0][2]};
        colors[0][0] = colors[1][0];
        colors[0][1] = colors[1][1];
        colors[0][2] = colors[1][2];
        colors[1][0] = tempColor[0];
        colors[1][1] = tempColor[1];
        colors[1][2] = tempColor[2];
        velocities[0] *= -1;
        velocities[1] *= -1;
      }

      if (positions[i] >= NUMPIXELS - 1 || positions[i] <= 0) {
        velocities[i] *= -1;
        positions[i] = constrain(positions[i], 0, NUMPIXELS - 1);
      }

      int pos = int(positions[i]);
      strip.setPixelColor(pos, strip.Color(colors[i][0], colors[i][1], colors[i][2]));

      for (int t = 1; t < trails[i]; t++) {
        int trailPos = pos - (t * (velocities[i] > 0 ? 1 : -1));
        if (trailPos >= 0 && trailPos < NUMPIXELS) {
          int fadeValue = map(t, 0, trails[i], 255, 50);
          strip.setPixelColor(trailPos, strip.Color(
            (colors[i][0] * fadeValue) / 255,
            (colors[i][1] * fadeValue) / 255,
            (colors[i][2] * fadeValue) / 255
          ));
        }
      }
    }

    // Oppdater ninja-stjerner
    for (int i = 0; i < NUM_STARS; i++) {
      starPositions[i] += starSpeed; // Beveg stjernen mot høyre

      if (starPositions[i] >= NUMPIXELS) {
        starPositions[i] = 0;
      }

      int starPos = int(starPositions[i]);
      strip.setPixelColor(starPos, strip.Color(starColors[i][0], starColors[i][1], starColors[i][2]));

      for (int t = 1; t < starTrails[i]; t++) {
        int trailPos = starPos - t;
        if (trailPos >= 0) {
          int fadeValue = map(t, 0, starTrails[i], 255, 50);
          strip.setPixelColor(trailPos, strip.Color(
            (starColors[i][0] * fadeValue) / 255,
            (starColors[i][1] * fadeValue) / 255,
            (starColors[i][2] * fadeValue) / 255
          ));
        }
      }
    }

    strip.show();
    delay(delayTime);
  }
}
#endif