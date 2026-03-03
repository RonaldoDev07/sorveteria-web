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
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card do Produto
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produto['nome'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estoque atual: ${_formatarNumero(widget.produto['estoque_atual'])} ${widget.produto['unidade']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Quantidade
              TextFormField(
                controller: _quantidadeController,
                decoration: InputDecoration(
                  labelText: 'Quantidade (Ex: 10)',
                  hintText: 'Digite a quantidade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Quantas unidades foram vendidas',
                  prefixIcon: const Icon(Icons.shopping_cart, color: Color(0xFF10B981)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
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
              // Forma de Pagamento
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    _formaPagamento == 'DINHEIRO' ? Icons.money_rounded :
                    _formaPagamento == 'PIX' ? Icons.pix_rounded :
                    _formaPagamento == 'DEBITO' ? Icons.credit_card_rounded :
                    Icons.credit_score_rounded,
                    color: const Color(0xFF10B981),
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
              // Valor Total
              if (_quantidadeController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final quantidadeStr = _quantidadeController.text.replaceAll(',', '.');
                    final quantidade = double.tryParse(quantidadeStr) ?? 0;
                    final precoUnitario = double.parse(widget.produto['preco_venda'].toString());
                    final valorTotal = quantidade * precoUnitario;
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Valor Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            'R\$ ${_formatarNumero(valorTotal)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              // Campo de valor pago (apenas para dinheiro)
              if (_formaPagamento == 'DINHEIRO') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorPagoController,
                  decoration: InputDecoration(
                    labelText: 'Valor Pago',
                    hintText: 'Quanto o cliente pagou',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixText: 'R\$ ',
                    prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
                // Troco
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
                          color: troco >= 0 
                              ? const Color(0xFF10B981).withOpacity(0.1) 
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: troco >= 0 ? const Color(0xFF10B981) : Colors.red,
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
                                color: troco >= 0 ? const Color(0xFF10B981) : Colors.red,
                              ),
                            ),
                            Text(
                              'R\$ ${_formatarNumero(troco.abs())}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: troco >= 0 ? const Color(0xFF10B981) : Colors.red,
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
              // Botão
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleBaixa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                      : const Text(
                          'Registrar Venda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
