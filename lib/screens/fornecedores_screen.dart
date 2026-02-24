import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/fornecedores_api_service.dart';
import '../models/fornecedor.dart';

class FornecedoresScreen extends StatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  List<Fornecedor> _fornecedores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarFornecedores();
  }

  Future<void> _carregarFornecedores() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final fornecedores = await FornecedoresApiService.getFornecedores(auth.token!);
      setState(() {
        _fornecedores = fornecedores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fornecedores.isEmpty
              ? const Center(child: Text('Nenhum fornecedor cadastrado'))
              : RefreshIndicator(
                  onRefresh: _carregarFornecedores,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fornecedores.length,
                    itemBuilder: (context, index) {
                      final fornecedor = _fornecedores[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFF59E0B),
                            child: Text(
                              fornecedor.nome.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(fornecedor.nome),
                          subtitle: Text(fornecedor.cpfCnpj),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
