import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class EditarProdutoScreen extends StatefulWidget {
  final Map<String, dynamic> produto;

  const EditarProdutoScreen({super.key, required this.produto});

  @override
  State<EditarProdutoScreen> createState() => _EditarProdutoScreenState();
}

class _EditarProdutoScreenState extends State<EditarProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _precoController;
  late String _unidade;
  bool _isLoading = false;
  DateTime? _dataValidade; // Data de validade (opcional)

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto['nome']);
    // Formatar preço removendo zeros desnecessários
    final preco = double.parse(widget.produto['preco_venda'].toString());
    _precoController = TextEditingController(
      text: preco.toStringAsFixed(2).replaceAll('.', ','),
    );
    // Garantir que a unidade esteja em maiúsculo
    _unidade = widget.produto['unidade'].toString().toUpperCase();
    
    // Inicializar data de validade se existir
    if (widget.produto['data_validade'] != null) {
      try {
        _dataValidade = DateTime.parse(widget.produto['data_validade'].toString());
      } catch (e) {
        _dataValidade = null;
      }
    }
  }

  String _formatarNumero(dynamic valor) {
    if (valor == null) return '0';
    final numero = double.parse(valor.toString());
    // Se for número inteiro, não mostrar casas decimais
    if (numero == numero.toInt()) {
      return numero.toInt().toString();
    }
    // Senão, mostrar com até 3 casas decimais, removendo zeros à direita
    return numero.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _handleAtualizar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      if (!auth.isAdmin) {
        throw Exception('Apenas ADMIN pode editar produtos');
      }

      // Converter vírgula para ponto no preço
      final precoStr = _precoController.text.replaceAll(',', '.');
      final preco = double.parse(precoStr);

      // Formatar data de validade se existir (formato: YYYY-MM-DD)
      String? dataValidadeStr;
      if (_dataValidade != null) {
        dataValidadeStr = '${_dataValidade!.year}-${_dataValidade!.month.toString().padLeft(2, '0')}-${_dataValidade!.day.toString().padLeft(2, '0')}';
      }

      await ApiService.atualizarProduto(
        auth.token!,
        widget.produto['id'],
        _nomeController.text,
        _unidade,
        preco,
        dataValidade: dataValidadeStr,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Produto'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.indigoAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card com informações não editáveis
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.indigo.shade700,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Informações do Produto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Estoque Atual',
                          '${_formatarNumero(widget.produto['estoque_atual'])} ${widget.produto['unidade']}',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Custo Médio',
                          BrazilianFormatters.formatCurrency(widget.produto['custo_medio']),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Estoque e custo médio não podem ser editados diretamente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Campos editáveis
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Produto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _unidade,
                  decoration: InputDecoration(
                    labelText: 'Unidade',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.straighten),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'UN', child: Text('Unidade (UN)')),
                    DropdownMenuItem(value: 'KG', child: Text('Quilograma (KG)')),
                  ],
                  onChanged: (value) => setState(() => _unidade = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precoController,
                  decoration: InputDecoration(
                    labelText: 'Preço de Venda',
                    hintText: 'Ex: 6,00',
                    prefixText: 'R\$ ',
                    prefixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Quanto você vai vender',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obrigatório';
                    final valorLimpo = value!.replaceAll(',', '.');
                    final preco = double.tryParse(valorLimpo);
                    if (preco == null || preco <= 0) {
                      return 'Preço inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Campo de validade (opcional)
                InkWell(
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: _dataValidade ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 anos
                      locale: const Locale('pt', 'BR'),
                      helpText: 'Selecionar data de validade',
                      cancelText: 'Cancelar',
                      confirmText: 'OK',
                    );
                    if (data != null) {
                      setState(() => _dataValidade = data);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: _dataValidade != null ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data de Validade (opcional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dataValidade != null
                                    ? '${_dataValidade!.day.toString().padLeft(2, '0')}/${_dataValidade!.month.toString().padLeft(2, '0')}/${_dataValidade!.year}'
                                    : 'Nenhuma data selecionada',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _dataValidade != null ? Colors.black87 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_dataValidade != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () => setState(() => _dataValidade = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAtualizar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Salvar Alterações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
