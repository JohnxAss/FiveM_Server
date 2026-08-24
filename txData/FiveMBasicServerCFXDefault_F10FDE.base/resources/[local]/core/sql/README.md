# Core – Datenbankschema

Die Dateien werden **von Hand** eingespielt, in der Reihenfolge ihrer Nummer. Der Core legt
nichts automatisch an – er prueft beim Start nur, ob die noetigen Tabellen da sind, und meldet
in der Konsole, wenn etwas fehlt.

## Erstes Setup – der einfache Weg

`setup.ps1` erledigt alles: Datenbank und Benutzer anlegen, Schema einspielen, Zugang
gegenpruefen und den Verbindungsstring in die `server.cfg` schreiben. In einem
PowerShell-Fenster in diesem Ordner:

```
powershell -ExecutionPolicy Bypass -File setup.ps1
```

Gefragt wird nur nach dem **MariaDB-root-Passwort** (bei der Installation gesetzt). Das
Passwort fuer den Datenbank-Benutzer `fivem` wird erzeugt und direkt in die `server.cfg`
geschrieben – man muss es sich nicht merken. Ein eigenes geht per
`-FivemPassword "..."`, dann aber den Zeichensatz beachten:

> **Achtung, Zeichensatz:** oxmysql parst den Verbindungsstring selbst (`parseUri` in
> `dist/build.js`) und **dekodiert kein URL-Encoding** – es splittet stumpf an `:` und `@`.
> Ein Passwort mit `@ : / ? # & ; = %` oder Leerzeichen zerlegt den String, und man sucht
> den Fehler danach in einer nichtssagenden Auth-Meldung. Erlaubt sind deshalb nur
> Buchstaben, Ziffern und `- _ .` – `setup.ps1` prueft das.

## Erstes Setup – von Hand

`mysql.exe` liegt bei einer Standardinstallation unter
`C:\Program Files\MariaDB <Version>\bin\` und ist **nicht** im PATH.

1. In `000_datenbank_und_benutzer.sql` das `<PASSWORT>` durch ein eigenes ersetzen
   (Zeichensatz wie oben).
2. `mysql -u root -p < 000_datenbank_und_benutzer.sql`
3. `mysql -u fivem -p fivem < 001_players.sql`
4. In der `server.cfg` das `<DB_PASSWORT>` im `mysql_connection_string` ersetzen.

## Aenderungen am Schema

Immer eine **neue, hochgezaehlte Datei** anlegen statt eine bestehende zu aendern. Nur so ist
nachvollziehbar, auf welchem Stand eine bereits vorhandene Datenbank ist. Wer eine Datei
nachtraeglich editiert, bekommt bei sich selbst kein Problem – aber die naechste frische
Installation weicht ab.

`setup.ps1` spielt beim naechsten Lauf alle `0*.sql` ausser `000_*` erneut ein; die Dateien
muessen deshalb mit `IF NOT EXISTS` o. ae. wiederholbar bleiben.

Neue Tabellen zusaetzlich in `REQUIRED_TABLES` in `server/database.lua` eintragen, damit ein
fehlendes Schema beim Start auffaellt statt erst beim ersten Zugriff.
