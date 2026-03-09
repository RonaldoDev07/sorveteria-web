import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/debug_logger.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // 🔥 WAKE UP API - Acordar servidor antes de fazer login
  static Future<void> wakeUpApi() async {
    try {
      print('⏰ Acordando API...');
      await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 30));
      print('✅ API acordada!');
    } catch (e) {
      print('⚠️ Erro ao acordar API (ignorado): $e');
      // Ignorar erro - API pode já estar acordada
    }
  }

  // 🔄 RETRY - Tentar novamente em caso de erro de conexão
  static Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 3),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        
        // Se for erro de conexão e ainda tem tentativas, aguarda e tenta novamente
        if (attempts < maxRetries && 
            (e.toString().contains('XMLHttpRequest') || 
             e.toString().contains('ClientException') ||
             e.toString().contains('SocketException'))) {
          print('⚠️ Tentativa $attempts falhou. Tentando novamente em ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
          continue;
        }
        
        // Se não for erro de conexão ou acabaram as tentativas, lança o erro
        rethrow;
      }
    }
    
    // Nunca deve chegar aqui, mas por segurança
    throw Exception('Falha após $maxRetries tentativas');
  }

  // Headers padrão com UTF-8 explícito e Authorization Bearer
  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'User-Agent': 'SorveteriaCamila/1.0.7 (Android)',
    };
    
    // CRÍTICO: Adicionar token JWT no header Authorization
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      // Debug: Log do token (apenas primeiros caracteres)
      if (kDebugMode) {
        print('🔑 Token enviado: ${token.substring(0, min(20, token.length))}...');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ AVISO: Requisição sem token!');
      }
    }
    
    return headers;
  }

  // Decodificar resposta com UTF-8
  static dynamic _decodeResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao decodificar resposta: $e');
        print('   Body: ${response.body}');
        print('   Status: ${response.statusCode}');
      }
      // Se falhar, tenta decodificar direto
      try {
        return jsonDecode(response.body);
      } catch (e2) {
        // Se ainda falhar, retorna objeto vazio
        return {};
      }
    }
  }

  // Codificar body com UTF-8
  static List<int> _encodeBody(Map<String, dynamic> body) {
    return utf8.encode(jsonEncode(body));
  }

  static Future<Map<String, dynamic>> login(String login, String senha) async {
    return _retryRequest(() async {
      try {
        print('📡 Enviando requisição de login para: $baseUrl/login/json');
        
        final response = await http.post(
          Uri.parse('$baseUrl/login/json'),
          headers: _getHeaders(null),
          body: _encodeBody({'login': login, 'senha': senha}),
        ).timeout(const Duration(seconds: 30)); // 🔥 Timeout aumentado para 30s

        print('📥 Resposta recebida - Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = _decodeResponse(response);
          print('✅ Login bem-sucedido! Token recebido.');
          return data;
        } else if (response.statusCode == 401) {
          print('❌ Credenciais inválidas (401)');
          throw Exception('Credenciais inválidas');
        } else {
          print('❌ Erro no servidor: ${response.statusCode}');
          throw Exception('Erro no servidor: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Exceção no login: $e');
        if (e.toString().contains('TimeoutException')) {
          throw Exception('Servidor demorando para responder. Aguarde e tente novamente.');
        }
        rethrow;
      }
    });
  }

  static Future<List<dynamic>> getProdutos(String token) async {
    return _retryRequest(() async {
      if (kDebugMode) {
        print('📡 Buscando produtos...');
        print('🔑 Token: ${token.substring(0, min(20, token.length))}...');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/produtos'),
        headers: _getHeaders(token),
      ).timeout(ApiConfig.timeout);

      if (kDebugMode) {
        print('📥 Resposta produtos - Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        return _decodeResponse(response);
      } else if (response.statusCode == 401) {
        print('❌ Token inválido ou expirado (401)');
        throw Exception('401');
      } else {
        throw Exception('Erro ao buscar produtos');
      }
    });
  }

  static Future<Map<String, dynamic>> getProdutoPorCodigoBarras(
    String token,
    String codigoBarras,
  ) async {
    return _retryRequest(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/produtos/barcode/$codigoBarras'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return _decodeResponse(response);
      } else if (response.statusCode == 404) {
        throw Exception('Produto não encontrado com este código de barras');
      } else {
        throw Exception('Erro ao buscar produto');
      }
    });
  }

  static Future<Map<String, dynamic>> criarProduto(
    String token,
    String nome,
    String unidade,
    double custo,
    double preco,
    double estoqueAtual, {
    String? dataValidade,
    String? codigoBarras,
  }) async {
    return _retryRequest(() async {
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
      
      if (codigoBarras != null && codigoBarras.isNotEmpty) {
        body['codigo_barras'] = codigoBarras;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/produtos'),
        headers: _getHeaders(token),
        body: _encodeBody(body),
      ).timeout(ApiConfig.timeout);

      if (kDebugMode) {
        print('📥 Resposta criar produto - Status: ${response.statusCode}');
        print('   Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = _decodeResponse(response);
        return decoded is Map<String, dynamic> ? decoded : {'success': true};
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'Sem detalhes';
        throw Exception('Erro ao criar produto: ${response.statusCode} - $errorBody');
      }
    });
  }

  static Future<Map<String, dynamic>> atualizarProduto(
    String token,
    int produtoId,
    String nome,
    String unidade,
    double preco, {
    String? dataValidade,
    String? codigoBarras,
  }) async {
    return _retryRequest(() async {
      final body = {
        'nome': nome,
        'unidade': unidade,
        'preco_venda': preco,
      };
      
      if (dataValidade != null) {
        body['data_validade'] = dataValidade;
      }
      
      if (codigoBarras != null && codigoBarras.isNotEmpty) {
        body['codigo_barras'] = codigoBarras;
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
    });
  }

  static Future<Map<String, dynamic>> deletarProduto(
    String token,
    int produtoId,
  ) async {
    return _retryRequest(() async {
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
    });
  }

  static Future<Map<String, dynamic>> registrarMovimentacao(
    String token,
    int produtoId,
    String tipo,
    double quantidade, {
    double? custoUnitario,
    String? formaPagamento,
    String? lote,
    String? validade,
  }) async {
    return _retryRequest(() async {
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

      if (lote != null && lote.isNotEmpty) {
        body['lote'] = lote;
      }

      if (validade != null && validade.isNotEmpty) {
        body['validade'] = validade;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/movimentacoes'),
        headers: _getHeaders(token),
        body: _encodeBody(body),
      ).timeout(ApiConfig.timeout);

      if (kDebugMode) {
        print('📥 Resposta registrar movimentação - Status: ${response.statusCode}');
        print('   Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = _decodeResponse(response);
        return decoded is Map<String, dynamic> ? decoded : {'success': true};
      } else {
        try {
          final error = _decodeResponse(response);
          throw Exception(error['detail'] ?? 'Erro ao registrar movimentação');
        } catch (e) {
          throw Exception('Erro ao registrar movimentação: ${response.statusCode}');
        }
      }
    });
  }

  static Future<Map<String, dynamic>> criarMovimentacao(
    String token,
    int produtoId,
    double quantidade,
    double valorUnitario,
    String tipo,
    String? observacao,
  ) async {
    return _retryRequest(() async {
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
    });
  }

  static Future<Map<String, dynamic>> getRelatorioLucro(
    String token,
    String? dataInicio,
    String? dataFim,
  ) async {
    return _retryRequest(() async {
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
    });
  }

  static Future<List<dynamic>> getMovimentacoes(String token) async {
    return _retryRequest(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/movimentacoes'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return _decodeResponse(response);
      } else {
        throw Exception('Erro ao buscar movimentações');
      }
    });
  }

  static Future<Map<String, dynamic>> cancelarMovimentacao(
    String token,
    int movimentacaoId,
  ) async {
    return _retryRequest(() async {
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
    });
  }

  // ========== USUÁRIOS ==========

  static Future<List<dynamic>> getUsuarios(String token) async {
    return _retryRequest(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return _decodeResponse(response);
      } else {
        throw Exception('Erro ao buscar usuários');
      }
    });
  }

  static Future<Map<String, dynamic>> criarUsuario(
    String token,
    String nome,
    String login,
    String senha,
    String perfil,
  ) async {
    return _retryRequest(() async {
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
    });
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
    return _retryRequest(() async {
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
    });
  }

  static Future<Map<String, dynamic>> deletarUsuario(
    String token,
    int usuarioId,
  ) async {
    return _retryRequest(() async {
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
    });
  }

  static Future<Map<String, dynamic>> toggleAtivoUsuario(
    String token,
    int usuarioId,
  ) async {
    return _retryRequest(() async {
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
    });
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
      
      // Download de relatório (funcionalidade web desabilitada para mobile)
      if (kIsWeb) {
        // Importação dinâmica para web
        // ignore: avoid_web_libraries_in_flutter
        // final blob = html.Blob([bytes]);
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement(href: url)
        //   ..setAttribute('download', 'relatorio_${DateTime.now().millisecondsSinceEpoch}.csv')
        //   ..click();
        // html.Url.revokeObjectUrl(url);
        print('Download de relatório disponível apenas na versão web');
      } else {
        // No mobile, funcionalidade não implementada
        print('Download de relatório não disponível no mobile');
      }
      return;
    } else {
      throw Exception('Erro ao exportar relatório');
    }
  }
}
