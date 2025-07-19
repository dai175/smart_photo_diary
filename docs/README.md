# Documentation

This directory contains specialized documentation for Smart Photo Diary development and deployment.

## File Structure

### 📋 [deployment_checklist.md](deployment_checklist.md)
Comprehensive pre-release checklist and deployment procedures for both iOS and Android platforms.

**Use when**: Preparing for production release
**Key sections**: Code quality, testing, store submission, rollback plans

### 🚀 [ci_cd_guide.md](ci_cd_guide.md)
CI/CD pipeline operations and GitHub Actions workflow management.

**Use when**: Configuring automated builds and deployments
**Key sections**: Workflow triggers, secrets management, deployment automation

### 💰 [monetization_strategy.md](monetization_strategy.md)
Monetization strategy, pricing analysis, and business planning.

**Use when**: Planning business strategy and revenue implementation
**Key sections**: Pricing strategy, competitive analysis, KPI tracking

### 🧪 [sandbox_testing_guide.md](sandbox_testing_guide.md)
Sandbox testing procedures for In-App Purchase validation.

**Use when**: Testing subscription flows before production
**Key sections**: Test account setup, purchase scenarios, validation procedures

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
| Setting up CI/CD | ci_cd_guide.md |
| Business planning | monetization_strategy.md |
| Testing purchases | sandbox_testing_guide.md |

## Maintenance

### Regular Updates Needed
- **deployment_checklist.md**: Update when new features or requirements are added
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