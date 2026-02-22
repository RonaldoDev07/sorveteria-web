import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'entrada_estoque_screen.dart';
import 'baixa_estoque_screen.dart';

class SelecionarProdutoScreen extends StatefulWidget {
  final String tipo; // 'ENTRADA' ou 'SAIDA'

  const SelecionarProdutoScreen({super.key, required this.tipo});

  @override
  State<SelecionarProdutoScreen> createState() => _SelecionarProdutoScreenState();
}

class _SelecionarProdutoScreenState extends State<SelecionarProdutoScreen> {
  List<dynamic> _produtos = [];
  List<dynamic> _produtosFiltrados = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarProdutos(String query) {
    setState(() {
      if (query.isEmpty) {
        _produtosFiltrados = _produtos;
      } else {
        _produtosFiltrados = _produtos
            .where((produto) =>
                produto['nome'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _carregarProdutos() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final produtos = await ApiService.getProdutos(auth.token!);
      setState(() {
        _produtos = produtos;
        _produtosFiltrados = produtos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.tipo == 'ENTRADA' ? 'Selecionar Produto - Compra' : 'Selecionar Produto - Venda';
    final cor = widget.tipo == 'ENTRADA' ? const Color(0xFF14B8A6) : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.tipo == 'ENTRADA' 
                  ? [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)]
                  : [const Color(0xFF10B981), const Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarProdutos,
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body:
_isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filtrarProdutos,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar produto...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search_rounded, color: cor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _filtrarProdutos('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _produtosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum produto encontrado',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _produtosFiltrados.length,
                            itemBuilder: (context, index) {
                              final produto = _produtosFiltrados[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.tipo == 'ENTRADA'
                                    ? [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)]
                                    : [const Color(0xFF10B981), const Color(0xFF34D399)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            produto['nome'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Icon(Icons.inventory_rounded, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  'Estoque: ${_formatarNumero(produto['estoque_atual'])} ${produto['unidade']}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: cor,
                            size: 20,
                          ),
                          onTap: () async {
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => widget.tipo == 'ENTRADA'
                                    ? EntradaEstoqueScreen(produto: produto)
                                    : BaixaEstoqueScreen(produto: produto),
                              ),
                            );
                            
                            // Recarregar produtos após voltar da tela de movimentação
                            if (resultado == true || mounted) {
                              _carregarProdutos();
                            }
                          },
                        ),
                      );
                            },
                          ),
                  ),
                ],
              ),
    );
  }
}
