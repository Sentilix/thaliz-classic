@echo off
set ADDONNAME=Thaliz
set SOURCE=%~dp0
set TARGET=C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\
set FOREVER=C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\

rem *** Classic Era:
copy %SOURCE%\%ADDONNAME%\*.txt "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.lua "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.toc "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.xml "%TARGET%\%ADDONNAME%\" /Y

rem *** Forever beta:
copy %SOURCE%\%ADDONNAME%\*.txt "%FOREVER%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.lua "%FOREVER%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.toc "%FOREVER%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.xml "%FOREVER%\%ADDONNAME%\" /Y

echo.
