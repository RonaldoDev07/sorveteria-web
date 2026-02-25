# 🚀 Como fazer o build e deploy

## Solução Rápida (no PC com Flutter)

1. Abra o terminal nesta pasta
2. Execute:
```bash
flutter build web --release
git add build/web
git commit -m "build: atualizar aplicação"
git push origin main
```

3. Aguarde 1-2 minutos e acesse: https://sorveteria-web-one.vercel.app

Pronto! ✅

---

## Arquivos importantes
- `lib/screens/home_screen.dart` - Tela principal
- `build/web/` - Pasta que o Vercel usa (precisa ser atualizada)
