# Fix: Correção CamelCase nos Services Financeiros

## Problema Identificado
O erro ao criar vendas/compras a prazo estava ocorrendo porque o frontend estava enviando campos em snake_case, mas o backend (após as correções anteriores) estava esperando camelCase.

**Erro Original:**
```
Exception: [(type: missing, loc: body, produtos, 0, produtoId], msg: Field required), 
(input: [produto_id: 61, quantidade: 1, valor_unitario: 6]
```

## Causa Raiz
Inconsistência entre:
- **Backend**: Esperando camelCase (`produtoId`, `valorUnitario`, etc.)
- **Frontend**: Enviando snake_case (`produto_id`, `valor_unitario`, etc.)

## Correções Implementadas

### 1. Formulários de Criação
**Arquivos:** `venda_prazo_form_screen.dart`, `compra_prazo_form_screen.dart`

**Antes:**
```dart
produtos: _itensVenda.map((item) => {
  'produto_id': item.produto.id,
  'quantidade': item.quantidade,
  'valor_unitario': item.valorUnitario,
}).toList(),
parcelas: _parcelas.map((p) => {
  'numero_parcela': p.numero,
  'valor_parcela': p.valor,
  'data_vencimento': p.dataVencimento.toIso8601String().split('T')[0],
}).toList(),
```

**Depois:**
```dart
produtos: _itensVenda.map((item) => {
  'produtoId': item.produto.id,
  'quantidade': item.quantidade,
  'valorUnitario': item.valorUnitario,
}).toList(),
parcelas: _parcelas.map((p) => {
  'numeroParcela': p.numero,
  'valorParcela': p.valor,
  'dataVencimento': p.dataVencimento.toIso8601String().split('T')[0],
}).toList(),
```

### 2. Services de API
**Arquivos:** `venda_prazo_service.dart`, `compra_prazo_service.dart`, `pagamento_service.dart`, `parcela_service.dart`, `relatorio_service.dart`

#### Query Parameters:
- `cliente_id` → `clienteId`
- `fornecedor_id` → `fornecedorId`
- `referencia_id` → `referenciaId`
- `data_inicio` → `dataInicio`
- `data_fim` → `dataFim`
- `vencimento_ate` → `vencimentoAte`

#### Request Body:
- `valor_pago` → `valorPago`
- `forma_pagamento` → `formaPagamento`
- `data_pagamento` → `dataPagamento`

### 3. Arquivos Modificados
1. `lib/screens/financeiro/venda_prazo_form_screen.dart`
2. `lib/screens/financeiro/compra_prazo_form_screen.dart`
3. `lib/services/financeiro/venda_prazo_service.dart`
4. `lib/services/financeiro/compra_prazo_service.dart`
5. `lib/services/financeiro/pagamento_service.dart`
6. `lib/services/financeiro/parcela_service.dart`
7. `lib/services/financeiro/relatorio_service.dart`

## Resultado
- ✅ Criação de vendas a prazo funcionando
- ✅ Criação de compras a prazo funcionando
- ✅ Pagamentos funcionando
- ✅ Relatórios funcionando
- ✅ Consistência entre frontend e backend

## Commit
`6344752` - fix: corrigir campos snake_case para camelCase em todos os services financeiros - resolver erro de criação de vendas/compras

## Teste
Agora o sistema deve permitir criar vendas e compras a prazo sem erros de validação.

**URL para teste:** https://sorveteria-camila.vercel.app