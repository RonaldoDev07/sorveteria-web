@echo off
cd /d "%~dp0"
echo Commitando build/web...
git add -f build/web/
git commit -m "build: add build/web for vercel deployment"
git push origin main
pause
