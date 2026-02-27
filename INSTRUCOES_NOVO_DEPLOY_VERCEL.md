# INSTRUÇÕES: Criar Novo Projeto no Vercel (Solução Definitiva)

## PROBLEMA
O Vercel está com cache muito persistente e não está usando os arquivos novos com a URL correta do servidor Oregon.

## SOLUÇÃO
Criar um NOVO projeto no Vercel com nome diferente. Isso força um deploy completamente limpo.

---

## PASSO A PASSO

### 1. Acesse o Vercel
- Vá em: https://vercel.com/dashboard
- Faça login se necessário

### 2. Crie Novo Projeto
- Clique em "Add New..." → "Project"
- Selecione o repositório: `sorveteria-web`
- Clique em "Import"

### 3. Configure o Projeto
**Framework Preset**: Other (ou deixe em branco)

**Build & Development Settings**:
- Build Command: `echo 'Using pre-built files'`
- Output Directory: `build/web`
- Install Command: `echo 'No install needed'`

**Root Directory**: `.` (deixe em branco ou ponto)

### 4. Variáveis de Ambiente
Não precisa adicionar nenhuma variável de ambiente.

### 5. Deploy
- Clique em "Deploy"
- Aguarde 1-2 minutos
- Anote a nova URL (será algo como: `sorveteria-web-xxx.vercel.app`)

### 6. Teste
- Acesse a nova URL
- Faça login (vai demorar 2-5 min - Render Free Tier)
- Abra o Console (F12)
- Vá em: Vendas a Prazo → Nova Venda → Adicionar Produto
- Observe os logs no console

### 7. (OPCIONAL) Deletar Projeto Antigo
Depois de confirmar que o novo projeto funciona:
- Vá em Settings do projeto antigo (`sorveteria-web-one`)
- Role até o final
- Clique em "Delete Project"

---

## O QUE ESPERAR

✅ **Logs no Console**:
```
🔍 Carregando produtos para venda...
✅ 22 produtos carregados da API
📦 22 produtos disponíveis no dropdown
📋 Produtos carregados:
   - Produto 1 (ID: xxx, Estoque: xx)
   - Produto 2 (ID: xxx, Estoque: xx)
   ...
```

✅ **No Dialog**:
- Caixa VERDE: "✅ 22 produtos disponíveis"
- Dropdown com lista de produtos

---

## SE AINDA NÃO FUNCIONAR

Se mesmo com o projeto novo o dropdown continuar vazio:
1. Verifique os logs no console
2. Tire print do console E do dialog
3. Me envie para investigar o problema real

---

## INFORMAÇÕES TÉCNICAS

- **Servidor Backend**: https://sorveteria-camila-api.onrender.com (Oregon)
- **Versão Backend**: 3.1.6
- **Último Build Frontend**: Commit `acc2d2e` (com URL correta)
- **Problema**: Cache persistente do Vercel no projeto antigo
