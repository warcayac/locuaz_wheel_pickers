import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class WheelSeparators {
  final Color? textColor;
  final TextStyle? textStyle;
  /* -------------------------------------------------------------------------------------- */
  const WheelSeparators({this.textColor, this.textStyle});
  /* -------------------------------------------------------------------------------------- */
  Widget custom(String text, {double padding = 2}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Text(
        text,
        style: textStyle ?? GoogleFonts.roboto(
          color: textColor,
          fontSize: 26,
          fontWeight: FontWeight.w200,
        ),
      ),
    );
  }
  /* -------------------------------------------------------------------------------------- */
  Widget colon({double padding = 2}) => custom(':', padding: padding);
  Widget comma({double padding = 2}) => custom(',', padding: padding);
  Widget dash({double padding = 2}) => custom('-', padding: padding);
  Widget slash({double padding = 2}) => custom('/', padding: padding);
}