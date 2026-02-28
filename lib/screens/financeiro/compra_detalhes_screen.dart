import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../../models/financeiro/pagamento_model.dart';
import '../../services/financeiro/pagamento_service.dart';
import '../../services/auth_service.dart';

class CompraDetalhesScreen extends StatefulWidget {
  final CompraPrazo compra;

  const CompraDetalhesScreen({super.key, required this.compra});

  @override
  State<CompraDetalhesScreen> createState() => _CompraDetalhesScreenState();
}

class _CompraDetalhesScreenState extends State<CompraDetalhesScreen> {
  late CompraPrazo _compra;
  List<Pagamento> _pagamentos = [];
  bool _isLoadingPagamentos = false;

  @override
  void initState() {
    super.initState();
    _compra = widget.compra;
    _carregarPagamentos();
  }

  Future<void> _carregarPagamentos() async {
    setState(() => _isLoadingPagamentos = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PagamentoService(auth);
      final pagamentos = await service.listarPagamentosCompra(_compra.id);
      setState(() {
        _pagamentos = pagamentos;
        _isLoadingPagamentos = false;
      });
    } catch (e) {
      setState(() => _isLoadingPagamentos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar pagamentos: $e')),
        );
      }
    }
  }

  Future<void> _mostrarDialogPagamento() async {
    if (_compra.saldoDevedor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra já está quitada!')),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogRegistrarPagamento(
        saldoDevedor: _compra.saldoDevedor,
        onPagamento: (valor, forma) async {
          try {
            final auth = Provider.of<AuthService>(context, listen: false);
            final service = PagamentoService(auth);
            await service.registrarPagamentoCompra(
              compraId: _compra.id,
              valorPago: valor,
              formaPagamento: forma,
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
      // Recarregar pagamentos
      await _carregarPagamentos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento registrado com sucesso!')),
        );
        // Voltar e sinalizar que houve mudança para recarregar a lista
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final formatoData = DateFormat('dd/MM/yyyy');
    final formatoHora = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Compra'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Informações Gerais
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _compra.fornecedor?.nome ?? 'Fornecedor',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Data', formatoData.format(_compra.dataCompra)),
                    _buildInfoRow('Horário', formatoHora.format(_compra.dataCompra)),
                    _buildInfoRow('Status', _getStatusLabel(_compra.status)),
                    const Divider(height: 24),
                    _buildInfoRow('Valor Total', formatoMoeda.format(_compra.valorTotal)),
                    _buildInfoRow('Valor Pago', formatoMoeda.format(_compra.valorPago), color: Colors.green),
                    _buildInfoRow('Saldo Devedor', formatoMoeda.format(_compra.saldoDevedor), color: Colors.red),
                    
                    // Botão de registrar pagamento
                    if (_compra.saldoDevedor > 0 && _compra.status != 'cancelada') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _mostrarDialogPagamento,
                          icon: const Icon(Icons.payment),
                          label: const Text('Registrar Pagamento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                    
                    if (_compra.observacoes != null && _compra.observacoes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'Observações:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_compra.observacoes!),
                    ],
                  ],
                ),
              ),
            ),

            // Card de Pagamentos
            if (_pagamentos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pagamentos Realizados (${_pagamentos.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._pagamentos.map((pagamento) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                  title: Text(formatoMoeda.format(pagamento.valorPago)),
                  subtitle: Text(
                    '${_getFormaPagamentoLabel(pagamento.formaPagamento)} - ${formatoData.format(pagamento.dataPagamento)}',
                  ),
                  trailing: Text(
                    formatoHora.format(pagamento.dataPagamento),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],

            // Card de Produtos
            if (_compra.produtos != null && _compra.produtos!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Produtos (${_compra.produtos!.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._compra.produtos!.map((produto) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.inventory, color: Colors.white, size: 20),
                  ),
                  title: Text('Produto ID: ${produto.produtoId}'),
                  subtitle: Text('${produto.quantidade}x ${formatoMoeda.format(produto.valorUnitario)}'),
                  trailing: Text(
                    formatoMoeda.format(produto.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )),
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'quitada':
        return 'Quitada';
      case 'atrasada':
        return 'Atrasada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Em Dia';
    }
  }

  String _getFormaPagamentoLabel(String forma) {
    switch (forma) {
      case 'dinheiro':
        return 'Dinheiro';
      case 'pix':
        return 'PIX';
      case 'cartao_debito':
        return 'Cartão de Débito';
      case 'cartao_credito':
        return 'Cartão de Crédito';
      case 'transferencia':
        return 'Transferência';
      default:
        return forma;
    }
  }
}

// Dialog para registrar pagamento
class _DialogRegistrarPagamento extends StatefulWidget {
  final double saldoDevedor;
  final Future<bool> Function(double valor, String forma) onPagamento;

  const _DialogRegistrarPagamento({
    required this.saldoDevedor,
    required this.onPagamento,
  });

  @override
  State<_DialogRegistrarPagamento> createState() => _DialogRegistrarPagamentoState();
}

class _DialogRegistrarPagamentoState extends State<_DialogRegistrarPagamento> {
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

    if (valor > widget.saldoDevedor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Valor não pode ser maior que o saldo devedor (R\$ ${widget.saldoDevedor.toStringAsFixed(2)})')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final sucesso = await widget.onPagamento(valor, _formaSelecionada);
    
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

    return AlertDialog(
      title: const Text('Registrar Pagamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Devedor: ${formatoMoeda.format(widget.saldoDevedor)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
            backgroundColor: Colors.purple,
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
