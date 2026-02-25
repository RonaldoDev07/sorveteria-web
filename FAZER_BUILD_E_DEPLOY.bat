@echo off
echo ========================================
echo   BUILD E DEPLOY DO FRONTEND
echo ========================================
echo.

echo [1/4] Limpando build anterior...
if exist build rmdir /s /q build
echo ✓ Build anterior removido
echo.

echo [2/4] Fazendo build do Flutter Web...
echo Isso pode demorar 3-5 minutos...
flutter build web --release
if errorlevel 1 (
    echo ❌ ERRO no build!
    pause
    exit /b 1
)
echo ✓ Build concluído com sucesso!
echo.

echo [3/4] Adicionando arquivos ao Git...
git add build/web
git add .
git status
echo.

echo [4/4] Fazendo commit e push...
git commit -m "build: Atualizar build do frontend com correção de CORS"
git push origin main
if errorlevel 1 (
    echo ❌ ERRO no push!
    pause
    exit /b 1
)
echo.

echo ========================================
echo   ✓ DEPLOY INICIADO COM SUCESSO!
echo ========================================
echo.
echo Aguarde 2-3 minutos para o deploy completar na Vercel.
echo Depois acesse: https://sorveteria-web-one.vercel.app
echo.
pause
