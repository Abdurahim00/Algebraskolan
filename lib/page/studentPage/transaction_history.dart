import 'package:algebra/page/studentPage/widget/date_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backend/coin_transaction.dart';
import '../../provider/transaction_provider.dart';

class TransactionHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text("Algebrona historik"),
      ),
      body: FutureBuilder<List<CoinTransaction>>(
        future: transactionProvider.fetchAllUserTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('Ingen transaktion har skett'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                CoinTransaction transaction = snapshot.data![index];
                Color amountColor =
                    transaction.amount >= 0 ? Colors.green : Colors.red;

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    subtitle: Row(
                      children: <Widget>[
                        Icon(Icons.person_outline, size: 16), // Teacher icon
                        SizedBox(width: 4), // Spacing between icon and text
                        Text(transaction.teacherName),
                      ],
                    ),
                    title: Text(
                      '${transaction.amount} Algebronor',
                      style: TextStyle(
                          color: amountColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    trailing: DateIcon(date: transaction.timestamp),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
