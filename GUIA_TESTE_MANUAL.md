# 🧪 Guia de Teste Manual - Sorveteria Camila

## Pré-requisitos

1. ✅ Backend rodando: `cd estoque_api && .\iniciar_api.bat`
2. ✅ Frontend rodando: `cd estoque_mobile && flutter run -d chrome`
3. ✅ Usuário admin criado (login: admin, senha: admin123)

---

## 📋 Roteiro de Testes

### 1️⃣ TELA DE LOGIN

**Objetivo**: Validar autenticação

**Passos**:
1. Abrir o app no navegador
2. Verificar visual da tela:
   - [ ] Logo circular com sorvete
   - [ ] Nome "Sorveteria" (leve) e "Camila" (bold)
   - [ ] Gradiente rosa no fundo
   - [ ] Campos de login e senha
   - [ ] Botão "Entrar" rosa

3. Testar validações:
   - [ ] Clicar "Entrar" sem preencher → Deve mostrar "Campo obrigatório"
   - [ ] Digitar login errado → Deve mostrar "Login ou senha inválidos"

4. Login correto:
   - [ ] Login: `admin`
   - [ ] Senha: `admin123`
   - [ ] Clicar "Entrar"
   - [ ] Deve redirecionar para Home

**Resultado Esperado**: ✅ Login bem-sucedido e redirecionamento

---

### 2️⃣ TELA HOME

**Objetivo**: Validar menu principal

**Passos**:
1. Verificar AppBar:
   - [ ] Logo de sorvete no canto esquerdo
   - [ ] Nome "Sorveteria Camila"
   - [ ] Botão de logout no canto direito

2. Verificar saudação:
   - [ ] Avatar com letra "A" (inicial de admin)
   - [ ] Texto "Olá, admin!"
   - [ ] Texto "Administrador"

3. Verificar cards do menu:
   - [ ] Produtos (azul)
   - [ ] Cadastrar Produto (roxo/indigo)
   - [ ] Registrar Compra (verde-água/teal)
   - [ ] Registrar Venda (verde)
   - [ ] Relatório de Lucro (roxo)

4. Testar navegação:
   - [ ] Clicar em cada card
   - [ ] Verificar se abre a tela correta
   - [ ] Voltar para Home

**Resultado Esperado**: ✅ Todos os cards funcionando

---

### 3️⃣ CADASTRAR PRODUTO

**Objetivo**: Criar novo produto

**Passos**:
1. Na Home, clicar em "Cadastrar Produto"
2. Verificar tela:
   - [ ] AppBar roxo/indigo
   - [ ] Fundo com gradiente
   - [ ] Campos: Nome, Unidade, Custo de Compra, Preço de Venda, Estoque Inicial

3. Preencher formulário:
   - [ ] Nome: `Sorvete de Chocolate`
   - [ ] Unidade: `UN`
   - [ ] Custo de Compra: `6.50`
   - [ ] Preço de Venda: `15.00`
   - [ ] Estoque Inicial: `30`

4. Clicar "Cadastrar Produto"
5. Verificar:
   - [ ] Mensagem "Produto cadastrado com sucesso"
   - [ ] Volta para Home

**Resultado Esperado**: ✅ Produto criado

---

### 4️⃣ LISTAR PRODUTOS

**Objetivo**: Visualizar produtos cadastrados

**Passos**:
1. Na Home, clicar em "Produtos"
2. Verificar tela:
   - [ ] AppBar azul
   - [ ] Campo de busca no topo
   - [ ] Botão de refresh
   - [ ] Lista de produtos

3. Verificar card do produto:
   - [ ] Ícone de inventário
   - [ ] Nome do produto
   - [ ] Estoque atual
   - [ ] Preço formatado (R$ 15,00)
   - [ ] Menu de 3 pontos

4. Testar busca:
   - [ ] Digitar "chocolate" no campo de busca
   - [ ] Deve filtrar e mostrar apenas produtos com "chocolate"
   - [ ] Limpar busca (X)

5. Testar refresh:
   - [ ] Clicar no botão de refresh
   - [ ] Lista deve recarregar

**Resultado Esperado**: ✅ Lista funcionando corretamente

---

### 5️⃣ REGISTRAR COMPRA (ENTRADA)

**Objetivo**: Adicionar estoque

**Passos**:
1. Na Home, clicar em "Registrar Compra"
2. Selecionar "Sorvete de Chocolate"
3. Verificar tela:
   - [ ] AppBar verde-água/teal
   - [ ] Nome do produto
   - [ ] Estoque atual: 30 UN
   - [ ] Campo quantidade
   - [ ] Campo custo de compra

4. Preencher:
   - [ ] Quantidade: `20`
   - [ ] Custo de Compra: `6.00`

5. Clicar "Registrar Compra"
6. Verificar:
   - [ ] Mensagem "Entrada registrada com sucesso"
   - [ ] Volta para lista de produtos
   - [ ] Lista atualiza automaticamente
   - [ ] Novo estoque: 50 UN

**Resultado Esperado**: ✅ Estoque aumentou de 30 para 50

---

### 6️⃣ REGISTRAR VENDA (SAÍDA)

**Objetivo**: Vender produto

**Passos**:
1. Na Home, clicar em "Registrar Venda"
2. Selecionar "Sorvete de Chocolate"
3. Verificar tela:
   - [ ] AppBar verde
   - [ ] Nome do produto
   - [ ] Estoque atual: 50 UN
   - [ ] Campo quantidade

4. Preencher:
   - [ ] Quantidade: `10`

5. Clicar "Registrar Venda"
6. Verificar:
   - [ ] Mensagem "Baixa registrada com sucesso"
   - [ ] Volta para lista de produtos
   - [ ] Lista atualiza automaticamente
   - [ ] Novo estoque: 40 UN

**Resultado Esperado**: ✅ Estoque diminuiu de 50 para 40

---

### 7️⃣ RELATÓRIO DE LUCRO

**Objetivo**: Visualizar dados financeiros

**Passos**:
1. Na Home, clicar em "Relatório de Lucro"
2. Verificar tela:
   - [ ] AppBar roxo
   - [ ] Card de seleção de período
   - [ ] Botão "Gerar Relatório"

3. Clicar "Gerar Relatório" (sem filtro de data)
4. Verificar cards de período:
   - [ ] Card verde: Últimos 7 dias (receita + lucro)
   - [ ] Card azul: Últimos 30 dias (receita + lucro)
   - [ ] Card laranja: Últimos 365 dias (receita + lucro)

5. Verificar resumo financeiro:
   - [ ] Total Vendido (formatado R$)
   - [ ] Custo Total (formatado R$)
   - [ ] Lucro Bruto (formatado R$)
   - [ ] Margem % (com vírgula)
   - [ ] Total Investido
   - [ ] Quantidade de Vendas

6. Verificar lucro por produto:
   - [ ] Lista de produtos vendidos
   - [ ] Receita, Lucro, Margem, Quantidade
   - [ ] Valores formatados em R$

7. Testar filtro de período:
   - [ ] Selecionar data início
   - [ ] Selecionar data fim
   - [ ] Clicar "Gerar Relatório"
   - [ ] Verificar se filtra corretamente

**Resultado Esperado**: ✅ Relatório completo e formatado

---

### 8️⃣ MENU POPUP (PRODUTOS)

**Objetivo**: Testar ações rápidas

**Passos**:
1. Na tela "Produtos", clicar nos 3 pontos de um produto
2. Verificar menu:
   - [ ] "Registrar Venda" (verde)
   - [ ] "Registrar Compra" (teal) - apenas ADMIN

3. Clicar "Registrar Venda"
4. Verificar:
   - [ ] Abre tela de venda com produto pré-selecionado
   - [ ] Registrar venda
   - [ ] Volta e atualiza lista

**Resultado Esperado**: ✅ Menu funcionando

---

### 9️⃣ FORMATAÇÃO BRASILEIRA

**Objetivo**: Validar formatação de valores

**Verificar em todas as telas**:
- [ ] Valores pequenos: R$ 5,00 (com vírgula)
- [ ] Valores grandes: R$ 5.000,00 (ponto para milhar, vírgula para decimal)
- [ ] Percentuais: 28,57% (vírgula)
- [ ] Datas: DD/MM/YYYY

**Resultado Esperado**: ✅ Tudo formatado corretamente

---

### 🔟 ATUALIZAÇÃO AUTOMÁTICA

**Objetivo**: Validar refresh automático

**Passos**:
1. Abrir "Produtos"
2. Anotar estoque de um produto
3. Registrar uma venda desse produto
4. Verificar:
   - [ ] Ao voltar, lista atualiza automaticamente
   - [ ] Estoque está correto

5. Repetir com compra
6. Repetir com cadastro de novo produto

**Resultado Esperado**: ✅ Listas sempre atualizadas

---

## 🎯 CHECKLIST FINAL

### Visual
- [ ] Logo elegante e profissional
- [ ] Cores consistentes (rosa)
- [ ] Gradientes suaves
- [ ] Sombras e elevações
- [ ] Ícones apropriados
- [ ] Tipografia elegante

### Funcionalidade
- [ ] Login/Logout
- [ ] Cadastro de produtos
- [ ] Listagem de produtos
- [ ] Busca de produtos
- [ ] Registro de compras
- [ ] Registro de vendas
- [ ] Relatórios financeiros
- [ ] Cálculos automáticos

### UX
- [ ] Feedback visual (SnackBar)
- [ ] Loading states
- [ ] Validações de formulário
- [ ] Atualização automática
- [ ] Navegação intuitiva
- [ ] Mensagens claras

### Performance
- [ ] Carregamento rápido
- [ ] Sem travamentos
- [ ] Transições suaves

---

## ✅ RESULTADO

Se todos os itens acima estiverem funcionando:

**🎉 SISTEMA 100% FUNCIONAL E PRONTO PARA USO! 🎉**

---

## 🐛 Problemas Encontrados

Anote aqui qualquer problema:

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________
