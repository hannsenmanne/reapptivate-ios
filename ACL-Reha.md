# ACL-Rekonstruktion Reha-Programm — Implementierungsstand

> **Stand:** 2026-02-24 | **Status:** Vollständig implementiert & produktionsbereit

---

## Übersicht

Das ACL-R (vordere Kreuzband-Rekonstruktion) Reha-Programm ist als vollständige Pathologie in die Reapptivate iOS-App integriert. Es umfasst ein **5-Meilenstein-System** mit 9 Trainings-Streams, umfassende KPI-Erfassung, Entlassungskriterien, Analytik und Psychoedukation.

**Umfang:** 11 Views, 6 ViewModels, ~580 Zeilen Domänenmodelle, 18 API-Endpoints, ~115 Unit-Tests

---

## 1. Meilenstein-System (5 Stufen)

| Meilenstein | Zeitraum | Schwerpunkt |
|------------|----------|-------------|
| M0 (Pre-Op) | Vor OP | Vorbereitung, Baseline-Erfassung |
| M1 | Wochen 0–6 | Wundheilung, ROM-Wiederherstellung, Quadrizeps-Aktivierung |
| M2 | Wochen 7–12 | Kraftaufbau, Gangbild-Normalisierung |
| M3 | Wochen 13–24 | Funktionelles Training, Laufprogression |
| M4 | Wochen 25–36 | Sport-spezifisches Training, Explosivität |
| M5 (Entlassung) | Ab Woche 36 | Return-to-Sport, Entlassungskriterien erfüllen |

**Meilenstein-Übergänge** werden durch funktionelle Kriterien gesteuert (z.B. Quadrizeps LSI ≥80%, Hamstring LSI ≥80%), nicht rein zeitbasiert. Therapeut:innen erfassen Laborwerte (Lab Assessments), die gegen die Kriterien geprüft werden.

---

## 2. Screening & Onboarding

### Screening-Workflow (6 Schritte)
1. **OP-Datum** (Datumswähler) — bestimmt initialen Meilenstein (M0 wenn prä-OP)
2. **Transplantat-Typ** (Radio) — Hamstring, Patellasehne (BTB), Quadrizepssehne
3. **Athleten-Level** (Radio) — Leistungssportler / Freizeitsportler
4. **Begleitverletzungen** (Checkboxen) — Meniskusnaht, Chondrale Reparatur, Laterale extraartikuläre Tenodese, Posterolateraler Eckenkomplex, Keine
5. **Sportart** (Freitext, optional)
6. **Knieseite** (Radio) — Links / Rechts

**UX-Details:** Radio-Auswahl mit Auto-Advance (~500ms), NONE-Checkbox-Exklusivität (entfernt andere Auswahlen), Fortschrittsbalken, Slide-Transitions zwischen Schritten.

### Nach dem Screening
- `ScreeningCompleteView` zeigt ACL-spezifische Inhalte (Kreuzbandrekonstruktion, 5-Meilenstein-Programm)
- Weiterleitung zum Dashboard

---

## 3. Dashboard (AclDashboardView)

Das ACL-Dashboard zeigt auf einen Blick:

| Komponente | Beschreibung |
|-----------|-------------|
| **Profil-Karte** | Aktueller Meilenstein (M/5), Wochen post-OP, Transplantat-Typ |
| **KPI Quick Actions** | Buttons für tägliche & wöchentliche KPI-Erfassung (öffnet Sheet) |
| **Meilenstein-Timeline** | Visuelle Zeitleiste M0–M5 mit aktuellem Fortschritt |
| **Nächste Ziele** | Kriterien für den nächsten Meilenstein mit Fortschrittsanzeige |
| **Aktive Streams** | Erste 4 freigeschaltete Trainings-Streams mit "Alle anzeigen" |
| **Entlassungskriterien** | Nur ab M4 sichtbar: Gesamtfortschritt + erfüllte/gesamt Kriterien |
| **Trainingsplan** | Geplante Trainingstage (wie bei anderen Pathologien) |

**Skeleton Loading** während Daten geladen werden, **InlineErrorView** mit Retry bei Fehlern.

---

## 4. Trainings-Streams (9 Streams)

### Stream-Übersicht (AclStreamOverviewView)
Zeigt alle verfügbaren Streams mit Freischaltungs-Status:

| Stream | Icon | Freischaltung |
|--------|------|--------------|
| CLINICAL_ROM | figure.walk | M1 |
| MOTOR_CONTROL | figure.mind.and.body | M1 |
| STRENGTH | figure.strengthtraining.functional | M1 |
| EXPLOSIVENESS | bolt.fill | M3 |
| REACTIVE_STRENGTH | figure.jumprope | M3 |
| RUNNING | figure.run | M2 |
| CHANGE_OF_DIRECTION | arrow.triangle.swap | M4 |
| SPORTS_SPECIFIC | sportscourt | M4 |
| CONDITIONING | heart.circle | M2 |

- Gesperrte Streams: Grau, Lock-Icon, 70% Opacity
- Freigeschaltete Streams: Farbig, Navigation zum Detail

### Stream-Detail (AclStreamDetailView)
Jede Übung zeigt:
- Name, Beschreibung (DE/EN)
- Parameter-Tags: Sätze, Wiederholungen, Haltezeit, Tempo, Intensität
- **Transplantat-spezifische Modifikationen** (gefiltert nach User-Graft-Typ)
- **Begleitverletzungs-Vorsichtsmaßnahmen** (gefiltert nach User-Verletzungen)

---

## 5. KPI-Erfassung (3 Ebenen)

### Tägliche KPIs (AclDailyKpiLoggerView)
| Parameter | Typ | Bereich |
|-----------|-----|---------|
| Schmerzintensität (NRS) | Slider | 0–10 |
| Schmerzlokalisation | Freitext | optional |
| Schmerzauslösende Aktivität | Freitext | optional |
| Knieflexion | Stepper | 0–160° (5°-Schritte) |
| Extensionsdefizit | Stepper | 0–30° (1°-Schritte) |
| Erguss (Stroke Test) | Segmented | Grad 0–3 |
| Quadrizeps-Lag | Toggle | Ja/Nein |
| Notizen | Freitext | optional |

### Wöchentliche KPIs (AclWeeklyKpiLoggerView)
| Parameter | Typ | Bereich |
|-----------|-----|---------|
| IKDC-Score | Nummernfeld | 0–100 |
| Tampa-Score (TSK-11) | Nummernfeld | 11–44 |
| Oberschenkelumfang 5cm | Dezimalfeld | 20–80 cm |
| Oberschenkelumfang 10cm | Dezimalfeld | 20–80 cm |

**Tampa-Warnung:** Bei Score >37 wird eine Warnung "Erhöhte Bewegungsangst erkannt" angezeigt (client-seitig + server-seitig).

### Labor-Assessments (Therapeut:in-seitig)
Umfassende Kraft-LSI-Metriken:
- **Kraft:** Quad, Hamstring, Hüft-Abd/Add/ER, Wade (alle als LSI %)
- **Explosivität:** DL CMJ konzentrisch/exzentrisch, SL CMJ Höhe
- **Reaktivkraft:** DL/SL Drop Jump RSI, SL DJ Kontaktzeit
- **Laufen:** Geschwindigkeit (km/h)
- **Klinisch:** IKDC, Tampa, Flexion, Extension, Erguss

### Unsaved Changes Protection
Beide KPI-Logger haben Bestätigungsdialoge beim Abbrechen mit ungespeicherten Änderungen.

---

## 6. KPI-Verlauf (AclKpiHistoryView)

Drei-Tab-Ansicht im Progress-Tab:

| Tab | Inhalt |
|-----|--------|
| **Täglich** | Expandierbare Karten mit Schmerz, ROM, Erguss, Details |
| **Wöchentlich** | IKDC, Tampa (mit Warnung >37), Oberschenkelumfang |
| **Labor** | Nach Meilenstein gruppiert: Kraft-LSI, Explosivität, Reaktivkraft, Laufen, Klinisch |

**Farbkodierung LSI:** Rot <70%, Amber 70–85%, Grün ≥85%

---

## 7. Entlassungskriterien (AclDischargeProgressView)

Ab Meilenstein 4 sichtbar. Zeigt:
- Gesamtfortschritt in % mit Farbbalken
- Einzelne Kriterien mit Fortschrittsbalken
- Operator-basierte Logik: `>=` (höher = besser) vs. `<=` (niedriger = besser)
- Checkmark bei erfüllten Kriterien
- Meldung "Alle Kriterien erfüllt — Entlassung möglich" bei 100%

---

## 8. Analytik (AclAnalyticsView)

8 Trend-Charts mit dem Swift Charts Framework:

| Chart | Typ | Besonderheiten |
|-------|-----|---------------|
| Schmerz-Trend | Linie + Punkte | Skala 0–10, farbkodiert |
| ROM-Trend | Dual-Linien | Flexion + Extensionsdefizit |
| Erguss-Trend | Farbkodierte Punkte | Grad 0–4 |
| IKDC-Trend | Linie | Grüne 85%-Ziellinie |
| Tampa-Trend | Linie | Rote 37-Schwelle (Kinesiophobia) |
| Oberschenkelumfang | Dual-Linien | 5cm + 10cm suprapatellär |
| Kraft-LSI | Balkendiagramm | Quad + Hamstring mit 90%-Ziellinie |

---

## 9. Psychoedukation (AclMicroModulesView)

- Meilenstein-gezielte Micro-Module
- Client-seitige Filterung: `targetCondition == "ACL_RECONSTRUCTION"` oder `nil`
- Expandierbare Karten mit Markdown-Inhalt
- "Take-Home" Botschaft (Amber-Highlight)
- Fortschrittsanzeige (abgeschlossen / gesamt)
- "Gelesen"-Button mit 2-Step API (start + complete)
- Haptic Feedback bei Abschluss

---

## 10. Technische Details

### API-Endpoints (18 Endpoints)

| Kategorie | Endpoints |
|-----------|----------|
| Screening | `GET /config`, `POST /screening`, `GET /screening` |
| Streams | `GET /streams`, `GET /streams/:streamId` |
| Meilenstein | `GET /milestone-status` |
| Tägliche KPIs | `POST /daily-kpi`, `GET /daily-kpi` |
| Wöchentliche KPIs | `POST /weekly-kpi`, `GET /weekly-kpi` |
| Labor | `POST /lab-assessment` (Therapeut), `GET /lab-assessment` |
| Entlassung | `GET /discharge-progress` |
| Analytik | `GET /analytics` |
| Micro-Module | `GET /micro-modules`, `GET /completed`, `POST /start`, `POST /complete` |

Alle Endpoints unter `/api/acl/` mit JWT-Authentifizierung.

### Flexible Numeric Decoding
PostgreSQL `numeric`-Spalten liefern Strings statt Zahlen. Gelöst durch `KeyedDecodingContainer`-Extension mit `flexibleDouble()` / `flexibleInt()` Hilfsmethoden in 7 Structs.

### Dateien

| Bereich | Dateien |
|---------|--------|
| Views | 11 Dateien in `Views/ACL/` |
| ViewModels | 6 Dateien in `ViewModels/Acl*.swift` |
| Models | `AclTypes.swift` (~580 Zeilen) |
| Endpoints | In `APIEndpoints.swift` (18 Methoden) |
| Tests | `AclTypesTests.swift`, `AclViewModelTests.swift` (~115 Tests) |

### UX-Patterns
- **Skeleton Loading** auf Dashboard
- **InlineErrorView** mit Retry-Buttons überall
- **Haptic Feedback:** Selection (Tab/Stream), Success (KPI-Submit, Modul-Read)
- **Card Entry Animations** mit gestaffelten Indizes
- **@ScaledMetric** auf Icon-Containern (Dynamic Type)
- **`.inputFieldStyle()`** konsistent auf allen Textfeldern
- **Shared `aclStreamIcon(for:)`** mit Mapping für alle 9 Backend-Streams

---

## 11. Test-Accounts

| Account | Passwort |
|---------|----------|
| `ACLcomptest@test.com` | `Test1234!` |

---

## 12. Offene Punkte / Zukünftige Erweiterungen

### Aus dem ursprünglichen Interview-Leitfaden noch nicht umgesetzt:
- **Push-Notifications** für Trainings-Erinnerungen (zeitbasiert, eventbasiert, adaptiv)
- **Wearable-Integration** (Apple Watch, Schrittzähler, Herzfrequenz)
- **Fear Hierarchy** speziell für ACL (gestufte Return-to-Sport-Szenarien, analog LBP-FAR)
- **Streak-Mechaniken** (mit Sicherheitsmechanismus gegen Übertraining)
- **Meilenstein-Feiern** (emotionale Erfolgserlebnisse bei funktionellen Durchbrüchen)
- **Red-Flag-Benachrichtigungen** an Therapeut:innen (plötzlicher Schmerzanstieg, Schwellung)
- **Video-Demonstrationen** für Übungen
- **ACL-RSI Fragebogen** (psychologische Return-to-Sport-Bereitschaft)
- **Compliance-Dashboard** für Therapeut:innen
- **Daily Tips** (Backend-Daten vorhanden in `acl-daily-tips.json`, UI noch nicht integriert)
