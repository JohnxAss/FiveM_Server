-- Core - Einstieg
-- Haengt die Spielerverwaltung an die Server-Events und stellt die Exports
-- fuer andere Resources bereit.

CreateThread(function()
    for attempt = 1, Config.DatabaseRetries do
        -- Details erst beim letzten Versuch: ein erster Fehlschlag direkt nach
        -- dem Serverstart ist normal und soll die Konsole nicht zumuellen.
        if Database.Init(attempt == Config.DatabaseRetries) then
            return
        end
        Wait(Config.DatabaseRetryDelay * 1000)
    end
end)

-- ---------------------------------------------------------------------------
-- Verbindungsaufbau
-- ---------------------------------------------------------------------------

AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    if not Database.ready then
        if Config.RejectWithoutDatabase then
            deferrals.done('Der Server ist gerade nicht bereit (keine Datenbankverbindung). Bitte spaeter erneut versuchen.')
            return
        end
        -- Ohne DB gibt es nichts zu laden; Spieler kommt rein, speichert aber nichts.
        print('[core] WARNUNG: Spieler verbindet ohne Datenbank, es wird nichts gespeichert.')
        deferrals.done()
        return
    end

    deferrals.update('Lade Spielerdaten...')

    local ok, reason = Players.Preload(src, name)
    if not ok then
        deferrals.done(reason)
        return
    end

    deferrals.done()
end)

AddEventHandler('playerJoining', function()
    local src = source
    if not Database.ready then return end

    local ok, reason = Players.StartSession(src)
    if not ok then
        DropPlayer(src, reason)
        return
    end

    -- Ab hier duerfen andere Resources Spielerdaten erwarten - vorher nicht.
    TriggerEvent('core:playerLoaded', src)
end)

-- ---------------------------------------------------------------------------
-- Verlassen des Servers
-- ---------------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    local src = source
    if not Players.Get(src) then return end

    Players.Save(src)
    -- Erst melden, dann die Sitzung verwerfen: Handler sollen die Daten des
    -- Spielers noch lesen koennen (z. B. um seine Fahrzeuge aufzuraeumen).
    TriggerEvent('core:playerDropped', src)
    Players.EndSession(src)
end)

-- ---------------------------------------------------------------------------
-- Autosave & Shutdown
-- ---------------------------------------------------------------------------

CreateThread(function()
    while true do
        Wait(Config.AutosaveInterval * 1000)
        if Database.ready then
            local saved = Players.SaveAll()
            if saved > 0 then
                Database.Debug(('Autosave: %d Sitzung(en) gespeichert.'):format(saved))
            end
        end
    end
end)

--- Feuert auch beim Herunterfahren des Servers und beim txAdmin-Neustart.
--- Achtung: das Zeitfenster beim Stop ist kurz, die Speichervorgaenge koennen
--- abgeschnitten werden. Deshalb gibt es zusaetzlich den Autosave oben.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local saved = Players.SaveAll()
    print(('[core] Shutdown: %d Sitzung(en) gespeichert.'):format(saved))
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    local saved = Players.SaveAll()
    print(('[core] txAdmin-Shutdown: %d Sitzung(en) gespeichert.'):format(saved))
end)

-- ---------------------------------------------------------------------------
-- Schnittstellen fuer andere Resources
-- ---------------------------------------------------------------------------

exports('GetPlayer', function(src) return Players.Get(src) end)
exports('GetPlayerByLicense', function(license) return Players.GetByLicense(license) end)
exports('GetPlayers', function() return Players.GetAll() end)
exports('SavePlayer', function(src) return Players.Save(src) end)
exports('IsDatabaseReady', function() return Database.ready end)

-- ---------------------------------------------------------------------------
-- Diagnose (nur Server-Konsole / ACE, kein Spieler-Feature)
-- ---------------------------------------------------------------------------

RegisterCommand('core_players', function()
    local list = Players.GetAll()
    print(('[core] %d aktive Sitzung(en):'):format(#list))
    for _, session in ipairs(list) do
        local live = session.playtime + (os.time() - session.joinedAt)
        print(('[core]   [%d] %s  license=%s  Spielzeit=%dm')
            :format(session.source, session.name or '?', session.license, math.floor(live / 60)))
    end
end, true)
