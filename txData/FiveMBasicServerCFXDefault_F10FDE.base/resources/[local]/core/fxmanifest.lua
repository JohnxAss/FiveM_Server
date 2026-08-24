fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'core'
author 'JohnxAss'
description 'Unterbau fuer alle Feature-Resources: Datenbank, Spielerdaten, Lebenszyklus'
version '0.1.0'

shared_script 'config.lua'

-- Reihenfolge ist relevant: erst die oxmysql-Lib, dann die eigenen Module.
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/players.lua',
    'server/main.lua',
}

dependency 'oxmysql'
