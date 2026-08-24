-- Basic Admin - Serverseite
-- Verantwortlich fuer Berechtigungspruefung (ACE) und Whitelist-Pruefung.
-- Die eigentlichen Aktionen (Spawn/Teleport) laufen als Client-Natives; der Server
-- gibt sie nur frei. Das schuetzt gegen normale Spieler, nicht gegen manipulierte
-- Clients - fuer dieses lokale Dev-Setup ist das ausreichend.

local lastAction = {}

--- ACE-Check inkl. Rueckmeldung an den Spieler.
local function isAllowed(src)
    if IsPlayerAceAllowed(src, Config.AcePermission) then
        return true
    end
    TriggerClientEvent('basic-admin:notify', src, 'Keine Berechtigung')
    return false
end

--- Einfacher Cooldown pro Spieler gegen Event-Spam.
local function passesCooldown(src)
    local now = GetGameTimer()
    local last = lastAction[src]
    if last and (now - last) < (Config.Cooldown * 1000) then
        return false
    end
    lastAction[src] = now
    return true
end

RegisterNetEvent('basic-admin:requestOpen', function()
    local src = source
    if not isAllowed(src) then return end
    TriggerClientEvent('basic-admin:openMenu', src, Config.Vehicles)
end)

RegisterNetEvent('basic-admin:spawnVehicle', function(model)
    local src = source
    if not isAllowed(src) then return end
    if not passesCooldown(src) then return end

    if not Config.IsVehicleAllowed(model) then
        TriggerClientEvent('basic-admin:notify', src, 'Unbekanntes Fahrzeug')
        print(('[basic-admin] %s (%d) hat ein nicht gelistetes Modell angefragt: %s')
            :format(GetPlayerName(src) or '?', src, tostring(model)))
        return
    end

    TriggerClientEvent('basic-admin:doSpawnVehicle', src, model)
end)

RegisterNetEvent('basic-admin:teleportWaypoint', function()
    local src = source
    if not isAllowed(src) then return end
    if not passesCooldown(src) then return end
    TriggerClientEvent('basic-admin:doTeleport', src)
end)

AddEventHandler('playerDropped', function()
    lastAction[source] = nil
end)
