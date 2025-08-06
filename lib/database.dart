import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'business_calc.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE companies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            investment REAL,
            fixedCost REAL,
            sales REAL,
            workingCapital REAL,
            utilityMonth REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE investment (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            companyId INTEGER,
            description TEXT,
            amount REAL,
            FOREIGN KEY (companyId) REFERENCES companies(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE fixedCost (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            companyId INTEGER,
            description TEXT,
            amount REAL,
            FOREIGN KEY (companyId) REFERENCES companies(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            companyId INTEGER,
            quantity INTEGER,
            product TEXT,
            priceBuy REAL,
            priceSell REAL,
            totalSell REAL,
            totalBuy REAL,
            margen REAL,
            FOREIGN KEY (companyId) REFERENCES companies(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // Insertar nueva empresa
  static Future<void> insertCompany(String name) async {
    final db = await database;
    await db.insert(
      'companies',
      {
        'name': name,
        'investment': 0,
        'fixedCost': 0,
        'sales': 0,
        'workingCapital': 0,
        'utilityMonth': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Actualizar un campo de suma acumulativa
  static Future<void> updateSumaTotal(
      String field, int companyId, double amountToAdd) async {
    final db = await database;
    final current = await getTotalAmount(field, companyId);
    final newTotal = current + amountToAdd;

    await db.update(
      'companies',
      {field: newTotal},
      where: 'id = ?',
      whereArgs: [companyId],
    );
  }

  // Obtener el total acumulado de un campo (por empresa)
  static Future<double> getTotalAmount(String field, int companyId) async {
    final db = await database;
    final result = await db.query(
      'companies',
      columns: [field],
      where: 'id = ?',
      whereArgs: [companyId],
    );
    if (result.isNotEmpty) {
      return (result.first[field] ?? 0) as double;
    }
    return 0.0;
  }

  // Insertar inversión
  static Future<void> insertInvestment(
      int companyId, String description, double amount) async {
    final db = await database;
    await db.insert(
      'investment',
      {
        'companyId': companyId,
        'description': description,
        'amount': amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insertar costo fijo
  static Future<void> insertFixedCost(
      int companyId, String description, double amount) async {
    final db = await database;
    await db.insert(
      'fixedCost',
      {
        'companyId': companyId,
        'description': description,
        'amount': amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insertar venta
  static Future<void> insertSales(
    int companyId,
    int quantitySell,
    String product,
    double priceBuy,
    double priceSell,
    double totalSell,
    double totalBuy,
    double margen,
  ) async {
    final db = await database;
    await db.insert(
      'sales',
      {
        'companyId': companyId,
        'quantity': quantitySell,
        'product': product,
        'priceBuy': priceBuy,
        'priceSell': priceSell,
        'totalSell': totalSell,
        'totalBuy': totalBuy,
        'margen': margen,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener lista de empresas
  static Future<List<Map<String, dynamic>>> getCompanies() async {
    final db = await database;
    return db.query('companies');
  }

  // Obtener datos de una empresa
  static Future<Map<String, dynamic>?> getCompanyById(int companyId) async {
    final db = await database;
    final result = await db.query(
      'companies',
      where: 'id = ?',
      whereArgs: [companyId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Obtener inversiones de una empresa
  static Future<List<Map<String, dynamic>>> getInvestmentByCompany(
      int companyId) async {
    final db = await database;
    return db
        .query('investment', where: 'companyId = ?', whereArgs: [companyId]);
  }

  // Obtener costos fijos de una empresa
  static Future<List<Map<String, dynamic>>> getCostByCompany(
      int companyId) async {
    final db = await database;
    return db
        .query('fixedCost', where: 'companyId = ?', whereArgs: [companyId]);
  }

  // Obtener ventas de una empresa
  static Future<List<Map<String, dynamic>>> getSalesByCompany(
      int companyId) async {
    final db = await database;
    return db.query('sales', where: 'companyId = ?', whereArgs: [companyId]);
  }

  // Eliminar empresa y sus datos relacionados
  static Future<void> deleteCompany(int companyId) async {
    final db = await database;
    await db
        .delete('investment', where: 'companyId = ?', whereArgs: [companyId]);
    await db
        .delete('fixedCost', where: 'companyId = ?', whereArgs: [companyId]);
    await db.delete('sales', where: 'companyId = ?', whereArgs: [companyId]);
    await db.delete('companies', where: 'id = ?', whereArgs: [companyId]);
  }

  // Eliminar item por ID desde tabla genérica
  static Future<void> deleteItems(String table, int dataId) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [dataId]);
  }

  // Actualizar nombre de empresa
  static Future<void> updateCompanyName(int id, String newName) async {
    final db = await database;
    await db.update(
      'companies',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Actualizar venta existente
  static Future<void> updateSale({
    required int id,
    required int quantitySell,
    required String product,
    required double priceBuy,
    required double priceSell,
    required double totalSell,
    required double totalBuy,
    required double margen,
  }) async {
    final db = await database;
    await db.update(
      'sales',
      {
        'quantity': quantitySell,
        'product': product,
        'priceBuy': priceBuy,
        'priceSell': priceSell,
        'totalSell': totalSell,
        'totalBuy': totalBuy,
        'margen': margen,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Actualizar inversión existente
  static Future<void> updateInvestment(
      int id, String description, double amount) async {
    final db = await database;

    await db.update(
      'investment',
      {
        'description': description,
        'amount': amount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Actualizar costo fijo existente
  static Future<void> updateFixedCost(
      int id, String description, double amount) async {
    final db = await database; // Asegúrate de tener este método en tu clase

    await db.update(
      'fixedCost',
      {
        'description': description,
        'amount': amount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
