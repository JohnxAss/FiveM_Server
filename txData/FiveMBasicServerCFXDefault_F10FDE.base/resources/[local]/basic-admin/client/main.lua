-- Basic Admin - Clientseite
-- Steuert das NUI-Menue und fuehrt die vom Server freigegebenen Aktionen aus.

local menuOpen = false

--- Native GTA-Notification oben links.
local function Notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('basic-admin:notify', function(message)
    Notify(message)
end)

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- --------------------------------------------------------------------------
-- Menue oeffnen
-- --------------------------------------------------------------------------

RegisterCommand('basicadmin', function()
    if menuOpen then
        closeMenu()
        return
    end
    -- Der Server entscheidet, ob geoeffnet werden darf, und liefert den Katalog mit.
    TriggerServerEvent('basic-admin:requestOpen')
end, false)

-- Leerer Default-Key: Taste wird bei Bedarf im Escape-Menue unter
-- Einstellungen -> Tastenbelegung -> "FiveM" selbst zugewiesen.
RegisterKeyMapping('basicadmin', 'Basic Admin oeffnen', 'keyboard', '')

RegisterNetEvent('basic-admin:openMenu', function(vehicles)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', vehicles = vehicles })
end)

-- --------------------------------------------------------------------------
-- NUI-Callbacks
-- --------------------------------------------------------------------------

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('basic-admin:spawnVehicle', data.model)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('teleportWaypoint', function(_, cb)
    TriggerServerEvent('basic-admin:teleportWaypoint')
    cb({ ok = true })
end)

-- --------------------------------------------------------------------------
-- Aktion: Fahrzeug spawnen
-- --------------------------------------------------------------------------

RegisterNetEvent('basic-admin:doSpawnVehicle', function(model)
    local hash = GetHashKey(model)

    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        Notify('Fahrzeug konnte nicht geladen werden')
        return
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            SetModelAsNoLongerNeeded(hash)
            Notify('Fahrzeug konnte nicht geladen werden')
            return
        end
        Wait(0)
    end

    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    -- Native liefert einen vector3 (kein table) -> Felder direkt lesen.
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, Config.SpawnDistance, 0.0)

    -- heading + 90 Grad: Fahrzeug steht quer vor dem Spieler statt frontal auf ihn zu.
    local vehicle = CreateVehicle(hash, offset.x, offset.y, offset.z, heading + 90.0, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    -- Bewusst KEIN SetEntityAsMissionEntity: das Fahrzeug bleibt eine normale
    -- Welt-Entity und darf von der Engine aufgeraeumt werden, wenn der Spieler weit
    -- genug weg ist. Sonst wuerde sich die Karte dauerhaft zumuellen, solange es das
    -- geplante Core-Cleanup noch nicht gibt.
    SetModelAsNoLongerNeeded(hash)

    -- Bewusst kein SetPedIntoVehicle: der Spieler steigt selbst ein (siehe GDD).
    Notify('Fahrzeug gespawnt: ' .. model)
end)

-- --------------------------------------------------------------------------
-- Aktion: Teleport zur Kartenmarkierung
-- --------------------------------------------------------------------------

--- Sucht die Bodenhoehe an X/Y. Der Wegpunkt liefert selbst kein Z, deshalb wird die
--- Entity gestaffelt auf verschiedene Hoehen gesetzt (damit die Collision dort laedt)
--- und jeweils der Boden abgefragt.
local function findGroundZ(entity, x, y)
    for height = 0, 950, 50 do
        SetEntityCoordsNoOffset(entity, x, y, height + 0.0, false, false, false)
        RequestCollisionAtCoord(x, y, height + 0.0)

        -- Der Collision-Streamer braucht ein paar Frames, bis er an der neuen
        -- Position geladen hat.
        local deadline = GetGameTimer() + 250
        repeat
            Wait(0)
            local found, groundZ = GetGroundZFor_3dCoord(x, y, height + 0.0, false)
            if found and groundZ > -100.0 then
                return groundZ
            end
        until GetGameTimer() > deadline
    end
    return nil
end

RegisterNetEvent('basic-admin:doTeleport', function()
    local blip = GetFirstBlipInfoId(8) -- 8 = Wegpunkt-Blip
    if not DoesBlipExist(blip) then
        Notify('Kein Wegpunkt gesetzt')
        return
    end

    local coords = GetBlipInfoIdCoord(blip)
    local x, y = coords.x, coords.y

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    -- Im Fahrzeug wird das Fahrzeug samt Insassen versetzt, sonst nur der Ped.
    local entity = (vehicle ~= 0) and vehicle or ped

    closeMenu()

    -- Waehrend der Suche einfrieren, damit die Entity nicht durch die noch nicht
    -- geladene Map faellt.
    FreezeEntityPosition(entity, true)
    local groundZ = findGroundZ(entity, x, y)
    FreezeEntityPosition(entity, false)

    if not groundZ then
        Notify('Zielhoehe nicht gefunden')
        return
    end

    SetEntityCoordsNoOffset(entity, x, y, groundZ + 1.0, false, false, false)
    SetWaypointOff()
    Notify('Teleportiert')
end)

-- Resource-Stop: NUI-Focus nicht haengen lassen (wichtig bei restart basic-admin).
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
