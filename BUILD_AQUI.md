# 🚀 Como fazer o build e deploy

## Problema
O código da aba de Gestão Financeira está correto, mas o build não está atualizado.

## Solução Rápida (no PC com Flutter)

1. Abra o terminal nesta pasta
2. Execute:
```bash
flutter build web --release
git add build/web
git commit -m "build: atualizar com Gestão Financeira"
git push origin main
```

3. Aguarde 1-2 minutos e acesse: https://sorveteria-web-one.vercel.app

Pronto! A aba de Gestão Financeira vai aparecer! ✅

---

## O que foi feito
- ✅ Código da Gestão Financeira reimplementado (simples e funcional)
- ✅ Card adicionado na home (sem condições)
- ✅ Arquivos desnecessários removidos
- ⏳ Falta apenas fazer o build com Flutter

## Arquivos importantes
- `lib/screens/home_screen.dart` - Home com o card da Gestão Financeira
- `lib/screens/financeiro_screen.dart` - Tela nova e simples
- `build/web/` - Pasta que o Vercel usa (precisa ser atualizada)
