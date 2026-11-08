import 'package:flutter/material.dart';
import 'colors.dart';

/// Layout constants. Every gap in the app comes from here, so rhythm is
/// decided once rather than per screen.
class BloomDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter. Every top-level screen aligns to this.
  static const double gutter = 20;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusPill = 999;

  /// Flat surface. Hairline outline, no shadow — shadow is reserved for the
  /// one element allowed to cast light: Bloom's dial.
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? color,
    Color? borderColor,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: BorderSide(color: borderColor ?? BloomColors.divider, width: 1),
      ),
      child: padding != null ? Padding(padding: padding, child: child) : child,
    );
  }

  /// Uppercase group label for grouped lists (settings, sync, notes).
  static Widget groupLabel(BuildContext context, String label) {
    final p = BloomPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: p.muted, letterSpacing: 0.9),
      ),
    );
  }

  static Widget primaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    bool loading = false,
    IconData? icon,
    bool fullWidth = true,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final onFill = color == null ? scheme.onPrimary : scheme.onPrimary;

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(onFill),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: onFill),
                const SizedBox(width: 8),
              ],
              Text(label, style: TextStyle(color: onFill)),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: color == null
            ? null
            : ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: onFill,
              ),
        child: child,
      ),
    );
  }

  static Widget outlineButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    Color? borderColor,
    Color? textColor,
    bool fullWidth = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor ?? BloomColors.divider, width: 1),
          foregroundColor: textColor,
        ),
        child: icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
      ),
    );
  }

  static Widget textField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    String? label,
    IconData? icon,
    bool obscure = false,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines ?? 1,
          validator: validator,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          ),
        ),
      ],
    );
  }

  /// Empty states teach the interface rather than reporting absence.
  static Widget emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
    Color? iconColor,
  }) {
    final p = BloomPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: p.periodContainer,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(icon, size: 40, color: iconColor ?? p.period),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: p.muted),
            ),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  /// A selectable chip. `activeColor` lets a screen carry its own state
  /// vocabulary while the shape and motion stay identical everywhere.
  static Widget pillChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final p = BloomPalette.of(context);
    final accent = activeColor ?? p.period;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: p.surfaceAlt,
      selectedColor: accent.withValues(alpha: 0.16),
      side: BorderSide(
        color: selected ? accent.withValues(alpha: 0.45) : p.divider,
        width: 1,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation('wght', 600)],
        color: selected ? accent : p.inkLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      shape: const StadiumBorder(),
    );
  }
}

/// Page title block shared by every top-level screen, so headers never drift
/// apart in size, spacing or alignment.
class BloomPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const BloomPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[const SizedBox(width: 12), ...actions],
      ],
    );
  }
}

/// A grouped, inset surface — the standard container for list content.
class BloomGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const BloomGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        border: Border.all(color: p.divider, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(children: children),
      ),
    );
  }
}

/// A single metric. Value leads, label follows — never the reverse.
class BloomMetricTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const BloomMetricTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        border: Border.all(color: p.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }
}
