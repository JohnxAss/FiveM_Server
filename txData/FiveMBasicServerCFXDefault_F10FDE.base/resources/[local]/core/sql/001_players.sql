-- Core Schema 001 - players
--
-- Der Account: ein Eintrag pro echtem Spieler, unabhaengig vom spaeteren
-- Charakter. Primaerschluessel ist die Rockstar-License, weil sie stabil ist.
-- Die fivem_id wird nur mitgefuehrt, weil Admin-Eintraege in der server.cfg
-- darueber laufen (add_principal identifier.fivem:...).
--
-- Ausfuehren mit:
--   mysql -u fivem -p fivem < 001_players.sql

CREATE TABLE IF NOT EXISTS `players` (
    `license`          VARCHAR(64)  NOT NULL,
    `fivem_id`         VARCHAR(32)  DEFAULT NULL,
    `name`             VARCHAR(64)  DEFAULT NULL,
    `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_seen`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `playtime_seconds` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`license`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
