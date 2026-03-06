import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
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
    final auth = Provider.of<AuthService>(context);
    
    // Debug: verificar se código novo está sendo executado
    print('🔥 FINANCEIRO MENU V3 - COM PERMISSÕES');
    print('   Perfil: ${auth.perfil}');
    print('   Pode gerenciar clientes: ${auth.canGerenciarClientes}');
    
    // Criar lista de cards
    final cards = <Widget>[
            // Clientes e Fornecedores - apenas ADMIN e VENDEDOR
            if (auth.canGerenciarClientes) ...[
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
            ],
            if (auth.canGerenciarFornecedores) ...[
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
            ],
            // Contas a Receber e Pagar - todos podem ver
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
            if (auth.isAdmin)
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
            // Vendas e Compras a Prazo - apenas ADMIN e VENDEDOR
            if (auth.canVenderPrazo) ...[
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
            ],
            if (auth.canComprarPrazo) ...[
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
            ],
            // Parcelas - todos podem ver
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
            // Relatórios - apenas ADMIN e VENDEDOR
            if (auth.canVerRelatorios) ...[
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
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
          children: cards,
        ),
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
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
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 8,
          shadowColor: widget.color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Stack(
                  children: [
                    // Padrão decorativo no fundo
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Conteúdo
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Ícone de seta
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
