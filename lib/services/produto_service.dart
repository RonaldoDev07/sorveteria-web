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
    
    try {
      final produtos = <Produto>[];
      for (var i = 0; i < response.length; i++) {
        try {
          final json = response[i];
          print('   Convertendo produto $i: ${json['nome']}');
          final produto = Produto.fromJson(json);
          produtos.add(produto);
        } catch (e, stackTrace) {
          print('❌ Erro ao converter produto $i: $e');
          print('   JSON: ${response[i]}');
          print('   Stack: $stackTrace');
        }
      }
      
      print('✅ ${produtos.length} produtos convertidos com sucesso');
      
      if (produtos.isNotEmpty) {
        print('   Exemplo: ${produtos.first.nome} (ID: ${produtos.first.id})');
      }
      
      return produtos;
    } catch (e, stackTrace) {
      print('❌ Erro fatal ao processar produtos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Produto>> listarProdutos() async {
    print('🔍 ProdutoService.listarProdutos() chamado');
    return getProdutos();
  }
}
