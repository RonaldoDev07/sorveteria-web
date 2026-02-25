@echo off
echo ========================================
echo Adicionar Flutter ao PATH
echo ========================================
echo.

REM Verificar se C:\flutter existe
if not exist "C:\flutter\bin\flutter.bat" (
    echo [ERRO] Flutter nao encontrado em C:\flutter
    echo.
    echo Por favor:
    echo 1. Baixe o Flutter
    echo 2. Extraia o ZIP
    echo 3. Mova a pasta 'flutter' para C:\
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter encontrado em C:\flutter
echo.
echo Adicionando ao PATH...

REM Adicionar ao PATH do usuario
setx PATH "%PATH%;C:\flutter\bin"

echo.
echo ========================================
echo Concluido!
echo ========================================
echo.
echo IMPORTANTE:
echo 1. Feche TODOS os terminais abertos
echo 2. Abra um NOVO terminal
echo 3. Execute: flutter --version
echo.
echo Se aparecer a versao do Flutter, esta instalado!
echo.
pause
