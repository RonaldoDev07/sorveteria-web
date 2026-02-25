@echo off
echo ========================================
echo VERIFICAR STATUS DO GIT
echo ========================================
echo.

echo Ultimo commit:
git log --oneline -1

echo.
echo ========================================
echo.

echo Arquivos modificados nao commitados:
git status --short

echo.
echo ========================================
echo.

echo Verificando se build/web esta no repositorio:
git ls-files build/web/*.js | findstr /C:"main.dart.js"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build esta no repositorio!
    echo.
    echo Verificando data do ultimo commit do build:
    git log -1 --format="%%ci" -- build/web/main.dart.js
) else (
    echo.
    echo ❌ Build NAO esta no repositorio!
    echo.
    echo Isso significa que o Vercel esta usando build antigo.
    echo.
)

echo.
echo ========================================
pause
