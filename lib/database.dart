import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

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
          CREATE TABLE investment(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            companyId INTEGER,
            description TEXT,
            amount REAL,
            FOREIGN KEY (companyId) REFERENCES companies(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE fixedCost(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            companyId INTEGER,
            description TEXT,
            amount REAL,
            FOREIGN KEY (companyId) REFERENCES companies(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE sales(
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

  static Future<void> updateSumaTotal(
      String dataName, int companyId, double amountToAdd) async {
    final db = await database;

    // Obtener el valor actual
    final currentInvestment = await getTotalAmount(dataName, companyId);

    // Calcular el nuevo valor
    final newInvestment = currentInvestment + amountToAdd;

    // Actualizar el valor en la base de datos
    await db.update(
      'companies',
      {
        dataName: newInvestment,
      },
      where: 'id = ?',
      whereArgs: [companyId],
    );
  }

// Función auxiliar para obtener el valor de inversión actual por ID
  static Future<double> getTotalAmount(String dataName, int companyId) async {
    final db = await database;
    final results = await db.query(
      'companies',
      columns: [dataName],
      where: 'id = ?',
      whereArgs: [companyId],
    );
    if (results.isNotEmpty) {
      return results.first[dataName] as double;
    }
    return 0; // Valor predeterminado si no se encuentra la compañía
  }

  static Future<void> insertInvestmet(
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

  static Future<List<Map<String, dynamic>>> getCompanies() async {
    final db = await database;
    return db.query('companies');
  }

  static Future<Map<String, dynamic>?> getCompanyById(int companyId) async {
    final db = await database;
    final results = await db.query(
      'companies',
      where: 'id = ?',
      whereArgs: [companyId],
    );

    if (results.isNotEmpty) {
      return results.first;
    }

    return null; // Si no se encuentra la empresa
  }

  static Future<List<Map<String, dynamic>>> getInvestmentByCompany(
      int companyId) async {
    final db = await database;
    return db
        .query('investment', where: 'companyId = ?', whereArgs: [companyId]);
  }

  static Future<List<Map<String, dynamic>>> getCostByCompany(
      int companyId) async {
    final db = await database;
    return db
        .query('fixedCost', where: 'companyId = ?', whereArgs: [companyId]);
  }

  static Future<List<Map<String, dynamic>>> getSalesByCompany(
      int companyId) async {
    final db = await database;
    return db.query('sales', where: 'companyId = ?', whereArgs: [companyId]);
  }

  // static Future<List<Map<String, dynamic>>> getFixedCost() async {
  //   final db = await database;
  //   return db.query('fixedCost');
  // }

  // static Future<List<Map<String, dynamic>>> getSales() async {
  //   final db = await database;
  //   return db.query('sales');
  // }

  static Future<void> deleteCompany(int companyId) async {
    final db = await database;

    // Primero, eliminamos las inversiones asociadas a la empresa
    await db.delete(
      'investment',
      where: 'companyId = ?',
      whereArgs: [companyId],
    );
    await db.delete(
      'fixedcost',
      where: 'companyId = ?',
      whereArgs: [companyId],
    );
    await db.delete(
      'sales',
      where: 'companyId = ?',
      whereArgs: [companyId],
    );
    // Luego, eliminamos la empresa en sí
    await db.delete(
      'companies',
      where: 'id = ?',
      whereArgs: [companyId],
    );
  }

  static Future<void> deleteItems(String dataName, int dataId) async {
    final db = await database;
    await db.delete(
      dataName,
      where: 'id = ?',
      whereArgs: [dataId],
    );
  }

  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'your_database.db');
    await databaseFactory.deleteDatabase(path);
  }
}
