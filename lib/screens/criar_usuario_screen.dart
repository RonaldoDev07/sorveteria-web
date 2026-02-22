import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class CriarUsuarioScreen extends StatefulWidget {
  const CriarUsuarioScreen({super.key});

  @override
  State<CriarUsuarioScreen> createState() => _CriarUsuarioScreenState();
}

class _CriarUsuarioScreenState extends State<CriarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  String _perfil = 'OPERADOR';
  bool _isLoading = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _handleCriar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      await ApiService.criarUsuario(
        auth.token!,
        _nomeController.text,
        _loginController.text.toLowerCase(),
        _senhaController.text,
        _perfil,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário criado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: const Text('Criar Novo Usuário'),
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.deepPurple, Colors.purpleAccent],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Dados do Usuário',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            labelText: 'Nome Completo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _loginController,
                          decoration: InputDecoration(
                            labelText: 'Login (usuário)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.login),
                            filled: true,
                            fillColor: Colors.white,
                            helperText: 'Será convertido para minúsculas',
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo obrigatório';
                            if (value!.length < 3) return 'Mínimo 3 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: !_mostrarSenha,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _mostrarSenha = !_mostrarSenha);
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo obrigatório';
                            if (value!.length < 4) return 'Mínimo 4 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _perfil,
                          decoration: InputDecoration(
                            labelText: 'Perfil',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.badge),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                                  SizedBox(width: 8),
                                  Text('ADMIN (pode fazer tudo)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'VENDEDOR',
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_bag, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('VENDEDOR (cadastra e vende)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'OPERADOR',
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('OPERADOR (só vende e consulta)'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _perfil = value!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Permissões',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_perfil == 'ADMIN') ...[
                          _buildPermissao('✓ Cadastrar produtos', Colors.green),
                          _buildPermissao('✓ Registrar compras', Colors.green),
                          _buildPermissao('✓ Registrar vendas', Colors.green),
                          _buildPermissao('✓ Editar produtos', Colors.green),
                          _buildPermissao('✓ Cancelar movimentações', Colors.green),
                          _buildPermissao('✓ Ver relatórios', Colors.green),
                          _buildPermissao('✓ Gerenciar usuários', Colors.green),
                        ] else ...[
                          _buildPermissao('✓ Registrar vendas', Colors.green),
                          _buildPermissao('✓ Ver produtos', Colors.green),
                          _buildPermissao('✓ Ver relatórios', Colors.green),
                          _buildPermissao('✗ Cadastrar produtos', Colors.red),
                          _buildPermissao('✗ Registrar compras', Colors.red),
                          _buildPermissao('✗ Editar produtos', Colors.red),
                          _buildPermissao('✗ Cancelar movimentações', Colors.red),
                          _buildPermissao('✗ Gerenciar usuários', Colors.red),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleCriar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: const Text(
                      'Criar Usuário',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissao(String texto, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: 13,
        ),
      ),
    );
  }
}
