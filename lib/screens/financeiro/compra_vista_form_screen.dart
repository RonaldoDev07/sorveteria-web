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
                padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Produtos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                onPressed: _adicionarProduto,
                                icon: const Icon(FinanceiroStyles.iconeAdicionar, size: 20),
                                label: const Text('Adicionar'),
                                style: FinanceiroStyles.botaoComIcone(FinanceiroStyles.corCompra),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_itensCompra.isEmpty)
                            const Text('Nenhum produto adicionado', style: TextStyle(color: Colors.grey))
                          else
                            ..._itensCompra.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return ListTile(
                                title: Text(item.produto.nome),
                                subtitle: Text('${item.quantidade}x ${_formatoMoeda.format(item.valorUnitario)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_formatoMoeda.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removerProduto(index),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const Divider(),
                          Text('Total: ${_formatoMoeda.format(_valorTotal)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Observações
                  TextField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  // Botão Salvar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _salvar,
                    style: FinanceiroStyles.botaoPrimario(FinanceiroStyles.corCompra).copyWith(
                      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FinanceiroStyles.iconeSalvar, size: 22),
                              SizedBox(width: 8),
                              Text('Registrar Compra à Vista', style: TextStyle(fontSize: 17)),
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

  const _DialogAdicionarProduto({
    required this.produtos,
    required this.onAdicionar,
  });

  @override
  State<_DialogAdicionarProduto> createState() => __DialogAdicionarProdutoState();
}

class __DialogAdicionarProdutoState extends State<_DialogAdicionarProduto> {
  Produto? _produtoSelecionado;
  final _quantidadeController = TextEditingController(text: '1');
  final _valorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Produto>(
              value: _produtoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Produto *',
                border: OutlineInputBorder(),
              ),
              items: widget.produtos.map((produto) {
                return DropdownMenuItem(
                  value: produto,
                  child: Text(produto.nome),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _produtoSelecionado = value;
                  if (value != null) {
                    _valorController.text = value.preco.toStringAsFixed(2);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantidadeController,
              decoration: const InputDecoration(
                labelText: 'Quantidade *',
                hintText: 'Ex: 10 ou 3,5',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorController,
              decoration: const InputDecoration(
                labelText: 'Valor Unitário *',
                hintText: 'Ex: 5,50',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
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
            if (_produtoSelecionado == null ||
                _quantidadeController.text.isEmpty ||
                _valorController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preencha todos os campos')),
              );
              return;
            }

            final quantidade = int.tryParse(_quantidadeController.text) ?? 0;
            final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;

            if (quantidade <= 0 || valor <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quantidade e valor devem ser maiores que zero')),
              );
              return;
            }

            widget.onAdicionar(_produtoSelecionado!, quantidade, valor);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
