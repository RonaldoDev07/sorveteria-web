import 'package:flutter/foundation.dart';

class ItemCarrinho {
  final int produtoId;
  final String nomeProduto;
  final double precoUnitario;
  int quantidade;
  
  ItemCarrinho({
    required this.produtoId,
    required this.nomeProduto,
    required this.precoUnitario,
    this.quantidade = 1,
  });
  
  double get subtotal => precoUnitario * quantidade;
}

class CarrinhoProvider extends ChangeNotifier {
  final List<ItemCarrinho> _itens = [];
  
  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  
  int get totalItens => _itens.fold(0, (sum, item) => sum + item.quantidade);
  
  double get valorTotal => _itens.fold(0.0, (sum, item) => sum + item.subtotal);
  
  bool get isEmpty => _itens.isEmpty;
  
  void adicionarProduto({
    required int produtoId,
    required String nomeProduto,
    required double precoUnitario,
    int quantidade = 1,
  }) {
    // Verificar se produto já está no carrinho
    final index = _itens.indexWhere((item) => item.produtoId == produtoId);
    
    if (index >= 0) {
      // Produto já existe, aumentar quantidade
      _itens[index].quantidade += quantidade;
    } else {
      // Adicionar novo produto
      _itens.add(ItemCarrinho(
        produtoId: produtoId,
        nomeProduto: nomeProduto,
        precoUnitario: precoUnitario,
        quantidade: quantidade,
      ));
    }
    
    notifyListeners();
  }
  
  void removerProduto(int produtoId) {
    _itens.removeWhere((item) => item.produtoId == produtoId);
    notifyListeners();
  }
  
  void atualizarQuantidade(int produtoId, int novaQuantidade) {
    if (novaQuantidade <= 0) {
      removerProduto(produtoId);
      return;
    }
    
    final index = _itens.indexWhere((item) => item.produtoId == produtoId);
    if (index >= 0) {
      _itens[index].quantidade = novaQuantidade;
      notifyListeners();
    }
  }
  
  void limparCarrinho() {
    _itens.clear();
    notifyListeners();
  }
  
  List<Map<String, dynamic>> toJson() {
    return _itens.map((item) => {
      'produto_id': item.produtoId,
      'quantidade': item.quantidade,
      'valor_unitario': item.precoUnitario,
    }).toList();
  }
}
