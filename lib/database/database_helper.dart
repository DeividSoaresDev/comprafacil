// database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/produto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'comprafacil.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS produtos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            quantidade REAL NOT NULL DEFAULT 1,
            unidade TEXT NOT NULL DEFAULT 'Unid.',
            preco REAL NOT NULL DEFAULT 0,
            comprado INTEGER NOT NULL DEFAULT 0,
            categoria TEXT
          )
        ''');
      },
    );
  }

  Future<int> inserirProduto(Produto produto) async {
    try {
      final db = await database;
      return await db.insert('produtos', produto.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Produto>> buscarTodos() async {
    try {
      final db = await database;
      final maps = await db.query('produtos', orderBy: 'nome ASC');
      return maps.map((m) => Produto.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Produto>> buscarNaoComprados() async {
    try {
      final db = await database;
      final maps = await db.query('produtos',
          where: 'comprado = ?', whereArgs: [0], orderBy: 'nome ASC');
      return maps.map((m) => Produto.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Produto>> buscarComprados() async {
    try {
      final db = await database;
      final maps = await db.query('produtos',
          where: 'comprado = ?', whereArgs: [1], orderBy: 'nome ASC');
      return maps.map((m) => Produto.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> atualizarProduto(Produto produto) async {
    try {
      final db = await database;
      return await db.update('produtos', produto.toMap(),
          where: 'id = ?', whereArgs: [produto.id]);
    } catch (e) {
      return 0;
    }
  }

  Future<int> toggleComprado(int id, int comprado) async {
    try {
      final db = await database;
      return await db.update('produtos', {'comprado': comprado},
          where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      return 0;
    }
  }

  Future<int> deletarProduto(int id) async {
    try {
      final db = await database;
      return await db.delete('produtos', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      return 0;
    }
  }

  Future<int> limparComprados() async {
    try {
      final db = await database;
      return await db.delete('produtos', where: 'comprado = ?', whereArgs: [1]);
    } catch (e) {
      return 0;
    }
  }

  Future<int> contarProdutos() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM produtos');
      return (result.first['cnt'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }
}