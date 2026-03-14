import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'clientes_screen.dart';
import 'fornecedores_screen.dart';
import 'dashboard_financeiro_screen.dart';
import 'parcelas_screen.dart';
import 'contas_receber_screen.dart';
import 'contas_pagar_screen.dart';
import '../relatorio_lucro_screen.dart';
import 'vendas_prazo_list_screen.dart';
import 'compras_prazo_list_screen.dart';

class FinanceiroMenuScreen extends StatelessWidget {
  const FinanceiroMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    final cards = <_CardData>[
      if (auth.canGerenciarClientes)
        _CardData(
          icon: Icons.people_alt_rounded,
          title: 'Clientes',
          subtitle: 'Cadastro e gestão',
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ClientesScreen())),
        ),
      if (auth.canGerenciarFornecedores)
        _CardData(
          icon: Icons.business_rounded,
          title: 'Fornecedores',
          subtitle: 'Cadastro e gestão',
          gradient: const LinearGradient(
            colors: [Color(0xFFB45309), Color(0xFFFBBF24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FornecedoresScreen())),
        ),
      _CardData(
        icon: Icons.arrow_circle_down_rounded,
        title: 'A Receber',
        subtitle: 'Cobranças pendentes',
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ContasReceberScreen())),
      ),
      if (auth.isAdmin)
        _CardData(
          icon: Icons.arrow_circle_up_rounded,
          title: 'A Pagar',
          subtitle: 'Pagamentos pendentes',
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFF87171)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ContasPagarScreen())),
        ),
      if (auth.canVenderPrazo)
        _CardData(
          icon: Icons.receipt_long_rounded,
          title: 'Vendas a Prazo',
          subtitle: 'Histórico de vendas',
          gradient: const LinearGradient(
            colors: [Color(0xFF047857), Color(0xFF6EE7B7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VendasPrazoListScreen())),
        ),
      if (auth.canComprarPrazo)
        _CardData(
          icon: Icons.inventory_rounded,
          title: 'Compras a Prazo',
          subtitle: 'Histórico de compras',
          gradient: const LinearGradient(
            colors: [Color(0xFF0E7490), Color(0xFF67E8F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ComprasPrazoListScreen())),
        ),
      _CardData(
        icon: Icons.calendar_month_rounded,
        title: 'Parcelas',
        subtitle: 'Controle de parcelas',
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ParcelasScreen())),
      ),
      if (auth.canVerRelatorios) ...[
        _CardData(
          icon: Icons.bar_chart_rounded,
          title: 'Relatório',
          subtitle: 'Lucros e vendas',
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFFA78BFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RelatorioLucroScreen())),
        ),
        _CardData(
          icon: Icons.dashboard_rounded,
          title: 'Dashboard',
          subtitle: 'Visão geral',
          gradient: const LinearGradient(
            colors: [Color(0xFFBE185D), Color(0xFFF9A8D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DashboardFinanceiroScreen())),
        ),
      ],
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFBE185D), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppTheme.radiusMd,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Módulo',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Financeiro',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, i) => _FinanceiroCard(data: cards[i]),
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

class _CardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _CardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

class _FinanceiroCard extends StatefulWidget {
  final _CardData data;
  const _FinanceiroCard({required this.data});

  @override
  State<_FinanceiroCard> createState() => _FinanceiroCardState();
}

class _FinanceiroCardState extends State<_FinanceiroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstColor = widget.data.gradient.colors.first;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.data.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.data.gradient,
            borderRadius: AppTheme.radiusXl,
            boxShadow: [
              BoxShadow(
                color: firstColor.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decoração
              Positioned(
                right: -14,
                bottom: -14,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Conteúdo
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppTheme.radiusMd,
                      ),
                      child: Icon(widget.data.icon, color: Colors.white, size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.data.subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Seta
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 9,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
