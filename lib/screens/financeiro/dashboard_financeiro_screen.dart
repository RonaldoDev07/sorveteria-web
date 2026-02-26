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
      appBar: AppBar(
        title: const Text('Dashboard Financeiro'),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDashboard,
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
                      // Saldo Líquido
                      Card(
                        elevation: 4,
                        color: _dashboard!.saldoLiquido >= 0 
                            ? Colors.green.shade50 
                            : Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'Saldo Líquido',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatoMoeda.format(_dashboard!.saldoLiquido),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _dashboard!.saldoLiquido >= 0 
                                      ? Colors.green.shade700 
                                      : Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A Receber - A Pagar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Contas a Receber e Pagar
                      Row(
                        children: [
                          Expanded(
                            child: _CardValor(
                              titulo: 'A Receber',
                              valor: _dashboard!.totalAReceber,
                              cor: Colors.green,
                              icone: Icons.arrow_downward,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CardValor(
                              titulo: 'A Pagar',
                              valor: _dashboard!.totalAPagar,
                              cor: Colors.red,
                              icone: Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Contas Atrasadas
                      Row(
                        children: [
                          Expanded(
                            child: _CardContador(
                              titulo: 'Atrasadas\n(Receber)',
                              valor: _dashboard!.contasAtrasadasReceber,
                              cor: Colors.orange,
                              icone: Icons.warning,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CardContador(
                              titulo: 'Atrasadas\n(Pagar)',
                              valor: _dashboard!.contasAtrasadasPagar,
                              cor: Colors.deepOrange,
                              icone: Icons.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Vencimentos
                      Row(
                        children: [
                          Expanded(
                            child: _CardContador(
                              titulo: 'Vencendo\nHoje',
                              valor: _dashboard!.contasVencendoHoje,
                              cor: Colors.blue,
                              icone: Icons.today,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CardContador(
                              titulo: 'Vencendo\nesta Semana',
                              valor: _dashboard!.contasVencendoSemana,
                              cor: Colors.purple,
                              icone: Icons.date_range,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Resumo
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resumo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _LinhaResumo(
                                label: 'Total a Receber:',
                                valor: _formatoMoeda.format(_dashboard!.totalAReceber),
                                cor: Colors.green,
                              ),
                              _LinhaResumo(
                                label: 'Total a Pagar:',
                                valor: _formatoMoeda.format(_dashboard!.totalAPagar),
                                cor: Colors.red,
                              ),
                              const Divider(),
                              _LinhaResumo(
                                label: 'Saldo Líquido:',
                                valor: _formatoMoeda.format(_dashboard!.saldoLiquido),
                                cor: _dashboard!.saldoLiquido >= 0 
                                    ? Colors.green 
                                    : Colors.red,
                                negrito: true,
                              ),
                            ],
                          ),
                        ),
                      ),
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
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
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
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
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
