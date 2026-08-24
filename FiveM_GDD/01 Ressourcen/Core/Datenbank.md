Der Core ist die **einzige** Resource, die mit der Datenbank spricht. Alle anderen Features
holen und schreiben ihre Daten über die [[Schnittstellen]] des Cores.

## Technik

- **MariaDB** (bzw. MySQL) lokal auf demselben Rechner wie der Server.
- Zugriff über die Fremd-Resource **`oxmysql`**. Der Core kapselt sie vollständig – ein
  Wechsel des Treibers soll nur den Core betreffen.
- Der Verbindungsstring steht in der `server.cfg`
  (`set mysql_connection_string "mysql://user:passwort@localhost/fivem?charset=utf8mb4"`)
  und enthält damit Zugangsdaten – die `server.cfg` ist bereits gitignored, in der
  `server.cfg.example` steht nur ein Platzhalter.
- Schreibende Zugriffe laufen **asynchron**, damit der Server-Tick nicht blockiert. Nur beim
  Server-Shutdown wird bewusst synchron gespeichert.

## Verhalten bei Problemen

- **Datenbank beim Serverstart nicht erreichbar** → der Core meldet den Fehler deutlich in der
  Konsole und **lässt keine Spieler auf den Server** (Ablehnung beim Connect mit
  entsprechender Meldung). Lieber kein Spiel als ein Spiel ohne Speicherstand.
- **Verbindung bricht im laufenden Betrieb ab** → Speichervorgänge werden im Speicher
  gehalten und beim nächsten erfolgreichen Zyklus nachgeholt. Fehlschläge werden geloggt.
- Ein Spieler, dessen Daten **nicht geladen werden konnten**, wird abgelehnt statt mit einem
  leeren Datensatz zu spawnen – sonst überschreibt der nächste Speichervorgang den Fortschritt.

## Schema (erste Version)

Bewusst klein gehalten. Neue Features bringen eigene Tabellen mit, die per `license` bzw.
`character_id` verknüpft sind – der Core besitzt nur die beiden Basistabellen.

**`players`** – der Account, ein Eintrag pro echtem Spieler.

| Spalte             | Typ            | Beschreibung                                    |
| ------------------ | -------------- | ----------------------------------------------- |
| `license`          | VARCHAR(64) PK | Rockstar-Lizenz, stabiler Primärschlüssel        |
| `fivem_id`         | VARCHAR(32)    | Forum-ID, wird für Admin-Einträge in der `server.cfg` genutzt |
| `name`             | VARCHAR(64)    | zuletzt gesehener Anzeigename                   |
| `created_at`       | DATETIME       | erster Connect                                  |
| `last_seen`        | DATETIME       | letzter Disconnect                              |
| `playtime_seconds` | INT            | aufsummierte Spielzeit                          |

**`characters`** – der Spielstand. Vorerst genau ein Eintrag pro `license`, die Tabelle ist
aber schon auf mehrere Charaktere vorbereitet.

| Spalte                             | Typ           | Beschreibung                          |
| ---------------------------------- | ------------- | ------------------------------------- |
| `id`                               | INT PK AI     |                                       |
| `license`                          | VARCHAR(64)   | FK auf `players.license`              |
| `firstname`, `lastname`            | VARCHAR(32)   |                                       |
| `money_cash`, `money_bank`         | BIGINT        | Kontostände                           |
| `pos_x`, `pos_y`, `pos_z`, `heading` | FLOAT       | letzte Position                       |
| `health`, `armor`                  | INT           | Zustand beim Verlassen                |
| `appearance`                       | JSON          | Aussehen/Kleidung                     |
| `metadata`                         | JSON          | freies Feld für Features ohne eigene Tabelle |
| `last_played`                      | DATETIME      |                                       |

Zu `metadata`: praktisch, um kleine Werte ohne Schema-Änderung abzulegen, aber schlecht
durchsuchbar. Sobald ein Feature seine Daten filtern oder auswerten will, bekommt es eine
eigene Tabelle.

## Speicherstrategie

Gespeichert wird zu drei Zeitpunkten:

1. **Beim Disconnect** des Spielers – der wichtigste Fall.
2. **Beim Herunterfahren des Servers** – alle noch verbundenen Spieler auf einmal. Muss auch
   bei einem txAdmin-Neustart greifen, nicht nur bei sauberem `quit`.
3. **Autosave** in festem Intervall (Vorschlag: alle 5 Minuten, konfigurierbar) – schützt den
   Fortschritt bei einem Absturz.

Zusätzlich kann ein Feature über die [[Schnittstellen]] ein sofortiges Speichern anstoßen,
wenn eine Änderung nicht verloren gehen darf (z. B. ein größerer Geldbetrag).

## Migrationen

Das Schema liegt als `.sql`-Datei in der Resource und wird versioniert. Änderungen kommen als
neue, nummerierte Datei dazu statt die alte zu ändern – so ist nachvollziehbar, welchen Stand
eine bestehende Datenbank hat. Automatisches Einspielen ist vorerst nicht vorgesehen; die
Dateien werden von Hand ausgeführt.
