import 'package:businesscalc/database.dart';
import 'package:businesscalc/homecard.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
                  child: Text(
                'No Hay Empresas',
                style: TextStyle(fontSize: 20.0),
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
            title: const Text('Agregar Empresa'),
            content: TextField(
              keyboardType: TextInputType.text,
              controller: _companyController,
              decoration:
                  const InputDecoration(labelText: 'Nombre de la Empresa'),
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
