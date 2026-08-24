-- Core - Datenbank
-- Kapselt oxmysql vollstaendig. KEINE andere Resource darf oxmysql direkt
-- ansprechen oder eigenes SQL schreiben - Grund siehe CLAUDE.md: zwei Resources,
-- die unabhaengig dieselbe Spielerzeile schreiben, ueberschreiben sich gegenseitig.
-- Ein Treiberwechsel soll ausserdem nur diese Datei betreffen.

Database = {}

-- Wird erst true, wenn Verbindung UND Schema geprueft sind. Solange false,
-- laesst main.lua niemanden auf den Server (siehe Config.RejectWithoutDatabase).
Database.ready = false

-- Tabellen, ohne die der Core nicht arbeiten kann. Wird beim Start geprueft;
-- angelegt wird nichts automatisch (siehe sql/README).
local REQUIRED_TABLES = { 'players' }

-- Waehrend der Startversuche still bleiben (siehe Database.Init).
local silent = false

function Database.Debug(msg)
    if Config.Debug then
        print(('[core] %s'):format(msg))
    end
end

--- Fuehrt eine Abfrage aus und faengt Fehler ab, statt die Resource abzuschiessen.
--- @return any, string|nil  Ergebnis oder nil + Fehlertext
local function safeCall(fn, sql, params)
    local ok, result = pcall(fn, sql, params)
    if not ok then
        if silent then return nil, tostring(result) end
        print(('[core] SQL-Fehler: %s'):format(tostring(result)))
        print(('[core]   Abfrage: %s'):format(sql))
        return nil, tostring(result)
    end
    return result, nil
end

function Database.Query(sql, params)
    return safeCall(MySQL.query.await, sql, params)
end

function Database.Single(sql, params)
    return safeCall(MySQL.single.await, sql, params)
end

function Database.Scalar(sql, params)
    return safeCall(MySQL.scalar.await, sql, params)
end

--- INSERT/UPDATE/DELETE. Gibt die Zahl betroffener Zeilen zurueck.
function Database.Execute(sql, params)
    return safeCall(MySQL.update.await, sql, params)
end

--- Verbindung und Schema pruefen. Setzt Database.ready.
--- Bei verbose = false bleibt der Core still: die ersten Fehlschlaege direkt
--- nach dem Serverstart sind normal, weil oxmysql noch verbindet.
function Database.Init(verbose)
    silent = not verbose
    local alive, err = Database.Scalar('SELECT 1')
    if alive == nil then
        if not verbose then return false end
        print('[core] ---------------------------------------------------------------')
        print('[core] KEINE VERBINDUNG ZUR DATENBANK.')
        print('[core] Pruefen: laeuft der MariaDB-Dienst, und stimmt der')
        print('[core] mysql_connection_string in der server.cfg?')
        print(('[core] Fehler: %s'):format(err or 'unbekannt'))
        print('[core] ---------------------------------------------------------------')
        return false
    end

    local missing = {}
    for _, tableName in ipairs(REQUIRED_TABLES) do
        local found = Database.Scalar(
            'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?',
            { tableName }
        )
        if not found or found == 0 then
            missing[#missing + 1] = tableName
        end
    end

    if #missing > 0 then
        if not verbose then return false end
        print('[core] ---------------------------------------------------------------')
        print(('[core] FEHLENDE TABELLEN: %s'):format(table.concat(missing, ', ')))
        print('[core] Schema von Hand einspielen, die Dateien liegen unter')
        print('[core] resources/[local]/core/sql/ (siehe README dort).')
        print('[core] ---------------------------------------------------------------')
        return false
    end

    silent = false
    Database.ready = true
    print('[core] Datenbank verbunden, Schema vollstaendig.')
    return true
end
