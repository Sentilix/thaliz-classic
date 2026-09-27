@echo off
set ADDONNAME=Thaliz
set SOURCE=%~dp0
set TARGET=C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\
set FOREVER=C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\
set ANNIVERSARY=C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\
set MODERN=C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\

rem *** Classic Era:
copy %SOURCE%\%ADDONNAME%\*.txt "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.lua "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.toc "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.xml "%TARGET%\%ADDONNAME%\" /Y

rem *** Anniversary:
copy %SOURCE%\%ADDONNAME%\*.txt "%ANNIVERSARY%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.lua "%ANNIVERSARY%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.toc "%ANNIVERSARY%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.xml "%ANNIVERSARY%\%ADDONNAME%\" /Y

rem *** Forever beta:
copy %SOURCE%\%ADDONNAME%\*.txt "%FOREVER%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.lua "%FOREVER%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.toc "%FOREVER%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.xml "%FOREVER%\%ADDONNAME%\" /Y

rem *** MODERN:
copy %SOURCE%\%ADDONNAME%\*.txt "%MODERN%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.lua "%MODERN%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.toc "%MODERN%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.xml "%MODERN%\%ADDONNAME%\" /Y

echo.
