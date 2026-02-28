import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/parcela_model.dart';
import '../../services/financeiro/parcela_service.dart';
import '../../services/auth_service.dart';

class ParcelasScreen extends StatefulWidget {
  const ParcelasScreen({super.key});

  @override
  State<ParcelasScreen> createState() => _ParcelasScreenState();
}

class _ParcelasScreenState extends State<ParcelasScreen> {
  List<Parcela> _parcelas = [];
  bool _isLoading = true;
  String? _errorMessage;
  ParcelaService? _parcelaService;
  
  String? _filtroTipo;
  String? _filtroStatus;

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parcelaService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _parcelaService = ParcelaService(authService);
      _carregarParcelas();
    }
  }

  Future<void> _carregarParcelas() async {
    if (!mounted || _parcelaService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parcelas = await _parcelaService!.listarParcelas(
        tipo: _filtroTipo,
        status: _filtroStatus,
      );
      
      if (!mounted) return;
      
      setState(() {
        _parcelas = parcelas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _darBaixa(Parcela parcela) async {
    final valorController = TextEditingController(
      text: parcela.saldoRestante.toStringAsFixed(2),
    );
    String formaPagamento = 'pix';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dar Baixa na Parcela'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Parcela ${parcela.numeroParcela}'),
            Text('Saldo: ${_formatoMoeda.format(parcela.saldoRestante)}'),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor Pago',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: formaPagamento,
              decoration: const InputDecoration(
                labelText: 'Forma de Pagamento',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                DropdownMenuItem(value: 'pix', child: Text('PIX')),
                DropdownMenuItem(value: 'cartao_debito', child: Text('Cartão Débito')),
                DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão Crédito')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferência')),
              ],
              onChanged: (value) {
                if (value != null) formaPagamento = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      try {
        final valor = double.parse(valorController.text.replaceAll(',', '.'));
        await _parcelaService!.darBaixaParcela(parcela.id, valor, formaPagamento);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Baixa realizada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cancelarParcela(Parcela parcela) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta parcela?\n\n'
          '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}\n'
          'Valor: ${_formatoMoeda.format(parcela.valorParcela)}\n'
          'Status: ${_getStatusLabel(parcela.status)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _parcelaService!.cancelarParcela(parcela.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parcela cancelada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paga':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'parcialmente_paga':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paga':
        return 'Paga';
      case 'atrasada':
        return 'Atrasada';
      case 'parcialmente_paga':
        return 'Parcial';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcelas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'todas') {
                  _filtroTipo = null;
                  _filtroStatus = null;
                } else if (value == 'venda' || value == 'compra') {
                  _filtroTipo = value;
                } else {
                  _filtroStatus = value;
                }
              });
              _carregarParcelas();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'venda', child: Text('Vendas')),
              const PopupMenuItem(value: 'compra', child: Text('Compras')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
              const PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              const PopupMenuItem(value: 'paga', child: Text('Pagas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarParcelas,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _parcelas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma parcela encontrada'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarParcelas,
                      child: ListView.builder(
                        itemCount: _parcelas.length,
                        itemBuilder: (context, index) {
                          final parcela = _parcelas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(parcela.status),
                                child: Text(
                                  parcela.numeroParcela.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vencimento: ${_formatoData.format(parcela.dataVencimento)}'),
                                  Text('Valor: ${_formatoMoeda.format(parcela.valorParcela)}'),
                                  if (parcela.valorPago > 0)
                                    Text('Pago: ${_formatoMoeda.format(parcela.valorPago)}'),
                                  Text(
                                    'Status: ${_getStatusLabel(parcela.status)}',
                                    style: TextStyle(
                                      color: _getStatusColor(parcela.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (!parcela.estaPaga)
                                    const PopupMenuItem(
                                      value: 'baixa',
                                      child: Row(
                                        children: [
                                          Icon(Icons.payment, size: 20),
                                          SizedBox(width: 8),
                                          Text('Dar Baixa'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'cancelar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Cancelar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'baixa') {
                                    _darBaixa(parcela);
                                  } else if (value == 'cancelar') {
                                    _cancelarParcela(parcela);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
);$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parcelaService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _parcelaService = ParcelaService(authService);
      _carregarParcelas();
    }
  }

  Future<void> _carregarParcelas() async {
    if (!mounted || _parcelaService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parcelas = await _parcelaService!.listarParcelas(
        tipo: _filtroTipo,
        status: _filtroStatus,
      );
      
      if (!mounted) return;
      
      setState(() {
        _parcelas = parcelas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _darBaixa(Parcela parcela) async {
    final valorController = TextEditingController(
      text: parcela.saldoRestante.toStringAsFixed(2),
    );
    String formaPagamento = 'pix';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dar Baixa na Parcela'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Parcela ${parcela.numeroParcela}'),
            Text('Saldo: ${_formatoMoeda.format(parcela.saldoRestante)}'),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor Pago',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: formaPagamento,
              decoration: const InputDecoration(
                labelText: 'Forma de Pagamento',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                DropdownMenuItem(value: 'pix', child: Text('PIX')),
                DropdownMenuItem(value: 'cartao_debito', child: Text('Cartão Débito')),
                DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão Crédito')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferência')),
              ],
              onChanged: (value) {
                if (value != null) formaPagamento = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      try {
        final valor = double.parse(valorController.text.replaceAll(',', '.'));
        await _parcelaService!.darBaixaParcela(parcela.id, valor, formaPagamento);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Baixa realizada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cancelarParcela(Parcela parcela) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta parcela?\n\n'
          '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}\n'
          'Valor: ${_formatoMoeda.format(parcela.valorParcela)}\n'
          'Status: ${_getStatusLabel(parcela.status)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _parcelaService!.cancelarParcela(parcela.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parcela cancelada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paga':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'parcialmente_paga':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paga':
        return 'Paga';
      case 'atrasada':
        return 'Atrasada';
      case 'parcialmente_paga':
        return 'Parcial';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcelas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'todas') {
                  _filtroTipo = null;
                  _filtroStatus = null;
                } else if (value == 'venda' || value == 'compra') {
                  _filtroTipo = value;
                } else {
                  _filtroStatus = value;
                }
              });
              _carregarParcelas();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'venda', child: Text('Vendas')),
              const PopupMenuItem(value: 'compra', child: Text('Compras')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
              const PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              const PopupMenuItem(value: 'paga', child: Text('Pagas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarParcelas,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _parcelas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma parcela encontrada'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarParcelas,
                      child: ListView.builder(
                        itemCount: _parcelas.length,
                        itemBuilder: (context, index) {
                          final parcela = _parcelas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(parcela.status),
                                child: Text(
                                  parcela.numeroParcela.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vencimento: ${_formatoData.format(parcela.dataVencimento)}'),
                                  Text('Valor: ${_formatoMoeda.format(parcela.valorParcela)}'),
                                  if (parcela.valorPago > 0)
                                    Text('Pago: ${_formatoMoeda.format(parcela.valorPago)}'),
                                  Text(
                                    'Status: ${_getStatusLabel(parcela.status)}',
                                    style: TextStyle(
                                      color: _getStatusColor(parcela.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (!parcela.estaPaga)
                                    const PopupMenuItem(
                                      value: 'baixa',
                                      child: Row(
                                        children: [
                                          Icon(Icons.payment, size: 20),
                                          SizedBox(width: 8),
                                          Text('Dar Baixa'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'cancelar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Cancelar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'baixa') {
                                    _darBaixa(parcela);
                                  } else if (value == 'cancelar') {
                                    _cancelarParcela(parcela);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
);$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parcelaService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _parcelaService = ParcelaService(authService);
      _carregarParcelas();
    }
  }

  Future<void> _carregarParcelas() async {
    if (!mounted || _parcelaService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parcelas = await _parcelaService!.listarParcelas(
        tipo: _filtroTipo,
        status: _filtroStatus,
      );
      
      if (!mounted) return;
      
      setState(() {
        _parcelas = parcelas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _darBaixa(Parcela parcela) async {
    final valorController = TextEditingController(
      text: parcela.saldoRestante.toStringAsFixed(2),
    );
    String formaPagamento = 'pix';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dar Baixa na Parcela'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Parcela ${parcela.numeroParcela}'),
            Text('Saldo: ${_formatoMoeda.format(parcela.saldoRestante)}'),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor Pago',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: formaPagamento,
              decoration: const InputDecoration(
                labelText: 'Forma de Pagamento',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                DropdownMenuItem(value: 'pix', child: Text('PIX')),
                DropdownMenuItem(value: 'cartao_debito', child: Text('Cartão Débito')),
                DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão Crédito')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferência')),
              ],
              onChanged: (value) {
                if (value != null) formaPagamento = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      try {
        final valor = double.parse(valorController.text.replaceAll(',', '.'));
        await _parcelaService!.darBaixaParcela(parcela.id, valor, formaPagamento);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Baixa realizada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cancelarParcela(Parcela parcela) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta parcela?\n\n'
          '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}\n'
          'Valor: ${_formatoMoeda.format(parcela.valorParcela)}\n'
          'Status: ${_getStatusLabel(parcela.status)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _parcelaService!.cancelarParcela(parcela.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parcela cancelada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paga':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'parcialmente_paga':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paga':
        return 'Paga';
      case 'atrasada':
        return 'Atrasada';
      case 'parcialmente_paga':
        return 'Parcial';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcelas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'todas') {
                  _filtroTipo = null;
                  _filtroStatus = null;
                } else if (value == 'venda' || value == 'compra') {
                  _filtroTipo = value;
                } else {
                  _filtroStatus = value;
                }
              });
              _carregarParcelas();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'venda', child: Text('Vendas')),
              const PopupMenuItem(value: 'compra', child: Text('Compras')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
              const PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              const PopupMenuItem(value: 'paga', child: Text('Pagas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarParcelas,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _parcelas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma parcela encontrada'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarParcelas,
                      child: ListView.builder(
                        itemCount: _parcelas.length,
                        itemBuilder: (context, index) {
                          final parcela = _parcelas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(parcela.status),
                                child: Text(
                                  parcela.numeroParcela.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vencimento: ${_formatoData.format(parcela.dataVencimento)}'),
                                  Text('Valor: ${_formatoMoeda.format(parcela.valorParcela)}'),
                                  if (parcela.valorPago > 0)
                                    Text('Pago: ${_formatoMoeda.format(parcela.valorPago)}'),
                                  Text(
                                    'Status: ${_getStatusLabel(parcela.status)}',
                                    style: TextStyle(
                                      color: _getStatusColor(parcela.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (!parcela.estaPaga)
                                    const PopupMenuItem(
                                      value: 'baixa',
                                      child: Row(
                                        children: [
                                          Icon(Icons.payment, size: 20),
                                          SizedBox(width: 8),
                                          Text('Dar Baixa'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'cancelar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Cancelar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'baixa') {
                                    _darBaixa(parcela);
                                  } else if (value == 'cancelar') {
                                    _cancelarParcela(parcela);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
);$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parcelaService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _parcelaService = ParcelaService(authService);
      _carregarParcelas();
    }
  }

  Future<void> _carregarParcelas() async {
    if (!mounted || _parcelaService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parcelas = await _parcelaService!.listarParcelas(
        tipo: _filtroTipo,
        status: _filtroStatus,
      );
      
      if (!mounted) return;
      
      setState(() {
        _parcelas = parcelas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _darBaixa(Parcela parcela) async {
    final valorController = TextEditingController(
      text: parcela.saldoRestante.toStringAsFixed(2),
    );
    String formaPagamento = 'pix';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dar Baixa na Parcela'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Parcela ${parcela.numeroParcela}'),
            Text('Saldo: ${_formatoMoeda.format(parcela.saldoRestante)}'),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor Pago',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: formaPagamento,
              decoration: const InputDecoration(
                labelText: 'Forma de Pagamento',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                DropdownMenuItem(value: 'pix', child: Text('PIX')),
                DropdownMenuItem(value: 'cartao_debito', child: Text('Cartão Débito')),
                DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão Crédito')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferência')),
              ],
              onChanged: (value) {
                if (value != null) formaPagamento = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      try {
        final valor = double.parse(valorController.text.replaceAll(',', '.'));
        await _parcelaService!.darBaixaParcela(parcela.id, valor, formaPagamento);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Baixa realizada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cancelarParcela(Parcela parcela) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta parcela?\n\n'
          '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}\n'
          'Valor: ${_formatoMoeda.format(parcela.valorParcela)}\n'
          'Status: ${_getStatusLabel(parcela.status)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _parcelaService!.cancelarParcela(parcela.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parcela cancelada com sucesso')),
          );
          _carregarParcelas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paga':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'parcialmente_paga':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paga':
        return 'Paga';
      case 'atrasada':
        return 'Atrasada';
      case 'parcialmente_paga':
        return 'Parcial';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcelas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'todas') {
                  _filtroTipo = null;
                  _filtroStatus = null;
                } else if (value == 'venda' || value == 'compra') {
                  _filtroTipo = value;
                } else {
                  _filtroStatus = value;
                }
              });
              _carregarParcelas();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'venda', child: Text('Vendas')),
              const PopupMenuItem(value: 'compra', child: Text('Compras')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
              const PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              const PopupMenuItem(value: 'paga', child: Text('Pagas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarParcelas,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _parcelas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma parcela encontrada'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarParcelas,
                      child: ListView.builder(
                        itemCount: _parcelas.length,
                        itemBuilder: (context, index) {
                          final parcela = _parcelas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(parcela.status),
                                child: Text(
                                  parcela.numeroParcela.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vencimento: ${_formatoData.format(parcela.dataVencimento)}'),
                                  Text('Valor: ${_formatoMoeda.format(parcela.valorParcela)}'),
                                  if (parcela.valorPago > 0)
                                    Text('Pago: ${_formatoMoeda.format(parcela.valorPago)}'),
                                  Text(
                                    'Status: ${_getStatusLabel(parcela.status)}',
                                    style: TextStyle(
                                      color: _getStatusColor(parcela.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (!parcela.estaPaga)
                                    const PopupMenuItem(
                                      value: 'baixa',
                                      child: Row(
                                        children: [
                                          Icon(Icons.payment, size: 20),
                                          SizedBox(width: 8),
                                          Text('Dar Baixa'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'cancelar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Cancelar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'baixa') {
                                    _darBaixa(parcela);
                                  } else if (value == 'cancelar') {
                                    _cancelarParcela(parcela);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
