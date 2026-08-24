Stellt Basis-Adminbefehle zur Verfügung.

Resource-Name: `basic-admin`

## Zugriff

Nur für Admins. Der Server prüft die ACE-Berechtigung `basicadmin`, die in der
`server.cfg` an `group.admin` vergeben wird. Spieler ohne Berechtigung bekommen beim
Öffnungsversuch die Meldung "Keine Berechtigung" und sehen das Menü nicht.

## Öffnen / Schließen

- Chat-Befehl `/basicadmin` öffnet das Menü.
- Zusätzlich ist eine frei wählbare Taste hinterlegbar: Escape-Menü → Einstellungen →
  Tastenbelegung → Kategorie "FiveM" → "Basic Admin öffnen". Es gibt bewusst **keine**
  Default-Taste, um Konflikte mit anderen Resources zu vermeiden.
- Schließen per Klick auf das `X` in der Kopfzeile oder mit `ESC`.

## Rückmeldungen

Erfolgs- und Fehlermeldungen erscheinen als native GTA-Notification oben links
(kein Chat-Spam).

## Abgrenzung

Das Aufräumen der Karte (gespawnte Fahrzeuge wieder entfernen) ist **nicht** Teil von
Basic Admin. Gespawnte Fahrzeuge bleiben bestehen. Das soll später ein eigenes
**Core**-Feature übernehmen.


Tabelle erstmal ignorieren

| Attribute | Kurz | Beschreibung |
| --------- | ---- | ------------ |
|           |      |              |
|           |      |              |
