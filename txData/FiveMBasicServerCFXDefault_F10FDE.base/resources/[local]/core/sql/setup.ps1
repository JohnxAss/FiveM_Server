# Core - einmaliges Datenbank-Setup
#
# Legt Datenbank und Benutzer an, spielt das Schema ein und traegt den
# Verbindungsstring in die server.cfg ein.
#
# Ausfuehren in einem PowerShell-Fenster:
#   powershell -ExecutionPolicy Bypass -File setup.ps1
#
# Das Passwort fuer den Datenbank-Benutzer "fivem" wird per Default erzeugt und
# direkt in die server.cfg geschrieben - man muss es sich nicht merken. Wer ein
# eigenes will: -FivemPassword "..." (Zeichensatz beachten, siehe unten).

param(
    [string]$FivemPassword
)

$ErrorActionPreference = 'Stop'

$sqlDir    = $PSScriptRoot
$serverCfg = [System.IO.Path]::GetFullPath((Join-Path $sqlDir '..\..\..\..\server.cfg'))

# oxmysql parst den Verbindungsstring selbst (parseUri in dist/build.js) und
# dekodiert dabei KEIN URL-Encoding - es splittet stumpf an ":" und "@".
# Ein Passwort mit @ : / ? # & ; = % oder Leerzeichen zerlegt den String also
# still und leise, mit einer nichtssagenden Auth-Fehlermeldung als Folge.
# Deshalb hier bewusst nur unkritische Zeichen.
$SAFE_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.'

# --- mysql.exe finden -------------------------------------------------------
$mysql = Get-ChildItem 'C:\Program Files\MariaDB*\bin\mysql.exe' -ErrorAction SilentlyContinue |
         Select-Object -First 1 -ExpandProperty FullName
if (-not $mysql) {
    $mysql = (Get-Command mysql -ErrorAction SilentlyContinue).Source
}
if (-not $mysql) {
    Write-Host 'mysql.exe nicht gefunden. Ist MariaDB installiert?' -ForegroundColor Red
    exit 1
}
Write-Host "Client: $mysql"

# --- Passwort fuer den Benutzer "fivem" -------------------------------------
$generated = $false
if ([string]::IsNullOrWhiteSpace($FivemPassword)) {
    $bytes = [byte[]]::new(32)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $FivemPassword = -join ($bytes | ForEach-Object { $SAFE_CHARS[$_ % $SAFE_CHARS.Length] })
    $generated = $true
} else {
    $bad = ($FivemPassword.ToCharArray() | Where-Object { $SAFE_CHARS.IndexOf($_) -lt 0 }) -join ''
    if ($bad) {
        Write-Host "Diese Zeichen kann oxmysql im Verbindungsstring nicht verarbeiten: $bad" -ForegroundColor Red
        Write-Host "Erlaubt sind Buchstaben, Ziffern und - _ ." -ForegroundColor Red
        exit 1
    }
}

# --- root-Passwort abfragen -------------------------------------------------
$secure = Read-Host -Prompt 'MariaDB root-Passwort (bei der Installation gesetzt)' -AsSecureString
$bstr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try   { $rootPw = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }

# --- Datenbank und Benutzer anlegen ----------------------------------------
# Passwort nicht per -p uebergeben, sonst steht es in der Prozessliste.
$env:MYSQL_PWD = $rootPw

$create = @(
    "CREATE DATABASE IF NOT EXISTS ``fivem`` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;",
    "CREATE USER IF NOT EXISTS 'fivem'@'localhost' IDENTIFIED BY '$FivemPassword';",
    "ALTER USER 'fivem'@'localhost' IDENTIFIED BY '$FivemPassword';",
    "GRANT ALL PRIVILEGES ON ``fivem``.* TO 'fivem'@'localhost';",
    "FLUSH PRIVILEGES;"
) -join ' '

Write-Host 'Lege Datenbank und Benutzer an...'
$create | & $mysql -u root
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Fehlgeschlagen - stimmt das root-Passwort?' -ForegroundColor Red
    exit 1
}

# --- Schema einspielen ------------------------------------------------------
foreach ($file in (Get-ChildItem -LiteralPath $sqlDir -Filter '0*.sql' | Sort-Object Name)) {
    # 000 legt Datenbank/Benutzer an, das haben wir oben schon erledigt.
    if ($file.Name -like '000_*') { continue }
    Write-Host "Spiele ein: $($file.Name)"
    Get-Content -LiteralPath $file.FullName -Raw | & $mysql -u root fivem
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Fehler in $($file.Name)" -ForegroundColor Red
        exit 1
    }
}

# --- Gegenprobe mit den echten Zugangsdaten --------------------------------
# Wichtig: nicht als root pruefen. Nur so faellt auf, wenn der Benutzer "fivem"
# selbst nicht durchkommt - genau der landet naemlich in der server.cfg.
$env:MYSQL_PWD = $FivemPassword
Write-Host 'Pruefe Zugang als Benutzer "fivem"...'
'SELECT COUNT(*) FROM players;' | & $mysql -u fivem fivem | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Der Benutzer "fivem" kommt nicht an die Tabelle.' -ForegroundColor Red
    exit 1
}
$env:MYSQL_PWD = $null

# --- server.cfg eintragen ---------------------------------------------------
$newLine = 'set mysql_connection_string "mysql://fivem:' + $FivemPassword + '@localhost/fivem?charset=utf8mb4"'

if (-not (Test-Path -LiteralPath $serverCfg)) {
    Write-Host "server.cfg nicht gefunden unter $serverCfg" -ForegroundColor Yellow
    Write-Host 'Bitte selbst eintragen:'
    Write-Host "  $newLine"
    exit 0
}

$cfg = Get-Content -LiteralPath $serverCfg -Raw
if ($cfg -match '(?m)^set mysql_connection_string .*$') {
    # MatchEvaluator statt -replace: im Ersetzungstext waeren $ und \ sonst
    # Sonderzeichen und wuerden das Passwort verstuemmeln.
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $newLine }
    $cfg = [regex]::Replace($cfg, '(?m)^set mysql_connection_string .*$', $evaluator)
    Set-Content -LiteralPath $serverCfg -Value $cfg -NoNewline
    Write-Host 'server.cfg: Verbindungsstring eingetragen.' -ForegroundColor Green
} else {
    Write-Host 'In der server.cfg steht keine Zeile "set mysql_connection_string".' -ForegroundColor Yellow
    Write-Host 'Bitte selbst ergaenzen:'
    Write-Host "  $newLine"
}

Write-Host ''
if ($generated) {
    Write-Host 'Das Passwort fuer den DB-Benutzer wurde erzeugt und steht in der server.cfg.'
    Write-Host 'Die ist gitignored - es verlaesst den Rechner nicht.'
}
Write-Host 'Fertig. Server starten, erwartete Zeile in der Konsole:' -ForegroundColor Green
Write-Host '  [core] Datenbank verbunden, Schema vollstaendig.'
