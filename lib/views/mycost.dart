import 'package:businesscalc/database.dart';
import 'package:businesscalc/views/card/cicard.dart';
import 'package:flutter/material.dart';

class MyCost extends StatefulWidget {
  final Map<String, dynamic> business;
  const MyCost({super.key, required this.business});

  @override
  State<MyCost> createState() => _MyCostState();
}

class _MyCostState extends State<MyCost> {
  double sumaTotal = 0;
  updateTotalAmonut() async {
    sumaTotal =
        await DatabaseHelper.getTotalAmount('fixedCost', widget.business['id']);
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
              children: [const Text('Costo Mes'), Text(sumaTotal.toString())],
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
        future: DatabaseHelper.getCostByCompany(widget.business['id']),
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
            final cost = snapshot.data!;
            return ListView.builder(
              itemCount: cost.length,
              itemBuilder: (context, index) {
                final item = cost[index];
                return CIcard(
                    items: item,
                    onDeletePressed: () async {
                      await DatabaseHelper.deleteItems('fixedCost', item['id']);
                      await DatabaseHelper.updateSumaTotal(
                          'fixedCost', widget.business['id'], -item['amount']);
                      await DatabaseHelper.updateSumaTotal('utilityMonth',
                          widget.business['id'], item['amount']);
                      updateTotalAmonut();
                    });
              },
            );
          }
        },
      ),
      floatingActionButton: CostFormDialog(
          companyId: widget.business['id'],
          updateState: () {
            Future.delayed(
                const Duration(milliseconds: 100), updateTotalAmonut);
          }),
    );
  }
}

class CostFormDialog extends StatelessWidget {
  final int companyId;
  final VoidCallback updateState;
  CostFormDialog(
      {super.key, required this.companyId, required this.updateState});
  final GlobalKey<FormState> _costFormKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  void guardarDatos(BuildContext context) async {
    String description = _descriptionController.text;
    double amount = double.tryParse(_costController.text) ?? 0.0;
    await DatabaseHelper.insertFixedCost(companyId, description, amount);
    await DatabaseHelper.updateSumaTotal('fixedCost', companyId, amount);
    await DatabaseHelper.updateSumaTotal('utilityMonth', companyId, -amount);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Agregar Costo'),
            content: IntrinsicHeight(
              child: Form(
                key: _costFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      keyboardType: TextInputType.text,
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, ingresa una Descripción';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(labelText: 'Costo'),
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
                onPressed: () {
                  if (_costFormKey.currentState!.validate()) {
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
