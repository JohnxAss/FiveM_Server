Config = {}

-- ACE-Berechtigung, die ein Spieler braucht. Vergabe in der server.cfg:
--   add_ace group.admin basicadmin allow
Config.AcePermission = 'basicadmin'

-- Abstand in Metern, in dem das Fahrzeug vor dem Spieler erscheint.
Config.SpawnDistance = 3.0

-- Mindestabstand zwischen zwei Aktionen desselben Spielers (Sekunden), gegen Event-Spam.
Config.Cooldown = 1.0

-- Fahrzeugkatalog. Dient gleichzeitig als serverseitige Whitelist:
-- gespawnt wird nur, was hier eingetragen ist.
Config.Vehicles = {
    {
        category = 'Sportwagen',
        vehicles = {
            { model = 'adder',    label = 'Adder' },
            { model = 'zentorno', label = 'Zentorno' },
            { model = 't20',      label = 'T20' },
            { model = 'italigtb', label = 'Itali GTB' },
            { model = 'ninef',    label = '9F' },
            { model = 'comet2',   label = 'Comet' },
            { model = 'banshee',  label = 'Banshee' },
            { model = 'elegy2',   label = 'Elegy Retro' },
            { model = 'sultan',   label = 'Sultan' },
            { model = 'futo',     label = 'Futo' },
        },
    },
    {
        category = 'Limousinen & Alltag',
        vehicles = {
            { model = 'schafter2', label = 'Schafter' },
            { model = 'oracle2',   label = 'Oracle' },
            { model = 'tailgater', label = 'Tailgater' },
            { model = 'premier',   label = 'Premier' },
            { model = 'blista',    label = 'Blista' },
            { model = 'washington',label = 'Washington' },
        },
    },
    {
        category = 'Gelaendewagen & Offroad',
        vehicles = {
            { model = 'dubsta3',   label = 'Dubsta 6x6' },
            { model = 'sandking',  label = 'Sandking' },
            { model = 'rebel2',    label = 'Rebel' },
            { model = 'bfinjection', label = 'BF Injection' },
            { model = 'baller',    label = 'Baller' },
            { model = 'granger',   label = 'Granger' },
        },
    },
    {
        category = 'Motorraeder',
        vehicles = {
            { model = 'sanchez',   label = 'Sanchez' },
            { model = 'bati',      label = 'Bati 801' },
            { model = 'akuma',     label = 'Akuma' },
            { model = 'hakuchou',  label = 'Hakuchou' },
            { model = 'pcj',       label = 'PCJ 600' },
            { model = 'bmx',       label = 'BMX (Fahrrad)' },
        },
    },
    {
        category = 'Einsatzfahrzeuge',
        vehicles = {
            { model = 'police',    label = 'Police Cruiser' },
            { model = 'police2',   label = 'Police Buffalo' },
            { model = 'police3',   label = 'Police Interceptor' },
            { model = 'policeb',   label = 'Police Bike' },
            { model = 'sheriff',   label = 'Sheriff Cruiser' },
            { model = 'ambulance', label = 'Ambulance' },
            { model = 'firetruk',  label = 'Fire Truck' },
            { model = 'riot',      label = 'Police Riot' },
        },
    },
    {
        category = 'Luftfahrzeuge',
        vehicles = {
            { model = 'buzzard',   label = 'Buzzard' },
            { model = 'maverick',  label = 'Maverick' },
            { model = 'frogger',   label = 'Frogger' },
            { model = 'lazer',     label = 'P-996 Lazer' },
            { model = 'cuban800',  label = 'Cuban 800' },
            { model = 'dodo',      label = 'Dodo' },
        },
    },
    {
        category = 'Nutzfahrzeuge',
        vehicles = {
            { model = 'bus',       label = 'Bus' },
            { model = 'taxi',      label = 'Taxi' },
            { model = 'phantom',   label = 'Phantom (Sattelzug)' },
            { model = 'mule',      label = 'Mule' },
            { model = 'bulldozer', label = 'Bulldozer' },
            { model = 'trash',     label = 'Trashmaster' },
        },
    },
    {
        category = 'Boote',
        vehicles = {
            { model = 'dinghy',    label = 'Dinghy' },
            { model = 'jetmax',    label = 'Jetmax' },
            { model = 'seashark',  label = 'Seashark' },
            { model = 'marquis',   label = 'Marquis' },
        },
    },
}

--- Prueft, ob ein Modellname im Katalog steht (Whitelist-Check).
-- @param model string
-- @return boolean
function Config.IsVehicleAllowed(model)
    if type(model) ~= 'string' then return false end
    model = model:lower()
    for _, group in ipairs(Config.Vehicles) do
        for _, vehicle in ipairs(group.vehicles) do
            if vehicle.model:lower() == model then
                return true
            end
        end
    end
    return false
end
