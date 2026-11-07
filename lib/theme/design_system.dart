import 'package:flutter/material.dart';
import 'colors.dart';

class BloomDesign {
  static const double xs = 6;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusPill = 999;

  static const Shadow cardShadow = Shadow(
    color: Color(0x0F000000),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.04,
    letterSpacing: -0.8,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.4,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.6,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static Widget card({required Widget child, EdgeInsetsGeometry? padding, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: BloomColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: padding != null ? Padding(padding: padding, child: child) : child,
    );
  }

  static Widget sectionHeader(BuildContext context, String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: BloomDesign.h3.copyWith(color: BloomColors.ink)),
        if (subtitle != null) ...[
          const SizedBox(height: BloomDesign.xs),
          Text(subtitle, style: BloomDesign.caption.copyWith(color: BloomColors.muted)),
        ],
        const SizedBox(height: BloomDesign.md),
      ],
    );
  }

  static Widget primaryButton({
    required String label,
    required VoidCallback onPressed,
    bool loading = false,
    IconData? icon,
    bool fullWidth = true,
  }) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: BloomDesign.xs),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );
    return SizedBox(
      height: 52,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: BloomColors.rose500,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          disabledBackgroundColor: BloomColors.rose200,
        ),
        child: child,
      ),
    );
  }

  static Widget outlineButton({
    required String label,
    required VoidCallback onPressed,
    Color? borderColor,
    Color? textColor,
    bool fullWidth = false,
  }) {
    return SizedBox(
      height: 52,
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor ?? BloomColors.divider, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          foregroundColor: textColor ?? BloomColors.ink,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  static Widget ghostButton({
    required String label,
    required VoidCallback onPressed,
    Color? color,
    bool fullWidth = false,
  }) {
    return SizedBox(
      height: 44,
      width: fullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color ?? BloomColors.rose500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          backgroundColor: (color ?? BloomColors.rose500).withValues(alpha: 0.08),
        ),
        child: Text(label),
      ),
    );
  }

  static Widget textField({
    required TextEditingController controller,
    required String hint,
    String? label,
    IconData? icon,
    bool obscure = false,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: BloomDesign.label.copyWith(color: BloomColors.inkLight)),
          const SizedBox(height: BloomDesign.xs),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          validator: validator,
          onTap: onTap,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: BloomColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: BloomColors.muted),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: BloomColors.muted) : null,
            filled: true,
            fillColor: BloomColors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: BloomColors.rose500, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
          ),
        ),
      ],
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: BloomColors.rose50, borderRadius: BorderRadius.circular(28)),
              child: Icon(icon, size: 44, color: iconColor ?? BloomColors.rose500),
            ),
            const SizedBox(height: BloomDesign.lg),
            Text(title, style: BloomDesign.h3.copyWith(color: BloomColors.ink), textAlign: TextAlign.center),
            const SizedBox(height: BloomDesign.xs),
            Text(subtitle, style: BloomDesign.bodySmall.copyWith(color: BloomColors.muted), textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: BloomDesign.xl),
              action,
            ],
          ],
        ),
      ),
    );
  }

  static Widget pillChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? BloomColors.rose500;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(radiusPill),
          border: Border.all(color: selected ? Colors.transparent : BloomColors.divider, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : BloomColors.inkLight),
        ),
      ),
    );
  }
}

class BloomStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  const BloomStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BloomDesign.card(
      padding: const EdgeInsets.all(BloomDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: BloomDesign.sm),
          ],
          Text(value, style: BloomDesign.h3.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: BloomDesign.xs),
          Text(label, style: BloomDesign.caption.copyWith(color: BloomColors.muted)),
        ],
      ),
    );
  }
}
