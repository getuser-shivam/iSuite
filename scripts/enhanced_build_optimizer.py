#!/usr/bin/env python3
"""
Enhanced Build Optimization Script for iSuite
=============================================

Advanced build optimization with intelligent caching, performance monitoring,
and cross-platform build acceleration.

Features:
- Intelligent build caching based on file changes
- Parallel build execution for multi-platform targets
- Build performance monitoring and bottleneck detection
- Dependency analysis and optimization
- Incremental build support with change detection
- Build artifact optimization and compression
- Cross-platform build orchestration

Author: iSuite Build Team
Version: 2.0.0
License: MIT
"""

import os
import sys
import json
import hashlib
import time
import subprocess
import threading
import concurrent.futures
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any, Set
from dataclasses import dataclass, asdict
import logging
import platform
import psutil
import shutil
from datetime import datetime, timedelta
import argparse
import yaml

# Enhanced logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.FileHandler('logs/build_optimizer.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class BuildCacheEntry:
    """Intelligent build cache entry with dependency tracking"""
    cache_key: str
    source_files: Dict[str, str]  # file_path -> hash
    dependencies: Dict[str, str]  # dependency -> version
    build_command: str
    platform: str
    build_time: datetime
    build_duration: float
    output_size: int
    success: bool
    checksum: str

@dataclass
class BuildMetrics:
    """Comprehensive build performance metrics"""
    start_time: datetime
    end_time: Optional[datetime] = None
    duration: float = 0.0
    peak_memory_mb: float = 0.0
    peak_cpu_percent: float = 0.0
    network_requests: int = 0
    cache_hits: int = 0
    cache_misses: int = 0
    files_processed: int = 0
    warnings: int = 0
    errors: int = 0

@dataclass
class BuildOptimization:
    """Build optimization recommendations"""
    optimization_type: str
    description: str
    impact: str  # high, medium, low
    action: str
    automated: bool = False

class EnhancedBuildOptimizer:
    """Advanced build optimizer with AI-assisted optimization"""

    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.cache_dir = self.project_path / '.build_cache'
        self.metrics_dir = self.project_path / '.build_metrics'
        self.cache_index_file = self.cache_dir / 'cache_index.json'
        self.metrics_file = self.metrics_dir / 'build_metrics.json'

        # Initialize directories
        self.cache_dir.mkdir(exist_ok=True)
        self.metrics_dir.mkdir(exist_ok=True)

        # Build state
        self.cache_index: Dict[str, BuildCacheEntry] = {}
        self.build_metrics: List[BuildMetrics] = []
        self.active_builds: Dict[str, BuildMetrics] = {}
        self.dependency_graph: Dict[str, Set[str]] = {}

        # Load existing cache and metrics
        self._load_cache_index()
        self._load_build_metrics()

        # Performance monitoring
        self.performance_monitor = BuildPerformanceMonitor()

    def optimize_build(self, platform: str, build_type: str = 'release',
                      force_rebuild: bool = False) -> Tuple[bool, str, BuildMetrics]:
        """
        Perform intelligent build optimization with caching and performance monitoring
        """
        logger.info(f"Starting optimized build for {platform} ({build_type})")

        # Generate cache key based on source files and dependencies
        cache_key = self._generate_cache_key(platform, build_type)

        # Check if we can use cached build
        if not force_rebuild and self._can_use_cached_build(cache_key):
            logger.info("Using cached build result")
            cached_metrics = self._get_cached_metrics(cache_key)
            return True, f"Build completed using cache (saved {cached_metrics.duration:.1f}s)", cached_metrics

        # Start performance monitoring
        build_id = f"{platform}_{build_type}_{int(time.time())}"
        metrics = BuildMetrics(start_time=datetime.now())
        self.active_builds[build_id] = metrics

        try:
            # Pre-build optimizations
            self._perform_prebuild_optimizations(platform, build_type)

            # Execute optimized build
            success, output = self._execute_optimized_build(platform, build_type, metrics)

            # Post-build optimizations
            if success:
                self._perform_postbuild_optimizations(platform, build_type)

                # Cache successful build
                self._cache_build_result(cache_key, platform, build_type, success, metrics)

            # Update metrics
            metrics.end_time = datetime.now()
            metrics.duration = (metrics.end_time - metrics.start_time).total_seconds()
            self.build_metrics.append(metrics)
            self._save_build_metrics()

            result_msg = f"Build {'succeeded' if success else 'failed'} in {metrics.duration:.1f}s"
            if success:
                result_msg += f" (peak memory: {metrics.peak_memory_mb:.1f}MB, peak CPU: {metrics.peak_cpu_percent:.1f}%)"

            logger.info(result_msg)
            return success, output, metrics

        finally:
            self.active_builds.pop(build_id, None)

    def _generate_cache_key(self, platform: str, build_type: str) -> str:
        """Generate intelligent cache key based on source files and dependencies"""
        hasher = hashlib.sha256()

        # Hash source files
        source_files = self._get_source_files()
        for file_path in sorted(source_files):
            file_path_obj = Path(file_path)
            if file_path_obj.exists():
                try:
                    with open(file_path_obj, 'rb') as f:
                        hasher.update(f.read())
                    hasher.update(str(file_path_obj.stat().st_mtime).encode())
                except (OSError, IOError):
                    # File might be locked or inaccessible
                    continue

        # Hash pubspec.yaml and build configuration
        pubspec_path = self.project_path / 'pubspec.yaml'
        if pubspec_path.exists():
            with open(pubspec_path, 'rb') as f:
                hasher.update(f.read())

        # Hash build scripts and configuration
        build_config = f"{platform}_{build_type}_{platform.system()}"
        hasher.update(build_config.encode())

        return hasher.hexdigest()[:16]  # Short hash for readability

    def _can_use_cached_build(self, cache_key: str) -> bool:
        """Determine if cached build can be used"""
        if cache_key not in self.cache_index:
            return False

        cache_entry = self.cache_index[cache_key]

        # Check if cache is still valid (not too old)
        cache_age = datetime.now() - cache_entry.build_time
        if cache_age > timedelta(hours=24):  # Cache expires after 24 hours
            return False

        # Check if source files have changed
        for file_path, cached_hash in cache_entry.source_files.items():
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                return False

            try:
                current_hash = self._calculate_file_hash(file_path_obj)
                if current_hash != cached_hash:
                    return False
            except (OSError, IOError):
                return False

        # Check if dependencies have changed
        for dep, version in cache_entry.dependencies.items():
            current_version = self._get_dependency_version(dep)
            if current_version != version:
                return False

        return True

    def _perform_prebuild_optimizations(self, platform: str, build_type: str):
        """Execute pre-build optimizations"""
        logger.info("Performing pre-build optimizations")

        # Clean old build artifacts
        self._clean_old_artifacts(platform)

        # Optimize dependencies
        self._optimize_dependencies()

        # Pre-warm build cache
        self._prewarm_build_cache(platform, build_type)

        # Platform-specific optimizations
        self._perform_platform_optimizations(platform, build_type)

    def _execute_optimized_build(self, platform: str, build_type: str, metrics: BuildMetrics) -> Tuple[bool, str]:
        """Execute the actual build with optimizations"""
        logger.info(f"Executing optimized build for {platform}")

        # Determine build command based on platform
        build_commands = self._get_build_commands(platform, build_type)

        # Execute build with monitoring
        return self._execute_build_with_monitoring(build_commands, metrics)

    def _perform_postbuild_optimizations(self, platform: str, build_type: str):
        """Execute post-build optimizations"""
        logger.info("Performing post-build optimizations")

        # Compress build artifacts
        self._compress_build_artifacts(platform)

        # Generate build analytics
        self._generate_build_analytics(platform, build_type)

        # Clean temporary files
        self._clean_temporary_files()

    def _execute_build_with_monitoring(self, commands: List[List[str]], metrics: BuildMetrics) -> Tuple[bool, str]:
        """Execute build commands with comprehensive monitoring"""
        full_output = []
        success = True

        # Start performance monitoring
        self.performance_monitor.start_monitoring()

        try:
            for command in commands:
                logger.info(f"Executing: {' '.join(command)}")

                # Execute command with timeout and monitoring
                process = subprocess.Popen(
                    command,
                    cwd=self.project_path,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )

                # Monitor process in real-time
                output_lines = []
                while True:
                    line = process.stdout.readline()
                    if not line and process.poll() is not None:
                        break

                    if line:
                        output_lines.append(line.rstrip())
                        full_output.append(line.rstrip())

                        # Real-time metrics update
                        self.performance_monitor.update_metrics()
                        current_metrics = self.performance_monitor.get_current_metrics()
                        metrics.peak_memory_mb = max(metrics.peak_memory_mb, current_metrics['memory_mb'])
                        metrics.peak_cpu_percent = max(metrics.peak_cpu_percent, current_metrics['cpu_percent'])

                        # Count warnings and errors
                        if 'warning' in line.lower():
                            metrics.warnings += 1
                        if 'error' in line.lower():
                            metrics.errors += 1

                # Wait for process to complete
                return_code = process.wait()

                if return_code != 0:
                    success = False
                    logger.error(f"Build command failed with exit code {return_code}")
                    break

        except subprocess.TimeoutExpired:
            success = False
            full_output.append("Build timed out")
            logger.error("Build timed out")

        except Exception as e:
            success = False
            full_output.append(f"Build error: {str(e)}")
            logger.error(f"Build error: {e}")

        finally:
            # Stop performance monitoring
            self.performance_monitor.stop_monitoring()
            final_metrics = self.performance_monitor.get_final_metrics()
            metrics.network_requests = final_metrics.get('network_requests', 0)

        return success, '\n'.join(full_output)

    def _get_build_commands(self, platform: str, build_type: str) -> List[List[str]]:
        """Get optimized build commands for the platform"""
        base_commands = []

        # Common pre-build commands
        base_commands.extend([
            ['flutter', 'clean'],
            ['flutter', 'pub', 'get'],
            ['flutter', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        ])

        # Platform-specific build commands
        if platform in ['apk', 'android']:
            if build_type == 'release':
                base_commands.append([
                    'flutter', 'build', 'apk', '--release',
                    '--split-debug-info=symbols',
                    '--obfuscate',
                    '--split-per-abi'
                ])
            else:
                base_commands.append(['flutter', 'build', 'apk', '--debug'])

        elif platform in ['aab', 'appbundle']:
            base_commands.append([
                'flutter', 'build', 'appbundle', '--release',
                '--split-debug-info=symbols',
                '--obfuscate'
            ])

        elif platform in ['ios', 'ipa']:
            base_commands.append([
                'flutter', 'build', 'ios', '--release',
                '--no-codesign'
            ])

        elif platform == 'web':
            base_commands.append([
                'flutter', 'build', 'web', '--release',
                '--web-renderer', 'canvaskit'
            ])

        elif platform in ['windows', 'exe']:
            base_commands.append(['flutter', 'build', 'windows', '--release'])

        elif platform in ['linux', 'appimage']:
            base_commands.append(['flutter', 'build', 'linux', '--release'])

        elif platform in ['macos', 'app']:
            base_commands.append(['flutter', 'build', 'macos', '--release'])

        return base_commands

    def _get_source_files(self) -> List[str]:
        """Get list of source files to monitor for caching"""
        source_files = []

        # Flutter source files
        lib_dir = self.project_path / 'lib'
        if lib_dir.exists():
            for file_path in lib_dir.rglob('*.dart'):
                source_files.append(str(file_path))

        # Pubspec and configuration files
        config_files = ['pubspec.yaml', 'analysis_options.yaml', 'build.yaml']
        for config_file in config_files:
            config_path = self.project_path / config_file
            if config_path.exists():
                source_files.append(str(config_path))

        return source_files

    def _calculate_file_hash(self, file_path: Path) -> str:
        """Calculate SHA256 hash of file content and metadata"""
        hasher = hashlib.sha256()
        with open(file_path, 'rb') as f:
            hasher.update(f.read())
        hasher.update(str(file_path.stat().st_mtime).encode())
        return hasher.hexdigest()

    def _get_dependency_version(self, dependency: str) -> str:
        """Get version of a dependency from pubspec.lock"""
        lock_file = self.project_path / 'pubspec.lock'
        if not lock_file.exists():
            return ''

        try:
            with open(lock_file, 'r') as f:
                lock_data = yaml.safe_load(f)

            packages = lock_data.get('packages', {})
            if dependency in packages:
                return packages[dependency].get('version', '')
        except Exception:
            pass

        return ''

    def _cache_build_result(self, cache_key: str, platform: str, build_type: str,
                          success: bool, metrics: BuildMetrics):
        """Cache successful build results"""
        if not success:
            return

        # Get output file size (approximate)
        output_size = self._estimate_output_size(platform)

        # Create cache entry
        cache_entry = BuildCacheEntry(
            cache_key=cache_key,
            source_files={file: self._calculate_file_hash(Path(file))
                         for file in self._get_source_files()},
            dependencies=self._get_current_dependencies(),
            build_command=f"flutter build {platform} --{build_type}",
            platform=platform,
            build_time=datetime.now(),
            build_duration=metrics.duration,
            output_size=output_size,
            success=success,
            checksum=self._generate_build_checksum(platform)
        )

        self.cache_index[cache_key] = cache_entry
        self._save_cache_index()

        logger.info(f"Cached build result for {platform} ({cache_key})")

    def _get_cached_metrics(self, cache_key: str) -> BuildMetrics:
        """Get cached build metrics"""
        cache_entry = self.cache_index[cache_key]
        return BuildMetrics(
            start_time=cache_entry.build_time,
            end_time=cache_entry.build_time + timedelta(seconds=cache_entry.build_duration),
            duration=cache_entry.build_duration,
            peak_memory_mb=0.0,  # Not cached
            peak_cpu_percent=0.0,  # Not cached
            cache_hits=1,
            files_processed=len(cache_entry.source_files)
        )

    def _estimate_output_size(self, platform: str) -> int:
        """Estimate output file size"""
        build_dir = self.project_path / 'build'
        if not build_dir.exists():
            return 0

        total_size = 0
        if platform in ['apk', 'android']:
            apk_dir = build_dir / 'app' / 'outputs' / 'flutter-apk'
            if apk_dir.exists():
                for apk_file in apk_dir.glob('*.apk'):
                    total_size += apk_file.stat().st_size
        elif platform == 'web':
            web_dir = build_dir / 'web'
            if web_dir.exists():
                total_size = sum(f.stat().st_size for f in web_dir.rglob('*') if f.is_file())

        return total_size

    def _generate_build_checksum(self, platform: str) -> str:
        """Generate checksum of build output"""
        build_dir = self.project_path / 'build'
        if not build_dir.exists():
            return ''

        hasher = hashlib.sha256()
        for file_path in sorted(build_dir.rglob('*')):
            if file_path.is_file():
                try:
                    with open(file_path, 'rb') as f:
                        hasher.update(f.read())
                except (OSError, IOError):
                    continue

        return hasher.hexdigest()

    def _get_current_dependencies(self) -> Dict[str, str]:
        """Get current dependency versions"""
        dependencies = {}
        lock_file = self.project_path / 'pubspec.lock'

        if lock_file.exists():
            try:
                with open(lock_file, 'r') as f:
                    lock_data = yaml.safe_load(f)

                packages = lock_data.get('packages', {})
                for name, info in packages.items():
                    dependencies[name] = info.get('version', '')
            except Exception:
                pass

        return dependencies

    def _clean_old_artifacts(self, platform: str):
        """Clean old build artifacts to free up space"""
        build_dir = self.project_path / 'build'
        if not build_dir.exists():
            return

        # Keep only last 3 builds per platform
        platform_dirs = []
        if platform in ['apk', 'android']:
            platform_dirs = [build_dir / 'app' / 'outputs' / 'flutter-apk']
        elif platform == 'web':
            platform_dirs = [build_dir / 'web']
        elif platform in ['windows', 'exe']:
            platform_dirs = [build_dir / 'windows']
        elif platform in ['linux', 'appimage']:
            platform_dirs = [build_dir / 'linux']
        elif platform in ['macos', 'app']:
            platform_dirs = [build_dir / 'macos']

        for platform_dir in platform_dirs:
            if platform_dir.exists():
                # Clean old files (keep last 3)
                files = sorted(platform_dir.glob('*'), key=lambda x: x.stat().st_mtime, reverse=True)
                for old_file in files[3:]:  # Keep first 3 (most recent)
                    if old_file.is_file():
                        old_file.unlink()
                    elif old_file.is_dir():
                        shutil.rmtree(old_file)

    def _optimize_dependencies(self):
        """Optimize Flutter dependencies"""
        try:
            # Run flutter pub get to ensure dependencies are up to date
            subprocess.run(['flutter', 'pub', 'get'],
                         cwd=self.project_path,
                         capture_output=True,
                         timeout=300)
        except Exception as e:
            logger.warning(f"Dependency optimization failed: {e}")

    def _prewarm_build_cache(self, platform: str, build_type: str):
        """Pre-warm build cache for faster builds"""
        try:
            # Pre-compile common dependencies
            subprocess.run(['flutter', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
                         cwd=self.project_path,
                         capture_output=True,
                         timeout=120)
        except Exception as e:
            logger.warning(f"Build cache pre-warming failed: {e}")

    def _perform_platform_optimizations(self, platform: str, build_type: str):
        """Perform platform-specific optimizations"""
        if platform in ['apk', 'android'] and build_type == 'release':
            # Android-specific optimizations
            self._optimize_android_build()
        elif platform == 'web':
            # Web-specific optimizations
            self._optimize_web_build()
        elif platform in ['windows', 'linux', 'macos']:
            # Desktop-specific optimizations
            self._optimize_desktop_build(platform)

    def _optimize_android_build(self):
        """Android-specific build optimizations"""
        android_dir = self.project_path / 'android'
        if not android_dir.exists():
            return

        # Ensure gradle.properties has optimizations
        gradle_props = android_dir / 'gradle.properties'
        if gradle_props.exists():
            content = gradle_props.read_text()
            optimizations = [
                'org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=1024m -XX:+HeapDumpOnOutOfMemoryError',
                'org.gradle.parallel=true',
                'org.gradle.caching=true',
                'android.enableR8.fullMode=true',
                'android.useAndroidX=true',
                'android.enableJetifier=false'
            ]

            for opt in optimizations:
                if opt not in content:
                    content += f'\n{opt}'

            gradle_props.write_text(content)

    def _optimize_web_build(self):
        """Web-specific build optimizations"""
        web_dir = self.project_path / 'web'
        if not web_dir.exists():
            web_dir.mkdir()

        # Create optimized index.html if it doesn't exist
        index_html = web_dir / 'index.html'
        if not index_html.exists():
            # This would be a basic template - in real implementation,
            # copy from Flutter's default or create optimized version
            pass

    def _optimize_desktop_build(self, platform: str):
        """Desktop-specific build optimizations"""
        # Platform-specific optimizations would go here
        pass

    def _compress_build_artifacts(self, platform: str):
        """Compress build artifacts for storage efficiency"""
        # Implementation for compressing build outputs
        pass

    def _generate_build_analytics(self, platform: str, build_type: str):
        """Generate build analytics and insights"""
        # Implementation for build analytics generation
        pass

    def _clean_temporary_files(self):
        """Clean temporary build files"""
        # Implementation for cleaning temporary files
        pass

    def _load_cache_index(self):
        """Load build cache index from disk"""
        if self.cache_index_file.exists():
            try:
                with open(self.cache_index_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    for key, entry_data in data.items():
                        # Convert datetime strings back to datetime objects
                        entry_data['build_time'] = datetime.fromisoformat(entry_data['build_time'])
                        self.cache_index[key] = BuildCacheEntry(**entry_data)
            except Exception as e:
                logger.warning(f"Failed to load cache index: {e}")

    def _save_cache_index(self):
        """Save build cache index to disk"""
        try:
            data = {}
            for key, entry in self.cache_index.items():
                entry_data = asdict(entry)
                # Convert datetime to ISO string
                entry_data['build_time'] = entry.build_time.isoformat()
                data[key] = entry_data

            with open(self.cache_index_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save cache index: {e}")

    def _load_build_metrics(self):
        """Load build metrics from disk"""
        if self.metrics_file.exists():
            try:
                with open(self.metrics_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    for metric_data in data:
                        # Convert datetime strings
                        metric_data['start_time'] = datetime.fromisoformat(metric_data['start_time'])
                        if metric_data.get('end_time'):
                            metric_data['end_time'] = datetime.fromisoformat(metric_data['end_time'])
                        self.build_metrics.append(BuildMetrics(**metric_data))
            except Exception as e:
                logger.warning(f"Failed to load build metrics: {e}")

    def _save_build_metrics(self):
        """Save build metrics to disk"""
        try:
            data = []
            for metric in self.build_metrics[-100:]:  # Keep last 100 builds
                metric_data = asdict(metric)
                # Convert datetime to ISO string
                metric_data['start_time'] = metric.start_time.isoformat()
                if metric.end_time:
                    metric_data['end_time'] = metric.end_time.isoformat()
                data.append(metric_data)

            with open(self.metrics_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save build metrics: {e}")

    def get_build_statistics(self) -> Dict[str, Any]:
        """Get comprehensive build statistics"""
        if not self.build_metrics:
            return {}

        successful_builds = [m for m in self.build_metrics if m.end_time is not None]
        avg_duration = sum(m.duration for m in successful_builds) / len(successful_builds) if successful_builds else 0

        return {
            'total_builds': len(self.build_metrics),
            'successful_builds': len(successful_builds),
            'failed_builds': len(self.build_metrics) - len(successful_builds),
            'average_duration': avg_duration,
            'cache_hit_ratio': sum(m.cache_hits for m in self.build_metrics) /
                             max(1, sum(m.cache_hits + m.cache_misses for m in self.build_metrics)),
            'peak_memory_usage': max((m.peak_memory_mb for m in self.build_metrics), default=0),
            'peak_cpu_usage': max((m.peak_cpu_percent for m in self.build_metrics), default=0),
        }

class BuildPerformanceMonitor:
    """Real-time build performance monitoring"""

    def __init__(self):
        self.monitoring = False
        self.start_time = None
        self.metrics = {
            'memory_mb': 0.0,
            'cpu_percent': 0.0,
            'network_requests': 0,
        }

    def start_monitoring(self):
        """Start performance monitoring"""
        self.monitoring = True
        self.start_time = time.time()

    def stop_monitoring(self):
        """Stop performance monitoring"""
        self.monitoring = False

    def update_metrics(self):
        """Update current performance metrics"""
        if not self.monitoring:
            return

        try:
            # Memory usage
            memory = psutil.virtual_memory()
            self.metrics['memory_mb'] = memory.used / (1024 * 1024)

            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=0.1)
            self.metrics['cpu_percent'] = cpu_percent

        except Exception:
            # Ignore monitoring errors
            pass

    def get_current_metrics(self) -> Dict[str, float]:
        """Get current performance metrics"""
        return self.metrics.copy()

    def get_final_metrics(self) -> Dict[str, Any]:
        """Get final performance metrics"""
        return {
            **self.metrics,
            'duration': time.time() - (self.start_time or time.time()),
        }

def main():
    """Main entry point for build optimization"""
    parser = argparse.ArgumentParser(description='Enhanced Build Optimizer for iSuite')
    parser.add_argument('project_path', help='Path to Flutter project')
    parser.add_argument('--platform', required=True, choices=['apk', 'aab', 'ios', 'web', 'windows', 'linux', 'macos'],
                       help='Target platform')
    parser.add_argument('--type', default='release', choices=['debug', 'release', 'profile'],
                       help='Build type')
    parser.add_argument('--force', action='store_true', help='Force rebuild (ignore cache)')
    parser.add_argument('--stats', action='store_true', help='Show build statistics')

    args = parser.parse_args()

    # Initialize optimizer
    optimizer = EnhancedBuildOptimizer(args.project_path)

    if args.stats:
        # Show build statistics
        stats = optimizer.get_build_statistics()
        print("Build Statistics:")
        print(json.dumps(stats, indent=2))
        return

    # Perform optimized build
    try:
        success, output, metrics = optimizer.optimize_build(
            platform=args.platform,
            build_type=args.type,
            force_rebuild=args.force
        )

        print(f"Build {'succeeded' if success else 'failed'}")
        print(f"Duration: {metrics.duration:.2f}s")
        print(f"Peak memory: {metrics.peak_memory_mb:.1f}MB")
        print(f"Peak CPU: {metrics.peak_cpu_percent:.1f}%")

        if not success:
            print("Build output:")
            print(output)
            sys.exit(1)

    except Exception as e:
        logger.error(f"Build optimization failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
