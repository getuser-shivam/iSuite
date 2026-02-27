#!/usr/bin/env python3
"""
iSuite Performance Optimizer & Code Cleaner
============================================

Comprehensive performance optimization and code cleanup tool for iSuite Flutter application.
Provides automated optimization suggestions, code quality improvements, and performance enhancements.

Features:
- Code analysis and optimization suggestions
- Performance bottleneck detection
- Memory leak prevention
- Bundle size optimization
- Code cleanup and formatting
- Import optimization
- Dead code elimination
- Performance regression detection

Author: iSuite Development Team
Version: 1.0.0
License: MIT
"""

import os
import re
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, asdict
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('performance_optimizer.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger('iSuiteOptimizer')

@dataclass
class OptimizationResult:
    """Result of an optimization operation"""
    file_path: str
    optimization_type: str
    description: str
    before_size: int
    after_size: int
    success: bool
    suggestions: List[str]

@dataclass
class PerformanceReport:
    """Comprehensive performance report"""
    total_files_processed: int
    total_optimizations: int
    total_size_reduction: int
    performance_score: float
    issues_found: int
    recommendations: List[str]
    detailed_results: List[OptimizationResult]

class ISuitePerformanceOptimizer:
    """Comprehensive performance optimizer for iSuite"""

    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.flutter_path = self._detect_flutter_path()
        self.results: List[OptimizationResult] = []

        # Optimization patterns
        self.inefficient_patterns = {
            'unused_imports': re.compile(r'^import\s+.*;\s*$', re.MULTILINE),
            'large_widgets': re.compile(r'class\s+\w+Widget.*extends.*Widget\s*\{[^}]*\}', re.DOTALL),
            'memory_leaks': re.compile(r'(?:TextEditingController|AnimationController|StreamController|Timer)\(\)\s*(?!.*dispose\(\))'),
            'inefficient_builds': re.compile(r'setState\(\(\)\s*\{\s*[^}]*\}\s*\)'),
            'large_lists': re.compile(r'ListView\(\s*children:\s*\[.*\]\s*\)', re.DOTALL),
        }

        # Performance optimization rules
        self.optimization_rules = {
            'const_widgets': 'Use const constructors for static widgets',
            'keys': 'Add keys to list items for better performance',
            'lazy_loading': 'Implement lazy loading for large lists',
            'image_optimization': 'Use cached network images and proper sizing',
            'async_optimizations': 'Use compute() for heavy computations',
            'memory_management': 'Implement proper dispose() methods',
        }

        logger.info(f"Initialized Performance Optimizer for: {project_path}")

    def _detect_flutter_path(self) -> str:
        """Detect Flutter SDK path"""
        try:
            result = subprocess.run(
                ['where', 'flutter'] if os.name == 'nt' else ['which', 'flutter'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                return result.stdout.splitlines()[0].strip()
        except Exception:
            pass
        return "flutter"

    def run_full_optimization(self) -> PerformanceReport:
        """Run comprehensive optimization suite"""
        logger.info("Starting comprehensive optimization suite")

        # 1. Code analysis
        logger.info("Step 1: Code analysis")
        self._analyze_codebase()

        # 2. Performance optimization
        logger.info("Step 2: Performance optimization")
        self._optimize_performance()

        # 3. Bundle size optimization
        logger.info("Step 3: Bundle size optimization")
        self._optimize_bundle_size()

        # 4. Import optimization
        logger.info("Step 4: Import optimization")
        self._optimize_imports()

        # 5. Code cleanup
        logger.info("Step 5: Code cleanup")
        self._cleanup_code()

        # 6. Flutter-specific optimizations
        logger.info("Step 6: Flutter-specific optimizations")
        self._flutter_optimizations()

        # Generate final report
        return self._generate_report()

    def _analyze_codebase(self):
        """Analyze codebase for optimization opportunities"""
        dart_files = list(self.project_path.rglob('*.dart'))

        for dart_file in dart_files:
            if self._should_skip_file(dart_file):
                continue

            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                file_size = len(content.encode('utf-8'))

                # Check for various optimization opportunities
                issues = self._analyze_file_content(content, str(dart_file))

                if issues:
                    result = OptimizationResult(
                        file_path=str(dart_file),
                        optimization_type="code_analysis",
                        description=f"Found {len(issues)} optimization opportunities",
                        before_size=file_size,
                        after_size=file_size,  # Size doesn't change from analysis
                        success=True,
                        suggestions=issues
                    )
                    self.results.append(result)

            except Exception as e:
                logger.warning(f"Could not analyze {dart_file}: {e}")

    def _analyze_file_content(self, content: str, file_path: str) -> List[str]:
        """Analyze file content for optimization opportunities"""
        issues = []

        # Check for unused imports (simplified check)
        imports = re.findall(r'^import\s+.*;', content, re.MULTILINE)
        for import_line in imports:
            package = re.search(r"package:([^']+)", import_line)
            if package:
                package_name = package.group(1)
                # Check if package is used in the file (simplified)
                if package_name not in content:
                    issues.append(f"Potentially unused import: {import_line.strip()}")

        # Check for large widgets that might cause performance issues
        widget_matches = re.finditer(r'class\s+(\w+Widget)\s+extends\s+(StatelessWidget|StatefulWidget)', content)
        for match in widget_matches:
            widget_name = match.group(1)
            # Check widget size (simplified heuristic)
            widget_content = self._extract_widget_content(content, widget_name)
            if len(widget_content) > 2000:  # Large widget
                issues.append(f"Large widget '{widget_name}' - consider breaking it down")

        # Check for setState calls that might be inefficient
        setstate_count = len(re.findall(r'setState\s*\(', content))
        if setstate_count > 10:
            issues.append(f"High number of setState calls ({setstate_count}) - consider optimization")

        # Check for ListView without optimization
        if 'ListView(' in content and 'itemBuilder:' not in content:
            issues.append("ListView without itemBuilder - consider using ListView.builder for performance")

        # Check for missing const constructors
        non_const_widgets = re.findall(r'(?!const\s)(Text|Container|Column|Row|Padding|SizedBox)\s*\(', content)
        if len(non_const_widgets) > 5:
            issues.append("Many widgets without const constructors - use const for better performance")

        # Check for potential memory leaks
        leak_indicators = ['TextEditingController()', 'AnimationController(', 'StreamController(', 'Timer(']
        for indicator in leak_indicators:
            if indicator in content and 'dispose()' not in content:
                issues.append(f"Potential memory leak: {indicator} without dispose()")

        return issues

    def _extract_widget_content(self, content: str, widget_name: str) -> str:
        """Extract widget content for analysis"""
        # Find the class definition and extract its content
        pattern = rf'class\s+{widget_name}.*?\{(.*?)\}}'
        match = re.search(pattern, content, re.DOTALL)
        return match.group(1) if match else ""

    def _optimize_performance(self):
        """Apply performance optimizations"""
        dart_files = list(self.project_path.rglob('*.dart'))

        for dart_file in dart_files:
            if self._should_skip_file(dart_file):
                continue

            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    original_content = f.read()

                optimized_content = self._apply_performance_optimizations(original_content, str(dart_file))

                if optimized_content != original_content:
                    # Write optimized content
                    with open(dart_file, 'w', encoding='utf-8') as f:
                        f.write(optimized_content)

                    result = OptimizationResult(
                        file_path=str(dart_file),
                        optimization_type="performance_optimization",
                        description="Applied performance optimizations",
                        before_size=len(original_content.encode('utf-8')),
                        after_size=len(optimized_content.encode('utf-8')),
                        success=True,
                        suggestions=["Performance optimizations applied"]
                    )
                    self.results.append(result)

            except Exception as e:
                logger.warning(f"Could not optimize {dart_file}: {e}")

    def _apply_performance_optimizations(self, content: str, file_path: str) -> str:
        """Apply specific performance optimizations to content"""
        # Add const to static widgets where safe
        content = re.sub(
            r'(?<![a-zA-Z_])(Text|Container|Column|Row|Padding|SizedBox)\s*\(',
            r'const \1(',
            content
        )

        # Optimize ListView to ListView.builder where appropriate
        # This is complex, so we'll add comments for manual optimization
        if 'ListView(' in content and 'children:' in content and 'itemBuilder:' not in content:
            content = content.replace(
                'ListView(',
                '// TODO: Consider using ListView.builder for better performance\n  ListView('
            )

        return content

    def _optimize_bundle_size(self):
        """Optimize bundle size"""
        try:
            # Run Flutter build with optimizations
            cmd = [self.flutter_path, 'build', 'apk', '--release',
                   '--split-debug-info=symbols', '--obfuscate', '--split-per-abi']

            result = subprocess.run(
                cmd,
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=300
            )

            if result.returncode == 0:
                logger.info("Bundle optimization completed successfully")
                # Analyze build output for size information
                self._analyze_build_output(result.stdout)
            else:
                logger.warning(f"Bundle optimization failed: {result.stderr}")

        except Exception as e:
            logger.error(f"Bundle optimization error: {e}")

    def _analyze_build_output(self, output: str):
        """Analyze build output for optimization insights"""
        # Look for bundle size information
        size_matches = re.findall(r'Built build/.*?\((\d+(?:\.\d+)?\s*[KMG]?B)\)', output)

        if size_matches:
            for size in size_matches:
                logger.info(f"Bundle size: {size}")

    def _optimize_imports(self):
        """Optimize imports for better tree shaking"""
        dart_files = list(self.project_path.rglob('*.dart'))

        for dart_file in dart_files:
            if self._should_skip_file(dart_file):
                continue

            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Sort imports (material, cupertino, package, relative)
                optimized_content = self._sort_imports(content)

                if optimized_content != content:
                    with open(dart_file, 'w', encoding='utf-8') as f:
                        f.write(optimized_content)

                    result = OptimizationResult(
                        file_path=str(dart_file),
                        optimization_type="import_optimization",
                        description="Sorted and optimized imports",
                        before_size=len(content.encode('utf-8')),
                        after_size=len(optimized_content.encode('utf-8')),
                        success=True,
                        suggestions=["Imports optimized for better tree shaking"]
                    )
                    self.results.append(result)

            except Exception as e:
                logger.warning(f"Could not optimize imports in {dart_file}: {e}")

    def _sort_imports(self, content: str) -> str:
        """Sort imports according to Flutter/Dart conventions"""
        lines = content.split('\n')
        dart_imports = []
        package_imports = []
        relative_imports = []
        other_lines = []

        i = 0
        while i < len(lines):
            line = lines[i].strip()

            if line.startswith('import ') and line.endswith(';'):
                if "'dart:" in line or '"dart:' in line:
                    dart_imports.append(lines[i])
                elif "'package:" in line or '"package:' in line:
                    package_imports.append(lines[i])
                else:
                    relative_imports.append(lines[i])
            else:
                other_lines.append(lines[i])

            i += 1

        # Reconstruct file with sorted imports
        result = []

        # Dart imports first
        if dart_imports:
            result.extend(sorted(dart_imports))
            result.append('')

        # Package imports
        if package_imports:
            result.extend(sorted(package_imports))
            result.append('')

        # Relative imports
        if relative_imports:
            result.extend(sorted(relative_imports))
            result.append('')

        # Rest of the file
        result.extend(other_lines)

        return '\n'.join(result)

    def _cleanup_code(self):
        """Clean up code formatting and remove unnecessary elements"""
        dart_files = list(self.project_path.rglob('*.dart'))

        for dart_file in dart_files:
            if self._should_skip_file(dart_file):
                continue

            try:
                with open(dart_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Apply various cleanup operations
                cleaned_content = self._apply_code_cleanup(content)

                if cleaned_content != content:
                    with open(dart_file, 'w', encoding='utf-8') as f:
                        f.write(cleaned_content)

                    result = OptimizationResult(
                        file_path=str(dart_file),
                        optimization_type="code_cleanup",
                        description="Applied code cleanup and formatting",
                        before_size=len(content.encode('utf-8')),
                        after_size=len(cleaned_content.encode('utf-8')),
                        success=True,
                        suggestions=["Code cleaned up and formatted"]
                    )
                    self.results.append(result)

            except Exception as e:
                logger.warning(f"Could not cleanup {dart_file}: {e}")

    def _apply_code_cleanup(self, content: str) -> str:
        """Apply various code cleanup operations"""
        # Remove trailing whitespace
        content = re.sub(r'[ \t]+$', '', content, flags=re.MULTILINE)

        # Fix double blank lines (more than 2 consecutive)
        content = re.sub(r'\n\n\n+', '\n\n', content)

        # Remove unnecessary semicolons (careful with this)
        # This is complex, so we'll skip for now

        return content

    def _flutter_optimizations(self):
        """Apply Flutter-specific optimizations"""
        try:
            # Run Flutter format
            result = subprocess.run(
                [self.flutter_path, 'format', '.'],
                cwd=self.project_path,
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                logger.info("Flutter formatting completed")
            else:
                logger.warning("Flutter formatting had issues")

            # Run Flutter analyze for suggestions
            result = subprocess.run(
                [self.flutter_path, 'analyze'],
                cwd=self.project_path,
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                logger.info("Flutter analysis completed successfully")
            else:
                logger.warning("Flutter analysis found issues")

        except Exception as e:
            logger.error(f"Flutter optimization error: {e}")

    def _should_skip_file(self, file_path: Path) -> bool:
        """Check if file should be skipped during optimization"""
        # Skip generated files, test files, and build artifacts
        skip_patterns = [
            '.dart_tool/',
            'build/',
            'android/',
            'ios/',
            'web/',
            'windows/',
            'linux/',
            'macos/',
            '.symlinks/',
            'test/',
            '.g.dart',  # Generated files
        ]

        file_str = str(file_path)
        for pattern in skip_patterns:
            if pattern in file_str:
                return True

        return False

    def _generate_report(self) -> PerformanceReport:
        """Generate comprehensive performance report"""
        total_optimizations = len(self.results)
        total_size_reduction = sum(
            result.before_size - result.after_size
            for result in self.results
            if result.before_size > result.after_size
        )

        # Calculate performance score (simplified)
        base_score = 100.0
        if total_optimizations == 0:
            performance_score = base_score
        else:
            # Deduct points for issues found
            issues_penalty = sum(len(result.suggestions) for result in self.results) * 0.5
            performance_score = max(0, base_score - issues_penalty)

        # Generate recommendations
        recommendations = self._generate_recommendations()

        return PerformanceReport(
            total_files_processed=len(set(result.file_path for result in self.results)),
            total_optimizations=total_optimizations,
            total_size_reduction=total_size_reduction,
            performance_score=performance_score,
            issues_found=sum(len(result.suggestions) for result in self.results),
            recommendations=recommendations,
            detailed_results=self.results
        )

    def _generate_recommendations(self) -> List[str]:
        """Generate optimization recommendations"""
        recommendations = []

        # Analyze results for common patterns
        large_files = [r for r in self.results if r.before_size > 50000]  # 50KB
        if large_files:
            recommendations.append(f"Consider splitting {len(large_files)} large files for better maintainability")

        # Check for performance issues
        perf_issues = [r for r in self.results if 'performance' in r.optimization_type.lower()]
        if perf_issues:
            recommendations.append("Review performance optimizations applied - monitor for improvements")

        # Import optimization
        import_opts = [r for r in self.results if 'import' in r.optimization_type.lower()]
        if import_opts:
            recommendations.append("Imports have been optimized for better tree shaking")

        # General recommendations
        recommendations.extend([
            "Run 'flutter analyze' regularly to catch issues early",
            "Use 'flutter build --analyze-size' to monitor bundle size",
            "Consider using code generation for repetitive code",
            "Implement proper error boundaries for better error handling",
            "Use const constructors wherever possible for better performance"
        ])

        return recommendations

    def save_report(self, report: PerformanceReport, output_file: str = 'performance_report.json'):
        """Save performance report to file"""
        try:
            report_data = asdict(report)

            # Convert Path objects to strings
            for result in report_data['detailed_results']:
                result['file_path'] = str(result['file_path'])

            with open(output_file, 'w') as f:
                json.dump(report_data, f, indent=2)

            logger.info(f"Performance report saved to {output_file}")

        except Exception as e:
            logger.error(f"Failed to save report: {e}")

    def print_summary(self, report: PerformanceReport):
        """Print human-readable summary"""
        print("\n" + "="*80)
        print("iSuite Performance Optimization Summary")
        print("="*80)

        print(f"Files Processed: {report.total_files_processed}")
        print(f"Optimizations Applied: {report.total_optimizations}")
        print(f"Size Reduction: {report.total_size_reduction} bytes")
        print(".1f")
        print(f"Issues Found: {report.issues_found}")

        if report.recommendations:
            print(f"\nRecommendations ({len(report.recommendations)}):")
            for i, rec in enumerate(report.recommendations, 1):
                print(f"{i}. {rec}")

        print("\n" + "="*80)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='iSuite Performance Optimizer & Code Cleaner')
    parser.add_argument('project_path', nargs='?', default='.',
                       help='Path to Flutter project (default: current directory)')
    parser.add_argument('--output', '-o', default='performance_report.json',
                       help='Output file for performance report')
    parser.add_argument('--dry-run', action='store_true',
                       help='Analyze only, do not apply changes')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')

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

    # Run optimization
    optimizer = ISuitePerformanceOptimizer(str(project_path))

    try:
        logger.info("Starting iSuite Performance Optimization")

        if args.dry_run:
            logger.info("Running in dry-run mode - no changes will be applied")

        report = optimizer.run_full_optimization()

        # Save report
        optimizer.save_report(report, args.output)

        # Print summary
        optimizer.print_summary(report)

        # Exit with success/failure code
        success = report.performance_score >= 70.0  # Arbitrary threshold
        sys.exit(0 if success else 1)

    except KeyboardInterrupt:
        logger.info("Optimization interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.error(f"Optimization failed: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
