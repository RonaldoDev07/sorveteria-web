import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import 'baixa_estoque_screen.dart';
import 'entrada_estoque_screen.dart';
import 'editar_produto_screen.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  List<dynamic> _produtos = [];
  List<dynamic> _produtosFiltrados = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProdutos();
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

  Future<void> _loadProdutos() async {
    setState(() => _isLoading = true);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFFFF8C00), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajustar Estoque',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      produto['nome'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.normal),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estoque atual: ${_formatarNumero(produto['estoque_atual'])} ${produto['unidade']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Tipo de ajuste:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Adicionar', style: TextStyle(fontSize: 14)),
                        value: 'adicionar',
                        groupValue: tipoAjuste,
                        onChanged: (value) => setDialogState(() => tipoAjuste = value!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Remover', style: TextStyle(fontSize: 14)),
                        value: 'remover',
                        groupValue: tipoAjuste,
                        onChanged: (value) => setDialogState(() => tipoAjuste = value!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    hintText: 'Ex: 5',
                    prefixIcon: Icon(
                      tipoAjuste == 'adicionar' ? Icons.add_rounded : Icons.remove_rounded,
                      color: tipoAjuste == 'adicionar' ? Colors.green : Colors.red,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: motivoController,
                  decoration: InputDecoration(
                    labelText: 'Motivo do ajuste',
                    hintText: 'Ex: Conversão balde para bolas, Perda, Inventário...',
                    prefixIcon: const Icon(Icons.description_rounded, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 2,
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
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ajustar Estoque'),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProdutos,
            tooltip: 'Atualizar',
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      () {
                                        final estoque = produto['estoque_atual'];
                                        final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0);
                                        return estoqueNum == 0 ? Icons.warning_rounded : Icons.inventory_rounded;
                                      }(), 
                                      size: 16, 
                                      color: () {
                                        final estoque = produto['estoque_atual'];
                                        final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0);
                                        return estoqueNum == 0 ? Colors.red[600] : Colors.grey[600];
                                      }()
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      () {
                                        final estoque = produto['estoque_atual'];
                                        final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0);
                                        return estoqueNum == 0
                                          ? 'Estoque esgotado'
                                          : 'Estoque: ${_formatarNumero(produto['estoque_atual'])} ${produto['unidade']}';
                                      }(),
                                      style: TextStyle(
                                        color: () {
                                          final estoque = produto['estoque_atual'];
                                          final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0);
                                          return estoqueNum == 0 ? Colors.red[700] : Colors.grey[700];
                                        }(),
                                        fontSize: 14,
                                        fontWeight: () {
                                          final estoque = produto['estoque_atual'];
                                          final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0);
                                          return estoqueNum == 0 ? FontWeight.w600 : FontWeight.w500;
                                        }(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.payments_rounded, size: 16, color: Colors.green[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      BrazilianFormatters.formatCurrency(produto['preco_venda']),
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
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
                ],
              ),
    );
  }
}
