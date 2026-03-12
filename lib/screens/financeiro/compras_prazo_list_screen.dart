import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../../services/financeiro/relatorio_service.dart';
import '../../services/auth_service.dart';
import 'compra_detalhes_screen.dart';

class ComprasPrazoListScreen extends StatefulWidget {
  const ComprasPrazoListScreen({super.key});

  @override
  State<ComprasPrazoListScreen> createState() => _ComprasPrazoListScreenState();
}

class _ComprasPrazoListScreenState extends State<ComprasPrazoListScreen> {
  List<CompraPrazo> _compras = [];
  bool _isLoading = true;
  String? _errorMessage;
  RelatorioService? _relatorioService;
  String _filtroStatus = 'TODOS';

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_relatorioService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _relatorioService = RelatorioService(authService);
      _carregarCompras();
    }
  }

  Future<void> _carregarCompras() async {
    if (!mounted || _relatorioService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resultado = await _relatorioService!.contasPagar(
        status: _filtroStatus == 'TODOS' ? null : _filtroStatus,
      );

      if (!mounted) return;

      setState(() {
        _compras = resultado['compras'] as List<CompraPrazo>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Compras a Prazo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarCompras,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'TODOS', label: Text('Todos')),
                      ButtonSegment(value: 'PENDENTE', label: Text('Pendentes')),
                      ButtonSegment(value: 'PAGO', label: Text('Pagos')),
                    ],
                    selected: {_filtroStatus},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _filtroStatus = newSelection.first;
                      });
                      _carregarCompras();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: _isLoading
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
                              onPressed: _carregarCompras,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _compras.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma compra encontrada',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _carregarCompras,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _compras.length,
                              itemBuilder: (context, index) {
                                final compra = _compras[index];
                                return _CompraCard(
                                  compra: compra,
                                  formatoMoeda: _formatoMoeda,
                                  formatoData: _formatoData,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CompraDetalhesScreen(compra: compra),
                                      ),
                                    ).then((_) => _carregarCompras());
                                  },
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

class _CompraCard extends StatelessWidget {
  final CompraPrazo compra;
  final NumberFormat formatoMoeda;
  final DateFormat formatoData;
  final VoidCallback onTap;

  const _CompraCard({
    required this.compra,
    required this.formatoMoeda,
    required this.formatoData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPago = compra.status == 'PAGO' || compra.status == 'quitada';
    final isCancelada = compra.status == 'cancelada' || compra.status == 'CANCELADA';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCancelada ? Border.all(color: Colors.red, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isCancelada ? Colors.red : isPago ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCancelada ? Icons.cancel : isPago ? Icons.check_circle : Icons.schedule,
                        color: isCancelada ? Colors.red : isPago ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            compra.fornecedor?.nome ?? 'Fornecedor',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: isCancelada ? TextDecoration.lineThrough : null,
                              color: isCancelada ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatoData.format(compra.dataCompra),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatoMoeda.format(compra.valorTotal),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isCancelada ? Colors.grey : const Color(0xFFEF4444),
                            decoration: isCancelada ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isCancelada ? Colors.red : isPago ? Colors.green : Colors.red).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCancelada ? 'Cancelada' : isPago ? 'Pago' : 'Pendente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCancelada ? Colors.red : isPago ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
