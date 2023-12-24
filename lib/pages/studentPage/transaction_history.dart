import 'package:algebra/pages/studentPage/widget/date_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backend/coin_transaction.dart';
import '../../provider/transaction_provider.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Adjust font size based on screen width and orientation
    double fontSize = isLandscape ? screenWidth * 0.03 : screenWidth * 0.04;
    double subtitleFontSize =
        isLandscape ? screenWidth * 0.025 : screenWidth * 0.035;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Algebrona historik"),
      ),
      body: FutureBuilder<List<CoinTransaction>>(
        future: transactionProvider.fetchAllUserTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Ingen transaktion har skett'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                CoinTransaction transaction = snapshot.data![index];
                Color amountColor =
                    transaction.amount >= 0 ? Colors.green : Colors.red;

                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    subtitle: Row(
                      children: <Widget>[
                        const Icon(Icons.person_outline,
                            size: 16), // Teacher icon
                        const SizedBox(
                            width: 4), // Spacing between icon and text
                        Text(
                          transaction.teacherName,
                          style: TextStyle(fontSize: subtitleFontSize),
                        ),
                      ],
                    ),
                    title: Text(
                      '${transaction.amount} Algebronor',
                      style: TextStyle(
                          color: amountColor,
                          fontSize: fontSize, // Dynamic font size for title
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
