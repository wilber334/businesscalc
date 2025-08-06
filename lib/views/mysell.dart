import 'package:businesscalc/database.dart';
import 'package:businesscalc/views/card/salecard.dart';
import 'package:businesscalc/views/sell_form_dialog.dart';
import 'package:flutter/material.dart';

class MySell extends StatefulWidget {
  final Map<String, dynamic> business;

  const MySell({super.key, required this.business});

  @override
  State<MySell> createState() => _MySellState();
}

class _MySellState extends State<MySell> {
  double _totalAmount = 0;
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carga los datos iniciales
  Future<void> _loadData() async {
    await _updateData();
  }

  /// Actualiza tanto el total como la lista de ventas
  Future<void> _updateData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        DatabaseHelper.getTotalAmount('sales', widget.business['id']),
        DatabaseHelper.getSalesByCompany(widget.business['id']),
      ]);

      if (mounted) {
        setState(() {
          _totalAmount = results[0] as double;
          _sales = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar datos: $e';
        });
        _showErrorSnackBar('Error al actualizar datos: $e');
      }
    }
  }

  /// Maneja la eliminación de una venta
  Future<void> _handleDeleteSale(Map<String, dynamic> sale) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    try {
      await _deleteSaleTransaction(sale);
      await _updateData();

      if (mounted) {
        _showSuccessSnackBar('Venta eliminada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al eliminar venta: $e');
      }
    }
  }

  /// Elimina una venta y actualiza las tablas relacionadas
  Future<void> _deleteSaleTransaction(Map<String, dynamic> sale) async {
    final saleId = sale['id'];
    final companyId = widget.business['id'];
    final totalSell = sale['totalSell'] ?? 0;
    final totalBuy = sale['totalBuy'] ?? 0;
    final margin = sale['margen'] ?? 0;

    // Realizar todas las operaciones de base de datos
    await Future.wait([
      DatabaseHelper.deleteItems('sales', saleId),
      DatabaseHelper.updateSumaTotal('sales', companyId, -totalSell),
      DatabaseHelper.updateSumaTotal('workingCapital', companyId, -totalBuy),
      DatabaseHelper.updateSumaTotal('utilityMonth', companyId, -margin),
    ]);
  }

  /// Muestra el diálogo de confirmación para eliminar
  Future<bool> _showDeleteConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Maneja la apertura del diálogo de nueva venta
  Future<void> _handleAddSale() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SellFormDialog(
        isEdit: false,
        companyId: widget.business['id'],
        onRefreshPressed: _updateData,
      ),
    );

    if (result == true) {
      await _updateData();
    }
  }

  /// Muestra un SnackBar de error
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Muestra un SnackBar de éxito
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Construye el AppBar con el total y los headers
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text('Venta Mes'),
              Text(
                _totalAmount.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Text('Producto', style: _headerTextStyle),
              SizedBox(width: 70.0),
              Text('PC', style: _headerTextStyle),
              SizedBox(width: 30.0),
              Text('PV', style: _headerTextStyle),
              SizedBox(width: 30.0),
              Text('Monto', style: _headerTextStyle),
            ],
          )
        ],
      ),
    );
  }

  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_sales.isEmpty) {
      return _buildEmptyView();
    }

    return _buildSalesList();
  }

  /// Construye la vista de error
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Error desconocido'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _updateData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Construye la vista cuando no hay ventas
  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay ventas registradas',
            style: TextStyle(fontSize: 18.0, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Presiona + para agregar una venta',
            style: TextStyle(fontSize: 14.0, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de ventas
  Widget _buildSalesList() {
    return RefreshIndicator(
      onRefresh: _updateData,
      child: ListView.builder(
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          final sale = _sales[index];
          return SaleCard(
            sales: sale,
            onDeletePressed: () => _handleDeleteSale(sale),
            onRefreshPressed: _updateData,
          );
        },
      ),
    );
  }

  /// Construye el botón flotante
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _isLoading ? null : _handleAddSale,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add),
    );
  }

  static const TextStyle _headerTextStyle = TextStyle(
    fontSize: 12.0,
    fontStyle: FontStyle.italic,
  );
}
