# 🚀 Como Fazer Deploy do Módulo Financeiro

## Opção 1: Scripts Automáticos (Recomendado)

### Passo 1: Build
```bash
cd sorveteria-web-deploy
BUILD_FINANCEIRO.bat
```

### Passo 2: Push
```bash
PUSH_FINANCEIRO.bat
```

---

## Opção 2: Manual (se Flutter já estiver no PATH)

```bash
cd sorveteria-web-deploy
flutter clean
flutter pub get
flutter build web --release
git add .
git commit -m "feat: adicionar módulo de clientes ao financeiro"
git push origin main
```

---

## Opção 3: Usar Flutter com caminho completo

```bash
cd sorveteria-web-deploy
C:\flutter\bin\flutter.bat clean
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat build web --release
git add .
git commit -m "feat: adicionar módulo de clientes ao financeiro"
git push origin main
```

---

## ⚠️ Se Flutter não estiver instalado

### Instalação Rápida:

1. **Baixar Flutter:**
   - https://docs.flutter.dev/get-started/install/windows
   - Ou direto: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip

2. **Extrair:**
   - Extrair o ZIP em `C:\flutter`

3. **Adicionar ao PATH:**
   - Windows + R → `sysdm.cpl`
   - Aba "Avançado" → "Variáveis de Ambiente"
   - Em "Path" → "Novo" → `C:\flutter\bin`
   - OK em tudo

4. **Verificar:**
   ```bash
   flutter --version
   ```

---

## 📋 Checklist

- [ ] Flutter instalado
- [ ] Flutter no PATH (ou usar caminho completo)
- [ ] Dentro da pasta `sorveteria-web-deploy`
- [ ] Build executado com sucesso
- [ ] Commit e push realizados
- [ ] Aguardar 3-5 minutos
- [ ] Testar em: https://sorveteria-web-one.vercel.app

---

## 🐛 Problemas Comuns

### "flutter não é reconhecido"
**Solução:** Use o caminho completo ou adicione ao PATH

### "not a git repository"
**Solução:** Certifique-se de estar dentro da pasta `sorveteria-web-deploy`

### Build demora muito
**Solução:** É normal na primeira vez (5-10 minutos)

### Erro de permissão
**Solução:** Execute o terminal como Administrador

---

## ✅ Após Deploy

1. Aguarde 3-5 minutos
2. Acesse: https://sorveteria-web-one.vercel.app
3. Faça login
4. Clique no card "Financeiro" 💳
5. Teste o módulo de Clientes

---

## 📞 Precisa de Ajuda?

Se tiver problemas, me avise qual erro apareceu!
