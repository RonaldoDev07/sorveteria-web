import '../models/produto.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ProdutoService {
  final AuthService authService;

  ProdutoService(this.authService);

  Future<List<Produto>> getProdutos() async {
    final token = authService.token;
    if (token == null) throw Exception('Não autenticado');

    final response = await ApiService.getProdutos(token);
    return response.map((json) => Produto.fromJson(json)).toList();
  }

  Future<List<Produto>> listarProdutos() async {
    return getProdutos();
  }
}
