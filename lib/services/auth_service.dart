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

  String? get token => _token;
  String? get perfil => _perfil;
  String? get username => _username;
  String? get fotoUrl => _fotoUrl;
  bool get isAuthenticated => _isAuthenticated;

  bool get isAdmin => _perfil == 'ADMIN';
  bool get isVendedor => _perfil == 'VENDEDOR';
  bool get isOperador => _perfil == 'OPERADOR';

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
  bool get canVenderVista => true;

  AuthService() {
    _loadToken();
    _startTokenCheck();
  }

  void _startTokenCheck() {
    _tokenCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_token == null && _isAuthenticated) {
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
      notifyListeners();
    } catch (e) {
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
      await ApiService.wakeUpApi();
      final response = await ApiService.login(login, senha);

      _token = response['access_token'];
      _username = response['nome'] ?? login;
      _perfil = response['perfil'];
      _fotoUrl = response['foto_url'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('perfil', _perfil!);
      await prefs.setString('username', _username!);
      if (_fotoUrl != null) {
        await prefs.setString('foto_url', _fotoUrl!);
      }

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    _token = null;
    _perfil = null;
    _username = null;
    _fotoUrl = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
