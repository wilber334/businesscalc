import 'package:businesscalc/views/cost_form_dialog.dart';
import 'package:businesscalc/views/investment_form_dialog.dart';
import 'package:businesscalc/views/sell_form_dialog.dart';
import 'package:flutter/material.dart';

class OptionsCard extends StatefulWidget {
  final String opcion;
  final Map<String, dynamic> data;
  final Function()? onDeletePressed;
  final VoidCallback? onRefreshPressed;
  const OptionsCard(
      {super.key,
      required this.onDeletePressed,
      required this.onRefreshPressed,
      required this.data,
      required this.opcion});

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
                child: ElevatedButton.icon(
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                    onPressed: () async {
                      await widget.onDeletePressed?.call();
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'))),
            SizedBox(
              height: 2,
            ),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    style: ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(Colors.blue[800]),
                        foregroundColor:
                            const WidgetStatePropertyAll(Colors.white)),
                    onPressed: () {
                      if (widget.opcion == 'ventas') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellFormDialog(
                                isEdit: true,
                                data: widget.data,
                                companyId: widget.data['companyId'],
                                onRefreshPressed: widget.onRefreshPressed,
                              ),
                            ));
                      } else if (widget.opcion == 'inversion') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvestmentFormDialog(
                                isEdit: true,
                                data: widget.data,
                                companyId: widget.data['companyId'],
                                onRefreshPressed: widget.onRefreshPressed,
                              ),
                            ));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CostFormDialog(
                                    data: widget.data,
                                    companyId: widget.data['companyId'],
                                    onRefreshPressed: widget.onRefreshPressed,
                                    isEdit: true)));
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'))),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
            // Navigator.pop(context, true);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
