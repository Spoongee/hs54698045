@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
set "APP_TITLE=// MOD INSTALLER :: TrX //"
title %APP_TITLE%

set "REPO_OWNER=Spoongee"
set "REPO_NAME=hs54698045"
set "BRANCH=main"
set "SCRIPT_NAME=install.bat"
set "PACK_DIR=pack"
set "MANAGED=options.txt mods config resourcepacks shaderpacks"
set "PRUNE=1"
set "CONFIGS=options.txt config"

set "WORK=%TEMP%\mc_installer"
if not exist "%WORK%\" mkdir "%WORK%"

for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "cY=%ESC%[93m"
set "cC=%ESC%[96m"
set "cM=%ESC%[95m"
set "cR=%ESC%[91m"
set "cG=%ESC%[92m"
set "cD=%ESC%[90m"
set "cW=%ESC%[97m"
set "cX=%ESC%[0m"

set "SELF_BAT=%~f0"
set "UI_FAST="
if /i "%~1"=="--updated" set "UI_FAST=1"
set "UI_MODE=boot"
call :ps

if /i "%REPO_OWNER%"=="TWOJ_LOGIN_GITHUB" (
    echo   %cR%[FAIL]%cX% Nie skonfigurowano repozytorium GitHub.
    echo         %cD%Edytuj poczatek pliku install.bat i ustaw REPO_OWNER oraz REPO_NAME.%cX%
    call :wait
    exit /b 1
)

echo   %cM%[ ^>^> ]%cX% Skanowanie repozytorium...
call :getsha

if defined REMOTE_SHA (
    set "REF=!REMOTE_SHA!"
    set "ZIP_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/archive/!REMOTE_SHA!.zip"
    echo   %cG%[ OK ]%cX% Najnowszy commit w repo: %cY%!REMOTE_SHA:~0,7!%cX%
) else (
    set "REF=%BRANCH%"
    set "ZIP_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/archive/refs/heads/%BRANCH%.zip"
    echo   %cY%[WARN]%cX% Nie mozna odczytac najnowszego commita. Uzywam brancha %BRANCH%.
)
echo.

set "RAW_URL=https://raw.githubusercontent.com/%REPO_OWNER%/%REPO_NAME%/!REF!"

if /i "%~1"=="--updated" (
    if exist "%WORK%\install.bat.new" (
        echo   %cR%[FAIL]%cX% Nie udalo sie podmienic pliku instalatora. Uruchom instalator ponownie.
    ) else (
        echo   %cG%[ OK ]%cX% Instalator zaktualizowany do najnowszej wersji.
    )
    echo.
    goto :after_selfupdate
)

set "NEW_SCRIPT=%WORK%\install.bat.new"
if exist "%NEW_SCRIPT%" del /f /q "%NEW_SCRIPT%"

call :download "%RAW_URL%/%SCRIPT_NAME%?cb=%RANDOM%%RANDOM%" "%NEW_SCRIPT%" "SYNC INSTALATORA"
if errorlevel 1 (
    echo   %cY%[WARN]%cX% Nie mozna sprawdzic aktualizacji instalatora. Kontynuuje z obecna wersja.
    echo.
    goto :after_selfupdate
)

set "FIX_FILE=%NEW_SCRIPT%"
set "UI_MODE=fixcrlf"
call :ps

findstr /b /c:"@echo off" "%NEW_SCRIPT%" >nul
if errorlevel 1 (
    echo   %cY%[WARN]%cX% Pobrany plik instalatora jest nieprawidlowy. Pomijam aktualizacje.
    echo.
    goto :after_selfupdate
)
findstr /b /c:"#PS_BEG" "%NEW_SCRIPT%" >nul
if errorlevel 1 (
    echo   %cY%[WARN]%cX% Pobrany plik instalatora jest niekompletny. Pomijam aktualizacje.
    echo.
    goto :after_selfupdate
)

set "HASH_A="
set "HASH_B="
call :filehash "%~f0" HASH_A
call :filehash "%NEW_SCRIPT%" HASH_B

if /i "!HASH_A!"=="!HASH_B!" (
    echo   %cG%[ OK ]%cX% Instalator jest aktualny. %cD%[!HASH_A:~0,7!]%cX%
    echo.
    goto :after_selfupdate
)

echo   %cM%[ ^>^> ]%cX% Wykryto nowa wersje instalatora %cD%[!HASH_A:~0,7! -^> !HASH_B:~0,7!]%cX% Aktualizacja i restart...
set "HELPER=%WORK%\update_helper.bat"
>"%HELPER%" echo @echo off
>>"%HELPER%" echo set n=0
>>"%HELPER%" echo :retry
>>"%HELPER%" echo timeout /t 1 /nobreak ^>nul
>>"%HELPER%" echo move /y "%NEW_SCRIPT%" "%~f0" ^>nul 2^>nul ^&^& goto ok
>>"%HELPER%" echo set /a n+=1
>>"%HELPER%" echo if %%n%% lss 10 goto retry
>>"%HELPER%" echo :ok
>>"%HELPER%" echo start "" "%~f0" --updated
start "" /min "%HELPER%"
exit /b 0

:after_selfupdate

set "DOCS="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')"`) do set "DOCS=%%I"
if not defined DOCS set "DOCS=%USERPROFILE%\Documents"

set "CFG_DIR=%DOCS%\InstalatorModowMinecraft"
set "CFG_FILE=%CFG_DIR%\sciezka_gry.txt"
set "SHA_FILE=%CFG_DIR%\wersja_paczki.txt"
set "CFGVER_FILE=%CFG_DIR%\wersja_configow.txt"

set "GAME="
set "REASK="
set "REASK_OK="
if exist "%CFG_FILE%" (
    set /p "GAME=" < "%CFG_FILE%"
)
if defined GAME set "REASK_OK=1"

if defined GAME (
    if exist "!GAME!\" (
        echo   %cG%[ OK ]%cX% Wczytano zapisana sciezke gry.
        echo         %cD%!CFG_FILE!%cX%
        goto :path_ok
    ) else (
        echo   %cY%[WARN]%cX% Zapisana sciezka juz nie istnieje: !GAME!
        echo.
    )
) else (
    echo   %cY%[WARN]%cX% Brak zapisanej sciezki do gry. Podaj ja recznie.
    echo.
)

:ask_path
set "GAME="
if defined REASK (
    set /p "GAME=%cX%  %cM%[ ?? ]%cX% Nowa sciezka do gry %cD%(Enter = anuluj)%cX% %cC%>%cX% "
) else (
    set /p "GAME=%cX%  %cM%[ ?? ]%cX% Sciezka do folderu z gra %cC%>%cX% "
)
set "GAME=%GAME:"=%"
if not defined GAME (
    if defined REASK (
        echo.
        echo   %cY%[WARN]%cX% Anulowano.
        call :wait
        exit /b 0
    )
    goto :ask_path
)
if "%GAME:~-1%"=="\" set "GAME=%GAME:~0,-1%"

if not exist "%GAME%\" (
    echo.
    echo   %cR%[FAIL]%cX% Taki folder nie istnieje: !GAME!
    echo.
    goto :ask_path
)

if not exist "%CFG_DIR%\" mkdir "%CFG_DIR%"
>"%CFG_FILE%" (echo !GAME!)
if errorlevel 1 (
    echo   %cY%[WARN]%cX% Nie udalo sie zapisac sciezki do pliku.
) else (
    echo   %cG%[ OK ]%cX% Zapisano sciezke do pliku:
    echo         %cD%!CFG_FILE!%cX%
)

:path_ok
if not exist "%CFG_DIR%\" mkdir "%CFG_DIR%"


set "LOCAL_SHA="
if exist "%SHA_FILE%" set /p "LOCAL_SHA=" < "%SHA_FILE%"

set "CFG_LOCAL="
if exist "%CFGVER_FILE%" set /p "CFG_LOCAL=" < "%CFGVER_FILE%"
set "CFG_LEGACY="
if exist "%SHA_FILE%" set "CFG_LEGACY=1"
if not defined CFG_DONE (
    call :getver
    set "CFG_DONE=1"
)

echo.
echo   %cD%----------------------------------------------------------%cX%
echo   %cC%CEL    %cD%:%cX% !GAME!
echo   %cC%REPO   %cD%:%cX% %REPO_OWNER%/%REPO_NAME% %cD%[%BRANCH%]%cX%

if not defined REMOTE_SHA (
    echo   %cC%STATUS %cD%:%cX% %cY%nieznany%cX%
    echo   %cD%----------------------------------------------------------%cX%
    echo   %cY%[WARN]%cX% Nie mozna sprawdzic wersji paczki. Zostanie pobrana najnowsza z repo.
) else (
    if /i "!REMOTE_SHA!"=="!LOCAL_SHA!" (
        echo   %cC%STATUS %cD%:%cX% %cG%aktualny%cX% %cD%[!REMOTE_SHA:~0,7!]%cX%
        echo   %cD%----------------------------------------------------------%cX%
        echo   %cG%[ OK ]%cX% Masz juz najnowsza wersje paczki.
        echo         %cD%Zweryfikuje jednak checksum kazdego pliku w folderze gry.%cX%
    ) else (
        if defined LOCAL_SHA (
            echo   %cC%STATUS %cD%:%cX% %cM%dostepna aktualizacja%cX% %cD%[!LOCAL_SHA:~0,7!%cX% -^> %cY%!REMOTE_SHA:~0,7!%cD%]%cX%
        ) else (
            echo   %cC%STATUS %cD%:%cX% %cM%nowa instalacja%cX% %cD%[!REMOTE_SHA:~0,7!]%cX%
        )
        echo   %cD%----------------------------------------------------------%cX%
    )
)

if "!CFG_OVERWRITE!"=="1" (
    if defined CFG_LOCAL (
        echo   %cC%KONFIG %cD%:%cX% %cM%nowa wersja%cX% %cD%[!CFG_LOCAL! -^> !CFG_REMOTE!]%cX% - zostana podmienione
    ) else (
        echo   %cC%KONFIG %cD%:%cX% %cM%instalacja%cX% - zostana wgrane domyslne
    )
) else if defined CFG_REMOTE (
    echo   %cC%KONFIG %cD%:%cX% %cG%bez zmian%cX% %cD%[v!CFG_REMOTE!]%cX% - Twoje zostaja, dodam tylko brakujace
) else (
    echo   %cC%KONFIG %cD%:%cX% %cY%nieznane%cX% - Twoje zostaja, dodam tylko brakujace
)

echo.
set "PLAN_FILE=%WORK%\plan.json"
set "STAGE=%WORK%\stage"
set "ZIP_SRC="
set "NEED_ZIP="
call :cleanup

echo   %cM%[ ^>^> ]%cX% Sprawdzanie plikow w repozytorium...
set "UI_MODE=plan"
call :ps
set "PLAN_RC=!PS_RC!"

if "!PLAN_RC!"=="3" (
    echo   %cY%[WARN]%cX% Nie mozna pobrac listy plikow z GitHub API. Porownuje z pobranym archiwum.
    call :fetch_zip
    if errorlevel 1 (
        call :wait
        exit /b 1
    )
    set "ZIP_SRC=!SRC!"
    set "UI_MODE=plan"
    call :ps
    set "PLAN_RC=!PS_RC!"
)

if "!PLAN_RC!"=="2" goto :uptodate
if "!PLAN_RC!"=="4" (
    set "NEED_ZIP=1"
    set "PLAN_RC=0"
)
if not "!PLAN_RC!"=="0" (
    echo   %cR%[FAIL]%cX% Nie udalo sie porownac plikow z repozytorium.
    call :wait
    exit /b 1
)

echo.
echo   %cR%[WARN]%cX% Zmienione zostana tylko pliki z listy powyzej:
echo         %cD%NEW = nowy, UPD = zmieniony, DEL = usuniety%cX%
if defined REASK_OK echo         %cD%Wpisz N, aby podac inna sciezke gry.%cX%
echo.
set "OK="
set /p "OK=%cX%  %cM%[ ?? ]%cX% Kontynuowac? %cD%(T/N)%cX% %cC%>%cX% "
if /i not "%OK%"=="T" (
    if defined REASK_OK (
        echo.
        echo   %cM%[ ^>^> ]%cX% Podaj inna sciezke do gry. Pusty Enter anuluje.
        echo.
        set "REASK=1"
        goto :ask_path
    )
    echo.
    echo   %cY%[WARN]%cX% Anulowano.
    call :cleanup
    call :wait
    exit /b 0
)

echo.
if defined NEED_ZIP (
    echo   %cM%[ ^>^> ]%cX% Duzo plikow do pobrania - pobieram cale archiwum zamiast pojedynczych plikow.
    call :fetch_zip
    if errorlevel 1 (
        call :wait
        exit /b 1
    )
    set "ZIP_SRC=!SRC!"
)

set "UI_MODE=sync"
call :ps
if errorlevel 1 (
    echo.
    echo   %cR%[FAIL]%cX% Synchronizacja nie powiodla sie.
    echo         %cD%Uruchom instalator ponownie - dokonczy tylko brakujace pliki.%cX%
    call :cleanup
    call :wait
    exit /b 1
)

if defined REMOTE_SHA >"%SHA_FILE%" (echo !REMOTE_SHA!)
if defined CFG_REMOTE >"%CFGVER_FILE%" (echo !CFG_REMOTE!)

call :cleanup

set "UI_MODE=done"
call :ps
call :wait
endlocal
exit /b 0

:uptodate
echo.
echo   %cG%[ OK ]%cX% Wszystkie pliki sa zgodne z repozytorium. Nic do pobrania.
if defined REMOTE_SHA >"%SHA_FILE%" (echo !REMOTE_SHA!)
if defined CFG_REMOTE >"%CFGVER_FILE%" (echo !CFG_REMOTE!)
call :cleanup
call :wait
endlocal
exit /b 0

:cleanup
if exist "%WORK%\repo.zip" del /f /q "%WORK%\repo.zip"
if exist "%WORK%\extract\" rd /s /q "%WORK%\extract"
if exist "%WORK%\stage\" rd /s /q "%WORK%\stage"
if exist "%WORK%\plan.json" del /f /q "%WORK%\plan.json"
exit /b 0

:fetch_zip
set "PACK_ZIP=%WORK%\repo.zip"
set "EXTRACT=%WORK%\extract"
if exist "%PACK_ZIP%" del /f /q "%PACK_ZIP%"
if exist "%EXTRACT%\" rd /s /q "%EXTRACT%"

call :download "!ZIP_URL!" "%PACK_ZIP%" "POBIERANIE PACZKI"
if errorlevel 1 (
    echo   %cR%[FAIL]%cX% Nie udalo sie pobrac paczki. Sprawdz internet oraz czy repozytorium jest publiczne.
    echo         %cD%Pliki w folderze gry NIE zostaly zmienione.%cX%
    exit /b 1
)

echo   %cM%[ ^>^> ]%cX% Rozpakowywanie archiwum...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory($env:PACK_ZIP, $env:EXTRACT)"
if errorlevel 1 (
    echo   %cR%[FAIL]%cX% Nie udalo sie rozpakowac pobranego archiwum.
    echo         %cD%Pliki w folderze gry NIE zostaly zmienione.%cX%
    exit /b 1
)

set "REPO_ROOT="
for /d %%R in ("%EXTRACT%\*") do set "REPO_ROOT=%%~fR"
if not defined REPO_ROOT (
    echo   %cR%[FAIL]%cX% Pobrane archiwum jest puste.
    exit /b 1
)

if defined PACK_DIR (
    set "SRC=!REPO_ROOT!\%PACK_DIR%"
) else (
    set "SRC=!REPO_ROOT!"
)

if not exist "!SRC!\" (
    echo   %cR%[FAIL]%cX% W repozytorium nie znaleziono folderu: %PACK_DIR%
    exit /b 1
)
echo   %cG%[ OK ]%cX% Archiwum gotowe.
exit /b 0

:download
set "DL_URL=%~1"
set "DL_OUT=%~2"
set "UI_LABEL=%~3"
set "UI_MODE=download"
call :ps
exit /b %errorlevel%

:getsha
set "REMOTE_SHA="
set "UI_MODE=sha"
for /f "usebackq delims=" %%S in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SELF_BAT); iex $s.Substring($s.IndexOf('#PS_'+'BEGIN'))"`) do set "REMOTE_SHA=%%S"
title %APP_TITLE%
exit /b 0

:getver
set "CFG_REMOTE="
set "CFG_OVERWRITE=0"
set "UI_MODE=ver"
for /f "usebackq tokens=1,2" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SELF_BAT); iex $s.Substring($s.IndexOf('#PS_'+'BEGIN'))"`) do (
    if not "%%A"=="-" set "CFG_REMOTE=%%A"
    set "CFG_OVERWRITE=%%B"
)
title %APP_TITLE%
exit /b 0

:ps
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SELF_BAT); iex $s.Substring($s.IndexOf('#PS_'+'BEGIN'))"
set "PS_RC=%errorlevel%"
title %APP_TITLE%
exit /b %PS_RC%

:filehash
set "HF=%~1"
for /f "usebackq delims=" %%H in (`powershell -NoProfile -Command "(Get-FileHash -LiteralPath $env:HF -Algorithm SHA256).Hash"`) do set "%~2=%%H"
exit /b 0

:wait
echo.
echo   %cD%Nacisnij dowolny klawisz, aby zamknac...%cX%
pause >nul
exit /b 0

#PS_BEGIN
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
try { [Net.ServicePointManager]::DefaultConnectionLimit = 16 } catch {}

$BLK = [string][char]0x2588
$DIM = [string][char]0x2591
$W = 58
$BAR = '+' + ('=' * ($W - 2)) + '+'
$global:pos = 0
$global:dir = 1

function Put($t, $c = 'Gray') { Write-Host $t -NoNewline -ForegroundColor $c }
function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c }
function Wipe { [Console]::Write("`r" + (' ' * 79) + "`r") }

function Typed($t, $c = 'Cyan', $ms = 8) {
    foreach ($ch in $t.ToCharArray()) { Put ([string]$ch) $c; Start-Sleep -Milliseconds $ms }
}

function Center($t) {
    $n = $W - 2
    $l = [int](($n + $t.Length) / 2)
    return '|' + $t.PadLeft($l).PadRight($n) + '|'
}

function Glitch($t, $c = 'Yellow') {
    $pool = '#@$%&*+=<>?/|0123456789ABCDEF'.ToCharArray()
    $r = New-Object System.Random
    for ($k = 0; $k -le $t.Length; $k++) {
        $n = [Math]::Min(5, $t.Length - $k)
        $noise = ''
        for ($j = 0; $j -lt $n; $j++) { $noise += $pool[$r.Next($pool.Length)] }
        [Console]::Write("`r")
        Put '  '
        Put $t.Substring(0, $k) $c
        Put $noise 'Magenta'
        Put '    '
        Start-Sleep -Milliseconds 22
    }
    [Console]::Write("`r")
    Put '  '
    Put $t $c
    Say ''
}

function Frame($label, $extra) {
    $width = 22
    $seg = 5
    [Console]::Write("`r")
    Put '  [ >> ] ' 'Cyan'
    Put $label 'White'
    Put '[' 'DarkCyan'
    Put ($DIM * $global:pos) 'DarkGray'
    Put ($BLK * $seg) 'Yellow'
    Put ($DIM * ($width - $seg - $global:pos)) 'DarkGray'
    Put ']' 'DarkCyan'
    Put (' ' + $extra + '   ') 'Magenta'
    $global:pos += $global:dir
    if ($global:pos -ge ($width - $seg)) { $global:dir = -1 } elseif ($global:pos -le 0) { $global:dir = 1 }
}

$SEP = [string][IO.Path]::DirectorySeparatorChar
$MAXP = 6
$CFGS = @($env:CONFIGS -split '\s+' | Where-Object { $_ })

function IsCfg($p) {
    foreach ($c in $CFGS) {
        if ($p -ieq $c -or $p.StartsWith($c + '/', [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function GitBlobSha($path) {
    $h = [Security.Cryptography.SHA1]::Create()
    $fs = $null
    try {
        $fs = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $hdr = [Text.Encoding]::ASCII.GetBytes(('blob {0}' -f $fs.Length) + [string][char]0)
        [void]$h.TransformBlock($hdr, 0, $hdr.Length, $null, 0)
        $buf = New-Object byte[] 4194304
        while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) { [void]$h.TransformBlock($buf, 0, $n, $null, 0) }
        [void]$h.TransformFinalBlock($buf, 0, 0)
        return ([BitConverter]::ToString($h.Hash).Replace('-', '').ToLower())
    } catch {
        return ''
    } finally {
        if ($fs) { $fs.Dispose() }
        $h.Dispose()
    }
}

function Prop($o, $k) {
    if ($o -is [System.Collections.IDictionary]) {
        try { return $o[$k] } catch { return $null }
    }
    return $o.$k
}

function LocalPath($root, $rel) { return (Join-Path $root $rel.Replace('/', $SEP)) }

function UrlPath($rel) { return ((($rel -split '/') | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/') }

function Mb($x) { return ('{0:N1} MB' -f ($x / 1MB)) }

function ListItems($tag, $color, $names) {
    $names = @($names)
    $max = 12
    $lim = [Math]::Min($max, $names.Count)
    for ($k = 0; $k -lt $lim; $k++) {
        Put ('  [ {0} ] ' -f $tag) $color
        Say $names[$k] 'Gray'
    }
    if ($names.Count -gt $max) { Say ('           ... i {0} wiecej' -f ($names.Count - $max)) 'DarkGray' }
}

switch ($env:UI_MODE) {

    'sha' {
        $o = $env:REPO_OWNER; $n = $env:REPO_NAME; $b = $env:BRANCH
        $sha = ''
        try {
            $u = 'https://github.com/{0}/{1}.git/info/refs?service=git-upload-pack' -f $o, $n
            $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers @{ 'User-Agent' = 'git/2.43.0'; 'Cache-Control' = 'no-cache' } -ErrorAction Stop
            $c = $r.Content
            if ($c -is [byte[]]) { $c = [Text.Encoding]::ASCII.GetString($c) }
            $m = [regex]::Match($c, '([0-9a-f]{40}) refs/heads/' + [regex]::Escape($b) + '(?=[\x00\r\n])')
            if ($m.Success) { $sha = $m.Groups[1].Value }
        } catch {}
        if (-not $sha) {
            try {
                $u = 'https://api.github.com/repos/{0}/{1}/commits/{2}?cb={3}' -f $o, $n, $b, (Get-Random)
                $sha = (Invoke-RestMethod -UseBasicParsing -Uri $u -Headers @{ Accept = 'application/vnd.github.sha'; 'User-Agent' = 'mc-installer'; 'Cache-Control' = 'no-cache' } -ErrorAction Stop).ToString().Trim()
            } catch {}
        }
        if ($sha -match '^[0-9a-f]{40}$') { Write-Output $sha }
    }

    'ver' {
        $remote = $null
        try {
            $u = '{0}/.versionpck?cb={1}' -f $env:RAW_URL, (Get-Random)
            $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers @{ 'User-Agent' = 'mc-installer'; 'Cache-Control' = 'no-cache' } -ErrorAction Stop
            $c = $r.Content
            if ($c -is [byte[]]) { $c = [Text.Encoding]::UTF8.GetString($c) }
            $c = ([string]$c).TrimStart([char]0xFEFF)
            $m = [regex]::Match($c, '(?im)^\s*config\s*=\s*(\d+)\s*$')
            if ($m.Success) { $remote = [int64]$m.Groups[1].Value }
        } catch {}
        if ($null -eq $remote) { Write-Output '- 0'; break }
        $local = $null
        $lt = ([string]$env:CFG_LOCAL).Trim()
        if ($lt -match '^\d+$') { $local = [int64]$lt }
        $ow = 0
        if ($null -eq $local) { if ($env:CFG_LEGACY -ne '1') { $ow = 1 } }
        elseif ($remote -gt $local) { $ow = 1 }
        Write-Output ('{0} {1}' -f $remote, $ow)
    }

    'fixcrlf' {
        $f = $env:FIX_FILE
        $t = [IO.File]::ReadAllText($f).TrimStart([char]0xFEFF)
        $t = $t -replace "`r`n", "`n" -replace "`r", "`n" -replace "`n", "`r`n"
        [IO.File]::WriteAllText($f, $t, (New-Object Text.UTF8Encoding($false)))
    }

    'boot' {
        try {
            Add-Type -Namespace Nx -Name Vt -MemberDefinition '[DllImport("kernel32.dll")] public static extern System.IntPtr GetStdHandle(int n); [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(System.IntPtr h, out int m); [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(System.IntPtr h, int m);'
            $h = [Nx.Vt]::GetStdHandle(-11)
            $m = 0
            if ([Nx.Vt]::GetConsoleMode($h, [ref]$m)) { [void][Nx.Vt]::SetConsoleMode($h, $m -bor 4) }
        } catch {}

        Say ''
        Say "  $BAR" 'Cyan'
        $title = Center 'MINECRAFT MOD INSTALLER  //  TrX'
        if ($env:UI_FAST) { Say "  $title" 'Yellow' } else { Glitch $title 'Yellow' }
        Say "  $BAR" 'Cyan'
        Say ''

        if (-not $env:UI_FAST) {
            foreach ($b in @('SPRAWDZANIE AKTUALIZACJI', 'LADOWANIE', 'LACZENIE Z GITHUB')) {
                Put '  > ' 'DarkCyan'
                Typed $b 'Cyan' 9
                Put ' '
                Put ('.' * [Math]::Max(3, 46 - $b.Length)) 'DarkGray'
                Start-Sleep -Milliseconds 80
                Say ' [ OK ]' 'Green'
            }
            Say ''
        }
    }

    'download' {
        $out = $env:DL_OUT
        $label = $env:UI_LABEL.PadRight(18)
        $wc = New-Object System.Net.WebClient
        $wc.Headers['User-Agent'] = 'mc-installer'
        $wc.Headers['Cache-Control'] = 'no-cache'
        $wc.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::BypassCache)
        $t = $wc.DownloadFileTaskAsync($env:DL_URL, $out)
        while (-not $t.IsCompleted) {
            $sz = 0
            if (Test-Path -LiteralPath $out) { $sz = (Get-Item -LiteralPath $out).Length }
            Frame $label ('{0,6:N2} MB' -f ($sz / 1MB))
            Start-Sleep -Milliseconds 45
        }
        Wipe
        $good = -not ($t.IsFaulted -or $t.IsCanceled)
        $sz = 0
        if ($good -and (Test-Path -LiteralPath $out)) { $sz = (Get-Item -LiteralPath $out).Length }
        $wc.Dispose()
        if ($good) {
            Put '  [ OK ] ' 'Green'
            Put $label 'White'
            Say ('{0:N2} MB' -f ($sz / 1MB)) 'DarkGray'
            exit 0
        } else {
            Put '  [FAIL] ' 'Red'
            Say $label.Trim() 'White'
            exit 1
        }
    }

    'plan' {
        $owner = $env:REPO_OWNER; $repo = $env:REPO_NAME; $ref = $env:REF
        $game = $env:GAME.TrimEnd('\', '/')
        $pack = $env:PACK_DIR
        $zip = $env:ZIP_SRC
        $items = New-Object System.Collections.ArrayList

        if ($zip) {
            $root = $zip.TrimEnd('\', '/')
            foreach ($f in (Get-ChildItem -LiteralPath $root -Recurse -File -Force)) {
                $rel = $f.FullName.Substring($root.Length + 1).Replace($SEP, '/')
                if ($rel -eq '.versionpck') { continue }
                [void]$items.Add([pscustomobject]@{ path = $rel; sha = ''; size = [int64]$f.Length })
            }
            if ($items.Count -eq 0) { exit 1 }
        } else {
            $u = 'https://api.github.com/repos/{0}/{1}/git/trees/{2}?recursive=1' -f $owner, $repo, $ref
            $txt = $null
            try {
                $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'mc-installer'; 'Cache-Control' = 'no-cache' } -ErrorAction Stop
                $txt = $r.Content
                if ($txt -is [byte[]]) { $txt = [Text.Encoding]::UTF8.GetString($txt) }
            } catch {}
            if (-not $txt) { exit 3 }
            $data = $null
            try {
                Add-Type -AssemblyName System.Web.Extensions
                $js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
                $js.MaxJsonLength = [int]::MaxValue
                $data = $js.DeserializeObject($txt)
            } catch { $data = $null }
            if (-not $data) { try { $data = $txt | ConvertFrom-Json } catch {} }
            if (-not $data) { exit 3 }
            if (Prop $data 'truncated') { exit 3 }
            $pre = ''
            if ($pack) { $pre = $pack.TrimEnd('/') + '/' }
            foreach ($e in (Prop $data 'tree')) {
                if ((Prop $e 'type') -ne 'blob') { continue }
                if ((Prop $e 'mode') -eq '120000') { continue }
                $p = [string](Prop $e 'path')
                if ($pre -and -not $p.StartsWith($pre, [StringComparison]::Ordinal)) { continue }
                if ($p.Substring($pre.Length) -eq '.versionpck') { continue }
                [void]$items.Add([pscustomobject]@{ path = $p.Substring($pre.Length); sha = [string](Prop $e 'sha'); size = [int64](Prop $e 'size') })
            }
            if ($items.Count -eq 0) { exit 3 }
        }

        $set = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        $new = New-Object System.Collections.ArrayList
        $upd = New-Object System.Collections.ArrayList
        $same = 0
        $kept = 0
        $keepCfg = ($env:CFG_OVERWRITE -ne '1')
        $total = $items.Count
        $label = 'SPRAWDZANIE PLIKOW'.PadRight(18)
        $i = 0
        foreach ($it in $items) {
            $i++
            [void]$set.Add($it.path)
            Frame $label ('{0}/{1}' -f $i, $total)
            $lp = LocalPath $game $it.path
            if (-not [IO.File]::Exists($lp)) { [void]$new.Add($it); continue }
            if ($keepCfg -and (IsCfg $it.path)) { $kept++; continue }
            if ((New-Object IO.FileInfo $lp).Length -ne $it.size) { [void]$upd.Add($it); continue }
            $rs = $it.sha
            if (-not $rs) { $rs = GitBlobSha (LocalPath $zip $it.path) }
            if ((GitBlobSha $lp) -eq $rs) { $same++ } else { [void]$upd.Add($it) }
        }

        $del = New-Object System.Collections.ArrayList
        if ($env:PRUNE -eq '1') {
            foreach ($m in @($env:MANAGED -split '\s+' | Where-Object { $_ })) {
                $mp = Join-Path $game $m
                if ([IO.File]::Exists($mp)) {
                    if (-not $set.Contains($m) -and -not ($keepCfg -and (IsCfg $m))) { [void]$del.Add($mp) }
                } elseif ([IO.Directory]::Exists($mp)) {
                    foreach ($f in (Get-ChildItem -LiteralPath $mp -Recurse -File -Force)) {
                        $rel = $f.FullName.Substring($game.Length + 1).Replace($SEP, '/')
                        if (-not $set.Contains($rel) -and -not ($keepCfg -and (IsCfg $rel))) { [void]$del.Add($f.FullName) }
                    }
                }
            }
        }
        Wipe

        $dl = New-Object System.Collections.ArrayList
        $newBytes = 0; $updBytes = 0; $allBytes = 0
        foreach ($it in $items) { $allBytes += $it.size }
        foreach ($it in $new) { $newBytes += $it.size; [void]$dl.Add($it) }
        foreach ($it in $upd) { $updBytes += $it.size; [void]$dl.Add($it) }

        $plan = [pscustomobject]@{ download = @($dl | ForEach-Object { [pscustomobject]@{ path = $_.path; sha = $_.sha; size = $_.size } }); delete = @($del) }
        $json = ConvertTo-Json -InputObject $plan -Depth 5 -Compress
        [IO.File]::WriteAllText($env:PLAN_FILE, $json, (New-Object Text.UTF8Encoding($false)))

        Put '  [ OK ] ' 'Green'
        Say ('Sprawdzono {0} plikow z paczki' -f $total) 'White'
        Put '         NOWE         : ' 'Cyan'; Say ('{0}  [{1}]' -f $new.Count, (Mb $newBytes)) 'Green'
        Put '         ZMIENIONE    : ' 'Cyan'; Say ('{0}  [{1}]' -f $upd.Count, (Mb $updBytes)) 'Yellow'
        Put '         DO USUNIECIA : ' 'Cyan'; Say ('{0}' -f $del.Count) 'Red'
        Put '         BEZ ZMIAN    : ' 'Cyan'; Say ('{0}' -f $same) 'DarkGray'
        if ($keepCfg -and $kept -gt 0) { Put '         ZACHOWANE    : ' 'Cyan'; Say ('{0}  [twoje konfigi]' -f $kept) 'DarkGray' }
        Say ''
        ListItems 'NEW' 'Green' @($new | ForEach-Object { $_.path })
        ListItems 'UPD' 'Yellow' @($upd | ForEach-Object { $_.path })
        ListItems 'DEL' 'Red' @($del | ForEach-Object { $_.Substring($game.Length + 1).Replace($SEP, '/') })

        if ($dl.Count + $del.Count -eq 0) { exit 2 }
        if ((-not $zip) -and $dl.Count -ge 100 -and (($newBytes + $updBytes) * 2 -ge $allBytes)) { exit 4 }
        exit 0
    }

    'sync' {
        $owner = $env:REPO_OWNER; $repo = $env:REPO_NAME; $ref = $env:REF
        $game = $env:GAME.TrimEnd('\', '/')
        $stage = $env:STAGE
        $zip = $env:ZIP_SRC
        $pack = $env:PACK_DIR
        $plan = $null
        try { $plan = [IO.File]::ReadAllText($env:PLAN_FILE) | ConvertFrom-Json } catch {}
        if (-not $plan) { exit 1 }
        $items = @($plan.download | Where-Object { $_ })
        $dels = @($plan.delete | Where-Object { $_ })

        if ([IO.Directory]::Exists($stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
        [void][IO.Directory]::CreateDirectory($stage)

        $failed = New-Object System.Collections.ArrayList
        $totalBytes = 0
        foreach ($it in $items) { $totalBytes += [int64]$it.size }
        $label = 'POBIERANIE'.PadRight(18)
        $sw = [Diagnostics.Stopwatch]::StartNew()

        if ($items.Count -gt 0 -and $zip) {
            $k = 0
            foreach ($it in $items) {
                $k++
                $tmp = LocalPath $stage $it.path
                try {
                    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($tmp))
                    [IO.File]::Copy((LocalPath $zip $it.path), $tmp, $true)
                } catch { [void]$failed.Add($it.path) }
                Frame $label ('{0}/{1}' -f $k, $items.Count)
            }
        } elseif ($items.Count -gt 0) {
            $queue = New-Object System.Collections.Generic.Queue[object]
            foreach ($it in $items) { $queue.Enqueue(@{ it = $it; tmp = (LocalPath $stage $it.path); tries = 0; wc = $null; task = $null; last = -1; tick = 0 }) }
            $active = New-Object System.Collections.ArrayList
            $doneCnt = 0; $doneBytes = 0
            $sha40 = ($ref -match '^[0-9a-f]{40}$')
            while ($queue.Count -gt 0 -or $active.Count -gt 0) {
                while ($queue.Count -gt 0 -and $active.Count -lt $MAXP) {
                    $j = $queue.Dequeue()
                    $j.tries++
                    $full = $j.it.path
                    if ($pack) { $full = $pack.TrimEnd('/') + '/' + $j.it.path }
                    $url = 'https://raw.githubusercontent.com/{0}/{1}/{2}/{3}' -f $owner, $repo, $ref, (UrlPath $full)
                    if (-not $sha40) { $url += '?cb=' + (Get-Random) }
                    try {
                        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($j.tmp))
                        [IO.File]::Delete($j.tmp)
                        $wc = New-Object System.Net.WebClient
                        $wc.Headers['User-Agent'] = 'mc-installer'
                        $j.wc = $wc
                        $j.task = $wc.DownloadFileTaskAsync($url, $j.tmp)
                        $j.last = -1
                        $j.tick = [Environment]::TickCount
                        [void]$active.Add($j)
                    } catch {
                        if ($j.tries -lt 3) { $queue.Enqueue($j) } else { [void]$failed.Add($j.it.path) }
                    }
                }

                $part = 0
                for ($k = $active.Count - 1; $k -ge 0; $k--) {
                    $j = $active[$k]
                    if (-not $j.task.IsCompleted) {
                        $cur = 0
                        if ([IO.File]::Exists($j.tmp)) { $cur = (New-Object IO.FileInfo $j.tmp).Length }
                        $part += $cur
                        if ($cur -ne $j.last) { $j.last = $cur; $j.tick = [Environment]::TickCount }
                        elseif (([Environment]::TickCount - $j.tick) -gt 60000) { try { $j.wc.CancelAsync() } catch {} }
                        continue
                    }
                    $good = -not ($j.task.IsFaulted -or $j.task.IsCanceled)
                    try { $j.wc.Dispose() } catch {}
                    if ($good) { $good = ((GitBlobSha $j.tmp) -eq $j.it.sha) }
                    $active.RemoveAt($k)
                    if ($good) { $doneCnt++; $doneBytes += [int64]$j.it.size }
                    elseif ($j.tries -lt 3) { $queue.Enqueue($j) }
                    else { [void]$failed.Add($j.it.path) }
                }
                Frame $label ('{0}/{1} {2:N0}/{3:N0}MB' -f ($doneCnt + $failed.Count), $items.Count, (($doneBytes + $part) / 1MB), ($totalBytes / 1MB))
                Start-Sleep -Milliseconds 45
            }
        }
        Wipe

        if ($failed.Count -gt 0) {
            Put '  [FAIL] ' 'Red'
            Say ('Nie udalo sie pobrac plikow: {0}' -f $failed.Count) 'White'
            for ($k = 0; $k -lt [Math]::Min(10, $failed.Count); $k++) { Say ('         ' + $failed[$k]) 'DarkGray' }
            Say '         Folder gry nie zostal zmieniony.' 'DarkGray'
            if ([IO.Directory]::Exists($stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
            exit 1
        }
        if ($items.Count -gt 0) {
            Put '  [ OK ] ' 'Green'
            Put $label 'White'
            Say ('{0} plikow / {1}  [{2:N1} s]' -f $items.Count, (Mb $totalBytes), $sw.Elapsed.TotalSeconds) 'DarkGray'
        }

        $label = 'WGRYWANIE ZMIAN'.PadRight(18)
        $k = 0
        $applyErr = New-Object System.Collections.ArrayList
        foreach ($d in $dels) {
            $k++
            try { [IO.File]::Delete($d) } catch { [void]$applyErr.Add($d) }
        }
        foreach ($it in $items) {
            $k++
            $src = LocalPath $stage $it.path
            $dst = LocalPath $game $it.path
            try {
                [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dst))
                [IO.File]::Delete($dst)
                [IO.File]::Move($src, $dst)
            } catch { [void]$applyErr.Add($dst) }
        }
        if ([IO.Directory]::Exists($stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }

        if ($applyErr.Count -gt 0) {
            Put '  [FAIL] ' 'Red'
            Say ('Nie udalo sie zapisac/usunac plikow: {0} (czy gra jest wylaczona?)' -f $applyErr.Count) 'White'
            for ($k = 0; $k -lt [Math]::Min(10, $applyErr.Count); $k++) { Say ('         ' + $applyErr[$k]) 'DarkGray' }
            exit 1
        }
        Put '  [ OK ] ' 'Green'
        Put $label 'White'
        Say ('zapisano {0}, usunieto {1}' -f $items.Count, $dels.Count) 'DarkGray'
        exit 0
    }

    'done' {
        Say ''
        Say "  $BAR" 'Green'
        Glitch (Center 'SUKCES  //  MODY ZAINSTALOWANE') 'Green'
        Say "  $BAR" 'Green'
    }
}
