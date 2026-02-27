import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/financeiro/venda_prazo_service.dart';
import '../../services/financeiro/compra_prazo_service.dart';
import '../../services/api_service.dart';

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
          
          if (mov['tipo'] == 'SAIDA') {
            itens.add(_ItemHistorico(
              tipo: 'Venda à Vista',
              descricao: mov['produto_nome'] ?? 'Produto',
              valor: ((mov['quantidade'] ?? 0) * (mov['preco_venda'] ?? 0)).toDouble(),
              data: data,
              status: 'quitada',
              cor: Colors.teal,
              icone: Icons.shopping_cart,
            ));
          } else if (mov['tipo'] == 'ENTRADA') {
            itens.add(_ItemHistorico(
              tipo: 'Compra à Vista',
              descricao: mov['produto_nome'] ?? 'Produto',
              valor: ((mov['quantidade'] ?? 0) * (mov['custo_unitario'] ?? 0)).toDouble(),
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
                              trailing: Column(
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

  _ItemHistorico({
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.status,
    required this.cor,
    required this.icone,
  });
}
