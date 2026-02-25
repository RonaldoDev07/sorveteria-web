Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BUILD E DEPLOY - Sorveteria Web" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Obter o diretório do script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "[1/4] Verificando diretório..." -ForegroundColor Yellow
Write-Host "Diretório atual: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERRO: pubspec.yaml não encontrado!" -ForegroundColor Red
    Write-Host "Execute este script da pasta sorveteria-web-deploy" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[2/4] Fazendo build do Flutter..." -ForegroundColor Yellow
& "C:\flutter\bin\flutter.bat" build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO: Build falhou!" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "[3/4] Adicionando arquivos ao Git..." -ForegroundColor Yellow
git add -A

Write-Host ""
Write-Host "[4/4] Fazendo commit e push..." -ForegroundColor Yellow
git commit -m "Update API URL to v3 and rebuild"
git push origin main

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOY CONCLUÍDO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Aguarde 1-2 minutos e acesse:" -ForegroundColor Cyan
Write-Host "https://sorveteria-web-one.vercel.app" -ForegroundColor White
Write-Host ""
pause
