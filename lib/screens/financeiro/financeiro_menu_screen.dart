import 'package:flutter/material.dart';
import 'clientes_screen.dart';
import 'fornecedores_screen.dart';
import 'dashboard_financeiro_screen.dart';
import 'parcelas_screen.dart';
import 'contas_receber_screen.dart';
import 'contas_pagar_screen.dart';
import 'vendas_prazo_screen.dart';
import 'compras_prazo_screen.dart';

/// Tela de menu do módulo financeiro
class FinanceiroMenuScreen extends StatelessWidget {
  const FinanceiroMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _MenuCard(
              icon: Icons.people,
              title: 'Clientes',
              subtitle: 'Cadastro de clientes',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientesScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.business,
              title: 'Fornecedores',
              subtitle: 'Cadastro de fornecedores',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FornecedoresScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.shopping_cart,
              title: 'Vendas a Prazo',
              subtitle: 'Vendas parceladas',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendasPrazoScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.shopping_bag,
              title: 'Compras a Prazo',
              subtitle: 'Compras parceladas',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComprasPrazoScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.attach_money,
              title: 'Contas a Receber',
              subtitle: 'Recebimentos pendentes',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContasReceberScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.money_off,
              title: 'Contas a Pagar',
              subtitle: 'Pagamentos pendentes',
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContasPagarScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.calendar_today,
              title: 'Parcelas',
              subtitle: 'Controle de parcelas',
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParcelasScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.dashboard,
              title: 'Dashboard',
              subtitle: 'Visão geral financeira',
              color: const Color(0xFFEC4899),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardFinanceiroScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
