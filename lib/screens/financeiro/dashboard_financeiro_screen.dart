import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/dashboard_model.dart';
import '../../services/financeiro/dashboard_service.dart';
import '../../services/auth_service.dart';

class DashboardFinanceiroScreen extends StatefulWidget {
  const DashboardFinanceiroScreen({super.key});

  @override
  State<DashboardFinanceiroScreen> createState() => _DashboardFinanceiroScreenState();
}

class _DashboardFinanceiroScreenState extends State<DashboardFinanceiroScreen> {
  DashboardFinanceiro? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;
  DashboardService? _dashboardService;

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dashboardService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _dashboardService = DashboardService(authService);
      _carregarDashboard();
    }
  }

  Future<void> _carregarDashboard() async {
    if (!mounted || _dashboardService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _dashboardService!.buscarDashboard();
      
      if (!mounted) return;
      
      setState(() {
        _dashboard = dashboard;
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
          'Dashboard Financeiro',
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
              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
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
            onPressed: _carregarDashboard,
            tooltip: 'Atualizar',
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
                        onPressed: _carregarDashboard,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Saldo Líquido - Card Principal
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _dashboard!.saldoLiquido >= 0
                                ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                                : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (_dashboard!.saldoLiquido >= 0 
                                  ? const Color(0xFF10B981) 
                                  : const Color(0xFFEF4444)).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Saldo Líquido',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _formatoMoeda.format(_dashboard!.saldoLiquido),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'A Receber - A Pagar',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Contas a Receber e Pagar
                      Row(
                        children: [
                          Expanded(
                            child: _CardValor(
                              titulo: 'A Receber',
                              valor: _dashboard!.totalAReceber,
                              cor: const Color(0xFF10B981),
                              icone: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CardValor(
                              titulo: 'A Pagar',
                              valor: _dashboard!.totalAPagar,
                              cor: const Color(0xFFEF4444),
                              icone: Icons.arrow_upward_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Contas Atrasadas
                      Row(
                        children: [
                          Expanded(
                            child: _CardContador(
                              titulo: 'Atrasadas\n(Receber)',
                              valor: _dashboard!.contasAtrasadasReceber,
                              cor: const Color(0xFFF59E0B),
                              icone: Icons.warning_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CardContador(
                              titulo: 'Atrasadas\n(Pagar)',
                              valor: _dashboard!.contasAtrasadasPagar,
                              cor: const Color(0xFFDC2626),
                              icone: Icons.warning_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Vencimentos
                      Row(
                        children: [
                          Expanded(
                            child: _CardContador(
                              titulo: 'Vencendo\nHoje',
                              valor: _dashboard!.contasVencendoHoje,
                              cor: const Color(0xFF3B82F6),
                              icone: Icons.today_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CardContador(
                              titulo: 'Vencendo\nesta Semana',
                              valor: _dashboard!.contasVencendoSemana,
                              cor: const Color(0xFF8B5CF6),
                              icone: Icons.date_range_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Resumo
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.summarize_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Resumo',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _LinhaResumo(
                                label: 'Total a Receber:',
                                valor: _formatoMoeda.format(_dashboard!.totalAReceber),
                                cor: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _LinhaResumo(
                                label: 'Total a Pagar:',
                                valor: _formatoMoeda.format(_dashboard!.totalAPagar),
                                cor: const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _dashboard!.saldoLiquido >= 0
                                      ? [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF34D399).withOpacity(0.1)]
                                      : [const Color(0xFFEF4444).withOpacity(0.1), const Color(0xFFF87171).withOpacity(0.1)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _dashboard!.saldoLiquido >= 0 
                                      ? const Color(0xFF10B981) 
                                      : const Color(0xFFEF4444),
                                  width: 2,
                                ),
                              ),
                              child: _LinhaResumo(
                                label: 'Saldo Líquido:',
                                valor: _formatoMoeda.format(_dashboard!.saldoLiquido),
                                cor: _dashboard!.saldoLiquido >= 0 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444),
                                negrito: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}

class _CardValor extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color cor;
  final IconData icone;

  const _CardValor({
    required this.titulo,
    required this.valor,
    required this.cor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatoMoeda.format(valor),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CardContador extends StatelessWidget {
  final String titulo;
  final int valor;
  final Color cor;
  final IconData icone;

  const _CardContador({
    required this.titulo,
    required this.valor,
    required this.cor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            valor.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final bool negrito;

  const _LinhaResumo({
    required this.label,
    required this.valor,
    required this.cor,
    this.negrito = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: negrito ? 16 : 14,
              fontWeight: negrito ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: negrito ? 16 : 14,
              fontWeight: negrito ? FontWeight.bold : FontWeight.w500,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
