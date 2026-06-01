// screens/lista_screen.dart
// Tela da lista de produtos com filtro, busca e ações

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';
import 'cadastro_screen.dart';
import 'edit_screen.dart';

class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _buscaController = TextEditingController();

  List<Produto> _produtos = [];
  List<Produto> _produtosFiltrados = [];
  String _filtroAtivo = 'Todos'; // 'Todos', 'Não comprados', 'Comprados'
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
    _buscaController.addListener(_filtrarPorBusca);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Carrega todos os produtos do banco
  Future<void> _carregarProdutos() async {
    setState(() => _carregando = true);
    final lista = await _db.buscarTodos();
    setState(() {
      _produtos = lista;
      _aplicarFiltro();
      _carregando = false;
    });
  }

  // Aplica o filtro de aba + busca
  void _aplicarFiltro() {
    List<Produto> base;
    switch (_filtroAtivo) {
      case 'Não comprados':
        base = _produtos.where((p) => p.comprado == 0).toList();
        break;
      case 'Comprados':
        base = _produtos.where((p) => p.comprado == 1).toList();
        break;
      default:
        base = List.from(_produtos);
    }

    final busca = _buscaController.text.trim().toLowerCase();
    if (busca.isNotEmpty) {
      base = base.where((p) => p.nome.toLowerCase().contains(busca)).toList();
    }

    _produtosFiltrados = base;
  }

  void _filtrarPorBusca() {
    setState(() => _aplicarFiltro());
  }

  // Toggle comprado/não comprado
  Future<void> _toggleComprado(Produto produto) async {
    final novoStatus = produto.comprado == 0 ? 1 : 0;
    await _db.toggleComprado(produto.id!, novoStatus);
    await _carregarProdutos();
  }

  // Confirma e deleta produto
  Future<void> _confirmarDelete(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover item',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Deseja remover "${produto.nome}" da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _db.deletarProduto(produto.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${produto.nome} removido!'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      await _carregarProdutos();
    }
  }

  // Navega para edição
  Future<void> _editarProduto(Produto produto) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditScreen(produto: produto)),
    );
    await _carregarProdutos();
  }

  // Calcula total dos itens não comprados
  double get _totalLista {
    return _produtos
        .where((p) => p.comprado == 0)
        .fold(0.0, (soma, p) => soma + (p.preco * p.quantidade));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ─── Barra de busca ──────────────────────────
          _buildBusca(),

          // ─── Filtros ─────────────────────────────────
          _buildFiltros(),

          // ─── Total estimado ──────────────────────────
          if (_produtos.isNotEmpty) _buildTotalCard(),

          // ─── Lista de produtos ────────────────────────
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF27AE60),
                    ),
                  )
                : _produtosFiltrados.isEmpty
                    ? _buildListaVazia()
                    : _buildLista(),
          ),
        ],
      ),

      // ─── FAB para adicionar novo item ─────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroScreen()),
          );
          await _carregarProdutos();
        },
        backgroundColor: const Color(0xFF27AE60),
        child: const Icon(Icons.add_rounded, size: 30),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF27AE60),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Minha Lista',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.shopping_cart_rounded,
                  color: Colors.white, size: 26),
            ),
            if (_produtos.isNotEmpty)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${_produtos.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
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
                    setState(() => _aplicarFiltro());
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

  Widget _buildFiltros() {
    final filtros = ['Todos', 'Não comprados', 'Comprados'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filtros.map((f) {
          final ativo = _filtroAtivo == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filtroAtivo = f;
                  _aplicarFiltro();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: ativo ? const Color(0xFF27AE60) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ativo
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        ativo ? FontWeight.w600 : FontWeight.w400,
                    color: ativo ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalCard() {
    final naoComprados = _produtos.where((p) => p.comprado == 0).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: Color(0xFF27AE60), size: 20),
          const SizedBox(width: 8),
          Text(
            '$naoComprados ${naoComprados == 1 ? 'item' : 'itens'} na lista',
            style: const TextStyle(
                color: Color(0xFF27AE60),
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const Spacer(),
          Text(
            'Total: R\$ ${_totalLista.toStringAsFixed(2).replaceAll('.', ',')}',
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
      itemCount: _produtosFiltrados.length,
      itemBuilder: (ctx, i) {
        final produto = _produtosFiltrados[i];
        return _buildProdutoCard(produto);
      },
    );
  }

  Widget _buildProdutoCard(Produto produto) {
    final comprado = produto.comprado == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: comprado,
                onChanged: (_) => _toggleComprado(produto),
                activeColor: const Color(0xFF27AE60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),

          // Ícone do produto
          Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconeCategoria(produto.categoria),
              color: comprado
                  ? const Color(0xFFBBBBBB)
                  : const Color(0xFF27AE60),
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // Informações
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.nome,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: comprado
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF1A1A1A),
                      decoration:
                          comprado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatarQuantidade(produto.quantidade)} ${produto.unidade}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888)),
                  ),
                  Text(
                    'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: comprado
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF27AE60),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botões de ação
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Editar
              _actionButton(
                icon: Icons.edit_rounded,
                color: const Color(0xFF27AE60),
                onTap: () => _editarProduto(produto),
              ),
              const SizedBox(width: 6),
              // Deletar
              _actionButton(
                icon: Icons.delete_rounded,
                color: Colors.red.shade400,
                onTap: () => _confirmarDelete(produto),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildListaVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 72,
              color: const Color(0xFF27AE60).withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            _buscaController.text.isNotEmpty
                ? 'Nenhum item encontrado'
                : _filtroAtivo == 'Comprados'
                    ? 'Nenhum item comprado'
                    : 'Sua lista está vazia',
            style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (_buscaController.text.isEmpty && _filtroAtivo != 'Comprados')
            const Text(
              'Adicione itens tocando no + abaixo',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
        ],
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
          _navItem(Icons.shopping_cart_rounded, true),
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

  // Formata quantidade (remove .0 se inteiro)
  String _formatarQuantidade(double q) {
    if (q == q.truncateToDouble()) return q.toInt().toString();
    return q.toString();
  }

  // Retorna ícone baseado na categoria
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