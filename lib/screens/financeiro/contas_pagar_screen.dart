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
  final _searchController = TextEditingController();
  String? _filtroStatus;

  double _totalAPagar = 0;
  double _totalPago = 0;
  double _totalEmAberto = 0;
  int _contasAtrasadas = 0;

  static const _cor = Color(0xFFDC2626);
  static const _gradiente = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_relatorioService == null) {
      _relatorioService = RelatorioService(Provider.of<AuthService>(context, listen: false));
      _carregar();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (!mounted || _relatorioService == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final resultado = await _relatorioService!.contasPagar(status: _filtroStatus);
      if (!mounted) return;
      setState(() {
        _compras = resultado['compras'] as List<CompraPrazo>;
        _comprasFiltradas = _compras;
        _totalAPagar = resultado['total_a_pagar'] ?? 0.0;
        _totalPago = resultado['total_pago'] ?? 0.0;
        _totalEmAberto = resultado['total_em_aberto'] ?? 0.0;
        _contasAtrasadas = resultado['contas_atrasadas'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  void _filtrar(String query) {
    setState(() {
      _comprasFiltradas = query.isEmpty
          ? List.from(_compras)
          : _compras.where((c) => (c.fornecedor?.nome ?? '').toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'quitada': return Colors.green;
      case 'atrasada': return Colors.red;
      case 'cancelada': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'quitada': return 'Quitada';
      case 'atrasada': return 'Atrasada';
      case 'cancelada': return 'Cancelada';
      default: return 'Em Dia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Contas a Pagar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _gradiente)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              setState(() => _filtroStatus = v == 'todas' ? null : v);
              _carregar();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'todas', child: Text('Todas')),
              PopupMenuItem(value: 'em_dia', child: Text('Em Dia')),
              PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              PopupMenuItem(value: 'quitada', child: Text('Quitadas')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _carregar),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : Column(
                  children: [
                    _buildResumo(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filtrar,
                        decoration: InputDecoration(
                          hintText: 'Buscar por fornecedor...',
                          prefixIcon: const Icon(Icons.search_rounded, color: _cor),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchController.clear(); _filtrar(''); })
                              : null,
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cor, width: 2)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(children: [
                        Text('${_comprasFiltradas.length} conta${_comprasFiltradas.length != 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    Expanded(child: _buildLista()),
                  ],
                ),
    );
  }

  Widget _buildResumo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFF87171)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _cor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(child: _ResumoItem(label: 'A Pagar', valor: _fmt.format(_totalAPagar))),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(child: _ResumoItem(label: 'Pago', valor: _fmt.format(_totalPago))),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(child: _ResumoItem(label: 'Em Aberto', valor: _fmt.format(_totalEmAberto))),
          if (_contasAtrasadas > 0) ...[
            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
            Expanded(child: _ResumoItem(label: 'Atrasadas', valor: '$_contasAtrasadas', destaque: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Erro ao carregar dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(backgroundColor: _cor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_comprasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhuma conta encontrada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _comprasFiltradas.length,
        itemBuilder: (context, i) {
          final compra = _comprasFiltradas[i];
          final sc = _statusColor(compra.status);
          final sl = _statusLabel(compra.status);
          final isCancelada = compra.status == 'cancelada';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isCancelada ? Border.all(color: Colors.red.shade200, width: 1.5) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompraDetalhesScreen(compra: compra))).then((_) => _carregar()),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.shopping_bag_rounded, color: sc, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(compra.fornecedor?.nome ?? 'Fornecedor',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                    color: isCancelada ? Colors.grey : const Color(0xFF1F2937),
                                    decoration: isCancelada ? TextDecoration.lineThrough : null)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(_fmtData.format(compra.dataCompra), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              const SizedBox(width: 10),
                              Text('Saldo: ${_fmt.format(compra.saldoDevedor)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_fmt.format(compra.valorTotal),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                                  color: isCancelada ? Colors.grey : _cor,
                                  decoration: isCancelada ? TextDecoration.lineThrough : null)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(sl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;
  const _ResumoItem({required this.label, required this.valor, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: destaque ? Colors.red.shade200 : Colors.white), textAlign: TextAlign.center),
      ],
    );
  }
}
