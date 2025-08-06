import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class Van extends StatefulWidget {
  final double cashFlow;
  final double investment;

  const Van({
    super.key,
    required this.cashFlow,
    required this.investment,
  });

  @override
  State<Van> createState() => _VanState();
}

class _VanState extends State<Van> {
  final TextEditingController _annualDiscountRateController =
      TextEditingController(text: '7.0');
  final _formKey = GlobalKey<FormState>();

  // Usando un mapa para manejar múltiples períodos de manera más escalable
  final Map<int, VanResult> _vanResults = {
    1: VanResult(),
    5: VanResult(),
  };

  double _calculatedEffectiveMonthlyRate = 0.0;
  bool _isCalculating = false;

  // 🆕 Variables para controlar el estado del botón
  String _initialRate = '7.0'; // Tasa inicial
  bool _hasRateChanged = false; // Si la tasa ha cambiado

  @override
  void initState() {
    super.initState();
    // 🆕 Configurar listener para detectar cambios en la tasa
    _annualDiscountRateController.addListener(_onRateChanged);

    // Calcular automáticamente con la tasa por defecto al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAllVanPeriods();
    });
  }

  @override
  void dispose() {
    _annualDiscountRateController.dispose();
    super.dispose();
  }

  // 🆕 Función para detectar cambios en la tasa
  void _onRateChanged() {
    final currentRate = _annualDiscountRateController.text;
    setState(() {
      _hasRateChanged = currentRate != _initialRate;
    });
  }

  /// Calcula el Valor Actual Neto usando una fórmula más eficiente
  double calculateVan({
    required double initialInvestment,
    required double monthlyCashFlow,
    required double monthlyDiscountRate,
    required int numberOfMonths,
  }) {
    if (monthlyDiscountRate <= -1.0) {
      throw ArgumentError(
          'La tasa de descuento no puede ser menor o igual a -100%');
    }

    // Si la tasa es 0, el cálculo se simplifica
    if (monthlyDiscountRate == 0) {
      return (monthlyCashFlow * numberOfMonths) - initialInvestment;
    }

    // Usar la fórmula de anualidad para mejor eficiencia
    // PV = CF * [(1 - (1 + r)^-n) / r]
    final double presentValueFactor =
        (1 - pow(1 + monthlyDiscountRate, -numberOfMonths)) /
            monthlyDiscountRate;

    return (monthlyCashFlow * presentValueFactor) - initialInvestment;
  }

  /// Genera explicación detallada basada en el resultado
  String _generateExplanation(double vanResult, int years) {
    final String period = years == 1 ? '1 año' : '$years años';
    final String amount = vanResult.abs().toStringAsFixed(2);

    if (vanResult > 0) {
      return 'VAN POSITIVO (+S/. $amount): El proyecto es RENTABLE en $period. '
          'Se recomienda ACEPTAR la inversión ya que generará valor adicional '
          'por encima del costo de capital requerido.';
    } else if (vanResult < 0) {
      return 'VAN NEGATIVO (-S/. $amount): El proyecto NO es rentable en $period. '
          'Se recomienda RECHAZAR la inversión ya que destruirá valor y no '
          'alcanzará la rentabilidad mínima requerida.';
    } else {
      return 'VAN NEUTRO (S/. 0.00): El proyecto es INDIFERENTE en $period. '
          'Solo recuperará la inversión inicial sin generar valor adicional.';
    }
  }

  /// Calcula el VAN para múltiples períodos de manera asíncrona
  Future<void> _calculateAllVanPeriods() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    try {
      final double annualRate =
          double.parse(_annualDiscountRateController.text) / 100;
      final double monthlyRate = pow(1 + annualRate, 1 / 12).toDouble() - 1;

      // Simular un pequeño delay para mostrar el indicador de carga
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _calculatedEffectiveMonthlyRate = monthlyRate * 100;

        for (int years in _vanResults.keys) {
          final int months = years * 12;
          final double van = calculateVan(
            initialInvestment: widget.investment,
            monthlyCashFlow: widget.cashFlow,
            monthlyDiscountRate: monthlyRate,
            numberOfMonths: months,
          );

          _vanResults[years] = VanResult(
            value: van,
            explanation: _generateExplanation(van, years),
            isCalculated: true,
          );
        }

        // 🆕 Actualizar la tasa inicial y resetear el estado de cambio
        _initialRate = _annualDiscountRateController.text;
        _hasRateChanged = false;
      });
    } catch (e) {
      _showErrorSnackBar('Error en el cálculo: ${e.toString()}');
      _resetResults();
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  void _resetResults() {
    setState(() {
      for (int years in _vanResults.keys) {
        _vanResults[years] = VanResult();
      }
      _calculatedEffectiveMonthlyRate = 0.0;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora VAN'),
      ),
      backgroundColor: Colors.grey[700],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProjectInfoCard(),
              const SizedBox(height: 4),
              _buildInputSection(),
              const SizedBox(height: 4),
              _buildCalculateButton(),
              const SizedBox(height: 20),
              _buildResultsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Información del Proyecto',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Inversión Inicial',
                'S/. ${widget.investment.toStringAsFixed(2)}'),
            _buildInfoRow('Flujo de Caja Mensual',
                'S/. ${widget.cashFlow.toStringAsFixed(2)}'),
            _buildInfoRow(
              'Tasa Efectiva Mensual',
              _calculatedEffectiveMonthlyRate > 0
                  ? '${_calculatedEffectiveMonthlyRate.toStringAsFixed(4)}%'
                  : 'Calculando...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parámetros de Cálculo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _annualDiscountRateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Tasa de Descuento Anual (%)',
                hintText: 'Ej: 7.5',
                prefixIcon: const Icon(Icons.percent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText:
                    'Se convertirá a tasa efectiva mensual para los cálculos',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese una tasa de descuento';
                }
                final double? rate = double.tryParse(value);
                if (rate == null) {
                  return 'Ingrese un número válido';
                }
                if (rate < 0 || rate > 100) {
                  return 'La tasa debe estar entre 0% y 100%';
                }
                return null;
              },
              // 🆕 Removido el onChanged para evitar cálculos automáticos
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton.icon(
      // 🆕 El botón se activa solo si hay cambios o está calculando
      onPressed:
          (_isCalculating || !_hasRateChanged) ? null : _calculateAllVanPeriods,
      icon: _isCalculating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.calculate),
      label: Text(_isCalculating
          ? 'Calculando...'
          : _hasRateChanged
              ? 'Calcular VAN'
              : 'VAN Calculado'),
      style: ElevatedButton.styleFrom(
        // 🆕 Color visual diferente cuando está deshabilitado
        backgroundColor: _hasRateChanged ? Colors.blue : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Resultados del Análisis',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ..._vanResults.entries.map((entry) {
          final int years = entry.key;
          final VanResult result = entry.value;
          return _buildResultCard(years, result);
        }),
      ],
    );
  }

  Widget _buildResultCard(int years, VanResult result) {
    final Color valueColor = result.isCalculated
        ? (result.value > 0
            ? Colors.green[700]!
            : result.value < 0
                ? Colors.red[700]!
                : Colors.orange[700]!)
        : Colors.grey[600]!;

    final IconData resultIcon = result.isCalculated
        ? (result.value > 0
            ? Icons.trending_up
            : result.value < 0
                ? Icons.trending_down
                : Icons.trending_flat)
        : Icons.calculate;

    return Card(
      elevation: result.isCalculated ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: result.isCalculated ? Colors.blue : Colors.grey[300]!,
            width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(resultIcon, color: valueColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'VAN a ${years == 1 ? "1 Año" : "$years Años"}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                  ),
                ),
                if (!result.isCalculated)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const Divider(height: 20),
            Text(
              result.isCalculated
                  ? 'S/. ${result.value.toStringAsFixed(2)}'
                  : 'S/. ---.--',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.explanation,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: result.isCalculated ? null : Colors.grey[600],
              ),
            ),
            if (result.isCalculated) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: valueColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Calculado con tasa efectiva mensual: ${_calculatedEffectiveMonthlyRate.toStringAsFixed(4)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: valueColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Clase para encapsular los resultados del VAN
class VanResult {
  final double value;
  final String explanation;
  final bool isCalculated;

  VanResult({
    this.value = 0.0,
    this.explanation = 'Presione "Calcular VAN" para obtener el resultado.',
    this.isCalculated = false,
  });
}
