import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // URL da API (configurável em api_config.dart)
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> login(String login, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha no login');
    }
  }

  static Future<List<dynamic>> getProdutos(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/produtos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar produtos');
    }
  }

  static Future<Map<String, dynamic>> criarProduto(
    String token,
    String nome,
    String unidade,
    double custo,
    double preco,
    double estoqueAtual,
    {String? dataValidade}, // Data de validade opcional (formato: YYYY-MM-DD)
  ) async {
    final body = {
      'nome': nome,
      'unidade': unidade,
      'custo_medio': custo,
      'preco_venda': preco,
      'estoque_atual': estoqueAtual,
    };
    
    if (dataValidade != null) {
      body['data_validade'] = dataValidade;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/produtos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao criar produto');
    }
  }

  static Future<Map<String, dynamic>> atualizarProduto(
    String token,
    int produtoId,
    String nome,
    String unidade,
    double preco,
    {String? dataValidade}, // Data de validade opcional (formato: YYYY-MM-DD)
  ) async {
    final body = {
      'nome': nome,
      'unidade': unidade,
      'preco_venda': preco,
    };
    
    if (dataValidade != null) {
      body['data_validade'] = dataValidade;
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl/produtos/$produtoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao atualizar produto');
    }
  }

  static Future<Map<String, dynamic>> deletarProduto(
    String token,
    int produtoId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/produtos/$produtoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao deletar produto');
    }
  }

  static Future<Map<String, dynamic>> registrarMovimentacao(
    String token,
    int produtoId,
    String tipo,
    double quantidade,
    {double? custoUnitario}
  ) async {
    final body = {
      'produto_id': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
    };
    
    if (custoUnitario != null) {
      body['custo_unitario'] = custoUnitario;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/movimentacoes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao registrar movimentação');
    }
  }

  // Método específico para ajustes de estoque
  static Future<Map<String, dynamic>> criarMovimentacao(
    String token,
    int produtoId,
    double quantidade,
    double valorUnitario,
    String tipo,
    String? observacao,
  ) async {
    final body = {
      'produto_id': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
    };
    
    // Para ajustes, não enviamos custo_unitario
    if (tipo != 'AJUSTE' && valorUnitario > 0) {
      body['custo_unitario'] = valorUnitario;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/movimentacoes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao criar movimentação');
    }
  }

  static Future<Map<String, dynamic>> getRelatorioLucro(
    String token,
    String? dataInicio,
    String? dataFim,
  ) async {
    var url = '$baseUrl/relatorios/lucro';
    final params = <String>[];

    if (dataInicio != null && dataInicio.isNotEmpty) {
      params.add('data_inicio=$dataInicio');
    }
    if (dataFim != null && dataFim.isNotEmpty) {
      params.add('data_fim=$dataFim');
    }

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw Exception('Erro ao buscar relatório');
    }
  }

  static Future<List<dynamic>> getMovimentacoes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movimentacoes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar movimentações');
    }
  }

  static Future<Map<String, dynamic>> cancelarMovimentacao(
    String token,
    int movimentacaoId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/movimentacoes/$movimentacaoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao cancelar movimentação');
    }
  }

  // ========== USUÁRIOS ==========

  static Future<List<dynamic>> getUsuarios(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar usuários');
    }
  }

  static Future<Map<String, dynamic>> criarUsuario(
    String token,
    String nome,
    String login,
    String senha,
    String perfil,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'login': login,
        'senha': senha,
        'perfil': perfil,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao criar usuário');
    }
  }

  static Future<Map<String, dynamic>> atualizarUsuario(
    String token,
    int usuarioId,
    String? nome,
    String? login,
    String? senha,
    String? perfil,
    bool? ativo,
  ) async {
    final body = <String, dynamic>{};
    
    if (nome != null) body['nome'] = nome;
    if (login != null) body['login'] = login;
    if (senha != null) body['senha'] = senha;
    if (perfil != null) body['perfil'] = perfil;
    if (ativo != null) body['ativo'] = ativo;

    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/$usuarioId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao atualizar usuário');
    }
  }

  static Future<Map<String, dynamic>> deletarUsuario(
    String token,
    int usuarioId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/usuarios/$usuarioId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao deletar usuário');
    }
  }

  static Future<Map<String, dynamic>> toggleAtivoUsuario(
    String token,
    int usuarioId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/usuarios/$usuarioId/toggle-ativo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao alterar status do usuário');
    }
  }

  // ========== FOTO DE PERFIL ==========

  static Future<Map<String, dynamic>> uploadFoto(
    String token,
    List<int> imageBytes,
    String fileName,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/usuarios/me/foto'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao fazer upload da foto');
    }
  }

  static Future<Map<String, dynamic>> removerFoto(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/usuarios/me/foto'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao remover foto');
    }
  }

  // ========== EXPORTAR CSV ==========

  static Future<void> exportarRelatorioCSV(
    String token,
    String? dataInicio,
    String? dataFim,
  ) async {
    var url = '$baseUrl/relatorios/exportar-csv';
    final params = <String>[];

    if (dataInicio != null && dataInicio.isNotEmpty) {
      params.add('data_inicio=$dataInicio');
    }
    if (dataFim != null && dataFim.isNotEmpty) {
      params.add('data_fim=$dataFim');
    }

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Para web, criar um link de download
      final bytes = response.bodyBytes;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'relatorio_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    } else {
      throw Exception('Erro ao exportar relatório');
    }
  }

}
