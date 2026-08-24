So greifen andere Resources auf den Core zu. Ziel ist, dass ein Feature **nie** selbst SQL
schreibt und **nie** eigene Connect-Handler braucht.

## Grundsätze

- Der Server ist die Quelle der Wahrheit. Der Client darf lesen, aber nichts verbindlich
  ändern.
- Zugriffe laufen über **Exports** (direkter Aufruf) und **Events** (Benachrichtigung).
- Event-Präfix ist der Resource-Name: `core:...` – wie bei [[Basic Admin]] festgelegt.
- Jede Berechtigungsprüfung passiert serverseitig.

## Serverseitig – Exports

| Export                              | Zweck                                              |
| ----------------------------------- | -------------------------------------------------- |
| `GetPlayer(source)`                 | Spielerobjekt der aktuellen Sitzung                 |
| `GetPlayerByLicense(license)`       | Zugriff auf einen bestimmten Spieler                |
| `GetPlayers()`                      | alle geladenen Spieler                              |
| `SavePlayer(source)`                | sofort speichern, statt auf den Autosave zu warten  |

Das Spielerobjekt bietet mindestens: Identifier, Name, Kontostände (`AddMoney`,
`RemoveMoney`, `GetMoney`) sowie Lesen/Schreiben von `metadata`. Geld-Funktionen geben
zurück, ob die Buchung geklappt hat – ein Kauf darf nicht stattfinden, wenn das Abbuchen
fehlschlägt.

## Serverseitig – Events

| Event                       | Wann                                                      |
| --------------------------- | --------------------------------------------------------- |
| `core:playerLoaded`         | Spielerdaten geladen und angewendet, Spieler ist bereit    |
| `core:playerDropped`        | Spieler hat den Server verlassen, Daten sind gespeichert   |
| `core:playerSaved`          | nach jedem Speichervorgang                                 |

## Clientseitig

- Export `GetPlayerData()` liefert die schreibgeschützte Kopie der eigenen Daten (für HUD und
  Menüs).
- Event `core:dataUpdated` meldet Änderungen, damit die UI nicht pollen muss.
- Event `core:playerReady` als clientseitiges Gegenstück zu `core:playerLoaded`.

> **Stand:** Umgesetzt sind die Server-Exports `GetPlayer`, `GetPlayerByLicense`,
> `GetPlayers`, `SavePlayer` und `IsDatabaseReady` sowie die drei Events oben. Der
> Client-Teil und die Callbacks darunter sind Zielzustand – der Core hat aktuell gar kein
> Client-Script, weil noch kein Feature danach fragt.

## Callbacks (Client fragt, Server antwortet)

Ein wiederkehrendes Muster: Der Client braucht eine Information, die nur der Server hat – wie
in [[Basic Admin]], wo das Menü beim Öffnen erst beim Server nachfragt. Statt dass jedes
Feature sich dafür ein Event-Paar baut, stellt der Core ein Callback-System bereit:

- Server: `RegisterCallback(name, handler)`
- Client: `TriggerCallback(name, cb, ...)`

Der Core kümmert sich um die Zuordnung von Anfrage und Antwort. Wird [[Basic Admin]] später
angepasst, ersetzt das dessen eigenes Anfrage-Event.

## Config

Die `config.lua` liegt als `shared_script` vor, damit Client und Server dieselben Werte sehen.
Enthält u. a. Startpunkt und Startguthaben für neue Charaktere, das Autosave-Intervall und ein
Debug-Flag für ausführlichere Konsolenausgaben.
