#!/usr/bin/env python3
"""
iSuite Build Optimizer and Quality Assurance Script
Enhanced with comprehensive checks for production readiness
"""

import os
import sys
import subprocess
import json
import time
import argparse
from pathlib import Path
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from enum import Enum

class CheckStatus(Enum):
    SUCCESS = "success"
    WARNING = "warning"
    ERROR = "error"
    INFO = "info"

@dataclass
class CheckResult:
    status: CheckStatus
    message: str
    details: Optional[str] = None
    fix_suggestion: Optional[str] = None

class BuildOptimizer:
    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.logger = self._setup_logger()
        self.results: List[CheckResult] = []
        
    def _setup_logger(self) -> Any:
        """Setup logging for the build optimizer"""
        import logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('build_optimizer.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        return logging.getLogger(__name__)
        
    def run_all_checks(self) -> Dict[str, Any]:
        """Run all quality checks and return comprehensive report"""
        self.logger.info("Starting iSuite Build Optimizer and Quality Assurance")
        
        # Core checks
        self.check_flutter_doctor()
        self.check_dependencies()
        self.check_code_quality()
        self.check_security()
        self.check_performance()
        self.check_documentation()
        self.check_build_readiness()
        
        # Feature-specific checks
        self.check_voice_translation()
        self.check_network_features()
        self.check_ai_features()
        self.check_collaboration_features()
        self.check_plugin_system()
        
        # Generate final report
        report = self.generate_report()
        self.save_report(report)
        
        return report
        
    def check_flutter_doctor(self) -> None:
        """Check Flutter doctor status"""
        self.logger.info("Checking Flutter doctor...")
        
        try:
            result = subprocess.run(
                ['flutter', 'doctor'],
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.results.append(CheckResult(
                    CheckStatus.SUCCESS,
                    "Flutter doctor check passed"
                ))
            else:
                self.results.append(CheckResult(
                    CheckStatus.ERROR,
                    "Flutter doctor check failed",
                    result.stdout,
                    "Run 'flutter doctor' and fix issues"
                ))
        except subprocess.TimeoutExpired:
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Flutter doctor check timed out",
                None,
                "Check network connection and Flutter installation"
            ))
        except Exception as e:
            self.logger.error(f"Flutter doctor check failed: {e}")
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                f"Flutter doctor check failed: {str(e)}",
                None,
                "Ensure Flutter is properly installed and in PATH"
            ))
    
    def check_dependencies(self) -> None:
        """Check project dependencies"""
        self.logger.info("Checking dependencies...")
        
        pubspec_path = self.project_path / "pubspec.yaml"
        if not pubspec_path.exists():
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                "pubspec.yaml not found",
                None,
                "Create pubspec.yaml file in project root"
            ))
            return
            
        try:
            result = subprocess.run(
                ['flutter', 'pub', 'get'],
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                self.results.append(CheckResult(
                    CheckStatus.SUCCESS,
                    "Dependencies installed successfully"
                ))
            else:
                self.results.append(CheckResult(
                    CheckStatus.ERROR,
                    "Dependency installation failed",
                    result.stdout,
                    "Check pubspec.yaml and internet connection"
                ))
        except Exception as e:
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                f"Dependency check failed: {str(e)}",
                None,
                "Check Flutter and internet connection"
            ))
    
    def check_code_quality(self) -> None:
        """Check code quality and formatting"""
        self.logger.info("Checking code quality...")
        
        # Check formatting
        try:
            result = subprocess.run(
                ['flutter', 'format', '--set-exit-if-changed', '.'],
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.results.append(CheckResult(
                    CheckStatus.SUCCESS,
                    "Code formatting is correct"
                ))
            else:
                self.results.append(CheckResult(
                    CheckStatus.WARNING,
                    "Code formatting issues found",
                    result.stdout,
                    "Run 'flutter format .' to fix formatting"
                ))
        except Exception as e:
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                f"Code formatting check failed: {str(e)}",
                None,
                "Check Flutter installation"
            ))
        
        # Check analysis
        try:
            result = subprocess.run(
                ['flutter', 'analyze'],
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.results.append(CheckResult(
                    CheckStatus.SUCCESS,
                    "Static analysis passed"
                ))
            else:
                self.results.append(CheckResult(
                    CheckStatus.WARNING,
                    "Static analysis issues found",
                    result.stdout,
                    "Fix analysis issues before production"
                ))
        except Exception as e:
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                f"Static analysis failed: {str(e)}",
                None,
                "Check Flutter installation"
            ))
    
    def check_security(self) -> None:
        """Check security vulnerabilities"""
        self.logger.info("Checking security...")
        
        # Check for sensitive data in code
        sensitive_patterns = [
            'password',
            'api_key',
            'secret',
            'token',
            'private_key'
        ]
        
        lib_path = self.project_path / "lib"
        if lib_path.exists():
            for pattern in sensitive_patterns:
                try:
                    result = subprocess.run(
                        ['grep', '-r', '-i', pattern, str(lib_path)],
                        capture_output=True,
                        text=True,
                        timeout=10
                    )
                    
                    if result.returncode == 0 and result.stdout.strip():
                        self.results.append(CheckResult(
                            CheckStatus.WARNING,
                            f"Potential sensitive data found: {pattern}",
                            result.stdout.strip()[:200],
                            "Review and secure sensitive data"
                        ))
                except Exception as e:
                    self.logger.debug(f"Security check for {pattern} failed: {e}")
        
        # Check for insecure dependencies
        pubspec_path = self.project_path / "pubspec.yaml"
        if pubspec_path.exists():
            try:
                with open(pubspec_path, 'r') as f:
                    content = f.read()
                    
                insecure_packages = [
                    'http: ^0.13.0',  # Known vulnerabilities
                    'dart:convert: ^2.0.0',
                    'path: ^1.8.0',
                ]
                
                for package in insecure_packages:
                    if package in content:
                        self.results.append(CheckResult(
                            CheckStatus.WARNING,
                            f"Potentially insecure package: {package}",
                            None,
                            "Update to latest version"
                        ))
            except Exception as e:
                self.logger.debug(f"Security dependency check failed: {e}")
    
    def check_performance(self) -> None:
        """Check performance metrics"""
        self.logger.info("Checking performance...")
        
        # Check app size
        build_path = self.project_path / "build"
        if build_path.exists():
            try:
                total_size = 0
                for root, dirs, files in os.walk(build_path):
                    for file in files:
                        total_size += os.path.getsize(file)
                
                size_mb = total_size / (1024 * 1024)
                if size_mb > 100:  # 100MB threshold
                    self.results.append(CheckResult(
                        CheckStatus.WARNING,
                        f"Large app size: {size_mb:.1f}MB",
                        None,
                        "Consider optimizing assets and code"
                    ))
                else:
                    self.results.append(CheckResult(
                        CheckStatus.SUCCESS,
                        f"App size acceptable: {size_mb:.1f}MB"
                    ))
            except Exception as e:
                self.results.append(CheckResult(
                    CheckStatus.ERROR,
                    f"Performance check failed: {str(e)}",
                    None,
                    "Check build directory"
                ))
        
        # Check for performance issues in code
        lib_path = self sync_get_lib_path()
        if lib_path.exists():
            try:
                # Check for synchronous operations in UI
                result = subprocess.run(
                    ['grep', '-r', 'await', str(lib_path)],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                await_count = result.stdout.count('await')
                if await_count > 100:
                    self.results.append(CatchResult(
                        CheckStatus.WARNING,
                        f"High number of await operations: {await_count}",
                        None,
                        "Consider optimizing async operations"
                    ))
            except Exception as e:
                self.logger.debug(f"Performance check failed: {e}")
    
    def check_documentation(self) -> None:
        """Check documentation completeness"""
        self.logger.info("Checking documentation...")
        
        # Check README.md
        readme_path = self.project_path / "README.md"
        if readme_path.exists():
            try:
                with open(readme_path, 'r') as f:
                    readme_content = f.read()
                
                required_sections = [
                    '# iSuite',
                    '## Features',
                    '## Getting Started',
                    '## Build',
                    '## License'
                ]
                
                missing_sections = []
                for section in required_sections:
                    if section not in readme_content:
                        missing_sections.append(section)
                
                if missing_sections:
                    self.results.append(CheckResult(
                        CheckStatus.WARNING,
                        f"Missing README sections: {', '.join(missing_sections)}",
                        None,
                        "Update README.md with missing sections"
                    ))
                else:
                    self.results.append(CheckResult(
                        CheckStatus.SUCCESS,
                        "README documentation is complete"
                    ))
            except Exception as e:
                self.results.append(CheckResult(
                    CheckStatus.ERROR,
                    f"README check failed: {str(e)}",
                    None,
                    "Check README.md file"
                ))
        else:
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                "README.md not found",
                None,
                "Create comprehensive README.md"
            ))
        
        # Check API documentation
        lib_path = self.sync_get_lib_path()
        if lib_path.exists():
            dart_files = list(lib_path.rglob('**/*.dart'))
            
            undocumented_classes = 0
            total_classes = 0
            
            for dart_file in dart_files:
                try:
                    with open(dart_file, 'r') as f:
                        content = f.read()
                    
                    # Count classes with documentation
                    class_matches = content.count('/// ')
                    class_count = content.count('class ')
                    
                    undocumented_classes += class_count - class_matches
                    total_classes += class_count
                except Exception as e:
                    self.logger.debug(f"Documentation check failed for {dart_file}: {e}")
            
            if total_classes > 0:
                doc_percentage = (class_count - undocumented_classes) / total_classes * 100
                if doc_percentage < 80:
                    self.results.append(CheckResult(
                        CheckStatus.WARNING,
                        f"Low documentation coverage: {doc_percentage:.1f}%",
                        None,
                        "Add documentation to classes"
                    ))
                else:
                    self.results.append(CheckResult(
                        CheckStatus.SUCCESS,
                        f"Documentation coverage: {doc_percentage:.1f}%"
                    ))
    
    def check_build_readiness(self) -> None:
        """Check build readiness"""
        self.logger.info("Checking build readiness...")
        
        # Check for required files
        required_files = [
            'lib/main.dart',
            'pubspec.yaml',
            'analysis_options.yaml',
            'README.md'
        ]
        
        for file_path in required_files:
            full_path = self.project_path / file_path
            if not full_path.exists():
                self.results.append(CheckResult(
                    CheckStatus.ERROR,
                    f"Required file missing: {file_path}",
                    None,
                    f"Create {file_path}"
                ))
        
        # Check Android/iOS readiness
        try:
            android_path = self.project_path / "android"
            ios_path = self.project_path / "ios"
            
            if android_path.exists():
                android_ready = (android_path / "app" / "build.gradle").exists() and \
                             (android_path / "gradle").exists()
                if android_ready:
                    self.results.append(CheckResult(
                        CheckStatus.SUCCESS,
                        "Android build configuration ready"
                    ))
                else:
                    self.results.append(CheckResult(
                        CheckStatus.WARNING,
                        "Android build configuration incomplete",
                        None,
                        "Run 'flutter create .' to generate Android files"
                    ))
            
            if ios_path.exists():
                ios_ready = (ios_path / "Runner.xcworkspace").exists() or \
                           (ios_path / "Podfile").exists()
                if ios_ready:
                    self.results.append(CheckResult(
                        CheckStatus.SUCCESS,
                        "iOS build configuration ready"
                    ))
                else:
                    self.results.append(CheckResult(
                        CheckStatus.WARNING,
                        "iOS build configuration incomplete",
                        None,
                        "Run 'flutter create .' to generate iOS files"
                    ))
        except Exception as e:
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                f"Build readiness check failed: {str(e)}",
                None,
                "Check project structure"
            ))
    
    def check_voice_translation(self) -> None:
        """Check voice translation feature readiness"""
        self.logger.info("Checking voice translation features...")
        
        voice_translation_path = self.project_path / "lib/features/voice_translation"
        if not voice_translation_path.exists():
            self.results.append(CheckResult(
                CheckStatus.INFO,
                "Voice translation feature not implemented",
                None,
                "Voice translation is optional"
            ))
            return
        
        # Check voice translation files
        required_files = [
            'screens/voice_translation_screen.dart',
            'widgets/voice_recorder_widget.dart',
            'widgets/translation_display_widget.dart',
            'widgets/language_selector_widget.dart'
        ]
        
        for file_path in required_files:
            full_path = voice_translation_path / file_path
            if not full_path.exists():
                self.results.append(CheckResult(
                    CheckStatus.WARNING,
                    f"Voice translation file missing: {file_path}",
                    None,
                    "Complete voice translation implementation"
                ))
        
        # Check voice translation configuration
        try:
            central_config_path = self.project_path / "lib/core/central_config.dart"
            if central_config_path.exists():
                with open(central_config_path, 'r') as f:
                    config_content = f.read()
                
                voice_params = [
                    'voice_translation.enable_offline',
                    'voice_translation.enable_encryption',
                    'voice_translation.supported_languages',
                    'ui.voice_recorder.button_size'
                ]
                
                missing_params = []
                for param in voice_params:
                    if param not in config_content:
                        missing_params.append(param)
                
                if missing_params:
                    self.results.append(CheckResult(
                        CheckStatus.WARNING,
                        f"Voice translation parameters missing: {', '.join(missing_params)}",
                        None,
                        "Add missing parameters to CentralConfig"
                    ))
                else:
                    self.results.append(CheckResult(
                        CheckStatus.SUCCESS,
                        "Voice translation configuration complete"
                    ))
        except Exception as e:
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                f"Voice translation configuration check failed: {str(e)}",
                None,
                "Check CentralConfig implementation"
            ))
    
    def check_network_features(self) -> None:
        """Check network and file sharing features"""
        self.logger.info("Checking network and file sharing features...")
        
        network_path = self.project_path / "lib/features/network_management"
        if not network_path.exists():
            self.results.append(CheckResult(
                CheckStatus.INFO,
                "Network management features not implemented",
                None,
                "Network management is optional"
            ))
            return
        
        # Check advanced network screen
        advanced_network_path = network_path / "screens/advanced_network_screen.dart"
        if not advanced_network_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Advanced network screen missing",
                None,
                "Implement advanced network features"
            ))
        
        # Check network widgets
        required_widgets = [
            'widgets/virtual_drive_widget.dart',
            'widgets/network_discovery_widget.dart'
        ]
        
        for widget_path in required_widgets:
            full_path = network_path / widget_path
            if not full_path.exists():
                self.results.append(CheckResult(
                    CheckStatus.WARNING,
                    f"Network widget missing: {widget_path}",
                    None,
                    "Complete network widget implementation"
                ))
        
        # Check network configuration
        try:
            central_config_path = self.project_path / "lib/core/central_config.dart"
            if central_config_path.exists():
                with open(central_config_path, 'r') as f:
                    config_content = f.read()
                
                network_params = [
                    'network.discovery.enable_mdns',
                    'network.virtual_drive.auto_reconnect',
                    'network.ftp.enable_ftps',
                    'network.smb.port',
                    'network.webdav.enable_dav',
                    'network.qr_code.size'
                ]
                
                missing_params = []
                for param in network_params:
                    if param not in config_content:
                        missing_params.append(param)
                
                if missing_params:
                    self.results.append(CheckResult(
                        CheckStatus.WARNING,
                        f"Network parameters missing: {', '.join(missing_params)}",
                        None,
                        "Add missing network parameters to CentralConfig"
                    ))
                else:
                    self.results.append(CheckResult(
                        CheckStatus.SUCCESS,
                        "Network configuration complete"
                    ))
        except Exception as e:
            self.results.append(CheckResult(
                CheckStatus.ERROR,
                f"Network configuration check failed: {str(e)}",
                None,
                "Check CentralConfig implementation"
            ))
    
    def check_ai_features(self) -> None:
        """Check AI features readiness"""
        self.logger.info("Checking AI features...")
        
        ai_path = self.project_path / "lib/features/ai_assistant"
        if not ai_path.exists():
            self.results.append(CheckResult(
                CheckStatus.INFO,
                "AI features not implemented",
                None,
                "AI features are optional"
            ))
            return
        
        # Check AI assistant screen
        ai_screen_path = ai_path / "ai_assistant_screen.dart"
        if not ai_screen_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "AI assistant screen missing",
                None,
                "Implement AI assistant features"
            ))
        
        # Check document AI screen
        doc_ai_path = ai_path / "document_ai_screen.dart"
        if not doc_ai_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Document AI screen missing",
                None,
                "Implement document AI features"
            ))
        
        # Check intelligent categorization
        cat_path = ai_path / "intelligent_categorization_screen.dart"
        if not cat_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Intelligent categorization screen missing",
                None,
                "Implement intelligent categorization"
            ))
    
    def check_collaboration_features(self) -> None:
        """Check collaboration features readiness"""
        self.logger.info("Checking collaboration features...")
        
        collaboration_path = self.project_path / "lib/features/collaboration"
        if not collaboration_path.exists():
            self.results.append(CheckResult(
                CheckStatus.INFO,
                "Collaboration features not implemented",
                None,
                "Collaboration features are optional"
            ))
            return
        
        # Check collaboration screen
        collab_screen_path = collaboration_path / "collaboration_screen.dart"
        if not collab_screen_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Collaboration screen missing",
                None,
                "Implement collaboration features"
            ))
        
        # Check collaboration service
        collab_service_path = self.project_path / "lib/services/collaboration/collaboration_service.dart"
        if not collab_service_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Collaboration service missing",
                None,
                "Implement collaboration backend service"
            ))
    
    def check_plugin_system(self) -> None:
        """Check plugin system readiness"""
        self.logger.info("Checking plugin system...")
        
        plugin_path = self.project_path / "lib/features/plugins"
        if not plugin_path.exists():
            self.results.append(CheckResult(
                CheckStatus.INFO,
                "Plugin system not implemented",
                None,
                "Plugin system is optional"
            ))
            return
        
        # Check plugin marketplace
        marketplace_path = plugin_path / "plugin_marketplace_screen.dart"
        if not marketplace_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Plugin marketplace screen missing",
                None,
                "Implement plugin marketplace"
            ))
        
        # Check plugin manager
        plugin_manager_path = self.project_path / "lib/core/plugin_manager.dart"
        if not plugin_manager_path.exists():
            self.results.append(CheckResult(
                CheckStatus.WARNING,
                "Plugin manager missing",
                None,
                "Implement plugin management system"
            ))
    
    def sync_get_lib_path(self) -> Path:
        """Get lib path safely"""
        return self.project_path / "lib"
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive quality report"""
        self.logger.info("Generating quality report...")
        
        success_count = len([r for r in self.results if r.status == CheckStatus.SUCCESS])
        warning_count = len([r for r in self.results if r.status == CheckStatus.WARNING])
        error_count = len([r for r in self.results if r.status == CheckStatus.ERROR])
        info_count = len([r for r in r.results if r.status == CheckStatus.INFO])
        total_count = len(self.results)
        
        success_rate = (success_count / total_count * 100) if total_count > 0 else 0
        
        return {
            'timestamp': time.time(),
            'summary': {
                'total_checks': total_count,
                'success_count': success_count,
                'warning_count': warning_count,
                'error_count': error_count,
                'info_count': info_count,
                'success_rate': success_rate,
                'status': 'PASS' if error_count == 0 else 'FAIL' if error_count > 10 else 'WARNING'
            },
            'categories': {
                'core': self._get_category_results(['Flutter Doctor', 'Dependencies', 'Code Quality', 'Security']),
                'features': self._get_category_results(['Voice Translation', 'Network Features', 'AI Features', 'Collaboration', 'Plugin System']),
                'documentation': self._get_category_results(['Documentation', 'Build Readiness']),
                'performance': self._get_category_results(['Performance'])
            },
            'results': [
                {
                    'category': self._categorize_result(r.message),
                    'status': r.status.value,
                    'message': r.message,
                    'details': r.details,
                    'fix_suggestion': r.fix_suggestion
                }
                for r in self.results
            ]
        }
    
    def _get_category_results(self, category_keywords: List[str]) -> List[CheckResult]:
        """Get results for a specific category"""
        return [
            r for r in self.results
            if any(keyword.lower() in r.message.lower() for keyword in category_keywords)
        ]
    
    def _categorize_result(self, message: str) -> str:
        """Categorize a result message"""
        message_lower = message.lower()
        
        if any(keyword in message_lower for keyword in ['flutter', 'dart']):
            return 'core'
        elif any(keyword in message_lower for keyword in ['voice', 'translation', 'audio']):
            return 'features'
        elif any(keyword in message_lower for keyword in ['network', 'ftp', 'smb', 'webdav']):
            return 'features'
        elif any(keyword in message_lower for keyword in ['ai', 'artificial', 'intelligence']):
            return 'features'
        elif any(keyword in message_lower for keyword in ['collaboration', 'team', 'real-time']):
            return 'features'
        elif any(keyword in message_lower for keyword in ['plugin', 'extension', 'marketplace']):
            return 'features'
        elif any(keyword in message_lower for keyword in ['documentation', 'readme', 'docs']):
            return 'documentation'
        elif any(keyword in message_lower for keyword in ['performance', 'size', 'await', 'async']):
            return 'performance'
        elif any(keyword in message_lower for keyword in ['build', 'android', 'ios', 'platform']):
            return 'core'
        else:
            return 'other'
    
    def save_report(self, report: Dict[str, Any]) -> None:
        """Save quality report to file"""
        try:
            report_path = self.project_path / "build_quality_report.json"
            with open(report_path, 'w') as f:
                json.dump(report, f, indent=2)
            
            self.logger.info(f"Quality report saved to {report_path}")
            
            # Also save as human-readable format
            report_txt_path = self.project_path / "build_quality_report.txt"
            with open(report_txt_path, 'w') as f:
                f.write("iSuite Build Quality Report\n")
                f.write("=" * 50 + "\n\n")
                f.write(f"Generated: {time.ctime()}\n")
                f.write(f"Status: {report['summary']['status']}\n")
                f.write(f"Success Rate: {report['summary']['success_rate']:.1f}%\n")
                f.write(f"Total Checks: {report['summary']['total_checks']}\n")
                f.write(f"Success: {report['summary']['success_count']}\n")
                f.write(f"Warnings: {report['summary']['warning_count']}\n")
                f.write(f"Errors: {report['summary']['error_count']}\n\n")
                f.write("Category Summary:\n")
                
                for category, results in report['categories'].items():
                    f.write(f"\n{category.title()}:")
                    for result in results:
                        f.write(f"  [{result['status'].upper()}] {result['message']}\n")
                
                f.write("\nDetailed Results:\n")
                for result in report['results']:
                    f.write(f"[{result['status'].upper()}] {result['message']}\n")
                    if result['details']:
                        f.write(f"  Details: {result['details']}\n")
                    if result['fix_suggestion']:
                        f.write(f"  Fix: {result['fix_suggestion']}\n")
            
            self.logger.info(f"Human-readable report saved to {report_txt_path}")
            
        except Exception as e:
            self.logger.error(f"Failed to save report: {e}")

def main():
    parser = argparse.ArgumentParser(description='iSuite Build Optimizer and Quality Assurance')
    parser.add_argument(
        '--project-path',
        default='.',
        help='Path to iSuite project directory'
    )
    
    args = parser.parse_args()
    
    # Validate project path
    project_path = Path(args.project_path).resolve()
    if not project_path.exists():
        print(f"Error: Project path {project_path} does not exist")
        sys.exit(1)
    
    if not (project_path / 'pubspec.yaml').exists():
        print(f"Error: {project_path} is not a Flutter project (no pubspec.yaml found)")
        sys.exit(1)
    
    # Run build optimizer
    optimizer = BuildOptimizer(str(project_path))
    report = optimizer.run_all_checks()
    
    # Print summary
    print(f"\n{iSuite Build Optimizer Report")
    print("=" * 50)
    print(f"Status: {report['summary']['status']}")
    print(f"Success Rate: {report['summary']['success_rate']:.1f}%")
    print(f"Total Checks: {report['summary']['total_checks']}")
    print(f"Success: {report['summary']['success_count']}")
    print(f"Warnings: {report['summary']['warning_count']}")
    print(f"Errors: {report['summary']['error_count']}")
    
    if report['summary']['error_count'] > 0:
        print(f"\n⚠️  {report['summary']['error_count']} critical issues found - fix before production")
        print("Run 'flutter fix' and address all errors")
    elif report['summary']['warning_count'] > 0:
        print(f"\n⚠️  {report['summary']['warning_count']} warnings found - review before production")
    
    print(f"\n📊 Detailed report saved to build_quality_report.json")
    print(f"📄 Human-readable report saved to build_quality_report.txt")
    
    # Exit with appropriate code
    if report['summary']['status'] == 'PASS':
        sys.exit(0)
    elif report['summary']['status'] == 'WARNING':
        sys.exit(1)
    else:
        sys.exit(2)

if __name__ == '__main__':
    main()
