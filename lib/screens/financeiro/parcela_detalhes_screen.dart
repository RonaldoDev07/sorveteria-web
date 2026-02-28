import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/parcela_model.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../../services/financeiro/venda_prazo_service.dart';
import '../../services/financeiro/compra_prazo_service.dart';
import '../../services/financeiro/parcela_service.dart';
import '../../services/auth_service.dart';

// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class ParcelaDetalhesScreen extends StatefulWidget {
  final Parcela parcela;

  const ParcelaDetalhesScreen({super.key, required this.parcela});

  @override
  State<ParcelaDetalhesScreen> createState() => _ParcelaDetalhesScreenState();
}

class _ParcelaDetalhesScreenState extends State<ParcelaDetalhesScreen> {
  late Parcela _parcela;
  bool _isLoading = true;
  VendaPrazo? _venda;
  CompraPrazo? _compra;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _parcela = widget.parcela;
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // Verificar se é venda ou compra
      if (_parcela.tipo == 'VENDA' || _parcela.tipo == 'venda') {
        final service = VendaPrazoService(auth);
        final venda = await service.obterVenda(_parcela.referenciaId);
        setState(() {
          _venda = venda;
          _isLoading = false;
        });
      } else if (_parcela.tipo == 'COMPRA' || _parcela.tipo == 'compra') {
        final service = CompraPrazoService(auth);
        final compra = await service.obterCompra(_parcela.referenciaId);
        setState(() {
          _compra = compra;
          _isLoading = false;
        });
      } else {
        setState(() {
          _erro = 'Tipo de parcela desconhecido: ${_parcela.tipo}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar detalhes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _darBaixaParcela() async {
    if (_parcela.status == 'PAGA' || _parcela.status == 'paga') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parcela já está paga!')),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogDarBaixa(
        parcela: _parcela,
        onBaixa: (valorPago, formaPagamento) async {
          try {
            final auth = Provider.of<AuthService>(context, listen: false);
            final service = ParcelaService(auth);
            await service.darBaixaParcela(
              parcelaId: _parcela.id,
              valorPago: valorPago,
              formaPagamento: formaPagamento,
            );
            return true;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: $e')),
            );
            return false;
          }
        },
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baixa registrada com sucesso!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final formatoData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Parcela'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _carregarDetalhes,
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card de Informações da Parcela
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _parcela.tipo == 'VENDA' || _parcela.tipo == 'venda'
                                        ? Icons.shopping_cart
                                        : Icons.shopping_bag,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Parcela ${_parcela.numeroParcela}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildStatusChip(_parcela.status),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow('Tipo', _getTipoLabel(_parcela.tipo)),
                              _buildInfoRow('Vencimento', formatoData.format(_parcela.dataVencimento)),
                              _buildInfoRow('Valor da Parcela', formatoMoeda.format(_parcela.valorParcela)),
                              _buildInfoRow('Valor Pago', formatoMoeda.format(_parcela.valorPago), color: Colors.green),
                              _buildInfoRow(
                                'Saldo',
                                formatoMoeda.format(_parcela.valorParcela - _parcela.valorPago),
                                color: Colors.red,
                              ),

                              // Botão de dar baixa
                              if (_parcela.status != 'PAGA' && _parcela.status != 'paga' && 
                                  _parcela.status != 'CANCELADA' && _parcela.status != 'cancelada') ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _darBaixaParcela,
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Dar Baixa na Parcela'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Card de Informações do Cliente/Fornecedor
                      if (_venda != null || _compra != null) ...[
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      _venda != null ? 'Cliente' : 'Fornecedor',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Text(
                                  _venda?.cliente?.nome ?? _compra?.fornecedor?.nome ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (_venda?.cliente?.telefone != null || _compra?.fornecedor?.telefone != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        _venda?.cliente?.telefone ?? _compra?.fornecedor?.telefone ?? '',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Card de Produtos
                      if ((_venda?.produtos != null && _venda!.produtos!.isNotEmpty) ||
                          (_compra?.produtos != null && _compra!.produtos!.isNotEmpty)) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Produtos (${_venda?.produtos?.length ?? _compra?.produtos?.length ?? 0})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_venda?.produtos ?? _compra?.produtos ?? []).map((produto) {
                          try {
                            final produtoMap = produto as Map<String, dynamic>;
                            
                            final produtoId = produtoMap['produto_id']?.toString() ?? 
                                             produtoMap['produtoId']?.toString() ?? 
                                             'N/A';
                            
                            final quantidade = produtoMap['quantidade'] ?? 0;
                            
                            final valorUnitario = _toDouble(
                              produtoMap['valor_unitario'] ?? produtoMap['valorUnitario']
                            );
                            
                            final subtotal = _toDouble(produtoMap['subtotal']);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                                ),
                                title: Text('Produto #$produtoId'),
                                subtitle: Text(
                                  'Quantidade: $quantidade un.\n'
                                  'Valor unitário: ${formatoMoeda.format(valorUnitario)}',
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Subtotal',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      formatoMoeda.format(subtotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } catch (e) {
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.error, color: Colors.white, size: 20),
                                ),
                                title: const Text('Erro ao carregar produto'),
                                subtitle: Text('Detalhes: $e'),
                              ),
                            );
                          }
                        }),
                      ],

                      // Card de Resumo
                      if (_venda != null || _compra != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          margin: const EdgeInsets.all(16),
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resumo da Transação',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  'Valor Total',
                                  formatoMoeda.format(_venda?.valorTotal ?? _compra?.valorTotal ?? 0),
                                ),
                                _buildInfoRow(
                                  'Valor Pago',
                                  formatoMoeda.format(_venda?.valorPago ?? _compra?.valorPago ?? 0),
                                  color: Colors.green,
                                ),
                                _buildInfoRow(
                                  'Saldo Devedor',
                                  formatoMoeda.format(_venda?.saldoDevedor ?? _compra?.saldoDevedor ?? 0),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color cor;
    String label;

    switch (status.toUpperCase()) {
      case 'PAGA':
        cor = Colors.green;
        label = 'Paga';
        break;
      case 'PENDENTE':
        cor = Colors.orange;
        label = 'Pendente';
        break;
      case 'ATRASADA':
        cor = Colors.red;
        label = 'Atrasada';
        break;
      case 'CANCELADA':
        cor = Colors.grey;
        label = 'Cancelada';
        break;
      default:
        cor = Colors.blue;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: cor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  String _getTipoLabel(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'VENDA':
        return 'Venda a Prazo';
      case 'COMPRA':
        return 'Compra a Prazo';
      default:
        return tipo;
    }
  }
}

// Dialog para dar baixa na parcela
class _DialogDarBaixa extends StatefulWidget {
  final Parcela parcela;
  final Future<bool> Function(double valorPago, String formaPagamento) onBaixa;

  const _DialogDarBaixa({
    required this.parcela,
    required this.onBaixa,
  });

  @override
  State<_DialogDarBaixa> createState() => _DialogDarBaixaState();
}

class _DialogDarBaixaState extends State<_DialogDarBaixa> {
  final _valorController = TextEditingController();
  String _formaSelecionada = 'dinheiro';
  bool _isLoading = false;

  final List<Map<String, String>> _formasPagamento = [
    {'value': 'dinheiro', 'label': 'Dinheiro'},
    {'value': 'pix', 'label': 'PIX'},
    {'value': 'cartao_debito', 'label': 'Cartão de Débito'},
    {'value': 'cartao_credito', 'label': 'Cartão de Crédito'},
    {'value': 'transferencia', 'label': 'Transferência'},
  ];

  @override
  void initState() {
    super.initState();
    // Preencher com o valor restante da parcela
    final valorRestante = widget.parcela.valorParcela - widget.parcela.valorPago;
    _valorController.text = valorRestante.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um valor válido')),
      );
      return;
    }

    final valorRestante = widget.parcela.valorParcela - widget.parcela.valorPago;
    if (valor > valorRestante) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Valor não pode ser maior que o saldo da parcela (R\$ ${valorRestante.toStringAsFixed(2)})'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final sucesso = await widget.onBaixa(valor, _formaSelecionada);
    
    if (mounted) {
      if (sucesso) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final valorRestante = widget.parcela.valorParcela - widget.parcela.valorPago;

    return AlertDialog(
      title: const Text('Dar Baixa na Parcela'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcela ${widget.parcela.numeroParcela}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Valor da Parcela: ${formatoMoeda.format(widget.parcela.valorParcela)}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Valor Pago: ${formatoMoeda.format(widget.parcela.valorPago)}',
            style: const TextStyle(fontSize: 14, color: Colors.green),
          ),
          Text(
            'Saldo: ${formatoMoeda.format(valorRestante)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valorController,
            decoration: const InputDecoration(
              labelText: 'Valor do Pagamento',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _formaSelecionada,
            decoration: const InputDecoration(
              labelText: 'Forma de Pagamento',
              border: OutlineInputBorder(),
            ),
            items: _formasPagamento.map((forma) {
              return DropdownMenuItem(
                value: forma['value'],
                child: Text(forma['label']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _formaSelecionada = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
