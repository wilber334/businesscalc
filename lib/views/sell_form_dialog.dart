import 'package:businesscalc/database.dart';
import 'package:flutter/material.dart';

class SellFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? data;
  final int companyId;
  final Function()? onRefreshPressed;

  const SellFormDialog({
    super.key,
    required this.companyId,
    required this.onRefreshPressed,
    required this.isEdit,
    this.data,
  });

  @override
  State<SellFormDialog> createState() => _SellFormDialogState();
}

class _SellFormDialogState extends State<SellFormDialog> {
  final GlobalKey<FormState> _sellFormKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceBuyController = TextEditingController();
  final TextEditingController _priceSellController = TextEditingController();
  final TextEditingController _quantitySellController = TextEditingController();

  String _rotation = 'Mensual';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.data != null) {
      _productNameController.text = widget.data!['product'] ?? '';
      _priceBuyController.text = (widget.data!['priceBuy'] ?? '').toString();
      _priceSellController.text = (widget.data!['priceSell'] ?? '').toString();
      int quantity = widget.data!['quantity'] ?? 0;

      // Detectar si es diario
      if (quantity % 30 == 0) {
        _rotation = 'Diario';
        quantity = quantity ~/ 30;
      }

      _quantitySellController.text = quantity.toString();
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceBuyController.dispose();
    _priceSellController.dispose();
    _quantitySellController.dispose();
    super.dispose();
  }

  /// Guarda los datos de la venta
  Future<bool> _saveSale() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String product = _productNameController.text.trim();
      double priceBuy = double.tryParse(_priceBuyController.text.trim()) ?? 0.0;
      double priceSell =
          double.tryParse(_priceSellController.text.trim()) ?? 0.0;
      int quantitySell = int.tryParse(_quantitySellController.text.trim()) ?? 0;

      // Validaciones adicionales
      if (priceBuy <= 0) {
        _showError('El precio de compra debe ser mayor a 0');
        return false;
      }

      if (priceSell <= 0) {
        _showError('El precio de venta debe ser mayor a 0');
        return false;
      }

      if (priceSell <= priceBuy) {
        _showError('El precio de venta debe ser mayor al precio de compra');
        return false;
      }

      if (quantitySell <= 0) {
        _showError('La cantidad debe ser mayor a 0');
        return false;
      }

      // Ajustar cantidad si es diario
      if (_rotation == 'Diario') {
        quantitySell *= 30;
      }

      double totalSell = priceSell * quantitySell;
      double totalBuy = priceBuy * quantitySell;
      double margen = totalSell - totalBuy;

      if (widget.isEdit && widget.data != null) {
        // Actualizar venta existente
        double oldTotalSell = widget.data!['totalSell'] ?? 0.0;
        double oldTotalBuy = widget.data!['totalBuy'] ?? 0.0;
        double oldMargen = widget.data!['margen'] ?? 0.0;

        await DatabaseHelper.updateSale(
          id: widget.data!['id'],
          quantitySell: quantitySell,
          product: product,
          priceBuy: priceBuy,
          priceSell: priceSell,
          totalSell: totalSell,
          totalBuy: totalBuy,
          margen: margen,
        );

        // Actualizar los totales con las diferencias
        await DatabaseHelper.updateSumaTotal(
            'sales', widget.companyId, totalSell - oldTotalSell);
        await DatabaseHelper.updateSumaTotal(
            'workingCapital', widget.companyId, totalBuy - oldTotalBuy);
        await DatabaseHelper.updateSumaTotal(
            'utilityMonth', widget.companyId, margen - oldMargen);
      } else {
        // Crear nueva venta
        await DatabaseHelper.insertSales(widget.companyId, quantitySell,
            product, priceBuy, priceSell, totalSell, totalBuy, margen);
        await DatabaseHelper.updateSumaTotal(
            'sales', widget.companyId, totalSell);
        await DatabaseHelper.updateSumaTotal(
            'workingCapital', widget.companyId, totalBuy);
        await DatabaseHelper.updateSumaTotal(
            'utilityMonth', widget.companyId, margen);
      }

      return true; // Éxito
    } catch (e) {
      _showError('Error al guardar venta: $e');
      return false; // Error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Muestra un mensaje de error
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Muestra un mensaje de éxito
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Maneja el guardado y cierre del diálogo
  Future<void> _handleSave() async {
    if (!_sellFormKey.currentState!.validate()) return;

    final success = await _saveSale();

    if (success && mounted) {
      _showSuccess(widget.isEdit
          ? 'Venta actualizada exitosamente'
          : 'Venta agregada exitosamente');

      // Cerrar el diálogo retornando true para indicar éxito
      if (widget.isEdit) {
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(true);
        widget.onRefreshPressed?.call();
      } else {
        Navigator.of(context).pop(true);
        widget.onRefreshPressed?.call();
      }
    }
  }

  /// Calcula el margen de ganancia para mostrar en tiempo real
  double _calculateMargin() {
    final priceBuy = double.tryParse(_priceBuyController.text) ?? 0.0;
    final priceSell = double.tryParse(_priceSellController.text) ?? 0.0;
    final quantity = int.tryParse(_quantitySellController.text) ?? 0;

    if (priceBuy > 0 && priceSell > 0 && quantity > 0) {
      final actualQuantity = _rotation == 'Diario' ? quantity * 30 : quantity;
      return (priceSell - priceBuy) * actualQuantity;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.isEdit ? 'Editar Venta' : 'Nueva Venta'),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 0,
            ),
            child: DropdownButton<String>(
              value: _rotation,
              underline: const SizedBox(),
              items: ['Mensual', 'Diario'].map((String value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (newValue) {
                      setState(() {
                        _rotation = newValue!;
                      });
                    },
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _sellFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa el producto';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceBuyController,
                decoration: const InputDecoration(
                  labelText: 'Precio Compra',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_cart),
                  suffixText: 'S/.',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isLoading,
                onChanged: (_) => setState(() {}), // Para actualizar el margen
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el precio de compra';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Precio inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceSellController,
                decoration: const InputDecoration(
                  labelText: 'Precio Venta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell),
                  suffixText: 'S/.',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isLoading,
                onChanged: (_) => setState(() {}), // Para actualizar el margen
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el precio de venta';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Precio inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _quantitySellController,
                decoration: InputDecoration(
                  labelText: 'Cantidad $_rotation',
                  border: const OutlineInputBorder(),
                  helperText:
                      _rotation == 'Diario' ? 'Se multiplicará por 30' : null,
                ),
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
                onChanged: (_) => setState(() {}), // Para actualizar el margen
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la cantidad';
                  }
                  final quantity = int.tryParse(value.trim());
                  if (quantity == null || quantity <= 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
              if (_calculateMargin() > 0)
                Text(
                  'Margen: S/. ${_calculateMargin().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (widget.isEdit) {
                    Navigator.of(context).pop(false);
                    Navigator.of(context).pop(false);
                  } else {
                    Navigator.of(context).pop(false);
                  }
                },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEdit ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}
