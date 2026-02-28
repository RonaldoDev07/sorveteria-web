@echo off
echo ========================================
echo DEPLOY - Correcao Strings R$ Quebradas
echo ========================================
echo.

echo [1/3] Adicionando arquivos ao Git...
git add lib/screens/financeiro/vendas_prazo_screen.dart
git add lib/screens/financeiro/compras_prazo_screen.dart
git add lib/screens/financeiro/parcelas_screen.dart

echo.
echo [2/3] Fazendo commit...
git commit -m "fix: corrigir strings R$ quebradas no modulo financeiro"

echo.
echo [3/3] Enviando para GitHub...
git push origin main

echo.
echo ========================================
echo DEPLOY CONCLUIDO!
echo ========================================
echo.
echo O Vercel vai detectar o push e fazer o build automaticamente.
echo Aguarde 2-3 minutos e acesse: https://sorveteria-web-one.vercel.app
echo.
echo Proximos passos:
echo 1. Aguardar 2-3 minutos
echo 2. Acessar o sistema
echo 3. Testar modulo financeiro
echo 4. Verificar console do navegador (F12)
echo.
pause
