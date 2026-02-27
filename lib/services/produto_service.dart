import '../models/produto.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ProdutoService {
  final AuthService authService;

  ProdutoService(this.authService);

  Future<List<Produto>> getProdutos() async {
    print('🔍 ProdutoService.getProdutos() chamado');
    
    final token = authService.token;
    if (token == null) {
      print('❌ Token NULL - não autenticado!');
      throw Exception('Não autenticado');
    }
    
    print('✅ Token presente, fazendo requisição...');
    final response = await ApiService.getProdutos(token);
    print('📦 API retornou ${response.length} produtos');
    
    final produtos = response.map((json) => Produto.fromJson(json)).toList();
    print('✅ ${produtos.length} produtos convertidos com sucesso');
    
    if (produtos.isNotEmpty) {
      print('   Exemplo: ${produtos.first.nome} (ID: ${produtos.first.id})');
    }
    
    return produtos;
  }

  Future<List<Produto>> listarProdutos() async {
    print('🔍 ProdutoService.listarProdutos() chamado');
    return getProdutos();
  }
}
