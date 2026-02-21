import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/design_system/app_spacing.dart';
import 'error_severity.dart';

/// SnackBar用エラーコンテンツ
class ErrorSnackBarContent extends StatelessWidget {
  final AppException error;
  final ErrorSeverity severity;

  const ErrorSnackBarContent({
    super.key,
    required this.error,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ErrorSeverityHelper.getIcon(severity), color: Colors.white),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            error.userMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// エラーダイアログウィジェット
class ErrorDialogWidget extends StatelessWidget {
  final AppException error;
  final ErrorDisplayConfig config;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorDialogWidget({
    super.key,
    required this.error,
    required this.config,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        ErrorSeverityHelper.getIcon(config.severity),
        color: ErrorSeverityHelper.getColor(context, config.severity),
        size: 32,
      ),
      title: Text(ErrorSeverityHelper.getTitle(context, config.severity)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.userMessage),
          if (_shouldShowDetails(config.severity))
            ..._buildErrorDetails(context),
        ],
      ),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildErrorDetails(BuildContext context) {
    return [
      const SizedBox(height: AppSpacing.lg),
      const Divider(),
      const SizedBox(height: AppSpacing.sm),
      Text(
        context.l10n.errorDetailsLabel,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppConstants.captionFontSize,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        error.message,
        style: TextStyle(
          fontSize: AppConstants.captionFontSize,
          color: Colors.grey[600],
        ),
      ),
    ];
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (config.showRetryButton && onRetry != null) {
      actions.add(
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry!();
          },
          child: Text(retryButtonText ?? context.l10n.commonRetry),
        ),
      );
    }

    if (config.dismissible) {
      actions.add(
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonOk),
        ),
      );
    }

    return actions;
  }

  bool _shouldShowDetails(ErrorSeverity severity) {
    return severity == ErrorSeverity.critical;
  }
}

/// インラインエラーウィジェット
class ErrorInlineWidget extends StatelessWidget {
  final AppException error;
  final ErrorDisplayConfig config;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorInlineWidget({
    super.key,
    required this.error,
    required this.config,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = ErrorSeverityHelper.getColor(
      context,
      config.severity,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        border: Border.all(color: severityColor),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ErrorSeverityHelper.getIcon(config.severity),
                color: severityColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ErrorSeverityHelper.getTitle(context, config.severity),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                        fontSize: AppConstants.bodyFontSize,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      error.userMessage,
                      style: TextStyle(
                        color: severityColor,
                        fontSize: AppConstants.captionFontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (config.showRetryButton && onRetry != null)
            ..._buildRetryButton(context, severityColor),
        ],
      ),
    );
  }

  List<Widget> _buildRetryButton(BuildContext context, Color severityColor) {
    return [
      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(
            retryButtonText ??
                config.retryButtonText ??
                context.l10n.commonRetry,
          ),
          style: TextButton.styleFrom(foregroundColor: severityColor),
        ),
      ),
    ];
  }
}

/// フルスクリーンエラーウィジェット
class ErrorFullScreenWidget extends StatelessWidget {
  final AppException error;
  final ErrorDisplayConfig config;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorFullScreenWidget({
    super.key,
    required this.error,
    required this.config,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = ErrorSeverityHelper.getColor(
      context,
      config.severity,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(ErrorSeverityHelper.getTitle(context, config.severity)),
        backgroundColor: severityColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ErrorSeverityHelper.getIcon(config.severity),
                    size: 80,
                    color: severityColor,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    ErrorSeverityHelper.getTitle(context, config.severity),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    error.userMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (_shouldShowDetails(config.severity))
                    ..._buildErrorDetails(context),
                ],
              ),
            ),
            _buildActionButtons(context, severityColor),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildErrorDetails(BuildContext context) {
    return [
      const SizedBox(height: AppSpacing.xl),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.errorDetailsLabel,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildActionButtons(BuildContext context, Color severityColor) {
    return Column(
      children: [
        if (config.showRetryButton && onRetry != null)
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry!();
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                retryButtonText ??
                    config.retryButtonText ??
                    context.l10n.commonRetry,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: severityColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (config.showRetryButton && onRetry != null)
          const SizedBox(height: AppSpacing.md),
        if (config.dismissible)
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonClose),
            ),
          ),
      ],
    );
  }

  bool _shouldShowDetails(ErrorSeverity severity) {
    return severity == ErrorSeverity.critical;
  }
}

/// 簡単なエラー表示用ヘルパーウィジェット
class SimpleErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? icon;

  const SimpleErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryButtonText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? context.l10n.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
