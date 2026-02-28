@echo off
cd /d "%~dp0"
echo Commitando debug...
git add lib/screens/financeiro/venda_prazo_form_screen.dart
git commit -m "debug: adicionar try-catch no dialog para capturar erro"
git push origin main
pause
