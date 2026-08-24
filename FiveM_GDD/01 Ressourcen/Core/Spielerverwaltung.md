Der Core besitzt den Lebenszyklus einer Spielsitzung: vom Verbindungsaufbau über das Laden der
Daten bis zum Speichern beim Verlassen. Andere Features docken sich über die
[[Schnittstellen]] daran an, statt eigene Connect-Handler zu schreiben.

## Verbindungsaufbau

1. Spieler verbindet sich, der Core hält die Verbindung zurück ("Deferral") und zeigt einen
   Status an ("Lade Spielerdaten…").
2. Identifier auslesen – maßgeblich ist die **Rockstar-Lizenz** (`license:`). Fehlt sie, wird
   die Verbindung abgelehnt.
3. `players`-Eintrag laden oder, bei einem neuen Spieler, anlegen.
4. Zugehörigen `characters`-Eintrag laden.
5. Bei einem Datenbankfehler wird die Verbindung **abgelehnt** statt durchgewunken (siehe
   [[Datenbank]]).

## Spawn

- **Bestehender Charakter** → Spawn an der zuletzt gespeicherten Position, mit gespeicherter
  Gesundheit/Rüstung und gespeichertem Aussehen.
- **Neuer Charakter** → Spawn an einem in der `config.lua` hinterlegten Startpunkt mit
  Startguthaben.
- Eine Charaktererstellung (Name, Aussehen) ist in dieser Version **nicht** enthalten. Neue
  Spieler bekommen einen Standard-Charakter; das Erstellen kommt später als eigene Resource,
  die den Core über die Schnittstellen befüllt.
- Erst wenn die Daten vollständig geladen und angewendet sind, gilt der Spieler als bereit und
  der Core löst `core:playerLoaded` aus. Features dürfen vorher keine Spielerdaten erwarten.

## Sitzung im laufenden Betrieb

- Der Core hält die Spielerdaten **serverseitig** im Speicher. Der Server ist die Quelle der
  Wahrheit; der Client bekommt eine schreibgeschützte Kopie zur Anzeige (HUD).
- Änderungen an Geld und Zustand laufen immer über den Server. Client-seitige Änderungen
  werden ignoriert.
- Position, Gesundheit und Rüstung werden regelmäßig vom Client an den Server gemeldet, damit
  der Autosave etwas Aktuelles zu speichern hat.
- Wie bei [[Basic Admin]] gilt: Das ist eine Hürde gegen normale Spieler, kein Cheat-Schutz.
  Für das lokale `127.0.0.1`-Setup akzeptiert.

## Verlassen des Servers

- Beim Disconnect werden die Daten gespeichert und aus dem Speicher entfernt, danach löst der
  Core `core:playerDropped` aus, damit Features aufräumen können.
- Die Spielzeit der Sitzung wird auf `playtime_seconds` addiert.
- Das Aufräumen der vom Spieler hinterlassenen Fahrzeuge/Objekte hängt sich an dieses Ereignis
  (siehe "Welt aufräumen" in [[Core]]).

## Tod & Respawn

Vorerst bewusst offen gelassen. Zu klären ist, ob der Core den Todeszustand besitzt (weil
mehrere Features darauf reagieren müssen: Sanitäter, Versicherung, Geldverlust) oder ob eine
eigene Resource das übernimmt. Bis dahin gilt das Standardverhalten von `spawnmanager`.
