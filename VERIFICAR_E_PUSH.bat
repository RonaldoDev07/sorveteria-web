@echo off
echo ========================================
echo VERIFICAR E FAZER PUSH
echo ========================================
echo.

echo Verificando status do Git...
git status

echo.
echo ========================================
echo.
echo Se aparecer "build/web" na lista acima,
echo significa que o build precisa ser commitado.
echo.
echo Pressione qualquer tecla para fazer o push...
pause > nul

echo.
echo Adicionando arquivos...
git add -A

echo.
echo Fazendo commit...
git commit -m "Update API URL to v3 and rebuild"

echo.
echo Fazendo push...
git push origin main

echo.
echo ========================================
echo PUSH CONCLUIDO!
echo ========================================
echo.
echo Aguarde 1-2 minutos e teste novamente.
echo.
pause
