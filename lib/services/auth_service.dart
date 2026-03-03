import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _perfil;
  String? _username;
  String? _fotoUrl;
  bool _isAuthenticated = false;
  Timer? _tokenCheckTimer;

  String? get token {
    if (_token == null && kDebugMode) {
      print('⚠️ Token solicitado mas está NULL!');
    }
    return _token;
  }
  String? get perfil => _perfil;
  String? get username => _username;
  String? get fotoUrl => _fotoUrl;
  bool get isAuthenticated => _isAuthenticated;
  
  // Verificações de perfil
  bool get isAdmin => _perfil == 'ADMIN';
  bool get isVendedor => _perfil == 'VENDEDOR';
  bool get isOperador => _perfil == 'OPERADOR';
  
  // Permissões específicas
  bool get canCadastrarProduto => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canEntradaEstoque => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canAjustarEstoque => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canVenderPrazo => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canComprarPrazo => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canGerenciarClientes => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canGerenciarFornecedores => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canVerRelatorios => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';
  bool get canGerenciarUsuarios => _perfil == 'ADMIN';
  bool get canCancelarOperacoes => _perfil == 'ADMIN';
  bool get canVenderVista => true; // Todos podem vender à vista

  AuthService() {
    _loadToken();
    _startTokenCheck();
  }

  void _startTokenCheck() {
    // Verificar token a cada 30 segundos
    _tokenCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (kDebugMode) {
        print('🔍 Verificando token...');
        print('   Token: ${_token != null ? "PRESENTE" : "AUSENTE"}');
        print('   Autenticado: $_isAuthenticated');
        if (_token != null) {
          print('   Token (primeiros 20 chars): ${_token!.substring(0, _token!.length > 20 ? 20 : _token!.length)}...');
        }
      }
      
      if (_token == null && _isAuthenticated) {
        print('🚨 PROBLEMA DETECTADO: Token NULL mas isAuthenticated=true!');
        print('   Forçando logout...');
        logout();
      }
    });
  }

  @override
  void dispose() {
    _tokenCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _perfil = prefs.getString('perfil');
      _username = prefs.getString('username');
      _fotoUrl = prefs.getString('foto_url');
      _isAuthenticated = _token != null && _token!.isNotEmpty;
      
      if (kDebugMode) {
        print('📱 Token carregado: ${_token != null ? "SIM" : "NÃO"}');
        print('   Perfil: $_perfil');
        print('   Username: $_username');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao carregar token: $e');
      }
      // Em caso de erro, inicializar com valores padrão
      _token = null;
      _perfil = null;
      _username = null;
      _fotoUrl = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> login(String login, String senha) async {
    try {
      print('🔐 Iniciando login...');
      print('   Login: $login');
      
      // 🔥 ACORDAR API PRIMEIRO (Cold Start do Render)
      await ApiService.wakeUpApi();
      
      final response = await ApiService.login(login, senha);
      
      _token = response['access_token'];
      _username = response['nome'] ?? login;
      _perfil = response['perfil'];
      _fotoUrl = response['foto_url'];
      
      // Debug: Verificar token no iPhone
      print('✅ Login bem-sucedido!');
      print('   Token recebido: ${_token?.substring(0, 20)}...');
      print('   Nome: $_username');
      print('   Perfil: $_perfil');
      print('   É Admin? ${_perfil == 'ADMIN'}');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('perfil', _perfil!);
      await prefs.setString('username', _username!);
      if (_fotoUrl != null) {
        await prefs.setString('foto_url', _fotoUrl!);
      }
      
      // Verificar se salvou corretamente
      final tokenSalvo = prefs.getString('token');
      print('📱 Token salvo no SharedPreferences: ${tokenSalvo != null ? "SIM" : "NÃO"}');
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erro no login: $e');
      return false;
    }
  }

  Future<void> atualizarFoto(String fotoUrl) async {
    _fotoUrl = fotoUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_url', fotoUrl);
    notifyListeners();
  }

  Future<void> removerFoto() async {
    _fotoUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('foto_url');
    notifyListeners();
  }

  Future<void> logout() async {
    print('🚪 Fazendo logout...');
    
    try {
      // Limpar SharedPreferences PRIMEIRO
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Verificar se realmente limpou
      final tokenAposLimpar = prefs.getString('token');
      print('📱 SharedPreferences limpo! Token: ${tokenAposLimpar ?? "NULL"}');
      
      // Limpar variáveis DEPOIS
      _token = null;
      _perfil = null;
      _username = null;
      _fotoUrl = null;
      _isAuthenticated = false;
      
      print('✅ Logout completo!');
      
      // Notificar listeners para atualizar UI
      notifyListeners();
    } catch (e) {
      print('❌ Erro no logout: $e');
      // Mesmo com erro, limpar variáveis
      _token = null;
      _perfil = null;
      _username = null;
      _fotoUrl = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}
