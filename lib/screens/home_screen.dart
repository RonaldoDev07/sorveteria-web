import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import '../widgets/auth_wrapper.dart';
import '../widgets/connectivity_banner.dart';
import 'produtos_screen.dart';
import 'vendas_menu_screen.dart';
import 'movimentacoes_screen.dart';
import 'usuarios_screen.dart';
import 'carrinho_venda_screen.dart';
import 'financeiro/financeiro_menu_screen.dart';
import 'financeiro/contas_receber_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _confirmarLogout(BuildContext context, AuthService auth) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF9C27B0),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Sair do Sistema',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Deseja realmente sair do sistema?',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Sair',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (resultado == true) {
      print('🚪 Usuário confirmou logout');
      
      // Fazer logout
      await auth.logout();
      
      print('🔄 Navegando para tela de login...');
      
      // Garantir que está montado antes de navegar
      if (!context.mounted) return;
      
      // Navegar para AuthWrapper removendo todas as rotas anteriores
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
          settings: const RouteSettings(name: '/'),
        ),
        (route) => false, // Remove todas as rotas
      );
      
      print('✅ Navegação concluída');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFBA68C8), // Lilás claro
                      Color(0xFFE1BEE7), // Lilás bem claro
                    ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.icecream_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sorveteria',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CAMILA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
        titleSpacing: 16,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF9C27B0), // Lilás
                Color(0xFFBA68C8), // Lilás claro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        actions: [
          Consumer<OfflineService>(
            builder: (context, offlineService, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: offlineService.isOnline 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: offlineService.isOnline ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      offlineService.isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: offlineService.isOnline ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offlineService.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: offlineService.isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmarLogout(context, auth),
            tooltip: 'Sair',
          ),
        ],
      ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Banner de conectividade
                const ConnectivityBanner(),
                // Header com informações do usuário
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF9C27B0).withOpacity(0.1),
                      backgroundImage: auth.fotoUrl != null ? NetworkImage(auth.fotoUrl!) : null,
                      child: auth.fotoUrl == null
                          ? Text(
                              auth.username?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9C27B0),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${auth.username ?? 'Usuário'}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.isAdmin ? 'Administrador' : (auth.isVendedor ? 'Proprietária' : 'Operador'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Grid de cards
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calcula o número de colunas baseado na largura
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 600 ? 3 : 2;
                    
                    // Criar lista de cards
                    final cards = <Widget>[
                      // Ações principais do dia a dia
                      _MenuCard(
                        emoji: '🛒',
                        title: 'Vendas',
                        color: const Color(0xFF10B981), // Verde vibrante
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VendasMenuScreen()),
                        ),
                      ),
                      _MenuCard(
                        emoji: '🛍️',
                        title: 'Carrinho (Vários Itens)',
                        color: const Color(0xFF059669), // Verde escuro
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CarrinhoVendaScreen()),
                        ),
                      ),
                      _MenuCard(
                        emoji: '💰',
                        title: 'Receber Pagamento',
                        color: const Color(0xFF16A34A), // Verde dinheiro
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContasReceberScreen()),
                        ),
                      ),
                      _MenuCard(
                        emoji: '📦',
                        title: 'Produtos',
                        color: const Color(0xFF2563EB), // Azul royal
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProdutosScreen()),
                        ),
                      ),
                      _MenuCard(
                        emoji: '📜',
                        title: 'Histórico Completo',
                        color: const Color(0xFFF59E0B), // Âmbar/Dourado
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MovimentacoesScreen()),
                        ),
                      ),
                      _MenuCard(
                        emoji: '💼',
                        title: 'Financeiro',
                        color: const Color(0xFFEC4899), // Rosa/Pink
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FinanceiroMenuScreen(),
                          ),
                        ),
                      ),
                      if (auth.isAdmin)
                        _MenuCard(
                          emoji: '👥',
                          title: 'Gerenciar Usuários',
                          color: const Color(0xFF7C3AED), // Violeta
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                          ),
                        ),
                    ];
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      padding: const EdgeInsets.all(8),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.25, // Mais largo que alto
                      children: cards,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final String emoji;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.emoji,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
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
                  // Shimmer effect sutil
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Transform.translate(
                            offset: Offset(_shimmerAnimation.value * 200, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Conteúdo do card
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
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
                          child: Text(
                            widget.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ícone de seta no canto
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
    );
  }
}
