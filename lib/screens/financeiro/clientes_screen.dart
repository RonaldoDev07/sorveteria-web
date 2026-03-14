import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/financeiro/cliente_model.dart';
import '../../services/financeiro/cliente_service.dart';
import '../../services/auth_service.dart';
import '../../utils/text_formatters.dart';
import 'cliente_form_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _clientes = [];
  List<Cliente> _filtrados = [];
  bool _isLoading = true;
  String? _errorMessage;
  ClienteService? _service;
  final _searchCtrl = TextEditingController();

  static const _cor = Color(0xFF1D4ED8);
  static const _gradiente = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_service == null) {
      _service = ClienteService(Provider.of<AuthService>(context, listen: false));
      _carregar();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (!mounted || _service == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final lista = await _service!.listarClientes();
      if (!mounted) return;
      setState(() {
        _clientes = lista;
        _filtrar(_searchCtrl.text);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  void _filtrar(String q) {
    setState(() {
      _filtrados = q.isEmpty
          ? List.from(_clientes)
          : _clientes
              .where((c) =>
                  c.nome.toLowerCase().contains(q.toLowerCase()) ||
                  c.cpfCnpj.contains(q))
              .toList();
    });
  }

  Future<void> _deletar(Cliente cliente) async {
    if (_service == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Excluir Cliente', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text('Deseja excluir "${cliente.nome}"?\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true && cliente.id != null) {
      try {
        await _service!.deletarCliente(cliente.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente excluído com sucesso'), backgroundColor: Colors.green),
          );
          _carregar();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _abrirFormulario([Cliente? cliente]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: cliente)),
    );
    if (resultado == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Clientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _gradiente)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _carregar, tooltip: 'Atualizar'),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou CPF/CNPJ...',
                prefixIcon: const Icon(Icons.search_rounded, color: _cor),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _searchCtrl.clear(); _filtrar(''); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _cor, width: 2),
                ),
              ),
            ),
          ),
          // Contador
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_filtrados.length} cliente${_filtrados.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          // Conteúdo
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: _cor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Erro ao carregar clientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty ? 'Nenhum resultado encontrado' : 'Nenhum cliente cadastrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Tente buscar por outro termo'
                  : 'Comece adicionando seu primeiro cliente',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            if (_searchCtrl.text.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Cadastrar Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filtrados.length,
        itemBuilder: (context, index) => _ClienteCard(
          cliente: _filtrados[index],
          onEditar: () => _abrirFormulario(_filtrados[index]),
          onDeletar: () => _deletar(_filtrados[index]),
        ),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  const _ClienteCard({
    required this.cliente,
    required this.onEditar,
    required this.onDeletar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              cliente.nome[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          cliente.nome,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1F2937)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(icon: Icons.badge_outlined, text: formatarCpfCnpj(cliente.cpfCnpj)),
              if (cliente.telefone != null)
                _InfoRow(icon: Icons.phone_outlined, text: formatarTelefone(cliente.telefone!)),
              if (cliente.createdAt != null)
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: 'Cadastrado em ${formatarDataHora(cliente.createdAt!)}',
                  small: true,
                ),
            ],
          ),
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'editar',
              child: Row(children: [
                const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 12),
                const Text('Editar'),
              ]),
            ),
            PopupMenuItem(
              value: 'excluir',
              child: Row(children: [
                const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                const SizedBox(width: 12),
                const Text('Excluir', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
          onSelected: (v) {
            if (v == 'editar') onEditar();
            else if (v == 'excluir') onDeletar();
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool small;

  const _InfoRow({required this.icon, required this.text, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: small ? 11 : 13, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
