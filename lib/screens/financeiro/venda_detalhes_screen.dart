import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../models/financeiro/pagamento_model.dart';
import '../../services/financeiro/pagamento_service.dart';
import '../../services/financeiro/venda_prazo_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class VendaDetalhesScreen extends StatefulWidget {
  final VendaPrazo venda;

  const VendaDetalhesScreen({super.key, required this.venda});

  @override
  State<VendaDetalhesScreen> createState() => _VendaDetalhesScreenState();
}

class _VendaDetalhesScreenState extends State<VendaDetalhesScreen> {
  late VendaPrazo _venda;
  List<Pagamento> _pagamentos = [];
  bool _isLoadingPagamentos = false;

  @override
  void initState() {
    super.initState();
    _venda = widget.venda;
    _carregarPagamentos();
  }

  Future<void> _carregarPagamentos() async {
    setState(() => _isLoadingPagamentos = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PagamentoService(auth);
      final pagamentos = await service.listarPagamentosVenda(_venda.id);
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

  Future<void> _mostrarDialogCancelarVenda() async {
    if (_venda.status == 'cancelada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda já está cancelada!')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Venda'),
        content: const Text(
          'Tem certeza que deseja cancelar esta venda?\n\n'
          'Esta ação irá:\n'
          '• Reverter o estoque dos produtos\n'
          '• Cancelar todas as parcelas pendentes\n'
          '• Marcar a venda como cancelada\n\n'
          'Esta ação não pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final service = VendaPrazoService(auth);
        
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        await service.cancelarVenda(_venda.id);
        
        if (mounted) {
          Navigator.pop(context); // Fechar loading
          Navigator.pop(context, true); // Voltar para lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venda cancelada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Fechar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cancelar venda: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _mostrarDialogPagamento() async {
    if (_venda.saldoDevedor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda já está quitada!')),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogRegistrarPagamento(
        saldoDevedor: _venda.saldoDevedor,
        onPagamento: (valor, forma) async {
          try {
            final auth = Provider.of<AuthService>(context, listen: false);
            final service = PagamentoService(auth);
            await service.registrarPagamentoVenda(
              vendaId: _venda.id,
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
      // Atualizar valores localmente
      setState(() {
        _venda = VendaPrazo(
          id: _venda.id,
          clienteId: _venda.clienteId,
          cliente: _venda.cliente,
          usuarioId: _venda.usuarioId,
          dataVenda: _venda.dataVenda,
          valorTotal: _venda.valorTotal,
          valorPago: _venda.valorPago, // Será atualizado ao recarregar
          saldoDevedor: _venda.saldoDevedor, // Será atualizado ao recarregar
          status: _venda.status,
          observacoes: _venda.observacoes,
          createdAt: _venda.createdAt,
          updatedAt: _venda.updatedAt,
          produtos: _venda.produtos,
        );
      });
      
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Detalhes da Venda',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                        const Icon(Icons.person, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _venda.cliente?.nome ?? 'Cliente',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Data', formatoData.format(_venda.dataVenda)),
                    _buildInfoRow('Horário', formatoHora.format(_venda.dataVenda)),
                    _buildInfoRow('Status', _getStatusLabel(_venda.status)),
                    const Divider(height: 24),
                    _buildInfoRow('Valor Total', formatoMoeda.format(_venda.valorTotal)),
                    _buildInfoRow('Valor Pago', formatoMoeda.format(_venda.valorPago), color: Colors.green),
                    _buildInfoRow('Saldo Devedor', formatoMoeda.format(_venda.saldoDevedor), color: Colors.red),
                    
                    // Botões de ação
                    if (_venda.status != 'cancelada') ...[
                      const SizedBox(height: 16),
                      // Botão de registrar pagamento
                      if (_venda.saldoDevedor > 0) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _mostrarDialogPagamento,
                            icon: const Icon(Icons.payment),
                            label: const Text('Registrar Pagamento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Botão de cancelar venda (apenas ADMIN ou VENDEDOR)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _mostrarDialogCancelarVenda,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Cancelar Venda'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                    
                    if (_venda.observacoes != null && _venda.observacoes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'Observações:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_venda.observacoes!),
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
                    backgroundColor: Colors.green,
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

            // Card de Produtos com Histórico Detalhado
            if (_venda.produtos != null && _venda.produtos!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Histórico de Adições',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Verificar se tem histórico detalhado
              if (_venda.historicoDetalhado != null && _venda.historicoDetalhado!.isNotEmpty) ...[
                // Mostrar histórico agrupado por data/hora
                ..._venda.historicoDetalhado!.map((historico) {
                  final dataAdicao = DateTime.parse(historico['dataAdicao']).toLocal();
                  final usuarioNome = historico['usuarioNome'] ?? 'Usuário';
                  final valorAdicionado = _toDouble(historico['valorAdicionado']);
                  final produtos = historico['produtos'] as List<dynamic>? ?? [];
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho do histórico
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${formatoData.format(dataAdicao)} às ${formatoHora.format(dataAdicao)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Adicionado por: $usuarioNome',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  formatoMoeda.format(valorAdicionado),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Produtos deste histórico
                        ...produtos.map((produto) {
                          try {
                            final produtoMap = produto as Map<String, dynamic>;
                            final produtoNome = produtoMap['produtoNome']?.toString() ?? 'Produto';
                            final quantidade = produtoMap['quantidade'] ?? 0;
                            final valorUnitario = _toDouble(produtoMap['valorUnitario']);
                            final subtotal = _toDouble(produtoMap['subtotal']);
                            
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.shopping_bag, size: 20, color: Colors.green),
                              title: Text(
                                produtoNome,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'Quantidade: $quantidade un. • ${formatoMoeda.format(valorUnitario)}/un',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                formatoMoeda.format(subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          } catch (e) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.error, size: 20, color: Colors.red),
                              title: const Text('Erro ao carregar produto'),
                            );
                          }
                        }),
                        
                        if (historico['observacoes'] != null && historico['observacoes'].toString().isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    historico['observacoes'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ] else ...[
                // Fallback: mostrar produtos sem histórico (formato antigo)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Produtos (${_venda.produtos!.length})',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                ..._venda.produtos!.map((produto) {
                  try {
                    final produtoMap = produto as Map<String, dynamic>;
                    final produtoId = produtoMap['produto_id']?.toString() ?? 
                                     produtoMap['produtoId']?.toString() ?? 
                                     'N/A';
                    String produtoNome = produtoMap['produto_nome']?.toString() ?? 
                                        produtoMap['produtoNome']?.toString() ?? 
                                        'Produto (ID: $produtoId)';
                    final quantidade = produtoMap['quantidade'] ?? 0;
                    final valorUnitario = _toDouble(
                      produtoMap['valor_unitario'] ?? 
                      produtoMap['valorUnitario']
                    );
                    final subtotal = _toDouble(produtoMap['subtotal']);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          produtoNome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                                color: Colors.green,
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
            textInputAction: TextInputAction.done,
            autofocus: true,
            onTap: () {
              if (_valorController.text.isNotEmpty) {
                _valorController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _valorController.text.length,
                );
              }
            },
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
