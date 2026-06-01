// models/produto.dart
// Modelo de dados do Produto

class Produto {
  int? id;
  String nome;
  double quantidade;
  String unidade;
  double preco;
  int comprado; // 0 = não comprado, 1 = comprado
  String? categoria;

  Produto({
    this.id,
    required this.nome,
    required this.quantidade,
    this.unidade = 'Unid.',
    required this.preco,
    this.comprado = 0,
    this.categoria,
  });

  // Converte Produto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'preco': preco,
      'comprado': comprado,
      'categoria': categoria,
    };
  }

  // Cria Produto a partir de Map (vindo do banco)
  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'],
      nome: map['nome'],
      quantidade: map['quantidade'],
      unidade: map['unidade'] ?? 'Unid.',
      preco: map['preco'],
      comprado: map['comprado'],
      categoria: map['categoria'],
    );
  }

  // Cria cópia com campos alterados
  Produto copyWith({
    int? id,
    String? nome,
    double? quantidade,
    String? unidade,
    double? preco,
    int? comprado,
    String? categoria,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      preco: preco ?? this.preco,
      comprado: comprado ?? this.comprado,
      categoria: categoria ?? this.categoria,
    );
  }
}