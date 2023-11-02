import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../provider/transaction_provider.dart';

class TransactionWidget extends StatefulWidget {
  final bool shouldShowDonation;
  final ValueNotifier<bool> refreshNotifier;

  const TransactionWidget({
    Key? key,
    required this.shouldShowDonation,
    required this.refreshNotifier,
  }) : super(key: key);

  @override
  _TransactionWidgetState createState() => _TransactionWidgetState();
}

class _TransactionWidgetState extends State<TransactionWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false)
          .fetchAndUpdateTransactions();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Defer marking donation as shown and resetting to avoid modifying state during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (transactionProvider.latestDonationMessage.isNotEmpty &&
              !transactionProvider.hasLatestDonationBeenShown) {
            // Mark the latest donation as shown
            transactionProvider.markLatestDonationAsShown();

            // Reset the message after 4 seconds
            Future.delayed(Duration(seconds: 4), () {
              transactionProvider.resetLatestDonationMessage();
            });
          }
        });

        return ValueListenableBuilder<bool>(
          valueListenable: widget.refreshNotifier,
          builder: (context, value, child) {
            // Determine color based on the message content
            final bool isDonation =
                transactionProvider.latestDonationMessage.contains('+');
            final Color textColor = isDonation ? Colors.green : Colors.red;

            return Text(
              transactionProvider.latestDonationMessage,
              style: GoogleFonts.carterOne(fontSize: 18, color: textColor),
            );
          },
        );
      },
    );
  }
}
