import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class EntradaEstoqueScreen extends StatefulWidget {
  final Map<String, dynamic> produto;

  const EntradaEstoqueScreen({super.key, required this.produto});

  @override
  State<EntradaEstoqueScreen> createState() => _EntradaEstoqueScreenState();
}

class _EntradaEstoqueScreenState extends State<EntradaEstoqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  final _custoController = TextEditingController();
  DateTime _dataEntrada = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _custoController.dispose();
    super.dispose();
  }

  String _formatarNumero(dynamic valor) {
    if (valor == null) return '0';
    final numero = double.parse(valor.toString());
    // Se for número inteiro, não mostrar casas decimais
    if (numero == numero.toInt()) {
      return numero.toInt().toString();
    }
    // Senão, mostrar com até 3 casas decimais, removendo zeros à direita
    return numero.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  Future<void> _handleEntrada() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Validação adicional no frontend (backend também valida)
      if (!auth.canCadastrarProduto) {
        throw Exception('Apenas ADMIN ou VENDEDOR podem registrar entrada');
      }

      // Converter vírgulas para pontos
      final quantidadeStr = _quantidadeController.text.replaceAll(',', '.');
      final custoStr = _custoController.text.replaceAll(',', '.');

      await ApiService.registrarMovimentacao(
        auth.token!,
        widget.produto['id'],
        'ENTRADA',
        double.parse(quantidadeStr),
        custoUnitario: double.parse(custoStr),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrada registrada com sucesso!'),
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
            content: Text('Erro ao registrar entrada: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Registrar Compra',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card do Produto
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.teal.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.inventory_2, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.produto['nome'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Estoque: ${_formatarNumero(widget.produto['estoque_atual'])} ${widget.produto['unidade']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Card de Dados da Compra
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_cart, color: Color(0xFF14B8A6), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Dados da Compra',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Data de Entrada
                      InkWell(
                        onTap: () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate: _dataEntrada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            locale: const Locale('pt', 'BR'),
                          );
                          if (data != null) {
                            setState(() => _dataEntrada = data);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF14B8A6)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data de Entrada',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_dataEntrada),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Quantidade
                      TextFormField(
                        controller: _quantidadeController,
                        decoration: InputDecoration(
                          labelText: 'Quantidade',
                          hintText: 'Ex: 10',
                          prefixIcon: const Icon(Icons.add_shopping_cart, color: Color(0xFF14B8A6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          helperText: 'Quantas unidades você comprou',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        onTap: () {
                          if (_quantidadeController.text.isNotEmpty) {
                            _quantidadeController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _quantidadeController.text.length,
                            );
                          }
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Campo obrigatório';
                          final valorLimpo = value!.replaceAll(',', '.');
                          final quantidade = double.tryParse(valorLimpo);
                          if (quantidade == null || quantidade <= 0) {
                            return 'Quantidade inválida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Custo
                      TextFormField(
                        controller: _custoController,
                        decoration: InputDecoration(
                          labelText: 'Custo de Compra',
                          hintText: 'Ex: 5,50',
                          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF14B8A6)),
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          helperText: 'Quanto você PAGOU por unidade',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        onTap: () {
                          if (_custoController.text.isNotEmpty) {
                            _custoController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _custoController.text.length,
                            );
                          }
                        },
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botão Registrar
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14B8A6).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEntrada,
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
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Registrar Compra',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
}
