# FiveM-Server – Projektnotizen

Diese Datei hält Wissen fest, das nicht direkt aus den Config-/Resource-Dateien ersichtlich ist:
Entscheidungen, Fallstricke, Konventionen. Bei neuen Erkenntnissen **diese Datei aktualisieren**
(alte, überholte Aussagen korrigieren statt nur anhängen).

Stand: 2026-08-24

## Setup / Architektur

- Kein klassischer reiner FXServer-Start, sondern **txAdmin-basiert** (erkennbar an `txData/`
  mit Profil-Unterordnern). `server/FXServer.exe` ist der Launcher für txAdmin + den eigentlichen
  Spiel-Server-Prozess in einem.
- Aktives Profil: **`default`** (`txData/default/config.json`). Dessen `dataPath` zeigt auf
  `txData/FiveMBasicServerCFXDefault_F10FDE.base/` – dort liegen die eigentliche `server.cfg`,
  `resources/`, Cache etc. Das ist der relevante Ordner für Config-/Resource-Änderungen, nicht
  `txData/default/` (das ist nur txAdmin-Verwaltungsdaten: Logs, Player-DB, Changelog).
- 26 Resources aktiv, u. a. Basis-Set (`mapmanager`, `chat`, `spawnmanager`, `sessionmanager`,
  `basic-gamemode`, `hardcap`) + `monitor` (= txAdmin selbst, läuft als Resource im
  Server-Prozess) + `EasyAdmin` (Admin-Menü/-Befehle, s. u.).
- Die geladene Map-Resource wechselt zwischen Starts (beobachtet: `fivem-map-skater`,
  `fivem-map-hipster`) – vermutlich zufällige Auswahl aus mehreren mitgelieferten
  Map-Resources durch `mapmanager`. Noch nicht untersucht, wo/ob das konfigurierbar ist.

## Server starten/stoppen

- Start (**immer im Vordergrund**, laut User-Vorgabe **nicht** als Hintergrundprozess starten –
  damit man Logs live sieht und selbst mit `Strg+C` stoppen kann):
  ```bash
  cd "/d/Entwicklung/FiveM-Server/server" && ./FXServer.exe +set serverProfile default
  ```
- txAdmin-Webpanel danach erreichbar unter `http://localhost:40120`.
- Stoppen: `Strg+C` im Server-Fenster, oder "Stop Server" im txAdmin-Panel. (Ein im Hintergrund
  gestarteter Prozess lässt sich auch per `tasklist`/`taskkill` bzw. Stoppen der Bash-Background-
  Task beenden – kam einmal vor, war aber nicht der gewünschte Standard-Workflow.)
- `serverProfile`-ConVar ist laut Startup-Log als **deprecated** markiert (Empfehlung: künftig
  `TXHOST_DATA_PATH`-Env-Var statt Profilname) – aktuell aber noch der einzig genutzte Weg hier,
  funktioniert weiterhin.

## Netzwerk / Lokalität

- `server.cfg` (`txData/FiveMBasicServerCFXDefault_F10FDE.base/server.cfg`) hat
  `endpoint_add_tcp`/`endpoint_add_udp` bewusst auf **`127.0.0.1:30120`** gesetzt (nicht
  `0.0.0.0`) → Spiel-Server ist nur vom eigenen PC aus erreichbar, kein LAN-/Internet-Zugriff.
  Verbinden im Client über `connect 127.0.0.1:30120`.
  **Falls später echter Mehrspieler-/Netzwerkbetrieb gewünscht ist**: zurück auf `0.0.0.0:30120`
  setzen und Windows-Firewall + Portforwarding im Router einrichten (Server warnt beim Start
  selbst darauf hin: "Home-hosting fxserver is not recommended").
- Das **txAdmin-Webpanel** (Port 40120) lauscht weiterhin auf `0.0.0.0` – das ist eine getrennte
  Einstellung, nicht Teil der `server.cfg`. Bisher nicht eingeschränkt; bei Bedarf separat lösen
  (txAdmin-Config bzw. Firewall-Regel für 40120).

## Admin-Zugriff

- Der eigene FiveM-Identifier ist bereits fest in der `server.cfg` als Admin eingetragen:
  `identifier.fivem:18963857` (Kommentar `#JohnxAss`), Mitglied in `group.admin` mit
  `command allow` (Ausnahme: `command.quit deny`).
- **EasyAdmin**-Resource aktiv (Stand: v7.52, als "UNSTABLE PRE-RELEASE" markiert). Menü öffnen
  per Chat-Befehl `/easyadmin` – **kein Default-Keybind** hinterlegt (`RegisterKeyMapping` mit
  leerem String). Bei Bedarf selbst binden: Escape-Menü → Einstellungen → Tastenbelegung →
  Kategorie "FiveM" → "EasyAdmin".
- Zusätzliche direkte Chat-Befehle aus EasyAdmin: `/kick`, `/ban`, `/slap`, `/spectate`,
  `/setgametype`, `/setmapname`.
- **Bekannter Fehler** (aufgetreten beim Start 2026-08-24): `SCRIPT ERROR:
  @EasyAdmin/server/admin_server.lua:1101: attempt to concatenate a nil value (global
  'resourceName')`. Ursache noch nicht untersucht – betrifft vermutlich ein Nebenfeature
  (Report/Webhook-Logging o. ä.), das Kern-Admin-Menü (`/easyadmin`) funktionierte trotzdem.
  Falls das Menü doch mal nicht reagiert: hier als bekannten Verdachtspunkt zuerst prüfen.

## Für eigene Feature-Entwicklung

- Eigene Resources gehören nach
  `txData/FiveMBasicServerCFXDefault_F10FDE.base/resources/[local]/<resourcename>/`, jeweils mit
  eigener `fxmanifest.lua`. Danach in der `server.cfg` mit `ensure <resourcename>` aktivieren
  (siehe bestehende `ensure`-Zeilen als Vorlage).
  - **`[local]/` ist bewusst die Kategorie für eigenen Code** – alle anderen Kategorie-Ordner
    (`[gameplay]`, `[system]`, …) und `EasyAdmin/` sind Fremdcode und in der `.gitignore`
    ausgeschlossen. Eine Resource direkt unter `resources/` würde nicht versioniert werden.
  - Kategorie-Ordner in eckigen Klammern werden von FXServer automatisch durchsucht; der
    `ensure`-Name ist nur der Resource-Ordnername, ohne die Kategorie.
- Nach Config-Änderungen (`server.cfg`, neue Resource) reicht ein Server-Neustart; `ensure`/
  `refresh`/`restart <resource>` gehen bei laufendem Server auch direkt über die Server-Konsole
  bzw. txAdmin-Panel, ohne kompletten Neustart – für schnelle Iteration beim Entwickeln nutzen.

### Eigene Resources (Stand)

- **`basic-admin`** – erstes eigenes Feature, dient als Blaupause. Spezifikation im GDD unter
  `FiveM_GDD/01 Ressourcen/Basic Admin/`. NUI-Menü (`/basicadmin`, dazu ein leeres
  `RegisterKeyMapping`, Taste selbst zuweisbar) mit Fahrzeug-Spawn und Teleport zum Wegpunkt.
- Konventionen, die daraus hervorgehen und für weitere Resources gelten sollen:
  - **Event-Präfix = Resource-Name**, z. B. `basic-admin:spawnVehicle`.
  - **ACE-Name = Resource-Name ohne Bindestrich**, z. B. `basicadmin`; Vergabe in der
    `server.cfg` per `add_ace group.admin <ace> allow`.
  - Berechtigungen werden **serverseitig** mit `IsPlayerAceAllowed` geprüft, nicht im Client.
    Der Client fragt beim Öffnen beim Server an und bekommt die Daten erst dann geliefert.
  - Client-seitige Natives (Spawn, Teleport) lassen sich nicht wirklich absichern – der
    ACE-Check ist eine Hürde gegen normale Spieler, kein Cheat-Schutz. Für das lokale
    `127.0.0.1`-Setup akzeptiert.
  - Konfiguration in einer `config.lua` als `shared_script`, damit Client und Server dieselbe
    Whitelist sehen.
  - `onResourceStop` immer `SetNuiFocus(false, false)` – sonst hängt nach `restart <resource>`
    der Mauszeiger fest.
- Änderungen an der `server.cfg` bitte **parallel in `server.cfg.example` spiegeln** – die
  echte `server.cfg` ist wegen `sv_licenseKey` gitignored, die `.example` ist der versionierte
  Stand.

## Vorsicht / sensible Daten

- `server.cfg` enthält `sv_licenseKey` im Klartext – nicht in öffentliche Repos, Screenshots oder
  Issues teilen.
- Der Ordner **ist inzwischen ein Git-Repo** (Branch `main`). Die `.gitignore` schließt bereits
  aus: den FXServer-Build (`/server/`), txAdmin-Logs/Player-DB, `txData/admins.json`
  (Passwort-Hash), die `server.cfg` selbst (Lizenzschlüssel) sowie alle Fremd-Resources.
  Neue Fremd-Resource-Kategorien dort ergänzen; eigener Code gehört nach `[local]/`.
