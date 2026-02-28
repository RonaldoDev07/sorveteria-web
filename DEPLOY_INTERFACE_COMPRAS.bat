@echo off
echo ========================================
echo DEPLOY - Melhoria Interface Compras
echo ========================================
echo.

echo [1/3] Adicionando arquivos ao Git...
git add lib/screens/financeiro/compra_prazo_form_screen.dart

echo.
echo [2/3] Fazendo commit...
git commit -m "feat: melhorar interface dialog adicionar produto em compras a prazo"

echo.
echo [3/3] Enviando para GitHub...
git push origin main

echo.
echo ========================================
echo DEPLOY CONCLUIDO!
echo ========================================
echo.
echo Melhorias implementadas:
echo - Interface visual moderna com cards
echo - Campo de pesquisa melhorado
echo - Badges informativos (estoque e preco)
echo - Selecao visual destacada
echo - Area de confirmacao
echo - Logs de debug
echo.
echo O Vercel vai fazer o build automaticamente.
echo Aguarde 2-3 minutos e acesse: https://sorveteria-web-one.vercel.app
echo.
echo Teste: Gestao Financeira - Compras a Prazo - Nova Compra - Adicionar Produto
echo.
pause
