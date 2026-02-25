@echo off
echo ========================================
echo FAZENDO PUSH PARA O GITHUB
echo ========================================
echo.

git add -A
git commit -m "Update API URL to v3 and rebuild"
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo PUSH CONCLUIDO COM SUCESSO!
    echo ========================================
    echo.
    echo Aguarde 1-2 minutos e acesse:
    echo https://sorveteria-web-one.vercel.app
    echo.
    echo Depois limpe o cache do iPhone!
    echo.
) else (
    echo.
    echo ========================================
    echo ERRO NO PUSH!
    echo ========================================
    echo.
)

pause
