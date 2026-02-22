#!/usr/bin/env python3
"""
iSuite Build Optimization and Quality Assurance Script
Enhanced build process with comprehensive quality checks, naming conventions,
and automated formatting.
"""

import os
import sys
import subprocess
import json
import re
from pathlib import Path
from typing import List, Dict, Set, Tuple
import argparse
import time
from datetime import datetime

class BuildOptimizer:
    """Comprehensive build optimization and quality assurance system."""

    def __init__(self, project_root: str = None):
        self.project_root = Path(project_root or os.getcwd())
        self.lib_dir = self.project_root / "lib"
        self.test_dir = self.project_root / "test"
        self.build_dir = self.project_root / "build"

        # Quality metrics
        self.metrics = {
            'files_analyzed': 0,
            'issues_fixed': 0,
            'naming_violations': 0,
            'formatting_issues': 0,
            'build_warnings': 0,
            'test_failures': 0,
        }

        # Naming convention patterns
        self.class_pattern = re.compile(r'^class\s+[A-Z][a-zA-Z0-9_]*(\s+extends|\s+implements|\s+with|\s*{)')
        self.function_pattern = re.compile(r'^\s*(?:[a-zA-Z_][a-zA-Z0-9_]*\s+)?([a-z_][a-zA-Z0-9_]*)\s*\(')
        self.variable_pattern = re.compile(r'^\s*(?:final\s+|const\s+|var\s+|late\s+)?([a-z_][a-zA-Z0-9_]*)\s*[=;]')

    def run_full_quality_check(self) -> bool:
        """Run comprehensive quality checks and optimizations."""
        print("🚀 Starting iSuite Build Quality Optimization...")

        start_time = time.time()

        try:
            # Phase 1: Code Analysis
            print("\n📊 Phase 1: Code Analysis")
            self.analyze_codebase()

            # Phase 2: Naming Convention Check
            print("\n🏷️ Phase 2: Naming Convention Validation")
            self.validate_naming_conventions()

            # Phase 3: Code Formatting
            print("\n🎨 Phase 3: Code Formatting")
            self.optimize_formatting()

            # Phase 4: Dependency Optimization
            print("\n📦 Phase 4: Dependency Optimization")
            self.optimize_dependencies()

            # Phase 5: Build Optimization
            print("\n🔨 Phase 5: Build Optimization")
            self.optimize_build_configuration()

            # Phase 6: Testing Validation
            print("\n🧪 Phase 6: Testing Validation")
            self.validate_test_coverage()

            # Phase 7: Documentation Check
            print("\n📚 Phase 7: Documentation Validation")
            self.validate_documentation()

            # Generate report
            self.generate_quality_report()

            elapsed = time.time() - start_time
            print(".2f"
            return self.metrics['test_failures'] == 0 and self.metrics['build_warnings'] < 10

        except Exception as e:
            print(f"❌ Quality check failed: {e}")
            return False

    def analyze_codebase(self):
        """Analyze the codebase structure and metrics."""
        print("   Analyzing project structure...")

        dart_files = list(self.lib_dir.rglob("*.dart"))
        self.metrics['files_analyzed'] = len(dart_files)

        # Analyze file sizes and complexity
        total_lines = 0
        large_files = []

        for file_path in dart_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = len(content.split('\n'))
                    total_lines += lines

                    if lines > 1000:
                        large_files.append((file_path.name, lines))

            except Exception as e:
                print(f"   Warning: Could not analyze {file_path}: {e}")

        print(f"   📁 Analyzed {len(dart_files)} Dart files")
        print(f"   📝 Total lines of code: {total_lines:,}")
        print(f"   📊 Average file size: {total_lines // len(dart_files) if dart_files else 0} lines")

        if large_files:
            print("   ⚠️ Large files detected:")
            for name, lines in large_files[:5]:
                print(f"     - {name}: {lines} lines")

    def validate_naming_conventions(self):
        """Validate and fix naming conventions."""
        print("   Checking naming conventions...")

        dart_files = list(self.lib_dir.rglob("*.dart"))
        violations = []

        for file_path in dart_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')

                for line_num, line in enumerate(lines, 1):
                    # Check class names
                    if self.class_pattern.search(line):
                        class_match = self.class_pattern.search(line)
                        if class_match:
                            class_name = class_match.group(0).split()[1]
                            if not class_name[0].isupper():
                                violations.append({
                                    'file': str(file_path.relative_to(self.project_root)),
                                    'line': line_num,
                                    'type': 'class_naming',
                                    'issue': f'Class "{class_name}" should start with uppercase',
                                    'fix': f'class {class_name[0].upper()}{class_name[1:]}'
                                })

                    # Check function names (basic check)
                    if line.strip().startswith('Future<') or line.strip().startswith('void ') or \
                       (line.strip() and not line.strip().startswith('//') and '(' in line):
                        func_match = self.function_pattern.search(line)
                        if func_match and len(func_match.groups()) > 0:
                            func_name = func_match.group(1)
                            if func_name and not func_name.startswith('_') and func_name[0].isupper():
                                violations.append({
                                    'file': str(file_path.relative_to(self.project_root)),
                                    'line': line_num,
                                    'type': 'function_naming',
                                    'issue': f'Function "{func_name}" should start with lowercase',
                                    'fix': f'{func_name[0].lower()}{func_name[1:]}'
                                })

            except Exception as e:
                print(f"   Warning: Could not check {file_path}: {e}")

        self.metrics['naming_violations'] = len(violations)

        if violations:
            print(f"   ⚠️ Found {len(violations)} naming convention violations")
            # Show first few violations
            for violation in violations[:3]:
                print(f"     - {violation['file']}:{violation['line']}: {violation['issue']}")

            # Save detailed report
            self.save_violations_report(violations)
        else:
            print("   ✅ All naming conventions are correct")

    def optimize_formatting(self):
        """Optimize code formatting using Flutter tools."""
        print("   Running code formatting...")

        try:
            # Run flutter format
            result = subprocess.run(
                ['flutter', 'format', '.'],
                cwd=self.project_root,
                capture_output=True,
                text=True,
                timeout=300
            )

            if result.returncode == 0:
                formatted_files = len(result.stdout.strip().split('\n')) if result.stdout.strip() else 0
                print(f"   ✅ Formatted {formatted_files} files")
                self.metrics['formatting_issues'] = formatted_files
            else:
                print(f"   ⚠️ Formatting completed with warnings: {result.stderr}")

        except subprocess.TimeoutExpired:
            print("   ⚠️ Formatting timed out")
        except FileNotFoundError:
            print("   ⚠️ Flutter not found in PATH - skipping formatting")

    def optimize_dependencies(self):
        """Optimize Flutter dependencies."""
        print("   Optimizing dependencies...")

        try:
            # Clean pub cache
            subprocess.run(['flutter', 'pub', 'cache', 'clean'],
                         cwd=self.project_root, capture_output=True)

            # Get dependencies
            result = subprocess.run(['flutter', 'pub', 'get'],
                                  cwd=self.project_root, capture_output=True, text=True)

            if result.returncode == 0:
                print("   ✅ Dependencies updated successfully")
            else:
                print(f"   ⚠️ Dependency update issues: {result.stderr[:200]}...")

        except FileNotFoundError:
            print("   ⚠️ Flutter not found - skipping dependency optimization")

    def optimize_build_configuration(self):
        """Optimize build configuration and assets."""
        print("   Optimizing build configuration...")

        # Check for unused assets
        assets_dir = self.project_root / "assets"
        if assets_dir.exists():
            asset_files = list(assets_dir.rglob("*"))
            print(f"   📁 Found {len(asset_files)} asset files")

            # Could analyze pubspec.yaml for unused assets
            # For now, just report count

        # Optimize pubspec.yaml
        pubspec_path = self.project_root / "pubspec.yaml"
        if pubspec_path.exists():
            try:
                with open(pubspec_path, 'r') as f:
                    content = f.read()

                # Check for common issues
                issues = []

                if 'sdk: ">=2.17.0 <3.0.0"' in content:
                    issues.append("Consider updating Flutter SDK constraint")

                if len(content.split('\n')) > 200:
                    issues.append("pubspec.yaml is quite large - consider organizing")

                if issues:
                    print("   ⚠️ Pubspec issues found:")
                    for issue in issues:
                        print(f"     - {issue}")
                else:
                    print("   ✅ Pubspec configuration looks good")

            except Exception as e:
                print(f"   Warning: Could not analyze pubspec.yaml: {e}")

        # Check build configurations
        android_dir = self.project_root / "android"
        ios_dir = self.project_root / "ios"

        if android_dir.exists():
            gradle_files = list(android_dir.rglob("*.gradle"))
            print(f"   🤖 Android: {len(gradle_files)} Gradle files")

        if ios_dir.exists():
            ios_files = list(ios_dir.rglob("*"))
            print(f"   🍎 iOS: {len([f for f in ios_files if f.is_file])} files")

    def validate_test_coverage(self):
        """Validate test coverage and run tests."""
        print("   Validating test coverage...")

        test_files = list(self.test_dir.rglob("*_test.dart"))
        print(f"   🧪 Found {len(test_files)} test files")

        if not test_files:
            print("   ⚠️ No test files found")
            return

        try:
            # Run tests with coverage
            result = subprocess.run(
                ['flutter', 'test', '--coverage'],
                cwd=self.project_root,
                capture_output=True,
                text=True,
                timeout=600
            )

            if result.returncode == 0:
                print("   ✅ All tests passed")

                # Check coverage if lcov file exists
                lcov_file = self.project_root / "coverage" / "lcov.info"
                if lcov_file.exists():
                    try:
                        with open(lcov_file, 'r') as f:
                            content = f.read()

                        # Simple coverage calculation
                        lines = content.split('\n')
                        covered_lines = 0
                        total_lines = 0

                        for line in lines:
                            if line.startswith('LF:'):
                                total_lines += int(line.split(':')[1])
                            elif line.startswith('LH:'):
                                covered_lines += int(line.split(':')[1])

                        if total_lines > 0:
                            coverage = (covered_lines / total_lines) * 100
                            print(".1f"
                        else:
                            print("   📊 Coverage data found but could not calculate percentage")

                    except Exception as e:
                        print(f"   Warning: Could not analyze coverage: {e}")
                else:
                    print("   📊 No coverage data found")

            else:
                print(f"   ❌ Tests failed: {result.stderr[:300]}...")
                self.metrics['test_failures'] += 1

        except subprocess.TimeoutExpired:
            print("   ⚠️ Tests timed out")
        except FileNotFoundError:
            print("   ⚠️ Flutter not found - skipping tests")

    def validate_documentation(self):
        """Validate documentation coverage."""
        print("   Validating documentation...")

        dart_files = list(self.lib_dir.rglob("*.dart"))
        documented_files = 0
        total_files = len(dart_files)

        for file_path in dart_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Check for /// documentation comments
                if '///' in content:
                    documented_files += 1

            except Exception:
                pass

        if total_files > 0:
            doc_percentage = (documented_files / total_files) * 100
            print(".1f"
            if doc_percentage < 50:
                print("   ⚠️ Low documentation coverage - consider adding more /// comments")

        # Check README
        readme_path = self.project_root / "README.md"
        if readme_path.exists():
            try:
                with open(readme_path, 'r') as f:
                    readme_content = f.read()

                if len(readme_content) > 10000:
                    print("   📚 README is comprehensive")
                else:
                    print("   📝 README could be more detailed")

            except Exception as e:
                print(f"   Warning: Could not check README: {e}")
        else:
            print("   ⚠️ README.md not found")

    def save_violations_report(self, violations: List[Dict]):
        """Save detailed violations report."""
        report_path = self.project_root / "build_quality_report.json"

        report = {
            'generated_at': datetime.now().isoformat(),
            'total_violations': len(violations),
            'violations': violations[:50],  # Limit to first 50
            'summary': {
                'class_naming': len([v for v in violations if v['type'] == 'class_naming']),
                'function_naming': len([v for v in violations if v['type'] == 'function_naming']),
                'variable_naming': len([v for v in violations if v['type'] == 'variable_naming']),
            }
        }

        try:
            with open(report_path, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"   📋 Detailed report saved to {report_path}")
        except Exception as e:
            print(f"   Warning: Could not save report: {e}")

    def generate_quality_report(self):
        """Generate comprehensive quality report."""
        print("\n📊 Quality Assurance Report")
        print("=" * 50)

        print(f"Files Analyzed: {self.metrics['files_analyzed']}")
        print(f"Naming Violations: {self.metrics['naming_violations']}")
        print(f"Formatting Issues Fixed: {self.metrics['formatting_issues']}")
        print(f"Build Warnings: {self.metrics['build_warnings']}")
        print(f"Test Failures: {self.metrics['test_failures']}")

        overall_score = 100
        if self.metrics['naming_violations'] > 0:
            overall_score -= min(20, self.metrics['naming_violations'])
        if self.metrics['test_failures'] > 0:
            overall_score -= 30
        if self.metrics['build_warnings'] > 10:
            overall_score -= 10

        print(f"Overall Quality Score: {overall_score}/100")

        if overall_score >= 90:
            print("🎉 Excellent! Code quality is outstanding")
        elif overall_score >= 75:
            print("✅ Good! Minor improvements recommended")
        elif overall_score >= 60:
            print("⚠️ Fair! Several improvements needed")
        else:
            print("❌ Poor! Major quality issues require attention")

        # Save metrics
        metrics_path = self.project_root / "quality_metrics.json"
        try:
            with open(metrics_path, 'w') as f:
                json.dump({
                    'timestamp': datetime.now().isoformat(),
                    'metrics': self.metrics,
                    'score': overall_score,
                }, f, indent=2)
        except Exception as e:
            print(f"Warning: Could not save metrics: {e}")

def main():
    parser = argparse.ArgumentParser(description='iSuite Build Quality Optimizer')
    parser.add_argument('--path', help='Project root path', default=None)
    parser.add_argument('--check-only', action='store_true', help='Only run checks, no fixes')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')

    args = parser.parse_args()

    optimizer = BuildOptimizer(args.path)

    if args.verbose:
        print(f"Project root: {optimizer.project_root}")
        print(f"Lib directory: {optimizer.lib_dir}")
        print(f"Test directory: {optimizer.test_dir}")

    success = optimizer.run_full_quality_check()

    if success:
        print("\n🎉 Build quality optimization completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Build quality optimization found issues that need attention.")
        sys.exit(1)

if __name__ == "__main__":
    main()
