// ignore: file_names
import 'package:flutter/material.dart';

import 'class_card.dart';

class ClassCardList extends StatelessWidget {
  final List<Map<String, String>> classesData;

  const ClassCardList({super.key, required this.classesData});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {}
        return true;
      },
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: classesData.length,
        itemBuilder: (context, index) {
          return ClassCard(
            classData: classesData[index],
          );
        },
      ),
    );
  }
}
