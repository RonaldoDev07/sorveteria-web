import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/text_formatters.dart';
import 'barcode_scanner_screen.dart';

class EntradaLoteScreen extends StatefulWidget {
  const EntradaLoteScreen({super.key});

  @override
  State<EntradaLoteScreen> createState() => _EntradaLoteScreenState();
}

class _EntradaLoteScreenState extends State<EntradaLoteScreen> {
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _itensCompra = [];
  bool _isLoading = false;
  bool _isLoadingProdutos = true;
  DateTime _dataEntrada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() => _isLoadingProdutos = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final produtos = await ApiService.getProdutos(auth.token!);
      if (mounted) {
        setState(() {
          _produtos = List<Map<String, dynamic>>.from(produtos);
          _isLoadingProdutos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProdutos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatarNumero(dynamic valor) {
    if (valor == null) return '0';
    final numero = double.parse(valor.toString());
    if (numero == numero.toInt()) {
      return numero.toInt().toString();
    }
    return numero.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  double _calcularTotal() {
    return _itensCompra.fold(0.0, (sum, item) {
      final quantidade = double.parse(item['quantidade'].toString());
      final custo = double.parse(item['custo_unitario'].toString());
      return sum + (quantidade * custo);
    });
  }

  Future<void> _abrirScanner() async {
    try {
      final codigo = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const BarcodeScannerScreen(),
          fullscreenDialog: true,
        ),
      );

      if (codigo != null && mounted) {
        await _buscarProdutoPorCodigo(codigo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao escanear: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _buscarProdutoPorCodigo(String codigo) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final produto = await ApiService.getProdutoPorCodigoBarras(auth.token!, codigo);
      
      if (mounted) {
        _mostrarDialogAdicionarProduto(produto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produto não encontrado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _mostrarDialogAdicionarProduto([Map<String, dynamic>? produtoSelecionado]) {
    final quantidadeController = TextEditingController();
    final custoController = TextEditingController();
    Map<String, dynamic>? produtoAtual = produtoSelecionado;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_shopping_cart, color: Color(0xFF14B8A6)),
              ),
              const SizedBox(width: 12),
              const Text('Adicionar Produto'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seletor de produto
                if (produtoAtual == null)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: InputDecoration(
                      labelText: 'Produto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.inventory_2),
                    ),
                    items: _produtos.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p['nome']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => produtoAtual = value);
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2, color: Color(0xFF14B8A6)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produtoAtual!['nome'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Estoque: ${_formatarNumero(produtoAtual!['estoque_atual'])} ${produtoAtual!['unidade']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setDialogState(() => produtoAtual = null);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Quantidade
                TextFormField(
                  controller: quantidadeController,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    hintText: 'Ex: 10',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.add_shopping_cart),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: produtoAtual != null,
                ),
                const SizedBox(height: 16),
                // Custo
                TextFormField(
                  controller: custoController,
                  decoration: InputDecoration(
                    labelText: 'Custo Unitário',
                    hintText: 'Ex: 5,50',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (produtoAtual == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecione um produto'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final quantidadeStr = quantidadeController.text.replaceAll(',', '.');
                final custoStr = custoController.text.replaceAll(',', '.');

                if (quantidadeStr.isEmpty || custoStr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha todos os campos'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final quantidade = double.tryParse(quantidadeStr);
                final custo = double.tryParse(custoStr);

                if (quantidade == null || quantidade <= 0 || custo == null || custo <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Valores inválidos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  _itensCompra.add({
                    'produto_id': produtoAtual!['id'],
                    'produto_nome': produtoAtual!['nome'],
                    'unidade': produtoAtual!['unidade'],
                    'quantidade': quantidade,
                    'custo_unitario': custo,
                  });
                });

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _removerItem(int index) {
    setState(() {
      _itensCompra.removeAt(index);
    });
  }

  Future<void> _finalizarCompra() async {
    if (_itensCompra.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um produto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // Registrar cada produto como entrada de estoque
      for (var item in _itensCompra) {
        await ApiService.registrarMovimentacao(
          auth.token!,
          item['produto_id'],
          'ENTRADA',
          item['quantidade'],
          custoUnitario: item['custo_unitario'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar compra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Entrada em Lote',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _abrirScanner,
            tooltip: 'Escanear código',
          ),
        ],
      ),
      body: _isLoadingProdutos
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header com data e total
                Container(
                  padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF14B8A6)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_dataEntrada),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total: ${formatarMoeda(_calcularTotal())}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14B8A6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${_itensCompra.length} ${_itensCompra.length == 1 ? 'item' : 'itens'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista de itens
                Expanded(
                  child: _itensCompra.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum produto adicionado',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toque no + para adicionar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _itensCompra.length,
                          itemBuilder: (context, index) {
                            final item = _itensCompra[index];
                            final subtotal = item['quantidade'] * item['custo_unitario'];

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
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14B8A6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Color(0xFF14B8A6),
                                  ),
                                ),
                                title: Text(
                                  item['produto_nome'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatarNumero(item['quantidade'])} ${item['unidade']} × ${formatarMoeda(item['custo_unitario'])}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subtotal: ${formatarMoeda(subtotal)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF14B8A6),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removerItem(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Botões de ação
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _mostrarDialogAdicionarProduto(),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Produto'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF14B8A6)),
                            foregroundColor: const Color(0xFF14B8A6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _finalizarCompra,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: const Text('Finalizar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF14B8A6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
