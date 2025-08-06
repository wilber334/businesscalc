import 'package:businesscalc/database.dart';
import 'package:businesscalc/views/card/cicard.dart';
import 'package:businesscalc/views/cost_form_dialog.dart';
import 'package:flutter/material.dart';

class MyCost extends StatefulWidget {
  final Map<String, dynamic> business;

  const MyCost({super.key, required this.business});

  @override
  State<MyCost> createState() => _MyCostState();
}

class _MyCostState extends State<MyCost> {
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
          'fixedCost', widget.business['id']);
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

  Future<void> _handleDeleteCost(Map<String, dynamic> item) async {
    final bool? confirm = await _showDeleteConfirmationDialog(item);
    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);

      final double amount = (item['amount'] as num).toDouble();

      await DatabaseHelper.deleteItems('fixedCost', item['id']);
      await DatabaseHelper.updateSumaTotal(
          'fixedCost', widget.business['id'], -amount);
      await DatabaseHelper.updateSumaTotal(
          'utilityMonth', widget.business['id'], amount);

      if (mounted) {
        await _loadTotalAmount();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Costo eliminado correctamente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
            const Text('¿Estás seguro de que quieres eliminar este costo?'),
            const SizedBox(height: 8),
            Text('Descripción: ${item['description'] ?? 'Sin descripción'}'),
            Text(
                'Monto: ${_formatCurrency((item['amount'] as num?)?.toDouble() ?? 0)}'),
            const SizedBox(height: 8),
            const Text(
              'Nota: Esto también actualizará la utilidad mensual.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
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

  Future<void> _showCostForm(
      {bool isEdit = false, Map<String, dynamic>? data}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CostFormDialog(
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Costos Mensuales',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
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
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatCurrency(_totalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Descripción',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  'Monto',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
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
            Icons.money_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay costos registrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar tu primer costo mensual',
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
            'Error al cargar los costos',
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

  Widget _buildCostInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.red[800],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Los costos fijos son gastos recurrentes que afectan tu utilidad mensual.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[800],
                    fontStyle: FontStyle.italic,
                  ),
            ),
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
          _buildCostInfo(),
          _buildHeader(),
          if (_error != null)
            Expanded(child: _buildErrorState())
          else
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.getCostByCompany(widget.business['id']),
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

                  final costs = snapshot.data ?? [];

                  if (costs.isEmpty) {
                    return Column(
                      children: [
                        // _buildCostInfo(),
                        Expanded(child: _buildEmptyState()),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadTotalAmount,
                    child: Column(
                      children: [
                        // _buildCostInfo(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: costs.length,
                            itemBuilder: (context, index) {
                              final cost = costs[index];
                              return CIcard(
                                opcion: 'costos',
                                items: cost,
                                onDeletePressed: () => _handleDeleteCost(cost),
                                onRefreshPressed: _loadTotalAmount,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _showCostForm(),
        tooltip: 'Agregar costo',
        backgroundColor:
            _isLoading ? Theme.of(context).colorScheme.outline : null,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
      ),
    );
  }
}
