-- Core - Spielerverwaltung
-- Besitzt den Lebenszyklus einer Sitzung: Laden beim Connect, Sitzung im
-- Speicher halten, Speichern beim Verlassen/Autosave/Shutdown.
-- Der Server ist die Quelle der Wahrheit; der Client bekommt (spaeter) nur Kopien.

Players = {}

-- Aktive Sitzungen, Schluessel ist die Server-ID des Spielers.
local sessions = {}

-- Zwischenspeicher zwischen playerConnecting und playerJoining. Beim Connect
-- gibt es noch keine endgueltige Server-ID, deshalb Schluessel = License.
local pending = {}

-- Nach so vielen Sekunden gilt ein Connect als abgebrochen und der
-- Zwischenspeicher wird verworfen (Spieler bricht im Ladebildschirm ab).
local PENDING_TIMEOUT = 300

local function prunePending()
    local now = os.time()
    for license, entry in pairs(pending) do
        if (now - entry.at) > PENDING_TIMEOUT then
            pending[license] = nil
        end
    end
end

--- Liest den Datensatz oder legt einen neuen an.
--- @return table|nil, string|nil
local function fetchOrCreate(license, fivemId, name)
    local row, err = Database.Single(
        'SELECT license, fivem_id, name, playtime_seconds FROM players WHERE license = ?',
        { license }
    )
    if err then return nil, err end
    if row then return row, nil end

    local affected, insertErr = Database.Execute(
        'INSERT INTO players (license, fivem_id, name, created_at, last_seen, playtime_seconds) VALUES (?, ?, ?, NOW(), NOW(), 0)',
        { license, fivemId, name }
    )
    if insertErr or not affected or affected == 0 then
        return nil, insertErr or 'INSERT ohne Wirkung'
    end

    print(('[core] Neuer Spieler angelegt: %s (%s)'):format(name or '?', license))
    return { license = license, fivem_id = fivemId, name = name, playtime_seconds = 0 }, nil
end

--- Waehrend playerConnecting: Daten laden und zwischenspeichern.
--- @return boolean, string|nil  Erfolg, sonst Grund fuer die Ablehnung
function Players.Preload(src, name)
    prunePending()

    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then
        return false, 'Kein gueltiger Rockstar-Identifier gefunden.'
    end

    local row, err = fetchOrCreate(license, GetPlayerIdentifierByType(src, 'fivem'), name)
    if not row then
        return false, ('Spielerdaten konnten nicht geladen werden (%s).'):format(err or 'unbekannt')
    end

    pending[license] = { row = row, at = os.time() }
    Database.Debug(('vorgeladen: %s (%s)'):format(name or '?', license))
    return true, nil
end

--- Beim tatsaechlichen Betreten: Sitzung aus dem Zwischenspeicher aufbauen.
--- @return boolean, string|nil
function Players.StartSession(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then
        return false, 'Kein gueltiger Rockstar-Identifier gefunden.'
    end

    local entry = pending[license]
    pending[license] = nil

    local row = entry and entry.row
    if not row then
        -- Fallback, falls der Zwischenspeicher verlorenging (z. B. Resource-Restart
        -- waehrend des Ladebildschirms). Dann eben hier nachladen.
        local err
        row, err = fetchOrCreate(license, GetPlayerIdentifierByType(src, 'fivem'), GetPlayerName(src))
        if not row then
            return false, ('Spielerdaten konnten nicht geladen werden (%s).'):format(err or 'unbekannt')
        end
    end

    sessions[src] = {
        source = src,
        license = license,
        fivemId = GetPlayerIdentifierByType(src, 'fivem'),
        name = GetPlayerName(src),
        -- Gesamtspielzeit aus der DB; die laufende Sitzung kommt beim Save dazu.
        playtime = row.playtime_seconds or 0,
        joinedAt = os.time(),
    }

    print(('[core] Spieler geladen: %s (%d)'):format(sessions[src].name or '?', src))
    return true, nil
end

function Players.Get(src)
    return sessions[src]
end

function Players.GetByLicense(license)
    for _, session in pairs(sessions) do
        if session.license == license then return session end
    end
    return nil
end

function Players.GetAll()
    local list = {}
    for _, session in pairs(sessions) do
        list[#list + 1] = session
    end
    return list
end

--- Schreibt die Sitzung in die Datenbank. Die Spielzeit wird dabei
--- fortgeschrieben und der Zaehler zurueckgesetzt, damit ein zweiter Save
--- dieselbe Zeit nicht doppelt addiert.
function Players.Save(src)
    local session = sessions[src]
    if not session then return false end
    if not Database.ready then return false end

    local now = os.time()
    session.playtime = session.playtime + (now - session.joinedAt)
    session.joinedAt = now
    session.name = GetPlayerName(src) or session.name

    local _, err = Database.Execute(
        'UPDATE players SET name = ?, fivem_id = ?, last_seen = NOW(), playtime_seconds = ? WHERE license = ?',
        { session.name, session.fivemId, session.playtime, session.license }
    )
    if err then
        print(('[core] Speichern fehlgeschlagen fuer %s (%s)'):format(session.name or '?', session.license))
        return false
    end

    Database.Debug(('gespeichert: %s (%ds Spielzeit)'):format(session.name or '?', session.playtime))
    TriggerEvent('core:playerSaved', src)
    return true
end

--- @return number  Anzahl erfolgreich gespeicherter Sitzungen
function Players.SaveAll()
    local saved = 0
    for src in pairs(sessions) do
        if Players.Save(src) then saved = saved + 1 end
    end
    return saved
end

function Players.EndSession(src)
    sessions[src] = nil
end
