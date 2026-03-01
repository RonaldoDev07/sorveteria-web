import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/venda_prazo_model.dart';
import '../../services/financeiro/venda_prazo_service.dart';
import '../../services/auth_service.dart';
import 'venda_detalhes_screen.dart';

class VendasPrazoScreen extends StatefulWidget {
  const VendasPrazoScreen({super.key});

  @override
  State<VendasPrazoScreen> createState() => _VendasPrazoScreenState();
}

class _VendasPrazoScreenState extends State<VendasPrazoScreen> {
  List<VendaPrazo> _vendas = [];
  List<VendaPrazo> _vendasFiltradas = [];
  bool _isLoading = false;
  String _filtroStatus = 'todas';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarVendas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarVendas() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = VendaPrazoService(auth);
      final vendas = await service.listarVendas();
      setState(() {
        _vendas = vendas;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar vendas: $e')),
        );
      }
    }
  }

  void _aplicarFiltros() {
    List<VendaPrazo> resultado = _vendas;

    // Filtro por status
    if (_filtroStatus != 'todas') {
      resultado = resultado.where((v) => v.status == _filtroStatus).toList();
    }

    // Filtro por busca
    final busca = _searchController.text.toLowerCase();
    if (busca.isNotEmpty) {
      resultado = resultado.where((v) {
        final cliente = (v.cliente?.nome ?? '').toLowerCase();
        return cliente.contains(busca);
      }).toList();
    }

    setState(() => _vendasFiltradas = resultado);
  }

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final formatoData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas a Prazo'),
        backgroundColor: Colors.blue,
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
                    hintText: 'Buscar por cliente...',
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

          // Lista de vendas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vendasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma venda encontrada',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarVendas,
                        child: ListView.builder(
                          itemCount: _vendasFiltradas.length,
                          itemBuilder: (context, index) {
                            final venda = _vendasFiltradas[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(venda.status),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  venda.cliente?.nome ?? 'Cliente',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formatoData.format(venda.dataVenda)),
                                    Text(
                                      'Saldo: ${formatoMoeda.format(venda.saldoDevedor)}',
                                      style: TextStyle(
                                        color: venda.saldoDevedor > 0
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
                                      formatoMoeda.format(venda.valorTotal),
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
                                        color: _getStatusColor(venda.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusLabel(venda.status),
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
                                          VendaDetalhesScreen(venda: venda),
                                    ),
                                  );
                                  if (resultado == true) {
                                    _carregarVendas();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // Resumo
          if (_vendasFiltradas.isNotEmpty)
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
                    'Total: ${_vendasFiltradas.length} vendas',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatoMoeda.format(
                      _vendasFiltradas.fold<double>(
                        0,
                        (sum, v) => sum + v.valorTotal,
                      ),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
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
        selectedColor: Colors.blue,
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
}
