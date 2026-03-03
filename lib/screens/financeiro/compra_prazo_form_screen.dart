import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/financeiro/fornecedor_model.dart';
import '../../models/produto.dart';
import '../../services/financeiro/fornecedor_service.dart';
import '../../services/financeiro/compra_prazo_service.dart';
import '../../services/produto_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/financeiro_styles.dart';

class CompraPrazoFormScreen extends StatefulWidget {
  const CompraPrazoFormScreen({super.key});

  @override
  State<CompraPrazoFormScreen> createState() => _CompraPrazoFormScreenState();
}

class _CompraPrazoFormScreenState extends State<CompraPrazoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late FornecedorService _fornecedorService;
  late ProdutoService _produtoService;
  late CompraPrazoService _compraService;
  
  List<Fornecedor> _fornecedores = [];
  List<Produto> _produtos = [];
  Fornecedor? _fornecedorSelecionado;
  final List<_ItemCompra> _itensCompra = [];
  final List<_Parcela> _parcelas = [];
  
  bool _isLoading = false;
  bool _isLoadingFornecedores = true;
  bool _isLoadingProdutos = true;
  
  String _filtroProduto = '';
  final _observacoesController = TextEditingController();
  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _fornecedorService = FornecedorService(authService);
    _produtoService = ProdutoService(authService);
    _compraService = CompraPrazoService(authService);
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
      print('🔍 Carregando produtos para compra...');
      final produtos = await _produtoService.listarProdutos();
      print('✅ ${produtos.length} produtos carregados da API');
      
      if (mounted) {
        setState(() {
          _produtos = produtos;
          _isLoadingProdutos = false;
        });
        print('📦 ${_produtos.length} produtos disponíveis no dropdown');
        
        // Listar os produtos para debug
        if (_produtos.isNotEmpty) {
          print('📋 Produtos carregados:');
          for (var p in _produtos.take(5)) {
            print('   - ${p.nome} (ID: ${p.id}, Estoque: ${p.quantidade})');
          }
          if (_produtos.length > 5) {
            print('   ... e mais ${_produtos.length - 5} produtos');
          }
        } else {
          print('⚠️ AVISO: Lista de produtos está vazia!');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar produtos: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingProdutos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
        onProdutoCadastrado: () async {
          // Recarregar lista de produtos após cadastro
          await _carregarProdutos();
        },
      ),
    );
  }

  void _removerProduto(int index) {
    setState(() {
      _itensCompra.removeAt(index);
    });
  }

  Future<void> _cadastrarFornecedorRapido() async {
    final nomeController = TextEditingController();
    final cnpjController = TextEditingController();
    final telefoneController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cadastrar Fornecedor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cnpjController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
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
      if (nomeController.text.isEmpty || cnpjController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha nome e CNPJ')),
        );
        return;
      }

      try {
        final novoFornecedor = Fornecedor(
          nome: nomeController.text,
          cnpj: cnpjController.text,
          telefone: telefoneController.text.isEmpty ? null : telefoneController.text,
        );
        await _fornecedorService.criarFornecedor(novoFornecedor);

        // Recarregar lista de fornecedores
        await _carregarFornecedores();

        // Selecionar o fornecedor recém-criado
        final fornecedorCriado = _fornecedores.firstWhere(
          (f) => f.cnpj == cnpjController.text,
          orElse: () => _fornecedores.last,
        );
        setState(() => _fornecedorSelecionado = fornecedorCriado);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fornecedor cadastrado com sucesso')),
          );
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

  double get _valorTotal {
    return _itensCompra.fold(0, (sum, item) => sum + item.subtotal);
  }

  void _gerarParcelas() {
    if (_valorTotal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione produtos antes de gerar parcelas')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _DialogGerarParcelas(
        valorTotal: _valorTotal,
        onGerar: (parcelas) {
          setState(() {
            _parcelas.clear();
            _parcelas.addAll(parcelas);
          });
        },
      ),
    );
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
    
    if (_parcelas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere as parcelas')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _compraService.criarCompra(
        fornecedorId: _fornecedorSelecionado!.id!,
        produtos: _itensCompra.map((item) => {
          'produtoId': item.produto.id,
          'quantidade': item.quantidade,
          'valorUnitario': item.valorUnitario,
        }).toList(),
        parcelas: _parcelas.map((p) => {
          'numeroParcela': p.numero,
          'valorParcela': p.valor,
          'dataVencimento': p.dataVencimento.toIso8601String().split('T')[0],
        }).toList(),
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra criada com sucesso')),
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

  Future<void> _abrirScanner() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              AppBar(
                title: const Text('Escanear Código de Barras'),
                automaticallyImplyLeading: false,
                backgroundColor: FinanceiroStyles.corCompra,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null) {
                        Navigator.pop(context);
                        _buscarProdutoPorCodigo(code);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buscarProdutoPorCodigo(String codigo) {
    final produto = _produtos.firstWhere(
      (p) => p.codigoBarras == codigo,
      orElse: () => _produtos.first,
    );

    if (produto.codigoBarras == codigo) {
      // Produto encontrado, abrir dialog de adicionar com produto pré-selecionado
      showDialog(
        context: context,
        builder: (context) => _DialogAdicionarProduto(
          produtos: _produtos,
          produtoInicial: produto,
          onAdicionar: (produto, quantidade, valorUnitario) {
            setState(() {
              _itensCompra.add(_ItemCompra(
                produto: produto,
                quantidade: quantidade,
                valorUnitario: valorUnitario,
              ));
            });
          },
          onProdutoCadastrado: () async {
            await _carregarProdutos();
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produto com código $codigo não encontrado'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FinanceiroStyles.appBar('Nova Compra a Prazo', FinanceiroStyles.corCompra),
      body: _isLoadingFornecedores || _isLoadingProdutos
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Fornecedor>(
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
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _cadastrarFornecedorRapido,
                        icon: const Icon(Icons.add_circle, color: Colors.purple, size: 32),
                        tooltip: 'Cadastrar novo fornecedor',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
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
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Parcelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                onPressed: _gerarParcelas,
                                icon: const Icon(Icons.calculate, size: 18),
                                label: const Text('Gerar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_parcelas.isEmpty)
                            const Text('Nenhuma parcela gerada', style: TextStyle(color: Colors.grey))
                          else
                            ..._parcelas.map((parcela) {
                              return ListTile(
                                title: Text('Parcela ${parcela.numero}'),
                                subtitle: Text('Vencimento: ${DateFormat('dd/MM/yyyy').format(parcela.dataVencimento)}'),
                                trailing: Text(_formatoMoeda.format(parcela.valor), style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
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
                              Text('Criar Compra a Prazo', style: TextStyle(fontSize: 17)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirScanner,
        backgroundColor: FinanceiroStyles.corCompra,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear'),
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

class _Parcela {
  final int numero;
  final double valor;
  final DateTime dataVencimento;

  _Parcela({
    required this.numero,
    required this.valor,
    required this.dataVencimento,
  });
}

// Reutilizar os mesmos dialogs da venda
class _DialogAdicionarProduto extends StatefulWidget {
  final List<Produto> produtos;
  final Function(Produto, int, double) onAdicionar;
  final Future<void> Function()? onProdutoCadastrado;
  final Produto? produtoInicial;

  const _DialogAdicionarProduto({
    required this.produtos,
    required this.onAdicionar,
    this.onProdutoCadastrado,
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
    print('🔍 Dialog Adicionar Produto (Compras) iniciado');
    print('   Produtos recebidos: ${widget.produtos.length}');
    
    // Se foi passado um produto inicial, selecionar automaticamente
    if (widget.produtoInicial != null) {
      _produtoSelecionado = widget.produtoInicial;
      _valorController.text = widget.produtoInicial!.preco.toStringAsFixed(2);
      print('   ✅ Produto pré-selecionado: ${widget.produtoInicial!.nome}');
    }
    
    if (widget.produtos.isNotEmpty) {
      print('   Exemplo: ${widget.produtos.first.nome}');
    } else {
      print('   ⚠️ AVISO: Lista de produtos vazia no dialog!');
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
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço de Venda *',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: estoqueController,
                decoration: const InputDecoration(
                  labelText: 'Estoque Inicial',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
          // Recarregar a lista de produtos
          if (widget.onProdutoCadastrado != null) {
            await widget.onProdutoCadastrado!();
          }
          
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text('✅ Produto cadastrado! Atualizando lista...'),
              backgroundColor: Colors.purple,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Fechar e reabrir o dialog para mostrar o produto novo
          Navigator.pop(dialogContext);
          
          // Aguardar um pouco para garantir que a lista foi atualizada
          await Future.delayed(const Duration(milliseconds: 300));
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
      title: const Text('Adicionar Produto'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
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
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() => _filtroProduto = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Cadastrar novo produto',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => _cadastrarProdutoRapido(context),
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // CAMPO DE CÓDIGO DE BARRAS COM BOTÃO SCANNER
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoBarrasController,
                    decoration: InputDecoration(
                      hintText: 'Código de barras...',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      suffixIcon: _codigoBarrasController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _codigoBarrasController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        // Buscar produto por código de barras
                        final produtoEncontrado = widget.produtos.firstWhere(
                          (p) => p.codigoBarras == value,
                          orElse: () => widget.produtos.first, // Fallback
                        );
                        
                        if (produtoEncontrado.codigoBarras == value) {
                          setState(() {
                            _produtoSelecionado = produtoEncontrado;
                            _valorController.text = produtoEncontrado.preco.toStringAsFixed(2);
                            _filtroProduto = ''; // Limpar filtro de nome
                          });
                        }
                      }
                    },
                    onSubmitted: (value) {
                      if (_produtoSelecionado != null && _produtoSelecionado!.codigoBarras == value) {
                        // Focar no campo de quantidade
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Escanear código de barras',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        // Abrir scanner
                        final codigo = await showDialog<String>(
                          context: context,
                          builder: (context) => Dialog(
                            child: SizedBox(
                              width: 400,
                              height: 500,
                              child: Column(
                                children: [
                                  AppBar(
                                    title: const Text('Escanear Código'),
                                    automaticallyImplyLeading: false,
                                    backgroundColor: Colors.purple,
                                    actions: [
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: MobileScanner(
                                      onDetect: (capture) {
                                        final List<Barcode> barcodes = capture.barcodes;
                                        if (barcodes.isNotEmpty) {
                                          final String? code = barcodes.first.rawValue;
                                          if (code != null) {
                                            Navigator.pop(context, code);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        
                        if (codigo != null) {
                          _codigoBarrasController.text = codigo;
                          // Buscar produto
                          final produtoEncontrado = widget.produtos.firstWhere(
                            (p) => p.codigoBarras == codigo,
                            orElse: () => widget.produtos.first,
                          );
                          
                          if (produtoEncontrado.codigoBarras == codigo) {
                            setState(() {
                              _produtoSelecionado = produtoEncontrado;
                              _valorController.text = produtoEncontrado.preco.toStringAsFixed(2);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // LISTA DE PRODUTOS
            Expanded(
              child: produtosFiltrados.isEmpty
                  ? const Center(child: Text('Nenhum produto encontrado'))
                  : ListView.builder(
                      itemCount: produtosFiltrados.length,
                      itemBuilder: (context, index) {
                        final produto = produtosFiltrados[index];
                        final isSelected = _produtoSelecionado?.id == produto.id;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? Colors.purple.shade50 : null,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              produto.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${produto.quantidade} UN',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'R\$ ${produto.preco.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.purple.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isSelected 
                                ? const Icon(Icons.check_circle, color: Colors.purple)
                                : const Icon(Icons.arrow_forward_ios, size: 16),
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
            
            const SizedBox(height: 16),
            
            // PRODUTO SELECIONADO
            if (_produtoSelecionado != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecionado: ${_produtoSelecionado!.nome}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantidadeController,
                            decoration: const InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _valorController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
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
          child: const Text('Concluir'),
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
            
            // Adicionar produto
            widget.onAdicionar(_produtoSelecionado!, quantidade, valor);
            
            // Mostrar feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${_produtoSelecionado!.nome} adicionado!'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.purple,
              ),
            );
            
            // Limpar campos para adicionar próximo produto
            setState(() {
              _produtoSelecionado = null;
              _quantidadeController.text = '1';
              _valorController.clear();
              _codigoBarrasController.clear();
              _filtroProduto = '';
            });
            
            // NÃO fechar o dialog - continua aberto para adicionar mais produtos
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

class _DialogGerarParcelas extends StatefulWidget {
  final double valorTotal;
  final Function(List<_Parcela>) onGerar;

  const _DialogGerarParcelas({
    required this.valorTotal,
    required this.onGerar,
  });

  @override
  State<_DialogGerarParcelas> createState() => __DialogGerarParcelasState();
}

class __DialogGerarParcelasState extends State<_DialogGerarParcelas> {
  final _numeroParcelasController = TextEditingController(text: '1');
  DateTime _dataPrimeiraParcela = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerar Parcelas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Valor Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(widget.valorTotal)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _numeroParcelasController,
            decoration: const InputDecoration(
              labelText: 'Número de Parcelas',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Data da 1ª Parcela'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataPrimeiraParcela)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final data = await showDatePicker(
                context: context,
                initialDate: _dataPrimeiraParcela,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (data != null) {
                setState(() => _dataPrimeiraParcela = data);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final numeroParcelas = int.tryParse(_numeroParcelasController.text) ?? 0;
            if (numeroParcelas <= 0) return;
            
            final valorParcela = widget.valorTotal / numeroParcelas;
            final parcelas = <_Parcela>[];
            
            for (int i = 0; i < numeroParcelas; i++) {
              final valor = i == numeroParcelas - 1
                  ? widget.valorTotal - (valorParcela * (numeroParcelas - 1))
                  : valorParcela;
              
              parcelas.add(_Parcela(
                numero: i + 1,
                valor: double.parse(valor.toStringAsFixed(2)),
                dataVencimento: _dataPrimeiraParcela.add(Duration(days: i * 30)),
              ));
            }
            
            widget.onGerar(parcelas);
            Navigator.pop(context);
          },
          child: const Text('Gerar'),
        ),
      ],
    );
  }
}
