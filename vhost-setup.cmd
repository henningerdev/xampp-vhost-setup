@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: ==============================
:: XAMPP Projekt Manager (vereinfacht)
:: ==============================
:: Dieser Batch-Script dient zur Verwaltung von lokalen XAMPP-Projekten.
:: Er ermöglicht das Erstellen, Scannen, Aktualisieren und Löschen von Projekten,
:: sowie die Generierung von Sitemap und Robots.txt

:: Prüfe ob als Administrator ausgeführt
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ======================================================
    echo ACHTUNG: Dieses Script muss als Administrator ausgeführt werden!
    echo Bitte schließen Sie das Fenster und führen Sie es erneut
    echo mit Rechtsklick "Als Administrator ausführen" aus.
    echo ======================================================
    pause
    exit /b 1
)

:: Pfade definieren
set apacheBin=C:\xampp\apache\bin
set apacheConf=C:\xampp\apache\conf
set htdocs=C:\xampp\htdocs
set hostsFile=C:\Windows\System32\drivers\etc\hosts
set vhostsFile=%apacheConf%\extra\httpd-vhosts.conf
set sslConfFile=%apacheConf%\extra\httpd-ssl.conf
set excludeDirs=dashboard img webalizer security xampp-manager

:: Standard Ports
set httpPort=80
set httpsPort=443

:: ==============================
:: Hauptmenü
:: ==============================
:menu
cls 
echo ================================
echo XAMPP Projekt Manager
echo ================================
echo.
echo 1) Neues Projekt anlegen
echo 2) Bestehende Projekte scannen
echo 3) Projekt löschen
echo 4) Projekt aktualisieren/reparieren
echo 5) Sitemap.xml generieren
echo 6) Robots.txt erstellen
echo 7) Beenden
echo.
set /p choice="Bitte wählen Sie eine Option (1-7): "

if "%choice%"=="1" goto newProject
if "%choice%"=="2" goto scanProjects
if "%choice%"=="3" goto deleteProject
if "%choice%"=="4" goto repairProject
if "%choice%"=="5" goto generateSitemap
if "%choice%"=="6" goto createRobots
if "%choice%"=="7" exit /b 0
goto menu

:: ==============================
:: Projekte scannen
:: ==============================
:scanProjects
cls
echo.
echo 🔍 Scanne nach Projekten...
echo.

set count=0
for /d %%D in ("%htdocs%\*") do (
    set "dirname=%%~nxD"
    set "skip="
    
    for %%E in (%excludeDirs%) do (
        if "!dirname!"=="%%E" set "skip=1"
    )
    
    if not defined skip (
        if exist "%%D\project.json" (
            set /a count+=1
            echo  ✓ !dirname! (mit project.json)
        ) else (
            echo  - !dirname!
        )
    )
)

echo.
if %count%==0 (
    echo Keine Projekte mit project.json gefunden.
) else (
    echo %count% Projekte mit project.json gefunden.
)
echo.
pause
goto menu

:: ==============================
:: Neues Projekt anlegen
:: ==============================
:newProject
cls
echo === Neues Projekt anlegen ===
echo.

:: Benutzereingaben
set /p projectName="🔧 Projektname eingeben (z.B. 'meinProjekt'): "
if "%projectName%"=="" (
    echo ❌ Projektname darf nicht leer sein!
    pause
    goto newProject
)

set /p domainName="🌐 Domainnamen eingeben (z.B. '%projectName%.local'): "
if "%domainName%"=="" set "domainName=%projectName%.local"

set /p projectTitle="📝 Projekttitel eingeben: "
if "%projectTitle%"=="" set "projectTitle=%projectName%"

set /p projectDesc="📋 Projektbeschreibung eingeben: "

:: Projektverzeichnis erstellen
echo.
echo 📁 Erstelle Projektverzeichnis...
set projectPath=%htdocs%\%projectName%

if exist "%projectPath%" (
    set /p overwrite="⚠️ Projektverzeichnis existiert bereits. Überschreiben? (j/n): "
    if /i not "%overwrite%"=="j" goto menu
    
    echo Lösche altes Verzeichnis...
    rd /s /q "%projectPath%"
    if exist "%projectPath%" (
        echo ❌ Fehler beim Löschen des alten Verzeichnisses!
        pause
        goto menu
    )
)

mkdir "%projectPath%"
if not exist "%projectPath%" (
    echo ❌ Fehler beim Erstellen des Projektverzeichnisses!
    pause
    goto menu
)

:: project.json erstellen
echo 📝 Erstelle project.json...
(
    echo {
    echo     "title": "%projectTitle%",
    echo     "description": "%projectDesc%",
    echo     "domain": "%domainName%"
    echo }
) > "%projectPath%\project.json"

:: index.php erstellen
echo 📝 Erstelle index.php...
(
    echo ^<?php
    echo header('Content-Type: text/html; charset=utf-8'^);
    echo ?^>
    echo ^<!DOCTYPE html^>
    echo ^<html lang="de"^>
    echo ^<head^>
    echo     ^<meta charset="UTF-8"^>
    echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
    echo     ^<title^>%projectTitle%^</title^>
    echo ^</head^>
    echo ^<body^>
    echo     ^<h1^>%projectTitle%^</h1^>
    echo     ^<p^>%projectDesc%^</p^>
    echo ^</body^>
    echo ^</html^>
) > "%projectPath%\index.php"

:: SSL-Verzeichnisse prüfen/erstellen
echo 📁 Prüfe SSL-Verzeichnisse...
if not exist "%apacheConf%\ssl.key" mkdir "%apacheConf%\ssl.key"
if not exist "%apacheConf%\ssl.crt" mkdir "%apacheConf%\ssl.crt"

:: SSL-Zertifikate erstellen
echo 🔑 Erstelle SSL-Zertifikate für %domainName%...
"%apacheBin%\openssl.exe" req -new -newkey rsa:2048 -days 365 -nodes -x509 ^
    -subj "/C=DE/ST=State/L=City/O=Organization/CN=%domainName%" ^
    -keyout "%apacheConf%\ssl.key\%domainName%.key" ^
    -out "%apacheConf%\ssl.crt\%domainName%.crt" ^
    -config "%apacheConf%\openssl.cnf" 2>nul

:: Host-Eintrag hinzufügen
echo 📝 Füge Host-Eintrag hinzu...
findstr /C:"%domainName%" "%hostsFile%" >nul
if errorlevel 1 (
   >> "%hostsFile%" echo 127.0.0.1 %domainName%
)

:: VirtualHost-Konfiguration erstellen
echo 📝 Erstelle VirtualHost-Einträge...
(
    echo.
    echo # VirtualHost für %domainName%
    echo ^<VirtualHost *:%httpPort%^>
    echo     ServerName %domainName%
    echo     DocumentRoot "%projectPath%"
    echo     ^<Directory "%projectPath%"^>
    echo         Options Indexes FollowSymLinks
    echo         AllowOverride All
    echo         Require all granted
    echo     ^</Directory^>
    echo     ErrorLog "logs/%domainName%-error.log"
    echo     CustomLog "logs/%domainName%-access.log" combined
    echo ^</VirtualHost^>
    echo.
    echo ^<VirtualHost *:%httpsPort%^>
    echo     ServerName %domainName%
    echo     DocumentRoot "%projectPath%"
    echo     SSLEngine on
    echo     SSLCertificateFile "%apacheConf%\ssl.crt\%domainName%.crt"
    echo     SSLCertificateKeyFile "%apacheConf%\ssl.key\%domainName%.key"
    echo     ^<Directory "%projectPath%"^>
    echo         Options Indexes FollowSymLinks
    echo         AllowOverride All
    echo         Require all granted
    echo     ^</Directory^>
    echo     ErrorLog "logs/%domainName%-ssl-error.log"
    echo     CustomLog "logs/%domainName%-ssl-access.log" combined
    echo ^</VirtualHost^>
) >> "%vhostsFile%"

:: Prüfe Apache Konfiguration
echo 🔍 Teste Apache-Konfiguration...
"%apacheBin%\httpd.exe" -t 2>nul
if errorlevel 1 (
    echo ⚠️ Apache-Konfiguration hat Fehler!
) else (
    echo ✅ Apache-Konfiguration ist valide
)

:: Frage nach Zusatzfunktionen
set /p createSitemap="Möchten Sie eine sitemap.xml erstellen? (j/n): "
if /i "%createSitemap%"=="j" (
    call :createSitemapFile "%projectPath%" "%domainName%"
)

set /p createRobots="Möchten Sie eine robots.txt erstellen? (j/n): "
if /i "%createRobots%"=="j" (
    call :createRobotsFile "%projectPath%" "%domainName%"
)

echo.
echo ✅ Projekt erfolgreich erstellt
echo.
echo 🔄 Bitte starten Sie Apache neu, um die Änderungen zu aktivieren
echo    http://%domainName%
echo    https://%domainName%
echo.
pause
goto menu

:: ==============================
:: Projekt löschen
:: ==============================
:deleteProject
cls
echo === Projekt löschen ===
echo.
echo 📁 Verfügbare Projekte:
echo.

set count=0
set projectList=
for /d %%D in ("%htdocs%\*") do (
    set "dirname=%%~nxD"
    set "skip="
    
    for %%E in (%excludeDirs%) do (
        if "!dirname!"=="%%E" set "skip=1"
    )
    
    if not defined skip (
        set /a count+=1
        echo !count!^) !dirname!
        set "project!count!=%%D"
        set "projectName!count!=!dirname!"
    )
)

if %count%==0 (
    echo Keine Projekte gefunden.
    pause
    goto menu
)

echo.
set /p projectNum="Wählen Sie ein Projekt zum Löschen (1-%count%): "
if "%projectNum%"=="" goto menu

set selectedProject=!project%projectNum%!
set selectedName=!projectName%projectNum%!

if not exist "%selectedProject%" (
    echo ❌ Ungültige Auswahl
    pause
    goto menu
)

:: Domain aus project.json auslesen, falls vorhanden
set domainName=%selectedName%
if exist "%selectedProject%\project.json" (
    for /f "tokens=2 delims=:," %%a in ('findstr "domain" "%selectedProject%\project.json"') do (
        set domainName=%%a
        set domainName=!domainName:"=!
        set domainName=!domainName: =!
    )
)

echo.
echo ⚠️ Sie sind dabei, das Projekt "%selectedName%" mit Domain "%domainName%" zu löschen!
set /p confirm="Sind Sie sicher? (j/n): "
if /i not "%confirm%"=="j" goto menu

:: Projektverzeichnis löschen
echo 🗑️ Lösche Projektverzeichnis...
rd /s /q "%selectedProject%"
if exist "%selectedProject%" (
    echo ❌ Fehler beim Löschen des Projektverzeichnisses!
) else (
    echo ✅ Projektverzeichnis gelöscht
)

:: SSL-Zertifikate löschen
if exist "%apacheConf%\ssl.key\%domainName%.key" (
    del "%apacheConf%\ssl.key\%domainName%.key"
    echo ✅ SSL-Schlüssel gelöscht
)

if exist "%apacheConf%\ssl.crt\%domainName%.crt" (
    del "%apacheConf%\ssl.crt\%domainName%.crt"
    echo ✅ SSL-Zertifikat gelöscht
)

:: VirtualHost-Einträge entfernen
echo 📝 Entferne VirtualHost-Einträge...
findstr /v /c:"# VirtualHost für %domainName%" /c:"ServerName %domainName%" "%vhostsFile%" > "%vhostsFile%.tmp"
move /y "%vhostsFile%.tmp" "%vhostsFile%" >nul

:: Host-Eintrag entfernen
echo 📝 Entferne Host-Eintrag...
findstr /v /c:"127.0.0.1 %domainName%" "%hostsFile%" > "%hostsFile%.tmp"
move /y "%hostsFile%.tmp" "%hostsFile%" >nul

:: Teste Apache Konfiguration
echo 🔍 Teste Apache-Konfiguration...
"%apacheBin%\httpd.exe" -t 2>nul
if errorlevel 1 (
    echo ⚠️ Apache-Konfiguration hat Fehler!
) else (
    echo ✅ Apache-Konfiguration ist valide
)

echo.
echo ✅ Projekt "%selectedName%" wurde erfolgreich gelöscht
echo.
pause
goto menu

:: ==============================
:: Sitemap generieren
:: ==============================
:generateSitemap
cls
echo === Sitemap generieren ===
echo.

:: Projektauswahl
set count=0
for /d %%D in ("%htdocs%\*") do (
    set "dirname=%%~nxD"
    set "skip="
    
    for %%E in (%excludeDirs%) do (
        if "!dirname!"=="%%E" set "skip=1"
    )
    
    if not defined skip (
        set /a count+=1
        echo !count!^) !dirname!
        set "project!count!=%%D"
        set "projectName!count!=!dirname!"
    )
)

if %count%==0 (
    echo Keine Projekte gefunden.
    pause
    goto menu
)

echo.
set /p projectNum="Wählen Sie ein Projekt (1-%count%): "
if "%projectNum%"=="" goto menu

set selectedProject=!project%projectNum%!
set selectedName=!projectName%projectNum%!

if not exist "%selectedProject%" (
    echo ❌ Ungültige Auswahl
    pause
    goto menu
)

:: Domain aus project.json auslesen, falls vorhanden
set domainName=%selectedName%
if exist "%selectedProject%\project.json" (
    for /f "tokens=2 delims=:," %%a in ('findstr "domain" "%selectedProject%\project.json"') do (
        set domainName=%%a
        set domainName=!domainName:"=!
        set domainName=!domainName: =!
    )
)

call :createSitemapFile "%selectedProject%" "%domainName%"
pause
goto menu

:: ==============================
:: Robots.txt erstellen
:: ==============================
:createRobots
cls
echo === Robots.txt erstellen ===
echo.

:: Projektauswahl
set count=0
for /d %%D in ("%htdocs%\*") do (
    set "dirname=%%~nxD"
    set "skip="
    
    for %%E in (%excludeDirs%) do (
        if "!dirname!"=="%%E" set "skip=1"
    )
    
    if not defined skip (
        set /a count+=1
        echo !count!^) !dirname!
        set "project!count!=%%D"
        set "projectName!count!=!dirname!"
    )
)

if %count%==0 (
    echo Keine Projekte gefunden.
    pause
    goto menu
)

echo.
set /p projectNum="Wählen Sie ein Projekt (1-%count%): "
if "%projectNum%"=="" goto menu

set selectedProject=!project%projectNum%!
set selectedName=!projectName%projectNum%!

if not exist "%selectedProject%" (
    echo ❌ Ungültige Auswahl
    pause
    goto menu
)

:: Domain aus project.json auslesen, falls vorhanden
set domainName=%selectedName%
if exist "%selectedProject%\project.json" (
    for /f "tokens=2 delims=:," %%a in ('findstr "domain" "%selectedProject%\project.json"') do (
        set domainName=%%a
        set domainName=!domainName:"=!
        set domainName=!domainName: =!
    )
)

call :createRobotsFile "%selectedProject%" "%domainName%"
pause
goto menu

:: ==============================
:: Hilfsfunktionen
:: ==============================

:createSitemapFile
:: Parameter: %1 = Projektpfad, %2 = Domain
echo 🔍 Erstelle Sitemap für %~nx1...

:: Aktuelles Datum im Format YYYY-MM-DD
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set "DD=%%a"
    set "MM=%%b"
    set "YYYY=%%c"
)
set "formattedDate=%YYYY%-%MM%-%DD%"

:: Sitemap erstellen
(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"^>
) > "%~1\sitemap.xml"

:: Root-URL hinzufügen
(
    echo     ^<url^>
    echo         ^<loc^>http://%~2/^</loc^>
    echo         ^<lastmod^>%formattedDate%^</lastmod^>
    echo         ^<changefreq^>weekly^</changefreq^>
    echo         ^<priority^>1.0^</priority^>
    echo     ^</url^>
) >> "%~1\sitemap.xml"

:: PHP-Dateien finden
for /r "%~1" %%F in (*.php) do (
    set "filePath=%%F"
    set "relativePath=!filePath:%~1\=!"
    
    if not "!relativePath!"=="index.php" (
        (
            echo     ^<url^>
            echo         ^<loc^>http://%~2/!relativePath:/=!^</loc^>
            echo         ^<lastmod^>%formattedDate%^</lastmod^>
            echo         ^<changefreq^>monthly^</changefreq^>
            echo         ^<priority^>0.8^</priority^>
            echo     ^</url^>
        ) >> "%~1\sitemap.xml"
    )
)

:: HTML-Dateien finden
for /r "%~1" %%F in (*.html) do (
    set "filePath=%%F"
    set "relativePath=!filePath:%~1\=!"
    
    (
        echo     ^<url^>
        echo         ^<loc^>http://%~2/!relativePath:\=/!^</loc^>
        echo         ^<lastmod^>%formattedDate%^</lastmod^>
        echo         ^<changefreq^>monthly^</changefreq^>
        echo         ^<priority^>0.8^</priority^>
        echo     ^</url^>
    ) >> "%~1\sitemap.xml"
)

:: Sitemap abschließen
(
    echo ^</urlset^>
) >> "%~1\sitemap.xml"

echo ✅ Sitemap erstellt: %~1\sitemap.xml
exit /b 0

:: ==============================
:: Projekt aktualisieren/reparieren
:: ==============================
:repairProject
cls
echo === Projekt aktualisieren/reparieren ===
echo.
echo 📁 Verfügbare Projekte:
echo.

set count=0
for /d %%D in ("%htdocs%\*") do (
    set "dirname=%%~nxD"
    set "skip="
    
    for %%E in (%excludeDirs%) do (
        if "!dirname!"=="%%E" set "skip=1"
    )
    
    if not defined skip (
        set /a count+=1
        echo !count!^) !dirname!
        set "project!count!=%%D"
        set "projectName!count!=!dirname!"
    )
)

if %count%==0 (
    echo Keine Projekte gefunden.
    pause
    goto menu
)

echo.
set /p projectNum="Wählen Sie ein Projekt (1-%count%): "
if "%projectNum%"=="" goto menu

set selectedProject=!project%projectNum%!
set selectedName=!projectName%projectNum%!

if not exist "%selectedProject%" (
    echo ❌ Ungültige Auswahl
    pause
    goto menu
)

:: Projektdaten abfragen
echo.
echo === Projekt "%selectedName%" aktualisieren ===
echo.

:: Bestehende Daten auslesen, falls vorhanden
set "existingTitle=%selectedName%"
set "existingDesc="
set "existingDomain=%selectedName%.local"

if exist "%selectedProject%\project.json" (
    for /f "tokens=2 delims=:," %%a in ('findstr "title" "%selectedProject%\project.json"') do (
        set existingTitle=%%a
        set existingTitle=!existingTitle:"=!
        set existingTitle=!existingTitle: =!
    )
    for /f "tokens=2 delims=:," %%a in ('findstr "description" "%selectedProject%\project.json"') do (
        set existingDesc=%%a
        set existingDesc=!existingDesc:"=!
        set existingDesc=!existingDesc: =!
    )
    for /f "tokens=2 delims=:," %%a in ('findstr "domain" "%selectedProject%\project.json"') do (
        set existingDomain=%%a
        set existingDomain=!existingDomain:"=!
        set existingDomain=!existingDomain: =!
    )
)

echo Aktuelle Daten:
echo - Titel: %existingTitle%
echo - Beschreibung: %existingDesc%
echo - Domain: %existingDomain%
echo.

:: Neue Daten abfragen
set /p newTitle="Neuer Titel (leer = beibehalten): "
if "%newTitle%"=="" set "newTitle=%existingTitle%"

set /p newDesc="Neue Beschreibung (leer = beibehalten): "
if "%newDesc%"=="" set "newDesc=%existingDesc%"

set /p newDomain="Neue Domain (leer = beibehalten): "
if "%newDomain%"=="" set "newDomain=%existingDomain%"

:: project.json aktualisieren
echo 📝 Aktualisiere project.json...
(
    echo {
    echo     "title": "%newTitle%",
    echo     "description": "%newDesc%",
    echo     "domain": "%newDomain%"
    echo }
) > "%selectedProject%\project.json"

:: Falls sich die Domain geändert hat, VirtualHost und hosts aktualisieren
if not "%newDomain%"=="%existingDomain%" (
    echo 📝 Domain hat sich geändert, aktualisiere Konfiguration...
    
    :: Host-Eintrag entfernen und neu hinzufügen
    findstr /v /c:"127.0.0.1 %existingDomain%" "%hostsFile%" > "%hostsFile%.tmp"
    move /y "%hostsFile%.tmp" "%hostsFile%" >nul
    
    echo 127.0.0.1 %newDomain% >> "%hostsFile%"
    
    :: SSL-Zertifikate erstellen
    echo 🔑 Erstelle neue SSL-Zertifikate...
    "%apacheBin%\openssl.exe" req -new -newkey rsa:2048 -days 365 -nodes -x509 ^
        -subj "/C=DE/ST=State/L=City/O=Organization/CN=%newDomain%" ^
        -keyout "%apacheConf%\ssl.key\%newDomain%.key" ^
        -out "%apacheConf%\ssl.crt\%newDomain%.crt" ^
        -config "%apacheConf%\openssl.cnf" 2>nul
    
    :: Alte Zertifikate löschen
    if exist "%apacheConf%\ssl.key\%existingDomain%.key" (
        del "%apacheConf%\ssl.key\%existingDomain%.key"
    )
    if exist "%apacheConf%\ssl.crt\%existingDomain%.crt" (
        del "%apacheConf%\ssl.crt\%existingDomain%.crt"
    )
    
    :: VirtualHost aktualisieren - zuerst alte Einträge entfernen
    findstr /v /c:"# VirtualHost für %existingDomain%" /c:"ServerName %existingDomain%" "%vhostsFile%" > "%vhostsFile%.tmp"
    move /y "%vhostsFile%.tmp" "%vhostsFile%" >nul
    
    :: Neue VirtualHost-Einträge erstellen
    (
        echo.
        echo # VirtualHost für %newDomain%
        echo ^<VirtualHost *:%httpPort%^>
        echo     ServerName %newDomain%
        echo     DocumentRoot "%selectedProject%"
        echo     ^<Directory "%selectedProject%"^>
        echo         Options Indexes FollowSymLinks
        echo         AllowOverride All
        echo         Require all granted
        echo     ^</Directory^>
        echo     ErrorLog "logs/%newDomain%-error.log"
        echo     CustomLog "logs/%newDomain%-access.log" combined
        echo ^</VirtualHost^>
        echo.
        echo ^<VirtualHost *:%httpsPort%^>
        echo     ServerName %newDomain%
        echo     DocumentRoot "%selectedProject%"
        echo     SSLEngine on
        echo     SSLCertificateFile "%apacheConf%\ssl.crt\%newDomain%.crt"
        echo     SSLCertificateKeyFile "%apacheConf%\ssl.key\%newDomain%.key"
        echo     ^<Directory "%selectedProject%"^>
        echo         Options Indexes FollowSymLinks
        echo         AllowOverride All
        echo         Require all granted
        echo     ^</Directory^>
        echo     ErrorLog "logs/%newDomain%-ssl-error.log"
        echo     CustomLog "logs/%newDomain%-ssl-access.log" combined
        echo ^</VirtualHost^>
    ) >> "%vhostsFile%"
)

:: Teste Apache Konfiguration
echo 🔍 Teste Apache-Konfiguration...
"%apacheBin%\httpd.exe" -t 2>nul
if errorlevel 1 (
    echo ⚠️ Apache-Konfiguration hat Fehler!
) else (
    echo ✅ Apache-Konfiguration ist valide
)

echo.
echo ✅ Projekt "%selectedName%" wurde erfolgreich aktualisiert
if not "%newDomain%"=="%existingDomain%" (
    echo ℹ️ Domain wurde geändert: %existingDomain% -> %newDomain%
    echo ℹ️ Bitte starten Sie Apache neu, um die Änderungen zu aktivieren
    echo    http://%newDomain%
    echo    https://%newDomain%
)
echo.
pause
goto menu

:createRobotsFile
:: Parameter: %1 = Projektpfad, %2 = Domain
echo 📝 Erstelle robots.txt für %~nx1...

(
    echo User-agent: *
    echo Allow: /
    echo.
    echo # Hier können weitere Regeln hinzugefügt werden:
    echo # Disallow: /admin/
    echo # Disallow: /private/
    echo.
) > "%~1\robots.txt"

:: Wenn eine Sitemap existiert, diese hinzufügen
if exist "%~1\sitemap.xml" (
    echo Sitemap: http://%~2/sitemap.xml>> "%~1\robots.txt"
)

echo ✅ robots.txt erstellt: %~1\robots.txt
exit /b 0