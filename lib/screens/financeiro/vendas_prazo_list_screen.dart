import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../services/financeiro/relatorio_service.dart';
import '../../services/auth_service.dart';
import 'venda_detalhes_screen.dart';

class VendasPrazoListScreen extends StatefulWidget {
  const VendasPrazoListScreen({super.key});

  @override
  State<VendasPrazoListScreen> createState() => _VendasPrazoListScreenState();
}

class _VendasPrazoListScreenState extends State<VendasPrazoListScreen> {
  List<VendaPrazo> _vendas = [];
  bool _isLoading = true;
  String? _errorMessage;
  RelatorioService? _relatorioService;
  String _filtroStatus = 'TODOS';

  static const _cor = Color(0xFF10B981);
  static const _gradiente = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_relatorioService == null) {
      _relatorioService = RelatorioService(Provider.of<AuthService>(context, listen: false));
      _carregar();
    }
  }

  Future<void> _carregar() async {
    if (!mounted || _relatorioService == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final resultado = await _relatorioService!.contasReceber(
        status: _filtroStatus == 'TODOS' ? null : _filtroStatus,
      );
      if (!mounted) return;
      setState(() {
        _vendas = resultado['vendas'] as List<VendaPrazo>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  // Totais para o resumo
  double get _totalPendente => _vendas
      .where((v) => v.status != 'PAGO' && v.status != 'quitada' && v.status != 'cancelada' && v.status != 'CANCELADA')
      .fold(0, (s, v) => s + v.valorTotal);

  int get _countPendente => _vendas
      .where((v) => v.status != 'PAGO' && v.status != 'quitada' && v.status != 'cancelada' && v.status != 'CANCELADA')
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Vendas a Prazo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _gradiente)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _carregar, tooltip: 'Atualizar'),
        ],
      ),
      body: Column(
        children: [
          // Card de resumo (só quando tem dados)
          if (!_isLoading && _errorMessage == null && _vendas.isNotEmpty)
            _buildResumoCard(),
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'TODOS', label: Text('Todos', style: TextStyle(fontSize: 13))),
                ButtonSegment(value: 'PENDENTE', label: Text('Pendentes', style: TextStyle(fontSize: 13))),
                ButtonSegment(value: 'PAGO', label: Text('Pagos', style: TextStyle(fontSize: 13))),
              ],
              selected: {_filtroStatus},
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              onSelectionChanged: (s) {
                setState(() => _filtroStatus = s.first);
                _carregar();
              },
            ),
          ),
          // Contador
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_vendas.length} venda${_vendas.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          // Lista
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildResumoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _cor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A Receber', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  _formatoMoeda.format(_totalPendente),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$_countPendente',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text('pendentes', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Erro ao carregar vendas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_vendas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Nenhuma venda encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente mudar o filtro de status',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _vendas.length,
        itemBuilder: (context, index) => _VendaCard(
          venda: _vendas[index],
          formatoMoeda: _formatoMoeda,
          formatoData: _formatoData,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VendaDetalhesScreen(venda: _vendas[index])),
          ).then((_) => _carregar()),
        ),
      ),
    );
  }
}

class _VendaCard extends StatelessWidget {
  final VendaPrazo venda;
  final NumberFormat formatoMoeda;
  final DateFormat formatoData;
  final VoidCallback onTap;

  const _VendaCard({
    required this.venda,
    required this.formatoMoeda,
    required this.formatoData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPago = venda.status == 'PAGO' || venda.status == 'quitada';
    final isCancelada = venda.status == 'cancelada' || venda.status == 'CANCELADA';

    final statusColor = isCancelada ? Colors.red : isPago ? Colors.green : Colors.orange;
    final statusLabel = isCancelada ? 'Cancelada' : isPago ? 'Pago' : 'Pendente';
    final statusIcon = isCancelada ? Icons.cancel_outlined : isPago ? Icons.check_circle_outline : Icons.schedule_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCancelada ? Border.all(color: Colors.red.shade200, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Ícone de status
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venda.cliente?.nome ?? 'Cliente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isCancelada ? Colors.grey : const Color(0xFF1F2937),
                          decoration: isCancelada ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            formatoData.format(venda.dataVenda),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Valor e status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatoMoeda.format(venda.valorTotal),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCancelada ? Colors.grey : const Color(0xFF10B981),
                        decoration: isCancelada ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                      ),
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
  }
}
