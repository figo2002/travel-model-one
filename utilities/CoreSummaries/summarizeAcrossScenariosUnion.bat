::
:: This version of summarizeAcrossScenarios.bat does not bother creating the extracts but instead copies the text files
:: over to use the union feature of Tableau
::
set USAGE=USAGE: summarizeAcrossScenariosUnion [current or all]
:: Run from M:\Application\Model One
::
:: Uses scenario list in \\mainmodel\MainModelShare\travel-model-one-master\utilities\RTP\ModelRuns.csv
::
:: For all, will include all runs in just copy ScenarioKey.csv and topsheet
:: For current, will include only runs marked with status=current and copies all core_summaries, transit and loaded network files
::

@echo off
setlocal enabledelayedexpansion

set MODEL_RUNS_CSV=\\mainmodel\MainModelShare\travel-model-one-master\utilities\RTP\ModelRuns.csv
set SET_TYPE=current

echo Argument 1=[%1]
if all==%1 (
  set SET_TYPE=all
  set COMBINED_DIR=M:\Application\Model One\All_Topsheets
) else (
  if current==%1 (
    set SET_TYPE=current
    set /p COMBINED_DIR="What across-runs directory do you want to use? "
    echo COMBINED_DIR=[!COMBINED_DIR!]
    if [!COMBINED_DIR!]==[] ( goto done )
  ) else (
    echo %USAGE%
    goto done
  )
)

rem set RUN_NAME_SET=
for /f "skip=1 tokens=1,2,3,4,5,6,7,8 delims=," %%A in (%MODEL_RUNS_CSV%) do (
  set project=%%A
  set year=%%B
  set directory=%%C
  set run_set=%%D
  set category=%%E
  set urbansim_path=%%F
  set urbansim_runid=%%G
  set status=%%H

  rem this doesn't handle blank fields correctly so adjust
  if !urbansim_path!==current (
    set urbansim_path=
    set status=current
  )
  if !urbansim_runid!==current (
    set urbansim_runid=
    set status=current
  )
  echo project=[!project!] year=[!year!] directory=[!directory!] run_set=[!run_set!] category=[!category!] urbansim_path=[!urbansim_path!] urbansim_runid=[!urbansim_runid!] status=[!status!]

  set SUBDIR=unknown
  if !run_set!==DraftBlueprint (
    set SUBDIR=BluePrint
  )
  if !run_set!==IP (
    set SUBDIR=IncrementalProgress
  )
  if !project!==RTP2017 (
    set SUBDIR=Scenarios
  )

  if !SET_TYPE!==current (
    if !status!==current (
      set RUN_NAME_SET=!RUN_NAME_SET!!project!\!SUBDIR!\!directory! 
    )
  )
  if !SET_TYPE!==all (
    set RUN_NAME_SET=!RUN_NAME_SET!!project!\!SUBDIR!\!directory! 
  )
)
echo RUN_NAME_SET=[!RUN_NAME_SET!]
echo COMBINED_DIR=[!COMBINED_DIR!]

mkdir "!COMBINED_DIR!"

:: Set to 1 if running from the original model run directory
:: (e.g. subdirs = CTRAMP, database, hwy, INPUT, landuse, etc...)
:: Set to 0 if if running from from results directory
:: (e.g. M:\Application\, subdirs=INPUT,OUTPUT)
set ORIGINAL_RUNDIR=0

set CODE_DIR=X:\travel-model-one-master\model-files\scripts\core_summaries

IF %USERNAME%==lzorn (
  rem I AM SPECIAL
  set R_HOME=C:\Program Files\R\R-3.5.1
  set R_USER=%USERNAME%
  set R_LIBS_USER=C:\Users\%R_USER%\Documents\R\win-library\3.5
) ELSE (
  IF %USERNAME%==ftsang (
      set R_HOME=C:\Program Files\R\R-3.4.4
      set R_USER=%USERNAME%
      set R_LIBS_USER=C:\Users\%R_USER%\Documents\R\win-library\3.4
  ) ELSE (
  set R_HOME=C:\Program Files\R\R-3.5.2
  set R_USER=%USERNAME%
  set R_LIBS_USER=C:\Users\%R_USER%\Documents\R\win-library\3.5
  )
)


:: copy over the scenariokey
copy "%MODEL_RUNS_CSV%" "%COMBINED_DIR%\ScenarioKey.csv"

:: copy over topsheet
for %%R in (%RUN_NAME_SET%) DO (
  rem echo %%R
  rem echo %%~nxR
  if exist "%COMBINED_DIR%\topsheet_%%~nxR.csv" (
    echo File is already present: %COMBINED_DIR%\topsheet_%%~nxR.csv
  ) else (
    if not exist "%%R\OUTPUT\metrics\topsheet.csv" (
      echo File doesn't exist: %%R\OUTPUT\metrics\topsheet.csv
    ) else (
      copy "%%R\OUTPUT\metrics\topsheet.csv" "%COMBINED_DIR%\topsheet_%%~nxR.csv"
    )
  )
)

:: rem for "all" mode, topsheet is it
if !SET_TYPE!==all ( goto done )

:: copy over core_summary csv files
set FILES=ActiveTransport ActivityPattern AutomobileOwnership CommuteByEmploymentLocation CommuteByIncomeHousehold CommuteByIncomeJob JourneyToWork PerTripTravelTime TimeOfDay TimeOfDay_personsTouring TravelCost TripDistance VehicleMilesTraveled

for %%F in (%FILES%) DO (
  echo %%F
  for %%R in (%RUN_NAME_SET%) DO (
    rem echo %%R
    rem echo %%~nxR
    if exist "%COMBINED_DIR%\%%F_%%~nxR.csv" (
      echo File is already present: %COMBINED_DIR%\%%F_%%~nxR.csv
    ) else (
      if not exist "%%R\OUTPUT\core_summaries\%%F.csv" (
        echo File doesn't exist: %%R\OUTPUT\core_summaries\%%F.csv
      ) else (
        copy "%%R\OUTPUT\core_summaries\%%F.csv" "%COMBINED_DIR%\%%F_%%~nxR.csv"
      )
    )
  )
)

:: copy over avgload5period.csv files
for %%R in (%RUN_NAME_SET%) DO (
  rem echo %%R
  rem echo %%~nxR
  if exist "%COMBINED_DIR%\avgload5period_%%~nxR.csv" (
    echo File is already present: %COMBINED_DIR%\avgload5period_%%~nxR.csv
  ) else (
    if not exist "%%R\OUTPUT\avgload5period.csv" (
      echo File doesn't exist: %%R\OUTPUT\avgload5period.csv
    ) else (
      copy "%%R\OUTPUT\avgload5period.csv" "%COMBINED_DIR%\avgload5period_%%~nxR.csv"
    )
  )
)
  
:: copy over avgload5period_vehclasses.csv files
for %%R in (%RUN_NAME_SET%) DO (
  if exist "%COMBINED_DIR%\avgload5period_vehclasses_%%~nxR.csv" (
    echo File is already present: %COMBINED_DIR%\avgload5period_vehclasses_%%~nxR.csv
  ) else (
    if not exist "%%R\OUTPUT\avgload5period_vehclasses.csv" (
      echo File doesn't exist: %%R\OUTPUT\avgload5period_vehclasses.csv
    ) else (
      copy "%%R\OUTPUT\avgload5period_vehclasses.csv" "%COMBINED_DIR%\avgload5period_vehclasses_%%~nxR.csv"
    )
  )
)

:: copy over scenario_metrics.csv files
for %%R in (%RUN_NAME_SET%) DO (
  if exist "%COMBINED_DIR%\scenario_metrics_%%~nxR.csv" (
    echo File is already present: %COMBINED_DIR%\scenario_metrics_%%~nxR.csv
  ) else (
    if not exist "%%R\OUTPUT\metrics\scenario_metrics.csv" (
      echo File doesn't exist: %%R\OUTPUT\metrics\scenario_metrics.csv
    ) else (
      copy "%%R\OUTPUT\metrics\scenario_metrics.csv" "%COMBINED_DIR%\scenario_metrics_%%~nxR.csv"
    )
  )
)

:: copy over trnline.csv files
for %%R in (%RUN_NAME_SET%) DO (
  if exist "%COMBINED_DIR%\trnline_%%~nxR.csv" (
    echo File is already present: %COMBINED_DIR%\trnline_%%~nxR.csv
  ) else (
    if not exist "%%R\OUTPUT\trn\trnline.csv" (
      echo File doesn't exist: %%R\OUTPUT\trn\trnline.csv
    ) else (
      copy "%%R\OUTPUT\trn\trnline.csv" "%COMBINED_DIR%\trnline_%%~nxR.csv"
    )
  )
)

:: copy over trnlink.csv files
for %%R in (%RUN_NAME_SET%) DO (
  if exist "%COMBINED_DIR%\trnlink_%%~nxR.csv" (
    echo File is already present: %COMBINED_DIR%\trnlink_%%~nxR.csv
  ) else (
    if not exist "%%R\OUTPUT\trn\trnlink.csv" (
      echo File doesn't exist: %%R\OUTPUT\trn\trnlink.csv
    ) else (
      copy "%%R\OUTPUT\trn\trnlink.csv" "%COMBINED_DIR%\trnlink_%%~nxR.csv"
    )
  )
)

:done

:: c:\windows\system32\Robocopy.exe /E "X:\travel-model-one-master\utilities\CoreSummaries\tableau"       %COMBINED_DIR%
