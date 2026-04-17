import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealioColors {
  static const primary      = Color(0xFF5BAD8F);
  static const primaryDark  = Color(0xFF3D8A6E);
  static const primaryLight = Color(0xFFD6F0E4);
  static const primaryMid   = Color(0xFF8FC9AE);
  static const bg           = Color(0xFFF2FBF6);
  static const bgCard       = Color(0xFFFFFFFF);
  static const bgInput      = Color(0xFFEBF7F1);
  static const accent       = Color(0xFFF4A26D);
  static const accentLight  = Color(0xFFFDF0E7);
  static const textDark     = Color(0xFF1E3A2F);
  static const textMid      = Color(0xFF4A7060);
  static const textLight    = Color(0xFF8AB5A0);
  static const success      = Color(0xFF4CAF79);
  static const error        = Color(0xFFE57373);
  static const online       = Color(0xFF66BB6A);
  static const border       = Color(0xFFD8EEE4);
}

ThemeData healioTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: HealioColors.bg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: HealioColors.primary,
    brightness: Brightness.light,
    error: HealioColors.error,
    background: HealioColors.bg,
    surface: HealioColors.bgCard,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: HealioColors.bgCard,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: HealioColors.textDark,
    ),
    iconTheme: const IconThemeData(color: HealioColors.textDark),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: HealioColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: HealioColors.bgInput,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealioColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealioColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
          color: HealioColors.primary, width: 2),
    ),
    hintStyle: GoogleFonts.poppins(
      fontSize: 14,
      color: HealioColors.textLight,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  ),
);

// Stethoscope painter
class StethoscopeIcon extends StatelessWidget {
  final double size;
  final Color color;
  const StethoscopeIcon({
    super.key,
    this.size = 40,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StethoPainter(color),
    );
  }
}

class _StethoPainter extends CustomPainter {
  final Color color;
  const _StethoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    final leftPath = Path()
      ..moveTo(w * 0.28, h * 0.10)
      ..lineTo(w * 0.28, h * 0.42)
      ..arcToPoint(
        Offset(w * 0.50, h * 0.62),
        radius: Radius.circular(w * 0.22),
        clockwise: true,
      );
    canvas.drawPath(leftPath, p);

    final rightPath = Path()
      ..moveTo(w * 0.72, h * 0.10)
      ..lineTo(w * 0.72, h * 0.42)
      ..arcToPoint(
        Offset(w * 0.50, h * 0.62),
        radius: Radius.circular(w * 0.22),
        clockwise: false,
      );
    canvas.drawPath(rightPath, p);

    final tubePath = Path()
      ..moveTo(w * 0.50, h * 0.62)
      ..lineTo(w * 0.50, h * 0.75)
      ..arcToPoint(
        Offset(w * 0.65, h * 0.75),
        radius: Radius.circular(w * 0.075),
        clockwise: false,
      )
      ..lineTo(w * 0.65, h * 0.68);
    canvas.drawPath(tubePath, p);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(w * 0.65, h * 0.63), w * 0.09, fill);
    canvas.drawCircle(
        Offset(w * 0.28, h * 0.09), w * 0.045, fill);
    canvas.drawCircle(
        Offset(w * 0.72, h * 0.09), w * 0.045, fill);
  }

  @override
  bool shouldRepaint(_StethoPainter old) => old.color != color;
}

// Logo widget
class HealioLogo extends StatelessWidget {
  final double size;
  const HealioLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: HealioColors.primary,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: HealioColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: StethoscopeIcon(
          size: size * 0.56,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Reusable error banner
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: HealioColors.error.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            color: HealioColors.error, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: HealioColors.error, fontSize: 13)),
        ),
      ]),
    );
  }
}

// Reusable spinner
class BtnSpinner extends StatelessWidget {
  const BtnSpinner({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22, height: 22,
    child: CircularProgressIndicator(
        color: Colors.white, strokeWidth: 2.5),
  );
}