Config = {}

-- Autosave-Intervall in Sekunden. Schuetzt den Fortschritt bei einem Absturz,
-- bei dem weder playerDropped noch onResourceStop feuern.
Config.AutosaveInterval = 300

-- Wenn true, kommt bei nicht erreichbarer Datenbank niemand auf den Server.
-- Bewusst der Default: lieber kein Spiel als ein Spiel ohne Speicherstand, das
-- beim naechsten Save den echten Fortschritt ueberschreibt.
Config.RejectWithoutDatabase = true

-- Beim Serverstart braucht oxmysql selbst ein paar Sekunden bis zur Verbindung.
-- Der Core versucht es deshalb mehrfach, bevor er aufgibt. Gibt er auf, hilft
-- nach dem Beheben der Ursache ein "restart core" in der Server-Konsole.
Config.DatabaseRetries = 10
Config.DatabaseRetryDelay = 3

-- Ausfuehrlichere Konsolenausgaben (jeder Ladevorgang, jeder Save).
Config.Debug = false
