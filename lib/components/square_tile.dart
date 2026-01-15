import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  const SquareTile({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 228, 224, 224),
        border: Border.all(color: Colors.indigo[400]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(imagePath, height: 50, width: 50),
    );
  }
}
