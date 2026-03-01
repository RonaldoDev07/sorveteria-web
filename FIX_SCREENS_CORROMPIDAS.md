# Fix: Screens Corrompidas - UTF-8 Encoding

## Problema Identificado
Os arquivos `vendas_prazo_screen.dart` e `compras_prazo_screen.dart` estavam corrompidos no repositório Git com:
- Encoding UTF-16 ao invés de UTF-8
- Código duplicado/triplicado
- Erros de sintaxe como `);$');`
- Arquivos com 633-1298 linhas ao invés das ~430 linhas esperadas

## Causa Raiz
A corrupção estava no próprio repositório Git, não apenas no working directory. Tentativas de restaurar via `git checkout`, `git reset --hard` e `git show` falharam com erros de UTF-8.

## Solução Implementada

### 1. Recriação dos Arquivos
- Deletados os arquivos corrompidos
- Recriados usando `fsWrite` tool (não PowerShell) com encoding UTF-8 limpo
- Baseados no padrão de `compra_detalhes_screen.dart` (arquivo funcionando corretamente)

### 2. Correções Adicionais
- Corrigido `parcela_detalhes_screen.dart`:
  - Método `obterVenda` → `buscarVenda` (VendaPrazoService)
  - Método `obterCompra` removido (não existe em CompraPrazoService)
  - Método `darBaixaParcela` corrigido para usar parâmetros posicionais ao invés de named parameters
- Corrigidos warnings de null-aware operators desnecessários:
  - `v.cliente?.nome?.toLowerCase()` → `(v.cliente?.nome ?? '').toLowerCase()`

### 3. Build e Deploy
- `flutter clean` executado com sucesso
- `flutter build web --release` compilado sem erros
- Build commitado e pushed para GitHub
- Vercel deployment triggerado automaticamente

## Commits Realizados
1. `c1812e4` - fix: recriar screens corrompidas vendas_prazo e compras_prazo com UTF-8 limpo
2. `e87aba7` - fix: corrigir warnings de null-aware operators desnecessários

## Arquivos Afetados
- `lib/screens/financeiro/vendas_prazo_screen.dart` - RECRIADO
- `lib/screens/financeiro/compras_prazo_screen.dart` - RECRIADO
- `lib/screens/financeiro/parcela_detalhes_screen.dart` - CORRIGIDO
- `build/web/*` - REBUILD COMPLETO

## Verificação
- ✅ Encoding UTF-8 confirmado
- ✅ Sem erros de compilação
- ✅ Sem warnings (exceto deprecations do Flutter)
- ✅ Build web gerado com sucesso
- ✅ Deploy para Vercel triggerado

## Próximos Passos
1. Aguardar deploy do Vercel completar
2. Testar em produção: https://sorveteria-camila.vercel.app
3. Verificar se as telas de Vendas a Prazo e Compras a Prazo estão funcionando corretamente
4. Testar integração com backend: https://sorveteria-camila-api.onrender.com

## Notas Técnicas
- PowerShell here-strings (@'...'@) causam buffer overflow para arquivos grandes (471+ linhas)
- `fsWrite` tool é mais confiável para criar arquivos grandes com encoding correto
- Git pode corromper arquivos se encoding não for consistente
- Sempre usar UTF-8 sem BOM para arquivos Dart
