@echo off
echo ========================================
echo FORCE REBUILD - Corrigir Codigo Minificado
echo ========================================
echo.

echo [1/3] Adicionando arquivo de force rebuild...
git add FORCE_REBUILD_V16.txt

echo.
echo [2/3] Fazendo commit...
git commit -m "build: force rebuild para corrigir codigo minificado (NoSuchMethodError produtoId)"

echo.
echo [3/3] Enviando para GitHub...
git push origin main

echo.
echo ========================================
echo DEPLOY CONCLUIDO!
echo ========================================
echo.
echo O Vercel vai fazer um REBUILD COMPLETO do Flutter.
echo Isso pode demorar 3-5 minutos (mais que o normal).
echo.
echo Aguarde e acesse: https://sorveteria-web-one.vercel.app
echo.
echo Teste novamente:
echo 1. Gestao Financeira - Vendas a Prazo
echo 2. Clique em uma venda
echo 3. Deve abrir os detalhes sem erro
echo.
pause
