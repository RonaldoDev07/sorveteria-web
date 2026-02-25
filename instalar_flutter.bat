@echo off
echo ========================================
echo Instalador Automatico do Flutter
echo ========================================
echo.

REM Verificar se Flutter ja esta instalado
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Flutter ja esta instalado!
    flutter --version
    echo.
    goto BUILD
)

echo [1/4] Verificando se C:\flutter existe...
if exist "C:\flutter" (
    echo [OK] Flutter encontrado em C:\flutter
    echo.
    echo [2/4] Adicionando ao PATH...
    setx PATH "%PATH%;C:\flutter\bin"
    echo.
    echo [IMPORTANTE] Feche este terminal e abra um novo!
    echo Depois execute este script novamente.
    pause
    exit
)

echo [ERRO] Flutter nao encontrado!
echo.
echo Por favor, siga estes passos:
echo.
echo 1. Baixe o Flutter:
echo    https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip
echo.
echo 2. Extraia o arquivo ZIP
echo.
echo 3. Mova a pasta 'flutter' para C:\
echo    (O caminho final deve ser C:\flutter)
echo.
echo 4. Execute este script novamente
echo.
pause
exit

:BUILD
echo ========================================
echo Fazendo build do projeto
echo ========================================
echo.

cd /d "%~dp0"

echo [3/4] Instalando dependencias...
flutter pub get

echo.
echo [4/4] Fazendo build web...
flutter build web --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERRO] Build falhou!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build concluido com sucesso!
echo ========================================
echo.
echo Agora execute:
echo   git add build/web
echo   git commit -m "build: atualizar"
echo   git push origin main
echo.
pause
