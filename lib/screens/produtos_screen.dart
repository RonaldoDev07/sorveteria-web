import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/text_formatters.dart';
import '../mixins/auto_refresh_mixin.dart';
import 'baixa_estoque_screen.dart';
import 'entrada_estoque_screen.dart';
import 'editar_produto_screen.dart';
import 'compras_menu_screen.dart';
import 'cadastro_produto_screen.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> with AutoRefreshMixin {
  List<dynamic> _produtos = [];
  List<dynamic> _produtosFiltrados = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _mostrarApenasEstoqueBaixo = false;

  @override
  void initState() {
    super.initState();
    _loadProdutos();
    startAutoRefresh(); // Inicia refresh automático a cada 30 segundos
  }

  int _contarProdutosEstoqueBaixo() {
    return _produtos.where((produto) {
      final estoque = produto['estoque_atual'];
      final estoqueNum = estoque is num ? estoque.toDouble() : (double.tryParse(estoque.toString().replaceAll(',', '.')) ?? 0);
      return estoqueNum > 0 && estoqueNum <= 5;
    }).length;
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

  String _formatarPreco(dynamic valor) {
    if (valor == null) return '0,00';
    final numero = double.parse(valor.toString());
    return numero.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatarData(dynamic data) {
    if (data == null) return '';
    try {
      final DateTime dataObj = DateTime.parse(data.toString());
      return '${dataObj.day.toString().padLeft(2, '0')}/${dataObj.month.toString().padLeft(2, '0')}/${dataObj.year}';
    } catch (e) {
      return '';
    }
  }

  double _calcularValorTotalEstoque() {
    double total = 0;
    for (var produto in _produtosFiltrados) {
      final estoque = produto['estoque_atual'];
      final estoqueNum = estoque is num ? estoque.toDouble() : (double.tryParse(estoque.toString().replaceAll(',', '.')) ?? 0);
      final preco = double.parse(produto['preco_venda'].toString());
      total += estoqueNum * preco;
    }
    return total;
  }

  // Calcular status da validade
  Map<String, dynamic>? _calcularStatusValidade(dynamic dataValidade) {
    if (dataValidade == null) return null;
    
    try {
      final DateTime validade = DateTime.parse(dataValidade.toString());
      final DateTime hoje = DateTime.now();
      final diferenca = validade.difference(hoje).inDays;
      
      if (diferenca < 0) {
        // Vencido
        return {
          'status': 'vencido',
          'cor': Colors.red,
          'icone': Icons.dangerous_rounded,
          'texto': 'Vencido há ${diferenca.abs()} ${diferenca.abs() == 1 ? 'dia' : 'dias'}',
        };
      } else if (diferenca <= 7) {
        // Próximo do vencimento (7 dias ou menos)
        return {
          'status': 'proximo',
          'cor': Colors.orange,
          'icone': Icons.warning_rounded,
          'texto': diferenca == 0 ? 'Vence hoje!' : 'Vence em $diferenca ${diferenca == 1 ? 'dia' : 'dias'}',
        };
      } else {
        // Válido
        return {
          'status': 'valido',
          'cor': Colors.blue,
          'icone': Icons.calendar_today_rounded,
          'texto': 'Válido até ${validade.day.toString().padLeft(2, '0')}/${validade.month.toString().padLeft(2, '0')}/${validade.year}',
        };
      }
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Future<void> loadData() => _loadProdutos();

  void _filtrarProdutos(String query) {
    setState(() {
      var produtosFiltrados = _produtos;
      
      // Filtrar por estoque baixo se ativado
      if (_mostrarApenasEstoqueBaixo) {
        produtosFiltrados = produtosFiltrados.where((produto) {
          final estoque = produto['estoque_atual'];
          final estoqueNum = estoque is num ? estoque.toDouble() : (double.tryParse(estoque.toString().replaceAll(',', '.')) ?? 0);
          return estoqueNum > 0 && estoqueNum <= 5;
        }).toList();
      }
      
      // Filtrar por nome
      if (query.isEmpty) {
        _produtosFiltrados = produtosFiltrados;
      } else {
        _produtosFiltrados = produtosFiltrados
            .where((produto) =>
                produto['nome'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleFiltroEstoqueBaixo() {
    setState(() {
      _mostrarApenasEstoqueBaixo = !_mostrarApenasEstoqueBaixo;
      _filtrarProdutos(_searchController.text);
    });
  }

  Future<void> _loadProdutos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final produtos = await ApiService.getProdutos(auth.token!);
      if (!mounted) return;
      setState(() {
        _produtos = produtos;
        _filtrarProdutos(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarDeletar(dynamic produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Deletar Produto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente excluir o produto "${produto['nome']}"?\n\nEsta ação não poderá ser desfeita.',
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Deletar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        await ApiService.deletarProduto(auth.token!, produto['id']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produto "${produto['nome']}" deletado com sucesso!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _loadProdutos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao deletar produto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _mostrarDialogAjustarEstoque(dynamic produto) async {
    final quantidadeController = TextEditingController();
    final motivoController = TextEditingController();
    String tipoAjuste = 'adicionar'; // 'adicionar' ou 'remover'

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFFFF8C00), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajustar Estoque',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      produto['nome'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Estoque atual: ${_formatarNumero(produto['estoque_atual'])} ${produto['unidade']}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tipo de ajuste:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Adicionar', style: TextStyle(fontSize: 11)),
                        value: 'adicionar',
                        groupValue: tipoAjuste,
                        onChanged: (value) => setDialogState(() => tipoAjuste = value!),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Remover', style: TextStyle(fontSize: 11)),
                        value: 'remover',
                        groupValue: tipoAjuste,
                        onChanged: (value) => setDialogState(() => tipoAjuste = value!),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantidadeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 13),
                  onTap: () {
                    if (quantidadeController.text.isNotEmpty) {
                      quantidadeController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: quantidadeController.text.length,
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    labelStyle: const TextStyle(fontSize: 12),
                    hintText: 'Ex: 5 ou 3,5',
                    hintStyle: const TextStyle(fontSize: 11),
                    prefixIcon: Icon(
                      tipoAjuste == 'adicionar' ? Icons.add_rounded : Icons.remove_rounded,
                      color: tipoAjuste == 'adicionar' ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: motivoController,
                  style: const TextStyle(fontSize: 13),
                  textInputAction: TextInputAction.done,
                  onTap: () {
                    if (motivoController.text.isNotEmpty) {
                      motivoController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: motivoController.text.length,
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Motivo do ajuste',
                    labelStyle: const TextStyle(fontSize: 12),
                    hintText: 'Ex: Conversão, Perda, Inventário...',
                    hintStyle: const TextStyle(fontSize: 11),
                    prefixIcon: const Icon(Icons.description_rounded, color: Colors.grey, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Ajustar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );

    if (resultado != true) return;

    if (quantidadeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe a quantidade'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (motivoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o motivo do ajuste'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final quantidade = double.parse(quantidadeController.text);
      // Para ajustes: positivo = adicionar, negativo = remover
      final quantidadeFinal = tipoAjuste == 'adicionar' ? quantidade : -quantidade;
      
      // Criar movimentação de ajuste
      await ApiService.criarMovimentacao(
        auth.token!,
        produto['id'],
        quantidadeFinal,
        0, // valor unitário 0 para ajustes
        'AJUSTE',
        'Ajuste de estoque: ${motivoController.text}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estoque ajustado com sucesso! ${tipoAjuste == 'adicionar' ? '+' : ''}${_formatarNumero(quantidadeFinal)} ${produto['unidade']}'
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadProdutos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao ajustar estoque: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Produtos',
          style: TextStyle(
            fontSize: 18,
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        actions: [
          // Badge de estoque baixo no AppBar
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  _mostrarApenasEstoqueBaixo ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _mostrarApenasEstoqueBaixo ? Colors.amber : Colors.white,
                ),
                onPressed: _toggleFiltroEstoqueBaixo,
                tooltip: _mostrarApenasEstoqueBaixo ? 'Mostrar todos' : 'Estoque baixo',
              ),
              if (_contarProdutosEstoqueBaixo() > 0)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_contarProdutosEstoqueBaixo()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CadastroProdutoScreen(),
                  ),
                );
                if (resultado == true) {
                  _loadProdutos();
                }
              },
              tooltip: 'Cadastrar Produto',
            ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.shopping_cart_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ComprasMenuScreen(),
                  ),
                );
              },
              tooltip: 'Registrar Compra',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProdutos,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Banner de filtro ativo
                  if (_mostrarApenasEstoqueBaixo)
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.orange.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mostrando apenas produtos com estoque baixo (≤5 unidades)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: _toggleFiltroEstoqueBaixo,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _filtrarProdutos,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar produto...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6)),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total: ${_produtosFiltrados.length} ${_produtosFiltrados.length == 1 ? 'produto' : 'produtos'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.attach_money_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'R\$ ${_formatarPreco(_calcularValorTotalEstoque())}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_produtosFiltrados.where((p) {
                                        final estoque = p['estoque_atual'];
                                        final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0);
                                        return estoqueNum > 0;
                                      }).length} disponível',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.warning_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_produtosFiltrados.where((p) {
                                        final estoque = p['estoque_atual'];
                                        final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0);
                                        return estoqueNum == 0;
                                      }).length} esgotado',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_searchController.text.isNotEmpty && _produtosFiltrados.length != _produtos.length) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(de ${_produtos.length})',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadProdutos,
                      child: _produtosFiltrados.isEmpty
                          ? ListView( // Precisa ser scrollable para o RefreshIndicator funcionar
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                Center(
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
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _produtosFiltrados.length,
                              itemBuilder: (context, index) {
                                final produto = _produtosFiltrados[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Badge de estoque com alerta visual
                                    Builder(
                                      builder: (context) {
                                        final estoque = produto['estoque_atual'];
                                        final estoqueNum = estoque is num ? estoque.toDouble() : (double.tryParse(estoque.toString().replaceAll(',', '.')) ?? 0);
                                        
                                        Color corEstoque;
                                        IconData iconeEstoque;
                                        String textoAlerta = '';
                                        
                                        if (estoqueNum == 0) {
                                          corEstoque = Colors.red;
                                          iconeEstoque = Icons.error_outline;
                                          textoAlerta = 'ESGOTADO';
                                        } else if (estoqueNum <= 5) {
                                          corEstoque = Colors.orange;
                                          iconeEstoque = Icons.warning_amber;
                                          textoAlerta = 'ESTOQUE BAIXO';
                                        } else {
                                          corEstoque = const Color(0xFF10B981);
                                          iconeEstoque = Icons.check_circle_outline;
                                          textoAlerta = '';
                                        }
                                        
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: corEstoque.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: corEstoque.withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(iconeEstoque, size: 14, color: corEstoque),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_formatarNumero(produto['estoque_atual'])} ${produto['unidade']}',
                                                    style: TextStyle(
                                                      color: corEstoque,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (textoAlerta.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: corEstoque,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  textoAlerta,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'R\$ ${_formatarPreco(produto['preco_venda'])}',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Código de barras (se existir)
                                if (produto['codigo_barras'] != null && produto['codigo_barras'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.purple.shade50, Colors.purple.shade100],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.purple.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.qr_code_2, size: 18, color: Colors.purple[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          produto['codigo_barras'],
                                          style: TextStyle(
                                            color: Colors.purple[900],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            fontFamily: 'monospace',
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                // Alerta de validade
                                if (produto['data_validade'] != null) ...[
                                  const SizedBox(height: 6),
                                  Builder(
                                    builder: (context) {
                                      final statusValidade = _calcularStatusValidade(produto['data_validade']);
                                      if (statusValidade == null) return const SizedBox.shrink();
                                      
                                      return Row(
                                        children: [
                                          Icon(
                                            statusValidade['icone'],
                                            size: 16,
                                            color: statusValidade['cor'],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusValidade['texto'],
                                            style: TextStyle(
                                              color: statusValidade['cor'],
                                              fontWeight: statusValidade['status'] == 'vencido' ? FontWeight.w700 : FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                                // Data de cadastro
                                if (produto['created_at'] != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cadastrado em ${_formatarData(produto['created_at'])}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'saida',
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981)),
                                    SizedBox(width: 12),
                                    Text('Registrar Venda', style: TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              if (auth.canCadastrarProduto)
                                const PopupMenuItem(
                                  value: 'entrada',
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_downward_rounded, color: Color(0xFF14B8A6)),
                                      SizedBox(width: 12),
                                      Text('Registrar Compra', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              if (auth.canCadastrarProduto)
                                const PopupMenuItem(
                                  value: 'ajustar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.tune_rounded, color: Color(0xFFFF8C00)),
                                      SizedBox(width: 12),
                                      Text('Ajustar Estoque', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              if (auth.isAdmin)
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, color: Color(0xFF6366F1)),
                                      SizedBox(width: 12),
                                      Text('Editar Produto', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              if (auth.isAdmin)
                                const PopupMenuItem(
                                  value: 'deletar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text('Deletar Produto', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                            ],
                            onSelected: (value) async {
                              if (value == 'saida') {
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BaixaEstoqueScreen(produto: produto),
                                  ),
                                );
                                if (resultado == true) {
                                  _loadProdutos();
                                }
                              } else if (value == 'entrada') {
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EntradaEstoqueScreen(produto: produto),
                                  ),
                                );
                                if (resultado == true) {
                                  _loadProdutos();
                                }
                              } else if (value == 'ajustar') {
                                _mostrarDialogAjustarEstoque(produto);
                              } else if (value == 'editar') {
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarProdutoScreen(produto: produto),
                                  ),
                                );
                                if (resultado == true) {
                                  _loadProdutos();
                                }
                              } else if (value == 'deletar') {
                                _confirmarDeletar(produto);
                              }
                            },
                          ),
                        ),
                      );
                            },
                          ),
                    ),
                  ),
                ],
              ),
      floatingActionButton: null,
    );
  }
}
