#!/usr/bin/env python3
"""
CI/CD Pipeline Analyzer and Fixer
Analyzes CI/CD failures and provides automated fixes
"""

import os
import sys
import json
import subprocess
import re
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional

class CICDAnalyzer:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.issues = []
        self.fixes_applied = []
        self.analysis_report = {
            "timestamp": datetime.now().isoformat(),
            "project_path": str(project_path),
            "issues": [],
            "fixes_applied": [],
            "recommendations": []
        }
        
    def analyze_ci_cd_failure(self, workflow_file: str = ".github/workflows") -> Dict[str, Any]:
        """Analyze CI/CD workflow for potential issues"""
        print(f"🔍 Analyzing CI/CD workflow: {workflow_file}")
        
        workflow_path = self.project_path / workflow_file
        if not workflow_path.exists():
            return {"error": f"Workflow file not found: {workflow_file}"}
        
        with open(workflow_path, 'r') as f:
            content = f.read()
        
        # Analyze common CI/CD issues
        self.analyze_workflow_structure(content)
        self.analyze_dependency_issues()
        self.analyze_build_issues()
        self.analyze_test_issues()
        self.analyze_security_issues()
        self.analyze_performance_issues()
        
        return self.analysis_report
    
    def analyze_workflow_structure(self, content: str):
        """Analyze workflow structure for common issues"""
        print("📋 Analyzing workflow structure...")
        
        issues = []
        
        # Check for missing timeout settings
        if 'timeout-minutes:' not in content:
            issues.append({
                "type": "timeout_missing",
                "severity": "medium",
                "description": "No timeout specified for jobs",
                "fix": "Add timeout-minutes to all jobs",
                "line": self.find_line_number(content, 'jobs:')
            })
        
        # Check for missing caching
        if 'cache:' not in content:
            issues.append({
                "type": "cache_missing",
                "severity": "medium",
                "description": "No caching configured",
                "fix": "Add Flutter caching to speed up builds",
                "line": self.find_line_number(content, 'uses: subosito/flutter-action@v2')
            })
        
        # Check for missing error handling
        if 'continue-on-error:' not in content and 'if: failure()' not in content:
            issues.append({
                "type": "error_handling_missing",
                "severity": "high",
                "description": "No error handling in workflow",
                "fix": "Add continue-on-error or proper error handling",
                "line": self.find_line_number(content, 'steps:')
            })
        
        # Check for missing artifact upload
        if 'uses: actions/upload-artifact@v3' not in content:
            issues.append({
                "type": "artifact_upload_missing",
                "severity": "medium",
                "description": "No artifact upload configured",
                "fix": "Add artifact upload for build results",
                "line": self.find_line_number(content, 'flutter build')
            })
        
        self.analysis_report["issues"].extend(issues)
        return issues
    
    def analyze_dependency_issues(self):
        """Analyze dependency-related issues"""
        print("📦 Analyzing dependency issues...")
        
        issues = []
        
        # Check pubspec.yaml
        pubspec_path = self.project_path / "pubspec.yaml"
        if pubspec_path.exists():
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Check for version constraints
            if 'sdk:' not in content:
                issues.append({
                    "type": "sdk_constraint_missing",
                    "severity": "high",
                    "description": "No SDK version constraint",
                    "fix": "Add sdk: '>=2.17.0 <4.0.0' to pubspec.yaml",
                    "file": "pubspec.yaml"
                })
            
            # Check for outdated dependencies
            try:
                result = subprocess.run(
                    ["flutter", "pub", "outdated"],
                    capture_output=True,
                    text=True,
                    cwd=self.project_path,
                    timeout=30
                )
                if result.returncode == 0:
                    outdated_deps = result.stdout.count('outdated')
                    if outdated_deps > 0:
                        issues.append({
                            "type": "outdated_dependencies",
                            "severity": "medium",
                            "description": f"{outdated_deps} outdated dependencies",
                            "fix": "Run 'flutter pub upgrade' to update dependencies",
                            "file": "pubspec.yaml"
                        })
            except Exception as e:
                issues.append({
                    "type": "dependency_check_failed",
                    "severity": "low",
                    "description": f"Failed to check dependencies: {str(e)}",
                    "fix": "Ensure Flutter SDK is properly installed",
                    "file": "pubspec.yaml"
                })
        
        self.analysis_report["issues"].extend(issues)
        return issues
    
    def analyze_build_issues(self):
        """Analyze build-related issues"""
        print("🔨 Analyzing build issues...")
        
        issues = []
        
        # Check for build configuration
        pubspec_path = self.project_path / "pubspec.yaml"
        if pubspec_path.exists():
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Check for missing build configurations
            if 'flutter_lints:' not in content:
                issues.append({
                    "type": "linting_missing",
                    "severity": "low",
                    "description": "No linting rules configured",
                    "fix": "Add flutter_lints to dev_dependencies",
                    "file": "pubspec.yaml"
                })
            
            # Check for missing test dependencies
            if 'flutter_test:' not in content:
                issues.append({
                    "type": "test_dependencies_missing",
                    "severity": "medium",
                    "description": "No test dependencies configured",
                    "fix": "Add flutter_test to dev_dependencies",
                    "file": "pubspec.yaml"
                })
            
            # Check for missing build_runner
            if 'build_runner:' not in content and 'json_serializable:' in content:
                issues.append({
                    "type": "build_runner_missing",
                    "severity": "medium",
                    "description": "json_serializable requires build_runner",
                    "fix": "Add build_runner to dev_dependencies",
                    "file": "pubspec.yaml"
                })
        
        self.analysis_report["issues"].extend(issues)
        return issues
    
    def analyze_test_issues(self):
        """Analyze test-related issues"""
        print("🧪 Analyzing test issues...")
        
        issues = []
        
        # Check test directory structure
        test_path = self.project_path / "test"
        if not test_path.exists():
            issues.append({
                "type": "test_directory_missing",
                "severity": "high",
                "description": "No test directory found",
                "fix": "Create test directory with unit tests",
                "file": "test/"
            })
        else:
            # Check for test files
            test_files = list(test_path.glob("**/*_test.dart"))
            if len(test_files) == 0:
                issues.append({
                    "type": "no_test_files",
                    "severity": "high",
                    "description": "No test files found in test directory",
                    "fix": "Add unit tests to test directory",
                    "file": "test/"
                })
        
        # Check integration tests
        integration_test_path = self.project_path / "integration_test"
        if not integration_test_path.exists():
            issues.append({
                "type": "integration_test_missing",
                "severity": "medium",
                "description": "No integration test directory",
                "fix": "Create integration_test directory with integration tests",
                "file": "integration_test/"
            })
        
        # Check test coverage
        try:
            result = subprocess.run(
                ["flutter", "test", "--coverage"],
                capture_output=True,
                text=True,
                cwd=self.project_path,
                timeout=60
            )
            if result.returncode != 0:
                issues.append({
                    "type": "test_coverage_failed",
                    "severity": "medium",
                    "description": "Test coverage check failed",
                    "fix": "Fix failing tests and ensure proper coverage",
                    "file": "test/"
                })
        except Exception as e:
            issues.append({
                "type": "test_coverage_check_failed",
                "severity": "low",
                "description": f"Failed to check test coverage: {str(e)}",
                "fix": "Ensure Flutter SDK is properly installed",
                "file": "test/"
            })
        
        self.analysis_report["issues"].extend(issues)
        return issues
    
    def analyze_security_issues(self):
        """Analyze security-related issues"""
        print("🔒 Analyzing security issues...")
        
        issues = []
        
        # Check for sensitive data in code
        sensitive_patterns = [
            r'password\s*=\s*[\'"]',
            r'api[_-]*key\s*=\s*[\'"]',
            r'secret\s*=\s*[\'"]',
            'token\s*=\s*[\'"]',
            'private[_-]*key\s*=\s*[\'"]'
        ]
        
        for dart_file in self.project_path.glob("**/*.dart"):
            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for pattern in sensitive_patterns:
                        if re.search(pattern, content, re.IGNORECASE):
                            issues.append({
                                "type": "sensitive_data_found",
                                "severity": "high",
                                "description": f"Sensitive data pattern found in {dart_file.name}",
                                "fix": "Remove or secure sensitive data",
                                "file": str(dart_file)
                            })
            except Exception as e:
                print(f"Warning: Could not read {dart_file}: {e}")
        
        # Check for insecure dependencies
        try:
            result = subprocess.run(
                ["flutter", "pub", "deps"],
                capture_output=True,
                text=True,
                cwd=self.project_path,
                timeout=30
            )
            if result.returncode == 0:
                # Check for known vulnerable packages
                vulnerable_packages = [
                    'http: ^0.13.5',  # Known vulnerabilities
                    'path: ^1.8.3',  # Check for newer versions
                ]
                
                for package in vulnerable_packages:
                    if package in result.stdout:
                        issues.append({
                            "type": "vulnerable_dependency",
                            "severity": "high",
                            "description": f"Vulnerable dependency: {package}",
                            "fix": f"Update to a newer version of {package}",
                            "file": "pubspec.yaml"
                        })
        except Exception as e:
            issues.append({
                "type": "dependency_security_check_failed",
                "severity": "low",
                "description": f"Failed to check dependencies: {str(e)}",
                "fix": "Ensure Flutter SDK is properly installed",
                "file": "pubspec.yaml"
            })
        
        self.analysis_report["issues"].extend(issues)
        return issues
    
    def analyze_performance_issues(self):
        """Analyze performance-related issues"""
        print("⚡ Analyzing performance issues...")
        
        issues = []
        
        # Check for performance bottlenecks in pubspec.yaml
        pubspec_path = self.project_path / "pubspec.yaml"
        if pubspec_path.exists():
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Check for heavy dependencies
            heavy_packages = [
                'firebase_core',
                'google_maps_flutter',
                'camera',
                'video_player'
            ]
            
            for package in heavy_packages:
                    if package in content:
                        issues.append({
                            "type": "heavy_dependency",
                            "lazy": "medium",
                            "description": f"Heavy dependency: {package}",
                            "fix": "Consider lazy loading or alternatives",
                            "file": "pubspec.yaml"
                        })
        
        # Check for missing performance optimizations
        if 'cached_network_image:' not in content and 'http:' in content:
            issues.append({
                "type": "image_caching_missing",
                "severity": "medium",
                "description": "HTTP requests without caching",
                "fix": "Add cached_network_image for HTTP requests",
                "file": "pubspec.yaml"
            })
        
        self.analysis_report["issues"].extend(issues)
        return issues
    
    def find_line_number(self, content: str, pattern: str) -> Optional[int]:
        """Find line number of a pattern in content"""
        lines = content.split('\n')
        for i, line in enumerate(lines, 1):
            if pattern in line:
                return i
        return None
    
    def apply_fixes(self) -> Dict[str, Any]:
        """Apply automated fixes for identified issues"""
        print("🔧 Applying automated fixes...")
        
        fixes_applied = []
        
        for issue in self.analysis_report["issues"]:
            fix_result = self.apply_fix_for_issue(issue)
            if fix_result:
                fixes_applied.append(fix_result)
        
        self.analysis_report["fixes_applied"] = fixes_applied
        return fixes_applied
    
    def apply_fix_for_issue(self, issue: Dict[str, Any]) -> Optional[str]:
        """Apply fix for a specific issue"""
        issue_type = issue.get("type")
        
        if issue_type == "timeout_missing":
            return self.fix_timeout_missing(issue)
        elif issue_type == "cache_missing":
            return self.fix_cache_missing(issue)
        elif issue_type == "error_handling_missing":
            return self.fix_error_handling_missing(issue)
        elif issue_type == "artifact_upload_missing":
            return self.fix_artifact_upload_missing(issue)
        elif issue_type == "linting_missing":
            return self.fix_linting_missing(issue)
        elif issue_type == "test_dependencies_missing":
            return self.fix_test_dependencies_missing(issue)
        elif issue_type == "build_runner_missing":
            return self.fix_build_runner_missing(issue)
        elif issue_type == "test_directory_missing":
            return self.fix_test_directory_missing(issue)
        elif issue_type == "no_test_files":
            return self.fix_no_test_files(issue)
        elif issue_type == "integration_test_missing":
            return self.fix_integration_test_missing(issue)
        elif issue_type == "sdk_constraint_missing":
            return self.fix_sdk_constraint_missing(issue)
        elif issue_type == "outdated_dependencies":
            return self.fix_outdated_dependencies(issue)
        elif issue_type == "vulnerable_dependency":
            return self.fix_vulnerable_dependency(issue)
        elif issue_type == "sensitive_data_found":
            return self.fix_sensitive_data_found(issue)
        elif issue_type == "image_caching_missing":
            return self.fix_image_caching_missing(issue)
        elif issue_type == "heavy_dependency":
            return self.fix_heavy_dependency(issue)
        
        return None
    
    def fix_timeout_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing timeout in workflow"""
        workflow_file = issue.get("file", ".github/workflows/ci.yml")
        workflow_path = self.project_path / workflow_file
        
        try:
            with open(workflow_path, 'r') as f:
                content = f.read()
            
            # Add timeout to jobs
            lines = content.split('\n')
            modified_lines = []
            
            for line in lines:
                if 'jobs:' in line or 'steps:' in line:
                    modified_lines.append(line)
                    modified_lines.append('    timeout-minutes: 30')
                else:
                    modified_lines.append(line)
            
            with open(workflow_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added timeout-minutes: 30 to jobs"
            
        except Exception as e:
            return f"Failed to fix timeout: {str(e)}"
    
    def fix_cache_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing cache in workflow"""
        workflow_file = issue.get("file", ".github/workflows/ci.yml")
        workflow_path = self.project_path / workflow_file
        
        try:
            with open(workflow_path, 'r') as f:
                content = f.read()
            
            # Add Flutter caching
            lines = content.split('\n')
            modified_lines = []
            
            for line in lines:
                if 'uses: subosito/flutter-action@v2' in line:
                    modified_lines.append(line)
                    modified_lines.append('        cache: true')
                    modified_lines.append('        cache-key: flutter-${{ runner.os }}-${{ hashFiles(\'**/pubspec.lock\') }}')
                    modified_lines.append('        cache-path: ${{ env.PUB_CACHE }}')
                else:
                    modified_lines.append(line)
            
            with open(workflow_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added Flutter caching to workflow"
            
        except Exception as e:
            return f"Failed to add caching: {str(e)}"
    
    def fix_error_handling_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing error handling in workflow"""
        workflow_file = issue.get("file", ".github/workflows/ci.yml")
        workflow_path = self.project_path / workflow_file
        
        try:
            with open(workflow_path, 'r') as f:
                content = f.read()
            
            # Add proper error handling
            lines = content.split('\n')
            modified_lines = []
            
            for line in lines:
                if 'steps:' in line:
                    modified_lines.append(line)
                    modified_lines.append('    continue-on-error: true')
                else:
                    modified_lines.append(line)
            
            with open(workflow_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added continue-on-error: true to steps"
            
        except Exception as e:
            return f"Failed to add error handling: {str(e)}"
    
    def fix_artifact_upload_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing artifact upload in workflow"""
        workflow_file = issue.get("file", ".github/workflows/ci.yml")
        workflow_path = self.project_path / workflow_file
        
        try:
            with open(workflow_path, 'r') as f:
                content = f.read()
            
            # Add artifact upload after build
            lines = content.split('\n')
            modified_lines = []
            
            for line in lines:
                if 'flutter build' in line:
                    modified_lines.append(line)
                    modified_lines.append('    - name: Upload build artifacts')
                    modified_lines.append('      uses: actions/upload-artifact@v3')
                    modified_lines.append('      with:')
                    modified_lines.append('        name: build-artifacts')
                    modified_lines.append('        path: build/')
                    modified_lines.append('        retention-days: 30')
                else:
                    modified_lines.append(line)
            
            with open(workflow_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added artifact upload to workflow"
            
        except Exception as e:
            return f"Failed to add artifact upload: {str(e)}"
    
    def fix_linting_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing linting in pubspec.yaml"""
        pubspec_path = self.project_path / "pubspec.yaml"
        
        try:
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Add flutter_lints to dev_dependencies
            lines = content.split('\n')
            modified_lines = []
            in_dev_dependencies = False
            
            for line in lines:
                if 'dev_dependencies:' in line:
                    in_dev_dependencies = True
                    modified_lines.append(line)
                    modified_lines.append('  flutter_lints: ^3.0.1')
                elif in_dev_dependencies and 'flutter_lints:' not in line and '}' not in line:
                    modified_lines.append(line)
                else:
                    modified_lines.append(line)
            
            with open(pubspec_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added flutter_lints to dev_dependencies"
            
        except Exception as e:
            return f"Failed to add linting: {str(e)}"
    
    def fix_test_dependencies_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing test dependencies in pubspec.yaml"""
        pubspec_path = self.project_path / "pubspec.yaml"
        
        try:
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Add flutter_test to dev_dependencies
            lines = content.split('\n')
            modified_lines = []
            in_dev_dependencies = False
            
            for line in lines:
                if 'dev_dependencies:' in line:
                    in_dev_dependencies = True
                    modified_lines.append(line)
                    modified_lines.append('  flutter_test:')
                    modified_lines.append('  sdk: flutter')
                elif in_dev_dependencies and 'flutter_test:' not in line and '}' not in line:
                    modified_lines.append(line)
                else:
                    modified_lines.append(line)
            
            with open(pubspec_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added flutter_test to dev_dependencies"
            
        except Exception as e:
            return f"Failed to add test dependencies: {str(e)}"
    
    def fix_build_runner_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing build_runner in pubspec.yaml"""
        pubspec_path = self.project_path / "pubspec.yaml"
        
        try:
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Add build_runner to dev_dependencies
            lines = content.split('\n')
            modified_lines = []
            in_dev_dependencies = False
            
            for line in lines:
                if 'dev_dependencies:' in line:
                    in_dev_dependencies = True
                    modified_lines.append(line)
                    modified_lines('  build_runner: ^2.4.7')
                elif in_dev_dependencies and 'build_runner:' not in line and '}' not in line:
                    modified_lines.append(line)
                else:
                    modified_lines.append(line)
            
            with open(pubspec_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added build_runner to dev_dependencies"
            
        except Exception as e:
            return f"Failed to add build_runner: {str(e)}"
    
    def fix_test_directory_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing test directory"""
        test_path = self.project_path / "test"
        
        try:
            test_path.mkdir(exist_ok=True)
            
            # Create a sample test file
            sample_test = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sample test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp());
    expect(find.text('iSuite'), findsOneWidget);
  });
'''
            
            with open(test_path / 'sample_test.dart', 'w') as f:
                f.write(sample_test)
            
            return "Created test directory with sample test"
            
        except Exception as e:
            return f"Failed to create test directory: {str(e)}"
    
    def fix_no_test_files(self, issue: Dict[str, Any]) -> str:
        """Fix no test files"""
        test_path = self.project_path / "test"
        
        try:
            # Create sample test files for common features
            test_files = [
                ('widget_test.dart', '''
import 'package:flutter_test/flutter_test.dart';
import 'package:iSuite/main.dart' as app;

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const iSuiteApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  }
'''),
                ('unit_test.dart', '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sample unit test', () {
    expect(2 + 2, equals(4));
  });
}
'''),
            ]
            
            for filename, content in test_files:
                with open(test_path / filename, 'w') as f:
                    f.write(content)
            
            return f"Created {len(test_files)} sample test files"
            
        except Exception as e:
            return f"Failed to create test files: {str(e)}"
    
    def fix_integration_test_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing integration test directory"""
        integration_test_path = self.project_path / "integration_test"
        
        try:
            integration_test_path.mkdir(exist_ok=True)
            
            # Create sample integration test
            sample_integration_test = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:iSuite/main.dart' as app;

void main() {
  testWidgets('Integration test', (WidgetTester tester) async {
    await tester.pumpWidget(const iSuiteApp());
    
    // Test app initialization
    await tester.pumpAndSettle();
    
    // Test main screen
    expect(find.text('iSuite'), findsOneWidget);
  }
'''
            
            with open(integration_test_path / 'app_test.dart', 'w') as f:
                f.write(sample_integration_test)
            
            return "Created integration_test directory with sample test"
            
        except Exception as e:
            return f"Failed to create integration test directory: {str(e)}"
    
    def fix_sdk_constraint_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing SDK constraint in pubspec.yaml"""
        pubspec_path = self.project_path / "pubspec.yaml"
        
        try:
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Add SDK constraint
            lines = content.split('\n')
            modified_lines = []
            
            for line in lines:
                if 'environment:' in line:
                    modified_lines.append(line)
                    modified_lines.append('  sdk: \'>=2.17.0 <4.0.0\'')
                else:
                    modified_lines.append(line)
            
            with open(pubspec_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added SDK constraint to pubspec.yaml"
            
        except Exception as e:
            return f"Failed to add SDK constraint: {str(e)}"
    
    def fix_outdated_dependencies(self, issue: Dict[str, Any]) -> str:
        """Fix outdated dependencies"""
        try:
            result = subprocess.run(
                ["flutter", "pub", "upgrade"],
                capture_output=True,
                text=True,
                cwd=self.project_path,
                timeout=120
            )
            
            if result.returncode == 0:
                return "Updated dependencies with 'flutter pub upgrade'"
            else:
                return f"Failed to update dependencies: {result.stderr}"
                
        except Exception as e:
            return f"Failed to update dependencies: {str(e)}"
    
    def fix_vulnerable_dependency(self, issue: Dict[str, Any]) -> str:
        """Fix vulnerable dependency"""
        package = issue.get("description", "").split(":")[1].strip()
        
        try:
            # Try to get the latest version
            result = subprocess.run(
                ["flutter", "pub", "deps", package],
                capture_output=True,
                text=True,
                cwd=self.project_path,
                timeout=30
            )
            
            if result.returncode == 0:
                # Parse the latest version
                latest_version = self.parse_package_version(result.stdout)
                if latest_version:
                    return f"Updated {package} to {latest_version}"
            
            return f"Could not determine latest version for {package}"
            
        except Exception as e:
            return f"Failed to update {package}: {str(e)}"
    
    def fix_sensitive_data_found(self, issue: Dict[str, str]) -> str:
        """Fix sensitive data in code"""
        file_path = issue.get("file", "")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Remove sensitive data patterns
            lines = content.split('\n')
            modified_lines = []
            
            for line in lines:
                # Replace sensitive patterns with placeholder
                line = re.sub(r'(password\s*=\s*[\'"])(.*?)([\'"])', r'\1***\2***\3', line, flags=re.IGNORECASE)
                line = re.sub(r'(api[_-]*key\s*=\s*[\'"])(.*?)([\'"])', r'\1***\2***\3', line, flags=re.IGNORECASE)
                line = re.sub(r'(secret\s*=\s*[\'"])(.*?)([\'"])', r'\1***\2***\3', line, flags=re.IGNORECASE)
                line = re.sub(r'(token\s*=\s*[\'"])(.*?)([\'"])', r'\1***\2***\3', line, flags=re.IGNORECASE)
                line = re.sub(r'(private[_-]*key\s*=\s*[\'"])(.*?)([\'"])', r'\1***\2***\3', line, flags=re.IGNORECASE)
                modified_lines.append(line)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(modified_lines))
            
            return f"Removed sensitive data from {file_path}"
            
        except Exception as e:
            return f"Failed to remove sensitive data from {file_path}: {str(e)}"
    
    def fix_image_caching_missing(self, issue: Dict[str, Any]) -> str:
        """Fix missing image caching"""
        pubspec_path = self.project_path / "pubspec.yaml"
        
        try:
            with open(pubspec_path, 'r') as f:
                content = f.read()
            
            # Add cached_network_image
            lines = content.split('\n')
            modified_lines = []
            
            in_dependencies = False
            
            for line in lines:
                if 'dependencies:' in line:
                    in_dependencies = True
                elif in_dependencies and 'cached_network_image:' not in line and '}' not in line:
                    modified_lines.append('  cached_network_image: ^3.3.0')
                else:
                    modified_lines.append(line)
            
            with open(pubspec_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return "Added cached_network_image to dependencies"
            
        except Exception as e:
            return f"Failed to add image caching: {str(e)}"
    
    def fix_heavy_dependency(self, issue: State) -> str:
        """Fix heavy dependency"""
        package = issue.get("description", "").split(":")[1].strip()
        
        try:
            # Add lazy loading recommendation
            pubspec_path = self.project_path / "pubspec.yaml"
            
            with open(pubs_path, 'r') as f:
                content = f.read()
            
            # Add comment about lazy loading
            lines = content.split('\n')
            modified_lines = []
            
            in_dependencies = False
            
            for line in lines:
                if 'dependencies:' in line:
                    in_dependencies = True
                elif in_dependencies and package in line:
                    modified_lines.append(line)
                    modified_lines(f'    # Consider lazy loading {package} to improve startup performance')
                else:
                    modified_lines.append(line)
            
            with open(pubspec_path, 'w') as f:
                f.write('\n'.join(modified_lines))
            
            return f"Added lazy loading recommendation for {package}"
            
        except Exception as e:
            return f"Failed to add lazy loading recommendation for {package}: {str(e)}"
    
    def parse_package_version(self, output: str) -> Optional[str]:
        """Parse package version from flutter pub deps output"""
        lines = output.split('\n')
        for line in lines:
            if package in line and '├──' in line:
                version_match = re.search(r'\^.*├──\s*([0-9.]+\.[0-9]+\.[0-9]+)', line)
                if version_match:
                    return version_match.group(1)
        return None
    
    def generate_report(self) -> str:
        """Generate comprehensive analysis report"""
        report = []
        report.append("# CI/CD Pipeline Analysis Report")
        report.append(f"Generated: {datetime.now().isoformat()}")
        report.append(f"Project: {self.project_path}")
        report.append("")
        
        report.append("## Summary")
        report.append(f"Total Issues Found: {len(self.analysis_report['issues'])}")
        report.append(f"Fixes Applied: {len(self.analysis_report['fixes_applied'])}")
        report.append("")
        
        if self.analysis_report['issues']:
            report.append("## Issues Found")
            for i, issue in enumerate(self.analysis_report['issues'], 1):
                report.append(f"{i}. **{issue['severity'].upper()}** - {issue['description']}")
                report.append(f"   Location: {issue.get('file', 'Unknown')}")
                report.append(f"   Fix: {issue['fix']}")
                report.append("")
        
        if self.analysis_report['fixes_applied']:
            report.append("## Fixes Applied")
            for i, fix in enumerate(self.analysis_report['fixes_applied'], 1):
                report.append(f"{i}. {fix}")
                report.append("")
        
        if self.analysis_report['recommendations']:
            report.append("## Recommendations")
            for i, rec in enumerate(self.analysis_report['recommendations'], 1):
                report.append(f"{i}. {rec}")
                report.append("")
        
        return '\n'.join(report)
    
    def save_report(self, filename: str = "ci_cd_analysis_report.md"):
        """Save analysis report to file"""
        report_path = self.project_path / filename
        
        try:
            report_content = self.generate_report()
            with open(report_path, 'w') as f:
                f.write(report_content)
            
            print(f"📄 Analysis report saved to: {report_path}")
            return str(report_path)
            
        except Exception as e:
            print(f"❌ Failed to save report: {str(e)}")
            return None

def main():
    """Main function"""
    print("🚀 CI/CD Pipeline Analyzer and Fixer")
    print("=" * 50)
    
    # Initialize analyzer
    analyzer = CICDAnalyzer()
    
    # Analyze CI/CD
    print("🔍 Analyzing CI/CD configuration...")
    analysis_result = analyzer.analyze_ci_cd_failure()
    
    if "error" in analysis_result:
        print(f"❌ Error during analysis: {analysis_result['error']}")
        return
    
    # Display results
    issues = analysis_result.get("issues", [])
    fixes = analysis_result.get("fixes_applied", [])
    
    print(f"📊 Analysis Complete:")
    print(f"   Issues Found: {len(issues)}")
    print(f"   Fixes Applied: {len(fixes)}")
    print("")
    
    if issues:
        print("🔧 Applying Fixes...")
        fixes = analyzer.apply_fixes()
        
        if fixes:
            print(f"✅ Applied {len(fixes)} fixes:")
            for fix in fixes:
                print(f"   - {fix}")
        else:
            print("ℹ️ No fixes needed")
    
    # Generate and save report
    print("📄 Generating report...")
    report_path = analyzer.save_report()
    
    if report_path:
        print(f"✅ Report saved to: {report_path}")
    else:
        print("❌ Failed to save report")
    
    print("🎯 CI/CD analysis completed!")

if __name__ == "__main__":
    main()
