import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../../services/financeiro/relatorio_service.dart';
import '../../services/auth_service.dart';
import 'compra_detalhes_screen.dart';

class ContasPagarScreen extends StatefulWidget {
  const ContasPagarScreen({super.key});

  @override
  State<ContasPagarScreen> createState() => _ContasPagarScreenState();
}

class _ContasPagarScreenState extends State<ContasPagarScreen> {
  List<CompraPrazo> _compras = [];
  List<CompraPrazo> _comprasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  RelatorioService? _relatorioService;
  
  double _totalAPagar = 0;
  double _totalPago = 0;
  double _totalEmAberto = 0;
  int _contasAtrasadas = 0;
  
  String? _filtroStatus;
  final _searchController = TextEditingController();

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarCompras);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_relatorioService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _relatorioService = RelatorioService(authService);
      _carregarContas();
    }
  }

  void _filtrarCompras() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _comprasFiltradas = _compras;
      } else {
        _comprasFiltradas = _compras.where((compra) {
          final nomeFornecedor = compra.fornecedor?.nome?.toLowerCase() ?? '';
          return nomeFornecedor.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _carregarContas() async {
    if (!mounted || _relatorioService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Carregando contas a pagar...');
      final resultado = await _relatorioService!.contasPagar(status: _filtroStatus);
      
      if (!mounted) return;
      
      print('✅ Dados recebidos: ${resultado.keys}');
      print('📊 Total compras: ${(resultado['compras'] as List).length}');
      
      setState(() {
        _compras = resultado['compras'] as List<CompraPrazo>;
        _comprasFiltradas = _compras;
        _totalAPagar = resultado['total_a_pagar'] ?? 0.0;
        _totalPago = resultado['total_pago'] ?? 0.0;
        _totalEmAberto = resultado['total_em_aberto'] ?? 0.0;
        _contasAtrasadas = resultado['contas_atrasadas'] ?? 0;
        _isLoading = false;
      });
      
      print('✅ Contas a pagar carregadas: ${_compras.length} compras');
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar contas a pagar: $e');
      print('📍 Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar dados: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'quitada':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'quitada':
        return 'Quitada';
      case 'atrasada':
        return 'Atrasada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Em Dia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas a Pagar'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroStatus = value == 'todas' ? null : value;
              });
              _carregarContas();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuItem(value: 'em_dia', child: Text('Em Dia')),
              const PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              const PopupMenuItem(value: 'quitada', child: Text('Quitadas')),
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
                        onPressed: _carregarContas,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Campo de pesquisa
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar por fornecedor...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.red.shade50,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _CardResumo(
                                label: 'A Pagar',
                                valor: _formatoMoeda.format(_totalAPagar),
                                cor: Colors.blue,
                              ),
                              _CardResumo(
                                label: 'Pago',
                                valor: _formatoMoeda.format(_totalPago),
                                cor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _CardResumo(
                                label: 'Em Aberto',
                                valor: _formatoMoeda.format(_totalEmAberto),
                                cor: Colors.orange,
                              ),
                              _CardResumo(
                                label: 'Atrasadas',
                                valor: _contasAtrasadas.toString(),
                                cor: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _comprasFiltradas.isEmpty
                          ? const Center(
                              child: Text('Nenhuma conta a pagar'),
                            )
                          : RefreshIndicator(
                              onRefresh: _carregarContas,
                              child: ListView.builder(
                                itemCount: _comprasFiltradas.length,
                                itemBuilder: (context, index) {
                                  final compra = _comprasFiltradas[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getStatusColor(compra.status),
                                        child: const Icon(Icons.money_off, color: Colors.white),
                                      ),
                                      title: Text(
                                        compra.fornecedor?.nome ?? 'Fornecedor',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Data: ${_formatoData.format(compra.dataCompra)}'),
                                          Text('Total: ${_formatoMoeda.format(compra.valorTotal)}'),
                                          Text('Saldo: ${_formatoMoeda.format(compra.saldoDevedor)}'),
                                          Text(
                                            _getStatusLabel(compra.status),
                                            style: TextStyle(
                                              color: _getStatusColor(compra.status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: !compra.estaQuitada && !compra.estaCancelada
                                          ? const Icon(Icons.arrow_forward_ios)
                                          : null,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CompraDetalhesScreen(compra: compra),
                                          ),
                                        ).then((_) => _carregarContas());
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _CardResumo extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;

  const _CardResumo({
    required this.label,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }
}
