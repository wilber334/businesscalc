import 'package:flutter/material.dart';
import 'dart:math';

class Tir extends StatefulWidget {
  final double cashFlow;
  final double investment;
  const Tir({super.key, required this.cashFlow, required this.investment});

  @override
  State<Tir> createState() => _TirState();
}

class _TirState extends State<Tir> {
  final TextEditingController _periodController =
      TextEditingController(text: '1');
  String _periodType = 'años';
  double? _monthlyTir;
  double? _annualTir;
  int _totalMonths = 12;
  bool _hasChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _calculateTir(); // Calcula con valores por defecto al iniciar
  }

  void _onPeriodChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  void _calculateTir() {
    // Convertir periodo a meses
    double periodValue = double.tryParse(_periodController.text) ?? 1;
    if (_periodType == 'años') {
      _totalMonths = (periodValue * 12).round();
    } else {
      _totalMonths = periodValue.round();
    }

    // Resetear error
    _errorMessage = null;

    // Validaciones específicas
    if (widget.investment <= 0) {
      _errorMessage = 'La inversión inicial debe ser mayor a 0';
      _monthlyTir = null;
      _annualTir = null;
      setState(() {
        _hasChanges = false;
      });
      return;
    }

    if (widget.cashFlow <= 0) {
      _errorMessage = 'El flujo de caja mensual debe ser mayor a 0';
      _monthlyTir = null;
      _annualTir = null;
      setState(() {
        _hasChanges = false;
      });
      return;
    }

    // Verificar si es posible recuperar la inversión
    double totalCashFlow = widget.cashFlow * _totalMonths;
    if (totalCashFlow <= widget.investment) {
      _errorMessage =
          'El flujo de caja total (S/. ${totalCashFlow.toStringAsFixed(2)}) es insuficiente para recuperar la inversión (S/. ${widget.investment.toStringAsFixed(2)}). Necesita aumentar el período o el flujo de caja mensual.';
      _monthlyTir = null;
      _annualTir = null;
      setState(() {
        _hasChanges = false;
      });
      return;
    }

    // Calcular TIR mensual usando el método de Newton-Raphson
    _monthlyTir = _calculateIrr();

    // TIR anual = (1 + TIR mensual)^12 - 1
    if (_monthlyTir != null) {
      _annualTir = pow(1 + _monthlyTir!, 12) - 1;
    } else {
      _annualTir = null;
      _errorMessage =
          'No se pudo calcular la TIR con los datos proporcionados.';
    }

    setState(() {
      _hasChanges = false;
    });
  }

  double? _calculateIrr() {
    // Crear flujo de caja: inversión inicial negativa + flujos mensuales positivos
    List<double> cashFlows = [];
    cashFlows.add(-widget.investment); // Inversión inicial (negativa)

    for (int i = 0; i < _totalMonths; i++) {
      cashFlows.add(widget.cashFlow); // Flujos mensuales
    }

    // Método de Newton-Raphson para encontrar la TIR
    double rate = 0.01; // Estimación inicial del 1% mensual
    const int maxIterations = 1000;
    const double tolerance = 1e-6;

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      double npv = 0;
      double npvDerivative = 0;

      for (int i = 0; i < cashFlows.length; i++) {
        num factor = pow(1 + rate, i);
        npv += cashFlows[i] / factor;
        npvDerivative -= i * cashFlows[i] / (factor * (1 + rate));
      }

      if (npvDerivative.abs() < tolerance) break;

      double newRate = rate - npv / npvDerivative;

      if ((newRate - rate).abs() < tolerance) {
        return newRate;
      }

      rate = newRate;

      // Evitar tasas extremas
      if (rate < -0.99 || rate > 10) {
        return null;
      }
    }

    return rate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora TIR'),
      ),
      backgroundColor: Colors.grey[600],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de entrada
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos de Inversión',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Flujo de Caja Mensual: S/. ${widget.cashFlow.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.trending_down, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Inversión Inicial: S/. ${widget.investment.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Input de periodo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período de Evaluación',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _periodController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Período',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                              ),
                              onChanged: (value) => _onPeriodChanged(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _periodType,
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'meses', child: Text('Meses')),
                                DropdownMenuItem(
                                    value: 'años', child: Text('Años')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _periodType = value;
                                  });
                                  _onPeriodChanged();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: $_totalMonths meses',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón Calcular
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _hasChanges ? _calculateTir : null,
                          icon: const Icon(Icons.calculate),
                          label: Text(
                              _hasChanges ? 'Calcular TIR' : 'TIR Calculada'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasChanges
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Resultados TIR
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultados TIR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (_monthlyTir != null && _annualTir != null) ...[
                        // TIR Mensual
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TIR Mensual',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(_monthlyTir! * 100).toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: _monthlyTir! > 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // TIR Anual
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TIR Anual',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(_annualTir! * 100).toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: _annualTir! > 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'No se puede calcular la TIR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red[300]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _periodController.dispose();
    super.dispose();
  }
}
