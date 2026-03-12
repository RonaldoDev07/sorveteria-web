@echo off
echo ========================================
echo BUILD E DEPLOY - REMOVER FORMA PAGAMENTO
echo ========================================
echo.

echo [1/4] Limpando build anterior...
if exist build rmdir /s /q build
echo.

echo [2/4] Fazendo build do Flutter...
C:\flutter\bin\flutter.bat build web --release --web-renderer html
if errorlevel 1 (
    echo ERRO no build do Flutter!
    pause
    exit /b 1
)
echo.

echo [3/4] Fazendo commit...
git add -A
git commit -m "fix: remover campo forma de pagamento de vendas/compras a prazo"
echo.

echo [4/4] Fazendo push para GitHub...
git push origin main
echo.

echo ========================================
echo BUILD E DEPLOY CONCLUIDO!
echo ========================================
echo.
echo O Vercel vai fazer o deploy automaticamente.
echo Aguarde alguns minutos e teste no app.
echo.
pause
