// screens/cadastro_screen.dart
// Tela de cadastro de novo produto

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();

  // Controllers
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();

  // Estado
  String _unidadeSelecionada = 'Unid.';
  String? _categoriaSelecionada;
  bool _salvando = false;

  // Opções
  final List<String> _unidades = [
    'Unid.', 'kg', 'g', 'L', 'ml', 'cx', 'pct', 'dz', 'un'
  ];

  final List<String> _categorias = [
    'Grãos',
    'Laticínios',
    'Padaria',
    'Bebidas',
    'Frutas',
    'Carnes',
    'Limpeza',
    'Higiene',
    'Outros',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final produto = Produto(
        nome: _nomeController.text.trim(),
        quantidade: double.parse(
            _quantidadeController.text.replaceAll(',', '.')),
        unidade: _unidadeSelecionada,
        preco:
            double.parse(_precoController.text.replaceAll(',', '.')),
        comprado: 0,
        categoria: _categoriaSelecionada,
      );

      await _db.inserirProduto(produto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${produto.nome} adicionado!'),
              ],
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _salvando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao salvar produto. Tente novamente.'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF27AE60),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Novo Item',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Área de imagem (decorativa) ─────────
              _buildImageArea(),

              const SizedBox(height: 24),

              // ─── Campo Nome ───────────────────────────
              _buildLabel('Nome do produto'),
              const SizedBox(height: 8),
              _buildNomeField(),

              const SizedBox(height: 20),

              // ─── Campo Quantidade + Unidade ───────────
              _buildLabel('Quantidade'),
              const SizedBox(height: 8),
              _buildQuantidadeRow(),

              const SizedBox(height: 20),

              // ─── Campo Preço ──────────────────────────
              _buildLabel('Preço (R\$)'),
              const SizedBox(height: 8),
              _buildPrecoField(),

              const SizedBox(height: 20),

              // ─── Campo Categoria ──────────────────────
              _buildLabel('Categoria'),
              const SizedBox(height: 8),
              _buildCategoriaDropdown(),

              const SizedBox(height: 32),

              // ─── Botão Salvar ─────────────────────────
              _buildBotaoSalvar(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF27AE60).withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_rounded,
            size: 42,
            color: const Color(0xFF27AE60).withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicionar imagem',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF27AE60).withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildNomeField() {
    return TextFormField(
      controller: _nomeController,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15),
      decoration: const InputDecoration(
        hintText: 'Ex: Arroz',
        hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Informe o nome do produto';
        if (v.trim().length < 2) return 'Nome muito curto';
        return null;
      },
    );
  }

  Widget _buildQuantidadeRow() {
    return Row(
      children: [
        // Campo quantidade
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _quantidadeController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Ex: 2',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe a quantidade';
              final n = double.tryParse(v.replaceAll(',', '.'));
              if (n == null || n <= 0) return 'Quantidade inválida';
              return null;
            },
          ),
        ),

        const SizedBox(width: 12),

        // Dropdown unidade
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _unidadeSelecionada,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF888888)),
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500),
                items: _unidades
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _unidadeSelecionada = val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrecoField() {
    return TextFormField(
      controller: _precoController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      style: const TextStyle(fontSize: 15),
      decoration: const InputDecoration(
        hintText: 'Ex: 25,90',
        hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
        prefixText: 'R\$ ',
        prefixStyle: TextStyle(
            color: Color(0xFF333333), fontWeight: FontWeight.w600),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Informe o preço';
        final n = double.tryParse(v.replaceAll(',', '.'));
        if (n == null || n < 0) return 'Preço inválido';
        return null;
      },
    );
  }

  Widget _buildCategoriaDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _categoriaSelecionada,
          isExpanded: true,
          hint: const Text('Selecione uma categoria',
              style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 15)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF888888)),
          style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500),
          items: _categorias
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) => setState(() => _categoriaSelecionada = val),
        ),
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _salvando ? null : _salvarProduto,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
        child: _salvando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Salvar Item',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
      ),
    );
  }
}