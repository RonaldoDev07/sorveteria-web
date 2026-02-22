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
          SnackBar(
            content: Text('Erro ao carregar usuários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAtivo(int usuarioId, String nome, bool ativoAtual) async {
    final acao = ativoAtual ? 'desativar' : 'ativar';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${acao[0].toUpperCase()}${acao.substring(1)} Usuário'),
        content: Text('Deseja realmente $acao o usuário "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ativoAtual ? Colors.orange : Colors.green,
            ),
            child: Text(acao[0].toUpperCase() + acao.substring(1)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await ApiService.toggleAtivoUsuario(auth.token!, usuarioId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário ${acao}do com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsuarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletarUsuario(int usuarioId, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Usuário'),
        content: Text(
          'Deseja realmente excluir o usuário "$nome"?\n\n'
          'Esta ação não poderá ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await ApiService.deletarUsuario(auth.token!, usuarioId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário deletado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsuarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsuarios,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _usuarios.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum usuário cadastrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _usuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = _usuarios[index];
                      final isAtivo = usuario['ativo'] == true;
                      final perfil = usuario['perfil'];
                      final isAdmin = perfil == 'ADMIN';
                      final isVendedor = perfil == 'VENDEDOR';

                      // Definir cor e ícone baseado no perfil
                      final perfilColor = isAdmin 
                          ? [Colors.deepPurple, Colors.purpleAccent]
                          : isVendedor
                              ? [Colors.green, Colors.greenAccent]
                              : [Colors.blue, Colors.blueAccent];
                      
                      final perfilIcon = isAdmin 
                          ? Icons.admin_panel_settings
                          : isVendedor
                              ? Icons.shopping_bag
                              : Icons.person;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isAtivo
                                  ? [Colors.white, Colors.grey.shade50]
                                  : [Colors.grey.shade200, Colors.grey.shade300],
                            ),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: perfilColor,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    perfilIcon,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        usuario['nome'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isAtivo ? Colors.black : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAtivo ? Colors.green : Colors.grey,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isAtivo ? 'ATIVO' : 'INATIVO',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.login, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Login: ${usuario['login']}',
                                            style: TextStyle(
                                              color: isAtivo ? Colors.grey[700] : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            perfilIcon,
                                            size: 16,
                                            color: isAdmin 
                                                ? Colors.amber 
                                                : isVendedor 
                                                    ? Colors.green 
                                                    : Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Perfil: ${usuario['perfil']}',
                                            style: TextStyle(
                                              color: isAtivo
                                                  ? (isAdmin 
                                                      ? Colors.deepPurple 
                                                      : isVendedor 
                                                          ? Colors.green 
                                                          : Colors.blue)
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          final resultado = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditarUsuarioScreen(usuario: usuario),
                                            ),
                                          );
                                          if (resultado == true) {
                                            _loadUsuarios();
                                          }
                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Editar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.grey.shade300,
                                    ),
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () => _toggleAtivo(
                                          usuario['id'],
                                          usuario['nome'],
                                          isAtivo,
                                        ),
                                        icon: Icon(
                                          isAtivo ? Icons.block : Icons.check_circle,
                                          size: 18,
                                        ),
                                        label: Text(isAtivo ? 'Desativar' : 'Ativar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isAtivo ? Colors.orange : Colors.green,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.grey.shade300,
                                    ),
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () => _deletarUsuario(
                                          usuario['id'],
                                          usuario['nome'],
                                        ),
                                        icon: const Icon(Icons.delete, size: 18),
                                        label: const Text('Deletar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CriarUsuarioScreen(),
            ),
          );
          if (resultado == true) {
            _loadUsuarios();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
