@setlocal

@set TMPVER=1
@set TMPPRJ=tidy
@set TMPSRC=..\..
@set TMPBGN=%TIME%
@set TMPINS=D:\Projects\3rdParty.x64
@set TMPLOG=bldlog-1.txt
@set DOPAUSE=1
@set TMPGEN=Visual Studio 16 2019
@set TMPBR=next
@set TMPINDBG=1

@set TMPOPTS=-G "%TMPGEN%" -A x64
@set TMPOPTS=%TMPOPTS% -DCMAKE_INSTALL_PREFIX=%TMPINS%
@set TMPOPTS=%TMPOPTS% -DBUILD_SHARED_LIB=ON

:RPT
@if "%~1x" == "x" goto GOTCMD
@if "%~1x" == "NOPAUSEx" (
    @set DOPAUSE=0
) else (
    @set TMPOPTS=%TMPOPTS% %1
)
@shift
@goto RPT
:GOTCMD

@call chkmsvc %TMPPRJ%
@if "%TMPBR%x" == "x" goto DNBR
@call chkbranch %TMPBR%
@if ERRORLEVEL 1 goto BAD_BR
:DNBR

@echo Build %TMPPRJ% 64-bits %DATE% %TIME%, in %CD%, to  %TMPLOG% > %TMPLOG%

@if NOT EXIST %TMPSRC%\nul goto NOSRC

@echo Build source %TMPSRC%... all output to build log %TMPLOG%
@echo Build source %TMPSRC%... all output to build log %TMPLOG% >> %TMPLOG%

@if EXIST build-cmake.bat (
@call build-cmake >> %TMPLOG%
)

@if NOT EXIST %TMPSRC%\CMakeLists.txt goto NOCM

@echo Doing: 'cmake -S %TMPSRC% %TMPOPTS%'
@echo Doing: 'cmake -S %TMPSRC% %TMPOPTS%' >> %TMPLOG% 2>&1
@cmake -S %TMPSRC% %TMPOPTS% >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR1

@echo Doing: 'cmake --build . --config Debug'
@echo Doing: 'cmake --build . --config Debug'  >> %TMPLOG% 2>&1
@cmake --build . --config Debug  >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR2

@echo Doing: 'cmake --build . --config Release'
@echo Doing: 'cmake --build . --config Release'  >> %TMPLOG% 2>&1
@cmake --build . --config Release  >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR3

@fa4 "***" %TMPLOG%
@call elapsed %TMPBGN%
@echo Appears a successful build... see %TMPLOG%
@echo Note install location %TMPINS%
@if "%TMPINDBG%x" == "1x" (
@echo Will install Debug and Release
) else (
@echo Will only intall Release
)
@echo.

@REM ##############################################
@REM Check if should continue with install
@REM ##############################################
@if "%DOPAUSE%x" == "0x" goto DOINST
@choice /? >nul 2>&1
@if ERRORLEVEL 1 goto NOCHOICE
@choice /D N /T 10 /M "Pausing for 10 seconds. Def=N"
@if ERRORLEVEL 2 goto GOTNO
@goto DOINST
:NOCHOICE
@echo Appears OS does not have the 'choice' command!
@ask *** CONTINUE with install? *** Only y continues
@if ERRORLEVEL 2 goto NOASK
@if ERRORLEVEL 1 goto DOINST
@echo Skipping install to %TMPINST% at this time...
@echo.
@goto END
:NOASK
@echo 'ask' utility not found in path...
@echo.
@echo *** CONTINUE with install? *** Only Ctrl+c aborts...
@echo.
@pause

:DOINST
@echo Proceeding with INSTALL...
@echo.
@if NOT "%TMPINDBG%x" == "1x" goto DNDBGIN
@if EXIST install_manifest.txt @del install_manifest.txt
@echo Doing: 'cmake --build . --config Debug  --target INSTALL'
@echo Doing: 'cmake --build . --config Debug  --target INSTALL' >> %TMPLOG% 2>&1
@cmake --build . --config Debug  --target INSTALL >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR4
@if EXIST install_manifest.txt (
    @copy install_manifest.txt install_manifest_debug.txt >nul
    @call add2installs install_manifest.txt -o %TMPINS%\install_manifest.txt >> %TMPLOG%
)
:DNDBGIN

@if EXIST install_manifest.txt @del install_manifest.txt
@echo Doing: 'cmake --build . --config Release  --target INSTALL'
@echo Doing: 'cmake --build . --config Release  --target INSTALL' >> %TMPLOG% 2>&1
@cmake --build . --config Release  --target INSTALL >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR5
@if EXIST install_manifest.txt (
    @copy install_manifest.txt install_manifest_release.txt >nul
    @call add2installs install_manifest.txt -o %TMPINS%\install_manifest.txt >> %TMPLOG%
)

@fa4 " -- " %TMPLOG%

@call elapsed %TMPBGN%
@echo All done... see %TMPLOG%

@goto END

:BAD_BR
@echo Try to do 'git checkout %TMPBR%'
@git checkout %TMPBR% >> %TMPLOG% 2>&1
@call chkbranch %TMPBR%
@if ERRORLEVEL 1 goto NO_BR
@goto DNBR
:NO_BR
@echo.
@echo Unable to check out %TMPBR%! *** FIX ME ***
@echo.
@goto ISERR

:GOTNO
@echo.
@echo No install at this time, but there may be an updexe.bat to copy the EXE to c:\MDOS...
@echo.
@goto END

:NOSRC
@echo Can NOT locate source %TMPSRC%! *** FIX ME ***
@echo Can NOT locate source %TMPSRC%! *** FIX ME *** >> %TMPLOG%
@goto ISERR

:NOCM
@echo Can NOT locate %TMPSRC%\CMakeLists.txt!
@echo Can NOT locate %TMPSRC%\CMakeLists.txt! >> %TMPLOG%
@goto ISERR

:ERR1
@echo cmake configuration or generations ERROR
@echo cmake configuration or generations ERROR >> %TMPLOG%
@goto ISERR

:ERR2
@echo ERROR: Cmake build Debug FAILED!
@echo ERROR: Cmake build Debug FAILED! >> %TMPLOG%
@goto ISERR

:ERR3
@echo ERROR: Cmake build Release FAILED!
@echo ERROR: Cmake build Release FAILED! >> %TMPLOG%
@goto ISERR

:ERR4
@echo ERROR: Install Debug FAILED!
@echo ERROR: Install Debug  FAILED! >> %TMPLOG%
@goto ISERR

:ERR5
@echo ERROR: Install Release FAILED!
@echo ERROR: Install Release  FAILED! >> %TMPLOG%
@goto ISERR

:ISERR
@echo See %TMPLOG% for details...
@endlocal
@exit /b 1

:END
@endlocal
@exit /b 0

@REM eof
