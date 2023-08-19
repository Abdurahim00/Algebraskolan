import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PopUp extends StatefulWidget {
  const PopUp({super.key});

  @override
  State<PopUp> createState() => _PopUpState();
}

class _PopUpState extends State<PopUp> {
  void _showDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("title"),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
