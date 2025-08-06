import 'package:businesscalc/database.dart';
import 'package:flutter/material.dart';

class CostFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? data;
  final int companyId;
  final VoidCallback? onRefreshPressed;

  const CostFormDialog({
    super.key,
    required this.companyId,
    this.onRefreshPressed,
    required this.isEdit,
    this.data,
  });

  @override
  State<CostFormDialog> createState() => _CostFormDialogState();
}

class _CostFormDialogState extends State<CostFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.isEdit && widget.data != null) {
      _descriptionController.text =
          widget.data!['description']?.toString() ?? '';
      _costController.text = (widget.data!['amount']?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String description = _descriptionController.text.trim();
      final double amount = double.tryParse(_costController.text.trim()) ?? 0.0;

      if (widget.isEdit && widget.data != null) {
        await _updateCost(description, amount);
      } else {
        await _createCost(description, amount);
      }

      if (mounted) {
        if (widget.isEdit) {
          Navigator.of(context).pop(true);
          Navigator.of(context).pop(true);
          widget.onRefreshPressed?.call();
        } else {
          Navigator.of(context).pop(true);
          widget.onRefreshPressed?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateCost(String description, double amount) async {
    final int id = widget.data!['id'];
    final double oldAmount =
        (widget.data!['amount'] as num?)?.toDouble() ?? 0.0;

    await DatabaseHelper.updateFixedCost(id, description, amount);

    final double difference = amount - oldAmount;
    if (difference != 0) {
      await DatabaseHelper.updateSumaTotal(
          'fixedCost', widget.companyId, difference);
      await DatabaseHelper.updateSumaTotal(
          'utilityMonth', widget.companyId, -difference);
    }
  }

  Future<void> _createCost(String description, double amount) async {
    await DatabaseHelper.insertFixedCost(widget.companyId, description, amount);
    await DatabaseHelper.updateSumaTotal('fixedCost', widget.companyId, amount);
    await DatabaseHelper.updateSumaTotal(
        'utilityMonth', widget.companyId, -amount);
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa una descripción';
    }
    if (value.trim().length < 3) {
      return 'La descripción debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa el monto';
    }

    final double? amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Monto inválido';
    }

    if (amount <= 0) {
      return 'El monto debe ser mayor que 0';
    }

    return null;
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Los costos fijos reducen automáticamente la utilidad mensual',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isEdit ? Icons.edit : Icons.add,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(widget.isEdit ? 'Editar Costo' : 'Agregar Costo'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción del costo',
                hintText: 'Ej: Alquiler, Servicios, Salarios',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: null,
              validator: _validateDescription,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Monto mensual',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: 'S/. ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validateAmount,
              enabled: !_isLoading,
            ),
            if (widget.isEdit && widget.data != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Monto anterior: S/.${((widget.data!['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (widget.isEdit) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveData,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
