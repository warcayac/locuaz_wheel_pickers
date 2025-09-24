# Publisher Guide for Locuaz Wheel Pickers

This comprehensive guide provides step-by-step instructions for publishing the Locuaz Wheel Pickers package to pub.dev.

## Prerequisites

### System Requirements
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Git version control
- Internet connection for pub.dev access

### Account Setup

#### 1. Create pub.dev Account
1. Visit [pub.dev](https://pub.dev)
2. Click "Sign in" in the top right
3. Sign in with your Google account
4. Complete profile setup with:
   - Display name
   - Profile picture (optional)
   - Bio (optional)

#### 2. Verify Email Address
1. Check your email for verification link
2. Click the verification link
3. Confirm email verification in pub.dev settings

#### 3. Set Up Two-Factor Authentication (Recommended)
1. Go to pub.dev account settings
2. Enable 2FA using authenticator app
3. Save backup codes securely

## Authentication Setup

### 1. Install pub.dev CLI Tools
```bash
# Ensure you have the latest Dart SDK
dart --version

# The pub command is included with Dart SDK
pub --version
```

### 2. Authenticate with pub.dev
```bash
# Login to pub.dev (opens browser for OAuth)
dart pub login
```

This will:
- Open your default browser
- Redirect to pub.dev authentication
- Store credentials locally for future use

### 3. Verify Authentication
```bash
# Check current authentication status
dart pub token list
```

## Pre-Publication Validation

### 1. Package Structure Verification

#### Navigate to Package Directory
```bash
cd locuaz_wheel_pickers
```

#### Verify Package Structure
```bash
# Check directory structure
tree -I 'build|.dart_tool'

# Expected structure:
# locuaz_wheel_pickers/
# ├── lib/
# │   ├── src/
# │   └── locuaz_wheel_pickers.dart
# ├── example/
# ├── test/
# ├── pubspec.yaml
# ├── README.md
# ├── CHANGELOG.md
# └── LICENSE
```

### 2. Package Metadata Validation

#### Check pubspec.yaml
```yaml
name: locuaz_wheel_pickers
description: A comprehensive collection of iOS-style wheel picker widgets for Flutter with advanced dependency management and performance optimization.
version: 1.0.0
homepage: https://github.com/warcayac/locuaz_wheel_pickers
repository: https://github.com/warcayac/locuaz_wheel_pickers
issue_tracker: https://github.com/warcayac/locuaz_wheel_pickers/issues

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

topics:
  - widgets
  - picker
  - ios
  - wheel
  - date-picker
  - time-picker
```

#### Required Fields Checklist
- [ ] `name` - Package name (lowercase, underscores allowed)
- [ ] `description` - Clear, concise description (60-180 characters)
- [ ] `version` - Semantic version (e.g., 1.0.0)
- [ ] `homepage` - Package homepage URL
- [ ] `repository` - Source code repository URL
- [ ] `environment` - Dart/Flutter SDK constraints
- [ ] `dependencies` - Required dependencies
- [ ] `dev_dependencies` - Development dependencies
- [ ] `topics` - Relevant tags for discoverability

### 3. Code Quality Validation

#### Run Static Analysis
```bash
# Analyze code for issues
flutter analyze

# Expected output: "No issues found!"
```

#### Format Code
```bash
# Format all Dart files
dart format .

# Check formatting without changes
dart format --set-exit-if-changed .
```

#### Generate Documentation
```bash
# Generate and validate documentation
dart doc --validate-links

# Check for documentation coverage
dart doc --show-progress
```

### 4. Testing Validation

#### Run All Tests
```bash
# Run unit and widget tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report (optional)
genhtml coverage/lcov.info -o coverage/html
```

#### Test Example Application
```bash
# Navigate to example directory
cd example

# Get dependencies
flutter pub get

# Run example app
flutter run --release

# Test on different platforms
flutter run -d chrome --release
flutter run -d macos --release
```

## Publication Process

### 1. Pre-Publication Dry Run

#### Validate Package for Publication
```bash
# Return to package root
cd locuaz_wheel_pickers

# Run dry-run to check for issues
flutter pub publish --dry-run
```

#### Review Dry Run Output
Check for:
- [ ] No validation errors
- [ ] All expected files included
- [ ] Reasonable package size
- [ ] Correct version number
- [ ] Proper dependency resolution

### 2. Final Pre-Publication Checks

#### Version Management
```bash
# Ensure version is updated in pubspec.yaml
grep "version:" pubspec.yaml

# Ensure CHANGELOG.md is updated
head -20 CHANGELOG.md

# Tag the release (optional but recommended)
git tag v1.0.0
git push origin v1.0.0
```

#### Documentation Review
- [ ] README.md is comprehensive and up-to-date
- [ ] API documentation is complete
- [ ] Examples work correctly
- [ ] Links are functional

### 3. Publish Package

#### Execute Publication
```bash
# Publish to pub.dev
flutter pub publish
```

#### Confirm Publication
When prompted:
1. Review the package details displayed
2. Confirm the files to be uploaded
3. Type 'y' to confirm publication
4. Wait for upload and processing to complete

#### Expected Output
```
Publishing locuaz_wheel_pickers 1.0.0 to https://pub.dev:
|-- .gitignore
|-- CHANGELOG.md
|-- LICENSE
|-- README.md
|-- analysis_options.yaml
|-- lib
|   |-- locuaz_wheel_pickers.dart
|   '-- src
|       |-- controllers
|       |-- helpers
|       |-- models
|       '-- widgets
|-- pubspec.yaml
'-- test
    |-- controllers
    |-- models
    '-- widgets

Looks great! Are you ready to upload your package (y/N)? y
Uploading...
Successfully uploaded package.
```

## Post-Publication Verification

### 1. Verify Package on pub.dev

#### Check Package Page
1. Visit https://pub.dev/packages/locuaz_wheel_pickers
2. Verify package information displays correctly
3. Check that documentation renders properly
4. Ensure example code is accessible

#### Verify Package Metrics
- [ ] Package appears in search results
- [ ] Health score is calculated
- [ ] Documentation score is good
- [ ] No immediate issues reported

### 2. Test Package Installation

#### Create Test Project
```bash
# Create new Flutter project for testing
flutter create test_installation
cd test_installation
```

#### Install Published Package
```bash
# Add package dependency
flutter pub add locuaz_wheel_pickers

# Verify installation
flutter pub deps
```

#### Test Package Usage
```dart
// Add to lib/main.dart
import 'package:locuaz_wheel_pickers/locuaz_wheel_pickers.dart';

// Test basic functionality
class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleWheelPickerBuilder(
      configs: [
        WheelConfig(
          itemCount: 10,
          initialIndex: 0,
          formatter: (index) => '$index',
        ),
      ],
    );
  }
}
```

#### Run Test Application
```bash
flutter run
```

## Version Management and Updates

### 1. Semantic Versioning Guidelines

#### Version Format: MAJOR.MINOR.PATCH
- **MAJOR**: Breaking changes that require user code updates
- **MINOR**: New features that are backward compatible
- **PATCH**: Bug fixes that are backward compatible

#### Examples
- `1.0.0` - Initial release
- `1.0.1` - Bug fix release
- `1.1.0` - New feature release
- `2.0.0` - Breaking changes release

### 2. Update Process

#### For Patch Updates (1.0.0 → 1.0.1)
```bash
# 1. Fix bugs and update tests
# 2. Update version in pubspec.yaml
sed -i 's/version: 1.0.0/version: 1.0.1/' pubspec.yaml

# 3. Update CHANGELOG.md
echo "## 1.0.1\n- Bug fixes\n- Performance improvements\n" >> CHANGELOG.md

# 4. Run validation
flutter pub publish --dry-run

# 5. Publish update
flutter pub publish
```

#### For Minor Updates (1.0.0 → 1.1.0)
```bash
# 1. Implement new features
# 2. Add tests for new features
# 3. Update documentation
# 4. Update version and changelog
# 5. Validate and publish
```

#### For Major Updates (1.0.0 → 2.0.0)
```bash
# 1. Implement breaking changes
# 2. Update migration guide
# 3. Update all documentation
# 4. Extensive testing
# 5. Update version and changelog
# 6. Validate and publish
```

### 3. Maintenance Best Practices

#### Regular Maintenance Tasks
- [ ] Monitor package health score
- [ ] Respond to user issues and questions
- [ ] Update dependencies regularly
- [ ] Keep documentation current
- [ ] Address security vulnerabilities promptly

#### Monitoring Package Health
```bash
# Check package status
curl -s https://pub.dev/api/packages/locuaz_wheel_pickers | jq '.latest.pubspec.version'

# Monitor download statistics
# Visit: https://pub.dev/packages/locuaz_wheel_pickers/score
```

## Troubleshooting Common Issues

### Authentication Issues

#### "Not authenticated" Error
```bash
# Re-authenticate
dart pub logout
dart pub login
```

#### "Invalid credentials" Error
1. Check internet connection
2. Verify pub.dev account status
3. Re-authenticate with fresh login

### Publication Errors

#### "Package validation failed"
```bash
# Check specific validation errors
flutter pub publish --dry-run

# Common fixes:
# - Update pubspec.yaml required fields
# - Fix analysis errors
# - Ensure all tests pass
```

#### "Version already exists"
```bash
# Update version in pubspec.yaml
# Ensure version follows semantic versioning
# Check existing versions on pub.dev
```

#### "Package name unavailable"
```bash
# Choose different package name
# Update pubspec.yaml with new name
# Update all references in code and documentation
```

### Documentation Issues

#### "Documentation generation failed"
```bash
# Generate docs locally to debug
dart doc

# Fix dartdoc comments
# Ensure all code examples compile
# Check for broken links
```

#### "README rendering issues"
1. Test README.md locally with Markdown viewer
2. Check for unsupported Markdown features
3. Validate all links and images
4. Ensure code blocks have proper syntax highlighting

### Testing Issues

#### "Tests failing in CI"
```bash
# Run tests locally
flutter test

# Check for platform-specific issues
# Ensure all dependencies are available
# Fix flaky tests
```

#### "Example app not working"
```bash
# Test example app locally
cd example
flutter pub get
flutter run

# Update example dependencies
# Fix any breaking changes
# Ensure examples demonstrate key features
```

## Emergency Procedures

### Critical Bug Fix
1. **Identify Issue**: Reproduce and understand the bug
2. **Create Hotfix**: Fix the issue with minimal changes
3. **Test Fix**: Run targeted tests for the fix
4. **Update Version**: Increment patch version
5. **Publish Quickly**: Use expedited publication process
6. **Monitor**: Watch for successful deployment and user feedback

### Security Vulnerability
1. **Assess Severity**: Determine impact and urgency
2. **Fix Vulnerability**: Implement security fix
3. **Test Thoroughly**: Ensure fix doesn't break functionality
4. **Update Version**: Increment appropriate version number
5. **Publish Immediately**: Prioritize security update
6. **Notify Users**: Consider security advisory if needed

### Package Corruption
1. **Verify Issue**: Confirm package is corrupted
2. **Identify Cause**: Determine what went wrong
3. **Prepare Fix**: Create corrected version
4. **Test Extensively**: Ensure package works correctly
5. **Publish Replacement**: Update with fixed version
6. **Communicate**: Inform users of the issue and resolution

## Success Metrics

### Publication Success Indicators
- [ ] Package published without errors
- [ ] Package appears on pub.dev within 5 minutes
- [ ] Documentation renders correctly
- [ ] Example code is accessible and functional
- [ ] Package can be installed in test projects

### Long-term Success Metrics
- [ ] Pub.dev health score > 100
- [ ] Growing download numbers
- [ ] Positive user feedback and ratings
- [ ] Active community engagement
- [ ] Regular maintenance and updates

## Support and Resources

### Official Documentation
- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Package Layout Conventions](https://dart.dev/tools/pub/package-layout)
- [Semantic Versioning](https://semver.org/)

### Community Resources
- [Flutter Community Discord](https://discord.gg/flutter)
- [r/FlutterDev Reddit](https://reddit.com/r/FlutterDev)
- [Flutter GitHub Discussions](https://github.com/flutter/flutter/discussions)

### Getting Help
- Check pub.dev documentation first
- Search existing issues on GitHub
- Ask questions in Flutter community forums
- Contact pub.dev support for platform issues

## Conclusion

Following this guide ensures a smooth publication process for the Locuaz Wheel Pickers package. Remember to:

1. **Validate thoroughly** before publishing
2. **Test extensively** in different environments
3. **Document comprehensively** for users
4. **Monitor actively** after publication
5. **Maintain regularly** for long-term success

Good luck with your package publication!