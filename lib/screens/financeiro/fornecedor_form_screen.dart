import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/financeiro/fornecedor_model.dart';
import '../../services/financeiro/fornecedor_service.dart';
import '../../services/auth_service.dart';

class FornecedorFormScreen extends StatefulWidget {
  final Fornecedor? fornecedor;

  const FornecedorFormScreen({super.key, this.fornecedor});

  @override
  State<FornecedorFormScreen> createState() => _FornecedorFormScreenState();
}

class _FornecedorFormScreenState extends State<FornecedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late FornecedorService _fornecedorService;
  
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool get _isEdicao => widget.fornecedor != null;

  @override
  void initState() {
    super.initState();
    _fornecedorService = FornecedorService(context.read<AuthService>());
    
    if (_isEdicao) {
      _nomeController.text = widget.fornecedor!.nome;
      _cnpjController.text = widget.fornecedor!.cnpj;
      _telefoneController.text = widget.fornecedor!.telefone ?? '';
      _enderecoController.text = widget.fornecedor!.endereco ?? '';
      _emailController.text = widget.fornecedor!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validarNome(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome/Razão Social é obrigatório';
    }
    if (value.length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  String? _validarCnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNPJ é obrigatório';
    }
    final numeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Email inválido';
      }
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEdicao) {
        // Atualizar fornecedor existente
        final dados = <String, dynamic>{};
        if (_nomeController.text != widget.fornecedor!.nome) {
          dados['nome'] = _nomeController.text;
        }
        if (_telefoneController.text != (widget.fornecedor!.telefone ?? '')) {
          dados['telefone'] = _telefoneController.text.isEmpty 
              ? null 
              : _telefoneController.text;
        }
        if (_enderecoController.text != (widget.fornecedor!.endereco ?? '')) {
          dados['endereco'] = _enderecoController.text.isEmpty 
              ? null 
              : _enderecoController.text;
        }
        if (_emailController.text != (widget.fornecedor!.email ?? '')) {
          dados['email'] = _emailController.text.isEmpty 
              ? null 
              : _emailController.text;
        }

        if (dados.isNotEmpty) {
          await _fornecedorService.atualizarFornecedor(widget.fornecedor!.id!, dados);
        }
      } else {
        // Criar novo fornecedor
        final fornecedor = Fornecedor(
          nome: _nomeController.text,
          cnpj: _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          telefone: _telefoneController.text.isEmpty ? null : _telefoneController.text,
          endereco: _enderecoController.text.isEmpty ? null : _enderecoController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
        );
        
        await _fornecedorService.criarFornecedor(fornecedor);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdicao 
                ? 'Fornecedor atualizado com sucesso' 
                : 'Fornecedor cadastrado com sucesso'),
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Fornecedor' : 'Novo Fornecedor'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome/Razão Social *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: _validarNome,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cnpjController,
              decoration: const InputDecoration(
                labelText: 'CNPJ * (Ex: 11.222.333/0001-81)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: '11.222.333/0001-81',
              ),
              validator: _validarCnpj,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
                _CnpjInputFormatter(),
              ],
              enabled: !_isEdicao, // CNPJ não pode ser alterado
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '(00) 00000-0000',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: _validarEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_isEdicao ? 'Atualizar' : 'Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}


// Formatador de CNPJ: 11.222.333/0001-81
class _CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();
    
    // Remove tudo que não é número
    final numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Aplica a máscara: 11.222.333/0001-81
    for (int i = 0; i < numbers.length && i < 14; i++) {
      if (i == 2 || i == 5) {
        buffer.write('.');
      } else if (i == 8) {
        buffer.write('/');
      } else if (i == 12) {
        buffer.write('-');
      }
      buffer.write(numbers[i]);
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
