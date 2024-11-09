import 'package:businesscalc/database.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.business['name'].toUpperCase()),
        actions: [
          SizedBox(
              width: 80,
              child: IconButton(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.update)))
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: DatabaseHelper.getCompanyById(widget.business['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error fetching data from database');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No Hay Datos',
              style: TextStyle(fontSize: 20.0),
            ));
          } else {
            final companyData = snapshot.data!;
            return Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Inversion',
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 94, 255),
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Capital de Trabajo',
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 94, 255),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      companyData['investment'].toString(),
                      textScaler: TextScaler.linear(1.5),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      companyData['workingCapital'].toString(),
                      textScaler: TextScaler.linear(1.5),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Divider(thickness: 1, color: Colors.blue[800]),
                Center(
                    child: SizedBox(
                  width: 250.0,
                  child: Column(
                    children: [
                      const Text('Resumen Mensual',
                          style: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.w600)),
                      const Divider(
                        color: Colors.blue,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ventas',
                            textScaler: TextScaler.linear(1.5),
                          ),
                          Text(
                            companyData['sales'].toString(),
                            textScaler: TextScaler.linear(1.5),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '- Compras',
                            textScaler: TextScaler.linear(1.5),
                          ),
                          Text(
                            companyData['workingCapital'].toString(),
                            textScaler: TextScaler.linear(1.5),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.blue,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Utilidad Bruta',
                            textScaler: TextScaler.linear(1.5),
                          ),
                          Text(
                            (companyData['sales'] -
                                    companyData['workingCapital'])
                                .toString(),
                            textScaler: TextScaler.linear(1.5),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '- Costos Fijos',
                            textScaler: TextScaler.linear(1.5),
                          ),
                          Text(
                            companyData['fixedCost'].toString(),
                            textScaler: TextScaler.linear(1.5),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.blue,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Utilidad Neta',
                            textScaler: TextScaler.linear(1.5),
                            style: TextStyle(
                                color: companyData['utilityMonth'] >= 0
                                    ? Colors.blue
                                    : Colors.red),
                          ),
                          Text(
                            companyData['utilityMonth'].toString(),
                            textScaler: TextScaler.linear(1.5),
                            style: TextStyle(
                                color: companyData['utilityMonth'] >= 0
                                    ? Colors.blue
                                    : Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
                const SizedBox(
                  height: 40.0,
                ),
                const Divider(
                  thickness: 1,
                  color: Colors.blue,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MyInvestment(business: widget.business),
                                ));
                          },
                          child: const Text('Inversion')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MyCost(business: widget.business),
                                ));
                          },
                          child: const Text('Costos Fijos')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MySell(business: widget.business),
                                ));
                          },
                          child: const Text('Ventas')),
                    ]),
              ],
            );
          }
        },
      ),
    );
  }
}
