import 'package:flutter/material.dart';

import 'theme.dart';

/// Forms share the same reading width on phones and tablets.
class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    ),
  );
}

class PageList extends StatelessWidget {
  const PageList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => PageContent(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children,
    ),
  );
}

class PageIntro extends StatelessWidget {
  const PageIntro(this.title, this.description, {super.key});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    ),
  );
}

class StatusNotice extends StatelessWidget {
  const StatusNotice(this.text, {super.key, this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: (error ? AppColors.danger : AppColors.accent).withValues(
        alpha: .08,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.error_outline : Icons.info_outline,
          size: 18,
          color: error ? AppColors.danger : AppColors.accent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: error ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class SettingsSlider extends StatelessWidget {
  const SettingsSlider({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
  });
  final String title;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(title)),
            Text(
              '${value.round()} px',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        Slider(
          min: min,
          max: max,
          divisions: (max - min).round(),
          value: value,
          label: '${value.round()}',
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    ),
  );
}
