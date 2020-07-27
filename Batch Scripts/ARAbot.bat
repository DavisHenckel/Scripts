ECHO OFF
echo Welcome to ARA Bot. Made by Davis Henckel
echo.
echo ---------------------------------------
echo                                       -
echo       ===              ===            -
echo       (O)              (O)            -
echo                                       -
echo                UU                     -
echo                                       -
echo          \_____________/              -
echo                                       -
echo ---------------------------------------
PAUSE

::Start of program, after each block of code is run, the user will select their next choice from here.
:mainMenu
cls
echo ------------------------------------- MAIN MENU -------------------------------------
echo.
echo Options curretly available:
echo 1) Browser cleaner
echo 2) Windows update Fix
echo 3) Common Command line repairs to fix OS problems (dism/chkdsk/sfc)
echo 4) Quit
echo.
echo -------------------------------------------------------------------------------------
set /p firstInput=Type the number of what you would like to do:
cls
if %firstInput%==1 goto browserCleaner
if %firstInput%==2 goto wUFix
if %firstInput%==3 goto ifExist
if %firstInput%==4 goto endProgram

echo Invalid input
goto mainMenu

::///////////////////////////////////////////////////////BROWSER CLEANER BLOCK////////////////////////////////////////////////////////////
:browserCleaner
:getInput
cls
echo -------------------------------------BROWSER CLEANER MENU -------------------------------------
echo This deletes IE, Edge, Firefox and Chrome Data. No it doesn't do Opera.
echo The best way to clean Opera is to uninstall it.
echo NOTE: This only clears data within the current user profile.
echo.
echo 1) Internet Explorer
echo 2) Edge
echo 3) Chrome
echo 4) Firefox
echo 5) All
echo 6) Back to ARA Bot Main Menu
echo.
echo ------------------------------------------------------------------------------------------------

set /p browserInput=Which browser(s) would you like to clear?:
if %browserInput%==5 goto internetExplorer
if %browserInput%==1 goto internetExplorer
if %browserInput%==2 goto edge
if %browserInput%==3 goto chrome
if %browserInput%==4 goto firefox
if %browserInput%==6 goto mainMenu

echo Invalid input.
goto getInput

:internetExplorer
taskkill /F /IM "iexplore.exe">nul 2>&1 
echo Deleting IE data ----------------------------------------------
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255
echo Done with IE ----------------------------------------------
echo.

if %browserInput%==1 goto finalCheck

:edge
taskkill /F /IM "MicrosoftEdge.exe">nul 2>&1
echo Deleting Edge Data ----------------------------------------------
cd %LOCALAPPDATA%\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\
powershell -command remove-item -recurse -force * -include *#!*
powershell -command remove-item -recurse -force * -include *Microsoft*
echo Done with Edge ----------------------------------------------
echo.

if %browserInput%==2 goto finalCheck

:chrome
if not exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\" echo No Chrome data detected. Moving on...
if not exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\" goto endChrome
taskkill /F /IM "chrome.exe">nul 2>&1
echo Deleting Chrome Data ----------------------------------------------
cd "%LOCALAPPDATA%\Google\Chrome\User Data\Default\"
if not exist history goto endChrome
del /s /q Cookies
del /s /q history
del /s /q preferences
rd /s /q Cache
:endChrome
echo Done with Chrome ----------------------------------------------
echo.

if %browserInput%==3 goto finalCheck

:firefox
if not exist %APPDATA%\Mozilla\Firefox\Profiles echo No Firefox data detected. Moving on...
if not exist %APPDATA%\Mozilla\Firefox\Profiles goto endFirefox
:startClearing
taskkill /F /IM "firefox.exe">nul 2>&1
echo Deleting Firefox Data ----------------------------------------------
cd %APPDATA%\Mozilla\Firefox\Profiles\
for /d %%F in (*) do cd "%%F"
if not exist places.sqlite goto endFirefox
del /s /q /f cookies.sqlite
del /s /q /f places.sqlite
cd %LOCALAPPDATA%\Mozilla\Firefox\Profiles
for /d %%F in (*) do cd "%%F"
rd /s /q OfflineCache
rd /s /q startupCache
:endFirefox
echo Done with Firefox ----------------------------------------------
echo.

if %browserInput%==5 goto end

:finalCheck
set /p secondInput=Done clearing browsers? (y/n)
if %secondInput%==n goto getInput
if %secondInput%==y goto mainMenu

echo Invalid input
goto finalCheck

:end
echo Browser cleaning complete
PAUSE
goto mainMenu
::///////////////////////////////////////////////////////END BLOCK////////////////////////////////////////////////////////////////

::////////////////////////////////////////////////WINDOWS UPDATE FIX BLOCK////////////////////////////////////////////////////////
:wUFix
echo Performing Windows update fix by restarting wuauserv, msiserver, cryptsvc and bits
net stop wuauserv
net stop msiserver
net stop cryptsvc
net stop bits

echo.
echo --------------------------------------
echo Renaming catroot2 to catroot2.old
ren c:\windows\system32\catroot2 catroot2.old
echo --------------------------------------
echo.

echo Starting services again
net start bits
net start cryptsvc
net start msiserver
net start wuauserv

echo Restart the computer and attempt Windows udpates again.

:prevStatement
set /p wUInput=Would you like to restart now? (y/n)
if %wUInput%==n goto end
if %wUInput%==y goto restart

echo Invalid input.
goto prevStatement

:restart
echo Program complete!
echo restarting...
shutdown /r /t 5

:end
echo Windows update fix complete.
goto mainMenu
::///////////////////////////////////////////////////////END BLOCK////////////////////////////////////////////////////////////////

::////////////////////////////////////////////////COMMON CMD REPAIRS BLOCK////////////////////////////////////////////////////////
:ifExist
cd %USERPROFILE%\Desktop\
if not exist ARABotRepairs.txt goto commCmdRep:
echo ARABotRepairs.txt already exists.
:enterYorN
set /p myQuestion= Would you like to delete it? (y/n)
if %myQuestion%==n goto commCmdRep
if %myQuestion%==y goto delARABotRepairs

echo Invalid input
goto enterYorN

:delARABotRepairs
del ARABotRepairs.txt
:commCmdRep
cls
echo -------------------------------------COMMON CMD REPAIRS MENU -------------------------------------
echo.
echo 1) dism 
echo 2) sfc
echo 3) chkdsk
echo 4) All in succession
echo 5) Back to ARA Bot Main Menu
echo.
echo --------------------------------------------------------------------------------------------------

set /p commCMDInput=What would you like to do?:
if %commCMDInput%==1 goto dism
if %commCMDInput%==2 goto sfc
if %commCMDInput%==3 goto chkdsk
if %commCMDInput%==4 goto dism
if %commCMDInput%==5 goto mainMenu

echo Invalid input.
goto commCmdRep

:dism
cls
echo This will save dism results to a folder on 
echo the Desktop called ARABotRepairs.txt
if exist %USERPROFILE%\Desktop\ARABotRepairs.txt goto alreadyExistsDISM
cd %USERPROFILE%\Desktop
ECHO ARABotRepairs > ARABotRepairs.txt
:alreadyExistsDISM
echo.
echo Running dism...
dism /online /cleanup-image /restorehealth >> %USERPROFILE%\Desktop\ARABotRepairs.txt

if %commCMDInput%==1 goto endCheck

:sfc
cls
echo This will save sfc results to a folder on 
echo the Desktop called ARABotRepairs.txt
if exist %USERPROFILE%\Desktop\ARABotRepairs.txt goto alreadyExistsSFC
cd %USERPROFILE%\Desktop
ECHO ARABotRepairs > ARABotRepairs.txt
:alreadyExistsSFC
echo.
echo Running sfc...
sfc /scannow >> ARABotRepairs.txt

if %commCMDInput%==2 goto endCheck

:chkdsk
if exist %USERPROFILE%\Desktop\ARABotRepairs.txt goto alreadyExistsCHKDSK
cd %USERPROFILE%\Desktop
ECHO ARABotRepairs > ARABotRepairs.txt
:alreadyExistsCHKDSK
cls
ECHO ON 
chkdsk /r /f /v
ECHO OFF
:getValidInput
set /p chkdskQ=Would You like to restart now? (y/n)
if %chkdskQ%==y goto reminder
if %chkdskQ%==n goto endCheck

echo Invalid input.
goto getValidInput

:reminder
echo To see chkdsk results go to event viewer, windows logs, (right click)applications, find "wininit" >> ARABotRepairs.txt
echo When chkdsk is done results can be found by going 
echo to event viewer, windows logs, applications, find "wininit"
echo regedit to set the batch file to continue running after
echo restart will be added at a later date.
echo restarting in 10 seconds...
shutdown /r /t 10

:endCheck
cls
echo 1) Keep using Common CMD Repairs
echo 2) Back to ARA Bot Main Menu
echo 3) Quit program
set /p nextDirection=What would you like to do?:
if %nextDirection%==1 goto commCmdRep
if %nextDirection%==2 goto mainMenu
if %nextDirection%==3 goto endProgram
echo Invalid input
goto endCheck
::///////////////////////////////////////////////////////END BLOCK////////////////////////////////////////////////////////////////

:endProgram
echo Thank you for using ARA Bot.
PAUSE
