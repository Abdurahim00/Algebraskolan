import 'package:flutter/material.dart';

class ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;

  const ClassCard({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10.0),
      width: MediaQuery.of(context).size.width * 0.25,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Image.asset("assets/images/${classData['image']}"),
            const SizedBox(height: 10),
            Text(
              "${classData["name"]}",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.apply(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
