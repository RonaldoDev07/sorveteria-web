@echo off
echo ========================================
echo FORCAR PUSH DO BUILD
echo ========================================
echo.

echo [1/5] Verificando arquivos do build...
dir build\web\*.js /b

echo.
echo [2/5] Forcando adicao do build/web...
git add -f build/web/

echo.
echo [3/5] Adicionando outros arquivos...
git add lib/config/api_config.dart

echo.
echo [4/5] Fazendo commit...
git commit -m "Update API URL to v3 and force rebuild"

echo.
echo [5/5] Fazendo push...
git push origin main

echo.
echo ========================================
echo PUSH CONCLUIDO!
echo ========================================
echo.
echo Aguarde 1-2 minutos e teste:
echo https://sorveteria-web-one.vercel.app
echo.
echo Depois limpe o cache do iPhone e reinicie!
echo.
pause
