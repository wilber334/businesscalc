import 'package:businesscalc/main.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;
  const MyDrawer(
      {super.key, required this.onThemeToggle, required this.currentThemeMode});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Business Calc',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: ThemeToggleButton(
              onPressed: widget.onThemeToggle,
              currentThemeMode: widget.currentThemeMode,
            ),
          ),
          SizedBox(
            height: 100,
          ),
          ListTile(
            leading: Icon(Icons.person_2_outlined),
            title: Text('Iniciar Sesión'),
            enabled: false,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          SizedBox(
            height: 50,
          ),
          ListTile(
            leading: Icon(Icons.sync_alt),
            title: Text('Sincronizar'),
            enabled: false,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
