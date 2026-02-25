@echo off
echo ========================================
echo BUILD DIRETO - SEM LIMPEZA
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] Instalando dependencias...
C:\flutter\bin\flutter.bat pub get
echo OK!
echo.

echo [2/4] Fazendo build para web...
C:\flutter\bin\flutter.bat build web --release
echo OK!
echo.

echo [3/4] Adicionando arquivos ao git...
git add build/web
git add pubspec.yaml
git add lib
echo OK!
echo.

echo [4/4] Fazendo commit e push...
git commit -m "build: adicionar arquivos de build do modulo financeiro"
git push origin main
echo OK!
echo.

echo ========================================
echo BUILD E DEPLOY CONCLUIDOS!
echo ========================================
echo.
echo Aguarde 3-5 minutos para o deploy na Vercel completar.
echo URL: https://sorveteria-web-one.vercel.app
echo.
pause
