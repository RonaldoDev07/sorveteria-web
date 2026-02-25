@echo off
echo ========================================
echo BUILD E DEPLOY - Sorveteria Web
echo ========================================
echo.

echo [1/3] Fazendo build do Flutter...
C:\flutter\bin\flutter.bat build web --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERRO: Build falhou!
    pause
    exit /b 1
)

echo.
echo [2/3] Adicionando arquivos ao Git...
git add -A

echo.
echo [3/3] Fazendo commit e push...
git commit -m "Update API URL to v3 and rebuild"
git push origin main

echo.
echo ========================================
echo DEPLOY CONCLUIDO!
echo ========================================
echo.
echo Aguarde 1-2 minutos e acesse:
echo https://sorveteria-web-one.vercel.app
echo.
pause
