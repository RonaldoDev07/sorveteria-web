import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../services/financeiro/relatorio_service.dart';
import '../../services/auth_service.dart';

class ContasReceberScreen extends StatefulWidget {
  const ContasReceberScreen({super.key});

  @override
  State<ContasReceberScreen> createState() => _ContasReceberScreenState();
}

class _ContasReceberScreenState extends State<ContasReceberScreen> {
  List<VendaPrazo> _vendas = [];
  bool _isLoading = true;
  String? _errorMessage;
  RelatorioService? _relatorioService;
  
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
      final resultado = await _relatorioService!.contasReceber(status: _filtroStatus);
      
      if (!mounted) return;
      
      setState(() {
        _vendas = resultado['vendas'] as List<VendaPrazo>;
        _totalAReceber = resultado['total_a_receber'];
        _totalRecebido = resultado['total_recebido'];
        _totalEmAberto = resultado['total_em_aberto'];
        _contasAtrasadas = resultado['contas_atrasadas'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
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
                    // Resumo
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
                    // Lista
                    Expanded(
                      child: _vendas.isEmpty
                          ? const Center(
                              child: Text('Nenhuma conta a receber'),
                            )
                          : RefreshIndicator(
                              onRefresh: _carregarContas,
                              child: ListView.builder(
                                itemCount: _vendas.length,
                                itemBuilder: (context, index) {
                                  final venda = _vendas[index];
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
                                        // TODO: Abrir detalhes da venda
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Detalhes da venda em desenvolvimento'),
                                          ),
                                        );
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
