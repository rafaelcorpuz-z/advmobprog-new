import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  const CustomText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.35,
      ),
    );
  }
}
