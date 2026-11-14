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
        echo         %cD%Mozesz zainstalowac ja ponownie, np. aby naprawic pliki.%cX%
    ) else (
        if defined LOCAL_SHA (
            echo   %cC%STATUS %cD%:%cX% %cM%dostepna aktualizacja%cX% %cD%[!LOCAL_SHA:~0,7!%cX% -^> %cY%!REMOTE_SHA:~0,7!%cD%]%cX%
        ) else (
            echo   %cC%STATUS %cD%:%cX% %cM%nowa instalacja%cX% %cD%[!REMOTE_SHA:~0,7!]%cX%
        )
        echo   %cD%----------------------------------------------------------%cX%
    )
)

echo.
echo   %cR%[WARN]%cX% Zostana USUNIETE jesli istnieja:
echo         %cD%options.txt, mods, config, resourcepacks, shaderpacks%cX%
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
    call :wait
    exit /b 0
)

echo.
set "PACK_ZIP=%WORK%\repo.zip"
set "EXTRACT=%WORK%\extract"
if exist "%PACK_ZIP%" del /f /q "%PACK_ZIP%"
if exist "%EXTRACT%\" rd /s /q "%EXTRACT%"

call :download "!ZIP_URL!" "%PACK_ZIP%" "POBIERANIE PACZKI"
if errorlevel 1 (
    echo   %cR%[FAIL]%cX% Nie udalo sie pobrac paczki. Sprawdz internet oraz czy repozytorium jest publiczne.
    echo         %cD%Stare pliki NIE zostaly usuniete.%cX%
    call :wait
    exit /b 1
)

echo   %cM%[ ^>^> ]%cX% Rozpakowywanie archiwum...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath $env:PACK_ZIP -DestinationPath $env:EXTRACT -Force"
if errorlevel 1 (
    echo   %cR%[FAIL]%cX% Nie udalo sie rozpakowac pobranego archiwum.
    echo         %cD%Stare pliki NIE zostaly usuniete.%cX%
    call :wait
    exit /b 1
)

set "REPO_ROOT="
for /d %%R in ("%EXTRACT%\*") do set "REPO_ROOT=%%~fR"
if not defined REPO_ROOT (
    echo   %cR%[FAIL]%cX% Pobrane archiwum jest puste.
    call :wait
    exit /b 1
)

if defined PACK_DIR (
    set "SRC=!REPO_ROOT!\%PACK_DIR%"
) else (
    set "SRC=!REPO_ROOT!"
)

if not exist "!SRC!\" (
    echo   %cR%[FAIL]%cX% W repozytorium nie znaleziono folderu: %PACK_DIR%
    echo         %cD%Stare pliki NIE zostaly usuniete.%cX%
    call :wait
    exit /b 1
)
echo   %cG%[ OK ]%cX% Archiwum gotowe.

echo.
echo   %cM%[ ^>^> ]%cX% Usuwanie starych plikow...
if exist "%GAME%\options.txt" (
    del /f /q "%GAME%\options.txt"
    echo   %cR%[ DEL ]%cX% options.txt
)
for %%D in (mods config resourcepacks shaderpacks) do (
    if exist "%GAME%\%%D\" (
        rd /s /q "%GAME%\%%D"
        echo   %cR%[ DEL ]%cX% %%D
    )
)

echo.
set "COPY_SRC=!SRC!"
set "COPY_DST=%GAME%"
set "UI_MODE=copy"
call :ps
if errorlevel 1 (
    echo   %cR%[FAIL]%cX% Nie udalo sie skopiowac plikow do folderu gry.
    call :wait
    exit /b 1
)

if defined REMOTE_SHA >"%SHA_FILE%" (echo !REMOTE_SHA!)

if exist "%PACK_ZIP%" del /f /q "%PACK_ZIP%"
if exist "%EXTRACT%\" rd /s /q "%EXTRACT%"

set "UI_MODE=done"
call :ps
call :wait
endlocal
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

    'copy' {
        $files = @(Get-ChildItem -LiteralPath $env:COPY_SRC -Recurse -File)
        $total = 0
        foreach ($f in $files) { $total += $f.Length }
        Put '  [ >> ] ' 'Cyan'
        Say ('PAYLOAD: {0} plikow / {1:N1} MB' -f $files.Count, ($total / 1MB)) 'White'

        $label = 'WGRYWANIE PLIKOW'.PadRight(18)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $args2 = '"{0}" "{1}" /E /NFL /NDL /NJH /NJS /NP' -f $env:COPY_SRC, $env:COPY_DST
        $p = Start-Process -FilePath robocopy -ArgumentList $args2 -PassThru -WindowStyle Hidden
        while (-not $p.HasExited) {
            Frame $label ('{0,5:N1} s' -f $sw.Elapsed.TotalSeconds)
            Start-Sleep -Milliseconds 45
        }
        $p.WaitForExit()
        Wipe
        if ($p.ExitCode -lt 8) {
            Put '  [ OK ] ' 'Green'
            Put $label 'White'
            Say ('{0:N1} s' -f $sw.Elapsed.TotalSeconds) 'DarkGray'
            exit 0
        } else {
            Put '  [FAIL] ' 'Red'
            Say $label.Trim() 'White'
            exit 1
        }
    }

    'done' {
        Say ''
        Say "  $BAR" 'Green'
        Glitch (Center 'SUKCES  //  MODY ZAINSTALOWANE') 'Green'
        Say "  $BAR" 'Green'
    }
}
