# Core – Datenbankschema

Nummerierte `.sql`-Dateien, die in ihrer Reihenfolge eingespielt werden. Der Core legt
**nichts automatisch an** – er prueft beim Start nur, ob die noetigen Tabellen da sind, und
meldet in der Konsole, wenn etwas fehlt.

## Erstes Setup

`setup.ps1` erledigt alles: Datenbank und Benutzer anlegen, Schema einspielen, Zugang
gegenpruefen und den Verbindungsstring in die `server.cfg` schreiben. In einem
PowerShell-Fenster in diesem Ordner:

```
powershell -ExecutionPolicy Bypass -File setup.ps1
```

Gefragt wird nur nach dem **MariaDB-root-Passwort** (bei der Installation gesetzt). Das
Passwort fuer den Datenbank-Benutzer `fivem` wird erzeugt und direkt in die `server.cfg`
geschrieben – man muss es sich nicht merken.

Es gibt bewusst **keine** SQL-Datei zum Anlegen von Datenbank und Benutzer mehr: Wer dort den
Platzhalter durch ein echtes Passwort ersetzt, hat es sofort in einer versionierten Datei
stehen. Genau das ist einmal passiert. `setup.ps1` kommt ohne Platzhalter aus.

Ein eigenes Passwort geht per `-FivemPassword "..."`, dann aber den Zeichensatz beachten:

> **Achtung, Zeichensatz:** oxmysql parst den Verbindungsstring selbst (`parseUri` in
> `dist/build.js`) und **dekodiert kein URL-Encoding** – es splittet stumpf an `:` und `@`.
> Ein Passwort mit `@ : / ? # & ; = %` oder Leerzeichen zerlegt den String, und man sucht den
> Fehler danach in einer nichtssagenden Auth-Meldung. Erlaubt sind nur Buchstaben, Ziffern
> und `- _ .` – `setup.ps1` prueft das.

`mysql.exe` liegt bei einer Standardinstallation uebrigens unter
`C:\Program Files\MariaDB <Version>\bin\` und ist **nicht** im PATH.

## Aenderungen am Schema

Immer eine **neue, hochgezaehlte Datei** anlegen statt eine bestehende zu aendern. Nur so ist
nachvollziehbar, auf welchem Stand eine bereits vorhandene Datenbank ist. Wer eine Datei
nachtraeglich editiert, bekommt bei sich selbst kein Problem – aber die naechste frische
Installation weicht ab.

`setup.ps1` spielt beim naechsten Lauf **alle** `0*.sql` erneut ein; die Dateien muessen
deshalb wiederholbar bleiben (`CREATE TABLE IF NOT EXISTS` o. ae.).

Neue Tabellen zusaetzlich in `REQUIRED_TABLES` in `server/database.lua` eintragen, damit ein
fehlendes Schema beim Start auffaellt statt erst beim ersten Zugriff.
