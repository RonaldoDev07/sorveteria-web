import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/financeiro/cliente_model.dart';
import '../../services/financeiro/cliente_service.dart';
import '../../services/auth_service.dart';
import '../../utils/input_formatters.dart';

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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEdicao ? 'Editar Cliente' : 'Novo Cliente',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Card de Informações Básicas
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Informações Básicas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo *',
                      hintText: 'Digite o nome do cliente',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF3B82F6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: _validarNome,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cpfCnpjController,
                    decoration: InputDecoration(
                      labelText: 'CPF/CNPJ *',
                      hintText: '000.000.000-00',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF3B82F6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                      filled: true,
                      fillColor: _isEdicao ? Colors.grey.shade200 : Colors.grey.shade50,
                    ),
                    validator: _validarCpfCnpj,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfCnpjInputFormatter()],
                    enabled: !_isEdicao,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Card de Contato
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.contact_phone, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Contato',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _telefoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefone',
                      hintText: '(00) 00000-0000',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneInputFormatter()],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'exemplo@email.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: _validarEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Card de Endereço
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on, color: Color(0xFF8B5CF6), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Endereço',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _enderecoController,
                    decoration: InputDecoration(
                      labelText: 'Endereço Completo',
                      hintText: 'Rua, número, bairro, cidade',
                      prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFF8B5CF6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Botão Salvar
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEdicao ? Icons.check_circle : Icons.add_circle, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _isEdicao ? 'Atualizar Cliente' : 'Cadastrar Cliente',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
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
