import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/cliente_model.dart';
import '../../models/produto.dart';
import '../../services/financeiro/cliente_service.dart';
import '../../services/financeiro/venda_prazo_service.dart';
import '../../services/produto_service.dart';
import '../../services/auth_service.dart';

class VendaPrazoFormScreen extends StatefulWidget {
  const VendaPrazoFormScreen({super.key});

  @override
  State<VendaPrazoFormScreen> createState() => _VendaPrazoFormScreenState();
}

class _VendaPrazoFormScreenState extends State<VendaPrazoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ClienteService _clienteService;
  late ProdutoService _produtoService;
  late VendaPrazoService _vendaService;
  
  List<Cliente> _clientes = [];
  List<Produto> _produtos = [];
  Cliente? _clienteSelecionado;
  final List<_ItemVenda> _itensVenda = [];
  final List<_Parcela> _parcelas = [];
  
  bool _isLoading = false;
  bool _isLoadingClientes = true;
  bool _isLoadingProdutos = true;
  
  final _observacoesController = TextEditingController();
  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _clienteService = ClienteService(authService);
    _produtoService = ProdutoService(authService);
    _vendaService = VendaPrazoService(authService);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await Future.wait([
      _carregarClientes(),
      _carregarProdutos(),
    ]);
  }

  Future<void> _carregarClientes() async {
    try {
      print('🔍 Carregando clientes...');
      final clientes = await _clienteService.listarClientes();
      print('✅ ${clientes.length} clientes carregados');
      
      if (mounted) {
        setState(() {
          _clientes = clientes;
          _isLoadingClientes = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar clientes: $e');
      if (mounted) {
        setState(() => _isLoadingClientes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _carregarProdutos() async {
    try {
      print('🔍 Carregando produtos para venda...');
      final produtos = await _produtoService.listarProdutos();
      print('✅ ${produtos.length} produtos carregados');
      
      if (mounted) {
        setState(() {
          // Remover filtro de quantidade para debug - mostrar todos os produtos
          _produtos = produtos; // .where((p) => p.quantidade > 0).toList();
          _isLoadingProdutos = false;
        });
        print('📦 ${_produtos.length} produtos disponíveis no dropdown');
      }
    } catch (e) {
      print('❌ Erro ao carregar produtos: $e');
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

  void _adicionarProduto() {
    showDialog(
      context: context,
      builder: (context) => _DialogAdicionarProduto(
        produtos: _produtos,
        onAdicionar: (produto, quantidade, valorUnitario) {
          setState(() {
            _itensVenda.add(_ItemVenda(
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
      _itensVenda.removeAt(index);
    });
  }

  double get _valorTotal {
    return _itensVenda.fold(0, (sum, item) => sum + item.subtotal);
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
    
    if (_clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente')),
      );
      return;
    }
    
    if (_itensVenda.isEmpty) {
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
      await _vendaService.criarVenda(
        clienteId: _clienteSelecionado!.id!,
        produtos: _itensVenda.map((item) => {
          'produto_id': item.produto.id,
          'quantidade': item.quantidade,
          'valor_unitario': item.valorUnitario,
        }).toList(),
        parcelas: _parcelas.map((p) => {
          'numero_parcela': p.numero,
          'valor_parcela': p.valor,
          'data_vencimento': p.dataVencimento.toIso8601String().split('T')[0],
        }).toList(),
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda criada com sucesso')),
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
      appBar: AppBar(
        title: const Text('Nova Venda a Prazo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingClientes || _isLoadingProdutos
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cliente
                  DropdownButtonFormField<Cliente>(
                    value: _clienteSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Cliente *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _clientes.map((cliente) {
                      return DropdownMenuItem(
                        value: cliente,
                        child: Text(cliente.nome),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _clienteSelecionado = value);
                    },
                    validator: (value) => value == null ? 'Selecione um cliente' : null,
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
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Adicionar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_itensVenda.isEmpty)
                            const Text('Nenhum produto adicionado', style: TextStyle(color: Colors.grey))
                          else
                            ..._itensVenda.asMap().entries.map((entry) {
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
                  
                  // Parcelas
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Criar Venda a Prazo'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ItemVenda {
  final Produto produto;
  final int quantidade;
  final double valorUnitario;

  _ItemVenda({
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Produto>(
            value: _produtoSelecionado,
            decoration: const InputDecoration(
              labelText: 'Produto',
              border: OutlineInputBorder(),
            ),
            items: widget.produtos.map((produto) {
              return DropdownMenuItem(
                value: produto,
                child: Text('${produto.nome} (Estoque: ${produto.quantidade})'),
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
              labelText: 'Quantidade',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valorController,
            decoration: const InputDecoration(
              labelText: 'Valor Unitário',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
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
            if (_produtoSelecionado == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecione um produto')),
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
            
            if (quantidade > _produtoSelecionado!.quantidade) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quantidade maior que o estoque disponível')),
              );
              return;
            }
            
            widget.onAdicionar(_produtoSelecionado!, quantidade, valor);
            Navigator.pop(context);
          },
          child: const Text('Adicionar'),
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
            
            if (numeroParcelas <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Número de parcelas deve ser maior que zero')),
              );
              return;
            }
            
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
