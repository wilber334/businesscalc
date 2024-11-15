import 'package:flutter/material.dart';

class OptionsCard extends StatefulWidget {
  final Function()? onDeletePressed;
  const OptionsCard({super.key, required this.onDeletePressed});

  @override
  State<OptionsCard> createState() => _OptionsCardState();
}

class _OptionsCardState extends State<OptionsCard> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: IntrinsicHeight(
        child: Column(
          children: [
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    onPressed: () {
                      widget.onDeletePressed!();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Borrar'))),
            // SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton(
            //         style: ButtonStyle(
            //             backgroundColor:
            //                 WidgetStatePropertyAll(Colors.blue[800]),
            //             foregroundColor:
            //                 const WidgetStatePropertyAll(Colors.white)),
            //         onPressed: () {},
            //         child: const Text('Actualizar'))),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
