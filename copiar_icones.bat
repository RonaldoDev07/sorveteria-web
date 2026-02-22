@echo off
echo Copiando icones...

REM Copiar icones da pasta web para build/web
xcopy /Y "web\icons\*.png" "build\web\icons\"

REM Copiar favicon
xcopy /Y "web\favicon.png" "build\web\"

echo.
echo ✅ Icones copiados com sucesso!
echo.
echo Agora faca upload da pasta build\web no Netlify
pause
