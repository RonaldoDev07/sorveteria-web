import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/carrinho_provider.dart';

class CarrinhoBottomSheet extends StatelessWidget {
  const CarrinhoBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final carrinho = Provider.of<CarrinhoProvider>(context);
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF9FAFB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.white,
                        size: 12),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Carrinho',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 14),
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Lista de itens
          Expanded(
            child: carrinho.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Carrinho vazio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione produtos para começar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: carrinho.itens.length,
                    itemBuilder: (context, index) {
                      final item = carrinho.itens[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nomeProduto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      formatoMoeda.format(item.precoUnitario),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.remove, size: 8),
                                      onPressed: () {
                                        carrinho.atualizarQuantidade(
                                          item.produtoId,
                                          item.quantidade - 1,
                                        );
                                      },
                                      color: Colors.red,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Text(
                                      '${item.quantidade}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add, size: 8),
                                      onPressed: () {
                                        carrinho.atualizarQuantidade(
                                          item.produtoId,
                                          item.quantidade + 1,
                                        );
                                      },
                                      color: const Color(0xFF10B981),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                formatoMoeda.format(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_rounded, size: 10),
                                  color: Colors.red,
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    carrinho.removerProduto(item.produtoId);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Footer com total
          if (!carrinho.isEmpty)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total (${carrinho.totalItens} itens)',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formatoMoeda.format(carrinho.valorTotal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                carrinho.limparCarrinho();
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 12),
                              label: const Text('Limpar', style: TextStyle(fontSize: 9)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 12),
                              label: const Text(
                                'Continuar',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
