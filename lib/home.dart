import 'package:businesscalc/database.dart';
import 'package:businesscalc/homecard.dart';
import 'package:businesscalc/my_drawer.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;
  const MyHomePage(
      {super.key, required this.onThemeToggle, required this.currentThemeMode});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Calc'),
      ),
      drawer: MyDrawer(
        onThemeToggle: widget.onThemeToggle,
        currentThemeMode: widget.currentThemeMode,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.getCompanies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Text('Error fetching data from database');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up_outlined,
                      size: 100.0, color: Colors.blueGrey),
                  Text(
                    'No Hay Proyectos\n Crea tu primer proyecto\n tocando el botón +',
                    style: TextStyle(fontSize: 20.0),
                    textAlign: TextAlign.center,
                  ),
                ],
              ));
            } else {
              final companies = snapshot.data!;
              return ListView.builder(
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  return HomeCard(
                    business: company,
                    onDeletePressed: () async {
                      await DatabaseHelper.deleteCompany(company['id']);
                      setState(() {});
                    },
                    onUpdated: () {
                      setState(() {}); // Refresca la pantalla cuando se edita
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: CompanyFormDialog(
        updateState: () {
          setState(() {});
        },
      ),
    );
  }
}

class CompanyFormDialog extends StatelessWidget {
  final VoidCallback updateState;

  CompanyFormDialog({super.key, required this.updateState});
  final TextEditingController _companyController = TextEditingController();

  void guardarNuevaEmpresa(BuildContext context) async {
    String companyName = _companyController.text;
    await DatabaseHelper.insertCompany(companyName);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Agregar Proyecto'),
            content: TextField(
              keyboardType: TextInputType.text,
              controller: _companyController,
              decoration:
                  const InputDecoration(labelText: 'Nombre del Proyecto'),
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
                  guardarNuevaEmpresa(context);
                  Navigator.of(context).pop();
                  updateState();
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
