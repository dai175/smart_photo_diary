Before marking any UI task done, verify BOTH light and dark modes:

- No hardcoded `Colors.white`, `Colors.black`, `Colors.grey`, or `Color(0xFF...)`
- Use `Theme.of(context).colorScheme.*` or `AppColors.*` tokens — never raw color values
- Icons must have explicit `color:` using theme tokens (defaults can be theme-unaware)
- `Colors.black.withOpacity(n)` only inside a brightness check
- See DESIGN.md "ダークモード実装ルール" for the full reference
