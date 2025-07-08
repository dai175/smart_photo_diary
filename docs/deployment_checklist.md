# Deployment Checklist

## Pre-Release Checklist

### Code Quality
- [ ] All tests passing (683 tests with 100% success rate)
- [ ] `fvm flutter analyze` shows no issues
- [ ] `fvm dart format .` applied to all files
- [ ] No debug prints or TODO comments in production code
- [ ] All features working in both debug and release builds

### Environment Configuration
- [ ] `.env` file excluded from version control
- [ ] API keys properly configured in CI/CD secrets
- [ ] Environment variables validated for production
- [ ] FORCE_PLAN setting disabled in release builds

### UI/UX Verification
- [ ] All modals use CustomDialog components
- [ ] Text alignment follows left-aligned standards
- [ ] Photo permission dialogs display correctly
- [ ] Responsive layouts work on different screen sizes
- [ ] Dark mode support verified
- [ ] Japanese font rendering correct

### Feature Testing
- [ ] Photo selection and permissions working
- [ ] AI diary generation functional (both single and multiple photos)
- [ ] Writing prompts system operational
- [ ] Basic/Premium plan enforcement correct
- [ ] In-app purchase flow tested (sandbox)
- [ ] Data export functionality working
- [ ] Calendar view and filtering operational

### Platform-Specific Testing

#### iOS
- [ ] Photo permissions (full access and limited access) working
- [ ] App Store Connect products configured
- [ ] TestFlight build uploaded and tested
- [ ] App Review Guidelines compliance verified
- [ ] Privacy policy updated and accessible

#### Android
- [ ] Photo permissions working across Android versions
- [ ] Google Play Console products configured
- [ ] Internal testing track verified
- [ ] Play Store policies compliance checked
- [ ] Target SDK version requirements met

### Security & Privacy
- [ ] No API keys in APK/IPA files
- [ ] User data stays local (no cloud sync)
- [ ] Privacy policy accurately describes data usage
- [ ] GDPR compliance verified (if applicable)
- [ ] App permissions justified and minimal

### Performance
- [ ] App startup time acceptable
- [ ] Large photo processing performance tested
- [ ] Memory usage within reasonable limits
- [ ] Battery consumption optimized
- [ ] Network requests properly handled (offline fallbacks)

### Documentation
- [ ] CLAUDE.md updated with latest implementation
- [ ] Store setup guides current
- [ ] CI/CD documentation accurate
- [ ] Monetization strategy documented

## Release Process

### 1. Version Bump
- [ ] Update version in `pubspec.yaml`
- [ ] Update build number for stores
- [ ] Create git tag for release
- [ ] Update changelog if applicable

### 2. Build Generation
- [ ] Generate release APK/AAB for Android
- [ ] Generate release IPA for iOS
- [ ] Verify build integrity and signing
- [ ] Test builds on real devices

### 3. Store Submission

#### iOS App Store
- [ ] Upload to App Store Connect
- [ ] Complete App Store listing information
- [ ] Submit for App Review
- [ ] Monitor review status

#### Google Play Store
- [ ] Upload to Google Play Console
- [ ] Complete Play Store listing information
- [ ] Submit for review
- [ ] Monitor review status

### 4. Post-Release
- [ ] Monitor crash reports and user feedback
- [ ] Verify in-app purchases working in production
- [ ] Check analytics and usage metrics
- [ ] Plan next iteration based on feedback

## Emergency Rollback Plan

### If Critical Issues Found
1. **Immediate Actions**:
   - [ ] Halt store rollout if possible
   - [ ] Document issue details
   - [ ] Assess impact and affected users

2. **Hotfix Process**:
   - [ ] Create hotfix branch
   - [ ] Implement minimal fix
   - [ ] Test thoroughly
   - [ ] Fast-track review process

3. **Communication**:
   - [ ] Notify stakeholders
   - [ ] Update support documentation
   - [ ] Prepare user communications if needed

## Sign-off

### Technical Lead
- [ ] Code review completed
- [ ] Architecture compliance verified
- [ ] Performance benchmarks met

### QA
- [ ] Test plan executed
- [ ] Edge cases verified
- [ ] Cross-platform compatibility confirmed

### Product
- [ ] Feature completeness verified
- [ ] User experience validated
- [ ] Business requirements met

### Release Manager
- [ ] All checklist items completed
- [ ] Deployment scripts ready
- [ ] Rollback plan prepared
- [ ] Go/No-go decision made

---

**Release Date**: ___________  
**Version**: ___________  
**Build Number**: ___________  
**Approved By**: ___________