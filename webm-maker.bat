@echo off

:: Necessary for some loop and branching operations ::
setlocal enabledelayedexpansion
:: Max 4chan file size for webm's, slightly reduced because ffmpeg averages the bitrate and it can become slightly bigger than the max size, even with perfect calculation
set max_file_size=2900

:: Check if script was started with a proper parameter ::
if "%~1" == "" (
	echo This script needs to be run by dragging and dropping a video file on it.
	echo It cannot do anything by itself.
	pause
	goto :EOF
)

:: Hello user ::
echo 4chan webm maker
echo by Cephei
echo Including changes by skr1p7k1dd
:: Time for some setup ::
cd /d "%~dp0"

echo Note: There is no input checking so make sure you type one of the proper options or leave blank for the default. (e.g. just press enter)
echo.

:: Ask user about resolution
echo Enter new webm vertical resolution. The horizontal resolution will scale accordingly.
echo Example input: "720" to scale to 720p (vertical)
echo Default: Source video resolution.
set /p resolution="Enter: " %=%
if not "%resolution%" == "" (
	set resolutionset=scale=-1:%resolution%
)
 echo.

:: Ask about rotation
echo Set the new rotation. Choose 1, 2, 3, 4 or leave blank to skip
echo 0 = 90Deg CounterClockwise and Vertical Flip
echo 1 = 90Deg Clockwise
echo 2 = 90Deg CounterClockwise
echo 3 = 90Deg Clockwise and Vertical Flip
echo Default: Same as source

set /p rotate="Enter: " %=%
if not "%rotate%" == "" (
	set rotateset="transpose=%rotate%"
)
echo.

:: Set vf flag
if not "%rotate%" == "" (
	set vfset=-vf
)
if not "%resolution%" == "" (
	set vfset=-vf
)

:: Ask user if they want audio
echo Do you want to keep the audio? (Type anything to remove audio)
echo Note: Most boards on 4chan don't allow webms with audio
echo Default: Keep audio
set /p removeaudio="Enter: " %=%
if not "%removeaudio%" == "" (
	echo Removing audio
	set audioset=-an
) else (
	echo Keeping audio
)
echo. 

:: Ask user where to start webm rendering in source video ::
echo Please enter webm start offset in SECONDS.
echo (Use this to crop off the beginning parts you want to skip)
echo Example: 31
echo Default: Start of source video.
set /p start="Enter: " %=%
if not "%start%" == "" (
	set startset=-ss %start%
)
echo.

:: Ask user for length of rendering ::
echo Please enter webm length in SECONDS.
echo (Use this to crop off the end parts you want to remove)
echo Example: 15
echo Default: Entire source video.
set /p length="Enter: " %=%
if not "%length%" == "" (
	set lengthset=-t %length%
) else (
	ffmpeg.exe -i %1 2> webm.tmp
	for /f "tokens=1,2,3,4,5,6 delims=:., " %%i in (webm.tmp) do (
		if "%%i"=="Duration" call :calculatelength %%j %%k %%l %%m
	)
	del webm.tmp
	echo Using source video length: !length! seconds
)
echo.

:: Find bitrate that maxes out max filesize on 4chan, defined above ::
set /a bitrate=8*%max_file_size%/%length%
echo Target bitrate: %bitrate%

:: Two pass encoding because reasons ::
ffmpeg.exe -i "%~1" -c:v libvpx -b:v %bitrate%K -quality best %vfset% %resolutionset% %rotateset% %startset% %lengthset% %audioset% -sn -threads 0 -f webm -pass 1 -y NUL
ffmpeg.exe -i "%~1" -c:v libvpx -b:v %bitrate%K -quality best %vfset% %resolutionset% %rotateset% %startset% %lengthset% %audioset% -sn -threads 0 -pass 2 -y "%~n1.webm"
del ffmpeg2pass-0.log

:: Finished
echo.
echo Finished! If you didn't see any red error text above then it probably worked. Look for the file in this folder.
echo Press any key to exit...
pause >nul

:: Helper function to calculate length of video ::
:calculatelength
	for /f "tokens=* delims=0" %%a in ("%3") do set /a s=%%a
	for /f "tokens=* delims=0" %%a in ("%2") do set /a s=s+%%a*60
	for /f "tokens=* delims=0" %%a in ("%1") do set /a s=s+%%a*60*60
	set /a length=s
