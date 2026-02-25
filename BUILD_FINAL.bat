@echo off
echo ========================================
echo BUILD FINAL COM TIMEOUT AUMENTADO
echo ========================================
echo.

echo [1/4] Limpando build anterior...
rmdir /s /q build\web 2>nul

echo.
echo [2/4] Fazendo build do Flutter...
echo (Isso pode demorar 2-3 minutos)
echo.
C:\flutter\bin\flutter.bat build web --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ ERRO NO BUILD!
    pause
    exit /b 1
)

echo.
echo [3/4] Adicionando ao Git...
git add -A

echo.
echo [4/4] Fazendo commit e push...
git commit -m "Fix: Add timeout to all HTTP requests for iPhone compatibility"
git push origin main

echo.
echo ========================================
echo BUILD E PUSH CONCLUIDOS!
echo ========================================
echo.
echo Aguarde 1-2 minutos e teste:
echo https://sorveteria-web-one.vercel.app
echo.
echo O timeout foi aumentado para 90 segundos.
echo Isso deve resolver o problema no iPhone!
echo.
pause
