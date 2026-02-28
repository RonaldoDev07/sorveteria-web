@echo off
echo ========================================
echo DEPLOY - Correcoes Strings e Interface
echo ========================================
echo.

echo [1/3] Adicionando arquivos corrigidos...
git add lib/screens/financeiro/parcelas_screen.dart
git add lib/screens/financeiro/vendas_prazo_screen.dart
git add lib/screens/financeiro/compras_prazo_screen.dart
git add lib/screens/financeiro/compra_prazo_form_screen.dart

echo.
echo [2/3] Fazendo commit...
git commit -m "fix: corrigir strings R$ e melhorar interface compras"

echo.
echo [3/3] Enviando para GitHub...
git push origin main

echo.
echo ========================================
echo DEPLOY CONCLUIDO!
echo ========================================
echo.
echo O Vercel vai fazer o build automaticamente.
echo Aguarde 3-5 minutos (build completo demora mais).
echo.
echo Acesse: https://sorveteria-web-one.vercel.app
echo.
pause
