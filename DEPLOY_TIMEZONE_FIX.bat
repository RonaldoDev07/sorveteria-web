@echo off
echo ========================================
echo DEPLOY - CORRECAO TIMEZONE
echo ========================================
echo.

echo [1/3] Adicionando arquivos ao Git...
git add -A

echo.
echo [2/3] Fazendo commit...
git commit -m "fix: Corrigir timezone em vendas e compras (Acre UTC-5)"

echo.
echo [3/3] Fazendo push...
git push

echo.
echo ========================================
echo DEPLOY CONCLUIDO!
echo ========================================
echo.
echo Aguarde alguns minutos para o Vercel fazer o deploy.
echo Depois recarregue a pagina com Ctrl+Shift+R
echo.
pause
