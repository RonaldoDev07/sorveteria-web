@echo off
echo ========================================
echo BUILD E DEPLOY LIMPO - CORRECAO PAGAMENTO
echo ========================================
echo.

REM Ir para o diretorio correto
cd /d "%~dp0"
echo Diretorio atual: %CD%
echo.

echo [1/5] Limpando build antigo...
C:\flutter\bin\flutter.bat clean
if errorlevel 1 (
    echo ERRO ao limpar build!
    pause
    exit /b 1
)
echo OK - Build limpo
echo.

echo [2/5] Obtendo dependencias...
C:\flutter\bin\flutter.bat pub get
if errorlevel 1 (
    echo ERRO ao obter dependencias!
    pause
    exit /b 1
)
echo OK - Dependencias obtidas
echo.

echo [3/5] Compilando para web...
C:\flutter\bin\flutter.bat build web --release --web-renderer canvaskit
if errorlevel 1 (
    echo ERRO ao compilar!
    pause
    exit /b 1
)
echo OK - Compilacao concluida
echo.

echo [4/5] Adicionando arquivos ao git...
git add build/web
git add lib/
git status
echo.

echo [5/5] Fazendo commit e push...
git commit -m "feat: buscar detalhes completos da venda ao abrir tela de detalhes"
git push origin main
if errorlevel 1 (
    echo ERRO ao fazer push!
    pause
    exit /b 1
)
echo.

echo ========================================
echo DEPLOY CONCLUIDO COM SUCESSO!
echo ========================================
echo.
echo Aguarde 2-3 minutos para o Vercel fazer o deploy
echo Depois limpe o cache do navegador (Ctrl+Shift+Delete)
echo E recarregue a pagina (Ctrl+Shift+R)
echo.
pause
