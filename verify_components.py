#!/usr/bin/env python3
"""
Component Parameterization and Connectivity Verification Script
=================================================================

Comprehensive verification system to ensure all iSuite components are:
- Properly parameterized through CentralConfig
- Well connected with correct dependencies
- Have proper relationship tracking
- Are centrally managed

This script performs static analysis of the Dart codebase to verify:
1. All services register with CentralConfig
2. Dependencies are correctly specified
3. Component relationships are established
4. Parameters are centrally managed
5. No hardcoded values bypass CentralConfig
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional, Any
from dataclasses import dataclass, asdict
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class ComponentInfo:
    """Information about a component's parameterization"""
    name: str
    file_path: str
    has_register_component: bool
    dependencies: List[str]
    parameters: List[str]
    relationships: List[str]
    hardcoded_values: List[str]
    issues: List[str]

@dataclass
class VerificationResult:
    """Result of component verification"""
    total_components: int
    properly_parameterized: int
    well_connected: int
    issues_found: int
    components: Dict[str, ComponentInfo]
    summary: Dict[str, Any]

class ComponentVerifier:
    """Verifies component parameterization and connectivity"""

    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_path = self.project_root / 'lib'
        self.components: Dict[str, ComponentInfo] = {}

        # Patterns for detecting component registration and usage
        self.register_component_pattern = re.compile(
            r'registerComponent\(\s*[\'"]([^\'"]+)[\'"]\s*,',
            re.MULTILINE | re.DOTALL
        )

        self.dependency_pattern = re.compile(
            r'dependencies:\s*\[([^\]]*)\]',
            re.MULTILINE | re.DOTALL
        )

        self.parameter_pattern = re.compile(
            r'[\'"](\w+(?:\.\w+)*)[\'"]\s*:',
            re.MULTILINE
        )

        self.hardcoded_pattern = re.compile(
            r'(?:const|final)\s+\w+\s*=\s*[\'"]([^\'"]*)[\'"]\s*;',
            re.MULTILINE
        )

        self.config_usage_pattern = re.compile(
            r'_config\.getParameter\(\s*[\'"]([^\'"]+)[\'"]',
            re.MULTILINE
        )

    def verify_all_components(self) -> VerificationResult:
        """Perform comprehensive verification of all components"""
        logger.info("Starting component verification...")

        # Find all service files
        service_files = self._find_service_files()
        logger.info(f"Found {len(service_files)} service files")

        # Analyze each service file
        for file_path in service_files:
            component_info = self._analyze_component_file(file_path)
            if component_info:
                self.components[component_info.name] = component_info

        # Verify connectivity
        self._verify_connectivity()

        # Generate results
        result = self._generate_verification_result()
        logger.info(f"Verification completed: {result.properly_parameterized}/{result.total_components} components properly parameterized")

        return result

    def _find_service_files(self) -> List[Path]:
        """Find all service files in the lib directory"""
        service_files = []

        # Look for service files in common locations
        service_directories = [
            'core',
            'features',
            'services',
        ]

        for service_dir in service_directories:
            dir_path = self.lib_path / service_dir
            if dir_path.exists():
                for file_path in dir_path.rglob('*_service.dart'):
                    service_files.append(file_path)

        # Also look for service files directly in lib
        for file_path in self.lib_path.glob('*_service.dart'):
            if file_path not in service_files:
                service_files.append(file_path)

        return service_files

    def _analyze_component_file(self, file_path: Path) -> Optional[ComponentInfo]:
        """Analyze a single component file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Extract component name from registerComponent call
            register_match = self.register_component_pattern.search(content)
            if not register_match:
                # Component doesn't register with CentralConfig
                component_name = file_path.stem.replace('_service', '').replace('_', ' ').title().replace(' ', '')
                return ComponentInfo(
                    name=component_name,
                    file_path=str(file_path),
                    has_register_component=False,
                    dependencies=[],
                    parameters=[],
                    relationships=[],
                    hardcoded_values=[],
                    issues=['Component does not register with CentralConfig']
                )

            component_name = register_match.group(1)

            # Extract dependencies
            dependencies = self._extract_dependencies(content)

            # Extract parameters
            parameters = self._extract_parameters(content)

            # Find hardcoded values
            hardcoded_values = self._find_hardcoded_values(content)

            # Check for issues
            issues = self._identify_issues(component_name, content, dependencies, parameters, hardcoded_values)

            return ComponentInfo(
                name=component_name,
                file_path=str(file_path),
                has_register_component=True,
                dependencies=dependencies,
                parameters=parameters,
                relationships=[],  # Would need more complex analysis
                hardcoded_values=hardcoded_values,
                issues=issues
            )

        except Exception as e:
            logger.error(f"Error analyzing {file_path}: {e}")
            return None

    def _extract_dependencies(self, content: str) -> List[str]:
        """Extract dependencies from registerComponent call"""
        dependencies = []

        # Find the registerComponent call
        register_start = content.find('registerComponent(')
        if register_start == -1:
            return dependencies

        # Find the dependencies parameter
        dep_match = self.dependency_pattern.search(content[register_start:])
        if dep_match:
            dep_string = dep_match.group(1)
            # Extract quoted strings
            dep_matches = re.findall(r'[\'"]([^\'"]+)[\'"]', dep_string)
            dependencies.extend(dep_matches)

        return dependencies

    def _extract_parameters(self, content: str) -> List[str]:
        """Extract parameters used by the component"""
        parameters = []

        # Find all getParameter calls
        param_matches = self.config_usage_pattern.findall(content)
        parameters.extend(param_matches)

        # Remove duplicates
        return list(set(parameters))

    def _find_hardcoded_values(self, content: str) -> List[str]:
        """Find potentially hardcoded values that should be parameterized"""
        hardcoded = []

        # Look for hardcoded constants that might be configuration
        lines = content.split('\n')
        for line in lines:
            # Skip comments and imports
            if line.strip().startswith('//') or line.strip().startswith('import'):
                continue

            # Look for hardcoded values in const declarations
            if 'const' in line or 'final' in line:
                hardcoded_match = self.hardcoded_pattern.search(line)
                if hardcoded_match:
                    value = hardcoded_match.group(1)
                    # Check if it looks like a configuration value
                    if any(keyword in value.lower() for keyword in [
                        'timeout', 'port', 'size', 'count', 'limit', 'delay',
                        'interval', 'threshold', 'buffer', 'chunk', 'pool'
                    ]):
                        hardcoded.append(f"{line.strip()}: {value}")

        return hardcoded

    def _identify_issues(self, component_name: str, content: str,
                        dependencies: List[str], parameters: List[str],
                        hardcoded_values: List[str]) -> List[str]:
        """Identify issues with component parameterization"""
        issues = []

        # Check if component has dependencies but they're not specified
        if 'CentralConfig' in content and not dependencies:
            issues.append("Uses CentralConfig but no dependencies specified")

        # Check for missing dependencies
        required_deps = []
        if 'LoggingService' in content:
            required_deps.append('LoggingService')
        if 'AdvancedSecurityService' in content:
            required_deps.append('AdvancedSecurityService')
        if 'CircuitBreakerService' in content:
            required_deps.append('CircuitBreakerService')

        for dep in required_deps:
            if dep not in dependencies:
                issues.append(f"Missing dependency: {dep}")

        # Check for hardcoded configuration values
        if hardcoded_values:
            issues.append(f"Found {len(hardcoded_values)} potentially hardcoded configuration values")

        # Check for parameters not used
        if parameters and not any('getParameter' in content for param in parameters):
            issues.append("Parameters defined but not used in component")

        return issues

    def _verify_connectivity(self):
        """Verify component connectivity and relationships"""
        for component_name, component in self.components.items():
            # Check if dependencies exist
            for dep in component.dependencies:
                if dep not in self.components and dep not in ['CentralConfig', 'LoggingService', 'AdvancedSecurityService', 'CircuitBreakerService']:
                    component.issues.append(f"Dependency '{dep}' not found in registered components")

            # Check for circular dependencies (simplified)
            for dep in component.dependencies:
                if dep in self.components:
                    dep_component = self.components[dep]
                    if component_name in dep_component.dependencies:
                        component.issues.append(f"Circular dependency detected with {dep}")

    def _generate_verification_result(self) -> VerificationResult:
        """Generate comprehensive verification result"""
        total_components = len(self.components)
        properly_parameterized = sum(1 for c in self.components.values() if c.has_register_component and not c.issues)
        well_connected = sum(1 for c in self.components.values() if not any('dependency' in issue.lower() for issue in c.issues))
        issues_found = sum(len(c.issues) for c in self.components.values())

        # Generate summary
        summary = {
            'total_components': total_components,
            'properly_parameterized_percentage': total_components > 0 ? (properly_parameterized / total_components) * 100 : 0,
            'well_connected_percentage': total_components > 0 ? (well_connected / total_components) * 100 : 0,
            'total_issues': issues_found,
            'most_common_issues': self._get_most_common_issues(),
            'components_by_status': self._get_components_by_status(),
        }

        return VerificationResult(
            total_components=total_components,
            properly_parameterized=properly_parameterized,
            well_connected=well_connected,
            issues_found=issues_found,
            components={name: asdict(info) for name, info in self.components.items()},
            summary=summary,
        )

    def _get_most_common_issues(self) -> Dict[str, int]:
        """Get most common issues across all components"""
        issue_counts = {}
        for component in self.components.values():
            for issue in component.issues:
                # Simplify issue for grouping
                simplified_issue = issue.split(':')[0] if ':' in issue else issue
                issue_counts[simplified_issue] = issue_counts.get(simplified_issue, 0) + 1

        # Return top 5 most common issues
        return dict(sorted(issue_counts.items(), key=lambda x: x[1], reverse=True)[:5])

    def _get_components_by_status(self) -> Dict[str, int]:
        """Get component counts by status"""
        status_counts = {'fully_compliant': 0, 'needs_attention': 0, 'critical_issues': 0}

        for component in self.components.values():
            if not component.issues:
                status_counts['fully_compliant'] += 1
            elif any('Missing dependency' in issue or 'does not register' in issue for issue in component.issues):
                status_counts['critical_issues'] += 1
            else:
                status_counts['needs_attention'] += 1

        return status_counts

def main():
    """Main verification function"""
    import argparse

    parser = argparse.ArgumentParser(description='Verify component parameterization and connectivity')
    parser.add_argument('--project-root', default='.', help='Project root directory')
    parser.add_argument('--output', help='Output JSON file for results')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Run verification
    verifier = ComponentVerifier(args.project_root)
    result = verifier.verify_all_components()

    # Print results
    print(f"\n{'='*60}")
    print("COMPONENT PARAMETERIZATION VERIFICATION RESULTS")
    print(f"{'='*60}")
    print(f"Total Components: {result.total_components}")
    print(f"Properly Parameterized: {result.properly_parameterized} ({result.summary['properly_parameterized_percentage']:.1f}%)")
    print(f"Well Connected: {result.well_connected} ({result.summary['well_connected_percentage']:.1f}%)")
    print(f"Issues Found: {result.issues_found}")
    print()

    print("COMPONENT STATUS:")
    status = result.summary['components_by_status']
    print(f"  Fully Compliant: {status['fully_compliant']}")
    print(f"  Needs Attention: {status['needs_attention']}")
    print(f"  Critical Issues: {status['critical_issues']}")
    print()

    if result.summary['most_common_issues']:
        print("MOST COMMON ISSUES:")
        for issue, count in result.summary['most_common_issues'].items():
            print(f"  {issue}: {count} components")
        print()

    # Show detailed issues
    components_with_issues = {name: info for name, info in result.components.items()
                             if info['issues']}
    if components_with_issues:
        print("COMPONENTS WITH ISSUES:")
        for name, info in components_with_issues.items():
            print(f"  {name} ({info['file_path']}):")
            for issue in info['issues']:
                print(f"    - {issue}")
        print()

    # Save results to file if requested
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(asdict(result), f, indent=2)
        print(f"Results saved to: {args.output}")

    # Exit with appropriate code
    success = result.properly_parameterized == result.total_components and result.well_connected == result.total_components
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
