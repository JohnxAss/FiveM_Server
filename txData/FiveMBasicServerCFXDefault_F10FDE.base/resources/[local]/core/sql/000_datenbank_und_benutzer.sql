-- Core Schema 000 - Datenbank und Benutzer anlegen
--
-- Einmalig als root ausfuehren:
--   mysql -u root -p < 000_datenbank_und_benutzer.sql
--
-- <PASSWORT> vorher durch ein eigenes ersetzen. Dasselbe Passwort landet in
-- der server.cfg im mysql_connection_string - die ist gitignored, diese Datei
-- hier ist versioniert und darf deshalb kein echtes Passwort enthalten.
--
-- Zeichensatz fuer <PASSWORT>: nur Buchstaben, Ziffern und - _ .
-- oxmysql dekodiert im Verbindungsstring kein URL-Encoding und splittet stumpf
-- an ":" und "@" - Sonderzeichen zerlegen den String (siehe README).
--
-- Bewusst ein eigener Benutzer statt root, und bewusst nur localhost:
-- der Server ist ohnehin nur lokal erreichbar.

CREATE DATABASE IF NOT EXISTS `fivem`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'fivem'@'localhost' IDENTIFIED BY '<PASSWORT>';

GRANT ALL PRIVILEGES ON `fivem`.* TO 'fivem'@'localhost';

FLUSH PRIVILEGES;
