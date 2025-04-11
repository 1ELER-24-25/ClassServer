#ifndef FUNKSJONER_H
#define FUNKSJONER_H

#include <Adafruit_NeoPixel.h>
#include "animasjoner.h"  // Lagt til denne linjen for å få tilgang til blink()

// Eksterne variabler
extern bool erNedtelling;
extern unsigned long nedtellingsStart;
extern unsigned long nedtellingsTid;
extern uint32_t nedtellingsFarge;
extern PubSubClient client;
extern const char* mqtt_status_topic;
extern Adafruit_NeoPixel strip;

// Funksjonserklæringer og definisjoner
void alarm(uint32_t color, int speed) {
  for(int i = 0; i < NUMPIXELS; i++) {
    strip.setPixelColor(i, color);
    strip.show();
    delay(speed);
  }
  delay(500);
  strip.clear();
  strip.show();
}

// Fjernet blink() funksjonen siden den er definert i animasjoner.h

void reconnect();

// Definer variablene her

struct timePlan {
  byte ukedag;              // Mandag = 1 --> fredag = 5
  String startTid;          // (tt:mm) f.eks. "08:10"
  byte varighet;            // (minutt)
  byte fag;                 // 0 = Ingenting 
                            // 1 = Friminutt 
                            // 2 = El- kretser og nettverk
                            // 3 = Energi og styresystemer 
                            // 4 = Norsk
                            // 5 = Engelsk
                            // 6 = Matte
                            // 7 = Naturfag
                            // 8 = Gym
};

extern timePlan plan[60]; // Deklarer plan som en ekstern variabel

// Funksjoner:

void fyllPlan() {
    // DAG          Klokke  Varighet  Fag
    // 1 = Mandag   "tt:mm" mm (int)  0 = Ingenting 
    // 2 = Tirsdag                    1 = Friminutt 
    // 3 = Onsdag                     2 = El- kretser og nettverk
    // 4 = Torsdag                    3 = Energi og styresystemer 
    // 4 = Fredag                     4 = YFF
    //                                5 = Engelsk
    //                                6 = Matte
    //                                7 = Naturfag
    //                                8 = Gym

  // Mandag
  plan[0] = {1, "08:10", 45, 2}; 
  plan[1] = {1, "08:55", 45, 3}; 
  plan[2] = {1, "09:40", 20, 1}; 
  plan[3] = {1, "10:00", 90, 4}; 
  plan[4] = {1, "11:30", 30, 1}; 
  plan[5] = {1, "12:00", 90, 8}; 
  plan[6] = {1, "13:30", 10, 1}; 
  plan[7] = {1, "13:40", 90, 5};  

  // Tirsdag 
  plan[8] = {2, "08:10", 90, 6}; 
  plan[9] = {2, "09:40", 20, 1}; 
  plan[10] = {2, "10:00", 90, 3}; 
  plan[11] = {2, "11:30", 30, 1}; 
  plan[12] = {2, "12:00", 90, 3}; 
  plan[13] = {2, "13:30", 10, 1}; 
  plan[14] = {2, "13:40", 45, 3}; 

  // Onsdag 
  plan[15] = {3, "08:10", 90, 6}; 
  plan[16] = {3, "09:40", 20, 1}; 
  plan[17] = {3, "10:00", 45, 6}; 
  plan[18] = {3, "10:45", 90, 4};  

  // Torsdag 
  plan[19] = {4, "08:10", 90, 2};  
  plan[20] = {4, "09:40", 20, 1};  
  plan[21] = {4, "10:00", 90, 2};  
  plan[22] = {4, "11:30", 30, 1};  
  plan[23] = {4, "12:00", 45, 2};  
  plan[24] = {4, "12:45", 45, 5};  
  plan[25] = {4, "13:30", 10, 1};  
  plan[26] = {4, "13:40", 90, 5};   

  // Fredag 
  plan[27] = {5, "08:55", 45, 2}; 
  plan[28] = {5, "09:40", 20, 1}; 
  plan[29] = {5, "10:00", 90, 3}; 
  plan[30] = {5, "11:30", 30, 1}; 
  plan[31] = {5, "12:00", 90, 3}; 
  plan[32] = {5, "13:30", 10, 1}; 
  plan[33] = {5, "13:40", 90, 7}; 

}


//************************************************************
//************            FAG             ********************
//************************************************************


String fag(DateTime now, timePlan plan[])
{
  const String fagList[] = {"Ingenting", "Friminutt", "El. kretser og nettverk",
                            "Energi og styresystemer", "Norsk", "Engelsk", "Matte",
                            "Naturfag", "Gym"};

  byte dag = now.dayOfTheWeek();
  if (dag == 0 || dag == 6) {
    return "Det er helg i dag.";
  }

  for (int i = 0; i < 60; i++) {
    if (dag == plan[i].ukedag) {
      // Calculate the end time of the lesson
      String startTid = plan[i].startTid;
      byte varighet = plan[i].varighet;
      
      // Convert start time to minutes
      int startHour = startTid.substring(0, 2).toInt();
      int startMinute = startTid.substring(3, 5).toInt();
      int startTotalMinutes = startHour * 60 + startMinute;

      // Convert current time to minutes
      int currentTotalMinutes = now.hour() * 60 + now.minute();

      // Check if current time falls within the lesson time frame
      if (currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < startTotalMinutes + varighet) {
        byte fagIndex = plan[i].fag;
        return fagList[fagIndex];
      }
    }
  }

  return fagList[0];
}

//************************************************************
//************        FAGNUMMER           ********************
//************************************************************

byte fagNummer(DateTime now, timePlan plan[]){
  byte dag = now.dayOfTheWeek();
  if (dag == 0 || dag == 6) {
    return 0;
  }

  for (int i = 0; i < 60; i++) {
    if (dag == plan[i].ukedag) {
      // Calculate the end time of the lesson
      String startTid = plan[i].startTid;
      byte varighet = plan[i].varighet;
      
      // Convert start time to minutes
      int startHour = startTid.substring(0, 2).toInt();
      int startMinute = startTid.substring(3, 5).toInt();
      int startTotalMinutes = startHour * 60 + startMinute;

      // Convert current time to minutes
      int currentTotalMinutes = now.hour() * 60 + now.minute();

      // Check if current time falls within the lesson time frame
      if (currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < startTotalMinutes + varighet) {
        return plan[i].fag;
      }
    }
  }
  return 0;
}

//************************************************************
//************          STILL KLOKKE      ********************
//************************************************************

void stillKlokke() {
  DateTime gammelTid = rtc.now();  // Hent nåværende tid for å beholde året
  
  // Spør om dato først
  Serial.println("Skriv inn dato (dd.mm.yyyy):");
  while (Serial.available() == 0);
  String datoInput = Serial.readStringUntil('\n');
  int dag, maned, ar;
  if (sscanf(datoInput.c_str(), "%d.%d.%d", &dag, &maned, &ar) != 3) {
    Serial.println("Ugyldig datoformat! Bruk dd.mm.yyyy");
    return;
  }
  
  // Valider dato
  if (ar < 2023 || ar > 2099 || maned < 1 || maned > 12 || dag < 1 || dag > 31) {
    Serial.println("Ugyldig dato!");
    return;
  }

  // Spør om klokkeslett
  Serial.println("Skriv inn klokkeslett (hh:mm:ss):");
  while (Serial.available() == 0);
  String tidInput = Serial.readStringUntil('\n');
  int timer, minutt, sekund;
  if (sscanf(tidInput.c_str(), "%d:%d:%d", &timer, &minutt, &sekund) != 3) {
    Serial.println("Ugyldig tidsformat! Bruk hh:mm:ss");
    return;
  }

  // Valider klokkeslett
  if (timer < 0 || timer > 23 || minutt < 0 || minutt > 59 || sekund < 0 || sekund > 59) {
    Serial.println("Ugyldig klokkeslett!");
    return;
  }

  // Oppdater RTC-klokken med alle verdiene
  DateTime nyTid = DateTime(ar, maned, dag, timer, minutt, sekund);
  rtc.adjust(nyTid);
  
  // Bekreft oppdatering
  Serial.println("Klokken er oppdatert til:");
  Serial.print(nyTid.year(), DEC);
  Serial.print('/');
  Serial.print(nyTid.month(), DEC);
  Serial.print('/');
  Serial.print(nyTid.day(), DEC);
  Serial.print(" ");
  Serial.print(nyTid.hour(), DEC);
  Serial.print(':');
  Serial.print(nyTid.minute(), DEC);
  Serial.print(':');
  Serial.println(nyTid.second(), DEC);
}

//************************************************************
//************ Sekunder igjen av timen    ********************
//************************************************************


  int tidIgjen(int currentDay, int currentHour, int currentMinute, int currentSecond){
    int currentfag = -1;
    for (int i = 0; i < 40; i++) {
      if (plan[i].ukedag == currentDay) {
        int fagStartMinutes = plan[i].startTid.substring(0, 2).toInt() * 60 + plan[i].startTid.substring(3, 5).toInt();
        int fagEndMinutes = fagStartMinutes + plan[i].varighet;
        int currentMinutes = currentHour * 60 + currentMinute;

        if (currentMinutes >= fagStartMinutes && currentMinutes < fagEndMinutes) {
          currentfag = i;
          break;
        }
      }
    }

    if (currentfag != -1) {
      int fagStartMinutes = plan[currentfag].startTid.substring(0, 2).toInt() * 60 + plan[currentfag].startTid.substring(3, 5).toInt();
      int fagEndMinutes = fagStartMinutes + plan[currentfag].varighet;
      int currentMinutes = currentHour * 60 + currentMinute;
      int currentTotalSeconds = currentMinutes * 60 + currentSecond;
      int fagEndTotalSeconds = fagEndMinutes * 60;

      int remainingTime = fagEndTotalSeconds - currentTotalSeconds;

      return remainingTime;
      //Serial.print(remainingTime);
      //Serial.println(" sekunder igjen");
    } else {
      return 0;
      //Serial.println("Ingen fag");
    }
  }

//************************************************************
//************        NEDTELLING          ********************
//************************************************************

void nedTelling(int igjen, uint32_t farge) {

  int tidNa = rtc.now().minute() * 60 + rtc.now().second();
  int tidNaPixel = map(tidNa,0,3599,0,NUMPIXELS);
  int endepunkt = tidNa + igjen;
  int endepunktPixel = map(endepunkt,0,3599,0,NUMPIXELS-1);
  
  for (int i = tidNaPixel; i <= endepunktPixel; i++) {
    strip.setPixelColor(i % NUMPIXELS, farge);
  }
}

void startNedtelling(unsigned long varighet, uint32_t farge) {
  erNedtelling = true;
  nedtellingsStart = millis();
  nedtellingsTid = varighet;
  nedtellingsFarge = farge;
  
  // Blink tre ganger raskt
  for (int i = 0; i < 3; i++) {
    strip.clear();
    strip.show();
    delay(200);
    for(int j = 0; j < NUMPIXELS; j++) {
      strip.setPixelColor(j, nedtellingsFarge);
    }
    strip.show();
    delay(200);
  }
}

void visNedtelling() {
  unsigned long gattTid = millis() - nedtellingsStart;
  
  if (gattTid >= nedtellingsTid) {
    // Nedtelling ferdig
    alarm(strip.Color(130, 0, 0), 25);  // Kjør en passende animasjon
    blink();
    erNedtelling = false;
    return;
  }
  
  // Beregn hvor mange LED-er som skal være tent
  float gjenstaendeProsent = 1.0 - ((float)gattTid / nedtellingsTid);
  int antallLED = round(NUMPIXELS * gjenstaendeProsent);
  
  strip.clear();
  for(int i = 0; i < antallLED; i++) {
    strip.setPixelColor(i, nedtellingsFarge);
  }
  strip.show();
}

void stoppNedtelling() {
  erNedtelling = false;
  strip.clear();
  strip.show();
}

void handleNedtellingsKommando(String message) {
  // Format: "nedtelling:1h2m30s:FF0000"
  // eller: "nedtelling:stopp"
  
  if (message == "nedtelling:stopp") {
    stoppNedtelling();
    client.publish(mqtt_status_topic, "Nedtelling stoppet");
    return;
  }
  
  // Del opp meldingen
  int firstColon = message.indexOf(':');
  int secondColon = message.lastIndexOf(':');
  
  if (firstColon == -1 || secondColon == -1) {
    client.publish(mqtt_status_topic, "Ugyldig nedtellingsformat");
    return;
  }
  
  String timeStr = message.substring(firstColon + 1, secondColon);
  String colorStr = message.substring(secondColon + 1);
  
  // Parse tid
  unsigned long totalMillis = 0;
  int timer = 0, minutter = 0, sekunder = 0;
  
  int hPos = timeStr.indexOf('h');
  int mPos = timeStr.indexOf('m');
  int sPos = timeStr.indexOf('s');
  
  if (hPos != -1) {
    timer = timeStr.substring(0, hPos).toInt();
  }
  if (mPos != -1) {
    int startPos = (hPos != -1) ? hPos + 1 : 0;
    minutter = timeStr.substring(startPos, mPos).toInt();
  }
  if (sPos != -1) {
    int startPos = (mPos != -1) ? mPos + 1 : (hPos != -1 ? hPos + 1 : 0);
    sekunder = timeStr.substring(startPos, sPos).toInt();
  }
  
  totalMillis = (timer * 3600000UL) + (minutter * 60000UL) + (sekunder * 1000UL);
  
  // Parse farge (hex til uint32_t)
  uint32_t farge;
  unsigned long hexValue = strtoul(colorStr.c_str(), NULL, 16);
  farge = strip.Color((hexValue >> 16) & 0xFF, (hexValue >> 8) & 0xFF, hexValue & 0xFF);
  
  // Start nedtellingen
  startNedtelling(totalMillis, farge);
  
  String bekreftelse = "Starter nedtelling: " + 
                      String(timer) + "t " + 
                      String(minutter) + "m " + 
                      String(sekunder) + "s";
  client.publish(mqtt_status_topic, bekreftelse.c_str());
}

//************************************************************
//************        WIFI & TIME          *******************
//************************************************************
void setTimezone(String timezone){
  Serial.printf("  Setting Timezone to %s\n",timezone.c_str());
  setenv("TZ",timezone.c_str(),1);  //  Now adjust the TZ.  Clock settings are adjusted to show the new local time
  tzset();
}
void initTime(String timezone){
  struct tm timeinfo;

  Serial.println("Setting up time");
  configTime(0, 0, "pool.ntp.org");    // First connect to NTP server, with 0 TZ offset
  if(!getLocalTime(&timeinfo)){
    Serial.println("  Failed to obtain time");
    return;
  }
  Serial.println("  Got the time from NTP");
  // Now we can set the real timezone
  setTimezone(timezone);
}

void printLocalTime(){
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)){
    Serial.println("Failed to obtain time 1");
    return;
  }
  Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S zone %Z %z ");
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println("Melding mottatt [" + String(topic) + "]: " + message);

  if (String(topic) == mqtt_command_topic) {
    if (message.startsWith("nedtelling:")) {
      handleNedtellingsKommando(message);
    }
  }
}
#endif
