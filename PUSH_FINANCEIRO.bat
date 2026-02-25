@echo off
chcp 65001 >nul
echo ========================================
echo   PUSH - MÓDULO FINANCEIRO
echo ========================================
echo.

echo [1/3] Adicionando arquivos ao git...
git add .
if errorlevel 1 (
    echo ❌ Erro ao adicionar arquivos
    pause
    exit /b 1
)
echo.

echo [2/3] Fazendo commit...
git commit -m "feat: adicionar módulo de clientes ao financeiro"
if errorlevel 1 (
    echo ⚠️ Nada para commitar ou erro no commit
    echo.
)
echo.

echo [3/3] Fazendo push para GitHub...
git push origin main
if errorlevel 1 (
    echo ❌ Erro ao fazer push
    pause
    exit /b 1
)
echo.

echo ========================================
echo   ✅ PUSH CONCLUÍDO COM SUCESSO!
echo ========================================
echo.
echo Deploy automático iniciado na Vercel
echo Aguarde 3-5 minutos
echo.
echo URL: https://sorveteria-web-one.vercel.app
echo.
pause
