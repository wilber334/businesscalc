import 'package:businesscalc/views/card/optionscard.dart';
import 'package:flutter/material.dart';

class SaleCard extends StatelessWidget {
  final Map<String, dynamic> sales;
  final Function()? onDeletePressed;
  final Function()? onRefreshPressed;
  const SaleCard(
      {super.key,
      required this.sales,
      required this.onDeletePressed,
      required this.onRefreshPressed});
  String truncateWords(String input, int wordLimit) {
    List<String> words = input.split(' ');
    if (words.length <= wordLimit) {
      return input;
    }
    return '${words.sublist(0, wordLimit).join(' ')}...';
  }

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
          Text(sales['quantity'].toString()),
          FittedBox(
            fit: BoxFit.fitWidth,
            child: Tooltip(
                message: sales[
                    'product'], // Mostrar el nombre completo del producto en el tooltip
                child: Text(
                  truncateWords(sales['product'], 2),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )),
          ),
          Row(
            children: [
              Text(sales['priceBuy'].toString()),
              const SizedBox(
                width: 20.0,
              ),
              Text(sales['priceSell'].toString()),
              const SizedBox(
                width: 20.0,
              ),
              Text((sales['priceSell'] * sales['quantity']).toString()),
              const SizedBox(
                width: 5.0,
              ),
              IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => OptionsCard(
                        opcion: 'ventas',
                        data: sales,
                        onDeletePressed: onDeletePressed,
                        onRefreshPressed: onRefreshPressed,
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert_rounded))
            ],
          )
        ],
      ),
    );
  }
}
