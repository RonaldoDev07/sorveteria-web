import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _perfil;
  String? _username;
  String? _fotoUrl;
  bool _isAuthenticated = false;

  String? get token => _token;
  String? get perfil => _perfil;
  String? get username => _username;
  String? get fotoUrl => _fotoUrl;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _perfil == 'ADMIN';
  bool get isVendedor => _perfil == 'VENDEDOR';
  bool get canCadastrarProduto => _perfil == 'ADMIN' || _perfil == 'VENDEDOR';

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _perfil = prefs.getString('perfil');
    _username = prefs.getString('username');
    _fotoUrl = prefs.getString('foto_url');
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  Future<bool> login(String login, String senha) async {
    try {
      final response = await ApiService.login(login, senha);
      _token = response['access_token'];
      _username = response['nome'] ?? login;
      _perfil = response['perfil'];
      _fotoUrl = response['foto_url'];
      
      // Debug: mostrar perfil no console
      print('🔐 Login realizado:');
      print('   Nome: $_username');
      print('   Login: $login');
      print('   Perfil: $_perfil');
      print('   É Admin? ${_perfil == 'ADMIN'}');
      
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
    _token = null;
    _perfil = null;
    _username = null;
    _fotoUrl = null;
    _isAuthenticated = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpa TUDO do cache
    
    notifyListeners();
  }
}
