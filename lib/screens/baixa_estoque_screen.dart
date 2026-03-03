import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class BaixaEstoqueScreen extends StatefulWidget {
  final Map<String, dynamic> produto;

  const BaixaEstoqueScreen({super.key, required this.produto});

  @override
  State<BaixaEstoqueScreen> createState() => _BaixaEstoqueScreenState();
}

class _BaixaEstoqueScreenState extends State<BaixaEstoqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  final _valorPagoController = TextEditingController();
  bool _isLoading = false;
  String _formaPagamento = 'DINHEIRO'; // Forma de pagamento padrão

  @override
  void dispose() {
    _quantidadeController.dispose();
    _valorPagoController.dispose();
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

  Future<void> _handleBaixa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Converter vírgula para ponto
      final quantidadeStr = _quantidadeController.text.replaceAll(',', '.');
      
      await ApiService.registrarMovimentacao(
        auth.token!,
        widget.produto['id'],
        'SAIDA',
        double.parse(quantidadeStr),
        formaPagamento: _formaPagamento,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venda registrada com sucesso!'),
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
            content: Text('Erro ao registrar venda: $e'),
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
        title: const Text('Registrar Venda'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.produto['nome'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estoque atual: ${_formatarNumero(widget.produto['estoque_atual'])} ${widget.produto['unidade']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _quantidadeController,
                  decoration: InputDecoration(
                    labelText: 'Quantidade (Ex: 10)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Quantas unidades foram vendidas',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}), // Atualizar UI quando quantidade mudar
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
                const SizedBox(height: 20),
                // Seletor de forma de pagamento
                DropdownButtonFormField<String>(
                  value: _formaPagamento,
                  decoration: InputDecoration(
                    labelText: 'Forma de Pagamento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(
                      _formaPagamento == 'DINHEIRO' ? Icons.money_rounded :
                      _formaPagamento == 'PIX' ? Icons.pix_rounded :
                      _formaPagamento == 'DEBITO' ? Icons.credit_card_rounded :
                      Icons.credit_score_rounded,
                      color: Colors.green,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'DINHEIRO',
                      child: Text('💵 Dinheiro'),
                    ),
                    DropdownMenuItem(
                      value: 'PIX',
                      child: Text('📱 PIX'),
                    ),
                    DropdownMenuItem(
                      value: 'DEBITO',
                      child: Text('💳 Cartão Débito'),
                    ),
                    DropdownMenuItem(
                      value: 'CREDITO',
                      child: Text('💳 Cartão Crédito'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _formaPagamento = value!;
                    _valorPagoController.clear();
                  }),
                ),
                // Exibir valor total sempre que houver quantidade
                if (_quantidadeController.text.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Builder(
                    builder: (context) {
                      final quantidadeStr = _quantidadeController.text.replaceAll(',', '.');
                      final quantidade = double.tryParse(quantidadeStr) ?? 0;
                      final precoUnitario = double.parse(widget.produto['preco_venda'].toString());
                      final valorTotal = quantidade * precoUnitario;
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Valor Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                            Text(
                              'R\$ ${_formatarNumero(valorTotal)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                // Campo de valor pago e troco (apenas para dinheiro)
                if (_formaPagamento == 'DINHEIRO') ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _valorPagoController,
                    decoration: InputDecoration(
                      labelText: 'Valor Pago',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixText: 'R\$ ',
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                      helperText: 'Quanto o cliente pagou',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  // Exibir troco se valor pago foi informado
                  if (_valorPagoController.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final quantidadeStr = _quantidadeController.text.replaceAll(',', '.');
                        final quantidade = double.tryParse(quantidadeStr) ?? 0;
                        final precoUnitario = double.parse(widget.produto['preco_venda'].toString());
                        final valorTotal = quantidade * precoUnitario;
                        
                        final valorPagoStr = _valorPagoController.text.replaceAll(',', '.');
                        final valorPago = double.tryParse(valorPagoStr) ?? 0;
                        final troco = valorPago - valorTotal;
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: troco >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: troco >= 0 ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                troco >= 0 ? 'Troco:' : 'Falta:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: troco >= 0 ? Colors.green[900] : Colors.red[900],
                                ),
                              ),
                              Text(
                                'R\$ ${_formatarNumero(troco.abs())}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: troco >= 0 ? Colors.green[900] : Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleBaixa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
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
                            'Registrar Venda',
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
      ),
    );
  }
}
