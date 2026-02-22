@echo off
echo ========================================
echo Executando App Flutter - Sorveteria Camila
echo ========================================
echo.

cd /d "%~dp0"

echo Verificando dependencias...
C:\flutter\bin\flutter.bat pub get

echo.
echo Iniciando app no Chrome...
echo.
echo CREDENCIAIS:
echo Login: admin
echo Senha: Sorv@2026#Camila!
echo.
echo ========================================

C:\flutter\bin\flutter.bat run -d chrome

pause
