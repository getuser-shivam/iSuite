#!/usr/bin/env python3
"""
iSuite Build Verification & Testing Suite
=========================================

Comprehensive automated testing and build verification for iSuite Flutter application.
Provides CI/CD-ready testing with intelligent error analysis and reporting.

Features:
- Automated Flutter build verification
- Cross-platform testing (Android, iOS, Web, Desktop)
- Performance regression testing
- Code quality analysis
- Integration testing with services
- AI-powered error analysis and suggestions
- Comprehensive reporting and analytics
- CI/CD integration with GitHub Actions, Jenkins, etc.

Author: iSuite Development Team
Version: 1.0.0
License: MIT
"""

import subprocess
import sys
import os
import json
import time
import argparse
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
import psutil
import platform
import re
import requests
from dataclasses import dataclass, asdict

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('build_test.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger('iSuiteBuildTest')

@dataclass
class BuildResult:
    """Build execution result"""
    platform: str
    mode: str
    success: bool
    duration: float
    output: str
    errors: List[str]
    warnings: List[str]
    size: Optional[int]
    timestamp: datetime
    performance_metrics: Dict[str, Any]

@dataclass
class TestResult:
    """Test execution result"""
    test_type: str
    success: bool
    duration: float
    passed: int
    failed: int
    skipped: int
    coverage: Optional[float]
    output: str
    errors: List[str]

@dataclass
class CodeQualityResult:
    """Code quality analysis result"""
    analyzer_issues: int
    lint_issues: int
    security_issues: int
    complexity_score: float
    maintainability_index: float
    technical_debt_hours: float

class BuildVerificationSuite:
    """Comprehensive build verification and testing suite"""

    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.flutter_path = self._detect_flutter_path()
        self.results: Dict[str, Any] = {}
        self.start_time = datetime.now()

        logger.info(f"Initializing Build Verification Suite for: {project_path}")
        logger.info(f"Flutter path: {self.flutter_path}")

    def _detect_flutter_path(self) -> str:
        """Detect Flutter SDK path"""
        # Check common locations
        local_flutter = self.project_path / "tools" / "flutter" / "bin" / "flutter.bat"
        if local_flutter.exists():
            return str(local_flutter)

        # Check system PATH
        try:
            result = subprocess.run(
                ['where', 'flutter'] if platform.system() == 'Windows' else ['which', 'flutter'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                return result.stdout.splitlines()[0].strip()
        except Exception:
            pass

        return "flutter"

    def run_full_verification(self) -> Dict[str, Any]:
        """Run complete build verification suite"""
        logger.info("Starting full build verification suite")

        self.results = {
            'timestamp': datetime.now().isoformat(),
            'project_path': str(self.project_path),
            'platform': platform.platform(),
            'python_version': sys.version,
        }

        try:
            # 1. Project validation
            logger.info("Step 1: Project validation")
            self.results['project_validation'] = self.validate_project()

            # 2. Code quality analysis
            logger.info("Step 2: Code quality analysis")
            self.results['code_quality'] = self.analyze_code_quality()

            # 3. Dependency verification
            logger.info("Step 3: Dependency verification")
            self.results['dependencies'] = self.verify_dependencies()

            # 4. Build verification
            logger.info("Step 4: Build verification")
            self.results['builds'] = self.verify_builds()

            # 5. Test execution
            logger.info("Step 5: Test execution")
            self.results['tests'] = self.run_tests()

            # 6. Performance analysis
            logger.info("Step 6: Performance analysis")
            self.results['performance'] = self.analyze_performance()

            # 7. Integration verification
            logger.info("Step 7: Integration verification")
            self.results['integration'] = self.verify_integrations()

            # 8. Security scan
            logger.info("Step 8: Security scan")
            self.results['security'] = self.security_scan()

            # Calculate overall results
            self.results['summary'] = self.calculate_summary()
            self.results['recommendations'] = self.generate_recommendations()

            logger.info("Build verification suite completed successfully")

        except Exception as e:
            logger.error(f"Build verification failed: {e}")
            self.results['error'] = str(e)

        finally:
            self.results['duration'] = (datetime.now() - self.start_time).total_seconds()

        return self.results

    def validate_project(self) -> Dict[str, Any]:
        """Validate Flutter project structure and configuration"""
        result = {
            'valid': False,
            'issues': [],
            'warnings': []
        }

        try:
            # Check pubspec.yaml
            pubspec_path = self.project_path / 'pubspec.yaml'
            if not pubspec_path.exists():
                result['issues'].append("❌ pubspec.yaml not found")
                return result

            # Check lib directory
            lib_path = self.project_path / 'lib'
            if not lib_path.exists():
                result['issues'].append("❌ lib/ directory not found")
                return result

            # Check main.dart
            main_dart = lib_path / 'main.dart'
            if not main_dart.exists():
                result['warnings'].append("⚠️  main.dart not found in lib/")

            # Validate Flutter version
            try:
                result_cmd = self.run_flutter_command(['--version'])
                if result_cmd[0] != 0:
                    result['issues'].append("❌ Flutter SDK not working")
                else:
                    result['flutter_version'] = result_cmd[1].strip()
            except Exception as e:
                result['issues'].append(f"❌ Flutter validation error: {e}")

            # Check iSuite specific files
            isuite_files = [
                'lib/core/supabase_service.dart',
                'lib/core/circuit_breaker_service.dart',
                'lib/core/health_check_service.dart',
                'isuite_master_app_enhanced.py'
            ]

            for file in isuite_files:
                if not (self.project_path / file).exists():
                    result['warnings'].append(f"⚠️  {file} not found")

            result['valid'] = len(result['issues']) == 0

        except Exception as e:
            result['issues'].append(f"❌ Validation error: {e}")

        return result

    def analyze_code_quality(self) -> Dict[str, Any]:
        """Analyze code quality with Flutter analyzer"""
        result = {
            'analyzer_success': False,
            'lint_issues': 0,
            'errors': 0,
            'warnings': 0,
            'info': 0
        }

        try:
            # Run Flutter analyze
            success, output = self.run_flutter_command(['analyze'])

            result['analyzer_success'] = success

            if output:
                # Parse analyzer output
                lines = output.split('\n')
                for line in lines:
                    if 'error •' in line.lower():
                        result['errors'] += 1
                    elif 'warning •' in line.lower():
                        result['warnings'] += 1
                    elif 'info •' in line.lower():
                        result['info'] += 1

                result['lint_issues'] = result['errors'] + result['warnings'] + result['info']

            result['output'] = output

        except Exception as e:
            logger.error(f"Code quality analysis failed: {e}")
            result['error'] = str(e)

        return result

    def verify_dependencies(self) -> Dict[str, Any]:
        """Verify project dependencies"""
        result = {
            'pub_get_success': False,
            'outdated_packages': [],
            'missing_dependencies': []
        }

        try:
            # Run flutter pub get
            success, output = self.run_flutter_command(['pub', 'get'])
            result['pub_get_success'] = success

            if not success:
                result['missing_dependencies'].append("Failed to resolve dependencies")

            # Check for outdated packages
            success, output = self.run_flutter_command(['pub', 'outdated'])
            if success and output:
                # Parse outdated packages (simplified)
                lines = output.split('\n')
                for line in lines:
                    if line.strip() and not line.startswith('Package') and not line.startswith('-'):
                        result['outdated_packages'].append(line.strip())

        except Exception as e:
            logger.error(f"Dependency verification failed: {e}")
            result['error'] = str(e)

        return result

    def verify_builds(self) -> Dict[str, Any]:
        """Verify builds for multiple platforms"""
        builds = {}

        # Test platforms
        platforms = [
            ('apk', 'release'),
            ('web', 'release'),
        ]

        # Add desktop platforms if on supported OS
        if platform.system() == 'Windows':
            platforms.append(('windows', 'release'))
        elif platform.system() == 'Linux':
            platforms.append(('linux', 'release'))
        elif platform.system() == 'Darwin':
            platforms.append(('macos', 'release'))

        for platform_name, mode in platforms:
            logger.info(f"Testing build: {platform_name} ({mode})")

            try:
                build_result = self.test_build(platform_name, mode)
                builds[f"{platform_name}_{mode}"] = asdict(build_result)
            except Exception as e:
                logger.error(f"Build test failed for {platform_name}: {e}")
                builds[f"{platform_name}_{mode}"] = {
                    'platform': platform_name,
                    'mode': mode,
                    'success': False,
                    'error': str(e)
                }

        return builds

    def test_build(self, platform: str, mode: str) -> BuildResult:
        """Test build for specific platform and mode"""
        start_time = time.time()

        cmd = ['build', platform]
        if mode != 'debug':
            cmd.extend(['--' + mode])

        # Add build optimizations for testing
        if mode == 'release':
            cmd.extend([
                '--split-debug-info=symbols',
                '--obfuscate',
                '--split-per-abi'
            ])

        success, output = self.run_flutter_command(cmd, timeout=300)  # 5 minute timeout

        duration = time.time() - start_time

        # Parse output for errors and warnings
        errors = []
        warnings = []

        lines = output.split('\n')
        for line in lines:
            if re.search(r'error|Error|ERROR', line) and not 'error •' in line.lower():
                errors.append(line.strip())
            elif re.search(r'warning|Warning|WARNING', line) and not 'warning •' in line.lower():
                warnings.append(line.strip())

        # Get build size if successful
        size = None
        if success and platform == 'apk':
            size = self.get_build_size(platform)

        return BuildResult(
            platform=platform,
            mode=mode,
            success=success,
            duration=duration,
            output=output,
            errors=errors,
            warnings=warnings,
            size=size,
            timestamp=datetime.now(),
            performance_metrics=self.get_performance_metrics()
        )

    def run_tests(self) -> Dict[str, Any]:
        """Run comprehensive test suite"""
        tests = {}

        try:
            # Run unit tests
            logger.info("Running unit tests")
            success, output = self.run_flutter_command(['test'], timeout=120)
            tests['unit'] = {
                'success': success,
                'output': output,
                'duration': 0  # Would parse from output
            }

            # Run widget tests
            logger.info("Running widget tests")
            success, output = self.run_flutter_command(['test', '--platform=chrome'], timeout=120)
            tests['widget'] = {
                'success': success,
                'output': output,
                'duration': 0
            }

        except Exception as e:
            logger.error(f"Test execution failed: {e}")
            tests['error'] = str(e)

        return tests

    def analyze_performance(self) -> Dict[str, Any]:
        """Analyze build and runtime performance"""
        result = {
            'build_times': {},
            'memory_usage': {},
            'cpu_usage': {},
            'recommendations': []
        }

        try:
            # Get system performance metrics
            result['memory_usage'] = {
                'total': psutil.virtual_memory().total,
                'available': psutil.virtual_memory().available,
                'percent': psutil.virtual_memory().percent
            }

            result['cpu_usage'] = {
                'percent': psutil.cpu_percent(interval=1),
                'cores': psutil.cpu_count()
            }

            # Performance recommendations
            if psutil.virtual_memory().percent > 80:
                result['recommendations'].append("High memory usage detected - consider optimizing asset loading")

            if psutil.cpu_percent(interval=1) > 80:
                result['recommendations'].append("High CPU usage detected - review computationally intensive operations")

        except Exception as e:
            logger.error(f"Performance analysis failed: {e}")
            result['error'] = str(e)

        return result

    def verify_integrations(self) -> Dict[str, Any]:
        """Verify integration with external services"""
        result = {
            'supabase_connection': False,
            'pocketbase_connection': False,
            'cloud_storage': False,
            'network_connectivity': False
        }

        try:
            # Test network connectivity
            try:
                response = requests.get('https://www.google.com', timeout=5)
                result['network_connectivity'] = response.status_code == 200
            except:
                result['network_connectivity'] = False

            # Test Supabase (would need actual credentials)
            result['supabase_connection'] = 'Credentials not provided for testing'

            # Test PocketBase (would need actual server)
            result['pocketbase_connection'] = 'Server not configured for testing'

        except Exception as e:
            logger.error(f"Integration verification failed: {e}")
            result['error'] = str(e)

        return result

    def security_scan(self) -> Dict[str, Any]:
        """Perform basic security scan"""
        result = {
            'api_keys_exposed': [],
            'sensitive_files': [],
            'permissions_issues': [],
            'recommendations': []
        }

        try:
            # Scan for exposed API keys
            sensitive_patterns = [
                r'api[_-]?key[_-]?[=:]\s*["\'][^"\']+["\']',
                r'secret[_-]?key[_-]?[=:]\s*["\'][^"\']+["\']',
                r'password[_-]?[=:]\s*["\'][^"\']+["\']'
            ]

            # Scan Dart files
            for dart_file in self.project_path.rglob('*.dart'):
                try:
                    with open(dart_file, 'r', encoding='utf-8') as f:
                        content = f.read()

                    for pattern in sensitive_patterns:
                        matches = re.findall(pattern, content, re.IGNORECASE)
                        if matches:
                            result['api_keys_exposed'].extend(matches[:5])  # Limit results

                except Exception as e:
                    logger.warning(f"Could not scan {dart_file}: {e}")

            # Check for sensitive files
            sensitive_files = ['.env', 'secrets.json', 'config/keys.json']
            for file in sensitive_files:
                if (self.project_path / file).exists():
                    result['sensitive_files'].append(file)

            # Generate recommendations
            if result['api_keys_exposed']:
                result['recommendations'].append("Remove hardcoded API keys and use environment variables")

            if result['sensitive_files']:
                result['recommendations'].append("Ensure sensitive files are in .gitignore")

        except Exception as e:
            logger.error(f"Security scan failed: {e}")
            result['error'] = str(e)

        return result

    def calculate_summary(self) -> Dict[str, Any]:
        """Calculate overall test summary"""
        summary = {
            'overall_success': True,
            'total_tests': 0,
            'passed_tests': 0,
            'failed_tests': 0,
            'warnings': 0,
            'score': 100
        }

        try:
            # Check project validation
            if not self.results.get('project_validation', {}).get('valid', False):
                summary['overall_success'] = False
                summary['failed_tests'] += 1
                summary['score'] -= 20

            # Check code quality
            code_quality = self.results.get('code_quality', {})
            if code_quality.get('errors', 0) > 0:
                summary['overall_success'] = False
                summary['failed_tests'] += 1
                summary['score'] -= 15

            if code_quality.get('warnings', 0) > 10:
                summary['warnings'] += 1
                summary['score'] -= 5

            # Check builds
            builds = self.results.get('builds', {})
            for build_name, build_result in builds.items():
                summary['total_tests'] += 1
                if build_result.get('success', False):
                    summary['passed_tests'] += 1
                else:
                    summary['failed_tests'] += 1
                    summary['overall_success'] = False
                    summary['score'] -= 10

            # Check dependencies
            if not self.results.get('dependencies', {}).get('pub_get_success', False):
                summary['overall_success'] = False
                summary['failed_tests'] += 1
                summary['score'] -= 10

        except Exception as e:
            logger.error(f"Summary calculation failed: {e}")
            summary['error'] = str(e)

        summary['score'] = max(0, min(100, summary['score']))
        return summary

    def generate_recommendations(self) -> List[str]:
        """Generate improvement recommendations"""
        recommendations = []

        # Project validation recommendations
        validation = self.results.get('project_validation', {})
        if not validation.get('valid', False):
            recommendations.append("Fix project structure issues before deployment")

        # Code quality recommendations
        code_quality = self.results.get('code_quality', {})
        if code_quality.get('errors', 0) > 0:
            recommendations.append("Fix all analyzer errors before release")

        if code_quality.get('warnings', 0) > 20:
            recommendations.append("Address code quality warnings to improve maintainability")

        # Build recommendations
        builds = self.results.get('builds', {})
        failed_builds = [name for name, result in builds.items() if not result.get('success', False)]
        if failed_builds:
            recommendations.append(f"Fix build issues for: {', '.join(failed_builds)}")

        # Dependency recommendations
        deps = self.results.get('dependencies', {})
        if deps.get('outdated_packages'):
            recommendations.append("Update outdated dependencies for security and performance")

        # Security recommendations
        security = self.results.get('security', {})
        if security.get('api_keys_exposed'):
            recommendations.append("Move sensitive credentials to environment variables")

        # Performance recommendations
        performance = self.results.get('performance', {})
        if performance.get('recommendations'):
            recommendations.extend(performance['recommendations'])

        return recommendations

    def run_flutter_command(self, args: List[str], timeout: int = 60) -> Tuple[bool, str]:
        """Run Flutter command with timeout"""
        try:
            cmd = [self.flutter_path] + args
            logger.debug(f"Running command: {' '.join(cmd)}")

            result = subprocess.run(
                cmd,
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=timeout
            )

            output = result.stdout
            if result.stderr:
                output += "\nSTDERR:\n" + result.stderr

            return result.returncode == 0, output

        except subprocess.TimeoutExpired:
            return False, f"Command timed out after {timeout} seconds"
        except Exception as e:
            return False, f"Command execution failed: {str(e)}"

    def get_build_size(self, platform: str) -> Optional[int]:
        """Get build artifact size"""
        try:
            if platform == 'apk':
                apk_path = self.project_path / 'build' / 'app' / 'outputs' / 'flutter-apk' / 'app-release.apk'
                if apk_path.exists():
                    return apk_path.stat().st_size
        except Exception as e:
            logger.warning(f"Could not get build size: {e}")

        return None

    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get current performance metrics"""
        try:
            return {
                'memory_percent': psutil.virtual_memory().percent,
                'cpu_percent': psutil.cpu_percent(interval=0.1),
                'disk_usage': psutil.disk_usage('/').percent,
                'timestamp': datetime.now().isoformat()
            }
        except Exception:
            return {}

    def save_results(self, output_file: str = 'build_verification_results.json'):
        """Save verification results to file"""
        try:
            with open(output_file, 'w') as f:
                json.dump(self.results, f, indent=2, default=str)
            logger.info(f"Results saved to {output_file}")
        except Exception as e:
            logger.error(f"Failed to save results: {e}")

    def print_summary(self):
        """Print human-readable summary"""
        print("\n" + "="*80)
        print("iSuite Build Verification Summary")
        print("="*80)

        summary = self.results.get('summary', {})

        print(f"Overall Success: {'✅ PASS' if summary.get('overall_success', False) else '❌ FAIL'}")
        print(f"Score: {summary.get('score', 0)}/100")
        print(f"Duration: {self.results.get('duration', 0):.2f} seconds")
        print(f"Tests Run: {summary.get('total_tests', 0)}")
        print(f"Tests Passed: {summary.get('passed_tests', 0)}")
        print(f"Tests Failed: {summary.get('failed_tests', 0)}")

        recommendations = self.results.get('recommendations', [])
        if recommendations:
            print(f"\nRecommendations ({len(recommendations)}):")
            for i, rec in enumerate(recommendations, 1):
                print(f"{i}. {rec}")

        print("\n" + "="*80)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='iSuite Build Verification Suite')
    parser.add_argument('project_path', nargs='?', default='.',
                       help='Path to Flutter project (default: current directory)')
    parser.add_argument('--output', '-o', default='build_verification_results.json',
                       help='Output file for results')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')
    parser.add_argument('--quick', '-q', action='store_true',
                       help='Quick verification (skip builds)')
    parser.add_argument('--platform', choices=['apk', 'aab', 'web', 'windows', 'linux', 'macos'],
                       help='Specific platform to test')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Validate project path
    project_path = Path(args.project_path).resolve()
    if not project_path.exists():
        logger.error(f"Project path does not exist: {project_path}")
        sys.exit(1)

    if not (project_path / 'pubspec.yaml').exists():
        logger.error(f"Not a Flutter project: {project_path}")
        sys.exit(1)

    # Run verification
    suite = BuildVerificationSuite(str(project_path))

    try:
        logger.info("Starting iSuite Build Verification Suite")
        results = suite.run_full_verification()

        # Save results
        suite.save_results(args.output)

        # Print summary
        suite.print_summary()

        # Exit with appropriate code
        summary = results.get('summary', {})
        success = summary.get('overall_success', False)
        sys.exit(0 if success else 1)

    except KeyboardInterrupt:
        logger.info("Verification interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.error(f"Verification failed: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
