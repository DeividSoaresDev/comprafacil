// screens/home_screen.dart
// Tela inicial do aplicativo CompraFácil

import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  int _totalItens = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Animação de entrada
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _carregarTotal();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _carregarTotal() async {
    final total = await _db.contarProdutos();
    if (mounted) setState(() => _totalItens = total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF4),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ─── AppBar personalizada ─────────────────
                _buildAppBar(),

                // ─── Conteúdo principal ───────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Logo e título
                        _buildLogo(),

                        const SizedBox(height: 40),

                        // Cards de navegação
                        _buildMenuCard(
                          icon: Icons.list_alt_rounded,
                          titulo: 'Minha Lista',
                          subtitulo: 'Ver todos os itens',
                          badge: _totalItens > 0 ? '$_totalItens' : null,
                          rota: '/lista',
                          delay: 0,
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          icon: Icons.check_circle_rounded,
                          titulo: 'Itens Comprados',
                          subtitulo: 'Ver itens concluídos',
                          rota: '/comprados',
                          delay: 100,
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          icon: Icons.add_circle_rounded,
                          titulo: 'Novo Item',
                          subtitulo: 'Adicionar produto',
                          rota: '/cadastro',
                          delay: 200,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ─── Bottom Navigation ────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color(0xFF27AE60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            onPressed: () {},
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_rounded,
                  color: Colors.white, size: 28),
              if (_totalItens > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_totalItens',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Ícone do carrinho com fundo circular
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.2), width: 2),
          ),
          child: const Icon(
            Icons.shopping_cart_rounded,
            color: Color(0xFF27AE60),
            size: 56,
          ),
        ),

        const SizedBox(height: 20),

        // Nome do app
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Compra',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Fácil',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF27AE60),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Sua lista de compras prática e fácil!',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required String rota,
    String? badge,
    int delay = 0,
  }) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, rota);
        _carregarTotal(); // Atualiza contador ao voltar
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),

            const SizedBox(width: 16),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),

            // Seta
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFCCCCCC),
              size: 18,
            ),
          ],
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
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomNavItem(Icons.grid_view_rounded, true),
          _bottomNavItem(Icons.shopping_cart_outlined, false),
          _bottomNavItem(Icons.favorite_border_rounded, false),
        ],
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, bool ativo) {
    return IconButton(
      icon: Icon(
        icon,
        color: ativo ? const Color(0xFF27AE60) : const Color(0xFFBBBBBB),
        size: 26,
      ),
      onPressed: () {},
    );
  }
}