import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Headers padrão com UTF-8 explícito
  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Decodificar resposta com UTF-8
  static dynamic _decodeResponse(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  // Codificar body com UTF-8
  static List<int> _encodeBody(Map<String, dynamic> body) {
    return utf8.encode(jsonEncode(body));
  }

  static Future<Map<String, dynamic>> login(String login, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/json'),
      headers: _getHeaders(null),
      body: _encodeBody({'login': login, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw Exception('Falha no login');
    }
  }

  static Future<List<dynamic>> getProdutos(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/produtos'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
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
    double estoqueAtual, {
    String? dataValidade,
  }) async {
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
      headers: _getHeaders(token),
      body: _encodeBody(body),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      // Melhorar mensagem de erro
      final error = _decodeResponse(response);
      final errorMsg = error['detail'] ?? 'Erro ao criar produto';
      throw Exception(errorMsg);
    }
  }

  static Future<Map<String, dynamic>> atualizarProduto(
    String token,
    int produtoId,
    String nome,
    String unidade,
    double preco, {
    String? dataValidade,
  }) async {
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
      headers: _getHeaders(token),
      body: _encodeBody(body),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
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
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao deletar produto');
    }
  }

  static Future<Map<String, dynamic>> registrarMovimentacao(
    String token,
    int produtoId,
    String tipo,
    double quantidade, {
    double? custoUnitario,
    String? formaPagamento,
  }) async {
    final body = {
      'produto_id': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
    };
    
    if (custoUnitario != null) {
      body['custo_unitario'] = custoUnitario;
    }
    
    if (formaPagamento != null && tipo == 'SAIDA') {
      body['forma_pagamento'] = formaPagamento;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/movimentacoes'),
      headers: _getHeaders(token),
      body: _encodeBody(body),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao registrar movimentação');
    }
  }

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
    
    if (tipo != 'AJUSTE' && valorUnitario > 0) {
      body['custo_unitario'] = valorUnitario;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/movimentacoes'),
      headers: _getHeaders(token),
      body: _encodeBody(body),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
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
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw Exception('Erro ao buscar relatório');
    }
  }

  static Future<List<dynamic>> getMovimentacoes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movimentacoes'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
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
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao cancelar movimentação');
    }
  }

  // ========== USUÁRIOS ==========

  static Future<List<dynamic>> getUsuarios(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
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
      headers: _getHeaders(token),
      body: _encodeBody({
        'nome': nome,
        'login': login,
        'senha': senha,
        'perfil': perfil,
      }),
    );

    if (response.statusCode == 201) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
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
      headers: _getHeaders(token),
      body: _encodeBody(body),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao atualizar usuário');
    }
  }

  static Future<Map<String, dynamic>> deletarUsuario(
    String token,
    int usuarioId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/usuarios/$usuarioId'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao deletar usuário');
    }
  }

  static Future<Map<String, dynamic>> toggleAtivoUsuario(
    String token,
    int usuarioId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/usuarios/$usuarioId/toggle-ativo'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
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
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao fazer upload da foto');
    }
  }

  static Future<Map<String, dynamic>> removerFoto(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/usuarios/me/foto'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      final error = _decodeResponse(response);
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
