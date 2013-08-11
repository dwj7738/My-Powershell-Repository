echo "Installing modules from %~dp0"
xcopy "%~dp0ShowUI" "%userprofile%\Documents\WindowsPowerShell\Modules\ShowUI" /y /s /i /d 

xcopy "%~dp0Pipeworks" "%userprofile%\Documents\WindowsPowerShell\Modules\Pipeworks" /y /s /i /d 

xcopy "%~dp0EZOut" "%userprofile%\Documents\WindowsPowerShell\Modules\EZOut" /y /s /i /d 

xcopy "%~dp0ScriptCop" "%userprofile%\Documents\WindowsPowerShell\Modules\ScriptCop" /y /s /i /d 

xcopy "%~dp0IsePackV2" "%userprofile%\Documents\WindowsPowerShell\Modules\IsePackV2" /y /s /i /d 

