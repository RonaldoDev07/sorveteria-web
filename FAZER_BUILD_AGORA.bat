@echo off
echo ========================================
echo FAZENDO BUILD DO FLUTTER
echo ========================================
echo.
echo Aguarde... isso pode demorar 1-2 minutos
echo.

C:\flutter\bin\flutter.bat build web --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo BUILD CONCLUIDO COM SUCESSO!
    echo ========================================
    echo.
    echo Agora execute: FAZER_PUSH_AGORA.bat
    echo.
) else (
    echo.
    echo ========================================
    echo ERRO NO BUILD!
    echo ========================================
    echo.
    echo Verifique se o Flutter esta instalado
    echo.
)

pause
