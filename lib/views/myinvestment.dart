import 'package:businesscalc/database.dart';
import 'package:businesscalc/views/card/cicard.dart';
import 'package:flutter/material.dart';

class MyInvestment extends StatefulWidget {
  final Map<String, dynamic> business;
  const MyInvestment({super.key, required this.business});

  @override
  State<MyInvestment> createState() => _MyInvestmentState();
}

class _MyInvestmentState extends State<MyInvestment> {
  double sumaTotal = 0;
  updateTotalAmonut() async {
    sumaTotal = await DatabaseHelper.getTotalAmount(
        'investment', widget.business['id']);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateTotalAmonut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [const Text('Inversion'), Text(sumaTotal.toString())],
            ),
            const Row(
              children: [
                Text(
                  'Descripción',
                  style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic),
                ),
                SizedBox(
                  width: 120.0,
                ),
                Text(
                  'Monto',
                  style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic),
                )
              ],
            )
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.getInvestmentByCompany(widget.business['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error fetching data from database');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No Hay items',
              style: TextStyle(fontSize: 20.0),
            ));
          } else {
            final investment = snapshot.data!;
            return ListView.builder(
              itemCount: investment.length,
              itemBuilder: (context, index) {
                final item = investment[index];
                return CIcard(
                    items: item,
                    onDeletePressed: () async {
                      await DatabaseHelper.deleteItems(
                          'investment', item['id']);
                      await DatabaseHelper.updateSumaTotal(
                          'investment', widget.business['id'], -item['amount']);
                      updateTotalAmonut();
                    });
              },
            );
          }
        },
      ),
      floatingActionButton: InvestmentFormDialog(
          companyId: widget.business['id'],
          updateState: () {
            Future.delayed(
                const Duration(milliseconds: 100), updateTotalAmonut);
          }),
    );
  }
}

class InvestmentFormDialog extends StatelessWidget {
  final int companyId;
  final VoidCallback updateState;
  InvestmentFormDialog(
      {super.key, required this.companyId, required this.updateState});

  final GlobalKey<FormState> _investmentFormKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _investmentController = TextEditingController();

  void guardarDatos(BuildContext context) async {
    String description = _descriptionController.text;
    double amount = double.tryParse(_investmentController.text) ?? 0.0;
    await DatabaseHelper.insertInvestmet(companyId, description, amount);
    await DatabaseHelper.updateSumaTotal('investment', companyId, amount);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Agregar Inversión'),
            content: IntrinsicHeight(
              child: Form(
                key: _investmentFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, ingresa una descripción';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _investmentController,
                      decoration: const InputDecoration(labelText: 'Inversión'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, ingresa el Monto';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (_investmentFormKey.currentState!.validate()) {
                    guardarDatos(context);
                    updateState();
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
