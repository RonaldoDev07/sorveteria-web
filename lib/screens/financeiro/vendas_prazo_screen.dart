import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../services/financeiro/venda_prazo_service.dart';
import '../../services/auth_service.dart';
import 'venda_prazo_form_screen.dart';

class VendasPrazoScreen extends StatefulWidget {
  const VendasPrazoScreen({super.key});

  @override
  State<VendasPrazoScreen> createState() => _VendasPrazoScreenState();
}

class _VendasPrazoScreenState extends State<VendasPrazoScreen> {
  List<VendaPrazo> _vendas = [];
  bool _isLoading = true;
  String? _errorMessage;
  VendaPrazoService? _vendaService;
  String? _filtroStatus = 'ativas'; // Filtro padrão: não mostrar canceladas

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vendaService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _vendaService = VendaPrazoService(authService);
      _carregarVendas();
    }
  }

  Future<void> _carregarVendas() async {
    if (!mounted || _vendaService == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Filtrar vendas: se filtro for 'ativas', excluir canceladas no frontend
      final vendas = await _vendaService!.listarVendas(
        status: _filtroStatus == 'ativas' ? null : _filtroStatus
      );
      
      // Se filtro for 'ativas', remover canceladas
      final vendasFiltradas = _filtroStatus == 'ativas'
          ? vendas.where((v) => v.status != 'cancelada').toList()
          : vendas;
      
      if (!mounted) return;
      
      setState(() {
        _vendas = vendasFiltradas;
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

  Future<void> _cancelarVenda(VendaPrazo venda) async {
    if (_vendaService == null) return;
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta venda?\n\n'
          'Cliente: ${venda.cliente?.nome}\n'
          'Valor: ${_formatoMoeda.format(venda.valorTotal)}\n\n'
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
        await _vendaService!.cancelarVenda(venda.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venda cancelada com sucesso')),
          );
          _carregarVendas();
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
        builder: (context) => const VendaPrazoFormScreen(),
      ),
    );

    if (resultado == true) {
      _carregarVendas();
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
        title: const Text('Vendas a Prazo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroStatus = value;
              });
              _carregarVendas();
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
                        onPressed: _carregarVendas,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _vendas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhuma venda a prazo cadastrada'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _abrirFormulario,
                            icon: const Icon(Icons.add),
                            label: const Text('Nova Venda a Prazo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarVendas,
                      child: ListView.builder(
                        itemCount: _vendas.length,
                        itemBuilder: (context, index) {
                          final venda = _vendas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(venda.status),
                                child: const Icon(Icons.shopping_cart, color: Colors.white),
                              ),
                              title: Text(
                                venda.cliente?.nome ?? 'Cliente',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data: ${_formatoData.format(venda.dataVenda)}'),
                                  Text('Total: ${_formatoMoeda.format(venda.valorTotal)}'),
                                  Text('Saldo: ${_formatoMoeda.format(venda.saldoDevedor)}'),
                                  Text(
                                    _getStatusLabel(venda.status),
                                    style: TextStyle(
                                      color: _getStatusColor(venda.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: !venda.estaCancelada
                                  ? PopupMenuButton(
                                      itemBuilder: (context) => [
                                        if (!venda.estaQuitada && !venda.estaCancelada)
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
                                          _cancelarVenda(venda);
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
