import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class CarrinhoVendaScreen extends StatefulWidget {
  const CarrinhoVendaScreen({super.key});

  @override
  State<CarrinhoVendaScreen> createState() => _CarrinhoVendaScreenState();
}

class _CarrinhoVendaScreenState extends State<CarrinhoVendaScreen> {
  List<dynamic> _produtos = [];
  List<dynamic> _produtosFiltrados = [];
  List<Map<String, dynamic>> _carrinho = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatarNumero(dynamic valor) {
    if (valor == null) return '0';
    final numero = double.parse(valor.toString());
    if (numero == numero.toInt()) {
      return numero.toInt().toString();
    }
    return numero.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  double _calcularTotal() {
    double total = 0;
    for (var item in _carrinho) {
      final preco = double.parse(item['produto']['preco_venda'].toString());
      final quantidade = item['quantidade'];
      total += preco * quantidade;
    }
    return total;
  }

  void _filtrarProdutos(String query) {
    setState(() {
      if (query.isEmpty) {
        _produtosFiltrados = _produtos.where((p) {
          final estoque = p['estoque_atual'];
          final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString()) ?? 0);
          return estoqueNum > 0;
        }).toList();
      } else {
        _produtosFiltrados = _produtos
            .where((produto) {
              final estoque = produto['estoque_atual'];
              final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString()) ?? 0);
              return estoqueNum > 0 && produto['nome'].toLowerCase().contains(query.toLowerCase());
            })
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
        _produtosFiltrados = produtos.where((p) {
          final estoque = p['estoque_atual'];
          final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString()) ?? 0);
          return estoqueNum > 0;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _adicionarAoCarrinho(dynamic produto) {
    final estoqueAtual = double.parse(produto['estoque_atual'].toString());
    
    // Verificar se já está no carrinho
    final index = _carrinho.indexWhere((item) => item['produto']['id'] == produto['id']);
    
    if (index >= 0) {
      // Já está no carrinho, aumentar quantidade
      final quantidadeAtual = _carrinho[index]['quantidade'];
      if (quantidadeAtual < estoqueAtual) {
        setState(() {
          _carrinho[index]['quantidade']++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${produto['nome']} - quantidade aumentada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estoque insuficiente de ${produto['nome']}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Adicionar novo item
      setState(() {
        _carrinho.add({
          'produto': produto,
          'quantidade': 1.0,
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${produto['nome']} adicionado ao carrinho'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _removerDoCarrinho(int index) {
    setState(() {
      _carrinho.removeAt(index);
    });
  }

  void _alterarQuantidade(int index, double novaQuantidade) {
    final produto = _carrinho[index]['produto'];
    final estoqueAtual = double.parse(produto['estoque_atual'].toString());
    
    if (novaQuantidade <= 0) {
      _removerDoCarrinho(index);
    } else if (novaQuantidade <= estoqueAtual) {
      setState(() {
        _carrinho[index]['quantidade'] = novaQuantidade;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estoque insuficiente. Disponível: ${_formatarNumero(estoqueAtual)}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _finalizarVenda() async {
    if (_carrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carrinho vazio! Adicione produtos antes de finalizar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Finalizar Venda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total de itens: ${_carrinho.length}'),
            const SizedBox(height: 8),
            Text(
              'Valor total: R\$ ${_formatarNumero(_calcularTotal())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text('Confirma a venda?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Venda'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Registrar cada item do carrinho
      for (var item in _carrinho) {
        final produto = item['produto'];
        final quantidade = item['quantidade'];
        final precoUnitario = double.parse(produto['preco_venda'].toString());
        
        await ApiService.criarMovimentacao(
          auth.token!,
          produto['id'],
          -quantidade, // Negativo para saída
          precoUnitario,
          'SAIDA',
          'Venda via carrinho',
        );
      }

      if (mounted) {
        setState(() {
          _carrinho.clear();
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venda finalizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        _carregarProdutos(); // Atualizar estoque
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar venda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Carrinho de Venda',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        actions: [
          if (_carrinho.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_carrinho.length}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Carrinho (parte superior)
                if (_carrinho.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              const Text(
                                'Itens no Carrinho',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() => _carrinho.clear());
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Limpar'),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _carrinho.length,
                            itemBuilder: (context, index) {
                              final item = _carrinho[index];
                              final produto = item['produto'];
                              final quantidade = item['quantidade'];
                              final preco = double.parse(produto['preco_venda'].toString());
                              final subtotal = preco * quantidade;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF10B981).withOpacity(0.05),
                                      Colors.white,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              produto['nome'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'R\$ ${_formatarNumero(preco)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '× ${_formatarNumero(quantidade)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            'R\$ ${_formatarNumero(subtotal)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.remove, size: 16),
                                                  onPressed: () => _alterarQuantidade(index, quantidade - 1),
                                                  color: Colors.red,
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.add, size: 16),
                                                  onPressed: () => _alterarQuantidade(index, quantidade + 1),
                                                  color: const Color(0xFF10B981),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Lista de produtos
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filtrarProdutos,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar produto...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                
                Expanded(
                  child: _produtosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum produto disponível',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _produtosFiltrados.length,
                          itemBuilder: (context, index) {
                            final produto = _produtosFiltrados[index];
                            final estoque = double.parse(produto['estoque_atual'].toString());
                            final preco = double.parse(produto['preco_venda'].toString());
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _adicionarAoCarrinho(produto),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF10B981).withOpacity(0.2),
                                                const Color(0xFF34D399).withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2,
                                            color: Color(0xFF10B981),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                produto['nome'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: estoque < 10
                                                          ? Colors.orange.withOpacity(0.1)
                                                          : Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.inventory,
                                                          size: 14,
                                                          color: estoque < 10
                                                              ? Colors.orange
                                                              : Colors.blue,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${_formatarNumero(estoque)} ${produto['unidade']}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: estoque < 10
                                                                ? Colors.orange
                                                                : Colors.blue,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'R\$ ${_formatarNumero(preco)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF10B981),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _carrinho.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'R\$ ${_formatarNumero(_calcularTotal())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _finalizarVenda,
                        icon: const Icon(Icons.check_circle, size: 24),
                        label: const Text(
                          'Finalizar Venda',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
