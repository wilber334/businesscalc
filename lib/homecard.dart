import 'package:businesscalc/company.dart';
import 'package:flutter/material.dart';

class HomeCard extends StatefulWidget {
  final Map<String, dynamic> business;
  final Function()? onDeletePressed;

  const HomeCard({
    super.key,
    required this.business,
    this.onDeletePressed,
  });

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  bool delete = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: ListTile(
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
          color: Colors.black,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.business['name'].toString().toUpperCase()),
            Text('U: ${widget.business['utilityMonth']}'),
          ],
        ),
        tileColor: Colors.blue[200],
        subtitle: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Inversión: ${widget.business['investment']}'),
                const SizedBox(width: 20.0),
                Text(
                  'Cap. Trabajo: ${widget.business['workingCapital']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Costos fijos: ${widget.business['fixedCost']}'),
                const SizedBox(width: 20.0),
                Text(
                  'Ventas ${widget.business['sales']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        trailing: delete
            ? IconButton(
                onPressed: widget.onDeletePressed,
                icon: const Icon(Icons.delete),
                color: Colors.red,
              )
            : const SizedBox(),
        onLongPress: () {
          setState(() {
            delete = !delete;
          });
        },
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Company(
                  business: widget.business,
                ),
              ));
        },
      ),
    );
  }
}
