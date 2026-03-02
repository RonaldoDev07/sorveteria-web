import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/financeiro/venda_prazo_service.dart';
import '../../services/financeiro/compra_prazo_service.dart';
import '../../services/api_service.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import 'venda_detalhes_screen.dart';
import 'compra_detalhes_screen.dart';

class HistoricoCompletoScreen extends StatefulWidget {
  const HistoricoCompletoScreen({super.key});

  @override
  State<HistoricoCompletoScreen> createState() => _HistoricoCompletoScreenState();
}

class _HistoricoCompletoScreenState extends State<HistoricoCompletoScreen> {
  List<_ItemHistorico> _historico = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filtroTipo = 'todos'; // todos, vendas, compras

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _formatoData = DateFormat('dd/MM/yyyy');
  final _formatoHora = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void didUpdateWidget(HistoricoCompletoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar quando o widget for atualizado
    _carregarHistorico();
  }

  // Recarregar sempre que a tela voltar ao foco
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar dados quando voltar para esta tela
    if (mounted) {
      _carregarHistorico();
    }
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final vendaService = VendaPrazoService(auth);
      final compraService = CompraPrazoService(auth);

      // Carregar vendas a prazo
      final vendas = await vendaService.listarVendas();
      
      // Carregar compras a prazo
      final compras = await compraService.listarCompras();

      // Carregar movimentações de estoque (vendas à vista)
      final movimentacoes = await ApiService.getMovimentacoes(auth.token!);

      // Combinar tudo em uma lista única
      final List<_ItemHistorico> itens = [];

      // Adicionar vendas a prazo
      for (var venda in vendas) {
        itens.add(_ItemHistorico(
          tipo: 'Venda a Prazo',
          descricao: venda.cliente?.nome ?? 'Cliente',
          valor: venda.valorTotal,
          data: venda.dataVenda,
          status: venda.status,
          cor: Colors.green,
          icone: Icons.credit_card,
          vendaPrazo: venda,
        ));
      }

      // Adicionar compras a prazo
      for (var compra in compras) {
        itens.add(_ItemHistorico(
          tipo: 'Compra a Prazo',
          descricao: compra.fornecedor?.nome ?? 'Fornecedor',
          valor: compra.valorTotal,
          data: compra.dataCompra,
          status: compra.status,
          cor: Colors.purple,
          icone: Icons.shopping_bag,
          compraPrazo: compra,
        ));
      }

      // Adicionar movimentações de estoque (vendas à vista)
      for (var mov in movimentacoes) {
        try {
          DateTime data;
          if (mov['data_movimentacao'] is String) {
            data = DateTime.parse(mov['data_movimentacao']);
          } else {
            data = DateTime.now();
          }
          
          // Calcular valor com segurança
          double calcularValor(dynamic quantidade, dynamic preco) {
            final qtd = quantidade is num ? quantidade.toDouble() : (double.tryParse(quantidade?.toString() ?? '0') ?? 0.0);
            final prc = preco is num ? preco.toDouble() : (double.tryParse(preco?.toString() ?? '0') ?? 0.0);
            return qtd * prc;
          }
          
          if (mov['tipo'] == 'SAIDA') {
            itens.add(_ItemHistorico(
              tipo: 'Venda à Vista',
              descricao: mov['produto_nome'] ?? 'Produto',
              valor: calcularValor(mov['quantidade'], mov['preco_venda']),
              data: data,
              status: 'quitada',
              cor: Colors.teal,
              icone: Icons.shopping_cart,
            ));
          } else if (mov['tipo'] == 'ENTRADA') {
            itens.add(_ItemHistorico(
              tipo: 'Compra à Vista',
              descricao: mov['produto_nome'] ?? 'Produto',
              valor: calcularValor(mov['quantidade'], mov['custo_unitario']),
              data: data,
              status: 'quitada',
              cor: Colors.orange,
              icone: Icons.inventory,
            ));
          }
        } catch (e) {
          print('Erro ao processar movimentação: $e');
          // Ignora movimentações com erro
        }
      }

      // Ordenar por data (mais recente primeiro)
      itens.sort((a, b) => b.data.compareTo(a.data));

      setState(() {
        _historico = itens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmarCancelamento(_ItemHistorico item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta ${item.tipo}?\n\n'
          'Cliente/Fornecedor: ${item.descricao}\n'
          'Valor: ${_formatoMoeda.format(item.valor)}\n\n'
          'O estoque será revertido automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        
        if (item.vendaPrazo != null) {
          final vendaService = VendaPrazoService(auth);
          await vendaService.cancelarVenda(item.vendaPrazo!.id!);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Venda cancelada com sucesso')),
            );
          }
        } else if (item.compraPrazo != null) {
          final compraService = CompraPrazoService(auth);
          await compraService.cancelarCompra(item.compraPrazo!.id!);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compra cancelada com sucesso')),
            );
          }
        }
        
        // Recarregar histórico
        _carregarHistorico();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cancelar: $e')),
          );
        }
      }
    }
  }

  List<_ItemHistorico> get _historicoFiltrado {
    if (_filtroTipo == 'todos') return _historico;
    if (_filtroTipo == 'vendas') {
      return _historico.where((item) => 
        item.tipo.contains('Venda')).toList();
    }
    if (_filtroTipo == 'compras') {
      return _historico.where((item) => 
        item.tipo.contains('Compra')).toList();
    }
    return _historico;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Completo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filtroTipo = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todos', child: Text('Todos')),
              const PopupMenuItem(value: 'vendas', child: Text('Apenas Vendas')),
              const PopupMenuItem(value: 'compras', child: Text('Apenas Compras')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarHistorico,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _historicoFiltrado.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma movimentação encontrada'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarHistorico,
                      child: ListView.builder(
                        itemCount: _historicoFiltrado.length,
                        itemBuilder: (context, index) {
                          final item = _historicoFiltrado[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              onTap: () {
                                if (item.vendaPrazo != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VendaDetalhesScreen(venda: item.vendaPrazo!),
                                    ),
                                  ).then((_) => _carregarHistorico());
                                } else if (item.compraPrazo != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CompraDetalhesScreen(compra: item.compraPrazo!),
                                    ),
                                  ).then((_) => _carregarHistorico());
                                }
                              },
                              leading: CircleAvatar(
                                backgroundColor: item.cor,
                                child: Icon(item.icone, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                item.tipo,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.descricao),
                                  Text(
                                    '${_formatoData.format(item.data)} às ${_formatoHora.format(item.data)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatoMoeda.format(item.valor),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: item.tipo.contains('Venda') ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      if (item.status != 'quitada')
                                        Text(
                                          _getStatusLabel(item.status),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getStatusColor(item.status),
                                          ),
                                        ),
                                    ],
                                  ),
                                  // Botão de cancelar para vendas/compras a prazo
                                  if ((item.vendaPrazo != null || item.compraPrazo != null) && 
                                      item.status != 'cancelada' && item.status != 'quitada')
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _confirmarCancelamento(item),
                                      tooltip: 'Cancelar',
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'em_dia':
        return 'Em Dia';
      case 'atrasada':
        return 'Atrasada';
      case 'cancelada':
        return 'Cancelada';
      case 'quitada':
        return 'Quitada';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'em_dia':
        return Colors.blue;
      case 'atrasada':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
      case 'quitada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _ItemHistorico {
  final String tipo;
  final String descricao;
  final double valor;
  final DateTime data;
  final String status;
  final Color cor;
  final IconData icone;
  final VendaPrazo? vendaPrazo;
  final CompraPrazo? compraPrazo;

  _ItemHistorico({
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.status,
    required this.cor,
    required this.icone,
    this.vendaPrazo,
    this.compraPrazo,
  });
}
