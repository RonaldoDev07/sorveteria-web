@echo off
chcp 65001 >nul
echo ========================================
echo   BUILD - MÓDULO FINANCEIRO
echo ========================================
echo.

REM Tentar encontrar Flutter
set FLUTTER_PATH=
if exist "C:\flutter\bin\flutter.bat" set FLUTTER_PATH=C:\flutter\bin\flutter.bat
if exist "C:\src\flutter\bin\flutter.bat" set FLUTTER_PATH=C:\src\flutter\bin\flutter.bat
if exist "%LOCALAPPDATA%\flutter\bin\flutter.bat" set FLUTTER_PATH=%LOCALAPPDATA%\flutter\bin\flutter.bat

if "%FLUTTER_PATH%"=="" (
    echo ❌ Flutter não encontrado!
    echo.
    echo Por favor, instale o Flutter:
    echo 1. Baixe: https://docs.flutter.dev/get-started/install/windows
    echo 2. Extraia em C:\flutter
    echo 3. Adicione C:\flutter\bin ao PATH
    echo.
    echo Ou execute manualmente:
    echo   flutter clean
    echo   flutter pub get
    echo   flutter build web --release
    echo.
    pause
    exit /b 1
)

echo ✅ Flutter encontrado em: %FLUTTER_PATH%
echo.

echo [1/3] Limpando build anterior...
call "%FLUTTER_PATH%" clean
if errorlevel 1 (
    echo ❌ Erro ao limpar build
    pause
    exit /b 1
)
echo.

echo [2/3] Instalando dependências...
call "%FLUTTER_PATH%" pub get
if errorlevel 1 (
    echo ❌ Erro ao instalar dependências
    pause
    exit /b 1
)
echo.

echo [3/3] Fazendo build para web...
call "%FLUTTER_PATH%" build web --release
if errorlevel 1 (
    echo ❌ Erro ao fazer build
    pause
    exit /b 1
)
echo.

echo ========================================
echo   ✅ BUILD CONCLUÍDO COM SUCESSO!
echo ========================================
echo.
echo Arquivos gerados em: build\web
echo.
echo Próximo passo: fazer commit e push
echo Execute: PUSH_FINANCEIRO.bat
echo.
pause
