import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'produtos_screen.dart';
import 'cadastro_produto_screen.dart';
import 'selecionar_produto_screen.dart';
import 'relatorio_lucro_screen.dart';
import 'movimentacoes_screen.dart';
import 'usuarios_screen.dart';
import 'carrinho_venda_screen.dart';
import 'financeiro_screen.dart';

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
      auth.logout();
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
                      // Ordem priorizada: ações do dia a dia primeiro
                      _MenuCard(
                        emoji: '🛒',
                        title: 'Venda Rápida',
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SelecionarProdutoScreen(tipo: 'SAIDA')),
                        ),
                      ),
                      _MenuCard(
                        emoji: '🛍️',
                        title: 'Carrinho (Vários Itens)',
                        color: const Color(0xFF059669),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CarrinhoVendaScreen()),
                        ),
                      ),
                      if (auth.canCadastrarProduto)
                        _MenuCard(
                          emoji: '📦',
                          title: 'Registrar Compra',
                          color: const Color(0xFF14B8A6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SelecionarProdutoScreen(tipo: 'ENTRADA')),
                          ),
                        ),
                      _MenuCard(
                        emoji: '📊',
                        title: 'Produtos',
                        color: const Color(0xFF3B82F6),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProdutosScreen()),
                        ),
                      ),
                      if (auth.canCadastrarProduto)
                        _MenuCard(
                          emoji: '➕',
                          title: 'Cadastrar Produto',
                          color: const Color(0xFF6366F1),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CadastroProdutoScreen()),
                          ),
                        ),
                      _MenuCard(
                        emoji: '💰',
                        title: 'Relatório de Lucro',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RelatorioLucroScreen()),
                        ),
                      ),
                      _MenuCard(
                        emoji: '📜',
                        title: 'Histórico',
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MovimentacoesScreen()),
                        ),
                      ),
                      _MenuCard(
                        emoji: '💼',
                        title: 'Gestão Financeira',
                        color: const Color(0xFF06B6D4),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
                        ),
                      ),
                      if (auth.isAdmin)
                        _MenuCard(
                          emoji: '👥',
                          title: 'Gerenciar Usuários',
                          color: const Color(0xFF7C3AED),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                          ),
                        ),
                    ];
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
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

class _MenuCardState extends State<_MenuCard> {
  bool _isPressed = false;

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
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(
                          fontSize: 36,
                        ),
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
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.2,
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
