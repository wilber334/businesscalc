import 'package:businesscalc/views/card/optionscard.dart';
import 'package:flutter/material.dart';

class CIcard extends StatelessWidget {
  final Map<String, dynamic> items;
  final Function()? onDeletePressed;
  const CIcard({super.key, required this.items, this.onDeletePressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
      padding: const EdgeInsets.only(left: 14.0, right: 7.0),
      decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.blue),
          borderRadius: const BorderRadius.all(Radius.circular(10.0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(items['description']),
          Row(
            children: [
              Text(items['amount'].toString()),
              const SizedBox(
                width: 20.0,
              ),
              IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) =>
                            OptionsCard(onDeletePressed: onDeletePressed));
                  },
                  icon: const Icon(Icons.more_vert_rounded))
            ],
          )
        ],
      ),
    );
  }
}

// class CardDialog extends StatefulWidget {
//   final Function()? onDeletePressed;
//   const CardDialog({super.key, required this.onDeletePressed});

//   @override
//   State<CardDialog> createState() => _CardDialogState();
// }

// class _CardDialogState extends State<CardDialog> {
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       content: IntrinsicHeight(
//         child: Column(
//           children: [
//             SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                     style: const ButtonStyle(
//                       backgroundColor: MaterialStatePropertyAll(Colors.red),
//                       foregroundColor: MaterialStatePropertyAll(Colors.white),
//                     ),
//                     onPressed: () {
//                       widget.onDeletePressed!();
//                       Navigator.of(context).pop();
//                     },
//                     child: const Text('Borrar'))),
//             SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                     style: ButtonStyle(
//                         backgroundColor:
//                             MaterialStatePropertyAll(Colors.blue[800]),
//                         foregroundColor:
//                             const MaterialStatePropertyAll(Colors.white)),
//                     onPressed: () {},
//                     child: const Text('Actualizar'))),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: const Text('Cancel'),
//         ),
//       ],
//     );
//   }
// }
