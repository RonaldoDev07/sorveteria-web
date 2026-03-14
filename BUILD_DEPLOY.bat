@echo off
cd /d "c:\Users\RonaldoDev\3D Objects\modificando esses\Aplicativo para controle de estoque 3 celulares\sorveteria-web-deploy"
echo Building Flutter web...
C:\flutter\bin\flutter.bat build web --release --web-renderer canvaskit
if %errorlevel% neq 0 (
    echo BUILD FAILED
    pause
    exit /b 1
)
echo Build OK. Committing...
git add -A
git add -f build/web
git commit -m "fix: corrigir email regex e remover prints de debug"
git push
echo DONE
pause
