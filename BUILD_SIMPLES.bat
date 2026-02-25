@echo off
echo ========================================
echo BUILD E DEPLOY - MODULO FINANCEIRO
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] Limpando build anterior...
C:\flutter\bin\flutter.bat clean
if %errorlevel% neq 0 (
    echo ERRO ao limpar build!
    pause
    exit /b 1
)
echo OK!
echo.

echo [2/5] Instalando dependencias...
C:\flutter\bin\flutter.bat pub get
if %errorlevel% neq 0 (
    echo ERRO ao instalar dependencias!
    pause
    exit /b 1
)
echo OK!
echo.

echo [3/5] Fazendo build para web...
C:\flutter\bin\flutter.bat build web --release
if %errorlevel% neq 0 (
    echo ERRO ao fazer build!
    pause
    exit /b 1
)
echo OK!
echo.

echo [4/5] Adicionando arquivos ao git...
git add .
if %errorlevel% neq 0 (
    echo ERRO ao adicionar arquivos!
    pause
    exit /b 1
)
echo OK!
echo.

echo [5/5] Fazendo commit e push...
git commit -m "build: adicionar arquivos de build do modulo financeiro"
git push origin main
if %errorlevel% neq 0 (
    echo ERRO ao fazer push!
    pause
    exit /b 1
)
echo OK!
echo.

echo ========================================
echo BUILD E DEPLOY CONCLUIDOS COM SUCESSO!
echo ========================================
echo.
echo Aguarde 3-5 minutos para o deploy na Vercel completar.
echo URL: https://sorveteria-web-one.vercel.app
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
