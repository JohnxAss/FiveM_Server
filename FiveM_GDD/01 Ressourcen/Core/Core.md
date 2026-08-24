In den Core sollen Funktionen, die alle oder viele andere Features gleichzeitig nutzen.

Resource-Name: `core`

Der Core ist **kein Gameplay-Feature**. Er stellt die Grundlage bereit, auf der alle anderen
Resources aufbauen: persistente Spielerdaten, den Lebenszyklus einer Spielsitzung und eine
gemeinsame Schnittstelle. Er ist bewusst schlank gehalten – ein eigener kleiner Unterbau, kein
Nachbau von ESX/QBCore.

## Faustregel: gehört es in den Core?

Etwas gehört in den Core, wenn **mindestens zwei Features es brauchen** und es sonst doppelt
implementiert würde – oder wenn es **einen einzigen Besitzer braucht**, weil zwei parallele
Implementierungen sich gegenseitig stören würden (z. B. zwei Systeme, die dieselbe Spielerzeile
in der Datenbank schreiben).

Alles andere bleibt in der jeweiligen Feature-Resource. Im Zweifel: **nicht** in den Core. Etwas
später vom Feature in den Core hochzuziehen ist einfach; den Core wieder zu entschlacken nicht.

## Bestandteile

| Baustein                | Beschreibung                                                    |
| ----------------------- | --------------------------------------------------------------- |
| [[Datenbank]]           | Verbindung zur MySQL/MariaDB, Schema, Speicherstrategie          |
| [[Spielerverwaltung]]   | Connect/Disconnect, Laden & Speichern der Spielerdaten, Spawn    |
| [[Schnittstellen]]      | Exports, Events und Callbacks für andere Resources               |

## Was ausdrücklich **nicht** in den Core gehört

- Konkretes Gameplay (Jobs, Shops, Fahrzeugbesitz, Aktivitäten). Der Core hält Geld, gibt es
  aber nicht aus und verdient es nicht.
- Inventar-Logik. Der Core speichert höchstens den Inventarstand als Datensatz, die Regeln
  gehören in eine eigene Resource.
- Admin-Werkzeuge – die liegen in [[Basic Admin]] bzw. `EasyAdmin`.
- Alles mit eigenem, sichtbarem Menü. Der Core hat keine eigene UI.

## Technik & Abhängigkeiten

- Eine einzelne Resource unter `resources/[local]/core/`.
- Abhängigkeit: **`oxmysql`** als Datenbank-Treiber (Fremd-Resource, gehört in die
  `.gitignore`). Der Core kapselt sie – Feature-Resources sprechen `oxmysql` **nie** direkt an.
- Start-Reihenfolge in der `server.cfg`: `oxmysql` → `core` → alle Feature-Resources.
- Feature-Resources tragen `dependency 'core'` in ihre `fxmanifest.lua` ein.
- Konventionen wie bei [[Basic Admin]]: Event-Präfix = Resource-Name (`core:playerLoaded`),
  Konfiguration in einer `config.lua` als `shared_script`.

## Weitere Bausteine (noch nicht ausgearbeitet)

Kandidaten, die die Faustregel erfüllen, aber noch keine Spezifikation haben:

- **Welt aufräumen** – der Core führt Buch über von Spielern gespawnte Fahrzeuge/Objekte und
  entfernt sie wieder (bei Disconnect des Spawners, per Admin-Befehl, ggf. zeitgesteuert). In
  [[Basic Admin]] ist das bereits als Core-Aufgabe abgegrenzt.
- **Notifications** – ein gemeinsames Meldungssystem, damit nicht jedes Feature sein eigenes
  baut. Basic Admin nutzt derzeit native GTA-Notifications und würde darauf umgestellt.
- **Logging** – zentrale Protokollierung wichtiger Ereignisse (Datei und/oder Discord-Webhook).
- **Berechtigungen** – dünne Hilfsschicht über `IsPlayerAceAllowed`, falls sich später
  abgestufte Gruppen (Supporter/Moderator/Admin) ergeben. Solange nur `group.admin` existiert,
  reicht ACE direkt.

## Offene Entscheidungen

- **Ein oder mehrere Charaktere pro Spieler?** Die erste Version geht von **einem** Charakter
  aus (siehe [[Spielerverwaltung]]), das Schema ist aber schon auf mehrere vorbereitet.
- **Gehört Geld in den Core?** Die erste Version sagt ja – Bargeld und Bankguthaben liegen im
  Spielerdatensatz, weil zu viele Features sie lesen und schreiben. Zu klären ist, ob der Core
  auch Transaktionen protokolliert oder nur den Kontostand hält.
- **Bans**: bleiben vorerst bei `EasyAdmin` (eigene Datenhaltung). Erst zusammenführen, wenn
  ein eigenes Admin-System EasyAdmin ablöst.
