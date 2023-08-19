import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../backend/coins_service.dart';

class CoinForm extends StatelessWidget {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _coinController = TextEditingController();
  final CoinService coinService = CoinService(FirebaseFirestore.instance);

  CoinForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _userIdController,
            decoration: const InputDecoration(
              labelText: 'Student ID',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _coinController,
            decoration: const InputDecoration(
              labelText: 'Coins',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final userId = _userIdController.text;
            final coinChange = int.tryParse(_coinController.text) ?? 0;

            if (coinChange >= 0) {
              await coinService.incrementCoins(userId, coinChange);
            } else {
              await coinService.decrementCoins(userId, -coinChange);
            }

            _userIdController.clear();
            _coinController.clear();
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
