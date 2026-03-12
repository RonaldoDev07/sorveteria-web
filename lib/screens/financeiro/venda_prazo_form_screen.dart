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
import '../../services/sound_service.dart';
import '../../services/api_service.dart';
import '../../widgets/financeiro_styles.dart';
import '../../utils/input_formatters.dart';
import '../barcode_scanner_universal.dart';

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
  
  String _filtroProduto = '';
  DateTime _dataVenda = DateTime.now(); // Data da venda
  final _observacoesController = TextEditingController();
  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

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
      print('✅ ${produtos.length} produtos carregados da API');
      
      if (mounted) {
        setState(() {
          // Remover filtro de quantidade para debug - mostrar todos os produtos
          _produtos = produtos; // .where((p) => p.quantidade > 0).toList();
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
    final auth = Provider.of<AuthService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => _DialogAdicionarProduto(
        produtos: _produtos,
        auth: auth,
        onAdicionar: (produto, quantidade, valorUnitario) {
          setState(() {
            _itensVenda.add(_ItemVenda(
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
      _itensVenda.removeAt(index);
    });
  }

  Future<void> _cadastrarClienteRapido() async {
    final nomeController = TextEditingController();
    final cpfCnpjController = TextEditingController();
    final telefoneController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cadastrar Cliente',
                style: TextStyle(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  labelStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cpfCnpjController,
                decoration: InputDecoration(
                  labelText: 'CPF/CNPJ *',
                  labelStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.badge, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.number,
                inputFormatters: [CpfCnpjInputFormatter()],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telefoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.phone,
                inputFormatters: [TelefoneInputFormatter()],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: const Text('Cadastrar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (resultado == true) {
      if (nomeController.text.isEmpty || cpfCnpjController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha nome e CPF/CNPJ')),
        );
        return;
      }

      try {
        final novoCliente = Cliente(
          nome: nomeController.text.trim(),
          cpfCnpj: cpfCnpjController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''), // Apenas números
          telefone: telefoneController.text.trim().isEmpty ? null : telefoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        );
        
        print('🔍 Criando cliente: ${novoCliente.toJson()}');
        
        await _clienteService.criarCliente(novoCliente);

        // Recarregar lista de clientes
        await _carregarClientes();

        // Selecionar o cliente recém-criado
        final clienteCriado = _clientes.firstWhere(
          (c) => c.cpfCnpj == cpfCnpjController.text,
          orElse: () => _clientes.last,
        );
        setState(() => _clienteSelecionado = clienteCriado);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente cadastrado com sucesso')),
          );
        }
      } catch (e) {
        print('❌ Erro ao criar cliente: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar cliente: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
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

    // Verificar se cliente tem conta aberta no mês
    setState(() => _isLoading = true);
    
    try {
      final contaAberta = await _vendaService.buscarContaAberta(_clienteSelecionado!.id!);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (contaAberta != null) {
        // Cliente tem conta aberta - perguntar o que fazer
        final opcao = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Conta Mensal Aberta',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${_clienteSelecionado!.nome}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Saldo devedor atual: ${_formatoMoeda.format(contaAberta['saldoDevedor'])}'),
                const SizedBox(height: 16),
                const Text(
                  'Este cliente já tem uma conta aberta neste mês. O que deseja fazer?',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancelar'),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'adicionar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar à Conta'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'nova'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Nova Venda'),
              ),
            ],
          ),
        );

        if (opcao == 'adicionar') {
          await _adicionarNaContaMensal();
        } else if (opcao == 'nova') {
          await _criarVendaComParcelas();
        }
      } else {
        // Não tem conta aberta - perguntar o que fazer
        final opcao = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.help_outline, color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tipo de Venda',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${_clienteSelecionado!.nome}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Produtos: ${_itensVenda.length}'),
                Text('Valor Total: ${_formatoMoeda.format(_valorTotal)}'),
                const SizedBox(height: 16),
                const Text(
                  'Como deseja registrar esta venda?',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Conta Mensal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cliente pode pegar produtos durante o mês. Parcelas geradas no final.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Venda com Parcelas',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gera parcelas imediatamente para esta venda.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancelar'),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'conta_mensal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Conta Mensal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'com_parcelas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Com Parcelas'),
              ),
            ],
          ),
        );

        if (opcao == 'conta_mensal') {
          await _adicionarNaContaMensal();
        } else if (opcao == 'com_parcelas') {
          await _criarVendaComParcelas();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _adicionarNaContaMensal() async {
    setState(() => _isLoading = true);

    try {
      final resultado = await _vendaService.adicionarProdutosConta(
        clienteId: _clienteSelecionado!.id!,
        produtos: _itensVenda.map((item) => {
          'produtoId': item.produto.id,
          'quantidade': item.quantidade,
          'valorUnitario': item.valorUnitario,
        }).toList(),
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      );

      if (mounted) {
        await SoundService.playSuccess();
        await Future.delayed(const Duration(milliseconds: 100));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${resultado['mensagem'] ?? 'Produtos adicionados à conta mensal!'}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        await SoundService.playError();
        await Future.delayed(const Duration(milliseconds: 100));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _criarVendaComParcelas() async {
    if (_parcelas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere as parcelas antes de continuar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _vendaService.criarVenda(
        clienteId: _clienteSelecionado!.id!,
        produtos: _itensVenda.map((item) => {
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
        await SoundService.playSuccess();
        await Future.delayed(const Duration(milliseconds: 100));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Venda criada com sucesso!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        await SoundService.playError();
        await Future.delayed(const Duration(milliseconds: 100));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _abrirScanner() async {
    try {
      final codigo = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const BarcodeScannerUniversal(),
          fullscreenDialog: true,
        ),
      );
      
      if (codigo != null && mounted) {
        _buscarProdutoPorCodigo(codigo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir scanner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _buscarProdutoPorCodigo(String codigo) {
    final produto = _produtos.firstWhere(
      (p) => p.codigoBarras == codigo,
      orElse: () => _produtos.first,
    );

    if (produto.codigoBarras == codigo) {
      // Produto encontrado, abrir dialog de adicionar com produto pré-selecionado
      final auth = Provider.of<AuthService>(context, listen: false);
      showDialog(
        context: context,
        builder: (context) => _DialogAdicionarProduto(
          produtos: _produtos,
          auth: auth,
          produtoInicial: produto,
          onAdicionar: (produto, quantidade, valorUnitario) {
            setState(() {
              _itensVenda.add(_ItemVenda(
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Nova Venda a Prazo',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoadingClientes || _isLoadingProdutos
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // Card Cliente
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person, color: Color(0xFF10B981), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Cliente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Cliente>(
                                value: _clienteSelecionado,
                                decoration: InputDecoration(
                                  labelText: 'Cliente *',
                                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF10B981)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _cadastrarClienteRapido,
                                icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                                tooltip: 'Cadastrar novo cliente',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final data = await showDatePicker(
                              context: context,
                              initialDate: _dataVenda,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              locale: const Locale('pt', 'BR'),
                            );
                            if (data != null) {
                              setState(() => _dataVenda = data);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF10B981)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data da Venda',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_dataVenda),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Card Produtos
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.shopping_cart, color: Color(0xFF10B981), size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Produtos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            Container(
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
                              child: ElevatedButton.icon(
                                onPressed: _adicionarProduto,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Adicionar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_itensVenda.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nenhum produto adicionado',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._itensVenda.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.inventory_2, color: Color(0xFF10B981), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.produto.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.quantidade}x ${_formatoMoeda.format(item.valorUnitario)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatoMoeda.format(item.subtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removerProduto(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                        if (_itensVenda.isNotEmpty) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                _formatoMoeda.format(_valorTotal),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Card Parcelas
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.calendar_month, color: Colors.blue, size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Parcelas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.blue, Colors.lightBlue],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _gerarParcelas,
                                icon: const Icon(Icons.calculate, size: 18),
                                label: const Text('Gerar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_parcelas.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.event_note_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nenhuma parcela gerada',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._parcelas.map((parcela) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${parcela.numero}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Parcela',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          'Vencimento: ${DateFormat('dd/MM/yyyy').format(parcela.dataVencimento)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatoMoeda.format(parcela.valor),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Card Observações
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.note, color: Colors.orange, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Observações',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _observacoesController,
                          decoration: InputDecoration(
                            hintText: 'Adicione observações sobre esta venda...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.orange, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botão Salvar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Criar Venda a Prazo',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
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
  final Future<void> Function()? onProdutoCadastrado;
  final Produto? produtoInicial;
  final AuthService auth;

  const _DialogAdicionarProduto({
    required this.produtos,
    required this.onAdicionar,
    this.onProdutoCadastrado,
    this.produtoInicial,
    required this.auth,
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
    print('🔍 Dialog Adicionar Produto iniciado');
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
      // Mostrar alerta visual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ERRO: ${widget.produtos.length} produtos carregados! Verifique se há produtos cadastrados.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cadastro Rápido',
                style: TextStyle(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Produto *',
                  labelStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.label, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: unidadeController,
                decoration: InputDecoration(
                  labelText: 'Unidade *',
                  labelStyle: const TextStyle(fontSize: 14),
                  hintText: 'UN, KG, L',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.straighten, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: custoController,
                decoration: InputDecoration(
                  labelText: 'Custo *',
                  labelStyle: const TextStyle(fontSize: 14),
                  hintText: '5,50',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFEF4444), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixText: 'R\$ ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: precoController,
                decoration: InputDecoration(
                  labelText: 'Preço de Venda *',
                  labelStyle: const TextStyle(fontSize: 14),
                  hintText: '8,00',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.sell, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixText: 'R\$ ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: estoqueController,
                decoration: InputDecoration(
                  labelText: 'Estoque Inicial',
                  labelStyle: const TextStyle(fontSize: 14),
                  hintText: '10 ou 3,5',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.inventory, color: Color(0xFF3B82F6), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codigoBarrasController,
                      decoration: InputDecoration(
                        labelText: 'Código de Barras',
                        labelStyle: const TextStyle(fontSize: 14),
                        prefixIcon: const Icon(Icons.qr_code_2, color: Color(0xFF9333EA), size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      try {
                        final codigo = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BarcodeScannerUniversal(),
                            fullscreenDialog: true,
                          ),
                        );
                        
                        if (codigo != null) {
                          codigoBarrasController.text = codigo;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao abrir scanner: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF9333EA)),
                    tooltip: 'Escanear código',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA).withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: const Text('Cadastrar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Fechar e reabrir o dialog para mostrar o produto novo
          Navigator.pop(dialogContext);
          
          // Aguardar um pouco para garantir que a lista foi atualizada
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Reabrir o dialog se ainda estiver montado
          if (mounted) {
            // O dialog pai vai reabrir automaticamente
          }
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
    try {
      final produtosFiltrados = widget.produtos
          .where((produto) => 
              _filtroProduto.isEmpty || 
              produto.nome.toLowerCase().contains(_filtroProduto))
          .toList();
      
      print('📋 Produtos filtrados: ${produtosFiltrados.length}');
      
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
                  if (widget.auth.canCadastrarProduto)
                    Tooltip(
                      message: 'Cadastrar novo produto',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
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
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          // Fechar dialog atual temporariamente
                          Navigator.pop(context);
                          
                          // Abrir scanner da tela principal
                          final parentContext = context;
                          final codigo = await Navigator.push<String>(
                            parentContext,
                            MaterialPageRoute(
                              builder: (_) => const BarcodeScannerUniversal(),
                              fullscreenDialog: true,
                            ),
                          );
                          
                          if (codigo != null) {
                            // Buscar produto
                            final produtoEncontrado = widget.produtos.firstWhere(
                              (p) => p.codigoBarras == codigo,
                              orElse: () => widget.produtos.first,
                            );
                            
                            if (produtoEncontrado.codigoBarras == codigo) {
                              // Adicionar produto diretamente
                              widget.onAdicionar(produtoEncontrado, 1, produtoEncontrado.preco);
                              
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text('✅ ${produtoEncontrado.nome} adicionado!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text('Produto com código $codigo não encontrado'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                          
                          // Reabrir dialog
                          showDialog(
                            context: parentContext,
                            builder: (context) => _DialogAdicionarProduto(
                              produtos: widget.produtos,
                              auth: widget.auth,
                              onAdicionar: widget.onAdicionar,
                              onProdutoCadastrado: widget.onProdutoCadastrado,
                            ),
                          );
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
                          color: isSelected ? Colors.green.shade50 : null,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              produto.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'R\$ ${produto.preco.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isSelected 
                                ? const Icon(Icons.check_circle, color: Colors.green)
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
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
                              hintText: 'Ex: 10',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            onTap: () {
                              if (_quantidadeController.text.isNotEmpty) {
                                _quantidadeController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _quantidadeController.text.length,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _valorController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              hintText: 'Ex: 5,50',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            onTap: () {
                              if (_valorController.text.isNotEmpty) {
                                _valorController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _valorController.text.length,
                                );
                              }
                            },
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
            
            if (quantidade > _produtoSelecionado!.quantidade) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quantidade maior que o estoque disponível'),
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
                backgroundColor: Colors.green,
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
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Adicionar Outro'),
        ),
      ],
    );
    } catch (e, stackTrace) {
      print('❌ ERRO NO BUILD DO DIALOG: $e');
      print('Stack: $stackTrace');
      return AlertDialog(
        title: const Text('Erro'),
        content: Text('Erro ao carregar produtos: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      );
    }
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
          Text('Valor Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(widget.valorTotal)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _numeroParcelasController,
            decoration: const InputDecoration(
              labelText: 'Número de Parcelas',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onTap: () {
              if (_numeroParcelasController.text.isNotEmpty) {
                _numeroParcelasController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _numeroParcelasController.text.length,
                );
              }
            },
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
