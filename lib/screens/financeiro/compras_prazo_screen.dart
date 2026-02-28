import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../../services/financeiro/compra_prazo_service.dart';
import '../../services/auth_service.dart';
import 'compra_prazo_form_screen.dart';
import 'compra_detalhes_screen.dart';

class ComprasPrazoScreen extends StatefulWidget {
  const ComprasPrazoScreen({super.key});

  @override
  State<ComprasPrazoScreen> createState() => _ComprasPrazoScreenState();
}

class _ComprasPrazoScreenState extends State<ComprasPrazoScreen> {
  List<CompraPrazo> _compras = [];
  List<CompraPrazo> _comprasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  CompraPrazoService? _compraService;
  String? _filtroStatus = 'ativas'; // Filtro padrão: não mostrar canceladas
  final TextEditingController _searchController = TextEditingController();

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_compraService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _compraService = CompraPrazoService(authService);
      _carregarCompras();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarCompras(String query) {
    setState(() {
      if (query.isEmpty) {
        _comprasFiltradas = _compras;
      } else {
        _comprasFiltradas = _compras.where((compra) {
          final nomeFornecedor = compra.fornecedor?.nome.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nomeFornecedor.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _carregarCompras() async {
    if (!mounted || _compraService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Filtrar compras: se filtro for 'ativas', excluir canceladas no frontend
      final compras = await _compraService!.listarCompras(
        status: _filtroStatus == 'ativas' ? null : _filtroStatus
      );
      
      // Se filtro for 'ativas', remover canceladas
      final comprasFiltradas = _filtroStatus == 'ativas'
          ? compras.where((c) => c.status != 'cancelada').toList()
          : compras;
      
      if (!mounted) return;
      
      setState(() {
        _compras = comprasFiltradas;
        _comprasFiltradas = comprasFiltradas;
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

  Future<void> _cancelarCompra(CompraPrazo compra) async {
    if (_compraService == null) return;
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta compra?\n\n'
          'Fornecedor: ${compra.fornecedor?.nome}\n'
          'Valor: ${_formatoMoeda.format(compra.valorTotal)}\n\n'
          'O estoque será revertido.',
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
        await _compraService!.cancelarCompra(compra.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra cancelada com sucesso')),
          );
          _carregarCompras();
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

  void _abrirFormulario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompraPrazoFormScreen(),
      ),
    );

    if (resultado == true) {
      _carregarCompras();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'quitada':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras a Prazo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroStatus = value;
              });
              _carregarCompras();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ativas', child: Text('Ativas (padrão)')),
              const PopupMenuItem(value: null, child: Text('Todas')),
              const PopupMenuItem(value: 'em_dia', child: Text('Em Dia')),
              const PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              const PopupMenuItem(value: 'quitada', child: Text('Quitadas')),
              const PopupMenuItem(value: 'cancelada', child: Text('Canceladas')),
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
                        onPressed: _carregarCompras,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _compras.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhuma compra a prazo cadastrada'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _abrirFormulario,
                            icon: const Icon(Icons.add),
                            label: const Text('Nova Compra a Prazo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarCompras,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Pesquisar fornecedor...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: _filtrarCompras,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _comprasFiltradas.length,
                              itemBuilder: (context, index) {
                                final compra = _comprasFiltradas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompraDetalhesScreen(compra: compra),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(compra.status),
                                child: const Icon(Icons.shopping_bag, color: Colors.white),
                              ),
                              title: Text(
                                compra.fornecedor?.nome ?? 'Fornecedor',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data: ${_formatoData.format(compra.dataCompra)}'),
                                  Text('Total: ${_formatoMoeda.format(compra.valorTotal)}'),
                                  Text('Saldo: ${_formatoMoeda.format(compra.saldoDevedor)}'),
                                  Text(
                                    _getStatusLabel(compra.status),
                                    style: TextStyle(
                                      color: _getStatusColor(compra.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: !compra.estaCancelada
                                  ? PopupMenuButton(
                                      itemBuilder: (context) => [
                                        if (!compra.estaQuitada && !compra.estaCancelada)
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
                                        if (value == 'cancelar') {
                                          _cancelarCompra(compra);
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
);$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_compraService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _compraService = CompraPrazoService(authService);
      _carregarCompras();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarCompras(String query) {
    setState(() {
      if (query.isEmpty) {
        _comprasFiltradas = _compras;
      } else {
        _comprasFiltradas = _compras.where((compra) {
          final nomeFornecedor = compra.fornecedor?.nome.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nomeFornecedor.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _carregarCompras() async {
    if (!mounted || _compraService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Filtrar compras: se filtro for 'ativas', excluir canceladas no frontend
      final compras = await _compraService!.listarCompras(
        status: _filtroStatus == 'ativas' ? null : _filtroStatus
      );
      
      // Se filtro for 'ativas', remover canceladas
      final comprasFiltradas = _filtroStatus == 'ativas'
          ? compras.where((c) => c.status != 'cancelada').toList()
          : compras;
      
      if (!mounted) return;
      
      setState(() {
        _compras = comprasFiltradas;
        _comprasFiltradas = comprasFiltradas;
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

  Future<void> _cancelarCompra(CompraPrazo compra) async {
    if (_compraService == null) return;
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta compra?\n\n'
          'Fornecedor: ${compra.fornecedor?.nome}\n'
          'Valor: ${_formatoMoeda.format(compra.valorTotal)}\n\n'
          'O estoque será revertido.',
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
        await _compraService!.cancelarCompra(compra.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra cancelada com sucesso')),
          );
          _carregarCompras();
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

  void _abrirFormulario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompraPrazoFormScreen(),
      ),
    );

    if (resultado == true) {
      _carregarCompras();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'quitada':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras a Prazo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroStatus = value;
              });
              _carregarCompras();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ativas', child: Text('Ativas (padrão)')),
              const PopupMenuItem(value: null, child: Text('Todas')),
              const PopupMenuItem(value: 'em_dia', child: Text('Em Dia')),
              const PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              const PopupMenuItem(value: 'quitada', child: Text('Quitadas')),
              const PopupMenuItem(value: 'cancelada', child: Text('Canceladas')),
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
                        onPressed: _carregarCompras,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _compras.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhuma compra a prazo cadastrada'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _abrirFormulario,
                            icon: const Icon(Icons.add),
                            label: const Text('Nova Compra a Prazo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarCompras,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Pesquisar fornecedor...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: _filtrarCompras,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _comprasFiltradas.length,
                              itemBuilder: (context, index) {
                                final compra = _comprasFiltradas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompraDetalhesScreen(compra: compra),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(compra.status),
                                child: const Icon(Icons.shopping_bag, color: Colors.white),
                              ),
                              title: Text(
                                compra.fornecedor?.nome ?? 'Fornecedor',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data: ${_formatoData.format(compra.dataCompra)}'),
                                  Text('Total: ${_formatoMoeda.format(compra.valorTotal)}'),
                                  Text('Saldo: ${_formatoMoeda.format(compra.saldoDevedor)}'),
                                  Text(
                                    _getStatusLabel(compra.status),
                                    style: TextStyle(
                                      color: _getStatusColor(compra.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: !compra.estaCancelada
                                  ? PopupMenuButton(
                                      itemBuilder: (context) => [
                                        if (!compra.estaQuitada && !compra.estaCancelada)
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
                                        if (value == 'cancelar') {
                                          _cancelarCompra(compra);
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
