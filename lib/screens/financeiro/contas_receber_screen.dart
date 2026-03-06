import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../services/financeiro/relatorio_service.dart';
import '../../services/auth_service.dart';
import 'venda_detalhes_screen.dart';

class ContasReceberScreen extends StatefulWidget {
  const ContasReceberScreen({super.key});

  @override
  State<ContasReceberScreen> createState() => _ContasReceberScreenState();
}

class _ContasReceberScreenState extends State<ContasReceberScreen> {
  List<VendaPrazo> _vendas = [];
  List<VendaPrazo> _vendasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  RelatorioService? _relatorioService;
  final _searchController = TextEditingController();
  
  double _totalAReceber = 0;
  double _totalRecebido = 0;
  double _totalEmAberto = 0;
  int _contasAtrasadas = 0;
  
  String? _filtroStatus;

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_relatorioService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _relatorioService = RelatorioService(authService);
      _carregarContas();
    }
  }

  Future<void> _carregarContas() async {
    if (!mounted || _relatorioService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Carregando contas a receber...');
      final resultado = await _relatorioService!.contasReceber(status: _filtroStatus);
      
      if (!mounted) return;
      
      print('✅ Dados recebidos: ${resultado.keys}');
      print('📊 Total vendas: ${(resultado['vendas'] as List).length}');
      
      setState(() {
        _vendas = resultado['vendas'] as List<VendaPrazo>;
        _vendasFiltradas = _vendas;
        _totalAReceber = resultado['total_a_receber'] ?? 0.0;
        _totalRecebido = resultado['total_recebido'] ?? 0.0;
        _totalEmAberto = resultado['total_em_aberto'] ?? 0.0;
        _contasAtrasadas = resultado['contas_atrasadas'] ?? 0;
        _isLoading = false;
      });
      
      print('✅ Contas a receber carregadas: ${_vendas.length} vendas');
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar contas a receber: $e');
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

  void _filtrarVendas(String query) {
    setState(() {
      if (query.isEmpty) {
        _vendasFiltradas = _vendas;
      } else {
        _vendasFiltradas = _vendas.where((venda) {
          final nomeCliente = venda.cliente?.nome?.toLowerCase() ?? '';
          return nomeCliente.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas a Receber'),
        backgroundColor: Colors.teal,
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
                          hintText: 'Pesquisar por cliente...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filtrarVendas('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: _filtrarVendas,
                      ),
                    ),
                    // Cards de resumo
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.teal.shade50,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _CardResumo(
                                label: 'A Receber',
                                valor: _formatoMoeda.format(_totalAReceber),
                                cor: Colors.blue,
                              ),
                              _CardResumo(
                                label: 'Recebido',
                                valor: _formatoMoeda.format(_totalRecebido),
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
                      child: _vendasFiltradas.isEmpty
                          ? const Center(
                              child: Text('Nenhuma conta a receber'),
                            )
                          : RefreshIndicator(
                              onRefresh: _carregarContas,
                              child: ListView.builder(
                                itemCount: _vendasFiltradas.length,
                                itemBuilder: (context, index) {
                                  final venda = _vendasFiltradas[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getStatusColor(venda.status),
                                        child: const Icon(Icons.attach_money, color: Colors.white),
                                      ),
                                      title: Text(
                                        venda.cliente?.nome ?? 'Cliente',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Data: ${_formatoData.format(venda.dataVenda)}'),
                                          Text('Total: ${_formatoMoeda.format(venda.valorTotal)}'),
                                          Text('Saldo: ${_formatoMoeda.format(venda.saldoDevedor)}'),
                                          Text(
                                            _getStatusLabel(venda.status),
                                            style: TextStyle(
                                              color: _getStatusColor(venda.status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: !venda.estaQuitada && !venda.estaCancelada
                                          ? const Icon(Icons.arrow_forward_ios)
                                          : null,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VendaDetalhesScreen(venda: venda),
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
