# 🚀 Deploy Rápido - Passo a Passo

## ✅ Suas Alterações Estão Prontas!

Todas as melhorias foram implementadas:
- ✅ Perfil VENDEDOR funcionando
- ✅ Formatação brasileira (R$)
- ✅ Diálogos profissionais
- ✅ Exportação CSV
- ✅ Campos organizados

---

## 📦 Passo 1: Fazer Build

Abra o **Prompt de Comando** ou **PowerShell** na pasta `estoque_mobile` e execute:

```bash
flutter build web --release
```

**Aguarde:** 2-5 minutos (vai compilar tudo)

**Resultado:** Pasta `build/web` será criada com todos os arquivos

---

## 🌐 Passo 2: Deploy no Render

### **Opção A: Via GitHub (Recomendado)**

1. **Commit das alterações:**
```bash
git add .
git commit -m "Melhorias: VENDEDOR, formatação BR, CSV export"
git push
```

2. **No Render Dashboard:**
   - Acesse: https://dashboard.render.com
   - Encontre seu serviço web (frontend)
   - Clique em **"Manual Deploy"** → **"Deploy latest commit"**
   - Aguarde 2-3 minutos

3. **Pronto!** Acesse: https://sorveteria-web.onrender.com

---

### **Opção B: Upload Manual (Mais Rápido)**

Se o Render não detectar as mudanças automaticamente:

1. **Fazer build local:**
```bash
flutter build web --release
```

2. **Acessar Vercel/Netlify:**
   - Vercel: https://vercel.com
   - Netlify: https://netlify.com

3. **Fazer upload:**
   - Arrastar pasta `build/web` para o site
   - Aguardar upload (1-2 minutos)
   - Copiar URL gerada

4. **Atualizar DNS (se tiver domínio próprio)**

---

## 🔧 Passo 3: Verificar Backend

O backend já está atualizado no Render? Vamos garantir:

### **Verificar se está rodando:**

Abra no navegador:
```
https://sorveteria-camila-api.onrender.com/
```

**Deve mostrar:**
```json
{
  "message": "Estoque API - Sistema de Gerenciamento...",
  "version": "2.0.0"
}
```

### **Se não estiver atualizado:**

1. **Commit do backend:**
```bash
cd estoque_api
git add .
git commit -m "Adiciona exportação CSV e melhorias"
git push
```

2. **No Render Dashboard:**
   - Encontre o serviço da API
   - Clique em **"Manual Deploy"**
   - Aguarde 2-3 minutos

---

## 🎯 Passo 4: Testar Tudo

### **Checklist de Testes:**

1. **Login:**
   - [ ] Fazer login com usuário ADMIN
   - [ ] Fazer login com usuário VENDEDOR

2. **Perfil VENDEDOR:**
   - [ ] Aparece opção "Cadastrar Produto"
   - [ ] Aparece opção "Registrar Compra"
   - [ ] Consegue cadastrar produto
   - [ ] Consegue registrar compra

3. **Formatação:**
   - [ ] Preços aparecem como "R$ 6,00" (não "$ R$ 6,00")
   - [ ] Campos de valor têm "R$" antes
   - [ ] Exemplos aparecem como hint

4. **Exportação CSV:**
   - [ ] Botão "Exportar CSV" aparece
   - [ ] Clica e baixa arquivo
   - [ ] Arquivo abre no Excel
   - [ ] Dados estão corretos

5. **Diálogos:**
   - [ ] Mensagens profissionais
   - [ ] Acentuação funcionando
   - [ ] Cores corretas (verde/vermelho)

---

## 📱 Passo 5: Atualizar no Celular

### **iPhone:**
1. Abrir Safari
2. Acessar: https://sorveteria-web.onrender.com
3. Clicar em "Compartilhar" (ícone de seta)
4. "Adicionar à Tela de Início"
5. Pronto! App atualizado

### **Android:**
1. Abrir Chrome
2. Acessar: https://sorveteria-web.onrender.com
3. Menu (3 pontinhos)
4. "Adicionar à tela inicial"
5. Pronto! App atualizado

---

## 🔄 Deploy Automático (Configurar Uma Vez)

### **Para não precisar fazer manual sempre:**

1. **Conectar GitHub ao Render:**
   - Render Dashboard → Settings
   - Connect Repository
   - Autorizar GitHub
   - Selecionar repositório

2. **Configurar Auto-Deploy:**
   - Settings → Build & Deploy
   - Ativar "Auto-Deploy"
   - Branch: `main` ou `master`

3. **Pronto!** Agora todo `git push` faz deploy automático

---

## 📊 Estrutura Atual

```
Produção:
├── Backend API: https://sorveteria-camila-api.onrender.com
├── Frontend Web: https://sorveteria-web.onrender.com
└── Banco de Dados: Supabase PostgreSQL

Desenvolvimento:
├── Backend: localhost:8000
└── Frontend: localhost (flutter run)
```

---

## 🆘 Problemas Comuns

### **1. "Flutter não reconhecido"**
```bash
# Usar caminho completo
C:\flutter\bin\flutter.bat build web --release
```

### **2. "Build falhou"**
```bash
# Limpar cache e tentar novamente
flutter clean
flutter pub get
flutter build web --release
```

### **3. "Render não atualiza"**
- Fazer commit e push
- Manual Deploy no dashboard
- Aguardar 3-5 minutos
- Limpar cache do navegador (Ctrl+Shift+R)

### **4. "Mudanças não aparecem no celular"**
- Remover app da tela inicial
- Limpar cache do navegador
- Adicionar novamente

### **5. "CSV não baixa"**
- Verificar se backend foi atualizado
- Testar endpoint: `/relatorios/exportar-csv`
- Ver console do navegador (F12)

---

## 💡 Dicas

### **Deploy Rápido:**
```bash
# Backend
cd estoque_api
git add . && git commit -m "update" && git push

# Frontend
cd estoque_mobile
flutter build web --release
# Arrastar build/web para Vercel/Netlify
```

### **Testar Localmente Antes:**
```bash
# Backend
cd estoque_api
uvicorn app.main:app --reload

# Frontend
cd estoque_mobile
flutter run -d chrome
```

### **Ver Logs de Erro:**
- Render Dashboard → Logs
- Ver erros em tempo real
- Útil para debug

---

## ✅ Checklist Final

Antes de considerar concluído:

- [ ] Backend atualizado no Render
- [ ] Frontend atualizado no Render/Vercel
- [ ] Testado no navegador desktop
- [ ] Testado no celular (iPhone/Android)
- [ ] Perfil VENDEDOR funcionando
- [ ] Exportação CSV funcionando
- [ ] Formatação brasileira correta
- [ ] Diálogos profissionais
- [ ] Sem erros no console

---

## 🎉 Pronto!

Seu sistema está atualizado com todas as melhorias:
- ✅ Perfil VENDEDOR completo
- ✅ Formatação 100% brasileira
- ✅ Exportação CSV para backup
- ✅ Diálogos profissionais
- ✅ Interface organizada

**Próximos passos:**
1. Fazer build: `flutter build web --release`
2. Fazer deploy no Render/Vercel
3. Testar tudo
4. Usar o sistema! 🚀

---

## 📞 Comandos Úteis

```bash
# Ver versão do Flutter
flutter --version

# Limpar cache
flutter clean

# Atualizar dependências
flutter pub get

# Build para web
flutter build web --release

# Rodar localmente
flutter run -d chrome

# Ver dispositivos disponíveis
flutter devices

# Analisar código
flutter analyze

# Formatar código
flutter format .
```

---

**Qualquer dúvida, consulte os guias:**
- `COMO_EXECUTAR_APP.md` - Como rodar localmente
- `DEPLOY_PWA.md` - Deploy detalhado
- `EXPORTAR_CSV.md` - Sobre exportação
- `BACKUP_GUIA.md` - Sobre backups
