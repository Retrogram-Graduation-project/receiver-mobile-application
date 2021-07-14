import 'package:flutter/material.dart';

class SentText extends StatelessWidget {
  const SentText({
    Key key,
    @required this.sentText,
  }) : super(key: key);

  final String sentText;

  @override
  Widget build(BuildContext context) {
    return Text(sentText);
  }
}
