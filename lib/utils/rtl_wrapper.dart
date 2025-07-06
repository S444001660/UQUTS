import 'package:flutter/material.dart';

class RTLWrapper extends StatelessWidget {
  final Widget child;

  const RTLWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    );
  }
}
