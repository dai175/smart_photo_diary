import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../localization/localization_extensions.dart';
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
        Icon(_getIconForSeverity(severity), color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            error.userMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
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
        _getIconForSeverity(config.severity),
        color: _getColorForSeverity(context, config.severity),
        size: 32,
      ),
      title: Text(_getTitleForSeverity(context, config.severity)),
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
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
      Text(
        context.l10n.errorDetailsLabel,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppConstants.captionFontSize,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 4),
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

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  String _getTitleForSeverity(BuildContext context, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return context.l10n.errorSeverityInfo;
      case ErrorSeverity.warning:
        return context.l10n.errorSeverityWarning;
      case ErrorSeverity.error:
        return context.l10n.errorSeverityError;
      case ErrorSeverity.critical:
        return context.l10n.errorSeverityCritical;
    }
  }

  Color _getColorForSeverity(BuildContext context, ErrorSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primary;
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800);
      case ErrorSeverity.error:
        return colorScheme.error;
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F);
    }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: _getColorForSeverity(
          context,
          config.severity,
        ).withValues(alpha: 0.1),
        border: Border.all(
          color: _getColorForSeverity(context, config.severity),
        ),
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getIconForSeverity(config.severity),
                color: _getColorForSeverity(context, config.severity),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitleForSeverity(context, config.severity),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorForSeverity(context, config.severity),
                        fontSize: AppConstants.bodyFontSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.userMessage,
                      style: TextStyle(
                        color: _getColorForSeverity(context, config.severity),
                        fontSize: AppConstants.captionFontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (config.showRetryButton && onRetry != null)
            ..._buildRetryButton(context),
        ],
      ),
    );
  }

  List<Widget> _buildRetryButton(BuildContext context) {
    return [
      const SizedBox(height: 12),
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
          style: TextButton.styleFrom(
            foregroundColor: _getColorForSeverity(context, config.severity),
          ),
        ),
      ),
    ];
  }

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  String _getTitleForSeverity(BuildContext context, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return context.l10n.errorSeverityInfo;
      case ErrorSeverity.warning:
        return context.l10n.errorSeverityWarning;
      case ErrorSeverity.error:
        return context.l10n.errorSeverityError;
      case ErrorSeverity.critical:
        return context.l10n.errorSeverityCritical;
    }
  }

  Color _getColorForSeverity(BuildContext context, ErrorSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primary;
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800);
      case ErrorSeverity.error:
        return colorScheme.error;
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F);
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForSeverity(context, config.severity)),
        backgroundColor: _getColorForSeverity(context, config.severity),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForSeverity(config.severity),
                    size: 80,
                    color: _getColorForSeverity(context, config.severity),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getTitleForSeverity(context, config.severity),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _getColorForSeverity(context, config.severity),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildErrorDetails(BuildContext context) {
    return [
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
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
            const SizedBox(height: 8),
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

  Widget _buildActionButtons(BuildContext context) {
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
                backgroundColor: _getColorForSeverity(context, config.severity),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (config.showRetryButton && onRetry != null)
          const SizedBox(height: 12),
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

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  String _getTitleForSeverity(BuildContext context, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return context.l10n.errorSeverityInfo;
      case ErrorSeverity.warning:
        return context.l10n.errorSeverityWarning;
      case ErrorSeverity.error:
        return context.l10n.errorSeverityError;
      case ErrorSeverity.critical:
        return context.l10n.errorSeverityCritical;
    }
  }

  Color _getColorForSeverity(BuildContext context, ErrorSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primary;
      case ErrorSeverity.warning:
        return const Color(0xFFFF9800);
      case ErrorSeverity.error:
        return colorScheme.error;
      case ErrorSeverity.critical:
        return const Color(0xFFD32F2F);
    }
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
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
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
