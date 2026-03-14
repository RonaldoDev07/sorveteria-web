import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'criar_usuario_screen.dart';
import 'editar_usuario_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _isLoading = true;

  static const _gradiente = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _cor = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final usuarios = await ApiService.getUsuarios(auth.token!);
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuários: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleAtivo(int usuarioId, String nome, bool ativoAtual) async {
    final acao = ativoAtual ? 'desativar' : 'ativar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${acao[0].toUpperCase()}${acao.substring(1)} Usuário'),
        content: Text('Deseja realmente $acao o usuário "$nome"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ativoAtual ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(acao[0].toUpperCase() + acao.substring(1)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await ApiService.toggleAtivoUsuario(auth.token!, usuarioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário ${acao}do com sucesso'), backgroundColor: Colors.green),
        );
        _loadUsuarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletarUsuario(int usuarioId, String nome) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Deletar Usuário', style: TextStyle(fontSize: 18)),
        ]),
        content: Text('Deseja excluir "$nome"?\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await ApiService.deletarUsuario(auth.token!, usuarioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário deletado com sucesso'), backgroundColor: Colors.green),
        );
        _loadUsuarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Usuários', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _gradiente)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadUsuarios, tooltip: 'Atualizar'),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CriarUsuarioScreen()),
          );
          if (resultado == true) _loadUsuarios();
        },
        backgroundColor: _cor,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Novo Usuário', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhum usuário cadastrado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsuarios,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _usuarios.length,
        itemBuilder: (context, index) => _UsuarioCard(
          usuario: _usuarios[index],
          onEditar: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditarUsuarioScreen(usuario: _usuarios[index])),
            );
            if (resultado == true) _loadUsuarios();
          },
          onToggleAtivo: () => _toggleAtivo(
            _usuarios[index]['id'],
            _usuarios[index]['nome'],
            _usuarios[index]['ativo'] == true,
          ),
          onDeletar: () => _deletarUsuario(_usuarios[index]['id'], _usuarios[index]['nome']),
        ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final dynamic usuario;
  final VoidCallback onEditar;
  final VoidCallback onToggleAtivo;
  final VoidCallback onDeletar;

  const _UsuarioCard({
    required this.usuario,
    required this.onEditar,
    required this.onToggleAtivo,
    required this.onDeletar,
  });

  @override
  Widget build(BuildContext context) {
    final isAtivo = usuario['ativo'] == true;
    final perfil = usuario['perfil'];
    final isAdmin = perfil == 'ADMIN';
    final isVendedor = perfil == 'VENDEDOR';

    final perfilColors = isAdmin
        ? [const Color(0xFF7C3AED), const Color(0xFFA78BFA)]
        : isVendedor
            ? [const Color(0xFF059669), const Color(0xFF34D399)]
            : [const Color(0xFF2563EB), const Color(0xFF60A5FA)];

    final perfilIcon = isAdmin
        ? Icons.admin_panel_settings_rounded
        : isVendedor
            ? Icons.storefront_rounded
            : Icons.person_rounded;

    final perfilLabel = isAdmin ? 'Admin' : isVendedor ? 'Proprietária' : 'Usuário';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAtivo ? null : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isAtivo ? perfilColors : [Colors.grey.shade400, Colors.grey.shade500]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(perfilIcon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          usuario['nome'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isAtivo ? const Color(0xFF1F2937) : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isAtivo ? Colors.green : Colors.grey).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAtivo ? 'Ativo' : 'Inativo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAtivo ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.alternate_email_rounded, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(usuario['login'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: perfilColors[0].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          perfilLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: perfilColors[0]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Menu
            PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 12),
                    const Text('Editar'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(isAtivo ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                        size: 20, color: isAtivo ? Colors.orange : Colors.green),
                    const SizedBox(width: 12),
                    Text(isAtivo ? 'Desativar' : 'Ativar'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'deletar',
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text('Deletar', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
              onSelected: (v) {
                if (v == 'editar') onEditar();
                else if (v == 'toggle') onToggleAtivo();
                else if (v == 'deletar') onDeletar();
              },
            ),
          ],
        ),
      ),
    );
  }
}
