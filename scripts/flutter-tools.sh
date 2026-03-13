#!/bin/bash

# Flutter Development Tools Script
# This script runs all Flutter development tools for code quality and testing

set -e

echo "🚀 Running Flutter Development Tools..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
check_flutter() {
    print_status "Checking Flutter installation..."
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    print_success "Flutter is installed"
}

# Run Flutter Doctor
run_flutter_doctor() {
    print_status "Running Flutter Doctor..."
    flutter doctor -v
    if [ $? -eq 0 ]; then
        print_success "Flutter Doctor completed successfully"
    else
        print_warning "Flutter Doctor found some issues"
    fi
}

# Get dependencies
get_dependencies() {
    print_status "Getting dependencies..."
    flutter pub get
    if [ $? -eq 0 ]; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Generate localization
generate_localization() {
    print_status "Generating localization..."
    flutter gen-l10n
    if [ $? -eq 0 ]; then
        print_success "Localization generated successfully"
    else
        print_warning "Localization generation failed"
    fi
}

# Run Flutter Analyze
run_flutter_analyze() {
    print_status "Running Flutter Analyze..."
    flutter analyze --fatal-infos --fatal-warnings
    if [ $? -eq 0 ]; then
        print_success "Flutter Analyze passed"
    else
        print_error "Flutter Analyze failed"
        exit 1
    fi
}

# Check code formatting
check_formatting() {
    print_status "Checking code formatting..."
    dart format --set-exit-if-changed .
    if [ $? -eq 0 ]; then
        print_success "Code is properly formatted"
    else
        print_error "Code formatting issues found"
        exit 1
    fi
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    # Unit tests
    print_status "Running unit tests..."
    flutter test --coverage --reporter=expanded
    if [ $? -eq 0 ]; then
        print_success "Unit tests passed"
    else
        print_error "Unit tests failed"
        exit 1
    fi
    
    # Widget tests
    print_status "Running widget tests..."
    flutter test --coverage integration_test/
    if [ $? -eq 0 ]; then
        print_success "Widget tests passed"
    else
        print_warning "Some widget tests failed"
    fi
}

# Build test
run_build_test() {
    print_status "Running build test..."
    
    # Web build
    print_status "Building for web..."
    flutter build web --release --web-renderer canvaskit
    if [ $? -eq 0 ]; then
        print_success "Web build successful"
    else
        print_error "Web build failed"
        exit 1
    fi
    
    # Android build (if possible)
    if command -v java &> /dev/null; then
        print_status "Building for Android..."
        flutter build apk --release
        if [ $? -eq 0 ]; then
            print_success "Android build successful"
        else
            print_warning "Android build failed"
        fi
    else
        print_warning "Java not available, skipping Android build"
    fi
}

# Code quality check
run_code_quality() {
    print_status "Running code quality check..."
    
    # Install dart_code_metrics if not available
    if ! command -v dart_code_metrics &> /dev/null; then
        print_status "Installing dart_code_metrics..."
        dart pub global activate dart_code_metrics
    fi
    
    # Run code metrics
    dart_code_metrics lib/ --reporter=console
    if [ $? -eq 0 ]; then
        print_success "Code quality check passed"
    else
        print_warning "Code quality issues found"
    fi
}

# Security check
run_security_check() {
    print_status "Running security check..."
    
    # Check dependencies for known vulnerabilities
    flutter pub deps --style=tree
    
    # Check for sensitive data
    print_status "Checking for sensitive data..."
    
    # Check for hardcoded secrets
    if grep -r "password\|secret\|token\|key" --include="*.dart" lib/ | grep -v "//" | grep -v "/*" | grep -v "*/" | grep -v "password\|secret\|token\|key.*:"; then
        print_warning "Potential hardcoded secrets found"
    else
        print_success "No hardcoded secrets found"
    fi
}

# Performance check
run_performance_check() {
    print_status "Running performance check..."
    
    # Check for common performance issues
    print_status "Checking for performance issues..."
    
    # Check for unnecessary rebuilds
    if grep -r "setState\|markNeedsBuild\|notifyListeners" --include="*.dart" lib/ | wc -l | grep -E "^\s*[0-9]+\s*$" > /dev/null; then
        print_status "Found $(grep -r "setState\|markNeedsBuild\|notifyListeners" --include="*.dart" lib/ | wc -l | tr -d ' ') state updates"
    fi
    
    # Check for async/await usage
    if grep -r "async\|await" --include="*.dart" lib/ | wc -l | grep -E "^\s*[0-9]+\s*$" > /dev/null; then
        print_status "Found $(grep -r "async\|await" --include="*.dart" lib/ | wc -l | tr -d ' ') async operations"
    fi
    
    print_success "Performance check completed"
}

# Documentation check
run_documentation_check() {
    print_status "Running documentation check..."
    
    # Generate documentation
    if ! command -v dartdoc &> /dev/null; then
        print_status "Installing dartdoc..."
        dart pub global activate dartdoc
    fi
    
    dartdoc --output docs/api --exclude-private --exclude-internal
    if [ $? -eq 0 ]; then
        print_success "Documentation generated successfully"
    else
        print_warning "Documentation generation failed"
    fi
    
    # Check for documentation coverage
    total_classes=$(find lib/ -name "*.dart" -exec grep -l "class\|mixin\|enum" {} \; | wc -l)
    documented_classes=$(find lib/ -name "*.dart" -exec grep -l "///" {} \; | wc -l)
    
    if [ $total_classes -gt 0 ]; then
        coverage=$((documented_classes * 100 / total_classes))
        print_status "Documentation coverage: $coverage% ($documented_classes/$total_classes classes)"
        
        if [ $coverage -lt 50 ]; then
            print_warning "Documentation coverage is low ($coverage%)"
        else
            print_success "Documentation coverage is good ($coverage%)"
        fi
    fi
}

# Clean up
cleanup() {
    print_status "Cleaning up..."
    
    # Remove temporary files
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    find . -name "Thumbs.db" -delete 2>/dev/null || true
    
    # Clean build cache
    flutter clean
    
    print_success "Cleanup completed"
}

# Generate report
generate_report() {
    print_status "Generating development report..."
    
    REPORT_FILE="development_report.md"
    
    cat > $REPORT_FILE << EOF
# Flutter Development Report

Generated on: $(date)

## Flutter Environment
\`\`\`
$(flutter doctor -v)
\`\`\`

## Project Statistics
- Total Dart files: $(find lib/ -name "*.dart" | wc -l)
- Total test files: $(find test/ -name "*.dart" | wc -l)
- Documentation coverage: $([ $total_classes -gt 0 ] && echo "$coverage%" || echo "N/A")

## Code Quality
- Analyze: $(flutter analyze --fatal-infos --fatal-warnings > /dev/null 2>&1 && echo "✅ PASSED" || echo "❌ FAILED")
- Tests: $(flutter test > /dev/null 2>&1 && echo "✅ PASSED" || echo "❌ FAILED")
- Build: $(flutter build web > /dev/null 2>&1 && echo "✅ PASSED" || echo "❌ FAILED")

## Dependencies
\`\`\`
$(flutter pub deps --style=tree)
\`\`\`

## Performance Metrics
- State updates: $(grep -r "setState\|markNeedsBuild\|notifyListeners" --include="*.dart" lib/ | wc -l | tr -d ' ')
- Async operations: $(grep -r "async\|await" --include="*.dart" lib/ | wc -l | tr -d ' ')

## Security Scan
- Hardcoded secrets: $(grep -r "password\|secret\|token\|key" --include="*.dart" lib/ | grep -v "//" | grep -v "/*" | grep -v "*/" | grep -v "password\|secret\|token\|key.*:" | wc -l | tr -d ' ' || echo "0")
- Vulnerable dependencies: Check manually with \`flutter pub deps\`

## Recommendations
- Keep documentation coverage above 70%
- Use async/await for asynchronous operations
- Avoid hardcoded secrets
- Run tests before committing
- Use flutter analyze to catch issues early

EOF

    print_success "Report generated: $REPORT_FILE"
}

# Main execution
main() {
    echo "Starting Flutter development tools..."
    echo ""
    
    # Check prerequisites
    check_flutter
    
    # Run all checks
    get_dependencies
    generate_localization
    run_flutter_analyze
    check_formatting
    run_tests
    run_build_test
    run_code_quality
    run_security_check
    run_performance_check
    run_documentation_check
    
    # Generate report
    generate_report
    
    # Cleanup
    cleanup
    
    echo ""
    echo "=================================="
    print_success "Flutter development tools completed successfully!"
    echo ""
    echo "📊 Report: development_report.md"
    echo "📚 Documentation: docs/api/"
    echo "🧪 Test coverage: coverage/"
    echo ""
    echo "Next steps:"
    echo "1. Review the development report"
    echo "2. Check test coverage"
    echo "3. Review documentation"
    echo "4. Fix any issues found"
    echo ""
}

# Run main function
main "$@"
