# Documentation

This directory contains specialized documentation for Smart Photo Diary development and deployment.

## File Structure

### Core Operational Guides

#### 📋 [deployment_checklist.md](deployment_checklist.md)
Comprehensive pre-release checklist and deployment procedures for both iOS and Android platforms.

**Use when**: Preparing for production release
**Key sections**: Code quality, testing, store submission, rollback plans

#### 🚀 [ci_cd_guide.md](ci_cd_guide.md)
CI/CD pipeline operations and GitHub Actions workflow management.

**Use when**: Configuring automated builds and deployments
**Key sections**: Workflow triggers, secrets management, deployment automation

#### 💰 [monetization_strategy.md](monetization_strategy.md)
Monetization strategy, pricing analysis, and business planning.

**Use when**: Planning business strategy and revenue implementation
**Key sections**: Pricing strategy, competitive analysis, KPI tracking

#### 🧪 [sandbox_testing_guide.md](sandbox_testing_guide.md)
Sandbox testing procedures for In-App Purchase validation.

**Use when**: Testing subscription flows before production
**Key sections**: Test account setup, purchase scenarios, validation procedures

### Internationalization & Localization

#### 🌐 [localization_guide.md](localization_guide.md)
Comprehensive guide for implementing and maintaining app localization.

**Use when**: Adding new languages or updating translations
**Key sections**: ARB file management, translation workflows, testing procedures

#### 📝 [translation_request_template.md](translation_request_template.md)
Template for requesting professional translations with context and guidelines.

**Use when**: Ordering professional translation services
**Key sections**: Translation briefs, context explanations, quality requirements

#### ✅ [i18n_checklist.md](i18n_checklist.md)
Step-by-step checklist for internationalization implementation and testing.

**Use when**: Implementing i18n features or preparing for multi-language releases
**Key sections**: Implementation tasks, testing scenarios, quality assurance

### Architecture & Development

#### 🔄 [refactoring_checklist.md](refactoring_checklist.md)
Quality assurance checklist for major architectural changes and refactoring.

**Use when**: Performing large-scale code refactoring or architectural updates
**Key sections**: Code quality checks, testing requirements, migration procedures

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
| Adding new languages | localization_guide.md |
| Ordering translations | translation_request_template.md |
| Implementing i18n features | i18n_checklist.md |
| Major refactoring | refactoring_checklist.md |

## Maintenance

### Regular Updates Needed
- **deployment_checklist.md**: Update when new features or requirements are added
- **monetization_strategy.md**: Update quarterly with progress and market changes
- **localization_guide.md**: Update when adding new languages or translation workflows
- **i18n_checklist.md**: Update when i18n implementation patterns change

### Automatically Updated
- **ci_cd_guide.md**: Reflects current workflow configurations
- **sandbox_testing_guide.md**: Stable testing procedures, rarely changes
- **translation_request_template.md**: Stable template, rarely changes

## Contributing

When adding new documentation:

1. **Evaluate placement**: Does it belong in CLAUDE.md or as a specialized guide?
2. **Avoid duplication**: Reference existing documentation rather than repeating
3. **Use clear structure**: Follow the established format and naming conventions
4. **Update this README**: Add new files to the structure above