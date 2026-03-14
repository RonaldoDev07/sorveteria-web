import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/parcela_model.dart';
import '../../services/financeiro/parcela_service.dart';
import '../../services/auth_service.dart';
import 'parcela_detalhes_screen.dart';

class ParcelasScreen extends StatefulWidget {
  const ParcelasScreen({super.key});

  @override
  State<ParcelasScreen> createState() => _ParcelasScreenState();
}

class _ParcelasScreenState extends State<ParcelasScreen> {
  List<Parcela> _parcelas = [];
  List<Parcela> _filtradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  ParcelaService? _parcelaService;
  String? _filtroTipo;
  String? _filtroStatus;
  final _searchCtrl = TextEditingController();

  static const _cor = Color(0xFF4F46E5);
  static const _gradiente = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parcelaService == null) {
      _parcelaService = ParcelaService(Provider.of<AuthService>(context, listen: false));
      _carregar();
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtradas = _parcelas.where((p) {
        final nome = (p.clienteNome ?? p.fornecedorNome ?? '').toLowerCase();
        return nome.contains(q);
      }).toList();
    });
  }

  Future<void> _carregar() async {
    if (!mounted || _parcelaService == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final lista = await _parcelaService!.listarParcelas(tipo: _filtroTipo, status: _filtroStatus);
      if (!mounted) return;
      setState(() {
        _parcelas = lista;
        _filtrar();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _darBaixa(Parcela parcela) async {
    final valorCtrl = TextEditingController(text: parcela.saldoRestante.toStringAsFixed(2));
    String formaPagamento = 'pix';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.payment_rounded, color: Colors.green, size: 22)),
          const SizedBox(width: 12),
          const Text('Dar Baixa', style: TextStyle(fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Parcela ${parcela.numeroParcela} • Saldo: ${_fmt.format(parcela.saldoRestante)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: valorCtrl,
              decoration: InputDecoration(
                labelText: 'Valor Pago', prefixText: 'R\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              onTap: () => valorCtrl.selection = TextSelection(baseOffset: 0, extentOffset: valorCtrl.text.length),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: formaPagamento,
              decoration: InputDecoration(labelText: 'Forma de Pagamento',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                DropdownMenuItem(value: 'pix', child: Text('PIX')),
                DropdownMenuItem(value: 'cartao_debito', child: Text('Cartão Débito')),
                DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão Crédito')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferência')),
              ],
              onChanged: (v) { if (v != null) formaPagamento = v; },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final valor = double.parse(valorCtrl.text.replaceAll(',', '.'));
        await _parcelaService!.darBaixaParcela(parcela.id, valor, formaPagamento);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Baixa realizada com sucesso'), backgroundColor: Colors.green),
          );
          _carregar();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cancelar(Parcela parcela) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cancel_rounded, color: Colors.red, size: 22)),
          const SizedBox(width: 12),
          const Text('Cancelar Parcela', style: TextStyle(fontSize: 18)),
        ]),
        content: Text('${parcela.tipo == 'venda' ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}\n'
            'Valor: ${_fmt.format(parcela.valorParcela)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Não', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _parcelaService!.cancelarParcela(parcela.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parcela cancelada'), backgroundColor: Colors.green),
          );
          _carregar();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paga': return Colors.green;
      case 'atrasada': return Colors.red;
      case 'parcialmente_paga': return Colors.orange;
      default: return Colors.blue;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'paga': return 'Paga';
      case 'atrasada': return 'Atrasada';
      case 'parcialmente_paga': return 'Parcial';
      default: return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Parcelas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _gradiente)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              setState(() {
                if (v == 'todas') { _filtroTipo = null; _filtroStatus = null; }
                else if (v == 'venda' || v == 'compra') _filtroTipo = v;
                else _filtroStatus = v;
              });
              _carregar();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'todas', child: Text('Todas')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'venda', child: Text('Vendas')),
              PopupMenuItem(value: 'compra', child: Text('Compras')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
              PopupMenuItem(value: 'atrasada', child: Text('Atrasadas')),
              PopupMenuItem(value: 'paga', child: Text('Pagas')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _carregar),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Erro ao carregar parcelas',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                          style: ElevatedButton.styleFrom(backgroundColor: _cor, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente ou fornecedor...',
                          prefixIcon: const Icon(Icons.search_rounded, color: _cor),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); })
                              : null,
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cor, width: 2)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(children: [
                        Text('${_filtradas.length} parcela${_filtradas.length != 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    Expanded(
                      child: _filtradas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('Nenhuma parcela encontrada',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _carregar,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _filtradas.length,
                                itemBuilder: (context, i) => _ParcelaCard(
                                  parcela: _filtradas[i],
                                  fmt: _fmt,
                                  fmtData: _fmtData,
                                  statusColor: _statusColor(_filtradas[i].status),
                                  statusLabel: _statusLabel(_filtradas[i].status),
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => ParcelaDetalhesScreen(parcela: _filtradas[i])))
                                      .then((_) => _carregar()),
                                  onBaixa: _filtradas[i].estaPaga ? null : () => _darBaixa(_filtradas[i]),
                                  onCancelar: () => _cancelar(_filtradas[i]),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _ParcelaCard extends StatelessWidget {
  final Parcela parcela;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;
  final VoidCallback? onBaixa;
  final VoidCallback onCancelar;

  const _ParcelaCard({
    required this.parcela,
    required this.fmt,
    required this.fmtData,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
    required this.onBaixa,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final isVenda = parcela.tipo == 'venda';
    final cor = isVenda ? const Color(0xFF10B981) : const Color(0xFF9333EA);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar com número
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cor, cor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${parcela.numeroParcela}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(isVenda ? 'V' : 'C',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${isVenda ? 'Venda' : 'Compra'} - Parcela ${parcela.numeroParcela}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(isVenda ? Icons.person_outline_rounded : Icons.business_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(child: Text(parcela.nomeRelacionado,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('Venc: ${fmtData.format(parcela.dataVencimento)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(width: 10),
                        Text(fmt.format(parcela.valorParcela),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      ]),
                      if (parcela.saldoRestante > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('Saldo: ${fmt.format(parcela.saldoRestante)}',
                              style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                // Menu
                PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    if (onBaixa != null)
                      const PopupMenuItem(value: 'baixa', child: Row(children: [
                        Icon(Icons.payment_rounded, size: 20, color: Color(0xFF10B981)),
                        SizedBox(width: 12), Text('Dar Baixa'),
                      ])),
                    const PopupMenuItem(value: 'cancelar', child: Row(children: [
                      Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                      SizedBox(width: 12), Text('Cancelar', style: TextStyle(color: Colors.red)),
                    ])),
                  ],
                  onSelected: (v) {
                    if (v == 'baixa' && onBaixa != null) onBaixa!();
                    else if (v == 'cancelar') onCancelar();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
