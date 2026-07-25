import 'package:flutter/material.dart';

class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ConstrainedContent({super.key, required this.child, this.maxWidth = 1000});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
