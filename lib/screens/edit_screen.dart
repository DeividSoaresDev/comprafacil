// screens/edit_screen.dart
// Tela de edição de produto existente

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';

class EditScreen extends StatefulWidget {
  final Produto produto;
  const EditScreen({super.key, required this.produto});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();

  late TextEditingController _nomeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _precoController;

  late String _unidadeSelecionada;
  String? _categoriaSelecionada;
  bool _salvando = false;

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
  void initState() {
    super.initState();
    // Preenche os campos com dados atuais do produto
    _nomeController =
        TextEditingController(text: widget.produto.nome);
    _quantidadeController = TextEditingController(
        text: _formatarQuantidade(widget.produto.quantidade));
    _precoController = TextEditingController(
        text: widget.produto.preco.toStringAsFixed(2).replaceAll('.', ','));
    _unidadeSelecionada = widget.produto.unidade;
    _categoriaSelecionada = widget.produto.categoria;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  String _formatarQuantidade(double q) {
    if (q == q.truncateToDouble()) return q.toInt().toString();
    return q.toString().replaceAll('.', ',');
  }

  Future<void> _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final produtoAtualizado = widget.produto.copyWith(
        nome: _nomeController.text.trim(),
        quantidade: double.parse(
            _quantidadeController.text.replaceAll(',', '.')),
        unidade: _unidadeSelecionada,
        preco: double.parse(
            _precoController.text.replaceAll(',', '.')),
        categoria: _categoriaSelecionada,
      );

      await _db.atualizarProduto(produtoAtualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Produto atualizado com sucesso!'),
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
            content: const Text('Erro ao atualizar. Tente novamente.'),
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
        title: const Text('Editar Item',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20)),
        actions: [
          // Botão de salvar rápido no AppBar
          TextButton.icon(
            onPressed: _salvando ? null : _salvarEdicao,
            icon: const Icon(Icons.save_rounded,
                color: Colors.white, size: 20),
            label: const Text('Salvar',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de informações do produto atual
              _buildInfoCard(),

              const SizedBox(height: 24),

              // ─── Nome ─────────────────────────────────
              _buildLabel('Nome do produto'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Ex: Arroz',
                  prefixIcon: Icon(Icons.label_rounded,
                      color: Color(0xFF27AE60)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o nome do produto';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─── Quantidade + Unidade ─────────────────
              _buildLabel('Quantidade'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantidadeController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d,.]')),
                      ],
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Ex: 2',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded,
                            color: Color(0xFF27AE60)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Informe a quantidade';
                        }
                        final n =
                            double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) {
                          return 'Quantidade inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unidadeSelecionada,
                          isExpanded: true,
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF888888)),
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500),
                          items: _unidades
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(
                                  () => _unidadeSelecionada = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─── Preço ────────────────────────────────
              _buildLabel('Preço (R\$)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _precoController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Ex: 25,90',
                  prefixIcon: Icon(Icons.attach_money_rounded,
                      color: Color(0xFF27AE60)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o preço';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n < 0) return 'Preço inválido';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─── Categoria ────────────────────────────
              _buildLabel('Categoria'),
              const SizedBox(height: 8),
              Container(
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
                        style: TextStyle(
                            color: Color(0xFFBBBBBB), fontSize: 15)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF888888)),
                    style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500),
                    items: _categorias
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _categoriaSelecionada = val),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Botão Atualizar ──────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvarEdicao,
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
                              'Atualizar Item',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF27AE60).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF27AE60), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Editando: ${widget.produto.nome}',
              style: const TextStyle(
                color: Color(0xFF27AE60),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
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
}