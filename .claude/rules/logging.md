Never use `print()` or `debugPrint()` for logging.

Always use `LoggingService` (injected via constructor):
- `logger.debug('message', data: {...})`
- `logger.info('message')`
- `logger.warning('message', error: e)`
- `logger.error('message', error: e, stackTrace: st)`

Exception: fallback-only when ServiceLocator is unavailable (e.g., very early app init).
All log messages and data map keys must be in English.
