@echo off
echo ========================================
echo   BUILD E DEPLOY - MODULO FINANCEIRO
echo ========================================
echo.

echo [1/4] Limpando build anterior...
call flutter clean
echo.

echo [2/4] Instalando dependencias...
call flutter pub get
echo.

echo [3/4] Fazendo build para web...
call flutter build web --release
echo.

echo [4/4] Fazendo commit e push...
git add .
git commit -m "feat: adicionar modulo de clientes ao financeiro"
git push origin main
echo.

echo ========================================
echo   BUILD E DEPLOY CONCLUIDOS!
echo ========================================
echo.
echo Aguarde 3-5 minutos para o deploy na Vercel completar.
echo URL: https://sorveteria-web-one.vercel.app
echo.
pause
