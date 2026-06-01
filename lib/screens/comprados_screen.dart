// screens/comprados_screen.dart
// Tela com a lista de itens já comprados

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';

class CompradosScreen extends StatefulWidget {
  const CompradosScreen({super.key});

  @override
  State<CompradosScreen> createState() => _CompradosScreenState();
}

class _CompradosScreenState extends State<CompradosScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _buscaController = TextEditingController();

  List<Produto> _comprados = [];
  List<Produto> _filtrados = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarComprados();
    _buscaController.addListener(_filtrarPorBusca);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarComprados() async {
    setState(() => _carregando = true);
    final lista = await _db.buscarComprados();
    setState(() {
      _comprados = lista;
      _filtrados = lista;
      _carregando = false;
    });
  }

  void _filtrarPorBusca() {
    final busca = _buscaController.text.trim().toLowerCase();
    setState(() {
      if (busca.isEmpty) {
        _filtrados = List.from(_comprados);
      } else {
        _filtrados = _comprados
            .where((p) => p.nome.toLowerCase().contains(busca))
            .toList();
      }
    });
  }

  // Remove o status de comprado (move de volta para a lista)
  Future<void> _desmarcarComprado(Produto produto) async {
    await _db.toggleComprado(produto.id!, 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${produto.nome} movido para a lista!'),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ver lista',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/lista'),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    await _carregarComprados();
  }

  // Deleta produto dos comprados
  Future<void> _deletarProduto(Produto produto) async {
    await _db.deletarProduto(produto.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${produto.nome} removido!'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    await _carregarComprados();
  }

  // Confirma e limpa todos os comprados
  Future<void> _limparTodos() async {
    if (_comprados.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpar itens comprados',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Deseja remover todos os ${_comprados.length} itens comprados? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _db.limparComprados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lista de comprados limpa!'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      await _carregarComprados();
    }
  }

  // Calcula total gasto
  double get _totalGasto {
    return _comprados.fold(
        0.0, (soma, p) => soma + (p.preco * p.quantidade));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ─── Busca ──────────────────────────────────
          _buildBusca(),

          // ─── Card resumo ─────────────────────────────
          if (_comprados.isNotEmpty) _buildResumoCard(),

          // ─── Lista ───────────────────────────────────
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF27AE60)))
                : _filtrados.isEmpty
                    ? _buildListaVazia()
                    : _buildLista(),
          ),

          // ─── Botão Limpar ─────────────────────────────
          if (_comprados.isNotEmpty) _buildBotaoLimpar(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF27AE60),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Itens Comprados',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20)),
      actions: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: const Icon(Icons.shopping_cart_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBusca() {
    return Container(
      color: const Color(0xFF27AE60),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _buscaController,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar item...',
          hintStyle: const TextStyle(color: Color(0xFF999999)),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF999999)),
          suffixIcon: _buscaController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF999999)),
                  onPressed: () {
                    _buscaController.clear();
                    _filtrarPorBusca();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildResumoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF27AE60).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF27AE60), size: 20),
          const SizedBox(width: 8),
          Text(
            '${_comprados.length} ${_comprados.length == 1 ? 'item comprado' : 'itens comprados'}',
            style: const TextStyle(
                color: Color(0xFF27AE60),
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const Spacer(),
          Text(
            'Total: R\$ ${_totalGasto.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
                color: Color(0xFF27AE60),
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      itemCount: _filtrados.length,
      itemBuilder: (ctx, i) {
        final produto = _filtrados[i];
        return _buildProdutoCard(produto);
      },
    );
  }

  Widget _buildProdutoCard(Produto produto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox marcado
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () => _desmarcarComprado(produto),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),

          // Ícone do produto
          Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconeCategoria(produto.categoria),
              color: const Color(0xFFBBBBBB),
              size: 28,
            ),
          ),

          // Informações
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.nome,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFAAAAAA),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatarQuantidade(produto.quantidade)} ${produto.unidade}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFBBBBBB)),
                  ),
                  Text(
                    'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBBBBBB)),
                  ),
                ],
              ),
            ),
          ),

          // Botão deletar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.shade300, size: 22),
              onPressed: () => _deletarProduto(produto),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 72,
              color: const Color(0xFF27AE60).withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _buscaController.text.isNotEmpty
                ? 'Nenhum item encontrado'
                : 'Nenhum item comprado ainda',
            style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (_buscaController.text.isEmpty)
            const Text(
              'Marque itens como comprados na lista',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
        ],
      ),
    );
  }

  Widget _buildBotaoLimpar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: OutlinedButton.icon(
        onPressed: _limparTodos,
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
        label: const Text('Limpar itens comprados',
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.grid_view_rounded, false),
          _navItem(Icons.shopping_cart_outlined, false),
          _navItem(Icons.favorite_border_rounded, false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, bool ativo) {
    return IconButton(
      icon: Icon(icon,
          color: ativo
              ? const Color(0xFF27AE60)
              : const Color(0xFFBBBBBB),
          size: 26),
      onPressed: () {},
    );
  }

  String _formatarQuantidade(double q) {
    if (q == q.truncateToDouble()) return q.toInt().toString();
    return q.toString();
  }

  IconData _getIconeCategoria(String? categoria) {
    switch (categoria) {
      case 'Laticínios':
        return Icons.egg_rounded;
      case 'Padaria':
        return Icons.breakfast_dining_rounded;
      case 'Bebidas':
        return Icons.local_drink_rounded;
      case 'Limpeza':
        return Icons.cleaning_services_rounded;
      case 'Higiene':
        return Icons.soap_rounded;
      case 'Frutas':
        return Icons.apple_rounded;
      case 'Carnes':
        return Icons.set_meal_rounded;
      case 'Grãos':
        return Icons.grain_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }
}