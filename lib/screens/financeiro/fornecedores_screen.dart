import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/financeiro/fornecedor_model.dart';
import '../../services/financeiro/fornecedor_service.dart';
import '../../services/auth_service.dart';
import 'fornecedor_form_screen.dart';

class FornecedoresScreen extends StatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  List<Fornecedor> _fornecedores = [];
  bool _isLoading = true;
  String? _errorMessage;
  FornecedorService? _fornecedorService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fornecedorService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _fornecedorService = FornecedorService(authService);
      _carregarFornecedores();
    }
  }

  Future<void> _carregarFornecedores() async {
    if (!mounted || _fornecedorService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fornecedores = await _fornecedorService!.listarFornecedores();
      
      if (!mounted) return;
      
      setState(() {
        _fornecedores = fornecedores;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletarFornecedor(Fornecedor fornecedor) async {
    if (_fornecedorService == null) return;
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o fornecedor ${fornecedor.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && fornecedor.id != null) {
      try {
        await _fornecedorService!.deletarFornecedor(fornecedor.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fornecedor excluído com sucesso')),
          );
          _carregarFornecedores();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir fornecedor: $e')),
          );
        }
      }
    }
  }

  void _abrirFormulario([Fornecedor? fornecedor]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FornecedorFormScreen(fornecedor: fornecedor),
      ),
    );

    if (resultado == true) {
      _carregarFornecedores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarFornecedores,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _fornecedores.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhum fornecedor cadastrado'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _abrirFormulario(),
                            icon: const Icon(Icons.add),
                            label: const Text('Cadastrar primeiro fornecedor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarFornecedores,
                      child: ListView.builder(
                        itemCount: _fornecedores.length,
                        itemBuilder: (context, index) {
                          final fornecedor = _fornecedores[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  fornecedor.nome[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                fornecedor.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CNPJ: ${fornecedor.cnpj}'),
                                  if (fornecedor.telefone != null)
                                    Text('Tel: ${fornecedor.telefone}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'excluir',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Excluir', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'editar') {
                                    _abrirFormulario(fornecedor);
                                  } else if (value == 'excluir') {
                                    _deletarFornecedor(fornecedor);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
