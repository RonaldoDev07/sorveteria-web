import 'package:flutter/material.dart';
import 'clientes_screen.dart';
import 'fornecedores_screen.dart';
import 'dashboard_financeiro_screen.dart';
import 'parcelas_screen.dart';
import 'contas_receber_screen.dart';
import 'contas_pagar_screen.dart';
import '../relatorio_lucro_screen.dart';
import 'vendas_prazo_list_screen.dart';
import 'compras_prazo_list_screen.dart';

/// Tela de menu do módulo financeiro - v2
class FinanceiroMenuScreen extends StatelessWidget {
  const FinanceiroMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Debug: verificar se código novo está sendo executado
    print('🔥 FINANCEIRO MENU V3 - 9 CARDS');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular número de colunas baseado na largura
          int crossAxisCount;
          double childAspectRatio;
          
          if (constraints.maxWidth < 600) {
            // Mobile: 2 colunas
            crossAxisCount = 2;
            childAspectRatio = 0.85;
          } else if (constraints.maxWidth < 900) {
            // Tablet: 3 colunas
            crossAxisCount = 3;
            childAspectRatio = 0.9;
          } else if (constraints.maxWidth < 1200) {
            // Desktop pequeno: 4 colunas
            crossAxisCount = 4;
            childAspectRatio = 0.95;
          } else {
            // Desktop grande: 4 colunas com mais espaço
            crossAxisCount = 4;
            childAspectRatio = 1.0;
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
            _MenuCard(
              emoji: '👤',
              title: 'Clientes',
              subtitle: 'Cadastro de clientes',
              color: const Color(0xFF3B82F6), // Azul
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
              emoji: '🏢',
              title: 'Fornecedores',
              subtitle: 'Cadastro de fornecedores',
              color: const Color(0xFFF97316), // Laranja
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
              emoji: '💰',
              title: 'Contas a Receber',
              subtitle: 'Recebimentos pendentes',
              color: const Color(0xFF14B8A6), // Teal
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
              emoji: '💸',
              title: 'Contas a Pagar',
              subtitle: 'Pagamentos pendentes',
              color: const Color(0xFFEF4444), // Vermelho
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
              emoji: '📋',
              title: 'Vendas a Prazo',
              subtitle: 'Histórico de vendas',
              color: const Color(0xFF10B981), // Verde
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendasPrazoListScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              emoji: '📦',
              title: 'Compras a Prazo',
              subtitle: 'Histórico de compras',
              color: const Color(0xFF06B6D4), // Cyan
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComprasPrazoListScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              emoji: '📅',
              title: 'Parcelas',
              subtitle: 'Controle de parcelas',
              color: const Color(0xFF6366F1), // Índigo
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
              emoji: '📈',
              title: 'Relatório de Lucro',
              subtitle: 'Análise de vendas e lucros',
              color: const Color(0xFF8B5CF6), // Roxo
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RelatorioLucroScreen(),
                  ),
                );
              },
            ),
            _MenuCard(
              emoji: '📊',
              title: 'Dashboard',
              subtitle: 'Visão geral financeira',
              color: const Color(0xFFEC4899), // Pink
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
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.emoji,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 40,
                    ),
                  ),
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
