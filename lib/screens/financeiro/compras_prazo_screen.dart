import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../../services/financeiro/compra_prazo_service.dart';
import '../../services/auth_service.dart';
import 'compra_detalhes_screen.dart';

class ComprasPrazoScreen extends StatefulWidget {
  const ComprasPrazoScreen({super.key});

  @override
  State<ComprasPrazoScreen> createState() => _ComprasPrazoScreenState();
}

class _ComprasPrazoScreenState extends State<ComprasPrazoScreen> {
  List<CompraPrazo> _compras = [];
  List<CompraPrazo> _comprasFiltradas = [];
  bool _isLoading = false;
  String _filtroStatus = 'todas';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarCompras();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarCompras() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = CompraPrazoService(auth);
      final compras = await service.listarCompras();
      setState(() {
        _compras = compras;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar compras: $e')),
        );
      }
    }
  }

  void _aplicarFiltros() {
    List<CompraPrazo> resultado = _compras;

    // Filtro por status
    if (_filtroStatus != 'todas') {
      resultado = resultado.where((c) => c.status == _filtroStatus).toList();
    }

    // Filtro por busca
    final busca = _searchController.text.toLowerCase();
    if (busca.isNotEmpty) {
      resultado = resultado.where((c) {
        final fornecedor = (c.fornecedor?.nome ?? '').toLowerCase();
        return fornecedor.contains(busca);
      }).toList();
    }

    setState(() => _comprasFiltradas = resultado);
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final formatoData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras a Prazo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de busca e filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por fornecedor...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _aplicarFiltros();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => _aplicarFiltros(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('Todas', 'todas'),
                      _buildFiltroChip('Em Dia', 'em_dia'),
                      _buildFiltroChip('Atrasadas', 'atrasada'),
                      _buildFiltroChip('Quitadas', 'quitada'),
                      _buildFiltroChip('Canceladas', 'cancelada'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de compras
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comprasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma compra encontrada',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarCompras,
                        child: ListView.builder(
                          itemCount: _comprasFiltradas.length,
                          itemBuilder: (context, index) {
                            final compra = _comprasFiltradas[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(compra.status),
                                  child: const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  compra.fornecedor?.nome ?? 'Fornecedor',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formatoData.format(compra.dataCompra)),
                                    Text(
                                      'Saldo: ${formatoMoeda.format(compra.saldoDevedor)}',
                                      style: TextStyle(
                                        color: compra.saldoDevedor > 0
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatoMoeda.format(compra.valorTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(compra.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusLabel(compra.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final resultado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CompraDetalhesScreen(compra: compra),
                                    ),
                                  );
                                  if (resultado == true) {
                                    _carregarCompras();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // Resumo
          if (_comprasFiltradas.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${_comprasFiltradas.length} compras',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatoMoeda.format(
                      _comprasFiltradas.fold<double>(
                        0,
                        (sum, c) => sum + c.valorTotal,
                      ),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final isSelected = _filtroStatus == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroStatus = valor;
            _aplicarFiltros();
          });
        },
        selectedColor: Colors.purple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
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
        return Colors.purple;
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
}
