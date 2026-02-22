# ⚡ Deploy Rápido no Vercel (5 minutos)

## 📋 Passo a Passo

### 1️⃣ Criar Conta no Vercel

1. Acesse: https://vercel.com/signup
2. Clique em **"Continue with GitHub"**
3. Autorize o Vercel

### 2️⃣ Fazer Deploy

**Opção A - Arrastar e Soltar (Mais Fácil):**

1. Acesse: https://vercel.com/new
2. Clique em **"Browse"** ou arraste a pasta `build/web` para a página
3. Aguarde o upload (1-2 minutos)
4. Clique em **"Deploy"**
5. Pronto! Você terá uma URL tipo: `https://sorveteria-camila-xxx.vercel.app`

**Opção B - Via GitHub:**

1. Crie um repositório no GitHub com a pasta `build/web`
2. No Vercel, clique em **"Import Project"**
3. Selecione o repositório
4. Clique em **"Deploy"**

### 3️⃣ Configurar Domínio Personalizado (Opcional)

1. No Vercel, vá em **Settings** → **Domains**
2. Adicione: `sorveteria-camila.vercel.app` (ou compre um domínio)

---

## 📱 Testar no Celular

Depois do deploy:

**iPhone:**
1. Abra Safari
2. Acesse a URL do Vercel
3. Compartilhar → Adicionar à Tela de Início

**Android:**
1. Abra Chrome
2. Acesse a URL do Vercel
3. Menu → Adicionar à tela inicial

---

## ✅ Pronto!

Seu app está no ar e funcionando em iPhone e Android! 🎉

**Arquivos para fazer upload:**
- Pasta completa: `build/web/`
- Contém: index.html, manifest.json, ícones, etc.

---

## 🔄 Atualizar o App

1. Faça alterações no código
2. Execute: `C:\flutter\bin\flutter.bat build web --release`
3. Faça upload da nova pasta `build/web` no Vercel
4. Pronto! Atualização automática para todos os usuários!
