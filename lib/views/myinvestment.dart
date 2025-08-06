import 'package:businesscalc/database.dart';
import 'package:businesscalc/views/card/cicard.dart';
import 'package:businesscalc/views/investment_form_dialog.dart';
import 'package:flutter/material.dart';

class MyInvestment extends StatefulWidget {
  final Map<String, dynamic> business;

  const MyInvestment({super.key, required this.business});

  @override
  State<MyInvestment> createState() => _MyInvestmentState();
}

class _MyInvestmentState extends State<MyInvestment> {
  double _totalAmount = 0.0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTotalAmount();
  }

  Future<void> _loadTotalAmount() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final total = await DatabaseHelper.getTotalAmount(
          'investment', widget.business['id']);
      if (mounted) {
        setState(() {
          _totalAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar el total: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return 'S/. ${amount.toStringAsFixed(2)}';
  }

  Future<void> _handleDeleteInvestment(Map<String, dynamic> item) async {
    final bool? confirm = await _showDeleteConfirmationDialog(item);
    if (confirm != true) return;

    try {
      await DatabaseHelper.deleteItems('investment', item['id']);
      await DatabaseHelper.updateSumaTotal('investment', widget.business['id'],
          -(item['amount'] as num).toDouble());

      if (mounted) {
        _loadTotalAmount();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inversión eliminada correctamente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(Map<String, dynamic> item) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres eliminar esta inversión?'),
            const SizedBox(height: 8),
            Text('Descripción: ${item['description'] ?? 'Sin descripción'}'),
            Text(
                'Monto: ${_formatCurrency((item['amount'] as num?)?.toDouble() ?? 0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInvestmentForm(
      {bool isEdit = false, Map<String, dynamic>? data}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InvestmentFormDialog(
        isEdit: isEdit,
        data: data,
        companyId: widget.business['id'],
        onRefreshPressed: _loadTotalAmount,
      ),
    );

    if (result == true) {
      _loadTotalAmount();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inversiones',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatCurrency(_totalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Descripción',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  'Monto',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay inversiones registradas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar tu primera inversión',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar las inversiones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Ha ocurrido un error inesperado',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.business['name'].toString().toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          if (_error != null)
            Expanded(child: _buildErrorState())
          else
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.getInvestmentByCompany(
                    widget.business['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar los datos',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final investments = snapshot.data ?? [];

                  if (investments.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _loadTotalAmount,
                    child: ListView.builder(
                      itemCount: investments.length,
                      itemBuilder: (context, index) {
                        final investment = investments[index];
                        return CIcard(
                          opcion: 'inversion',
                          items: investment,
                          onDeletePressed: () =>
                              _handleDeleteInvestment(investment),
                          onRefreshPressed: _loadTotalAmount,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInvestmentForm(),
        tooltip: 'Agregar inversión',
        child: const Icon(Icons.add),
      ),
    );
  }
}
