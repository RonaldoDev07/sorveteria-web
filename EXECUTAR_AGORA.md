# ⚠️ EXECUTE ESTES COMANDOS AGORA

## A API está funcionando! 🎉
URL: https://sorveteria-camila-api-v3.onrender.com

## Agora você precisa atualizar o frontend

### PASSO 1: Abrir Terminal
1. Abra o Windows Explorer
2. Navegue até a pasta: `sorveteria-web-deploy`
3. Clique com botão direito na pasta
4. Escolha "Abrir no Terminal" ou "Git Bash Here"

### PASSO 2: Executar Comandos

Cole estes comandos um por um:

```bash
# Build do Flutter
C:\flutter\bin\flutter.bat build web --release
```

Aguarde o build terminar (1-2 minutos)

```bash
# Adicionar ao Git
git add -A
```

```bash
# Commit
git commit -m "Update API URL to v3 and rebuild"
```

```bash
# Push
git push origin main
```

### PASSO 3: Aguardar Deploy
- O Vercel vai redesenhar automaticamente
- Aguarde 1-2 minutos
- Acesse: https://sorveteria-web-one.vercel.app

### PASSO 4: Testar no iPhone
1. Abra o Safari no iPhone
2. Vá em Configurações > Safari > Avançado > Dados de Sites
3. Remova os dados do "vercel.app"
4. Feche completamente o Safari
5. Abra novamente e acesse o app
6. Faça login: admin / admin123

## ✅ Deve Funcionar!

Se tudo der certo:
- ✅ App carrega sem erro
- ✅ Produtos aparecem
- ✅ Funciona no iPhone, Android e PC

## Se Der Erro

Me avise qual erro apareceu e em qual passo!

---

**Alternativamente**, você pode simplesmente clicar duas vezes no arquivo:
`build_e_deploy.bat`

Ele vai fazer tudo automaticamente!
