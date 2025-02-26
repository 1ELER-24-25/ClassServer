# Spilldatabase og Webserver

## 1. Oversikt
Dette er et system for å registrere og administrere bordspill-konkurranser via en webserver. Systemet støtter foosball og sjakk, med mulighet for fremtidig utvidelse.

### Teknisk Stack
- **Server:** Ubuntu 22.04 LTS
- **Backend:** Node.js + Express
- **Frontend:** React + Tailwind CSS
- **Database:** PostgreSQL + Sequelize ORM
- **Hardware:** ESP32-mikrokontrollere med RFID-lesere

## 2. Spillsystemer

### Elo-ratingsystem
- Matematisk system for å beregne relative ferdighetsnivåer
- Alle nye spillere starter med rating 1200
- Formelen som brukes er: `R_new = R_old + K * (actual_score - expected_score)`
  - `R_new`: Ny rating
  - `R_old`: Gammel rating
  - `K`: K-faktor som bestemmer hvor mye ratingen kan endres
  - `actual_score`: Faktisk resultat (1 for seier, 0.5 for uavgjort, 0 for tap)
  - `expected_score`: Forventet resultat basert på ratingforskjell
- K-faktoren bestemmer hvor raskt ratings endres:
  - Høy K-faktor (32): Store endringer, passer for uformelle spill
  - Lav K-faktor (16): Mindre endringer, passer for formelle spill

### Foosball
- 1 mot 1 kamper
- Første spiller til 10 mål vinner
- Elo K-faktor: 32
- Registrering via RFID-scanning

### Sjakk
- Standard sjakkregler
- Valgfri tidskontroll per spiller
- Elo K-faktor: 16
- Ugyldige trekk håndteres av sjakkbrettet
- Registrering via RFID-scanning

## 3. Database

### Hovedtabeller
1. **users**
   - Brukerinformasjon og RFID-data
   - Primærnøkkel: id
   - Unik: rfid_uid

2. **games**
   - Spilltyper og beskrivelser
   - Primærnøkkel: id
   - Unik: name

3. **matches**
   - Kampinformasjon og resultater
   - Kobling til players og games
   - Lagrer score og vinner

4. **user_elo**
   - Elo-rating per spill per bruker
   - Startrating: 1200
   - Oppdateres automatisk
   - Felter:
     - `user_id`: Kobling til users-tabellen
     - `game_id`: Kobling til games-tabellen
     - `elo`: Nåværende rating (INTEGER)
     - `created_at`: Tidspunkt for første kamp
     - `updated_at`: Sist oppdatert
   - Primærnøkkel: Kombinasjon av (user_id, game_id)

## 4. API

### Bruker-API
```
GET    /api/users         - Liste alle brukere
POST   /api/users         - Ny bruker
GET    /api/users/:id     - Hent bruker
```

### Spill-API
```
POST   /api/matches/start          - Start spill
POST   /api/matches/:id/move       - Sjakktrekk
POST   /api/matches/:id/score      - Foosball scoring
POST   /api/matches/:id/end        - Avslutt spill
```

### ESP32 Dataformat
```json
{
  "type": "foosball_score|chess_move",
  "match_id": "string",
  "player_uid": "string",
  "timestamp": "ISO-8601",
  // For sjakk:
  "move": "string",       // Valgfri (sjakk)
  // For foosball:
  "new_score": "string"   // Valgfri (foosball)
}
```

## 5. Frontend

### Design
- **Farger:**
  - Primær: `#2563EB` (blå)
  - Sekundær: `#DC2626` (rød)
  - Bakgrunn: `#F8FAFC`
  - Tekst: `#1E293B`

- **UI Komponenter:**
  - Runde hjørner (8px)
  - Tykke rammer (2px)
  - Tydelige skygger
  - Filled style ikoner

### Hovedsider
1. **Brukeradministrasjon**
   - Opprett/rediger brukere
   - RFID-registrering

2. **Spilloversikt**
   - Aktive kamper
   - Historikk

3. **Statistikk**
   - Elo-ratings
   - Vinn/tap statistikk
   - Ledertavler

## 6. System og Sikkerhet

### Begrensninger
- Maks 100 brukere
- Maks 10 samtidige spill
- 500ms maks API responstid
- 100 requests/min per IP

### Sikkerhet
- Enkel autentisering (lukket nettverk)
- Daglig database backup
- Automatisk reconnect ved nettverksfeil

### Feilhåndtering
- Automatisk logging av feil
- Spilltilstand caches lokalt
- Retry-mekanismer for nettverksfeil