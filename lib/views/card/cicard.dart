import 'package:businesscalc/views/card/optionscard.dart';
import 'package:flutter/material.dart';

class CIcard extends StatelessWidget {
  final String opcion;
  final Map<String, dynamic> items;
  final Function()? onDeletePressed;
  final Function()? onRefreshPressed;
  const CIcard(
      {super.key,
      required this.items,
      required this.opcion,
      this.onDeletePressed,
      this.onRefreshPressed});

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
                        builder: (context) => OptionsCard(
                            opcion: opcion,
                            data: items,
                            onDeletePressed: onDeletePressed,
                            onRefreshPressed: onRefreshPressed));
                  },
                  icon: const Icon(Icons.more_vert_rounded))
            ],
          )
        ],
      ),
    );
  }
}
