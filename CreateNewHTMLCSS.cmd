@ECHO OFF
:: Self-elevation routine
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
IF '%errorlevel%' NEQ '0' (
    ECHO Requesting admin privileges...
    GOTO UACPrompt
) ELSE ( GOTO gotAdmin )

:UACPrompt
    ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    ECHO UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    DEL "%temp%\getadmin.vbs"
    EXIT /B

:gotAdmin
    PUSHD "%CD%"
    CD /D "%~dp0"
::MODE CON: COLS=80
:MENU
CLS
ECHO.
ECHO  		======================================
ECHO  		       Create New Menu Modifier       
ECHO  		======================================
ECHO.
ECHO  This script is for adding and removing "New" context menu entries,
ECHO  by safely editing the registry for the current user and adding the
ECHO  appropriate template files to the main Templates folder.
ECHO.  
ECHO. 
ECHO 	A - About
ECHO 	1 - Add HTML template
ECHO 	2 - Remove HTML template
ECHO 	3 - Add CSS template
ECHO 	4 - Remove CSS template
ECHO 	R - Refresh Explorer
ECHO 	Q - Quit
ECHO.
ECHO.
CHOICE /C A1234RQ /N /M " Enter an option to proceed: (1-4, R, A or Q): "
IF ERRORLEVEL 7 GOTO END
IF ERRORLEVEL 6 GOTO 5REFRESH
IF ERRORLEVEL 5 GOTO 4REMOVECSS
IF ERRORLEVEL 4 GOTO 3CREATECSS
IF ERRORLEVEL 3 GOTO 2REMOVEHTML
IF ERRORLEVEL 2 GOTO 1NEWHTML
IF ERRORLEVEL 1 GOTO ABOUTMENU
GOTO MENU

:ABOUTMENU
CLS
ECHO.
ECHO          Create New Menu Modifier v1.0 ^| DR - x87e
ECHO        =============================================
ECHO.
ECHO This script adds or removes custom HTML/CSS template links for the
ECHO "New" context menu entry in Windows Explorer.
ECHO.
ECHO It works by modifying the following registry values:
ECHO HKEY_CLASSES_ROOT\.html\ShellNew - FileName = "HTMLTemplate.html"
ECHO HKEY_CLASSES_ROOT\.css\ShellNew  - FileName = "CSSTemplate.css"
ECHO.
ECHO A base template file for each option is created in this location:
ECHO %%APPDATA%%\Microsoft\Windows\Templates
ECHO You can manually edit these files to customize them as needed.
ECHO.
ECHO PLEASE CREATE A RESTORE POINT BEFORE USING THIS SCRIPT!
ECHO It is strongly recommended to back up your system (restore point,
ECHO registry export, or full image) before making any registry changes.
ECHO This takes only a few seconds and prevents potential regret later.
ECHO.
ECHO For advanced users:
ECHO ---------------------------------
ECHO - You can open this script in a text editor and modify the registry
ECHO   commands or create your own custom versions.
ECHO - If you are unsure about any change, search online for guidance.
ECHO - Editing the Windows Registry (regedit.exe) can cause problems if
ECHO   incompatible changes are made, though following instructions usually
ECHO   results in only minor registry bloat.
ECHO - This version (v1.0) does not yet support adding fully custom templates.
ECHO   That feature will be added in a future update.
ECHO.
ECHO - BY USING OR EDITING THIS SCRIPT, YOU AGREE THAT THE ORIGINAL AUTHOR
ECHO   IS NOT RESPONSIBLE FOR ANY UNWANTED CHANGES YOU MAKE.
ECHO.
ECHO   GitHub: x87e
ECHO   Reddit: u/dx0100
ECHO.
ECHO - Most issues can be resolved quickly with a few online searches.
ECHO.
PAUSE
GOTO MENU

:1NEWHTML
CLS
ECHO.
ECHO Adding custom HTML "New" template...
ECHO.

:: Confirm action
CHOICE /C YN /M "Proceed with adding the registry entry and template file? (y/n)?"
IF ERRORLEVEL 2 GOTO MENU

:: Define paths
SET "TemplateDir=%APPDATA%\Microsoft\Windows\Templates"
SET "TemplateFile=%TemplateDir%\HTMLTemplate.html"

:: Create directory if needed
IF NOT EXIST "%TemplateDir%" MKDIR "%TemplateDir%"

:: Create the template file (basic HTML5 template)
(
ECHO ^<!DOCTYPE html^>
ECHO ^<html lang="en"^>
ECHO ^<head^>
ECHO     ^<meta charset="utf-8"^>
ECHO     ^<title^>New HTML Document^</title^>
ECHO ^</head^>
ECHO ^<body^>
ECHO.
ECHO ^</body^>
ECHO ^</html^>
) > "%TemplateFile%"

:: Add registry entry
REG ADD "HKEY_CLASSES_ROOT\.html\ShellNew" /v FileName /t REG_SZ /d "HTMLTemplate.html" /f >NUL

:: Verify if template file and registry entry were successfully created
ECHO.
ECHO Verifying:
ECHO ----------

:: Check if the file is there
IF EXIST "%TemplateFile%" (
    ECHO Template file successfully created in: %TemplateFile%
) ELSE (
    ECHO HTML template file wasn't created in: %TemplateFile%
    ECHO Please create the file yourself or try and run the script again as admin.
)

:: Check registry value was created
REG QUERY "HKEY_CLASSES_ROOT\.html\ShellNew" /v FileName >NUL 2>&1
IF %ERRORLEVEL%==0 (
    FOR /F "tokens=3" %%A IN ('REG QUERY "HKEY_CLASSES_ROOT\.html\ShellNew" /v FileName ^| FIND "FileName"') DO SET "RegValue=%%A"
    IF /I "%RegValue%"=="HTMLTemplate.html" (
        ECHO Registry entry successfully added!
    ) ELSE (
        ECHO Registry value exists but is incorrect: %RegValue%
    )
) ELSE (
    ECHO Registry entry not found. Try to run script again as admin.
)

ECHO.
PAUSE
GOTO MENU

:2REMOVEHTML
CLS
ECHO.
ECHO Removing "New" custom HTML template and registry entry...
ECHO.

:: Ask user to confirm
CHOICE /C YN /M "Remove the registry entry and template file? (y/n)?"
IF ERRORLEVEL 2 GOTO MENU

:: Define paths for readability
SET "TemplateDir=%APPDATA%\Microsoft\Windows\Templates"
SET "TemplateFile=%TemplateDir%\HTMLTemplate.html"

:: Delete the registry value first
REG DELETE "HKEY_CLASSES_ROOT\.html\ShellNew" /v FileName /f >NUL 2>&1

:: Then delete the ShellNew key if empty
REG QUERY "HKEY_CLASSES_ROOT\.html\ShellNew" >NUL 2>&1
IF %ERRORLEVEL%==1 (
    REG DELETE "HKEY_CLASSES_ROOT\.html\ShellNew" /f >NUL 2>&1
)

:: Finally delete the template file
IF EXIST "%TemplateFile%" DEL /F /Q "%TemplateFile%" >NUL

:: Verify if successful
ECHO.
ECHO Verifying file and registry changes...
ECHO. 

:: Check file
IF NOT EXIST "%TemplateFile%" (
    ECHO Template file successfully deleted.
) ELSE (
    ECHO Template file still exists: %TemplateFile%
    ECHO Please locate and delete it manually or try and run the script as admin.
)

:: Check registry
REG QUERY "HKEY_CLASSES_ROOT\.html\ShellNew" /v FileName >NUL 2>&1
IF %ERRORLEVEL%==0 (
    ECHO Deletion failed, registry value still exists.
    ECHO Please delete key and value manually from: HKEY_CLASSES_ROOT\.html\ShellNew - FileName.
    ECHO If not, try and run the script as admin or contact the author.
) ELSE (
    ECHO Successfully deleted the registry entry.
)

ECHO.
PAUSE
GOTO MENU

:3CREATECSS
CLS
ECHO.
ECHO Adding custom CSS "New" template...
ECHO.

:: Confirm action
CHOICE /C YN /M "Proceed with adding the registry entry and template file? (y/n)?"
IF ERRORLEVEL 2 GOTO MENU

:: Define paths
SET "TemplateDir=%APPDATA%\Microsoft\Windows\Templates"
SET "TemplateFile=%TemplateDir%\CSSTemplate.css"

:: Create directory if needed
IF NOT EXIST "%TemplateDir%" MKDIR "%TemplateDir%"

:: Create the template file (minimal CSS reset)
(
ECHO /* Minimal CSS Reset */
ECHO.
ECHO *,
ECHO *::before,
ECHO *::after {
ECHO     box-sizing: border-box;
ECHO     margin: 0;
ECHO     padding: 0;
ECHO }
ECHO.
ECHO body {
ECHO     min-height: 100vh;
ECHO     line-height: 1.5;
ECHO     font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
ECHO }
ECHO.
ECHO h1, h2, h3, h4, h5, h6 {
ECHO     margin: 0;
ECHO     font-weight: normal;
ECHO     line-height: 1.2;
ECHO }
ECHO.
ECHO p {
ECHO     margin: 0;
ECHO }
ECHO.
ECHO ul, ol {
ECHO     list-style: none;
ECHO }
ECHO.
ECHO img {
ECHO     max-width: 100%%;
ECHO     display: block;
ECHO }
ECHO.
ECHO /* Add your custom styles below */
) > "%TemplateFile%"

:: Add registry entry
REG ADD "HKEY_CLASSES_ROOT\.css\ShellNew" /v FileName /t REG_SZ /d "CSSTemplate.css" /f >NUL

:: Verify if template file and registry entry were successfully created
ECHO.
ECHO Verifying:
ECHO ----------

:: Check if the file is there
IF EXIST "%TemplateFile%" (
    ECHO Template file successfully created in: %TemplateFile%
) ELSE (
    ECHO CSS template file wasn't created in: %TemplateFile%
    ECHO Please create the file yourself or try and run the script again as admin.
)

:: Check registry value was created
REG QUERY "HKEY_CLASSES_ROOT\.css\ShellNew" /v FileName >NUL 2>&1
IF %ERRORLEVEL%==0 (
    FOR /F "tokens=3" %%A IN ('REG QUERY "HKEY_CLASSES_ROOT\.css\ShellNew" /v FileName ^| FIND "FileName"') DO SET "RegValue=%%A"
    IF /I "%RegValue%"=="CSSTemplate.css" (
        ECHO Registry entry successfully added!
    ) ELSE (
        ECHO Registry value exists but is incorrect: %RegValue%
    )
) ELSE (
    ECHO Registry entry not found. Try to run script again as admin.
)

ECHO.
PAUSE
GOTO MENU

:4REMOVECSS
CLS
ECHO.
ECHO Removing "New" custom CSS template and registry entry...
ECHO.

:: Ask user to confirm
CHOICE /C YN /M "Remove the registry entry and template file? (y/n)?"
IF ERRORLEVEL 2 GOTO MENU

:: Define paths for readability
SET "TemplateDir=%APPDATA%\Microsoft\Windows\Templates"
SET "TemplateFile=%TemplateDir%\CSSTemplate.css"

:: Delete the registry value first
REG DELETE "HKEY_CLASSES_ROOT\.css\ShellNew" /v FileName /f >NUL 2>&1

:: Then delete the ShellNew key if empty
REG QUERY "HKEY_CLASSES_ROOT\.css\ShellNew" >NUL 2>&1
IF %ERRORLEVEL%==1 (
    REG DELETE "HKEY_CLASSES_ROOT\.css\ShellNew" /f >NUL 2>&1
)

:: Finally delete the template file
IF EXIST "%TemplateFile%" DEL /F /Q "%TemplateFile%" >NUL

:: Verify if successful
ECHO.
ECHO Verifying file and registry changes...
ECHO. 

:: Check file
IF NOT EXIST "%TemplateFile%" (
    ECHO Template file successfully deleted.
) ELSE (
    ECHO Template file still exists: %TemplateFile%
    ECHO Please locate and delete it manually or try and run the script as admin.
)

:: Check registry
REG QUERY "HKEY_CLASSES_ROOT\.css\ShellNew" /v FileName >NUL 2>&1
IF %ERRORLEVEL%==0 (
    ECHO Deletion failed, registry value still exists.
    ECHO Please delete key and value manually from: HKEY_CLASSES_ROOT\.css\ShellNew - FileName.
    ECHO If not, try and run the script as admin or contact the author.
) ELSE (
    ECHO Successfully deleted the registry entry.
)

ECHO.
PAUSE
GOTO MENU

:5REFRESH
CLS
ECHO.
ECHO 	Refreshing Windows Explorer to apply "New" menu changes...
ie4uinit.exe -show
ECHO 	Done. Check the "New" context menu in Explorer to confirm your changes were successful.
ECHO.
PAUSE
GOTO MENU

:END
EXIT