import 'package:businesscalc/database.dart';
import 'package:flutter/material.dart';

class InvestmentFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? data;
  final int companyId;
  final VoidCallback? onRefreshPressed;

  const InvestmentFormDialog({
    super.key,
    required this.companyId,
    this.onRefreshPressed,
    required this.isEdit,
    this.data,
  });

  @override
  State<InvestmentFormDialog> createState() => _InvestmentFormDialogState();
}

class _InvestmentFormDialogState extends State<InvestmentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _investmentController = TextEditingController();

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
      _investmentController.text = (widget.data!['amount']?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _investmentController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String description = _descriptionController.text.trim();
      final double amount =
          double.tryParse(_investmentController.text.trim()) ?? 0.0;

      if (widget.isEdit && widget.data != null) {
        await _updateInvestment(description, amount);
      } else {
        await _createInvestment(description, amount);
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

  Future<void> _updateInvestment(String description, double amount) async {
    final int id = widget.data!['id'];
    final double oldAmount =
        (widget.data!['amount'] as num?)?.toDouble() ?? 0.0;

    await DatabaseHelper.updateInvestment(id, description, amount);

    final double difference = amount - oldAmount;
    if (difference != 0) {
      await DatabaseHelper.updateSumaTotal(
          'investment', widget.companyId, difference);
    }
  }

  Future<void> _createInvestment(String description, double amount) async {
    await DatabaseHelper.insertInvestment(
        widget.companyId, description, amount);
    await DatabaseHelper.updateSumaTotal(
        'investment', widget.companyId, amount);
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa una descripción';
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Editar Inversión' : 'Agregar Inversión'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              validator: _validateDescription,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _investmentController,
              decoration: const InputDecoration(
                labelText: 'Monto de Inversión',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: 'S/. ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validateAmount,
              enabled: !_isLoading,
            ),
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
