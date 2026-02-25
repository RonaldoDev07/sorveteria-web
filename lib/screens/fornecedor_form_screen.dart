import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/fornecedores_api_service.dart';
import '../models/fornecedor.dart';

class FornecedorFormScreen extends StatefulWidget {
  final Fornecedor? fornecedor;

  const FornecedorFormScreen({super.key, this.fornecedor});

  @override
  State<FornecedorFormScreen> createState() => _FornecedorFormScreenState();
}

class _FornecedorFormScreenState extends State<FornecedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _enderecoController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fornecedor != null) {
      _nomeController.text = widget.fornecedor!.nome;
      _cpfCnpjController.text = widget.fornecedor!.cpfCnpj;
      _telefoneController.text = widget.fornecedor!.telefone ?? '';
      _emailController.text = widget.fornecedor!.email ?? '';
      _enderecoController.text = widget.fornecedor!.endereco ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfCnpjController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final fornecedor = Fornecedor(
        id: widget.fornecedor?.id ?? 0,
        nome: _nomeController.text,
        cpfCnpj: _cpfCnpjController.text,
        telefone: _telefoneController.text.isEmpty ? null : _telefoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        endereco: _enderecoController.text.isEmpty ? null : _enderecoController.text,
        dataCadastro: DateTime.now(),
      );

      if (widget.fornecedor == null) {
        await FornecedoresApiService.criarFornecedor(auth.token!, fornecedor);
      } else {
        await FornecedoresApiService.atualizarFornecedor(
          auth.token!,
          widget.fornecedor!.id,
          fornecedor,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.fornecedor == null
                ? 'Fornecedor criado com sucesso'
                : 'Fornecedor atualizado com sucesso'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.fornecedor == null ? 'Novo Fornecedor' : 'Editar Fornecedor'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome',
                hintText: 'Nome do fornecedor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cpfCnpjController,
              decoration: InputDecoration(
                labelText: 'CPF/CNPJ',
                hintText: '00000000000 ou 00000000000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefoneController,
              decoration: InputDecoration(
                labelText: 'Telefone',
                hintText: '00000000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                hintText: 'email@exemplo.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _enderecoController,
              decoration: InputDecoration(
                labelText: 'Endereço',
                hintText: 'Endereço completo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.fornecedor == null ? 'Criar Fornecedor' : 'Salvar Alterações',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
