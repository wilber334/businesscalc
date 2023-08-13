import 'package:businesscalc/database.dart';
import 'package:businesscalc/views/card/salecard.dart';
import 'package:flutter/material.dart';

class MySell extends StatefulWidget {
  final Map<String, dynamic> business;
  const MySell({super.key, required this.business});

  @override
  State<MySell> createState() => _MySellState();
}

class _MySellState extends State<MySell> {
  double sumaTotal = 0;
  updateTotalAmonut() async {
    sumaTotal =
        await DatabaseHelper.getTotalAmount('sales', widget.business['id']);
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
              children: [const Text('Venta Mes'), Text(sumaTotal.toString())],
            ),
            const Row(
              children: [
                Text(
                  'Producto',
                  style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic),
                ),
                SizedBox(
                  width: 70.0,
                ),
                Text(
                  'PC',
                  style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic),
                ),
                SizedBox(
                  width: 30.0,
                ),
                Text(
                  'PV',
                  style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic),
                ),
                SizedBox(
                  width: 30.0,
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
        future: DatabaseHelper.getSalesByCompany(widget.business['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error fetching data from database');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No Hay Ventas',
              style: TextStyle(fontSize: 20.0),
            ));
          } else {
            final sales = snapshot.data!;
            return ListView.builder(
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final item = sales[index];
                return SaleCard(
                    sales: item,
                    onDeletePressed: () async {
                      await DatabaseHelper.deleteItems('sales', item['id']);
                      await DatabaseHelper.updateSumaTotal(
                          'sales', widget.business['id'], -item['totalSell']);
                      await DatabaseHelper.updateSumaTotal('workingCapital',
                          widget.business['id'], -item['totalBuy']);
                      await DatabaseHelper.updateSumaTotal('utilityMonth',
                          widget.business['id'], -item['margen']);
                      updateTotalAmonut();
                    });
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => SellFormDialog(
                companyId: widget.business['id'],
                updateState: () {
                  Future.delayed(
                      const Duration(milliseconds: 100), updateTotalAmonut);
                }),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SellFormDialog extends StatefulWidget {
  final int companyId;
  final VoidCallback updateState;
  const SellFormDialog(
      {super.key, required this.companyId, required this.updateState});

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
  void guardarDatos(BuildContext context) async {
    String product = _productNameController.text;
    double priceBuy = double.tryParse(_priceBuyController.text) ?? 0.0;
    double priceSell = double.tryParse(_priceSellController.text) ?? 0.0;
    int quantitySell = int.tryParse(_quantitySellController.text) ?? 0;
    if (_rotation == 'Diario') {
      quantitySell = quantitySell * 30;
    }
    double totalSell = priceSell * quantitySell;
    double totalBuy = priceBuy * quantitySell;
    double margen = totalSell - totalBuy;
    await DatabaseHelper.insertSales(widget.companyId, quantitySell, product,
        priceBuy, priceSell, totalSell, totalBuy, margen);
    await DatabaseHelper.updateSumaTotal('sales', widget.companyId, totalSell);
    await DatabaseHelper.updateSumaTotal(
        'workingCapital', widget.companyId, totalBuy);
    await DatabaseHelper.updateSumaTotal(
        'utilityMonth', widget.companyId, margen);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text('Venta'),
          DropdownButton(
            dropdownColor: Colors.blue,
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            value: _rotation,
            items: ['Mensual', 'Diario'].map((String value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _rotation = newValue!;
              });
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _sellFormKey,
          child: Column(
            children: [
              TextFormField(
                keyboardType: TextInputType.name,
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Producto'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, ingresa Producto';
                  }
                  return null;
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                controller: _priceBuyController,
                decoration: const InputDecoration(labelText: 'Precio Compra'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, ingresa el Precio de Compra';
                  }
                  return null;
                },
              ),
              TextFormField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _priceSellController,
                decoration: const InputDecoration(labelText: 'Precio Venta'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, ingresa el Precio de Venta';
                  }
                  return null;
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                controller: _quantitySellController,
                decoration: InputDecoration(labelText: 'Cantidad $_rotation'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, ingresa la Cantidad $_rotation de venta';
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
            if (_sellFormKey.currentState!.validate()) {
              guardarDatos(context);
              widget.updateState();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Ok'),
        ),
      ],
    );
  }
}
