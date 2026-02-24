import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'barcode_scanner_screen.dart';

class CadastroProdutoScreen extends StatefulWidget {
  const CadastroProdutoScreen({super.key});

  @override
  State<CadastroProdutoScreen> createState() => _CadastroProdutoScreenState();
}

class _CadastroProdutoScreenState extends State<CadastroProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _custoController = TextEditingController();
  final _precoController = TextEditingController();
  final _estoqueController = TextEditingController();
  String _unidade = 'UN';
  bool _isLoading = false;
  DateTime? _dataValidade; // Data de validade (opcional)

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoBarrasController.dispose();
    _custoController.dispose();
    _precoController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }

  Future<void> _abrirScanner() async {
    try {
      final codigo = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const BarcodeScannerScreen(),
        ),
      );
      
      if (codigo != null && mounted) {
        setState(() {
          _codigoBarrasController.text = codigo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir scanner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Validação adicional no frontend (backend também valida)
      if (!auth.canCadastrarProduto) {
        throw Exception('Apenas ADMIN ou VENDEDOR podem cadastrar produtos');
      }

      // Converter vírgulas para pontos
      final custoStr = _custoController.text.replaceAll(',', '.');
      final precoStr = _precoController.text.replaceAll(',', '.');
      final estoqueStr = _estoqueController.text.replaceAll(',', '.');

      // Formatar data de validade se existir (formato: YYYY-MM-DD)
      String? dataValidadeStr;
      if (_dataValidade != null) {
        dataValidadeStr = '${_dataValidade!.year}-${_dataValidade!.month.toString().padLeft(2, '0')}-${_dataValidade!.day.toString().padLeft(2, '0')}';
      }

      await ApiService.criarProduto(
        auth.token!,
        _nomeController.text,
        _unidade,
        double.parse(custoStr),
        double.parse(precoStr),
        double.parse(estoqueStr),
        dataValidade: dataValidadeStr,
        codigoBarras: _codigoBarrasController.text.isEmpty ? null : _codigoBarrasController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Cadastrar Produto',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Produto',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              // Campo de código de barras com botão de scanner
              TextFormField(
                controller: _codigoBarrasController,
                decoration: InputDecoration(
                  labelText: 'Código de Barras (opcional)',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  hintText: 'Escanear ou digitar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF6366F1)),
                    onPressed: _abrirScanner,
                    tooltip: 'Escanear código de barras',
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _unidade,
                decoration: InputDecoration(
                  labelText: 'Unidade',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                items: const [
                  DropdownMenuItem(value: 'UN', child: Text('Unidade (UN)')),
                  DropdownMenuItem(value: 'KG', child: Text('Quilograma (KG)')),
                ],
                onChanged: (value) => setState(() => _unidade = value!),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _custoController,
                decoration: InputDecoration(
                  labelText: 'Custo de Compra',
                  hintText: 'Ex: 4,00',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  prefixText: 'R\$ ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  helperText: 'Quanto você pagou pela mercadoria',
                  helperStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                  final valorLimpo = value!.replaceAll(',', '.');
                  final custo = double.tryParse(valorLimpo);
                  if (custo == null || custo <= 0) {
                    return 'Custo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _precoController,
                decoration: InputDecoration(
                  labelText: 'Preço de Venda',
                  hintText: 'Ex: 6,00',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  prefixText: 'R\$ ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  helperText: 'Quanto você vai vender',
                  helperStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                  final valorLimpo = value!.replaceAll(',', '.');
                  final preco = double.tryParse(valorLimpo);
                  if (preco == null || preco <= 0) {
                    return 'Preço inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _estoqueController,
                decoration: InputDecoration(
                  labelText: 'Estoque Inicial',
                  hintText: 'Ex: 50',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                  final valorLimpo = value!.replaceAll(',', '.');
                  final estoque = double.tryParse(valorLimpo);
                  if (estoque == null || estoque < 0) {
                    return 'Estoque inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Campo de validade (opcional)
              InkWell(
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: _dataValidade ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 anos
                    locale: const Locale('pt', 'BR'),
                    helpText: 'Selecionar data de validade',
                    cancelText: 'Cancelar',
                    confirmText: 'OK',
                  );
                  if (data != null) {
                    setState(() => _dataValidade = data);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _dataValidade != null ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data de Validade (opcional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dataValidade != null
                                  ? '${_dataValidade!.day.toString().padLeft(2, '0')}/${_dataValidade!.month.toString().padLeft(2, '0')}/${_dataValidade!.year}'
                                  : 'Nenhuma data selecionada',
                              style: TextStyle(
                                fontSize: 16,
                                color: _dataValidade != null ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_dataValidade != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => setState(() => _dataValidade = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCadastro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Cadastrar Produto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
