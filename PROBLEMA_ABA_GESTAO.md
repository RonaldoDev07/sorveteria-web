# Problema: Aba de Gestão Financeira não aparece

## Causa Raiz
O Vercel está configurado para usar arquivos pré-buildados da pasta `build/web`, mas o build não está sendo atualizado quando o código muda.

## Solução
Você precisa ter o Flutter instalado no computador para fazer o build localmente antes de fazer push.

### Como resolver:

1. Instale o Flutter: https://docs.flutter.dev/get-started/install/windows

2. Depois de fazer mudanças no código, execute:
```bash
flutter build web --release
git add .
git commit -m "build: atualizar"
git push origin main
```

3. O Vercel vai detectar o novo build e fazer deploy automaticamente.

## Alternativa
Configurar o GitHub Actions para fazer o build automaticamente (já configurado no arquivo `.github/workflows/build.yml`).

O workflow vai rodar automaticamente quando você fizer push de mudanças na pasta `lib/`.
