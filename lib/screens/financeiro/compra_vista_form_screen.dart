import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/fornecedor_model.dart';
import '../../models/produto.dart';
import '../../services/financeiro/fornecedor_service.dart';
import '../../services/produto_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/financeiro_styles.dart';
import '../barcode_scanner_universal.dart';

/// Tela de compra à vista - similar à compra a prazo mas sem parcelas
class CompraVistaFormScreen extends StatefulWidget {
  const CompraVistaFormScreen({super.key});

  @override
  State<CompraVistaFormScreen> createState() => _CompraVistaFormScreenState();
}

class _CompraVistaFormScreenState extends State<CompraVistaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late FornecedorService _fornecedorService;
  late ProdutoService _produtoService;
  
  List<Fornecedor> _fornecedores = [];
  List<Produto> _produtos = [];
  Fornecedor? _fornecedorSelecionado;
  final List<_ItemCompra> _itensCompra = [];
  
  bool _isLoading = false;
  bool _isLoadingFornecedores = true;
  bool _isLoadingProdutos = true;
  
  String _formaPagamento = 'dinheiro';
  final _observacoesController = TextEditingController();
  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _fornecedorService = FornecedorService(authService);
    _produtoService = ProdutoService(authService);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await Future.wait([
      _carregarFornecedores(),
      _carregarProdutos(),
    ]);
  }

  Future<void> _carregarFornecedores() async {
    try {
      final fornecedores = await _fornecedorService.listarFornecedores();
      if (mounted) {
        setState(() {
          _fornecedores = fornecedores;
          _isLoadingFornecedores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFornecedores = false);
      }
    }
  }

  Future<void> _carregarProdutos() async {
    try {
      final produtos = await _produtoService.listarProdutos();
      if (mounted) {
        setState(() {
          _produtos = produtos;
          _isLoadingProdutos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProdutos = false);
      }
    }
  }

  void _adicionarProduto() {
    showDialog(
      context: context,
      builder: (context) => _DialogAdicionarProduto(
        produtos: _produtos,
        onAdicionar: (produto, quantidade, valorUnitario) {
          setState(() {
            _itensCompra.add(_ItemCompra(
              produto: produto,
              quantidade: quantidade,
              valorUnitario: valorUnitario,
            ));
          });
        },
      ),
    );
  }

  void _removerProduto(int index) {
    setState(() {
      _itensCompra.removeAt(index);
    });
  }

  double get _valorTotal {
    return _itensCompra.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_fornecedorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um fornecedor')),
      );
      return;
    }
    
    if (_itensCompra.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um produto')),
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
          int.parse(item.produto.id),
          'ENTRADA',
          item.quantidade.toDouble(),
          custoUnitario: item.valorUnitario,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra registrada com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FinanceiroStyles.appBar('Nova Compra à Vista', FinanceiroStyles.corCompra),
      body: _isLoadingFornecedores || _isLoadingProdutos
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // Fornecedor
                  DropdownButtonFormField<Fornecedor>(
                    value: _fornecedorSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Fornecedor *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: _fornecedores.map((fornecedor) {
                      return DropdownMenuItem(
                        value: fornecedor,
                        child: Text(fornecedor.nome),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _fornecedorSelecionado = value);
                    },
                    validator: (value) => value == null ? 'Selecione um fornecedor' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Forma de Pagamento
                  DropdownButtonFormField<String>(
                    value: _formaPagamento,
                    decoration: const InputDecoration(
                      labelText: 'Forma de Pagamento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'dinheiro', child: Text('💵 Dinheiro')),
                      DropdownMenuItem(value: 'pix', child: Text('📱 PIX')),
                      DropdownMenuItem(value: 'cartao_credito', child: Text('💳 Cartão de Crédito')),
                      DropdownMenuItem(value: 'cartao_debito', child: Text('💳 Cartão de Débito')),
                      DropdownMenuItem(value: 'boleto', child: Text('📄 Boleto')),
                      DropdownMenuItem(value: 'transferencia', child: Text('🏦 Transferência')),
                      DropdownMenuItem(value: 'cheque', child: Text('📝 Cheque')),
                      DropdownMenuItem(value: 'outro', child: Text('➕ Outro')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _formaPagamento = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Produtos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Produtos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                onPressed: _adicionarProduto,
                                icon: const Icon(FinanceiroStyles.iconeAdicionar, size: 18),
                                label: const Text('Adicionar', style: TextStyle(fontSize: 14)),
                                style: FinanceiroStyles.botaoComIcone(FinanceiroStyles.corCompra),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_itensCompra.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Nenhum produto adicionado', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            )
                          else
                            ..._itensCompra.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                title: Text(item.produto.nome, style: const TextStyle(fontSize: 14)),
                                subtitle: Text('${item.quantidade}x ${_formatoMoeda.format(item.valorUnitario)}', style: const TextStyle(fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_formatoMoeda.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _removerProduto(index),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const Divider(height: 16),
                          Text('Total: ${_formatoMoeda.format(_valorTotal)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Observações
                  TextField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  
                  // Botão Salvar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _salvar,
                    style: FinanceiroStyles.botaoPrimario(FinanceiroStyles.corCompra).copyWith(
                      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FinanceiroStyles.iconeSalvar, size: 20),
                              SizedBox(width: 8),
                              Text('Registrar Compra à Vista', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ItemCompra {
  final Produto produto;
  final int quantidade;
  final double valorUnitario;

  _ItemCompra({
    required this.produto,
    required this.quantidade,
    required this.valorUnitario,
  });

  double get subtotal => quantidade * valorUnitario;
}

class _DialogAdicionarProduto extends StatefulWidget {
  final List<Produto> produtos;
  final Function(Produto, int, double) onAdicionar;
  final Produto? produtoInicial;

  const _DialogAdicionarProduto({
    required this.produtos,
    required this.onAdicionar,
    this.produtoInicial,
  });

  @override
  State<_DialogAdicionarProduto> createState() => __DialogAdicionarProdutoState();
}

class __DialogAdicionarProdutoState extends State<_DialogAdicionarProduto> {
  Produto? _produtoSelecionado;
  final _quantidadeController = TextEditingController(text: '1');
  final _valorController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  String _filtroProduto = '';

  @override
  void initState() {
    super.initState();
    if (widget.produtoInicial != null) {
      _produtoSelecionado = widget.produtoInicial;
      _valorController.text = widget.produtoInicial!.preco.toStringAsFixed(2);
    }
  }

  Future<void> _cadastrarProdutoRapido(BuildContext dialogContext) async {
    final nomeController = TextEditingController();
    final unidadeController = TextEditingController(text: 'UN');
    final custoController = TextEditingController();
    final precoController = TextEditingController();
    final estoqueController = TextEditingController(text: '0');
    final codigoBarrasController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Cadastro Rápido de Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unidadeController,
                decoration: const InputDecoration(
                  labelText: 'Unidade *',
                  border: OutlineInputBorder(),
                  hintText: 'UN, KG, L, etc',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: custoController,
                decoration: const InputDecoration(
                  labelText: 'Custo *',
                  hintText: 'Ex: 5,50',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço de Venda *',
                  hintText: 'Ex: 8,00',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: estoqueController,
                decoration: const InputDecoration(
                  labelText: 'Estoque Inicial',
                  hintText: 'Ex: 10 ou 3,5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codigoBarrasController,
                decoration: const InputDecoration(
                  labelText: 'Código de Barras',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      if (nomeController.text.isEmpty || 
          unidadeController.text.isEmpty ||
          custoController.text.isEmpty ||
          precoController.text.isEmpty) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
        );
        return;
      }

      try {
        final authService = Provider.of<AuthService>(dialogContext, listen: false);
        final custo = double.tryParse(custoController.text.replaceAll(',', '.')) ?? 0;
        final preco = double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0;
        final estoque = double.tryParse(estoqueController.text) ?? 0;

        await ApiService.criarProduto(
          authService.token!,
          nomeController.text,
          unidadeController.text,
          custo,
          preco,
          estoque,
          codigoBarras: codigoBarrasController.text.isEmpty ? null : codigoBarrasController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text('✅ Produto cadastrado!'),
              backgroundColor: Colors.purple,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(dialogContext);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Erro ao cadastrar produto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtosFiltrados = widget.produtos
        .where((produto) => 
            _filtroProduto.isEmpty || 
            produto.nome.toLowerCase().contains(_filtroProduto))
        .toList();
    
    return AlertDialog(
      contentPadding: const EdgeInsets.all(12),
      title: const Text('Adicionar Produto', style: TextStyle(fontSize: 15)),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CAMPO DE PESQUISA
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Pesquisar produto...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (value) {
                      setState(() => _filtroProduto = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Cadastrar novo produto',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => _cadastrarProdutoRapido(context),
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // CAMPO DE CÓDIGO DE BARRAS
            TextField(
              controller: _codigoBarrasController,
              decoration: InputDecoration(
                hintText: 'Código de barras...',
                prefixIcon: const Icon(Icons.qr_code_scanner, size: 16),
                suffixIcon: _codigoBarrasController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _codigoBarrasController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final produtoEncontrado = widget.produtos.firstWhere(
                    (p) => p.codigoBarras == value,
                    orElse: () => widget.produtos.first,
                  );
                  
                  if (produtoEncontrado.codigoBarras == value) {
                    setState(() {
                      _produtoSelecionado = produtoEncontrado;
                      _valorController.text = produtoEncontrado.preco.toStringAsFixed(2);
                      _filtroProduto = '';
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            
            // LISTA DE PRODUTOS
            Expanded(
              child: produtosFiltrados.isEmpty
                  ? const Center(child: Text('Nenhum produto encontrado', style: TextStyle(fontSize: 12)))
                  : ListView.builder(
                      itemCount: produtosFiltrados.length,
                      itemBuilder: (context, index) {
                        final produto = produtosFiltrados[index];
                        final isSelected = _produtoSelecionado?.id == produto.id;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          color: isSelected ? Colors.purple.shade50 : null,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.inventory_2, color: Colors.white, size: 14),
                            ),
                            title: Text(
                              produto.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${produto.quantidade} UN',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'R\$ ${produto.preco.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.purple.shade900,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isSelected 
                                ? const Icon(Icons.check_circle, color: Colors.purple, size: 18)
                                : const Icon(Icons.arrow_forward_ios, size: 12),
                            onTap: () {
                              setState(() {
                                _produtoSelecionado = produto;
                                _valorController.text = produto.preco.toStringAsFixed(2);
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 8),
            
            // PRODUTO SELECIONADO
            if (_produtoSelecionado != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _produtoSelecionado!.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantidadeController,
                            decoration: const InputDecoration(
                              labelText: 'Quantidade *',
                              hintText: 'Ex: 10',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 14),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _valorController,
                            decoration: const InputDecoration(
                              labelText: 'Valor Unitário *',
                              hintText: 'Ex: 5,50',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 14),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
            if (_produtoSelecionado == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selecione um produto'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            
            final quantidade = int.tryParse(_quantidadeController.text) ?? 0;
            final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
            
            if (quantidade <= 0 || valor <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quantidade e valor devem ser maiores que zero'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            
            widget.onAdicionar(_produtoSelecionado!, quantidade, valor);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${_produtoSelecionado!.nome} adicionado!'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.purple,
              ),
            );
            
            setState(() {
              _produtoSelecionado = null;
              _quantidadeController.text = '1';
              _valorController.clear();
              _codigoBarrasController.clear();
              _filtroProduto = '';
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Adicionar Outro'),
        ),
      ],
    );
  }
}
