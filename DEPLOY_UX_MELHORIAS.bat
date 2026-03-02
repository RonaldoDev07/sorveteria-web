@echo off
echo ========================================
echo DEPLOY - Melhorias de UX
echo ========================================
echo.

echo [1/3] Adicionando arquivos ao Git...
git add lib/screens/home_screen.dart
git add lib/screens/financeiro/historico_completo_screen.dart

echo.
echo [2/3] Fazendo commit...
git commit -m "UX: Adicionar botão Compra a Prazo, renomear Histórico e adicionar cancelamento no Histórico Completo"

echo.
echo [3/3] Enviando para GitHub...
git push origin main

echo.
echo ========================================
echo DEPLOY CONCLUIDO!
echo ========================================
echo.
pause
