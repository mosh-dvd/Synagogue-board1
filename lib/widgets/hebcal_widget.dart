// lib/widgets/hebcal_widget.dart
import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';

class HebcalWidget extends StatelessWidget {
  const HebcalWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jewishDate = JewishDate();

    return Text(
      jewishDate.toString(),
      style: const TextStyle(color: Colors.black87, fontSize: 24),
    );
  }
}