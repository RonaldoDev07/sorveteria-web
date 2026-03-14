import '../models/produto.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ProdutoService {
  final AuthService authService;

  ProdutoService(this.authService);

  Future<List<Produto>> getProdutos() async {
    final token = authService.token;
    if (token == null) {
      throw Exception('Não autenticado');
    }
    
    final response = await ApiService.getProdutos(token);
    
    final produtos = <Produto>[];
    for (var i = 0; i < response.length; i++) {
      try {
        final produto = Produto.fromJson(response[i]);
        produtos.add(produto);
      } catch (e) {
        // Ignorar produto com erro de parsing
      }
    }
    return produtos;
  }

  Future<List<Produto>> listarProdutos() async {
    return getProdutos();
  }
}
