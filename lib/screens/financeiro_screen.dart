import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/clientes_api_service.dart';
import '../services/fornecedores_api_service.dart';
import 'clientes_screen.dart';
import 'contas_receber_screen.dart';
import 'contas_pagar_screen.dart';
import 'fornecedores_screen.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  Map<String, dynamic>? _resumoReceber;
  Map<String, dynamic>? _resumoPagar;
  int _alertasReceber = 0;
  int _alertasPagar = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      final resumoReceber = await ClientesApiService.getTotalReceber(auth.token!);
      final resumoPagar = await FornecedoresApiService.getTotalPagar(auth.token!);
      final alertasReceber = await ClientesApiService.getAlertasCount(auth.token!);
      final alertasPagar = await FornecedoresApiService.getAlertasCount(auth.token!);

      setState(() {
        _resumoReceber = resumoReceber;
        _resumoPagar = resumoPagar;
        _alertasReceber = (alertasReceber is int) ? alertasReceber : int.tryParse(alertasReceber.toString()) ?? 0;
        _alertasPagar = (alertasPagar is int) ? alertasPagar : int.tryParse(alertasPagar.toString()) ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar resumo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarResumo,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Resumo Financeiro
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo Financeiro',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ResumoCard(
                                  title: 'A Receber',
                                  value: formatter.format(
                                    _resumoReceber?['total_receber'] ?? 0,
                                  ),
                                  color: Colors.green,
                                  icon: Icons.arrow_downward,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ResumoCard(
                                  title: 'A Pagar',
                                  value: formatter.format(
                                    _resumoPagar?['total_pagar'] ?? 0,
                                  ),
                                  color: Colors.red,
                                  icon: Icons.arrow_upward,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Alertas
                  if (_alertasReceber > 0 || _alertasPagar > 0)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_alertasReceber + _alertasPagar} conta(s) vencida(s)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Menu de Ações
                  const Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    title: 'Clientes',
                    subtitle: 'Gerenciar clientes',
                    icon: Icons.people,
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClientesScreen()),
                    ),
                  ),
                  _MenuCard(
                    title: 'Contas a Receber',
                    subtitle: 'Vendas a prazo e recebimentos',
                    icon: Icons.arrow_downward,
                    color: const Color(0xFF10B981),
                    badge: _alertasReceber > 0 ? _alertasReceber : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContasReceberScreen()),
                    ),
                  ),
                  _MenuCard(
                    title: 'Fornecedores',
                    subtitle: 'Gerenciar fornecedores',
                    icon: Icons.business,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FornecedoresScreen()),
                    ),
                  ),
                  _MenuCard(
                    title: 'Contas a Pagar',
                    subtitle: 'Compras a prazo e pagamentos',
                    icon: Icons.arrow_upward,
                    color: const Color(0xFFEF4444),
                    badge: _alertasPagar > 0 ? _alertasPagar : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContasPagarScreen()),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _ResumoCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int? badge;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Text(title),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
