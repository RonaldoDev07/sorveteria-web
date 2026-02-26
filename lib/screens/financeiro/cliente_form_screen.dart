import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/financeiro/cliente_model.dart';
import '../../services/financeiro/cliente_service.dart';
import '../../services/auth_service.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ClienteService _clienteService;
  
  final _nomeController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool get _isEdicao => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _clienteService = ClienteService(context.read<AuthService>());
    
    if (_isEdicao) {
      _nomeController.text = widget.cliente!.nome;
      _cpfCnpjController.text = widget.cliente!.cpfCnpj;
      _telefoneController.text = widget.cliente!.telefone ?? '';
      _enderecoController.text = widget.cliente!.endereco ?? '';
      _emailController.text = widget.cliente!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfCnpjController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validarNome(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  String? _validarCpfCnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF/CNPJ é obrigatório';
    }
    final numeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length != 11 && numeros.length != 14) {
      return 'CPF deve ter 11 dígitos ou CNPJ 14 dígitos';
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
        // Atualizar cliente existente
        final dados = <String, dynamic>{};
        if (_nomeController.text != widget.cliente!.nome) {
          dados['nome'] = _nomeController.text;
        }
        if (_telefoneController.text != (widget.cliente!.telefone ?? '')) {
          dados['telefone'] = _telefoneController.text.isEmpty 
              ? null 
              : _telefoneController.text;
        }
        if (_enderecoController.text != (widget.cliente!.endereco ?? '')) {
          dados['endereco'] = _enderecoController.text.isEmpty 
              ? null 
              : _enderecoController.text;
        }
        if (_emailController.text != (widget.cliente!.email ?? '')) {
          dados['email'] = _emailController.text.isEmpty 
              ? null 
              : _emailController.text;
        }

        if (dados.isNotEmpty) {
          await _clienteService.atualizarCliente(widget.cliente!.id!, dados);
        }
      } else {
        // Criar novo cliente
        final cliente = Cliente(
          nome: _nomeController.text,
          cpfCnpj: _cpfCnpjController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          telefone: _telefoneController.text.isEmpty ? null : _telefoneController.text,
          endereco: _enderecoController.text.isEmpty ? null : _enderecoController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
        );
        
        await _clienteService.criarCliente(cliente);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdicao 
                ? 'Cliente atualizado com sucesso' 
                : 'Cliente cadastrado com sucesso'),
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
        title: Text(_isEdicao ? 'Editar Cliente' : 'Novo Cliente'),
        backgroundColor: Colors.blue,
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
                labelText: 'Nome *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: _validarNome,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cpfCnpjController,
              decoration: const InputDecoration(
                labelText: 'CPF/CNPJ * (Ex: 040.697.722-43 ou 11.222.333/0001-81)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: '040.697.722-43',
              ),
              validator: _validarCpfCnpj,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
                _CpfCnpjInputFormatter(),
              ],
              enabled: !_isEdicao, // CPF/CNPJ não pode ser alterado
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
                backgroundColor: Colors.blue,
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


// Formatador de CPF/CNPJ: 040.697.722-43 ou 11.222.333/0001-81
class _CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();
    
    // Remove tudo que não é número
    final numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbers.length <= 11) {
      // Formata como CPF: 040.697.722-43
      for (int i = 0; i < numbers.length && i < 11; i++) {
        if (i == 3 || i == 6) {
          buffer.write('.');
        } else if (i == 9) {
          buffer.write('-');
        }
        buffer.write(numbers[i]);
      }
    } else {
      // Formata como CNPJ: 11.222.333/0001-81
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
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
