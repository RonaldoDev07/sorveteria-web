@echo off
echo ========================================
echo BUILD - Formatacao Automatica
echo ========================================
echo.

cd /d "C:\Users\PC\3D Objects\Aplicativo para controle de estoque 3 celulares\sorveteria-web-deploy"

set FLUTTER_PATH=C:\flutter\bin\flutter.bat

echo [1/4] Limpando build anterior...
if exist build\web rmdir /s /q build\web
echo.

echo [2/4] Fazendo build do Flutter...
%FLUTTER_PATH% build web --release
if errorlevel 1 (
    echo ERRO no build!
    pause
    exit /b 1
)
echo.

echo [3/4] Adicionando ao Git...
git add .
git commit -m "build: adicionar formatacao automatica de CPF/CNPJ e telefone"
echo.

echo [4/4] Enviando para GitHub...
git push
echo.

echo ========================================
echo DEPLOY CONCLUIDO!
echo Aguarde 1-2 minutos para o Vercel atualizar
echo ========================================
pause
