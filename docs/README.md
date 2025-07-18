# Documentation

This directory contains specialized documentation for Smart Photo Diary development and deployment.

## File Structure

### 📋 [deployment_checklist.md](deployment_checklist.md)
Comprehensive pre-release checklist and deployment procedures for both iOS and Android platforms.

**Use when**: Preparing for production release
**Key sections**: Code quality, testing, store submission, rollback plans

### 🏪 [store_setup_guide.md](store_setup_guide.md)
In-App Purchase product configuration for App Store Connect and Google Play Console.

**Use when**: Setting up store products and pricing
**Key sections**: Product IDs, pricing tiers, store-specific setup instructions

### 🚀 [ci_cd_guide.md](ci_cd_guide.md)
Detailed CI/CD pipeline operations and GitHub Actions workflow management.

**Use when**: Configuring automated builds and deployments
**Key sections**: Workflow triggers, secrets management, deployment automation

### 💰 [monetization_strategy.md](monetization_strategy.md)
Comprehensive monetization strategy, pricing analysis, and implementation progress tracking.

**Use when**: Planning business strategy and tracking revenue implementation
**Key sections**: Pricing strategy, competitive analysis, implementation roadmap

### 🧪 [sandbox_testing_guide.md](sandbox_testing_guide.md)
Detailed sandbox testing procedures for In-App Purchase validation.

**Use when**: Testing subscription flows before production
**Key sections**: Test account setup, purchase scenarios, validation procedures

### 💳 [in-app-purchase-setup-guide.md](in-app-purchase-setup-guide.md)
Comprehensive In-App Purchase configuration and setup procedures.

**Use when**: Setting up detailed subscription functionality and purchase flows
**Key sections**: StoreKit configuration, product setup, testing procedures

### ✈️ [testflight-build-guide.md](testflight-build-guide.md)
Detailed TestFlight build creation and distribution procedures.

**Use when**: Creating and distributing TestFlight builds for testing
**Key sections**: Xcode build process, App Store Connect upload, tester management

## Main Documentation

The primary development documentation is located in the project root:

- **[CLAUDE.md](../CLAUDE.md)** - Main development guide with architecture, coding standards, and implementation status
- **[README.md](../README.md)** - Project overview and quick start guide

## Documentation Philosophy

### Principle of Single Source of Truth
- **CLAUDE.md** serves as the comprehensive technical documentation
- **docs/** folder contains specialized operational guides
- Avoid duplication between main and specialized documentation

### When to Use Which Document

| Need | Document |
|------|----------|
| Understanding the codebase | CLAUDE.md |
| Setting up development environment | CLAUDE.md + README.md |
| Preparing for release | deployment_checklist.md |
| Configuring store products | store_setup_guide.md |
| Setting up CI/CD | ci_cd_guide.md |
| Business planning | monetization_strategy.md |
| Testing purchases | sandbox_testing_guide.md |
| TestFlight builds | testflight-build-guide.md |
| In-App Purchase setup | in-app-purchase-setup-guide.md |

## Maintenance

### Regular Updates Needed
- **deployment_checklist.md**: Update when new features or requirements are added
- **store_setup_guide.md**: Update when pricing or products change
- **monetization_strategy.md**: Update quarterly with progress and market changes

### Automatically Updated
- **ci_cd_guide.md**: Reflects current workflow configurations
- **sandbox_testing_guide.md**: Stable testing procedures, rarely changes

## Contributing

When adding new documentation:

1. **Evaluate placement**: Does it belong in CLAUDE.md or as a specialized guide?
2. **Avoid duplication**: Reference existing documentation rather than repeating
3. **Use clear structure**: Follow the established format and naming conventions
4. **Update this README**: Add new files to the structure above