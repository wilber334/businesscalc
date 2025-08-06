import 'package:businesscalc/database.dart';
import 'package:businesscalc/tir.dart';
import 'package:businesscalc/van.dart';
import 'package:businesscalc/views/mycost.dart';
import 'package:businesscalc/views/myinvestment.dart';
import 'package:businesscalc/views/mysell.dart';
import 'package:flutter/material.dart';

class Company extends StatefulWidget {
  final Map<String, dynamic> business;
  const Company({super.key, required this.business});

  @override
  State<Company> createState() => _CompanyState();
}

class _CompanyState extends State<Company> {
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    // Pequeña pausa para mostrar la animación
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.business['name'].toString().toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _isRefreshing ? null : _refreshData,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Actualizar datos',
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[500],
      body: FutureBuilder<Map<String, dynamic>?>(
        future: DatabaseHelper.getCompanyById(widget.business['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar los datos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else {
            final companyData = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFinancialOverview(companyData),
                    _buildMonthlySummary(companyData),
                    const SizedBox(height: 16),
                    _buildActionButtons(context, companyData),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFinancialOverview(Map<String, dynamic> companyData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Resumen Financiero',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Inversión',
                    companyData['investment']?.toString() ?? '0',
                    Colors.blue[100]!,
                    Colors.blue[800]!,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Capital de Trabajo',
                    companyData['workingCapital']?.toString() ?? '0',
                    Colors.green[100]!,
                    Colors.green[800]!,
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color bgColor,
      Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'S/. ${_formatCurrency(value)}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(Map<String, dynamic> companyData) {
    final sales = companyData['sales'] ?? 0;
    final workingCapital = companyData['workingCapital'] ?? 0;
    final fixedCost = companyData['fixedCost'] ?? 0;
    final grossProfit = sales - workingCapital;
    final netProfit = companyData['utilityMonth'] ?? (grossProfit - fixedCost);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Resumen Mensual',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Ventas', sales, Colors.blue[700]!),
            _buildSummaryRow('- Compras', workingCapital, Colors.orange[700]!,
                isNegative: true),
            const Divider(thickness: 2, color: Colors.blue),
            _buildSummaryRow('Utilidad Bruta', grossProfit, Colors.green[700]!),
            _buildSummaryRow('- Costos Fijos', fixedCost, Colors.red[700]!,
                isNegative: true),
            const Divider(thickness: 2, color: Colors.blue),
            _buildSummaryRow(
              'Utilidad Neta',
              netProfit,
              netProfit >= 0 ? Colors.green[700]! : Colors.red[700]!,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, dynamic value, Color color,
      {bool isNegative = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            'S/. ${_formatCurrency(value.toString())}',
            style: TextStyle(
              fontSize: isHighlight ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Map<String, dynamic> companyData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Gestión Financiera',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Icon(Icons.edit_note_outlined,
                        color: Colors.orange, size: 28),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Inversión',
                        Icons.trending_up,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MyInvestment(business: widget.business),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Costos Fijos',
                        Icons.receipt_long,
                        Colors.orange,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MyCost(business: widget.business),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Ventas',
                        Icons.point_of_sale,
                        Colors.green,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MySell(business: widget.business),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Análisis Financiero',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'VAN',
                        Icons.analytics,
                        Colors.purple,
                        // () => print(companyData),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Van(
                                cashFlow:
                                    companyData['utilityMonth']?.toDouble() ??
                                        0.0,
                                investment:
                                    companyData['investment']?.toDouble() ??
                                        0.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'TIR',
                        Icons.show_chart,
                        Colors.teal,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Tir(
                                cashFlow:
                                    companyData['utilityMonth']?.toDouble() ??
                                        0.0,
                                investment:
                                    companyData['investment']?.toDouble() ??
                                        0.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    );
  }

  String _formatCurrency(String value) {
    try {
      final number = double.parse(value.replaceAll(',', ''));
      return number.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    } catch (e) {
      return value;
    }
  }
}
