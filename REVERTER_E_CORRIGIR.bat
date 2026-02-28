@echo off
echo ========================================
echo REVERTER para commit com build funcionando
echo ========================================
echo.

echo [1/4] Voltando para commit 213c47a (tinha build)...
git reset --hard 213c47a

echo.
echo [2/4] Aplicando correcoes nos arquivos...
echo Aguarde...

echo.
echo [3/4] Fazendo commit das correcoes...
git add lib/screens/financeiro/
git commit -m "fix: corrigir strings R$ e melhorar interface (com build)"

echo.
echo [4/4] Forcando push...
git push origin main --force

echo.
echo ========================================
echo CONCLUIDO!
echo ========================================
echo.
echo O Vercel vai fazer deploy do build que estava funcionando.
echo Aguarde 2 minutos e acesse: https://sorveteria-web-one.vercel.app
echo.
pause
