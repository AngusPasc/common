@echo off

rem **************************************************************************
rem *
rem * Copyright 2016 Tim De Baets
rem *
rem * Licensed under the Apache License, Version 2.0 (the "License");
rem * you may not use this file except in compliance with the License.
rem * You may obtain a copy of the License at
rem *
rem *     http://www.apache.org/licenses/LICENSE-2.0
rem *
rem * Unless required by applicable law or agreed to in writing, software
rem * distributed under the License is distributed on an "AS IS" BASIS,
rem * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem * See the License for the specific language governing permissions and
rem * limitations under the License.
rem *
rem **************************************************************************
rem *
rem * Delphi-specific compile script
rem *
rem **************************************************************************

setlocal

rem  Units in LibFixed to compile separately
set LIBFIXED_UNITS= ^
    Controls.pas ^
    ComCtrls.pas

rem  Units in Imports to compile separately
set IMPORTS_UNITS= ^
    SHDocVw_TLB.pas

rem Units in LibUser to compile separately
set LIBUSER_UNITS= ^
    GIFImage.pas ^
    HugeIni.pas ^
    MBCSUtil.pas ^
    NewDialogs.pas ^
    PEStruct.pas ^
    ShellApi2.pas ^
    ShlObj2.pas ^
    uProcessMemMgr.pas

set CFGFILE=
set OLDCFGFILE=

rem  Quiet compile / Build all / Output warnings
set DCC32OPTS=-Q -B -W

rem  Generate semi-unique string for temporary file renames
for /f "delims=:., tokens=1-4" %%t in ("%TIME: =0%") do (
    set UNIQUESTR=%%t%%u%%v%%w
)

rem  Retrieve user-specific compile settings from file
if exist ..\usercompilesettings.bat goto usercompilesettingsfound
:usercompilesettingserror
echo usercompilesettings.bat (in the root of the repository) is missing or
echo incomplete. It needs to be created with the following lines, adjusted
echo for your system:
echo.
echo   set DELPHIROOT=c:\delphi4              [Path to Delphi 4 (or later)]
goto failed2

:usercompilesettingsfound
set DELPHIROOT=
call ..\usercompilesettings.bat
if "%DELPHIROOT%"=="" goto usercompilesettingserror

set COMMON_LIB_PATH=..\LibFixed;%DELPHIROOT%\lib

rem -------------------------------------------------------------------------

rem  Compile each project separately because it seems Delphi carries some
rem  settings (e.g. $APPTYPE) between projects if multiple projects are
rem  specified on the command line.

rem  Always use 'master' .cfg file when compiling from the command line to
rem  prevent user options from hiding compile failures in official builds.
rem  Temporarily rename any user-generated .cfg file during compilation.

cd LibFixed
if errorlevel 1 goto failed

echo - LibFixed

"%DELPHIROOT%\bin\dcc32.exe" %DCC32OPTS% %1 ^
    -U"%COMMON_LIB_PATH%" -R"%DELPHIROOT%\lib" ^
    %LIBFIXED_UNITS%
if errorlevel 1 goto failed

cd ..

cd Imports
if errorlevel 1 goto failed

echo - Imports

"%DELPHIROOT%\bin\dcc32.exe" %DCC32OPTS% %1 ^
    -U"%COMMON_LIB_PATH%" ^ -R"%DELPHIROOT%\lib" ^
    %IMPORTS_UNITS%
if errorlevel 1 goto failed

cd ..

cd LibUser
if errorlevel 1 goto failed

echo - LibUser

"%DELPHIROOT%\bin\dcc32.exe" %DCC32OPTS% %1 ^
    -U"%COMMON_LIB_PATH%" ^ -R"%DELPHIROOT%\lib" ^
    %LIBUSER_UNITS%
if errorlevel 1 goto failed

echo - tdebaets_comps.dpk

rem  Rename user-generated .cfg file if it exists
if not exist tdebaets_comps.cfg goto tdebaets_comps
ren tdebaets_comps.cfg tdebaets_comps.cfg.%UNIQUESTR%
if errorlevel 1 goto failed
set OLDCFGFILE=tdebaets_comps.cfg

:tdebaets_comps
ren tdebaets_comps.cfg.main tdebaets_comps.cfg
if errorlevel 1 goto failed
set CFGFILE=tdebaets_comps.cfg
"%DELPHIROOT%\bin\dcc32.exe" %DCC32OPTS% %1 ^
    -U"%COMMON_LIB_PATH%;Virtual Treeview\Source;Virtual Treeview\Design" ^
    -R"%DELPHIROOT%\lib" ^
    tdebaets_comps.dpk
if errorlevel 1 goto failed
ren %CFGFILE% %CFGFILE%.main
set CFGFILE=
ren %OLDCFGFILE%.%UNIQUESTR% %OLDCFGFILE%
set OLDCFGFILE=

echo Success!
cd ..
goto exit

:failed
if not "%CFGFILE%"=="" ren %CFGFILE% %CFGFILE%.main
if not "%OLDCFGFILE%"=="" ren %OLDCFGFILE%.%UNIQUESTR% %OLDCFGFILE%
echo *** FAILED ***
cd ..
:failed2
exit /b 1

:exit
