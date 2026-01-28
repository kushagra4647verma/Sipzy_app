import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? submessage;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? icon;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.submessage,
    this.onAction,
    this.actionLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon ?? Icons.restaurant_rounded,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (submessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  submessage!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                AppTheme.gradientButtonAmber(
                  onPressed: onAction!,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
