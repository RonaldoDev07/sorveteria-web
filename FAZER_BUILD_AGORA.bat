@echo off
chcp 65001 >nul
echo ========================================
echo   BUILD CORRIGIDO - MÓDULO FINANCEIRO
echo ========================================
echo.

echo [1/4] Limpando build anterior...
C:\flutter\bin\flutter.bat clean
echo.

echo [2/4] Instalando dependências (versão corrigida)...
C:\flutter\bin\flutter.bat pub get
if errorlevel 1 (
    echo ❌ Erro ao instalar dependências
    pause
    exit /b 1
)
echo.

echo [3/4] Fazendo build para web...
C:\flutter\bin\flutter.bat build web --release
if errorlevel 1 (
    echo ❌ Erro ao fazer build
    pause
    exit /b 1
)
echo.

echo [4/4] Fazendo commit e push...
git add .
git commit -m "fix: corrigir versão do intl e fazer build do módulo financeiro"
git push origin main
echo.

echo ========================================
echo   ✅ BUILD E DEPLOY CONCLUÍDOS!
echo ========================================
echo.
echo Aguarde 3-5 minutos para o deploy na Vercel completar.
echo URL: https://sorveteria-web-one.vercel.app
echo.
echo Teste o módulo:
echo 1. Faça login
echo 2. Clique no card "Financeiro" 💳
echo 3. Teste cadastrar/editar/excluir clientes
echo.
pause
