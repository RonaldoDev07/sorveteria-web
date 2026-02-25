@echo off
echo ========================================
echo Build e Deploy - Sorveteria Camila
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] Fazendo build do Flutter Web...
flutter build web --release

if %ERRORLEVEL% NEQ 0 (
    echo ERRO: Build falhou!
    pause
    exit /b 1
)

echo.
echo [2/3] Adicionando arquivos ao Git...
git add .

echo.
echo [3/3] Fazendo commit e push...
git commit -m "build: atualizar build web"
git push origin main

echo.
echo ========================================
echo Deploy concluido com sucesso!
echo ========================================
echo.
echo Aguarde 2-3 minutos para o Vercel processar.
echo Depois acesse: https://sorveteria-web-one.vercel.app
echo.
pause
